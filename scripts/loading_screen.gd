extends Control

@onready var logo = $Logo
@onready var loading_card = $Content/Center/VBox/LoadingCard
@onready var subtitle: Label = $Content/Center/VBox/Subtitle
@onready var dot_1 = $Content/Center/VBox/LoadingCard/LoadingCenter/LoadingRow/Dot1
@onready var dot_2 = $Content/Center/VBox/LoadingCard/LoadingCenter/LoadingRow/Dot2
@onready var dot_3 = $Content/Center/VBox/LoadingCard/LoadingCenter/LoadingRow/Dot3

var _dot_base_y = {}

func _ready() -> void:
	SettingsManager.pause_tree_when_open = false
	SettingsManager.close_menu()
	_dot_base_y[dot_1] = dot_1.position.y
	_dot_base_y[dot_2] = dot_2.position.y
	_dot_base_y[dot_3] = dot_3.position.y

	if not GameState.player_name.is_empty():
		subtitle.text = "Preparando o tabuleiro para %s..." % GameState.player_name

	if not GameState.session_preparation_updated.is_connected(_on_session_preparation_updated):
		GameState.session_preparation_updated.connect(_on_session_preparation_updated)

	animate_logo()
	animate_loading_card()
	animate_dot(dot_1, 0.0)
	animate_dot(dot_2, 0.14)
	animate_dot(dot_3, 0.28)

	var result := await GameState.prepare_session()
	if not result.get("ok", false):
		await _show_startup_error(result.get("error", "Nao foi possivel iniciar a partida."))
		return

	await get_tree().create_timer(0.6).timeout
	get_tree().change_scene_to_file("res://scene/game.tscn")

func _exit_tree() -> void:
	if GameState.session_preparation_updated.is_connected(_on_session_preparation_updated):
		GameState.session_preparation_updated.disconnect(_on_session_preparation_updated)

func animate_logo() -> void:
	var base_scale = logo.scale
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(logo, "scale", base_scale * 1.02, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(logo, "scale", base_scale, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func animate_loading_card() -> void:
	var base_scale = loading_card.scale
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(loading_card, "scale", base_scale * 1.01, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(loading_card, "scale", base_scale, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func animate_dot(dot: Control, delay: float) -> void:
	var base_y = _dot_base_y[dot]
	var tween = create_tween()
	tween.set_loops()
	tween.tween_interval(delay)
	tween.tween_property(dot, "position:y", base_y - 8.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(dot, "position:y", base_y, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_interval(0.22)

func _on_session_preparation_updated(message: String) -> void:
	subtitle.text = message

func _show_startup_error(message: String) -> void:
	subtitle.text = message
	var dialog := AcceptDialog.new()
	add_child(dialog)
	dialog.title = "Falha ao iniciar"
	dialog.dialog_text = message
	dialog.popup_centered()
	await dialog.confirmed
	get_tree().change_scene_to_file("res://scene/tela_inicial.tscn")

func _on_timer_timeout() -> void:
	pass
