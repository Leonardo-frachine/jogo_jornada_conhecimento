extends Control

const UITheme := preload("res://scripts/UITheme.gd")
const ACCESS_SCENE_PATH := "res://scene/selecao_perfil.tscn"
const LOADING_SCENE_PATH := "res://scene/loading_screen.tscn"
const SCORE_ANIMATION_DURATION := 0.9
const HIGH_PERFORMANCE_THRESHOLD := 80
const MEDIUM_PERFORMANCE_THRESHOLD := 50

@onready var painel_central: Panel = $PainelCentral
@onready var panel_margin: MarginContainer = $PainelCentral/MarginContainer
@onready var main_vbox: VBoxContainer = $PainelCentral/MarginContainer/MainVBox
@onready var header_box: VBoxContainer = $PainelCentral/MarginContainer/MainVBox/HeaderBox
@onready var logo: TextureRect = find_child("Logo", true, false) as TextureRect
@onready var title_label: Label = find_child("Title", true, false) as Label
@onready var badge_text: Label = find_child("BadgeText", true, false) as Label
@onready var content_row: HBoxContainer = $PainelCentral/MarginContainer/MainVBox/ContentRow
@onready var metrics_row: HBoxContainer = $PainelCentral/MarginContainer/MainVBox/MetricsRow
@onready var buttons_row: HBoxContainer = $PainelCentral/MarginContainer/MainVBox/ButtonsRow
@onready var character: TextureRect = find_child("Character", true, false) as TextureRect
@onready var subtitle: Label = find_child("Subtitle", true, false) as Label
@onready var result_value: Label = $PainelCentral/MarginContainer/MainVBox/ContentRow/ScoreHeroCard/HeroMargin/HeroVBox/ResultValue
@onready var performance_seal_text: Label = $PainelCentral/MarginContainer/MainVBox/ContentRow/ScoreHeroCard/HeroMargin/HeroVBox/PerformanceSeal/PerformanceSealText
@onready var performance_message: Label = $PainelCentral/MarginContainer/MainVBox/ContentRow/ScoreHeroCard/HeroMargin/HeroVBox/PerformanceMessage
@onready var accuracy_value: Label = $PainelCentral/MarginContainer/MainVBox/ContentRow/SummaryCard/SummaryMargin/SummaryVBox/AccuracyRow/AccuracyValue
@onready var level_value: Label = $PainelCentral/MarginContainer/MainVBox/ContentRow/SummaryCard/SummaryMargin/SummaryVBox/LevelRow/LevelValue
@onready var answered_summary_value: Label = $PainelCentral/MarginContainer/MainVBox/ContentRow/SummaryCard/SummaryMargin/SummaryVBox/AnsweredRow/AnsweredSummaryValue
@onready var ranking_status: Label = $PainelCentral/MarginContainer/MainVBox/ContentRow/RankingCard/RankingMargin/RankingVBox/RankingStatus
@onready var ranking_list: VBoxContainer = $PainelCentral/MarginContainer/MainVBox/ContentRow/RankingCard/RankingMargin/RankingVBox/RankingScroll/RankingList
@onready var score_card: Panel = $PainelCentral/MarginContainer/MainVBox/ContentRow/ScoreHeroCard
@onready var summary_card: Panel = $PainelCentral/MarginContainer/MainVBox/ContentRow/SummaryCard
@onready var ranking_card: Panel = $PainelCentral/MarginContainer/MainVBox/ContentRow/RankingCard
@onready var answered_value: Label = $PainelCentral/MarginContainer/MainVBox/MetricsRow/DetailRespondidas/MarginRespondidas/VBoxRespondidas/AnsweredValue
@onready var correct_value: Label = $PainelCentral/MarginContainer/MainVBox/MetricsRow/DetailCertas/MarginCertas/VBoxCertas/CorrectValue
@onready var wrong_value: Label = $PainelCentral/MarginContainer/MainVBox/MetricsRow/DetailErros/MarginErros/VBoxErros/WrongValue
@onready var botao_jogar_novamente: Button = $PainelCentral/MarginContainer/MainVBox/ButtonsRow/BotaoJogarNovamente
@onready var botao_menu_principal: Button = $PainelCentral/MarginContainer/MainVBox/ButtonsRow/BotaoMenuPrincipal
@onready var botao_configuracao: TextureButton = $BotaoConfiguracao

var _final_score := 0
var _final_accuracy := 0

func _ready() -> void:
	SettingsManager.pause_tree_when_open = false
	SettingsManager.close_menu()
	_apply_visual_refresh()
	_connect_buttons()
	_apply_session_data()
	_prepare_intro_state()
	_play_intro_animation()
	_animate_score_value()
	animate_logo()
	animate_character()
	_update_responsive_layout()
	if not get_viewport().size_changed.is_connected(_update_responsive_layout):
		get_viewport().size_changed.connect(_update_responsive_layout)
	if not SettingsManager.font_scale_changed.is_connected(_on_font_scale_changed):
		SettingsManager.font_scale_changed.connect(_on_font_scale_changed)
	call_deferred("_load_room_ranking")

func _apply_visual_refresh() -> void:
	UITheme.apply_font_tree(painel_central)
	UITheme.apply_title(title_label, 42, title_label.get_theme_color("font_color"))
	if badge_text != null:
		UITheme.apply_subtitle(badge_text, 17, badge_text.get_theme_color("font_color"))
	if subtitle != null:
		UITheme.apply_subtitle(subtitle, 18, subtitle.get_theme_color("font_color"))
	UITheme.apply_font_only(result_value, 64)
	UITheme.apply_font_only(performance_seal_text, 26)
	UITheme.apply_font_only(performance_message, 20)
	UITheme.apply_font_only(accuracy_value, 20)
	UITheme.apply_font_only(level_value, 20)
	UITheme.apply_font_only(answered_summary_value, 20)
	UITheme.apply_font_only(ranking_status, 16)
	UITheme.apply_font_only(answered_value, 34)
	UITheme.apply_font_only(correct_value, 34)
	UITheme.apply_font_only(wrong_value, 34)
	UITheme.apply_button(botao_jogar_novamente, UITheme.BUTTON_PRIMARY, 20)
	UITheme.apply_button(botao_menu_principal, UITheme.BUTTON_SECONDARY, 20)
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if subtitle != null:
		subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ranking_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _update_responsive_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var font_scale := SettingsManager.font_scale
	var panel_width := minf(viewport_size.x - 40.0, 1180.0)
	var panel_height := minf(viewport_size.y - 24.0, 780.0)
	painel_central.custom_minimum_size = Vector2(panel_width, panel_height)
	painel_central.offset_left = -panel_width * 0.5
	painel_central.offset_right = panel_width * 0.5
	painel_central.offset_top = -panel_height * 0.5
	painel_central.offset_bottom = panel_height * 0.5

	var compact_height := viewport_size.y <= 760.0 or font_scale > 1.15
	var horizontal_margin := 20 if compact_height else 34
	var vertical_margin := 14 if compact_height else 28
	panel_margin.add_theme_constant_override("margin_left", horizontal_margin)
	panel_margin.add_theme_constant_override("margin_top", vertical_margin)
	panel_margin.add_theme_constant_override("margin_right", horizontal_margin)
	panel_margin.add_theme_constant_override("margin_bottom", vertical_margin)
	main_vbox.add_theme_constant_override("separation", 10 if compact_height else 18)
	header_box.add_theme_constant_override("separation", 4 if compact_height else 8)

	var card_height := 260.0 + roundf(70.0 * (font_scale - 1.0))
	score_card.custom_minimum_size.y = card_height
	summary_card.custom_minimum_size.y = card_height
	ranking_card.custom_minimum_size.y = card_height
	character.visible = not compact_height and viewport_size.x >= 1500.0

func _on_font_scale_changed(_value: float) -> void:
	call_deferred("_update_responsive_layout")

func _apply_session_data() -> void:
	_final_score = GameState.score
	_final_accuracy = GameState.get_accuracy_percent()
	result_value.text = "0"
	accuracy_value.text = "%d%%" % _final_accuracy
	level_value.text = str(GameState.level)
	answered_value.text = str(GameState.questions_answered)
	answered_summary_value.text = answered_value.text
	correct_value.text = str(GameState.correct_answers)
	wrong_value.text = str(GameState.wrong_answers)
	performance_message.text = _get_performance_message(_final_accuracy)
	performance_message.add_theme_color_override("font_color", _get_performance_color(_final_accuracy))
	performance_seal_text.text = _get_performance_seal(_final_accuracy)

	if GameState.victory:
		if badge_text != null:
			badge_text.text = "JORNADA CONCLUIDA"
		if title_label != null:
			title_label.text = "Jornada Concluida"
		if subtitle != null:
			subtitle.text = "%s concluiu a jornada com sucesso. Veja como foi o desempenho final." % [_get_player_display_name()]
	else:
		if badge_text != null:
			badge_text.text = "FIM DA PARTIDA"
		if title_label != null:
			title_label.text = "Partida Encerrada"
		if subtitle != null:
			subtitle.text = "%s encerrou a partida. Revise o resultado e tente novamente para evoluir." % [_get_player_display_name()]

func _load_room_ranking() -> void:
	_clear_ranking()
	if GameState.resolved_room_id <= 0:
		_show_ranking_message("Ranking disponivel apenas para partidas vinculadas a uma sala.")
		return

	ranking_status.text = "Carregando alunos finalizados..."
	var response: Dictionary = await ApiClient.fetch_room_ranking(GameState.resolved_room_id)
	if not is_inside_tree():
		return
	if not response.get("ok", false):
		_show_ranking_message(response.get("error", "Nao foi possivel carregar o ranking."))
		return

	var payload: Dictionary = response.get("data", {})
	_render_room_ranking(_extract_ranking(payload.get("ranking", [])))

func _render_room_ranking(items: Array[Dictionary]) -> void:
	_clear_ranking()
	var finalizados: Array[Dictionary] = []
	var jogadores_exibidos := {}
	for item in items:
		if str(item.get("statusPartida", "")).to_lower() != "finalizado":
			continue
		var jogador_id := int(item.get("jogadorId", 0))
		if jogador_id <= 0 or jogadores_exibidos.has(jogador_id):
			continue
		jogadores_exibidos[jogador_id] = true
		finalizados.append(item)

	if finalizados.is_empty():
		_show_ranking_message("Nenhum aluno finalizou a jornada nesta sala ainda.")
		return

	ranking_status.text = "%d alunos com partida finalizada." % finalizados.size()
	for item in finalizados:
		ranking_list.add_child(_create_ranking_row(item))

func _create_ranking_row(item: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 48)
	row.add_theme_constant_override("separation", 8)
	var is_current_player := int(item.get("jogadorId", 0)) == GameState.player_id
	var text_color := Color(0.50, 0.32, 0.06, 1.0) if is_current_player else Color(0.12, 0.16, 0.27, 1.0)

	var position_label := Label.new()
	position_label.custom_minimum_size = Vector2(34, 0)
	position_label.text = "#%d" % int(item.get("posicao", 0))
	UITheme.apply_font_only(position_label, 18)
	position_label.add_theme_color_override("font_color", text_color)
	row.add_child(position_label)

	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 0)
	var name_label := Label.new()
	name_label.text = str(item.get("nome", "Aluno"))
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.apply_font_only(name_label, 16)
	name_label.add_theme_color_override("font_color", text_color)
	identity.add_child(name_label)
	var status_label := Label.new()
	status_label.text = "Finalizado%s" % (" | Voce" if is_current_player else "")
	UITheme.apply_font_only(status_label, 14)
	status_label.add_theme_color_override("font_color", Color(0.15, 0.60, 0.38, 1.0))
	identity.add_child(status_label)
	row.add_child(identity)

	var score_label := Label.new()
	score_label.custom_minimum_size = Vector2(72, 0)
	score_label.text = "%d pts" % int(item.get("pontuacao", 0))
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UITheme.apply_font_only(score_label, 16)
	score_label.add_theme_color_override("font_color", text_color)
	row.add_child(score_label)
	return row

func _show_ranking_message(message: String) -> void:
	ranking_status.text = message
	var label := Label.new()
	label.text = "Aguardando resultados da sala."
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.apply_font_only(label, 15)
	label.add_theme_color_override("font_color", Color(0.22, 0.29, 0.43, 1.0))
	ranking_list.add_child(label)

func _clear_ranking() -> void:
	for child in ranking_list.get_children():
		ranking_list.remove_child(child)
		child.queue_free()

func _extract_ranking(payload: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if payload is Array:
		for item in payload:
			if item is Dictionary:
				result.append(item)
	return result

func _connect_buttons() -> void:
	if not botao_jogar_novamente.pressed.is_connected(_on_play_again_pressed):
		botao_jogar_novamente.pressed.connect(_on_play_again_pressed)
	if not botao_menu_principal.pressed.is_connected(_on_main_menu_pressed):
		botao_menu_principal.pressed.connect(_on_main_menu_pressed)
	if not botao_configuracao.pressed.is_connected(_on_settings_pressed):
		botao_configuracao.pressed.connect(_on_settings_pressed)

func _prepare_intro_state() -> void:
	painel_central.modulate = Color(1, 1, 1, 0)
	painel_central.scale = Vector2(0.96, 0.96)
	content_row.modulate = Color(1, 1, 1, 0)
	content_row.scale = Vector2(0.98, 0.98)
	metrics_row.modulate = Color(1, 1, 1, 0)
	buttons_row.modulate = Color(1, 1, 1, 0)
	buttons_row.scale = Vector2(0.96, 0.96)
	if character != null:
		character.modulate = Color(1, 1, 1, 0)

func _play_intro_animation() -> void:
	var tween := create_tween()
	tween.tween_property(painel_central, "modulate", Color.WHITE, 0.24)
	tween.parallel().tween_property(painel_central, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if character != null:
		tween.parallel().tween_property(character, "modulate", Color.WHITE, 0.30)
	tween.chain().tween_property(content_row, "modulate", Color.WHITE, 0.18)
	tween.parallel().tween_property(content_row, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(metrics_row, "modulate", Color.WHITE, 0.16)
	tween.chain().tween_property(buttons_row, "modulate", Color.WHITE, 0.16)
	tween.parallel().tween_property(buttons_row, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _animate_score_value() -> void:
	var tween := create_tween()
	tween.tween_method(Callable(self, "_update_score_value"), 0.0, float(_final_score), SCORE_ANIMATION_DURATION)
	tween.finished.connect(_pulse_score_value)

func _update_score_value(value: float) -> void:
	result_value.text = str(int(round(value)))

func _pulse_score_value() -> void:
	var tween := create_tween()
	tween.tween_property(result_value, "scale", Vector2(1.08, 1.08), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(result_value, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _get_player_display_name() -> String:
	return GameState.player_name if not GameState.player_name.is_empty() else "O aluno"

func _get_performance_message(accuracy: int) -> String:
	if accuracy >= HIGH_PERFORMANCE_THRESHOLD:
		return "Excelente! Voce mandou muito bem!"
	if accuracy >= MEDIUM_PERFORMANCE_THRESHOLD:
		return "Bom trabalho! Continue praticando."
	return "Nao desanime! Tente novamente para melhorar."

func _get_performance_seal(accuracy: int) -> String:
	if accuracy >= HIGH_PERFORMANCE_THRESHOLD:
		return "A+"
	if accuracy >= MEDIUM_PERFORMANCE_THRESHOLD:
		return "B"
	return "C"

func _get_performance_color(accuracy: int) -> Color:
	if accuracy >= HIGH_PERFORMANCE_THRESHOLD:
		return Color(1.0, 0.92549, 0.709804, 1.0)
	if accuracy >= MEDIUM_PERFORMANCE_THRESHOLD:
		return Color(0.905882, 0.956863, 1.0, 1.0)
	return Color(1.0, 0.87451, 0.756863, 1.0)

func animate_logo() -> void:
	if logo == null:
		return
	var base_scale = logo.scale
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(logo, "scale", base_scale * 1.02, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(logo, "scale", base_scale, 0.85).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func animate_character() -> void:
	if character == null:
		return
	var base_y = character.position.y
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(character, "position:y", base_y - 8.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(character, "position:y", base_y, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_play_again_pressed() -> void:
	var player_name := GameState.player_name
	var room_code := GameState.room_code
	SettingsManager.close_menu()
	GameState.start_session(player_name, room_code)
	get_tree().change_scene_to_file(LOADING_SCENE_PATH)

func _on_main_menu_pressed() -> void:
	SettingsManager.close_menu()
	GameState.reset_run_stats()
	get_tree().change_scene_to_file(ACCESS_SCENE_PATH)

func _on_settings_pressed() -> void:
	SettingsManager.open_menu()
