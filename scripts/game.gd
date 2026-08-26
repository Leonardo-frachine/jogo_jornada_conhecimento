extends Node2D

# Controlador principal do tabuleiro: coordena turno, perguntas, movimento, HUD e sincronizacao.
const UITheme := preload("res://scripts/UITheme.gd")
const TOTAL_CASAS := 28
const HUD_BG := Color(0.045, 0.071, 0.125, 0.96)
const HUD_SURFACE_ALT := Color(0.105, 0.15, 0.245, 0.94)
const HUD_BORDER := Color(0.36, 0.47, 0.67, 0.58)
const HUD_TEXT_MUTED := Color(0.72, 0.79, 0.90, 1.0)
const HUD_ACCENT := Color(0.98, 0.73, 0.20, 1.0)
const DICE_ROLLING_COLOR := Color(0.42, 0.75, 1.0, 1.0)
const FEEDBACK_OK := Color(0.29, 0.85, 0.45, 0.95)
const FEEDBACK_FAIL := Color(0.93, 0.33, 0.33, 0.95)
const HUD_LAYER := 20
const DIALOG_LAYER := 40
const CAMERA_PADDING := 0.92
const BOARD_MIN_ZOOM := 0.36
const DIALOG_MAX_WIDTH := 1180.0
const DIALOG_MAX_HEIGHT := 720.0
const QUESTION_BASE_HEIGHT := 84.0
const QUESTION_TALL_HEIGHT := 126.0
const QUESTION_EXTRA_TALL_HEIGHT := 156.0
const ANSWER_BASE_HEIGHT := 52.0
const ANSWER_TALL_HEIGHT := 78.0
const ANSWER_EXTRA_TALL_HEIGHT := 104.0
const ANSWER_ULTRA_TALL_HEIGHT := 128.0
const ANSWER_SLOT_LABELS: Array[String] = ["A", "B", "C", "D"]
const DEFAULT_QUESTION_TIME_LIMIT := 30
const DICE_ANIMATION_STEPS := 11
const DICE_RESULT_HOLD_SECONDS := 1.15
const QUESTION_TIMER_WARNING_SECONDS := 10
const QUESTION_TIMER_DANGER_SECONDS := 5
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
const BOARD_PLAYER_Z_INDEX := 8
const BOARD_HOUSE_SPRITE_SCALE := Vector2(0.18, 0.135)
const BOARD_BACKGROUND_TINT := Color(0.76, 0.76, 0.76, 1.0)
const CHALLENGE_HOUSE_TEXTURE := preload("res://imagens/chao/challenge_house.png")
const CHALLENGE_HOUSE_SPRITE_SCALE := Vector2(0.075, 0.075)
const CHALLENGE_HOUSES: Array[int] = [5, 10, 15, 20, 25]
const CHALLENGE_COLOR := Color(0.92, 0.22, 0.18, 1.0)
const ROOM_PLAYERS_REFRESH_SECONDS := 3.0
const REMOTE_PLAYER_TEXTURE_PATHS: Array[String] = [
	"res://imagens/personagens_animais/cachorro.png",
	"res://imagens/personagens_animais/leao.png",
	"res://imagens/personagens_animais/tartaruga.png",
	"res://imagens/personagens_animais/aguia.png",
	"res://imagens/personagens_animais/gato.png",
]
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
	ROLLING_DICE,
	SHOWING_QUESTION,
	MOVING_PLAYER,
	MOVING_TO_CHALLENGE,
	RETURNING_FROM_CHALLENGE
}

@onready var casas_root: Node = get_node_or_null("Casas")
@onready var player = get_node_or_null("Player")
@onready var canvas_layer: CanvasLayer = get_node_or_null("CanvasLayer") as CanvasLayer
@onready var sprite_dado: TextureRect = get_node_or_null("HUD/Root/ActionDock/Margin/HBox/DiceFrame/SpriteDado") as TextureRect
@onready var dialog_panel: Control = get_node_or_null("CanvasLayer/JanelaPergunta") as Control
@onready var dialog_backdrop: ColorRect = get_node_or_null("CanvasLayer/DialogBackdrop") as ColorRect
@onready var dialog_title_label: Label = get_node_or_null("CanvasLayer/JanelaPergunta/Margin/VBox/HeaderRow/DialogTitle") as Label
@onready var question_timer_panel: PanelContainer = get_node_or_null("CanvasLayer/JanelaPergunta/Margin/VBox/HeaderRow/QuestionTimerPanel") as PanelContainer
@onready var question_timer_label: Label = get_node_or_null("CanvasLayer/JanelaPergunta/Margin/VBox/HeaderRow/QuestionTimerPanel/TimerMargin/QuestionTimerLabel") as Label
@onready var question_timer_progress: ProgressBar = get_node_or_null("CanvasLayer/JanelaPergunta/Margin/VBox/QuestionTimerProgress") as ProgressBar
@onready var turn_feedback_panel: PanelContainer = get_node_or_null("CanvasLayer/JanelaPergunta/Margin/VBox/TurnFeedbackPanel") as PanelContainer
@onready var turn_feedback_label: Label = get_node_or_null("CanvasLayer/JanelaPergunta/Margin/VBox/TurnFeedbackPanel/FeedbackMargin/TurnFeedbackLabel") as Label
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
@onready var stats_panel: PanelContainer = get_node_or_null("HUD/Root/StatsPanel") as PanelContainer
@onready var feedback_toast: PanelContainer = get_node_or_null("HUD/Root/FeedbackToast") as PanelContainer
@onready var feedback_status: Label = get_node_or_null("HUD/Root/FeedbackToast/Margin/HBox/StatusDot") as Label
@onready var action_dock: PanelContainer = get_node_or_null("HUD/Root/ActionDock") as PanelContainer
@onready var dice_frame: PanelContainer = get_node_or_null("HUD/Root/ActionDock/Margin/HBox/DiceFrame") as PanelContainer
@onready var roll_status_label: Label = get_node_or_null("HUD/Root/ActionDock/Margin/HBox/RollContent/RollStatusLabel") as Label
@onready var roll_button: Button = get_node_or_null("HUD/Root/ActionDock/Margin/HBox/RollContent/RollButton") as Button
@onready var feedback_label: Label = get_node_or_null("HUD/Root/FeedbackToast/Margin/HBox/FeedbackLabel") as Label
@onready var score_label: Label = get_node_or_null("HUD/Root/StatsPanel/Margin/HBox/ScoreCard/VBox/ScoreLabel") as Label
@onready var level_label: Label = get_node_or_null("HUD/Root/StatsPanel/Margin/HBox/LevelCard/VBox/LevelLabel") as Label
@onready var progress_label: Label = get_node_or_null("HUD/Root/StatsPanel/Margin/HBox/ProgressCard/VBox/ProgressLabel") as Label
@onready var player_label: Label = get_node_or_null("HUD/Root/TopPanel/Margin/HBox/Identity/PlayerLabel") as Label
@onready var room_label: Label = get_node_or_null("HUD/Root/TopPanel/Margin/HBox/Identity/RoomLabel") as Label
@onready var accuracy_label: Label = get_node_or_null("HUD/Root/StatsPanel/Margin/HBox/AccuracyCard/VBox/AccuracyLabel") as Label
@onready var player_badge: PanelContainer = get_node_or_null("HUD/Root/TopPanel/Margin/HBox/PlayerBadge") as PanelContainer
@onready var player_badge_label: Label = get_node_or_null("HUD/Root/TopPanel/Margin/HBox/PlayerBadge/PlayerBadgeLabel") as Label
@onready var identity_label: Label = get_node_or_null("HUD/Root/TopPanel/Margin/HBox/Identity/IdentityLabel") as Label
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
var pending_start_house: int = 1
var pending_is_challenge := false
var pending_correct_index: int = 0
var current_roll: int = 0
var rng_roll = RandomNumberGenerator.new()
var accepting_roll: bool = true
var turn_state: int = TurnState.WAITING_ROLL
var answering_locked: bool = false
var remote_players_root: Node2D
var remote_player_nodes: Dictionary = {}
var remote_players_snapshot: Array[Dictionary] = []
var room_players_refreshing := false
var room_players_timer: Timer
var question_timer: Timer
var question_time_limit := DEFAULT_QUESTION_TIME_LIMIT
var question_deadline_ms := 0
var question_timer_color_state := -1

func _ready() -> void:
	# Inicializa camadas, controles, tabuleiro e estado do turno antes de aceitar entrada.
	randomize()

	SettingsManager.pause_tree_when_open = true
	SettingsManager.close_menu()
	# Dialogos ficam acima do HUD quando a camada existe na cena.
	if canvas_layer != null:
		canvas_layer.layer = DIALOG_LAYER
	# HUD usa uma camada inferior para permanecer visivel sem cobrir dialogos.
	if hud_canvas != null:
		hud_canvas.layer = HUD_LAYER
	_bind_scene_ui()
	_setup_question_timer()
	_layout_board_path()
	_build_board_positions()
	_decorate_challenge_houses()

	# Configura o peao local somente quando a variante de cena o possui.
	if player != null:
		player.z_index = BOARD_PLAYER_Z_INDEX
		# setup recebe a sequencia calculada de casas para iniciar na primeira.
		if player.has_method("setup"):
			player.setup(board_positions)
		# Cada passo atualiza progresso local e efeito sonoro uma unica vez.
		if player.has_signal("step_reached") and not player.step_reached.is_connected(_on_step_reached):
			player.step_reached.connect(_on_step_reached)
		# O fim do movimento libera a proxima etapa do turno.
		if player.has_signal("movement_finished") and not player.movement_finished.is_connected(_on_movement_finished):
			player.movement_finished.connect(_on_movement_finished)

	_setup_room_players_sync()

	AudioManager.play_game_music()
	_configure_camera()
	_refresh_hud()
	call_deferred("_apply_initial_layout")
	_hide_dialog()
	_set_turn_state(TurnState.WAITING_ROLL)
	_show_feedback("Role o dado para abrir uma pergunta.", FEEDBACK_OK)

	# Resize reposiciona casas, camera, HUD e dialogo sem duplicar o listener.
	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)
	# Fonte acessivel tambem exige recalcular o layout do dialogo.
	if not SettingsManager.font_scale_changed.is_connected(_on_font_scale_changed):
		SettingsManager.font_scale_changed.connect(_on_font_scale_changed)

func _bind_scene_ui() -> void:
	# Os testes de null permitem reutilizar o controlador em variantes incompletas da cena.
	if hud_root != null:
		hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Painel de identidade nao captura cliques destinados ao tabuleiro.
	if top_panel != null:
		top_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		top_panel.add_theme_stylebox_override("panel", _make_hud_surface(HUD_BG, HUD_BORDER, 1, 22, 12))

	# Badge destaca as iniciais do jogador quando estiver presente.
	if player_badge != null:
		player_badge.add_theme_stylebox_override("panel", _make_hud_surface(HUD_ACCENT, Color(1.0, 0.86, 0.50, 0.8), 1, 18, 0))
	# Texto do badge usa contraste escuro sobre o destaque amarelo.
	if player_badge_label != null:
		UITheme.apply_font_only(player_badge_label, 24)
		player_badge_label.add_theme_color_override("font_color", Color(0.15, 0.12, 0.08, 1.0))
	# Rotulo auxiliar da identidade recebe cor de acento.
	if identity_label != null:
		UITheme.apply_font_only(identity_label, 11)
		identity_label.add_theme_color_override("font_color", HUD_ACCENT)
	# Nome longo e truncado no HUD sem impedir interacao com o jogo.
	if player_label != null:
		player_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UITheme.apply_font_only(player_label, 22)
		player_label.add_theme_color_override("font_color", Color.WHITE)
		player_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	# Codigo da sala e exibido como informacao secundaria.
	if room_label != null:
		room_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UITheme.apply_font_only(room_label, 13)
		room_label.add_theme_color_override("font_color", HUD_TEXT_MUTED)

	# Painel de estatisticas recebe a mesma superficie escura do HUD.
	if stats_panel != null:
		stats_panel.add_theme_stylebox_override("panel", _make_hud_surface(HUD_BG, HUD_BORDER, 1, 22, 12))
	var stat_cards: Array[PanelContainer] = []
	var stat_colors: Array[Color] = [HUD_ACCENT, Color(0.42, 0.75, 1.0, 1.0), Color(0.67, 0.55, 1.0, 1.0), FEEDBACK_OK]
	# Coleta somente os cards encontrados na hierarquia atual da cena.
	if stats_panel != null:
		# Percorre os quatro indicadores na mesma ordem das cores.
		for card_name in ["ScoreCard", "LevelCard", "ProgressCard", "AccuracyCard"]:
			var stat_card := stats_panel.get_node_or_null("Margin/HBox/%s" % card_name) as PanelContainer
			# Card ausente e ignorado sem deslocar os demais elementos da cena.
			if stat_card != null:
				stat_cards.append(stat_card)
	# Estiliza cada card encontrado e seu titulo interno.
	for index in range(stat_cards.size()):
		var stat_card := stat_cards[index]
		stat_card.add_theme_stylebox_override("panel", _make_hud_surface(HUD_SURFACE_ALT, Color(stat_colors[index], 0.22), 1, 14, 0))
		var title := stat_card.get_node_or_null("VBox/Title") as Label
		# Titulo opcional usa tipografia secundaria do HUD.
		if title != null:
			UITheme.apply_font_only(title, 11)
			title.add_theme_color_override("font_color", HUD_TEXT_MUTED)
	# Associa no maximo quatro labels de valor aos quatro cards oficiais.
	for index in range(mini(stat_cards.size(), 4)):
		var value_label := [score_label, level_label, progress_label, accuracy_label][index] as Label
		# Label ausente nao impede configurar os outros indicadores.
		if value_label != null:
			value_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			UITheme.apply_font_only(value_label, 21)
			value_label.add_theme_color_override("font_color", stat_colors[index])

	# Mensagem de feedback permanece legivel sem capturar mouse.
	if feedback_label != null:
		feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		UITheme.apply_font_only(feedback_label, 17)
		feedback_label.add_theme_color_override("font_color", Color.WHITE)
	# O ponto de status herda a cor dinamica do feedback.
	if feedback_status != null:
		UITheme.apply_font_only(feedback_status, 18)
	_style_feedback_toast(FEEDBACK_OK)

	# Dock agrupa dado e botao na superficie principal do HUD.
	if action_dock != null:
		action_dock.add_theme_stylebox_override("panel", _make_hud_surface(HUD_BG, HUD_BORDER, 1, 24, 14))
	# Moldura clara separa visualmente o dado das acoes.
	if dice_frame != null:
		dice_frame.add_theme_stylebox_override("panel", _make_hud_surface(Color(1.0, 0.97, 0.88, 1.0), Color(HUD_ACCENT, 0.75), 2, 18, 0))
	# Status do turno usa a cor de acento para chamar atencao.
	if roll_status_label != null:
		UITheme.apply_font_only(roll_status_label, 14)
		roll_status_label.add_theme_color_override("font_color", HUD_ACCENT)

	# Botao do dado e opcional e recebe o callback uma unica vez.
	if roll_button != null:
		roll_button.focus_mode = Control.FOCUS_NONE
		UITheme.apply_button(roll_button, UITheme.BUTTON_PRIMARY, 19)
		roll_button.add_theme_color_override("font_disabled_color", UITheme.TEXT_PRIMARY)
		# Evita dois lancamentos disparados por uma conexao duplicada.
		if not roll_button.pressed.is_connected(Callable(self, "roll_dice")):
			roll_button.pressed.connect(Callable(self, "roll_dice"))

	# Engrenagem opcional abre o overlay global.
	if settings_button != null:
		# Conecta somente uma vez apesar de reconfiguracoes visuais.
		if not settings_button.pressed.is_connected(Callable(self, "_on_settings_pressed")):
			settings_button.pressed.connect(Callable(self, "_on_settings_pressed"))

	# Dialogo de pergunta bloqueia cliques no tabuleiro enquanto estiver visivel.
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

	# Titulo identifica casa, desafio e nivel.
	if dialog_title_label != null:
		UITheme.apply_font_only(dialog_title_label, 26)
		dialog_title_label.add_theme_color_override("font_color", HUD_ACCENT)

	# Enunciado permite quebra de linha para perguntas longas.
	if question_label != null:
		UITheme.apply_font_only(question_label, 24)
		question_label.add_theme_color_override("font_color", Color.WHITE)
		question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Dicas exibem materia e caracteristica da pergunta em texto secundario.
	if question_hint_label != null:
		UITheme.apply_font_only(question_hint_label, 15)
		question_hint_label.add_theme_color_override("font_color", Color(0.85, 0.90, 0.98, 0.88))
		question_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Timer recebe borda de destaque quando o controle existe.
	if question_timer_panel != null:
		question_timer_panel.add_theme_stylebox_override("panel", _make_emphasis_style(Color(0.06, 0.08, 0.15, 0.98), HUD_ACCENT, 2, 14))
	# Label do timer comeca em cor neutra e muda conforme o prazo.
	if question_timer_label != null:
		UITheme.apply_font_only(question_timer_label, 18)
		question_timer_label.add_theme_color_override("font_color", Color.WHITE)
	# Barra de tempo usa fundo escuro separado do preenchimento dinamico.
	if question_timer_progress != null:
		question_timer_progress.add_theme_stylebox_override("background", _make_emphasis_style(Color(0.03, 0.05, 0.10, 0.95), Color(0.16, 0.20, 0.31, 1.0), 0, 5))
	# Feedback interno explica acerto, erro ou timeout dentro do modal.
	if turn_feedback_label != null:
		UITheme.apply_font_only(turn_feedback_label, 17)
		turn_feedback_label.add_theme_color_override("font_color", Color.WHITE)
	# Painel de feedback recebe borda que muda conforme o resultado.
	if turn_feedback_panel != null:
		turn_feedback_panel.add_theme_stylebox_override("panel", _make_emphasis_style(Color(0.15, 0.11, 0.04, 0.96), HUD_ACCENT, 2, 14))

	_style_and_connect_answer_button(button_a, 0)
	_style_and_connect_answer_button(button_b, 1)
	_style_and_connect_answer_button(button_c, 2)
	_style_and_connect_answer_button(button_d, 3)

func _make_emphasis_style(background: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 12.0
	style.content_margin_right = 12.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style

func _make_hud_surface(
	background: Color,
	border: Color,
	border_width: int,
	radius: int,
	shadow_size: int
) -> StyleBoxFlat:
	var style := _make_emphasis_style(background, border, border_width, radius)
	style.content_margin_left = 0.0
	style.content_margin_right = 0.0
	style.content_margin_top = 0.0
	style.content_margin_bottom = 0.0
	style.shadow_color = Color(0.01, 0.02, 0.05, 0.30 if shadow_size > 0 else 0.0)
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0, 5)
	return style

func _style_feedback_toast(accent_color: Color) -> void:
	# Recolore a superficie do toast segundo sucesso, falha ou estado do dado.
	if feedback_toast != null:
		var toast_background := HUD_BG.lerp(accent_color, 0.08)
		feedback_toast.add_theme_stylebox_override("panel", _make_hud_surface(toast_background, Color(accent_color, 0.72), 1, 18, 10))
	# O indicador circular acompanha a mesma cor de estado.
	if feedback_status != null:
		feedback_status.add_theme_color_override("font_color", accent_color)
		feedback_status.add_theme_stylebox_override("normal", _make_emphasis_style(Color(accent_color, 0.13), Color(accent_color, 0.0), 0, 12))

func _setup_question_timer() -> void:
	# Reutiliza timer existente para nao criar multiplas contagens regressivas.
	if question_timer != null and is_instance_valid(question_timer):
		return
	question_timer = Timer.new()
	question_timer.name = "QuestionCountdownTimer"
	question_timer.wait_time = 0.1
	question_timer.one_shot = false
	question_timer.timeout.connect(_on_question_timer_tick)
	add_child(question_timer)

func _start_question_timer(time_limit: int) -> void:
	# Sem timer configurado, a pergunta continua sem contagem em vez de falhar.
	if question_timer == null:
		return
	question_time_limit = maxi(time_limit, 1)
	question_deadline_ms = Time.get_ticks_msec() + question_time_limit * 1000
	question_timer_color_state = -1
	_update_question_timer_visual(float(question_time_limit))
	question_timer.start()

func _stop_question_timer() -> void:
	question_deadline_ms = 0
	# Para a instancia apenas quando ela existe.
	if question_timer != null:
		question_timer.stop()

func _on_question_timer_tick() -> void:
	# Timer fora de uma pergunta ativa e interrompido imediatamente.
	if question_deadline_ms <= 0 or turn_state != TurnState.SHOWING_QUESTION:
		_stop_question_timer()
		return

	var remaining_seconds := maxf(0.0, float(question_deadline_ms - Time.get_ticks_msec()) / 1000.0)
	_update_question_timer_visual(remaining_seconds)
	# Enquanto resta tempo, apenas atualiza a interface e aguarda o proximo tick.
	if remaining_seconds > 0.0:
		return

	_stop_question_timer()
	# Timeout nao resolve duas vezes nem atua sobre dialogo ja fechado.
	if answering_locked or dialog_panel == null or not dialog_panel.visible:
		return
	answering_locked = true
	_set_question_buttons_enabled(false)
	# Informa visualmente que o prazo terminou.
	if question_timer_label != null:
		question_timer_label.text = "Tempo esgotado!"
	_set_turn_feedback("Tempo esgotado. A resposta sera registrada como incorreta.", FEEDBACK_FAIL)
	await get_tree().create_timer(0.65).timeout
	# Depois da pausa visual, resolve somente se a cena e a pergunta ainda estiverem ativas.
	if is_inside_tree() and turn_state == TurnState.SHOWING_QUESTION:
		await _resolve_answer(false, true)

func _update_question_timer_visual(remaining_seconds: float) -> void:
	# Atualiza o texto arredondando para cima para nao exibir zero cedo demais.
	if question_timer_label != null:
		question_timer_label.text = "Tempo: %ds" % ceili(remaining_seconds)
	# Barra usa o limite total como maximo e os segundos restantes como valor.
	if question_timer_progress != null:
		question_timer_progress.max_value = float(question_time_limit)
		question_timer_progress.value = remaining_seconds

	var color_state := 2 if remaining_seconds <= QUESTION_TIMER_DANGER_SECONDS else (1 if remaining_seconds <= QUESTION_TIMER_WARNING_SECONDS else 0)
	# Evita recriar estilos enquanto permanece na mesma faixa de cor.
	if color_state == question_timer_color_state:
		return
	question_timer_color_state = color_state
	var timer_color := FEEDBACK_FAIL if color_state == 2 else (HUD_ACCENT if color_state == 1 else FEEDBACK_OK)
	# Texto acompanha verde, amarelo ou vermelho conforme o prazo.
	if question_timer_label != null:
		question_timer_label.add_theme_color_override("font_color", timer_color)
	# Preenchimento da barra acompanha a mesma cor do texto.
	if question_timer_progress != null:
		question_timer_progress.add_theme_stylebox_override("fill", _make_emphasis_style(timer_color, timer_color, 0, 5))

func _set_turn_feedback(text_value: String, accent_color: Color) -> void:
	# Atualiza a mensagem somente quando o label existe.
	if turn_feedback_label != null:
		turn_feedback_label.text = text_value
	# A borda do painel comunica a natureza do feedback.
	if turn_feedback_panel != null:
		turn_feedback_panel.add_theme_stylebox_override("panel", _make_emphasis_style(Color(0.06, 0.08, 0.15, 0.98), accent_color, 2, 14))

func _style_and_connect_answer_button(button: Button, answer_slot: int) -> void:
	# Variantes com menos botoes podem passar referencias nulas.
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
	# Cada alternativa conecta seu indice apenas uma vez.
	if not button.pressed.is_connected(callback):
		button.pressed.connect(callback)

func _apply_initial_layout() -> void:
	await get_tree().process_frame
	_update_viewport_layout()

func _unhandled_input(event: InputEvent) -> void:
	# Pausa de configuracoes bloqueia atalhos do turno.
	if get_tree().paused:
		return

	var dialog_open: bool = dialog_panel != null and dialog_panel.visible
	# Enter/espaco rola o dado apenas no estado de espera e sem pergunta aberta.
	if event.is_action_pressed("ui_accept") and accepting_roll and not dialog_open:
		roll_dice()
		get_viewport().set_input_as_handled()

func _build_board_positions() -> void:
	# Reconstroi as coordenadas usadas por movimento, camera e jogadores remotos.
	board_positions.clear()
	board_local_positions.clear()
	# Sem o container de casas nao ha tabuleiro para mapear.
	if casas_root == null:
		return

	# Percorre as 28 casas na ordem usada pelas regras de movimento.
	for i in range(1, TOTAL_CASAS + 1):
		var casa: Node = casas_root.get_node_or_null("StaticBody2D_P%d" % i)
		var casa_2d := casa as Node2D
		# Somente nodes 2D fornecem coordenadas validas para o peao.
		if casa_2d:
			board_positions.append(casa_2d.global_position)
			board_local_positions.append(casa_2d.position)

	_refresh_board_path_visual()

func _decorate_challenge_houses() -> void:
	# Sem tabuleiro nao existem casas para marcar como desafio.
	if casas_root == null:
		return

	# Percorre a lista de casas especiais definida pela regra do jogo.
	for house_index in CHALLENGE_HOUSES:
		var house := casas_root.get_node_or_null("StaticBody2D_P%d" % house_index) as Node2D
		# Uma casa ausente e ignorada para manter a cena funcional.
		if house == null:
			continue

		house.set_meta("is_challenge_house", true)
		var sprite := house.get_node_or_null("Sprite2D") as Sprite2D
		# Troca textura e escala somente quando a casa possui sprite visual.
		if sprite != null:
			sprite.texture = CHALLENGE_HOUSE_TEXTURE
			sprite.scale = CHALLENGE_HOUSE_SPRITE_SCALE
			sprite.modulate = Color.WHITE
			sprite.z_index = 4

func _is_challenge_house(house_index: int) -> bool:
	return CHALLENGE_HOUSES.has(house_index)

func _get_challenge_return_house() -> int:
	return maxi(1, pending_target_house - current_roll)

func _refresh_board_path_visual() -> void:
	var casas_node := casas_root as Node2D
	# Uma linha precisa de container e ao menos dois pontos.
	if casas_node == null or board_local_positions.size() < 2:
		return

	# Remove linhas anteriores para que resize nao duplique o caminho.
	for old_path_name in [BOARD_PATH_SHADOW_NAME, BOARD_PATH_LINE_NAME]:
		var old_path := casas_node.get_node_or_null(old_path_name)
		# Apenas nodes realmente encontrados precisam ser removidos/liberados.
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
	# Constroi uma linha independente para caminho ou sombra.
	var line := Line2D.new()
	line.name = line_name
	line.width = width
	line.default_color = color_value
	line.z_index = z_value
	line.antialiased = true
	# Adiciona os pontos na mesma ordem das casas para desenhar a trilha completa.
	for point in board_local_positions:
		line.add_point(point)
	return line

func _layout_board_path() -> void:
	# Sem raiz de casas o layout nao tem alvos para reposicionar.
	if casas_root == null:
		return

	var viewport_size := _get_layout_size()
	# Dimensao invalida pode ocorrer durante a criacao/troca da janela.
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	# Posiciona cada casa pelo ponto normalizado correspondente ao viewport.
	for index in range(mini(TOTAL_CASAS, BOARD_PATH_SCREEN_POINTS.size())):
		var casa := casas_root.get_node_or_null("StaticBody2D_P%d" % (index + 1)) as Node2D
		# Casa ausente e pulada sem interromper o layout das demais.
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
	# A regra visual so se aplica quando a casa possui Sprite2D.
	if sprite != null:
		# Casas-desafio usam textura e escala especiais.
		if bool(casa.get_meta("is_challenge_house", false)):
			sprite.texture = CHALLENGE_HOUSE_TEXTURE
			sprite.scale = CHALLENGE_HOUSE_SPRITE_SCALE
		# Casas comuns mantem a escala padrao do caminho.
		else:
			sprite.scale = BOARD_HOUSE_SPRITE_SCALE

func _on_settings_pressed() -> void:
	SettingsManager.open_menu()

func _configure_camera() -> void:
	# Variantes sem camera deixam o viewport na transformacao padrao.
	if board_camera == null:
		return

	board_camera.enabled = true
	board_camera.position_smoothing_enabled = false
	board_camera.make_current()

func _on_viewport_size_changed() -> void:
	_update_viewport_layout()

func _on_font_scale_changed(_value: float) -> void:
	# Reaplica tema e dimensoes para acomodar o novo tamanho do texto.
	_bind_scene_ui()
	_update_viewport_layout()
	# Pergunta aberta precisa recalcular alturas de enunciado e alternativas.
	if dialog_panel != null and dialog_panel.visible:
		_fit_question_content(question_label.text, _get_answer_buttons())

func _update_viewport_layout() -> void:
	# Atualiza componentes na ordem fundo, interface, tabuleiro, avatares e camera.
	_layout_screen_background()
	_layout_hud()
	_layout_dialog()
	_layout_board_path()
	_build_board_positions()
	# Repassa novas coordenadas ao peao sem reiniciar seu progresso.
	if player != null and player.has_method("update_board_positions"):
		player.update_board_positions(board_positions)
	_apply_remote_players_snapshot(false)
	_fit_board_to_view()

func _setup_room_players_sync() -> void:
	# Sem sala remota nao ha outros alunos para sincronizar.
	if GameState.resolved_room_id <= 0:
		return

	remote_players_root = Node2D.new()
	remote_players_root.name = "RemotePlayers"
	remote_players_root.z_index = 8
	add_child(remote_players_root)

	room_players_timer = Timer.new()
	room_players_timer.name = "RoomPlayersRefreshTimer"
	room_players_timer.wait_time = ROOM_PLAYERS_REFRESH_SECONDS
	room_players_timer.one_shot = false
	room_players_timer.timeout.connect(_refresh_room_players)
	add_child(room_players_timer)
	room_players_timer.start()
	call_deferred("_refresh_room_players")

func _refresh_room_players() -> void:
	# Impede requisicoes sobrepostas e chamadas sem sala valida.
	if room_players_refreshing or GameState.resolved_room_id <= 0:
		return

	room_players_refreshing = true
	var response: Dictionary = await ApiClient.fetch_room_players(GameState.resolved_room_id)
	room_players_refreshing = false
	# Descarta resposta se a cena saiu da arvore ou a API falhou.
	if not is_inside_tree() or not response.get("ok", false):
		return

	remote_players_snapshot.clear()
	var payload: Variant = response.get("data", [])
	# Somente listas podem formar o snapshot de alunos da sala.
	if payload is Array:
		# Percorre todos os alunos devolvidos pelo endpoint.
		for item in payload:
			# Ignora itens malformados que nao possuem campos de jogador.
			if item is Dictionary:
				remote_players_snapshot.append(item)
	_apply_remote_players_snapshot(true)

func _refresh_room_players_after_answer() -> void:
	# Aguarda a consulta atual terminar antes de solicitar o estado pos-resposta.
	while room_players_refreshing and is_inside_tree():
		await get_tree().process_frame
	# So inicia nova consulta se a tela ainda estiver ativa.
	if is_inside_tree():
		await _refresh_room_players()

func _apply_remote_players_snapshot(animate_changes: bool) -> void:
	# Avatares remotos exigem container e coordenadas de casas prontas.
	if remote_players_root == null or board_positions.is_empty():
		return

	var active_player_ids := {}
	var occupants_per_house := {}
	# Atualiza ou cria um avatar para cada aluno remoto do snapshot.
	for aluno in remote_players_snapshot:
		var jogador_id := int(aluno.get("jogadorId", 0))
		# Ignora IDs invalidos e o proprio jogador, ja representado pelo peao local.
		if jogador_id <= 0 or jogador_id == GameState.player_id:
			continue

		var casa_atual := clampi(int(aluno.get("casaAtual", 1)), 1, board_positions.size())
		var occupant_index := int(occupants_per_house.get(casa_atual, 0))
		occupants_per_house[casa_atual] = occupant_index + 1
		active_player_ids[jogador_id] = true

		var avatar := remote_player_nodes.get(jogador_id) as Node2D
		# Primeira aparicao do aluno cria seu node visual e o guarda por ID.
		if avatar == null:
			avatar = _create_remote_player(jogador_id)
			remote_player_nodes[jogador_id] = avatar

		var name_label := avatar.get_node_or_null("NameLabel") as Label
		# Nome exibido acompanha o dado mais recente da API.
		if name_label != null:
			name_label.text = str(aluno.get("nome", "Aluno"))

		var target_position := board_positions[casa_atual - 1] + _get_remote_player_offset(occupant_index)
		var previous_house := int(avatar.get_meta("casa_atual", 0))
		avatar.set_meta("casa_atual", casa_atual)
		# Mudanca conhecida de casa usa tween; primeiro snapshot posiciona imediatamente.
		if animate_changes and previous_house > 0 and previous_house != casa_atual:
			var tween := create_tween()
			tween.tween_property(avatar, "global_position", target_position, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		# Sem mudanca animavel, fixa o avatar no destino calculado.
		else:
			avatar.global_position = target_position

	# Remove avatares que deixaram de aparecer no snapshot atual.
	for jogador_id in remote_player_nodes.keys():
		# IDs ainda ativos permanecem na cena.
		if active_player_ids.has(jogador_id):
			continue
		var stale_avatar := remote_player_nodes[jogador_id] as Node2D
		remote_player_nodes.erase(jogador_id)
		# Libera o node visual quando ele ainda existe.
		if stale_avatar != null:
			stale_avatar.queue_free()

func _create_remote_player(jogador_id: int) -> Node2D:
	# Cria representacao leve, sem colisao ou logica de turno.
	var avatar := Node2D.new()
	avatar.name = "RemotePlayer_%d" % jogador_id
	avatar.z_index = 8
	remote_players_root.add_child(avatar)

	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	var texture_path := REMOTE_PLAYER_TEXTURE_PATHS[jogador_id % REMOTE_PLAYER_TEXTURE_PATHS.size()]
	var texture := load(texture_path) as Texture2D
	# Recurso valido define textura e escala uniforme do token remoto.
	if texture != null:
		sprite.texture = texture
		var token_scale := 86.0 / maxf(float(texture.get_height()), 1.0)
		sprite.scale = Vector2.ONE * token_scale
	sprite.modulate = Color(1.0, 1.0, 1.0, 0.82)
	avatar.add_child(sprite)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.position = Vector2(-58.0, -72.0)
	name_label.size = Vector2(116.0, 28.0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.10, 0.95))
	name_label.add_theme_constant_override("outline_size", 5)
	avatar.add_child(name_label)
	return avatar

func _get_remote_player_offset(occupant_index: int) -> Vector2:
	var angle := -PI * 0.5 + float(occupant_index % 8) * TAU / 8.0
	var radius := 24.0 + float(occupant_index / 8) * 12.0
	return Vector2(cos(angle), sin(angle)) * radius

func _layout_screen_background() -> void:
	# Background opcional nao participa da regra do jogo.
	if screen_background == null:
		return

	var viewport_size: Vector2 = _get_layout_size()
	screen_background.self_modulate = BOARD_BACKGROUND_TINT
	screen_background.anchor_left = 0.0
	screen_background.anchor_top = 0.0
	screen_background.anchor_right = 0.0
	screen_background.anchor_bottom = 0.0
	screen_background.offset_left = 0.0
	screen_background.offset_top = 0.0
	screen_background.offset_right = viewport_size.x
	screen_background.offset_bottom = viewport_size.y

func _layout_hud() -> void:
	# Sem raiz de HUD nao existem controles a posicionar.
	if hud_root == null:
		return

	var viewport_size: Vector2 = _get_layout_size()
	var font_scale: float = SettingsManager.font_scale
	var panel_height := 104.0 + roundf(28.0 * (font_scale - 1.0))
	var compact_layout := viewport_size.x < 1100.0
	var outer_margin := 16.0 if compact_layout else 24.0
	var feedback_y := outer_margin + panel_height + 14.0

	# Layout estreito empilha identidade e estatisticas verticalmente.
	if compact_layout:
		# Posiciona o painel de identidade no topo quando presente.
		if top_panel != null:
			top_panel.position = Vector2(outer_margin, outer_margin)
			top_panel.size = Vector2(minf(360.0, viewport_size.x - outer_margin * 2.0), panel_height)
		# Estatisticas ocupam a largura disponivel abaixo da identidade.
		if stats_panel != null:
			stats_panel.position = Vector2(outer_margin, outer_margin + panel_height + 10.0)
			stats_panel.size = Vector2(viewport_size.x - outer_margin * 2.0, panel_height)
		feedback_y = outer_margin + panel_height * 2.0 + 24.0
	# Layout largo distribui identidade e estatisticas na mesma faixa superior.
	else:
		var identity_width := clampf(viewport_size.x * 0.22, 360.0, 420.0)
		var stats_width := clampf(viewport_size.x * 0.34, 560.0, 680.0)
		var stats_x := (viewport_size.x - stats_width) * 0.5
		var identity_x := outer_margin + 24.0
		stats_x = maxf(stats_x, identity_x + identity_width + 18.0)
		# Mantem identidade a esquerda com largura limitada.
		if top_panel != null:
			top_panel.position = Vector2(identity_x, outer_margin)
			top_panel.size = Vector2(identity_width, panel_height)
		# Centraliza estatisticas sem sobrepor a identidade.
		if stats_panel != null:
			stats_panel.position = Vector2(stats_x, outer_margin)
			stats_panel.size = Vector2(stats_width, panel_height)

	# Toast centraliza feedback logo abaixo dos paineis superiores.
	if feedback_toast != null:
		var toast_width := minf(660.0, viewport_size.x - outer_margin * 2.0)
		feedback_toast.position = Vector2((viewport_size.x - toast_width) * 0.5, feedback_y)
		feedback_toast.size = Vector2(toast_width, 52.0 * minf(font_scale, 1.2))
	# Permite que mensagens longas quebrem dentro da largura do toast.
	if feedback_label != null:
		feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# Dock do dado permanece centralizado na margem inferior.
	if action_dock != null:
		var dock_width := minf(420.0, viewport_size.x - 90.0)
		var dock_height := 108.0
		action_dock.position = Vector2(
			(viewport_size.x - dock_width) * 0.5,
			viewport_size.y - dock_height - 22.0
		)
		action_dock.size = Vector2(dock_width, dock_height)

func _layout_dialog() -> void:
	# Variantes sem modal de pergunta nao precisam de layout.
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
	# Sem camera dedicada nao ha zoom/centro a atualizar.
	if board_camera == null:
		return

	var viewport_size: Vector2 = _get_layout_size()
	# Evita configurar camera durante viewport temporariamente vazio.
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	board_camera.zoom = Vector2.ONE
	board_camera.global_position = viewport_size * 0.5

func _get_layout_size() -> Vector2:
	return get_viewport_rect().size

func _build_board_focus_rect(viewport_size: Vector2) -> Rect2:
	var board_rect: Rect2 = _calculate_board_bounds()
	# Bounds vazios nao recebem padding porque nao representam um tabuleiro real.
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

	# Expande os limites para incluir cada casa conhecida.
	for position_value in board_positions:
		var board_position: Vector2 = position_value
		# O primeiro ponto inicializa o retangulo.
		if not has_bounds:
			bounds = Rect2(board_position, Vector2.ZERO)
			has_bounds = true
		# Pontos seguintes expandem o retangulo existente.
		else:
			bounds = bounds.expand(board_position)

	# Inclui o peao para a camera nao corta-lo fora do caminho.
	if player != null:
		# Sem casas, a posicao do jogador pode iniciar os bounds.
		if not has_bounds:
			bounds = Rect2(player.global_position, Vector2.ZERO)
			has_bounds = true
		# Com casas, apenas expande para incluir o jogador.
		else:
			bounds = bounds.expand(player.global_position)

	# Nenhuma casa/jogador produz retangulo vazio seguro.
	if not has_bounds:
		return Rect2()

	return bounds

func _hide_dialog() -> void:
	# Fecha pergunta, para o timer e devolve o feedback principal ao HUD.
	_stop_question_timer()
	# Modal opcional e ocultado quando existe.
	if dialog_panel != null:
		dialog_panel.hide()

	# Fundo bloqueador acompanha a visibilidade do modal.
	if dialog_backdrop != null:
		dialog_backdrop.hide()

	_set_question_buttons_enabled(false)
	answering_locked = false
	# Toast volta a aparecer depois que a pergunta fecha.
	if feedback_toast != null:
		feedback_toast.show()

func _show_dialog() -> void:
	# Sem modal nao e possivel apresentar nem responder a pergunta.
	if dialog_panel == null:
		return

	# Backdrop bloqueia interacoes com tabuleiro durante a pergunta.
	if dialog_backdrop != null:
		dialog_backdrop.show()
	# Oculta feedback externo para liberar espaco visual ao modal.
	if feedback_toast != null:
		feedback_toast.hide()

	dialog_panel.show()
	canvas_layer.move_child(dialog_panel, canvas_layer.get_child_count() - 1)
	_set_question_buttons_enabled(true)
	answering_locked = false

	# Move foco para a primeira alternativa visivel, facilitando teclado.
	for button in _get_answer_buttons():
		# Ignora slots ausentes/ocultos e interrompe ao focar o primeiro valido.
		if button != null and button.visible:
			button.grab_focus()
			break

func _set_question_buttons_enabled(enabled: bool) -> void:
	# Aplica bloqueio de resposta a todos os quatro slots.
	for button in _get_answer_buttons():
		# Botao oculto permanece desabilitado mesmo ao liberar os demais.
		if button != null:
			button.disabled = not enabled or not button.visible

func _get_answer_buttons() -> Array[Button]:
	return [button_a, button_b, button_c, button_d]

func _set_turn_state(new_state: int) -> void:
	# Estado central controla botao, mensagens e disponibilidade das configuracoes.
	turn_state = new_state
	accepting_roll = new_state == TurnState.WAITING_ROLL

	# Atualiza disponibilidade e texto do botao quando ele existe.
	if roll_button != null:
		roll_button.disabled = not accepting_roll
		# Espera de turno convida o aluno a jogar.
		if new_state == TurnState.WAITING_ROLL:
			roll_button.text = "ROLAR O DADO"
		# Durante animacao o botao informa que a acao esta em curso.
		elif new_state == TurnState.ROLLING_DICE:
			roll_button.text = "ROLANDO..."

	# Estado de espera restaura destaque padrao do dock.
	if new_state == TurnState.WAITING_ROLL:
		_set_roll_status("SUA VEZ  •  ROLE O DADO", HUD_ACCENT)
		# Dock opcional recebe borda neutra.
		if action_dock != null:
			action_dock.add_theme_stylebox_override("panel", _make_hud_surface(HUD_BG, HUD_BORDER, 1, 24, 14))
	# Estado de rolagem troca texto e borda para azul.
	elif new_state == TurnState.ROLLING_DICE:
		_set_roll_status("O DADO ESTÁ ROLANDO...", DICE_ROLLING_COLOR)
		# Dock opcional recebe destaque de movimento.
		if action_dock != null:
			action_dock.add_theme_stylebox_override("panel", _make_hud_surface(HUD_BG, Color(DICE_ROLLING_COLOR, 0.9), 2, 24, 16))

	# Configuracoes ficam bloqueadas durante operacoes do turno para nao interromper awaits.
	if settings_button != null:
		settings_button.disabled = new_state != TurnState.WAITING_ROLL

func _set_roll_status(text_value: String, color_value: Color) -> void:
	# Variantes sem label ignoram a atualizacao textual.
	if roll_status_label == null:
		return
	roll_status_label.text = text_value
	roll_status_label.add_theme_color_override("font_color", color_value)

func roll_dice() -> void:
	# So aceita rolagem no estado inicial do turno.
	if turn_state != TurnState.WAITING_ROLL:
		return
	# Sem peao nao ha destino que possa receber o resultado.
	if player == null:
		return
	# Pergunta aberta ou menu pausado bloqueia novo lancamento.
	if (dialog_panel != null and dialog_panel.visible) or get_tree().paused:
		return

	_set_turn_state(TurnState.ROLLING_DICE)
	_show_feedback("O dado está rolando... acompanhe os números!", DICE_ROLLING_COLOR)
	AudioManager.play_dice_sfx()
	rng_roll.randomize()
	var roll_chance: float = rng_roll.randf()
	# Faixa superior de 10% concede o maior deslocamento.
	if roll_chance <= 0.1: current_roll = 6 #10%
	# Faixas seguintes concedem 5, 4, 3 ou 2, cada uma com 10%.
	elif roll_chance <= 0.2: current_roll = 5 #10%
	# Mantem 10% de chance para tirar quatro.
	elif roll_chance <= 0.3: current_roll = 4 #10%
	# Mantem 10% de chance para tirar tres.
	elif roll_chance <= 0.4: current_roll = 3 #10%
	# Mantem 10% de chance para tirar dois.
	elif roll_chance <= 0.5: current_roll = 2 #10%
	# Metade restante produz um, favorecendo partidas mais longas.
	else: current_roll= 1	 # >50%
	
	pending_start_house = player.current_house
	pending_target_house = mini(pending_start_house + current_roll, TOTAL_CASAS)
	pending_is_challenge = _is_challenge_house(pending_target_house)

	await _animate_dice_roll(current_roll)
	# Await da animacao pode terminar depois que o usuario saiu da cena.
	if not is_inside_tree():
		return
	_show_dice_result(current_roll)
	await get_tree().create_timer(DICE_RESULT_HOLD_SECONDS).timeout
	# A pausa de exibicao do resultado tambem pode atravessar uma troca de cena.
	if not is_inside_tree():
		return

	# Casa especial move antes da pergunta para sinalizar visualmente o desafio.
	if pending_is_challenge:
		_set_turn_state(TurnState.MOVING_TO_CHALLENGE)
		_show_feedback("Casa desafio! Prepare-se para uma pergunta especial.", CHALLENGE_COLOR)
		await player.move_to_house(pending_target_house)
		# Movimento assincrono nao continua em uma cena destruida.
		if not is_inside_tree():
			return

	_set_turn_state(TurnState.SHOWING_QUESTION)
	_present_question(pending_target_house)

func _animate_dice_roll(result: int) -> void:
	# Sem sprite/texturas mantem apenas a duracao minima do turno.
	if sprite_dado == null or dice_textures.is_empty():
		await get_tree().create_timer(0.65).timeout
		return

	sprite_dado.pivot_offset = sprite_dado.size * 0.5
	sprite_dado.rotation = 0.0
	sprite_dado.scale = Vector2.ONE
	var animation_steps := DICE_ANIMATION_STEPS if SettingsManager.vfx_enabled else 6
	var previous_face := -1

	# Alterna faces por varios passos para simular a rolagem.
	for step in range(animation_steps):
		var face_index := rng_roll.randi_range(0, dice_textures.size() - 1)
		# Evita mostrar a mesma face duas vezes seguidas.
		if face_index == previous_face:
			face_index = (face_index + 1) % dice_textures.size()
		previous_face = face_index
		sprite_dado.texture = dice_textures[face_index]

		var step_duration := 0.045 + float(step) * 0.004
		# Com efeitos visuais, rotaciona e pulsa o dado a cada troca.
		if SettingsManager.vfx_enabled:
			var target_angle := deg_to_rad(16.0 if step % 2 == 0 else -16.0)
			var step_tween := create_tween().set_parallel(true)
			step_tween.tween_property(sprite_dado, "rotation", target_angle, step_duration).set_trans(Tween.TRANS_SINE)
			step_tween.tween_property(sprite_dado, "scale", Vector2(1.13, 1.13), step_duration).set_trans(Tween.TRANS_SINE)
			await step_tween.finished
		# Sem VFX preserva apenas o ritmo de troca das texturas.
		else:
			await get_tree().create_timer(step_duration).timeout

	sprite_dado.texture = dice_textures[clampi(result - 1, 0, dice_textures.size() - 1)]
	# Revelacao final amplia a face sorteada quando VFX esta ligado.
	if SettingsManager.vfx_enabled:
		var reveal_tween := create_tween().set_parallel(true)
		reveal_tween.tween_property(sprite_dado, "rotation", 0.0, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		reveal_tween.tween_property(sprite_dado, "scale", Vector2(1.34, 1.34), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await reveal_tween.finished
		var settle_tween := create_tween()
		settle_tween.tween_property(sprite_dado, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await settle_tween.finished
	# Sem VFX restaura imediatamente transformacoes neutras.
	else:
		sprite_dado.rotation = 0.0
		sprite_dado.scale = Vector2.ONE

func _show_dice_result(result: int) -> void:
	# Atualiza textos e destaque do dock com o valor efetivo sorteado.
	_set_roll_status("RESULTADO DO DADO", HUD_ACCENT)
	# Botao opcional exibe o numero tirado.
	if roll_button != null:
		roll_button.text = "VOCÊ TIROU %d!" % result
	# Dock opcional recebe borda amarela de resultado.
	if action_dock != null:
		action_dock.add_theme_stylebox_override("panel", _make_hud_surface(HUD_BG, HUD_ACCENT, 2, 24, 18))
	_show_feedback("Você tirou %d! Acerte a pergunta para avançar." % result, HUD_ACCENT)
	# Pequeno pulso reforca o resultado somente com VFX ativo.
	if SettingsManager.vfx_enabled and action_dock != null:
		action_dock.pivot_offset = action_dock.size * 0.5
		var dock_tween := create_tween()
		dock_tween.tween_property(action_dock, "scale", Vector2(1.04, 1.04), 0.10)
		dock_tween.tween_property(action_dock, "scale", Vector2.ONE, 0.16)

func _present_question(house_index: int) -> void:
	# Sem modal nao existe interface segura para mostrar a pergunta.
	if dialog_panel == null:
		return

	var question: Dictionary
	# Casa especial solicita pergunta um nivel acima e marca o payload como desafio.
	if pending_is_challenge:
		question = GameState.get_challenge_question_for_house(house_index)
	# Casa comum usa a dificuldade correspondente a posicao.
	else:
		question = GameState.get_question_for_house(house_index)
	var options: Array = question.get("options", [])
	# Pergunta sem alternativas nao pode bloquear indefinidamente o turno.
	if options.is_empty():
		push_error("Pergunta selecionada sem alternativas.")
		# Desafio indisponivel precisa devolver o peao a posicao anterior.
		if pending_is_challenge:
			call_deferred("_cancel_unavailable_challenge")
		# Pergunta comum indisponivel apenas encerra o turno atual.
		else:
			_finalize_turn()
		return

	var order: Array[int] = []
	# Cria a lista de indices que sera embaralhada sem alterar os textos originais.
	for index in range(options.size()):
		order.append(index)
	order.shuffle()
	pending_correct_index = order.find(int(question.get("correct_index", 0)))

	var question_level := int(question.get("difficulty", GameState.get_level_for_house(house_index)))
	var question_points := int(question.get("points", question_level * 100))
	var wrong_penalty := int(round(float(question_points) / 2.0))
	# Cabecalho de desafio destaca risco de retorno e pontuacao.
	if pending_is_challenge:
		dialog_title_label.text = "DESAFIO - Casa %d - Nivel %d" % [house_index, question_level]
		dialog_title_label.add_theme_color_override("font_color", CHALLENGE_COLOR)
		_set_turn_feedback(
			"Casa desafio %d | Acerto: +%d pontos | Erro: -%d pontos e volta %d casas" % [house_index, question_points, wrong_penalty, current_roll],
			CHALLENGE_COLOR
		)
	# Cabecalho comum mostra somente recompensa e penalidade de pontos.
	else:
		dialog_title_label.text = "Casa %d - Nivel %d" % [house_index, question_level]
		dialog_title_label.add_theme_color_override("font_color", HUD_ACCENT)
		_set_turn_feedback(
			"Casa %d | Acerto: +%d pontos | Erro: -%d pontos" % [house_index, question_points, wrong_penalty],
			HUD_ACCENT
		)
	question_label.text = str(question.get("text", ""))
	_update_question_hint(question)

	var buttons: Array[Button] = _get_answer_buttons()
	# Distribui as opcoes embaralhadas pelos quatro slots visuais.
	for index in range(buttons.size()):
		var button: Button = buttons[index]
		# Slot ausente e ignorado sem afetar os demais.
		if button == null:
			continue

		# Slots que possuem opcao recebem letra, texto e ficam visiveis.
		if index < order.size():
			var option_index: int = order[index]
			button.text = "%s) %s" % [ANSWER_SLOT_LABELS[index], str(options[option_index])]
			button.show()
		# Slots excedentes ficam ocultos para perguntas com menos alternativas.
		else:
			button.hide()

	_fit_question_content(question_label.text, buttons)
	_show_dialog()
	_start_question_timer(_get_question_time_limit(question))

func _cancel_unavailable_challenge() -> void:
	# Desafio sem pergunta nao penaliza resposta, mas desfaz o deslocamento especial.
	_set_turn_state(TurnState.RETURNING_FROM_CHALLENGE)
	_show_feedback("Pergunta desafio indisponivel. Retornando a posicao anterior.", FEEDBACK_FAIL)
	# Retorna o peao somente quando ele ainda existe na cena.
	if player != null:
		await player.move_to_house(_get_challenge_return_house())
	_finalize_turn()

func _fit_question_content(question_text: String, buttons: Array[Button]) -> void:
	# Mede enunciado e maior alternativa para adaptar fonte e altura sem cortar texto.
	var question_length := question_text.length()
	var longest_answer_length := 0
	# Percorre apenas botoes visiveis para calcular a maior resposta apresentada.
	for button in buttons:
		# Slots nulos/ocultos nao participam do dimensionamento.
		if button != null and button.visible:
			longest_answer_length = maxi(longest_answer_length, button.text.length())

	var question_font_size := 24
	var question_height := QUESTION_BASE_HEIGHT
	var height_scale := minf(SettingsManager.font_scale, 1.2)
	# Enunciado muito longo usa a menor fonte e a maior altura.
	if question_length > 170:
		question_font_size = 19
		question_height = QUESTION_EXTRA_TALL_HEIGHT
	# Comprimento intermediario usa dimensao alta moderada.
	elif question_length > 110:
		question_font_size = 21
		question_height = QUESTION_TALL_HEIGHT

	# Aplica os valores calculados somente quando o label existe.
	if question_label != null:
		UITheme.apply_font_only(question_label, question_font_size)
		question_label.custom_minimum_size.y = question_height * height_scale

	var answer_font_size := 17
	var answer_height := ANSWER_BASE_HEIGHT
	# Alternativa extremamente longa usa altura maxima e fonte reduzida.
	if longest_answer_length > 150:
		answer_font_size = 15
		answer_height = ANSWER_ULTRA_TALL_HEIGHT
	# Alternativa muito longa recebe altura extra.
	elif longest_answer_length > 105:
		answer_font_size = 16
		answer_height = ANSWER_EXTRA_TALL_HEIGHT
	# Alternativa moderadamente longa recebe altura intermediaria.
	elif longest_answer_length > 70:
		answer_font_size = 16
		answer_height = ANSWER_TALL_HEIGHT

	# Aplica dimensoes coerentes a todos os slots de resposta existentes.
	for button in buttons:
		# Ignora slots ausentes em variantes do modal.
		if button == null:
			continue
		button.custom_minimum_size.y = answer_height * height_scale
		UITheme.apply_button(button, UITheme.BUTTON_SECONDARY, answer_font_size)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.set("autowrap_mode", TextServer.AUTOWRAP_WORD_SMART)
		button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		button.clip_text = false

	# Reduz espacamento quando respostas altas precisam de mais area vertical.
	if answers_container != null:
		answers_container.add_theme_constant_override("separation", 6 if answer_height > ANSWER_TALL_HEIGHT else 8)
		var vbox := answers_container.get_parent() as VBoxContainer
		# Container pai tambem ajusta a separacao entre secoes do modal.
		if vbox != null:
			vbox.add_theme_constant_override("separation", 9 if answer_height > ANSWER_BASE_HEIGHT else 14)

func _update_question_hint(question: Dictionary) -> void:
	# Monta dicas a partir de metadados sem revelar a resposta correta.
	var hints: Array[String] = []
	var subject: String = str(question.get("subject", "")).strip_edges()

	# Identifica visualmente perguntas de casa especial.
	if bool(question.get("is_challenge", false)):
		hints.append("Pergunta desafio")
	# Materia aparece apenas quando cadastrada no banco.
	if not subject.is_empty():
		hints.append("Materia: %s" % subject)

	# Sem metadados usa uma instrucao generica de jogabilidade.
	if hints.is_empty():
		question_hint_label.text = "Escolha a alternativa correta para seguir no tabuleiro."
	# Com metadados une as dicas em uma unica linha.
	else:
		question_hint_label.text = "  |  ".join(hints)

func _get_question_time_limit(question: Dictionary) -> int:
	var configured_limit := int(question.get("time_limit", 0))
	return configured_limit if configured_limit > 0 else DEFAULT_QUESTION_TIME_LIMIT

func _on_answer_button_pressed(answer_slot: int) -> void:
	# Ignora cliques que chegam fora da etapa de resposta.
	if turn_state != TurnState.SHOWING_QUESTION:
		return
	# Modal fechado, ausente ou resposta ja bloqueada nao pode resolver novamente.
	if dialog_panel == null or not dialog_panel.visible or answering_locked:
		return

	answering_locked = true
	_stop_question_timer()
	_set_question_buttons_enabled(false)
	await _resolve_answer(answer_slot == pending_correct_index, false)

func _resolve_answer(correct: bool, timed_out: bool) -> void:
	# Fecha a interface antes de aplicar pontuacao, movimento e sincronizacao.
	_hide_dialog()
	var score_delta := GameState.register_answer(correct, pending_target_house)
	# Timeout substitui o feedback comum por uma mensagem explicita de prazo.
	if timed_out:
		GameState.last_feedback = "Tempo esgotado! %d pontos." % score_delta
	_show_feedback(GameState.last_feedback, FEEDBACK_OK if correct else FEEDBACK_FAIL)

	# Erro em desafio executa a penalidade especial de voltar o valor do dado.
	if pending_is_challenge and not correct:
		_set_turn_state(TurnState.RETURNING_FROM_CHALLENGE)
		_show_feedback(
			"%s Casa desafio: volte %d casas." % [GameState.last_feedback, current_roll],
			FEEDBACK_FAIL
		)
		AudioManager.play_wrong_sfx()
		# Move de volta somente se o peao ainda existir.
		if player != null:
			await player.move_to_house(_get_challenge_return_house())

		var challenge_sync: Dictionary = await GameState.submit_answer_result(false, pending_target_house)
		# Sucesso remoto solicita snapshot atualizado dos alunos.
		if challenge_sync.get("ok", false):
			call_deferred("_refresh_room_players_after_answer")
		_refresh_hud()
		_finalize_turn()
		return

	var sync_response: Dictionary = await GameState.submit_answer_result(correct, pending_target_house)
	# Resposta comum confirmada tambem atualiza os avatares remotos.
	if sync_response.get("ok", false):
		call_deferred("_refresh_room_players_after_answer")

	# Acerto decide entre concluir desafio no lugar ou mover o peao comum.
	if correct:
		# Desafio correto exibe mensagem especial.
		if pending_is_challenge:
			_show_feedback("%s Desafio concluido!" % GameState.last_feedback, FEEDBACK_OK)
		# Acerto comum entra no estado de movimento e toca o som positivo.
		else:
			_set_turn_state(TurnState.MOVING_PLAYER)
		AudioManager.play_correct_sfx()

		# Pulso visual e opcional conforme preferencia de efeitos.
		if SettingsManager.vfx_enabled:
			_pulse_feedback()

		# Desafio termina o turno sem deslocamento adicional.
		if pending_is_challenge:
			_finalize_turn()
		# Casa comum move o peao ate o destino calculado pelo dado.
		elif player != null:
			await player.move_to_house(pending_target_house)
	# Erro comum nao move o peao e encerra o turno apos feedback negativo.
	else:
		_show_feedback(GameState.last_feedback, FEEDBACK_FAIL)
		AudioManager.play_wrong_sfx()
		_finalize_turn()

	_refresh_hud()

func _pulse_feedback() -> void:
	# Variantes sem toast simplesmente ignoram o efeito visual.
	if feedback_toast == null:
		return

	var tween: Tween = create_tween()
	feedback_toast.pivot_offset = feedback_toast.size * 0.5
	tween.tween_property(feedback_toast, "scale", Vector2(1.03, 1.03), 0.08)
	tween.tween_property(feedback_toast, "scale", Vector2.ONE, 0.12)

func _on_step_reached(house_index: int) -> void:
	GameState.update_progress(house_index)
	_refresh_hud()
	AudioManager.play_move_sfx()

func _on_movement_finished() -> void:
	# Somente movimento comum conclui automaticamente o turno por este sinal.
	if turn_state == TurnState.MOVING_PLAYER:
		_finalize_turn()

func _finalize_turn() -> void:
	# Limpa dados transitórios para preparar o proximo lancamento.
	current_roll = 0
	answering_locked = false
	pending_is_challenge = false
	pending_start_house = GameState.current_house
	GameState.current_question.clear()

	# Alcancar a ultima casa finaliza localmente, sincroniza e abre o resultado.
	if GameState.current_house >= TOTAL_CASAS:
		GameState.finish_session(true)
		await GameState.sync_finished_session(true)
		get_tree().change_scene_to_file("res://scene/end_game_screen.tscn")
		return

	_set_turn_state(TurnState.WAITING_ROLL)

func _show_feedback(text_value: String, color_value: Color) -> void:
	# Label opcional recebe a mensagem principal e possivel aviso de sincronizacao.
	if feedback_label != null:
		var display_text := text_value
		# Falha remota e anexada sem apagar o resultado da jogada local.
		if not GameState.sync_warning.is_empty():
			display_text = "%s  •  %s" % [display_text, GameState.sync_warning]
		feedback_label.text = display_text
		feedback_label.add_theme_color_override("font_color", Color.WHITE)
	_style_feedback_toast(color_value)
	# Simbolo do toast resume visualmente falha, processamento ou sucesso.
	if feedback_status != null:
		# Vermelho usa exclamacao.
		if color_value.is_equal_approx(FEEDBACK_FAIL):
			feedback_status.text = "!"
		# Azul de rolagem usa reticencias.
		elif color_value.is_equal_approx(DICE_ROLLING_COLOR):
			feedback_status.text = "..."
		# Demais estados representam sucesso/confirmacao.
		else:
			feedback_status.text = "✓"

func _refresh_hud() -> void:
	# Nome vazio recebe rotulo generico para nunca deixar o HUD sem identidade.
	if player_label != null:
		player_label.text = GameState.player_name if not GameState.player_name.is_empty() else "Aluno"
	# Badge mostra iniciais calculadas do nome atual.
	if player_badge_label != null:
		player_badge_label.text = _get_player_initials(GameState.player_name)

	# Codigo da sala ajuda professor/aluno a confirmar o contexto da partida.
	if room_label != null:
		room_label.text = "SALA  •  %s" % (GameState.room_code.to_upper() if not GameState.room_code.is_empty() else "SEM CÓDIGO")

	# Pontuacao usa separador de milhar e aceita penalidade negativa.
	if score_label != null:
		score_label.text = _format_hud_number(GameState.score)

	# Nivel e exibido com dois digitos para largura estavel.
	if level_label != null:
		level_label.text = "%02d" % GameState.level

	# Progresso mostra casa atual sobre o total fixo do tabuleiro.
	if progress_label != null:
		progress_label.text = "%02d / %02d" % [GameState.current_house, TOTAL_CASAS]

	# Aproveitamento deriva das respostas desta tentativa local.
	if accuracy_label != null:
		accuracy_label.text = "%d%%" % GameState.get_accuracy_percent()

func _get_player_initials(player_name_value: String) -> String:
	var clean_name := player_name_value.strip_edges()
	# Nome ausente recebe inicial generica de aluno.
	if clean_name.is_empty():
		return "A"
	var words := clean_name.split(" ", false)
	# Nome simples usa apenas sua primeira letra.
	if words.size() == 1:
		return words[0].substr(0, 1).to_upper()
	return (words[0].substr(0, 1) + words[words.size() - 1].substr(0, 1)).to_upper()

func _format_hud_number(value: int) -> String:
	# Insere pontos da direita para a esquerda a cada grupo de tres digitos.
	var digits := str(absi(value))
	var formatted := ""
	# Continua extraindo grupos ate restarem no maximo tres digitos.
	while digits.length() > 3:
		formatted = ".%s%s" % [digits.right(3), formatted]
		digits = digits.left(digits.length() - 3)
	formatted = digits + formatted
	return "-%s" % formatted if value < 0 else formatted

func _notification(what: int) -> void:
	# Fechar a janela encerra apenas o estado local; nao finaliza a partida na API.
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		GameState.finish_session(false)
