extends Control

# Cada avanço corresponde a uma etapa concluída, sem simular um percentual de download.
const UITheme := preload("res://scripts/UITheme.gd")
const SettingsButtonLayout := preload("res://ui/settings/SettingsButtonLayout.gd")
const GAME_SCENE := "res://scene/game.tscn"
const ENTRY_SCENE := "res://scene/tela_inicial.tscn"
const STEP_TITLES: Array[String] = ["Encontrar sua sala", "Preparar seu jogador", "Carregar as perguntas", "Organizar o tabuleiro"]
const STEP_MESSAGES: Array[String] = ["Conferindo o código da sua sala…", "Preparando seu lugar na partida…", "Buscando os desafios da sua turma…", "Organizando tudo para você começar…"]
const INK := Color("24334b")
const MUTED := Color("59677a")
const GOLD := Color("edbd52")
const SUCCESS := Color("287552")
const ERROR := Color("a63e3e")

@onready var card: PanelContainer = %Card
@onready var columns: BoxContainer = %Columns
@onready var hero_panel: PanelContainer = %HeroPanel
@onready var hero_content: BoxContainer = %HeroContent
@onready var hero_margin: MarginContainer = %HeroMargin
@onready var hero_logo: TextureRect = %Logo
@onready var avatar_stage: Control = %AvatarStage
@onready var character: TextureRect = %Character
@onready var character_name: Label = %CharacterName
@onready var hero_title: Label = %HeroTitle
@onready var content_margin: MarginContainer = %ContentMargin
@onready var title: Label = %Title
@onready var player_text: Label = %PlayerText
@onready var room_text: Label = %RoomText
@onready var status_text: Label = %StatusText
@onready var stage_counter: Label = %StageCounter
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var steps: VBoxContainer = %Steps
@onready var hint_text: Label = %HintText
@onready var actions: BoxContainer = %Actions
@onready var retry_button: Button = %RetryButton
@onready var back_button: Button = %BackButton
@onready var safe_area: MarginContainer = %SafeArea
@onready var scroll: ScrollContainer = %Scroll
@onready var content: VBoxContainer = %Content
@onready var divider: ColorRect = %Divider

var _step_rows: Array[PanelContainer] = []
var _step_numbers: Array[Label] = []
var _step_labels: Array[Label] = []
var _step_states: Array[Label] = []
var _progress_tween: Tween
var _entrance_tween: Tween
var _progress_target := 0.0
var _current_step := 0
var _busy := false
var _failed := false
var _finished := false
var _leaving := false
var _waiting_seconds := 0.0
var _pulse_time := 0.0


func _ready() -> void:
	SettingsManager.pause_tree_when_open = false
	SettingsManager.close_menu()
	_apply_typography()
	_build_steps()
	var texture_path := GameState.get_selected_character_texture_path()
	if ResourceLoader.exists(texture_path):
		character.texture = load(texture_path) as Texture2D
	character_name.text = "Seu personagem: %s" % GameState.get_selected_character_name()
	player_text.text = "Vamos começar uma nova descoberta!" if GameState.player_name.is_empty() else "%s, a aventura já vai começar." % GameState.player_name
	player_text.tooltip_text = player_text.text
	var room_badge := _format_room_badge(GameState.room_code)
	room_text.text = room_badge["label"]
	room_text.tooltip_text = room_badge["tooltip"]
	retry_button.pressed.connect(_on_retry_pressed)
	back_button.pressed.connect(_on_back_pressed)
	GameState.session_preparation_updated.connect(_on_session_preparation_updated)
	SettingsManager.settings_changed.connect(_on_settings_changed)
	SettingsManager.font_scale_changed.connect(_on_font_scale_changed)
	get_viewport().size_changed.connect(_update_responsive_layout)
	_update_responsive_layout()
	if SettingsManager.vfx_enabled:
		card.modulate.a = 0.0
		_entrance_tween = create_tween()
		_entrance_tween.tween_property(card, "modulate:a", 1.0, 0.28)
	_begin_preparation()


func _apply_typography() -> void:
	# A fonte do jogo fica nos títulos; textos de apoio usam a fonte de leitura da interface.
	UITheme.apply_title(title, 38, INK)
	UITheme.apply_title(hero_title, 25, Color("fff5da"))
	UITheme.apply_button(retry_button, UITheme.BUTTON_PRIMARY, 16)
	UITheme.apply_button(back_button, UITheme.BUTTON_SURFACE, 16)


func _build_steps() -> void:
	for index in range(STEP_TITLES.size()):
		var row := PanelContainer.new()
		row.name = "Step%d" % (index + 1)
		steps.add_child(row)
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 12)
		row.add_child(line)
		var number := Label.new()
		number.custom_minimum_size.x = 28
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		line.add_child(number)
		var label := Label.new()
		label.text = STEP_TITLES[index]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.add_child(label)
		var state := Label.new()
		line.add_child(state)
		for item in [number, label, state]:
			AccessibilityManager.apply_font_size(item, 16 if item != state else 13)
		_step_rows.append(row)
		_step_numbers.append(number)
		_step_labels.append(label)
		_step_states.append(state)


func _begin_preparation() -> void:
	# O retry só é liberado depois de a tentativa anterior terminar.
	if _busy or _leaving:
		return
	_busy = true
	_failed = false
	_finished = false
	_current_step = 0
	_progress_target = 0.0
	_waiting_seconds = 0.0
	_stop_progress_tween()
	progress_bar.value = 0.0
	progress_bar.add_theme_stylebox_override("fill", _bar_style(GOLD))
	_set_title("Preparando\nsua jornada")
	actions.hide()
	player_text.show()
	hint_text.show()
	divider.show()
	scroll.scroll_vertical = 0
	retry_button.disabled = true
	back_button.disabled = true
	hint_text.text = "Dica: leia cada pergunta com atenção antes de escolher sua resposta."
	_set_step(0)
	var result: Dictionary = await GameState.prepare_session()
	if _leaving or not is_inside_tree():
		return
	if not result.get("ok", false):
		_show_startup_error(str(result.get("error", "")))
		return
	_set_step(3)
	# Carrega a cena sem bloquear a animação e só conclui a barra quando ela estiver pronta.
	var request_error := ResourceLoader.load_threaded_request(GAME_SCENE)
	if request_error != OK:
		_show_startup_error("tabuleiro")
		return
	while ResourceLoader.load_threaded_get_status(GAME_SCENE) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		await get_tree().process_frame
		if _leaving or not is_inside_tree():
			return
	if ResourceLoader.load_threaded_get_status(GAME_SCENE) != ResourceLoader.THREAD_LOAD_LOADED:
		_show_startup_error("tabuleiro")
		return
	var game_scene := ResourceLoader.load_threaded_get(GAME_SCENE) as PackedScene
	if game_scene == null:
		_show_startup_error("tabuleiro")
		return
	_finished = true
	_set_title("Tudo pronto.\nVamos começar!")
	status_text.text = "Sua turma e seus desafios estão esperando."
	stage_counter.text = "4 DE 4 ETAPAS CONCLUÍDAS"
	hint_text.text = "Boa jornada e boas descobertas!"
	_update_steps()
	_animate_progress_to(100.0)
	await get_tree().create_timer(0.4).timeout
	if _leaving or not is_inside_tree():
		return
	SettingsManager.close_menu()
	var scene_error := get_tree().change_scene_to_packed(game_scene)
	if scene_error != OK:
		_show_startup_error("tabuleiro")


func _on_session_preparation_updated(message: String) -> void:
	if not _busy or _leaving or _failed:
		return
	# O GameState valida a sala antes de criar o jogador; esta ordem não pode retroceder.
	if message.begins_with("Validando"):
		_set_step(0)
	elif message.begins_with("Conectando"):
		_set_step(1)
	elif message.begins_with("Carregando"):
		_set_step(2)
	elif message.begins_with("Tudo pronto"):
		_set_step(3)


func _set_step(index: int) -> void:
	_current_step = maxi(_current_step, index)
	_waiting_seconds = 0.0
	status_text.text = STEP_MESSAGES[_current_step]
	status_text.add_theme_color_override("font_color", MUTED)
	stage_counter.text = "ETAPA %d DE 4" % (_current_step + 1)
	hint_text.text = "Dica: leia cada pergunta com atenção antes de escolher sua resposta."
	_update_steps()
	_animate_progress_to(float(_current_step) * 25.0)
	_reveal_current_step.call_deferred()


func _update_steps() -> void:
	for index in range(_step_rows.size()):
		var complete := _finished or index < _current_step
		var active := not _finished and index == _current_step
		var color := SUCCESS if complete else (INK if active else MUTED)
		var background := Color("edf5ef") if complete else Color(0, 0, 0, 0)
		var border := Color(0, 0, 0, 0)
		if active:
			background = Color("fff2d4")
			border = Color("e8cd91")
		if active and _failed:
			color = ERROR
			background = Color("fceeee")
			border = Color("edc5c5")
		var style := StyleBoxFlat.new()
		style.bg_color = background
		style.border_color = border
		style.set_border_width_all(1)
		style.set_corner_radius_all(10)
		style.content_margin_left = 10
		style.content_margin_right = 12
		style.content_margin_top = 7 if get_viewport_rect().size.y < 800.0 else 10
		style.content_margin_bottom = style.content_margin_top
		_step_rows[index].add_theme_stylebox_override("panel", style)
		_step_numbers[index].text = "✓" if complete else ("!" if active and _failed else "%02d" % (index + 1))
		_step_numbers[index].modulate.a = 1.0
		_step_states[index].text = "Concluído" if complete else ("Revisar" if active and _failed else ("Agora" if active else ""))
		for item in [_step_numbers[index], _step_labels[index], _step_states[index]]:
			item.add_theme_color_override("font_color", color)


func _animate_progress_to(target: float) -> void:
	_progress_target = maxf(_progress_target, target)
	_stop_progress_tween()
	if not SettingsManager.vfx_enabled:
		progress_bar.value = _progress_target
		return
	_progress_tween = create_tween()
	_progress_tween.tween_property(progress_bar, "value", _progress_target, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _stop_progress_tween() -> void:
	if _progress_tween != null and _progress_tween.is_valid():
		_progress_tween.kill()


func _bar_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(6)
	return style


func _show_startup_error(message: String) -> void:
	_busy = false
	_failed = true
	_finished = false
	_stop_progress_tween()
	_progress_target = float(_current_step) * 25.0
	progress_bar.value = _progress_target
	progress_bar.add_theme_stylebox_override("fill", _bar_style(ERROR))
	_set_title("Vamos tentar\nmais uma vez?")
	if "nao possui perguntas" in message or "não possui perguntas" in message:
		status_text.text = "Esta sala ainda não tem perguntas disponíveis. Avise seu professor."
	elif _current_step == 0:
		status_text.text = "Não foi possível acessar a sala. Confira o código e sua conexão."
	elif _current_step == 3:
		status_text.text = "Não foi possível abrir o tabuleiro. Tente novamente para continuar."
	else:
		status_text.text = "Não foi possível concluir esta etapa. Confira sua conexão e tente novamente."
	status_text.add_theme_color_override("font_color", ERROR)
	stage_counter.text = "PREPARAÇÃO INTERROMPIDA"
	player_text.hide()
	hint_text.hide()
	divider.hide()
	_update_steps()
	actions.show()
	retry_button.disabled = false
	back_button.disabled = false
	_focus_recovery_actions.call_deferred()


func _focus_recovery_actions() -> void:
	# Aguarda o novo tamanho do conteúdo para não focar um botão fora da área visível.
	await get_tree().process_frame
	if _leaving or not is_inside_tree() or not _failed:
		return
	# O menu global mantém o foco enquanto estiver aberto; a ação volta a ser focada ao fechar.
	var overlay = SettingsManager.overlay
	if overlay != null and is_instance_valid(overlay) and overlay.has_method("is_open") and overlay.is_open():
		var callback := Callable(self, "_focus_recovery_actions")
		if overlay.has_signal("menu_closed") and not overlay.is_connected("menu_closed", callback):
			overlay.connect("menu_closed", callback, CONNECT_ONE_SHOT)
		return
	retry_button.grab_focus()
	scroll.ensure_control_visible(actions)


func _reveal_current_step() -> void:
	await get_tree().process_frame
	if _leaving or not is_inside_tree() or _failed:
		return
	scroll.ensure_control_visible(_step_rows[_current_step])


func _set_title(text: String) -> void:
	var viewport_size := get_viewport_rect().size
	title.text = text.replace("\n", " ") if viewport_size.x < 920.0 or viewport_size.y < 800.0 else text


func _format_room_badge(code: String) -> Dictionary:
	var normalized := code.strip_edges().to_upper()
	if normalized.is_empty():
		return {"label": "SUA SALA", "tooltip": ""}
	var visible_code := normalized if normalized.length() <= 12 else "%s…" % normalized.left(12)
	return {
		"label": "SALA  %s" % visible_code,
		"tooltip": "Código completo: %s" % normalized,
	}


func _on_retry_pressed() -> void:
	if _failed and not _busy:
		_begin_preparation()


func _on_back_pressed() -> void:
	if _busy or _leaving:
		return
	_leaving = true
	SettingsManager.close_menu()
	get_tree().change_scene_to_file(ENTRY_SCENE)


func _process(delta: float) -> void:
	if not _busy or _finished:
		return
	_waiting_seconds += delta
	if _waiting_seconds >= 8.0 and _current_step < 3:
		hint_text.text = "Está demorando um pouco. Estamos aguardando a conexão com sua sala."
	if SettingsManager.vfx_enabled:
		_pulse_time += delta
		_step_numbers[_current_step].modulate.a = 0.78 + 0.22 * sin(_pulse_time * 3.0)


func _on_settings_changed() -> void:
	if not SettingsManager.vfx_enabled:
		if _entrance_tween != null and _entrance_tween.is_valid():
			_entrance_tween.kill()
		card.modulate.a = 1.0
		_stop_progress_tween()
		progress_bar.value = _progress_target
		for number in _step_numbers:
			number.modulate.a = 1.0


func _on_font_scale_changed(_value: float) -> void:
	_update_responsive_layout()


func _update_responsive_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var compact := viewport_size.x < 920.0
	var short_window := viewport_size.y < 800.0
	var padding := 20 if compact or short_window else 40
	# Em telas estreitas, a engrenagem fica numa faixa inferior reservada.
	var side_margin := 16 if compact else 40
	safe_area.add_theme_constant_override("margin_left", side_margin)
	safe_area.add_theme_constant_override("margin_right", side_margin)
	safe_area.add_theme_constant_override("margin_top", 20 if compact else 32)
	safe_area.add_theme_constant_override("margin_bottom", int(SettingsButtonLayout.CONTENT_SAFE_MARGIN) if compact else 32)
	var available_width := viewport_size.x - float(side_margin * 2) - 12.0
	if not compact:
		available_width = SettingsButtonLayout.fit_centered_content_width(viewport_size.x, 1100.0)
	card.custom_minimum_size.x = minf(1100.0, maxf(240.0, available_width))
	columns.vertical = compact
	hero_content.vertical = not compact
	hero_panel.custom_minimum_size.x = 0.0 if compact else (280.0 if short_window else 340.0)
	hero_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL if compact else Control.SIZE_FILL
	hero_logo.visible = not compact
	hero_title.text = "Aprender é\numa aventura." if not compact else "Aprender é uma aventura."
	hero_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if compact else HORIZONTAL_ALIGNMENT_CENTER
	character_name.horizontal_alignment = hero_title.horizontal_alignment
	avatar_stage.custom_minimum_size = Vector2(68, 76) if compact else Vector2(0, 192 if short_window else 256)
	hero_logo.custom_minimum_size.y = 110.0 if short_window else 135.0
	avatar_stage.size_flags_horizontal = Control.SIZE_FILL if compact else Control.SIZE_EXPAND_FILL
	avatar_stage.size_flags_vertical = Control.SIZE_FILL if compact else Control.SIZE_EXPAND_FILL
	for edge in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		content_margin.add_theme_constant_override(edge, padding)
		hero_margin.add_theme_constant_override(edge, 16 if compact else 28)
	actions.vertical = viewport_size.x < 600.0
	content.add_theme_constant_override("separation", 12 if short_window else 16)
	UITheme.apply_title(title, 30 if compact or short_window else 38, INK)
	UITheme.apply_title(hero_title, 19 if compact else 25, Color("fff5da"))
	_set_title("Vamos tentar\nmais uma vez?" if _failed else ("Tudo pronto.\nVamos começar!" if _finished else "Preparando\nsua jornada"))
	_update_steps()
	if _failed:
		_focus_recovery_actions.call_deferred()


func _exit_tree() -> void:
	_leaving = true
	_stop_progress_tween()
	if GameState.session_preparation_updated.is_connected(_on_session_preparation_updated):
		GameState.session_preparation_updated.disconnect(_on_session_preparation_updated)
	if SettingsManager.settings_changed.is_connected(_on_settings_changed):
		SettingsManager.settings_changed.disconnect(_on_settings_changed)
	if SettingsManager.font_scale_changed.is_connected(_on_font_scale_changed):
		SettingsManager.font_scale_changed.disconnect(_on_font_scale_changed)
