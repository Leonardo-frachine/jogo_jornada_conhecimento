extends Control

const UITheme := preload("res://scripts/UITheme.gd")

@onready var painel_central: Panel = $PainelCentral
@onready var titulo: Label = $PainelCentral/MarginContainer/VBoxContainer/Titulo
@onready var subtitulo: Label = $PainelCentral/MarginContainer/VBoxContainer/Subtitulo
@onready var label_nome: Label = $PainelCentral/MarginContainer/VBoxContainer/LabelNome
@onready var input_nome: LineEdit = $PainelCentral/MarginContainer/VBoxContainer/InputNome
@onready var label_codigo: Label = $PainelCentral/MarginContainer/VBoxContainer/LabelCodigo
@onready var input_codigo: LineEdit = $PainelCentral/MarginContainer/VBoxContainer/InputCodigo
@onready var botao_personagem_1: Button = $PainelCentral/MarginContainer/VBoxContainer/PersonagensContainer/BotaoPersonagem1
@onready var botao_personagem_2: Button = $PainelCentral/MarginContainer/VBoxContainer/PersonagensContainer/BotaoPersonagem2
@onready var botao_jogar: Button = $PainelCentral/MarginContainer/VBoxContainer/BotoesAcao/BotaoJogar
@onready var botao_voltar: Button = $PainelCentral/MarginContainer/VBoxContainer/BotoesAcao/BotaoVoltar
@onready var botao_configuracao: TextureButton = $BotaoConfiguracao

var nome_aluno: String = ""
var codigo_sala: String = ""
var music_player: AudioStreamPlayer
var personagem_selecionado: int = 1
var estilo_personagem_normal: StyleBox
var estilo_personagem_selecionado: StyleBox

func _ready() -> void:
	SettingsManager.pause_tree_when_open = false
	SettingsManager.close_menu()
	_ensure_music_player()
	if not SettingsManager.settings_changed.is_connected(_on_settings_changed):
		SettingsManager.settings_changed.connect(_on_settings_changed)
	_sync_music_state()
	_apply_visual_refresh()

	_preparar_botoes_personagem()
	botao_jogar.pressed.connect(_on_botao_jogar_pressed)
	botao_voltar.pressed.connect(_on_botao_voltar_pressed)
	botao_configuracao.pressed.connect(_on_botao_configuracao_pressed)
	input_nome.text_submitted.connect(_on_input_nome_submitted)
	input_codigo.text_submitted.connect(_on_input_codigo_submitted)
	input_nome.grab_focus()

func _apply_visual_refresh() -> void:
	UITheme.apply_surface_panel(painel_central)
	UITheme.apply_font_tree(painel_central)
	UITheme.apply_title(titulo, 38)
	UITheme.apply_subtitle(subtitulo, 16)
	UITheme.apply_field_label(label_nome)
	UITheme.apply_field_label(label_codigo)
	UITheme.apply_line_edit(input_nome, 18)
	UITheme.apply_line_edit(input_codigo, 18)
	UITheme.apply_button(botao_jogar, UITheme.BUTTON_PRIMARY, 20)
	UITheme.apply_button(botao_voltar, UITheme.BUTTON_SECONDARY, 19)

func _preparar_botoes_personagem() -> void:
	estilo_personagem_selecionado = botao_personagem_1.get_theme_stylebox("normal").duplicate()
	estilo_personagem_normal = botao_personagem_2.get_theme_stylebox("normal").duplicate()

	botao_personagem_1.pressed.connect(_selecionar_personagem.bind(1))
	botao_personagem_2.pressed.connect(_selecionar_personagem.bind(2))
	_atualizar_selecao_personagem()

func _selecionar_personagem(indice: int) -> void:
	personagem_selecionado = indice
	_atualizar_selecao_personagem()

func _atualizar_selecao_personagem() -> void:
	_aplicar_estilo_personagem(botao_personagem_1, personagem_selecionado == 1)
	_aplicar_estilo_personagem(botao_personagem_2, personagem_selecionado == 2)

func _aplicar_estilo_personagem(botao: Button, selecionado: bool) -> void:
	var estilo_base: StyleBox = estilo_personagem_selecionado if selecionado else estilo_personagem_normal
	var estilo_interacao: StyleBox = estilo_personagem_selecionado

	botao.add_theme_stylebox_override("normal", estilo_base)
	botao.add_theme_stylebox_override("hover", estilo_interacao)
	botao.add_theme_stylebox_override("pressed", estilo_interacao)
	botao.add_theme_stylebox_override("focus", estilo_base)

func _ensure_music_player() -> void:
	music_player = get_node_or_null("MenuMusic")
	if music_player != null:
		return
	music_player = AudioStreamPlayer.new()
	music_player.name = "MenuMusic"
	music_player.bus = "Music"
	music_player.stream = load("res://assets/audio/menu_theme.wav")
	music_player.autoplay = false
	add_child(music_player)

func _play_music() -> void:
	if music_player == null or music_player.stream == null:
		return
	if SettingsManager.music_enabled and not music_player.playing:
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

func _on_input_nome_submitted(_texto: String) -> void:
	input_codigo.grab_focus()

func _on_input_codigo_submitted(_texto: String) -> void:
	_on_botao_jogar_pressed()

func _on_botao_configuracao_pressed() -> void:
	SettingsManager.open_menu()

func _on_botao_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/selecao_perfil.tscn")

func _on_botao_jogar_pressed() -> void:
	if not validar_campos():
		return

	SettingsManager.close_menu()
	GameState.start_session(nome_aluno, codigo_sala, personagem_selecionado)
	get_tree().change_scene_to_file("res://scene/loading_screen.tscn")

func validar_campos() -> bool:
	nome_aluno = input_nome.text.strip_edges()
	codigo_sala = input_codigo.text.strip_edges()

	if nome_aluno.is_empty():
		mostrar_alerta("Por favor, informe o nome do aluno.")
		input_nome.grab_focus()
		return false

	if codigo_sala.is_empty():
		mostrar_alerta("Por favor, informe o codigo da sala.")
		input_codigo.grab_focus()
		return false

	return true

func mostrar_alerta(mensagem: String) -> void:
	var dialog := AcceptDialog.new()
	add_child(dialog)
	dialog.title = "Atencao"
	dialog.dialog_text = mensagem
	dialog.popup_centered()
