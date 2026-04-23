extends Node2D

const TOTAL_CASAS := 28
const HUD_BG := Color(0.08, 0.10, 0.18, 0.90)
const HUD_ACCENT := Color(0.96, 0.66, 0.16, 1.0)
const FEEDBACK_OK := Color(0.29, 0.85, 0.45, 0.95)
const FEEDBACK_FAIL := Color(0.93, 0.33, 0.33, 0.95)
const HUD_LAYER := 20
const DIALOG_LAYER := 40
const CAMERA_MARGIN := .0
const DIALOG_MAX_WIDTH := 760.0
const DIALOG_MAX_HEIGHT := 460.0

enum TurnState {
	WAITING_ROLL,
	SHOWING_QUESTION,
	MOVING_PLAYER
}

@onready var casas_root: Node = $Casas
@onready var player = $Player
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var sprite_dado: Sprite2D = $CanvasLayer/SpriteDado
@onready var dialog_panel: Panel = $CanvasLayer/JanelaPergunta
@onready var board_background: Sprite2D = $BoardBackground
@onready var board_camera: Camera2D = $BoardCamera

var dice_textures := [
	preload("res://imagens/Dado/Dado/dieWhite_border1.png"),
	preload("res://imagens/Dado/Dado/dieWhite_border2.png"),
	preload("res://imagens/Dado/Dado/dieWhite_border3.png"),
	preload("res://imagens/Dado/Dado/dieWhite_border4.png"),
	preload("res://imagens/Dado/Dado/dieWhite_border5.png"),
	preload("res://imagens/Dado/Dado/dieWhite_border6.png")
]

var board_positions: Array[Vector2] = []
var pending_target_house: int = 1
var pending_correct_index: int = 0
var current_roll: int = 0
var accepting_roll := true
var turn_state: int = TurnState.WAITING_ROLL
var answering_locked := false

var hud_canvas: CanvasLayer
var hud_root: Control
var roll_button: Button
@onready var settings_button: TextureButton = $CanvasLayer/BotaoConfiguracao
var feedback_label: Label
var score_label: Label
var level_label: Label
var progress_label: Label
var player_label: Label
var room_label: Label
var accuracy_label: Label
var subtitle_label: Label

var dialog_backdrop: ColorRect
var dialog_title_label: Label
var question_label: Label
var question_hint_label: Label
var button_a: Button
var button_b: Button
var button_c: Button

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

func _ready() -> void:
	randomize()
	SettingsManager.pause_tree_when_open = true
	SettingsManager.close_menu()
	canvas_layer.layer = DIALOG_LAYER
	_build_board_positions()
	player.setup(board_positions)
	player.step_reached.connect(_on_step_reached)
	player.movement_finished.connect(_on_movement_finished)

	_create_audio_players()
	_build_hud()
	_build_question_ui()
	_configure_camera()
	_refresh_hud()
	call_deferred("_apply_initial_layout")
	_hide_dialog()
	_set_turn_state(TurnState.WAITING_ROLL)
	_play_music()
	_show_feedback("Role o dado para abrir uma pergunta.", FEEDBACK_OK)

	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)
		
func _apply_initial_layout() -> void:
	await get_tree().process_frame
	_update_viewport_layout()
	
func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event.is_action_pressed("ui_accept") and accepting_roll and not dialog_panel.visible:
		roll_dice()
		get_viewport().set_input_as_handled()

func _build_board_positions() -> void:
	board_positions.clear()
	for i in range(1, TOTAL_CASAS + 1):
		var casa := casas_root.get_node_or_null("StaticBody2D_P%d" % i)
		if casa:
			board_positions.append(casa.global_position)

func _create_audio_players() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "GameMusic"
	music_player.bus = "Music"
	music_player.stream = load("res://assets/audio/menu_theme.wav")
	add_child(music_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "GameSfx"
	sfx_player.bus = "SFX"
	add_child(sfx_player)

func _play_music() -> void:
	if music_player and music_player.stream and SettingsManager.music_enabled and not music_player.playing:
		music_player.play()

func _play_sfx(path: String) -> void:
	if sfx_player == null:
		return
	var stream := load(path)
	if stream == null:
		return
	sfx_player.stream = stream
	sfx_player.play()

func _build_hud() -> void:
	hud_canvas = CanvasLayer.new()
	hud_canvas.name = "HUD"
	hud_canvas.layer = HUD_LAYER
	add_child(hud_canvas)

	hud_root = Control.new()
	hud_root.name = "Root"
	hud_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_canvas.add_child(hud_root)

	var top_panel := PanelContainer.new()
	top_panel.name = "TopPanel"
	top_panel.custom_minimum_size = Vector2(520, 88)
	top_panel.size = Vector2(540, 96)
	top_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = HUD_BG
	panel_style.corner_radius_top_left = 20
	panel_style.corner_radius_top_right = 20
	panel_style.corner_radius_bottom_left = 20
	panel_style.corner_radius_bottom_right = 20
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = HUD_ACCENT
	panel_style.shadow_color = Color(0, 0, 0, 0.25)
	panel_style.shadow_size = 8
	top_panel.add_theme_stylebox_override("panel", panel_style)
	hud_root.add_child(top_panel)

	var margin := MarginContainer.new()
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 14)
	top_panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 24)
	margin.add_child(hbox)

	var left := VBoxContainer.new()
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 6)
	hbox.add_child(left)

	player_label = _make_label(22, true)
	room_label = _make_label(16)
	subtitle_label = _make_label(15)
	left.add_child(player_label)
	left.add_child(room_label)
	left.add_child(subtitle_label)

	var right := VBoxContainer.new()
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right.add_theme_constant_override("separation", 4)
	hbox.add_child(right)

	score_label = _make_label(15, true)
	level_label = _make_label(15, true)
	progress_label = _make_label(15, true)
	accuracy_label = _make_label(15, true)
	right.add_child(score_label)
	right.add_child(level_label)
	right.add_child(progress_label)
	right.add_child(accuracy_label)

	feedback_label = Label.new()
	feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	feedback_label.size = Vector2(560, 42)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 20)
	feedback_label.add_theme_color_override("font_color", Color.WHITE)
	hud_root.add_child(feedback_label)

	roll_button = _create_action_button("ROLAR DADO", Callable(self, "roll_dice"))
	hud_root.add_child(roll_button)

	if settings_button and not settings_button.pressed.is_connected(_on_settings_pressed):
		settings_button.pressed.connect(_on_settings_pressed)	
	
func _on_settings_pressed() -> void:
	SettingsManager.open_menu()

func _create_action_button(text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.size = Vector2(214, 54)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", Color(0.08, 0.10, 0.18, 1.0))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(1.0, 0.78, 0.22, 1.0)
	normal.corner_radius_top_left = 18
	normal.corner_radius_top_right = 18
	normal.corner_radius_bottom_left = 18
	normal.corner_radius_bottom_right = 18
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = Color(0.12, 0.08, 0.03, 0.95)
	var hover := normal.duplicate()
	hover.bg_color = Color(1.0, 0.85, 0.36, 1.0)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.pressed.connect(callback)
	return button

func _make_label(size: int, bold := false) -> Label:
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	if bold:
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.25))
	return label

func _build_question_ui() -> void:
	for child in dialog_panel.get_children():
		child.queue_free()

	dialog_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	dialog_panel.focus_mode = Control.FOCUS_ALL
	dialog_panel.visible = false
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.09, 0.12, 0.21, 0.97)
	panel_style.corner_radius_top_left = 28
	panel_style.corner_radius_top_right = 28
	panel_style.corner_radius_bottom_left = 28
	panel_style.corner_radius_bottom_right = 28
	panel_style.border_width_left = 3
	panel_style.border_width_top = 3
	panel_style.border_width_right = 3
	panel_style.border_width_bottom = 3
	panel_style.border_color = Color(1.0, 0.76, 0.25, 1.0)
	panel_style.shadow_color = Color(0, 0, 0, 0.35)
	panel_style.shadow_size = 14
	dialog_panel.add_theme_stylebox_override("panel", panel_style)

	dialog_backdrop = ColorRect.new()
	dialog_backdrop.name = "DialogBackdrop"
	dialog_backdrop.visible = false
	dialog_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialog_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	dialog_backdrop.color = Color(0.02, 0.02, 0.05, 0.58)
	canvas_layer.add_child(dialog_backdrop)
	canvas_layer.move_child(dialog_backdrop, 0)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 26)
	dialog_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)

	dialog_title_label = Label.new()
	dialog_title_label.text = "DESAFIO DO TABULEIRO"
	dialog_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialog_title_label.add_theme_font_size_override("font_size", 26)
	dialog_title_label.add_theme_color_override("font_color", HUD_ACCENT)
	vbox.add_child(dialog_title_label)

	question_label = Label.new()
	question_label.custom_minimum_size = Vector2(0, 108)
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	question_label.add_theme_font_size_override("font_size", 28)
	question_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	vbox.add_child(question_label)

	question_hint_label = Label.new()
	question_hint_label.text = "Escolha uma alternativa para continuar avançando."
	question_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_hint_label.add_theme_font_size_override("font_size", 16)
	question_hint_label.add_theme_color_override("font_color", Color(0.85, 0.90, 0.98, 0.88))
	vbox.add_child(question_hint_label)

	var answers := VBoxContainer.new()
	answers.add_theme_constant_override("separation", 14)
	answers.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(answers)

	button_a = _create_answer_button(0)
	button_b = _create_answer_button(1)
	button_c = _create_answer_button(2)
	answers.add_child(button_a)
	answers.add_child(button_b)
	answers.add_child(button_c)

func _create_answer_button(answer_slot: int) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 56) # antes 72
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 18) # antes 22
	button.add_theme_constant_override("h_separation", 8)
	button.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	button.add_theme_stylebox_override("normal", _make_answer_style(Color(0.17, 0.25, 0.42, 1.0)))
	button.add_theme_stylebox_override("hover", _make_answer_style(Color(0.22, 0.32, 0.53, 1.0)))
	button.add_theme_stylebox_override("pressed", _make_answer_style(Color(0.28, 0.40, 0.60, 1.0)))
	button.pressed.connect(func() -> void:
		_on_answer_button_pressed(answer_slot)
	)
	return button

func _make_answer_style(color_value: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color_value
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.92, 0.95, 1.0, 0.20)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	return style

func _configure_camera() -> void:
	if board_camera == null:
		return
	board_camera.enabled = true
	board_camera.position_smoothing_enabled = false
	board_camera.make_current()

func _on_viewport_size_changed() -> void:
	_update_viewport_layout()

func _update_viewport_layout() -> void:
	_layout_hud()
	_layout_dialog()
	_fit_board_to_view()

func _layout_hud() -> void:
	if hud_root == null:
		return
	var viewport_size := get_viewport_rect().size
	var top_panel: PanelContainer = hud_root.get_node_or_null("TopPanel")
	if top_panel:
		top_panel.position = Vector2(16, 16)
		top_panel.size = Vector2( maxf(320.0, minf(540.0, viewport_size.x - 32.0)),96.0)
	feedback_label.position = Vector2(18, 156)
	feedback_label.size.x = maxf(320.0, minf(560.0, viewport_size.x - 36.0))
	var bottom_margin := 24.0
	var action_y := viewport_size.y - roll_button.size.y - bottom_margin

	roll_button.position = Vector2(
		(viewport_size.x - roll_button.size.x) * 0.5,
		action_y
	)

	sprite_dado.position = Vector2(viewport_size.x - 86.0, 82.0)

func _layout_dialog() -> void:
	if dialog_panel == null:
		return
	var viewport_size := get_viewport_rect().size
	var dialog_width := maxf(360.0, minf(DIALOG_MAX_WIDTH, viewport_size.x - 72.0))
	var dialog_height := maxf(320.0, minf(DIALOG_MAX_HEIGHT, viewport_size.y - 72.0))
	dialog_panel.anchor_left = 0.5
	dialog_panel.anchor_top = 0.5
	dialog_panel.anchor_right = 0.5
	dialog_panel.anchor_bottom = 0.5
	dialog_panel.offset_left = -dialog_width * 0.5
	dialog_panel.offset_top = -dialog_height * 0.5
	dialog_panel.offset_right = dialog_width * 0.5
	dialog_panel.offset_bottom = dialog_height * 0.5

func _fit_board_to_view() -> void:
	if board_camera == null:
		return

	var bounds := _get_board_bounds()
	if bounds.size == Vector2.ZERO:
		return

	var viewport_size := get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var usable_view := viewport_size - Vector2(CAMERA_MARGIN * 2.0, CAMERA_MARGIN * 2.0)
	usable_view.x = maxf(usable_view.x, 1.0)
	usable_view.y = maxf(usable_view.y, 1.0)

	var zoom_x := bounds.size.x / usable_view.x
	var zoom_y := bounds.size.y / usable_view.y
	var zoom_factor := maxf(zoom_x, zoom_y)

	if zoom_factor < 1.0:
		zoom_factor = 1.0

	board_camera.zoom = Vector2(zoom_factor, zoom_factor)
	board_camera.global_position = bounds.get_center()

func _get_board_bounds() -> Rect2:
	var points: Array[Vector2] = []

	if board_background != null and board_background.texture != null:
		var texture_size := board_background.texture.get_size()
		var scale_abs := Vector2(absf(board_background.scale.x), absf(board_background.scale.y))
		var background_size := texture_size * scale_abs

		var top_left := board_background.global_position - (background_size * 0.5)

		if not board_background.centered:
			top_left = board_background.global_position

		top_left += board_background.offset * scale_abs

		points.append(top_left)
		points.append(top_left + Vector2(background_size.x, 0))
		points.append(top_left + Vector2(0, background_size.y))
		points.append(top_left + background_size)

	for position in board_positions:
		points.append(position)

	if player != null:
		points.append(player.global_position)

	if points.is_empty():
		return Rect2()

	var min_x := points[0].x
	var min_y := points[0].y
	var max_x := points[0].x
	var max_y := points[0].y

	for p in points:
		min_x = minf(min_x, p.x)
		min_y = minf(min_y, p.y)
		max_x = maxf(max_x, p.x)
		max_y = maxf(max_y, p.y)

	return Rect2(
		Vector2(min_x, min_y),
		Vector2(max_x - min_x, max_y - min_y)
	).grow(CAMERA_MARGIN)

func _hide_dialog() -> void:
	dialog_panel.hide()
	if dialog_backdrop:
		dialog_backdrop.hide()
	_set_question_buttons_enabled(false)
	answering_locked = false

func _show_dialog() -> void:
	if dialog_backdrop:
		dialog_backdrop.show()
	dialog_panel.show()
	canvas_layer.move_child(dialog_panel, canvas_layer.get_child_count() - 1)
	_set_question_buttons_enabled(true)
	answering_locked = false
	button_a.grab_focus()

func _set_question_buttons_enabled(enabled: bool) -> void:
	for button in [button_a, button_b, button_c]:
		if button != null:
			button.disabled = not enabled

func _set_turn_state(new_state: int) -> void:
	turn_state = new_state
	accepting_roll = new_state == TurnState.WAITING_ROLL
	if roll_button != null:
		roll_button.disabled = not accepting_roll
	if settings_button != null:
		settings_button.disabled = new_state != TurnState.WAITING_ROLL

func roll_dice() -> void:
	if turn_state != TurnState.WAITING_ROLL:
		return
	if dialog_panel.visible or get_tree().paused:
		return

	_set_turn_state(TurnState.SHOWING_QUESTION)
	current_roll = randi_range(1, 6)
	pending_target_house = mini(player.current_house + current_roll, TOTAL_CASAS)
	sprite_dado.texture = dice_textures[current_roll - 1]
	_play_sfx("res://assets/audio/dice.wav")
	_present_question(pending_target_house)

func _present_question(house_index: int) -> void:
	var question := GameState.get_question_for_house(house_index)
	var order := [0, 1, 2]
	order.shuffle()
	pending_correct_index = order.find(int(question["correct"]))

	dialog_title_label.text = "Casa %d • Nível %d" % [house_index, GameState.get_level_for_house(house_index)]
	question_label.text = question["text"]
	button_a.text = "A) %s" % question["options"][order[0]]
	button_b.text = "B) %s" % question["options"][order[1]]
	button_c.text = "C) %s" % question["options"][order[2]]
	_show_dialog()

	if SettingsManager.subtitles_enabled:
		subtitle_label.text = "Leia a pergunta e escolha a resposta correta."

func _on_answer_button_pressed(answer_slot: int) -> void:
	if turn_state != TurnState.SHOWING_QUESTION:
		return
	if not dialog_panel.visible or answering_locked:
		return

	answering_locked = true
	_set_question_buttons_enabled(false)
	var correct := answer_slot == pending_correct_index
	_hide_dialog()
	GameState.register_answer(correct, pending_target_house)

	if correct:
		_set_turn_state(TurnState.MOVING_PLAYER)
		_show_feedback(GameState.last_feedback, FEEDBACK_OK)
		_play_sfx("res://assets/audio/correct.wav")
		if SettingsManager.vfx_enabled:
			_pulse_feedback()
		await player.move_to_house(pending_target_house)
	else:
		_show_feedback(GameState.last_feedback, FEEDBACK_FAIL)
		_play_sfx("res://assets/audio/wrong.wav")
		_finalize_turn()

	_refresh_hud()

func _pulse_feedback() -> void:
	var tween := create_tween()
	tween.tween_property(feedback_label, "scale", Vector2(1.08, 1.08), 0.08)
	tween.tween_property(feedback_label, "scale", Vector2.ONE, 0.12)

func _on_step_reached(house_index: int) -> void:
	GameState.update_progress(house_index)
	_refresh_hud()
	_play_sfx("res://assets/audio/move.wav")

func _on_movement_finished() -> void:
	if turn_state == TurnState.MOVING_PLAYER:
		_finalize_turn()

func _finalize_turn() -> void:
	current_roll = 0
	answering_locked = false
	if GameState.current_house >= TOTAL_CASAS:
		GameState.finish_session(true)
		get_tree().change_scene_to_file("res://scene/end_game_screen.tscn")
		return
	_set_turn_state(TurnState.WAITING_ROLL)

func _show_feedback(text_value: String, color_value: Color) -> void:
	feedback_label.text = text_value
	feedback_label.add_theme_color_override("font_color", color_value)
	if SettingsManager.subtitles_enabled:
		subtitle_label.text = GameState.last_feedback
	else:
		subtitle_label.text = ""

func _refresh_hud() -> void:
	player_label.text = "Jogador: %s" % (GameState.player_name if not GameState.player_name.is_empty() else "Aluno")
	room_label.text = "Sala: %s" % (GameState.room_code if not GameState.room_code.is_empty() else "Sem codigo")
	score_label.text = "Score: %d" % GameState.score
	level_label.text = "Nível: %d" % GameState.level
	progress_label.text = "Casa: %d/%d" % [GameState.current_house, TOTAL_CASAS]
	accuracy_label.text = "Acertos: %d%%" % GameState.get_accuracy_percent()
	if not SettingsManager.subtitles_enabled:
		subtitle_label.text = ""

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		GameState.finish_session(false)
