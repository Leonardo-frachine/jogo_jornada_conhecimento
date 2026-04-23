extends Control

@onready var logo = find_child("Title", true, false)
@onready var character = find_child("Character", true, false)
@onready var subtitle: Label = $Content/Center/MainPanel/Inner/VBox/Subtitle
@onready var result_value: Label = $Content/Center/MainPanel/Inner/VBox/StatsRow/Card1/Card1V/Card1Value
@onready var accuracy_value: Label = $Content/Center/MainPanel/Inner/VBox/StatsRow/Card3/Card3V/Card3Value
@onready var level_value: Label = $Content/Center/MainPanel/Inner/VBox/StatsRow/Card4/Card4V/Card4Value
@onready var answered_value: Label = $Content/Center/MainPanel/Inner/VBox/DetailsPanel/DetailsInner/DetailsVBox/DetailsStats/D1/D1Value
@onready var correct_value: Label = $Content/Center/MainPanel/Inner/VBox/DetailsPanel/DetailsInner/DetailsVBox/DetailsStats/D2/D2Value
@onready var wrong_value: Label = $Content/Center/MainPanel/Inner/VBox/DetailsPanel/DetailsInner/DetailsVBox/DetailsStats/D3/D3Value

func _ready() -> void:
	SettingsManager.pause_tree_when_open = false
	SettingsManager.close_menu()
	_apply_session_data()
	if logo:
		animate_logo()
	if character:
		animate_character()

func _apply_session_data() -> void:
	result_value.text = str(GameState.score)
	accuracy_value.text = "%d%%" % GameState.get_accuracy_percent()
	level_value.text = str(GameState.level)
	answered_value.text = str(GameState.questions_answered)
	correct_value.text = str(GameState.correct_answers)
	wrong_value.text = str(GameState.wrong_answers)

	if GameState.victory:
		subtitle.text = "%s concluiu a jornada com sucesso!" % (GameState.player_name if not GameState.player_name.is_empty() else "O jogador")
	else:
		subtitle.text = "Partida encerrada. Revise as respostas e tente novamente."

func animate_logo() -> void:
	var base_y = logo.position.y
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(logo, "position:y", base_y - 6.0, 0.95).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(logo, "position:y", base_y, 0.95).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func animate_character() -> void:
	var base_y = character.position.y
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(character, "position:y", base_y - 8.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(character, "position:y", base_y, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_restart_pressed() -> void:
	GameState.reset_run_stats()
	get_tree().change_scene_to_file("res://scene/tela_inicial.tscn")
