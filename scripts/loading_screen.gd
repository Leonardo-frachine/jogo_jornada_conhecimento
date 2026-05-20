extends Control

@onready var logo: TextureRect = $PainelCentral/MarginContainer/VBoxContainer/Logo
@onready var loading_card: Panel = $PainelCentral/MarginContainer/VBoxContainer/LoadingCard
@onready var subtitle: Label = $PainelCentral/MarginContainer/VBoxContainer/Subtitle
@onready var hint_text: Label = $PainelCentral/MarginContainer/VBoxContainer/HintText
@onready var dot_1: Label = $PainelCentral/MarginContainer/VBoxContainer/LoadingCard/LoadingCenter/LoadingRow/Dot1
@onready var dot_2: Label = $PainelCentral/MarginContainer/VBoxContainer/LoadingCard/LoadingCenter/LoadingRow/Dot2
@onready var dot_3: Label = $PainelCentral/MarginContainer/VBoxContainer/LoadingCard/LoadingCenter/LoadingRow/Dot3
@onready var personagem: TextureRect = $Personagem
@onready var progress_bar: ProgressBar = $PainelCentral/MarginContainer/VBoxContainer/ProgressSection/ProgressBar
@onready var step_1: Panel = $PainelCentral/MarginContainer/VBoxContainer/ProgressSection/StepsContainer/Step1
@onready var step_2: Panel = $PainelCentral/MarginContainer/VBoxContainer/ProgressSection/StepsContainer/Step2
@onready var step_3: Panel = $PainelCentral/MarginContainer/VBoxContainer/ProgressSection/StepsContainer/Step3
@onready var step_1_label: Label = $PainelCentral/MarginContainer/VBoxContainer/ProgressSection/StepsContainer/Step1/Step1Label
@onready var step_2_label: Label = $PainelCentral/MarginContainer/VBoxContainer/ProgressSection/StepsContainer/Step2/Step2Label
@onready var step_3_label: Label = $PainelCentral/MarginContainer/VBoxContainer/ProgressSection/StepsContainer/Step3/Step3Label

var _dot_base_y = {}
var _current_step: int = 0
var _step_colors = {
	0: Color(0.9, 0.9, 1, 0.7),  # Cinza claro
	1: Color(0.4, 0.7, 1.0, 1.0),  # Azul claro
	2: Color(0.3, 0.8, 0.5, 1.0),  # Verde
}

func _ready() -> void:
	SettingsManager.pause_tree_when_open = false
	SettingsManager.close_menu()
	_dot_base_y[dot_1] = dot_1.position.y
	_dot_base_y[dot_2] = dot_2.position.y
	_dot_base_y[dot_3] = dot_3.position.y

	if not GameState.player_name.is_empty():
		subtitle.text = "Preparando o tabuleiro para %s..." % GameState.player_name
		hint_text.text = "A sala, as perguntas e o progresso do jogador estao sendo preparados."

	if not GameState.session_preparation_updated.is_connected(_on_session_preparation_updated):
		GameState.session_preparation_updated.connect(_on_session_preparation_updated)

	# Inicializar progresso
	progress_bar.value = 0.0
	_update_step_visual(0)

	animate_logo()
	animate_loading_card()
	animate_character()
	animate_dot(dot_1, 0.0)
	animate_dot(dot_2, 0.14)
	animate_dot(dot_3, 0.28)

	var result := await GameState.prepare_session()
	if not result.get("ok", false):
		await _show_startup_error(result.get("error", "Nao foi possivel iniciar a partida."))
		return

	# Animar para 100% antes de trocar de cena
	_animate_progress_to(100.0, 0.4)
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

func animate_character() -> void:
	var base_y = personagem.position.y
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(personagem, "position:y", base_y - 8.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(personagem, "position:y", base_y, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

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
	
	# Atualizar progresso baseado na mensagem
	if "Conectando" in message:
		_update_step_visual(0)
		_animate_progress_to(25.0, 0.3)
	elif "Validando" in message:
		_update_step_visual(1)
		_animate_progress_to(50.0, 0.3)
	elif "Carregando" in message:
		_update_step_visual(1)
		_animate_progress_to(75.0, 0.3)
	elif "pronto" in message.to_lower() or "Tudo" in message:
		_update_step_visual(2)
		_animate_progress_to(95.0, 0.3)

func _update_step_visual(step: int) -> void:
	_current_step = step
	var steps = [step_1, step_2, step_3]
	var step_labels = [step_1_label, step_2_label, step_3_label]
	
	for i in range(steps.size()):
		if i <= step:
			# Ativar step
			var tween = create_tween()
			tween.tween_property(steps[i], "self_modulate", Color.WHITE, 0.2)
			step_labels[i].add_theme_color_override("font_color", _step_colors[min(i, 2)])
		else:
			# Desativar step
			var tween = create_tween()
			tween.tween_property(steps[i], "self_modulate", Color(1, 1, 1, 0.6), 0.2)
			step_labels[i].add_theme_color_override("font_color", _step_colors[0])

func _animate_progress_to(target: float, duration: float) -> void:
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", target, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _show_startup_error(message: String) -> void:
	subtitle.text = message
	hint_text.text = "Nao foi possivel preparar a partida."
	var dialog := AcceptDialog.new()
	add_child(dialog)
	dialog.title = "Falha ao iniciar"
	dialog.dialog_text = message
	dialog.popup_centered()
	await dialog.confirmed
	get_tree().change_scene_to_file("res://scene/selecao_perfil.tscn")
