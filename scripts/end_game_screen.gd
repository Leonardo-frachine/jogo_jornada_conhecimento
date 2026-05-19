extends Control

const ACCESS_SCENE_PATH := "res://scene/selecao_perfil.tscn"
const LOADING_SCENE_PATH := "res://scene/loading_screen.tscn"
const SCORE_ANIMATION_DURATION := 0.9
const HIGH_PERFORMANCE_THRESHOLD := 80
const MEDIUM_PERFORMANCE_THRESHOLD := 50

@onready var painel_central: Panel = $PainelCentral
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
	_connect_buttons()
	_apply_session_data()
	_prepare_intro_state()
	_play_intro_animation()
	_animate_score_value()
	animate_logo()
	animate_character()

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
	character.modulate = Color(1, 1, 1, 0)

func _play_intro_animation() -> void:
	var tween := create_tween()
	tween.tween_property(painel_central, "modulate", Color.WHITE, 0.24)
	tween.parallel().tween_property(painel_central, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
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
