extends Node2D

const UITheme := preload("res://scripts/UITheme.gd")
const TOTAL_CASAS := 28
const HUD_BG := Color(0.08, 0.10, 0.18, 0.90)
const HUD_ACCENT := Color(0.96, 0.66, 0.16, 1.0)
const FEEDBACK_OK := Color(0.29, 0.85, 0.45, 0.95)
const FEEDBACK_FAIL := Color(0.93, 0.33, 0.33, 0.95)
const HUD_LAYER := 20
const DIALOG_LAYER := 40
const CAMERA_PADDING := 0.92
const BOARD_MIN_ZOOM := 0.36
const DIALOG_MAX_WIDTH := 980.0
const DIALOG_MAX_HEIGHT := 720.0
const QUESTION_BASE_HEIGHT := 84.0
const QUESTION_TALL_HEIGHT := 126.0
const QUESTION_EXTRA_TALL_HEIGHT := 156.0
const ANSWER_BASE_HEIGHT := 52.0
const ANSWER_TALL_HEIGHT := 78.0
const ANSWER_EXTRA_TALL_HEIGHT := 104.0
const ANSWER_ULTRA_TALL_HEIGHT := 128.0
const ANSWER_SLOT_LABELS: Array[String] = ["A", "B", "C", "D"]
const BOARD_HORIZONTAL_PADDING_RATIO := 0.015
const BOARD_HORIZONTAL_PADDING_MIN := 12.0
const BOARD_HORIZONTAL_PADDING_MAX := 28.0
const BOARD_TOP_PADDING_RATIO := 0.05
const BOARD_TOP_PADDING_MIN := 28.0
const BOARD_TOP_PADDING_MAX := 52.0
const BOARD_BOTTOM_PADDING_RATIO := 0.05
const BOARD_BOTTOM_PADDING_MIN := 28.0
const BOARD_BOTTOM_PADDING_MAX := 52.0
const BOARD_PATH_SHADOW_NAME := "BoardPathShadow"
const BOARD_PATH_LINE_NAME := "BoardPathLine"
const BOARD_HOUSE_SPRITE_SCALE := Vector2(0.18, 0.135)
const BOARD_PATH_SCREEN_POINTS: Array[Vector2] = [
	Vector2(0.22, 0.83),
	Vector2(0.30, 0.80),
	Vector2(0.38, 0.76),
	Vector2(0.46, 0.71),
	Vector2(0.54, 0.66),
	Vector2(0.62, 0.60),
	Vector2(0.70, 0.55),
	Vector2(0.78, 0.51),
	Vector2(0.84, 0.47),
	Vector2(0.82, 0.40),
	Vector2(0.75, 0.36),
	Vector2(0.67, 0.33),
	Vector2(0.59, 0.32),
	Vector2(0.51, 0.34),
	Vector2(0.43, 0.39),
	Vector2(0.36, 0.45),
	Vector2(0.28, 0.52),
	Vector2(0.19, 0.55),
	Vector2(0.12, 0.48),
	Vector2(0.09, 0.40),
	Vector2(0.08, 0.31),
	Vector2(0.12, 0.23),
	Vector2(0.22, 0.21),
	Vector2(0.34, 0.21),
	Vector2(0.48, 0.21),
	Vector2(0.62, 0.21),
	Vector2(0.76, 0.21),
	Vector2(0.82, 0.18),
]

enum TurnState {
	WAITING_ROLL,
	SHOWING_QUESTION,
	MOVING_PLAYER
}

@onready var casas_root: Node = get_node_or_null("Casas")
@onready var player = get_node_or_null("Player")
@onready var canvas_layer: CanvasLayer = get_node_or_null("CanvasLayer") as CanvasLayer
@onready var sprite_dado: Sprite2D = get_node_or_null("CanvasLayer/SpriteDado") as Sprite2D
@onready var dialog_panel: Control = get_node_or_null("CanvasLayer/JanelaPergunta") as Control
@onready var dialog_backdrop: ColorRect = get_node_or_null("CanvasLayer/DialogBackdrop") as ColorRect
@onready var dialog_title_label: Label = get_node_or_null("CanvasLayer/JanelaPergunta/Margin/VBox/DialogTitle") as Label
@onready var question_label: Label = get_node_or_null("CanvasLayer/JanelaPergunta/Margin/VBox/QuestionLabel") as Label
@onready var question_hint_label: Label = get_node_or_null("CanvasLayer/JanelaPergunta/Margin/VBox/QuestionHintLabel") as Label
@onready var answers_container: VBoxContainer = get_node_or_null("CanvasLayer/JanelaPergunta/Margin/VBox/Answers") as VBoxContainer
@onready var button_a: Button = get_node_or_null("CanvasLayer/JanelaPergunta/Margin/VBox/Answers/ButtonA") as Button
@onready var button_b: Button = get_node_or_null("CanvasLayer/JanelaPergunta/Margin/VBox/Answers/ButtonB") as Button
@onready var button_c: Button = get_node_or_null("CanvasLayer/JanelaPergunta/Margin/VBox/Answers/ButtonC") as Button
@onready var button_d: Button = get_node_or_null("CanvasLayer/JanelaPergunta/Margin/VBox/Answers/ButtonD") as Button
@onready var hud_canvas: CanvasLayer = get_node_or_null("HUD") as CanvasLayer
@onready var hud_root: Control = get_node_or_null("HUD/Root") as Control
@onready var top_panel: PanelContainer = get_node_or_null("HUD/Root/TopPanel") as PanelContainer
@onready var roll_button: Button = get_node_or_null("HUD/Root/RollButton") as Button
@onready var feedback_label: Label = get_node_or_null("HUD/Root/FeedbackLabel") as Label
@onready var score_label: Label = get_node_or_null("HUD/Root/TopPanel/Margin/HBox/Right/ScoreLabel") as Label
@onready var level_label: Label = get_node_or_null("HUD/Root/TopPanel/Margin/HBox/Right/LevelLabel") as Label
@onready var progress_label: Label = get_node_or_null("HUD/Root/TopPanel/Margin/HBox/Right/ProgressLabel") as Label
@onready var player_label: Label = get_node_or_null("HUD/Root/TopPanel/Margin/HBox/Left/PlayerLabel") as Label
@onready var room_label: Label = get_node_or_null("HUD/Root/TopPanel/Margin/HBox/Left/RoomLabel") as Label
@onready var accuracy_label: Label = get_node_or_null("HUD/Root/TopPanel/Margin/HBox/Right/AccuracyLabel") as Label
@onready var subtitle_label: Label = get_node_or_null("HUD/Root/TopPanel/Margin/HBox/Left/SubtitleLabel") as Label
@onready var screen_background: TextureRect = get_node_or_null("BackgroundLayer/Background") as TextureRect
@onready var board_camera: Camera2D = get_node_or_null("BoardCamera") as Camera2D
@onready var settings_button: TextureButton = get_node_or_null("CanvasLayer/BotaoConfiguracao") as TextureButton

var dice_textures: Array[Texture2D] = [
	preload("res://imagens/Dado/Dado/dieWhite_border1.png"),
	preload("res://imagens/Dado/Dado/dieWhite_border2.png"),
	preload("res://imagens/Dado/Dado/dieWhite_border3.png"),
	preload("res://imagens/Dado/Dado/dieWhite_border4.png"),
	preload("res://imagens/Dado/Dado/dieWhite_border5.png"),
	preload("res://imagens/Dado/Dado/dieWhite_border6.png")
]

var board_positions: Array[Vector2] = []
var board_local_positions: Array[Vector2] = []
var pending_target_house: int = 1
var pending_correct_index: int = 0
var current_roll: int = 0
var rng_roll = RandomNumberGenerator.new()
var accepting_roll: bool = true
var turn_state: int = TurnState.WAITING_ROLL
var answering_locked: bool = false

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

func _ready() -> void:
	randomize()

	SettingsManager.pause_tree_when_open = true
	SettingsManager.close_menu()
	if canvas_layer != null:
		canvas_layer.layer = DIALOG_LAYER
	if hud_canvas != null:
		hud_canvas.layer = HUD_LAYER
	_bind_scene_ui()
	_layout_board_path()
	_build_board_positions()

	if player != null:
		if player.has_method("setup"):
			player.setup(board_positions)
		if player.has_signal("step_reached") and not player.step_reached.is_connected(_on_step_reached):
			player.step_reached.connect(_on_step_reached)
		if player.has_signal("movement_finished") and not player.movement_finished.is_connected(_on_movement_finished):
			player.movement_finished.connect(_on_movement_finished)

	_create_audio_players()
	if not SettingsManager.settings_changed.is_connected(_on_settings_changed):
		SettingsManager.settings_changed.connect(_on_settings_changed)
	_configure_camera()
	_refresh_hud()
	call_deferred("_apply_initial_layout")
	_hide_dialog()
	_set_turn_state(TurnState.WAITING_ROLL)
	_sync_music_state()
	_show_feedback("Role o dado para abrir uma pergunta.", FEEDBACK_OK)

	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)

func _bind_scene_ui() -> void:
	if hud_root != null:
		hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if top_panel != null:
		top_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var panel_style: StyleBoxFlat = StyleBoxFlat.new()
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

	for label in [player_label, room_label, subtitle_label]:
		if label != null:
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			UITheme.apply_font_only(label, 22 if label == player_label else (16 if label == room_label else 15))
			label.add_theme_color_override("font_color", Color.WHITE)

	for label in [score_label, level_label, progress_label, accuracy_label]:
		if label != null:
			label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			UITheme.apply_font_only(label, 15)
			label.add_theme_color_override("font_color", Color.WHITE)

	if feedback_label != null:
		feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UITheme.apply_font_only(feedback_label, 20)
		feedback_label.add_theme_color_override("font_color", Color.WHITE)

	if roll_button != null:
		roll_button.focus_mode = Control.FOCUS_NONE
		UITheme.apply_button(roll_button, UITheme.BUTTON_PRIMARY, 20)
		if not roll_button.pressed.is_connected(Callable(self, "roll_dice")):
			roll_button.pressed.connect(Callable(self, "roll_dice"))

	if settings_button != null:
		if not settings_button.pressed.is_connected(Callable(self, "_on_settings_pressed")):
			settings_button.pressed.connect(Callable(self, "_on_settings_pressed"))

	if dialog_panel != null:
		dialog_panel.mouse_filter = Control.MOUSE_FILTER_STOP
		dialog_panel.focus_mode = Control.FOCUS_ALL
		dialog_panel.visible = false
		var dialog_style: StyleBoxFlat = StyleBoxFlat.new()
		dialog_style.bg_color = Color(0.09, 0.12, 0.21, 0.97)
		dialog_style.corner_radius_top_left = 28
		dialog_style.corner_radius_top_right = 28
		dialog_style.corner_radius_bottom_left = 28
		dialog_style.corner_radius_bottom_right = 28
		dialog_style.border_width_left = 3
		dialog_style.border_width_top = 3
		dialog_style.border_width_right = 3
		dialog_style.border_width_bottom = 3
		dialog_style.border_color = Color(1.0, 0.76, 0.25, 1.0)
		dialog_style.shadow_color = Color(0, 0, 0, 0.35)
		dialog_style.shadow_size = 14
		dialog_panel.add_theme_stylebox_override("panel", dialog_style)

	if dialog_title_label != null:
		UITheme.apply_font_only(dialog_title_label, 26)
		dialog_title_label.add_theme_color_override("font_color", HUD_ACCENT)

	if question_label != null:
		UITheme.apply_font_only(question_label, 24)
		question_label.add_theme_color_override("font_color", Color.WHITE)
		question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	if question_hint_label != null:
		UITheme.apply_font_only(question_hint_label, 15)
		question_hint_label.add_theme_color_override("font_color", Color(0.85, 0.90, 0.98, 0.88))
		question_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	_style_and_connect_answer_button(button_a, 0)
	_style_and_connect_answer_button(button_b, 1)
	_style_and_connect_answer_button(button_c, 2)
	_style_and_connect_answer_button(button_d, 3)

func _style_and_connect_answer_button(button: Button, answer_slot: int) -> void:
	if button == null:
		return
	button.focus_mode = Control.FOCUS_ALL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.set("autowrap_mode", TextServer.AUTOWRAP_WORD_SMART)
	button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	button.clip_text = false
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_constant_override("h_separation", 8)
	UITheme.apply_button(button, UITheme.BUTTON_SECONDARY, 17)
	var callback := Callable(self, "_on_answer_button_pressed").bind(answer_slot)
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)

func _apply_initial_layout() -> void:
	await get_tree().process_frame
	_update_viewport_layout()

func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return

	var dialog_open: bool = dialog_panel != null and dialog_panel.visible
	if event.is_action_pressed("ui_accept") and accepting_roll and not dialog_open:
		roll_dice()
		get_viewport().set_input_as_handled()

func _build_board_positions() -> void:
	board_positions.clear()
	board_local_positions.clear()
	if casas_root == null:
		return

	for i in range(1, TOTAL_CASAS + 1):
		var casa: Node = casas_root.get_node_or_null("StaticBody2D_P%d" % i)
		var casa_2d := casa as Node2D
		if casa_2d:
			board_positions.append(casa_2d.global_position)
			board_local_positions.append(casa_2d.position)

	_refresh_board_path_visual()

func _refresh_board_path_visual() -> void:
	var casas_node := casas_root as Node2D
	if casas_node == null or board_local_positions.size() < 2:
		return

	for old_path_name in [BOARD_PATH_SHADOW_NAME, BOARD_PATH_LINE_NAME]:
		var old_path := casas_node.get_node_or_null(old_path_name)
		if old_path != null:
			casas_node.remove_child(old_path)
			old_path.free()

	var shadow := _create_board_path_line(
		BOARD_PATH_SHADOW_NAME,
		Color(0.18, 0.11, 0.04, 0.28),
		20.0,
		-20
	)
	var path_line := _create_board_path_line(
		BOARD_PATH_LINE_NAME,
		Color(1.0, 0.78, 0.22, 0.72),
		9.0,
		-19
	)
	casas_node.add_child(shadow)
	casas_node.add_child(path_line)

func _create_board_path_line(line_name: String, color_value: Color, width: float, z_value: int) -> Line2D:
	var line := Line2D.new()
	line.name = line_name
	line.width = width
	line.default_color = color_value
	line.z_index = z_value
	line.antialiased = true
	for point in board_local_positions:
		line.add_point(point)
	return line

func _layout_board_path() -> void:
	if casas_root == null:
		return

	var viewport_size := _get_layout_size()
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	for index in range(mini(TOTAL_CASAS, BOARD_PATH_SCREEN_POINTS.size())):
		var casa := casas_root.get_node_or_null("StaticBody2D_P%d" % (index + 1)) as Node2D
		if casa == null:
			continue

		var normalized_point := BOARD_PATH_SCREEN_POINTS[index]
		casa.global_position = Vector2(
			normalized_point.x * viewport_size.x,
			normalized_point.y * viewport_size.y
		)
		_apply_house_visual_size(casa)

func _apply_house_visual_size(casa: Node2D) -> void:
	var sprite := casa.get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.scale = BOARD_HOUSE_SPRITE_SCALE

func _create_audio_players() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.name = "GameMusic"
	music_player.bus = "Music"
	music_player.stream = load("res://assets/audio/fundo.mp3")
	add_child(music_player)

	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "GameSfx"
	sfx_player.bus = "SFX"
	add_child(sfx_player)

func _play_music() -> void:
	if music_player and music_player.stream and SettingsManager.music_enabled and not music_player.playing:
		music_player.play()

func _sync_music_state() -> void:
	if music_player == null or music_player.stream == null:
		return
	if SettingsManager.music_enabled:
		if not music_player.playing:
			music_player.play()
	else:
		if music_player.playing:
			music_player.stop()

func _on_settings_changed() -> void:
	_sync_music_state()

func _play_sfx(path: String) -> void:
	if sfx_player == null:
		return

	var stream: AudioStream = load(path) as AudioStream
	if stream == null:
		return

	sfx_player.stream = stream
	sfx_player.play()

func _on_settings_pressed() -> void:
	SettingsManager.open_menu()

func _configure_camera() -> void:
	if board_camera == null:
		return

	board_camera.enabled = true
	board_camera.position_smoothing_enabled = false
	board_camera.make_current()

func _on_viewport_size_changed() -> void:
	_update_viewport_layout()

func _update_viewport_layout() -> void:
	_layout_screen_background()
	_layout_hud()
	_layout_dialog()
	_layout_board_path()
	_build_board_positions()
	_fit_board_to_view()

func _layout_screen_background() -> void:
	if screen_background == null:
		return

	var viewport_size: Vector2 = _get_layout_size()
	screen_background.anchor_left = 0.0
	screen_background.anchor_top = 0.0
	screen_background.anchor_right = 0.0
	screen_background.anchor_bottom = 0.0
	screen_background.offset_left = 0.0
	screen_background.offset_top = 0.0
	screen_background.offset_right = viewport_size.x
	screen_background.offset_bottom = viewport_size.y

func _layout_hud() -> void:
	if hud_root == null:
		return

	var viewport_size: Vector2 = _get_layout_size()
	var top_panel: PanelContainer = hud_root.get_node_or_null("TopPanel") as PanelContainer

	if top_panel:
		top_panel.position = Vector2(16, 16)
		top_panel.size = Vector2(
			clampf(viewport_size.x * 0.34, 320.0, 680.0),
			102.0
		)

	if feedback_label != null:
		feedback_label.position = Vector2(18, 156)
		feedback_label.size.x = maxf(320.0, minf(560.0, viewport_size.x - 36.0))

	if roll_button != null:
		var bottom_margin: float = 24.0
		var action_y: float = viewport_size.y - roll_button.size.y - bottom_margin
		roll_button.position = Vector2(
			(viewport_size.x - roll_button.size.x) * 0.5,
			action_y
		)

	if sprite_dado != null:
		sprite_dado.position = Vector2(viewport_size.x - 86.0, 82.0)

	if settings_button != null:
		var settings_size: float = 128.0
		var settings_margin: float = 18.0
		settings_button.anchor_left = 0.0
		settings_button.anchor_top = 0.0
		settings_button.anchor_right = 0.0
		settings_button.anchor_bottom = 0.0
		settings_button.custom_minimum_size = Vector2(settings_size, settings_size)
		settings_button.size = Vector2(settings_size, settings_size)
		settings_button.position = Vector2(
			viewport_size.x - settings_size - settings_margin,
			viewport_size.y - settings_size - settings_margin
		)
		settings_button.scale = Vector2.ONE

func _layout_dialog() -> void:
	if dialog_panel == null:
		return

	var viewport_size: Vector2 = _get_layout_size()
	var dialog_width: float = maxf(420.0, minf(DIALOG_MAX_WIDTH, viewport_size.x - 56.0))
	var dialog_height: float = maxf(430.0, minf(DIALOG_MAX_HEIGHT, viewport_size.y - 24.0))

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

	var viewport_size: Vector2 = _get_layout_size()
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	board_camera.zoom = Vector2.ONE
	board_camera.global_position = viewport_size * 0.5

func _get_layout_size() -> Vector2:
	return get_viewport_rect().size

func _build_board_focus_rect(viewport_size: Vector2) -> Rect2:
	var board_rect: Rect2 = _calculate_board_bounds()
	if board_rect.size.x <= 0.0 or board_rect.size.y <= 0.0:
		return board_rect

	var horizontal_padding: float = clampf(
		viewport_size.x * BOARD_HORIZONTAL_PADDING_RATIO,
		BOARD_HORIZONTAL_PADDING_MIN,
		BOARD_HORIZONTAL_PADDING_MAX
	)
	var top_padding: float = clampf(
		viewport_size.y * BOARD_TOP_PADDING_RATIO,
		BOARD_TOP_PADDING_MIN,
		BOARD_TOP_PADDING_MAX
	)
	var bottom_padding: float = clampf(
		viewport_size.y * BOARD_BOTTOM_PADDING_RATIO,
		BOARD_BOTTOM_PADDING_MIN,
		BOARD_BOTTOM_PADDING_MAX
	)
	board_rect.position -= Vector2(horizontal_padding, top_padding)
	board_rect.size += Vector2(horizontal_padding * 2.0, top_padding + bottom_padding)
	return board_rect

func _calculate_board_bounds() -> Rect2:
	var has_bounds: bool = false
	var bounds: Rect2 = Rect2()

	for position_value in board_positions:
		var board_position: Vector2 = position_value
		if not has_bounds:
			bounds = Rect2(board_position, Vector2.ZERO)
			has_bounds = true
		else:
			bounds = bounds.expand(board_position)

	if player != null:
		if not has_bounds:
			bounds = Rect2(player.global_position, Vector2.ZERO)
			has_bounds = true
		else:
			bounds = bounds.expand(player.global_position)

	if not has_bounds:
		return Rect2()

	return bounds

func _hide_dialog() -> void:
	if dialog_panel != null:
		dialog_panel.hide()

	if dialog_backdrop != null:
		dialog_backdrop.hide()

	_set_question_buttons_enabled(false)
	answering_locked = false

func _show_dialog() -> void:
	if dialog_panel == null:
		return

	if dialog_backdrop != null:
		dialog_backdrop.show()

	dialog_panel.show()
	canvas_layer.move_child(dialog_panel, canvas_layer.get_child_count() - 1)
	_set_question_buttons_enabled(true)
	answering_locked = false

	for button in _get_answer_buttons():
		if button != null and button.visible:
			button.grab_focus()
			break

func _set_question_buttons_enabled(enabled: bool) -> void:
	for button in _get_answer_buttons():
		if button != null:
			button.disabled = not enabled or not button.visible

func _get_answer_buttons() -> Array[Button]:
	return [button_a, button_b, button_c, button_d]

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
	if player == null:
		return
	if (dialog_panel != null and dialog_panel.visible) or get_tree().paused:
		return

	_set_turn_state(TurnState.SHOWING_QUESTION)
	rng_roll.randomize()
	var rng_roll: float = rng_roll.randf() #gera um numero aleatorio entre 0 e 1
	if rng_roll <= 0.1: current_roll = 6 #10%
	elif rng_roll <= 0.2: current_roll= 5	#20%
	elif rng_roll <= 0.3: current_roll= 4	#30%
	elif rng_roll <= 0.4: current_roll= 3	#40%
	elif rng_roll <= 0.5: current_roll= 2	#50%
	else: current_roll= 1	 # >50%
	
	pending_target_house = mini(player.current_house + current_roll, TOTAL_CASAS)

	if sprite_dado != null:
		sprite_dado.texture = dice_textures[current_roll - 1]

	_play_sfx("res://assets/audio/dice.mp3")
	_present_question(pending_target_house)

func _present_question(house_index: int) -> void:
	if dialog_panel == null:
		return

	var question: Dictionary = GameState.get_question_for_house(house_index)
	var options: Array = question.get("options", [])
	if options.is_empty():
		push_error("Pergunta selecionada sem alternativas.")
		_finalize_turn()
		return

	var order: Array[int] = []
	for index in range(options.size()):
		order.append(index)
	order.shuffle()
	pending_correct_index = order.find(int(question.get("correct_index", 0)))

	dialog_title_label.text = "Casa %d - Nivel %d" % [house_index, GameState.get_level_for_house(house_index)]
	question_label.text = str(question.get("text", ""))
	_update_question_hint(question)

	var buttons: Array[Button] = _get_answer_buttons()
	for index in range(buttons.size()):
		var button: Button = buttons[index]
		if button == null:
			continue

		if index < order.size():
			var option_index: int = order[index]
			button.text = "%s) %s" % [ANSWER_SLOT_LABELS[index], str(options[option_index])]
			button.show()
		else:
			button.hide()

	_fit_question_content(question_label.text, buttons)
	_show_dialog()

	if SettingsManager.subtitles_enabled:
		subtitle_label.text = "Leia a pergunta e escolha a resposta correta."

func _fit_question_content(question_text: String, buttons: Array[Button]) -> void:
	var question_length := question_text.length()
	var longest_answer_length := 0
	for button in buttons:
		if button != null and button.visible:
			longest_answer_length = maxi(longest_answer_length, button.text.length())

	var question_font_size := 24
	var question_height := QUESTION_BASE_HEIGHT
	if question_length > 170:
		question_font_size = 19
		question_height = QUESTION_EXTRA_TALL_HEIGHT
	elif question_length > 110:
		question_font_size = 21
		question_height = QUESTION_TALL_HEIGHT

	if question_label != null:
		UITheme.apply_font_only(question_label, question_font_size)
		question_label.custom_minimum_size.y = question_height

	var answer_font_size := 17
	var answer_height := ANSWER_BASE_HEIGHT
	if longest_answer_length > 150:
		answer_font_size = 15
		answer_height = ANSWER_ULTRA_TALL_HEIGHT
	elif longest_answer_length > 105:
		answer_font_size = 16
		answer_height = ANSWER_EXTRA_TALL_HEIGHT
	elif longest_answer_length > 70:
		answer_font_size = 16
		answer_height = ANSWER_TALL_HEIGHT

	for button in buttons:
		if button == null:
			continue
		button.custom_minimum_size.y = answer_height
		UITheme.apply_button(button, UITheme.BUTTON_SECONDARY, answer_font_size)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.set("autowrap_mode", TextServer.AUTOWRAP_WORD_SMART)
		button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		button.clip_text = false

	if answers_container != null:
		answers_container.add_theme_constant_override("separation", 6 if answer_height > ANSWER_TALL_HEIGHT else 8)
		var vbox := answers_container.get_parent() as VBoxContainer
		if vbox != null:
			vbox.add_theme_constant_override("separation", 9 if answer_height > ANSWER_BASE_HEIGHT else 14)

func _update_question_hint(question: Dictionary) -> void:
	var hints: Array[String] = []
	var subject: String = str(question.get("subject", "")).strip_edges()
	var time_limit: int = int(question.get("time_limit", 0))
	var points: int = int(question.get("points", 0))

	if not subject.is_empty():
		hints.append("Materia: %s" % subject)
	if time_limit > 0:
		hints.append("Tempo: %ds" % time_limit)
	if points > 0:
		hints.append("Valor: %d pts" % points)

	if hints.is_empty():
		question_hint_label.text = "Escolha a alternativa correta para seguir no tabuleiro."
	else:
		question_hint_label.text = "  |  ".join(hints)

func _on_answer_button_pressed(answer_slot: int) -> void:
	if turn_state != TurnState.SHOWING_QUESTION:
		return
	if dialog_panel == null or not dialog_panel.visible or answering_locked:
		return

	answering_locked = true
	_set_question_buttons_enabled(false)

	var correct: bool = answer_slot == pending_correct_index
	_hide_dialog()
	GameState.register_answer(correct, pending_target_house)
	await GameState.submit_answer_result(correct, pending_target_house)

	if correct:
		_set_turn_state(TurnState.MOVING_PLAYER)
		_show_feedback(GameState.last_feedback, FEEDBACK_OK)
		_play_sfx("res://assets/audio/correct.mp3")

		if SettingsManager.vfx_enabled:
			_pulse_feedback()

		if player != null:
			await player.move_to_house(pending_target_house)
	else:
		_show_feedback(GameState.last_feedback, FEEDBACK_FAIL)
		_play_sfx("res://assets/audio/wrong.wav")
		_finalize_turn()

	_refresh_hud()

func _pulse_feedback() -> void:
	if feedback_label == null:
		return

	var tween: Tween = create_tween()
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
	GameState.current_question.clear()

	if GameState.current_house >= TOTAL_CASAS:
		GameState.finish_session(true)
		get_tree().change_scene_to_file("res://scene/end_game_screen.tscn")
		return

	_set_turn_state(TurnState.WAITING_ROLL)

func _show_feedback(text_value: String, color_value: Color) -> void:
	if feedback_label != null:
		feedback_label.text = text_value
		feedback_label.add_theme_color_override("font_color", color_value)

	if subtitle_label != null:
		if SettingsManager.subtitles_enabled:
			subtitle_label.text = _build_feedback_subtitle()
		else:
			subtitle_label.text = ""

func _build_feedback_subtitle() -> String:
	var subtitle: String = GameState.last_feedback
	if not GameState.sync_warning.is_empty():
		subtitle = "%s | %s" % [subtitle, GameState.sync_warning]
	return subtitle

func _refresh_hud() -> void:
	if player_label != null:
		player_label.text = "Jogador: %s" % (GameState.player_name if not GameState.player_name.is_empty() else "Aluno")

	if room_label != null:
		room_label.text = "Sala: %s" % (GameState.room_code if not GameState.room_code.is_empty() else "Sem codigo")

	if score_label != null:
		score_label.text = "Score: %d" % GameState.score

	if level_label != null:
		level_label.text = "Nivel: %d" % GameState.level

	if progress_label != null:
		progress_label.text = "Casa: %d/%d" % [GameState.current_house, TOTAL_CASAS]

	if accuracy_label != null:
		accuracy_label.text = "Acertos: %d%%" % GameState.get_accuracy_percent()

	if subtitle_label != null:
		if SettingsManager.subtitles_enabled:
			subtitle_label.text = _build_feedback_subtitle()
		else:
			subtitle_label.text = ""

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		GameState.finish_session(false)
