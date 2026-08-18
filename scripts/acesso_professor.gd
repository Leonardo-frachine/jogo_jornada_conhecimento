extends Control

const UITheme := preload("res://scripts/UITheme.gd")
const STATUS_INFO := UITheme.STATUS_INFO
const STATUS_OK := UITheme.STATUS_SUCCESS
const STATUS_ERROR := UITheme.STATUS_ERROR

@onready var background: TextureRect = $Background
@onready var painel_central: Panel = $PainelCentral
@onready var titulo: Label = $PainelCentral/MarginContainer/VBoxContainer/Titulo
@onready var subtitulo: Label = $PainelCentral/MarginContainer/VBoxContainer/Subtitulo
@onready var botao_entrar: Button = $PainelCentral/MarginContainer/VBoxContainer/Modos/BotaoEntrar
@onready var botao_cadastrar: Button = $PainelCentral/MarginContainer/VBoxContainer/Modos/BotaoCadastrar
@onready var label_status: Label = $PainelCentral/MarginContainer/VBoxContainer/LabelStatus
@onready var grupo_nome: VBoxContainer = $PainelCentral/MarginContainer/VBoxContainer/GrupoNome
@onready var label_nome: Label = $PainelCentral/MarginContainer/VBoxContainer/GrupoNome/LabelNome
@onready var input_nome: LineEdit = $PainelCentral/MarginContainer/VBoxContainer/GrupoNome/InputNome
@onready var label_email: Label = $PainelCentral/MarginContainer/VBoxContainer/GrupoEmail/LabelEmail
@onready var input_email: LineEdit = $PainelCentral/MarginContainer/VBoxContainer/GrupoEmail/InputEmail
@onready var label_senha: Label = $PainelCentral/MarginContainer/VBoxContainer/GrupoSenha/LabelSenha
@onready var input_senha: LineEdit = $PainelCentral/MarginContainer/VBoxContainer/GrupoSenha/InputSenha
@onready var botao_acao: Button = $PainelCentral/MarginContainer/VBoxContainer/BotaoAcao
@onready var botao_alternar: Button = $PainelCentral/MarginContainer/VBoxContainer/BotaoAlternar
@onready var botao_voltar: Button = $PainelCentral/MarginContainer/VBoxContainer/BotaoVoltar
@onready var personagem: TextureRect = get_node_or_null("Personagem") as TextureRect
@onready var botao_configuracao: TextureButton = $BotaoConfiguracao

var modo_cadastro := false
var requisicao_em_andamento := false

func _ready() -> void:
	SettingsManager.pause_tree_when_open = false
	SettingsManager.close_menu()
	ProfessorSession.clear_session()
	_apply_visual_refresh()

	botao_entrar.pressed.connect(func() -> void:
		_set_modo(false)
	)
	botao_cadastrar.pressed.connect(func() -> void:
		_set_modo(true)
	)
	botao_acao.pressed.connect(_on_botao_acao_pressed)
	botao_alternar.pressed.connect(_on_botao_alternar_pressed)
	botao_voltar.pressed.connect(_on_botao_voltar_pressed)
	botao_configuracao.pressed.connect(_on_botao_configuracao_pressed)
	input_email.text_submitted.connect(_on_input_email_submitted)
	input_senha.text_submitted.connect(_on_input_senha_submitted)
	input_nome.text_submitted.connect(_on_input_nome_submitted)

	_update_layout()
	if not get_viewport().size_changed.is_connected(_update_layout):
		get_viewport().size_changed.connect(_update_layout)
	if not SettingsManager.font_scale_changed.is_connected(_on_font_scale_changed):
		SettingsManager.font_scale_changed.connect(_on_font_scale_changed)

	_set_modo(false)

func _apply_visual_refresh() -> void:
	UITheme.apply_surface_panel(painel_central)
	UITheme.apply_font_tree(painel_central)
	UITheme.apply_title(titulo, 36)
	UITheme.apply_subtitle(subtitulo, 16)
	UITheme.apply_field_label(label_nome)
	UITheme.apply_field_label(label_email)
	UITheme.apply_field_label(label_senha)
	UITheme.apply_subtitle(label_status, 14, STATUS_INFO)
	UITheme.apply_line_edit(input_nome, 18)
	UITheme.apply_line_edit(input_email, 18)
	UITheme.apply_line_edit(input_senha, 18)
	UITheme.apply_button(botao_acao, UITheme.BUTTON_PRIMARY, 20)
	UITheme.apply_button(botao_alternar, UITheme.BUTTON_SURFACE, 17)
	UITheme.apply_button(botao_voltar, UITheme.BUTTON_SECONDARY, 17)
	label_status.custom_minimum_size.y = 38.0
	_update_mode_button_styles()

func _update_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var font_scale: float = SettingsManager.font_scale
	var compact_width: bool = viewport_size.x < 1180.0
	var compact_height: bool = viewport_size.y < 760.0
	var panel_width: float = clampf(viewport_size.x * 0.46, 480.0, 600.0 + 120.0 * (font_scale - 1.0))
	var panel_height: float = clampf(viewport_size.y - (32.0 if compact_height else 72.0), 600.0, 700.0 + 120.0 * (font_scale - 1.0))

	painel_central.offset_left = -panel_width * 0.5
	painel_central.offset_top = -panel_height * 0.5
	painel_central.offset_right = panel_width * 0.5
	painel_central.offset_bottom = panel_height * 0.5
	painel_central.custom_minimum_size = Vector2(panel_width, panel_height)

	if background != null:
		background.size = viewport_size

	if personagem != null:
		personagem.visible = viewport_size.x >= 1180.0 and viewport_size.y >= 700.0
		if personagem.visible:
			var character_width: float = clampf(viewport_size.x * 0.23, 260.0, 360.0)
			var character_height: float = character_width * 1.08
			personagem.position = Vector2(maxf(24.0, viewport_size.x * 0.05), viewport_size.y - character_height - 14.0)
			personagem.size = Vector2(character_width, character_height)

	if botao_configuracao != null:
		var settings_size: float = 72.0 if compact_width else 84.0
		botao_configuracao.anchor_left = 0.0
		botao_configuracao.anchor_top = 0.0
		botao_configuracao.anchor_right = 0.0
		botao_configuracao.anchor_bottom = 0.0
		botao_configuracao.custom_minimum_size = Vector2(settings_size, settings_size)
		botao_configuracao.size = Vector2(settings_size, settings_size)
		botao_configuracao.position = Vector2(viewport_size.x - settings_size - 18.0, 18.0)

func _on_font_scale_changed(_value: float) -> void:
	_apply_visual_refresh()
	call_deferred("_update_layout")

func _update_mode_button_styles() -> void:
	UITheme.apply_button(
		botao_entrar,
		UITheme.BUTTON_TAB_ACTIVE if not modo_cadastro else UITheme.BUTTON_TAB_INACTIVE,
		17
	)
	UITheme.apply_button(
		botao_cadastrar,
		UITheme.BUTTON_TAB_ACTIVE if modo_cadastro else UITheme.BUTTON_TAB_INACTIVE,
		17
	)

func _set_modo(cadastro: bool) -> void:
	modo_cadastro = cadastro
	titulo.text = "Cadastro de Professor" if modo_cadastro else "Login do Professor"
	subtitulo.text = "Crie seu acesso para gerenciar salas." if modo_cadastro else "Entre para acompanhar a sua turma."
	grupo_nome.visible = modo_cadastro
	botao_acao.text = "CRIAR CONTA" if modo_cadastro else "ENTRAR"
	botao_alternar.text = "JA TENHO CONTA" if modo_cadastro else "QUERO ME CADASTRAR"
	botao_entrar.disabled = requisicao_em_andamento
	botao_cadastrar.disabled = requisicao_em_andamento
	label_status.text = ""
	_update_mode_button_styles()

	if modo_cadastro:
		input_nome.grab_focus()
	else:
		input_email.grab_focus()

func _on_input_nome_submitted(_texto: String) -> void:
	input_email.grab_focus()

func _on_input_email_submitted(_texto: String) -> void:
	input_senha.grab_focus()

func _on_input_senha_submitted(_texto: String) -> void:
	_on_botao_acao_pressed()

func _on_botao_alternar_pressed() -> void:
	_set_modo(not modo_cadastro)

func _on_botao_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/selecao_perfil.tscn")

func _on_botao_configuracao_pressed() -> void:
	SettingsManager.open_menu()

func _on_botao_acao_pressed() -> void:
	if requisicao_em_andamento:
		return

	var nome: String = input_nome.text.strip_edges()
	var email: String = input_email.text.strip_edges()
	var senha: String = input_senha.text.strip_edges()

	if modo_cadastro and nome.is_empty():
		_show_status("Informe o nome do professor para continuar.", STATUS_ERROR)
		input_nome.grab_focus()
		return

	if email.is_empty():
		_show_status("Informe o e-mail do professor.", STATUS_ERROR)
		input_email.grab_focus()
		return

	if senha.is_empty():
		_show_status("Informe a senha do professor.", STATUS_ERROR)
		input_senha.grab_focus()
		return

	if not email.contains("@"):
		_show_status("Digite um e-mail valido.", STATUS_ERROR)
		input_email.grab_focus()
		return

	requisicao_em_andamento = true
	_set_form_enabled(false)
	_show_status("Conectando ao backend...", STATUS_INFO)

	var response: Dictionary = {}
	if modo_cadastro:
		response = await ApiClient.register_teacher(nome, email, senha)
	else:
		response = await ApiClient.login_teacher(email, senha)

	requisicao_em_andamento = false
	_set_form_enabled(true)

	if not response.get("ok", false):
		_show_status(response.get("error", "Nao foi possivel concluir o acesso do professor."), STATUS_ERROR)
		return

	var payload: Dictionary = response.get("data", {})
	var professor: Dictionary = payload.get("professor", {})
	if professor.is_empty():
		_show_status("A API nao retornou os dados do professor.", STATUS_ERROR)
		return

	ProfessorSession.start_session(professor)
	_show_status(payload.get("mensagem", "Acesso liberado com sucesso."), STATUS_OK)
	await get_tree().create_timer(0.35).timeout
	get_tree().change_scene_to_file("res://scene/painel_professor.tscn")

func _set_form_enabled(enabled: bool) -> void:
	input_nome.editable = enabled
	input_email.editable = enabled
	input_senha.editable = enabled
	botao_acao.disabled = not enabled
	botao_alternar.disabled = not enabled
	botao_entrar.disabled = not enabled
	botao_cadastrar.disabled = not enabled
	botao_voltar.disabled = not enabled
	_update_mode_button_styles()

func _show_status(message: String, color_value: Color) -> void:
	label_status.text = message
	label_status.add_theme_color_override("font_color", color_value)
