extends Control

@onready var input_nome: LineEdit = $PainelCentral/MarginContainer/VBoxContainer/InputNome
@onready var input_codigo: LineEdit = $PainelCentral/MarginContainer/VBoxContainer/InputCodigo
@onready var botao_jogar: Button = $PainelCentral/MarginContainer/VBoxContainer/BotoesAcao/BotaoJogar
@onready var botao_voltar: Button = $PainelCentral/MarginContainer/VBoxContainer/BotoesAcao/BotaoVoltar
@onready var botao_configuracao: TextureButton = $BotaoConfiguracao

var nome_aluno: String = ""
var codigo_sala: String = ""
var music_player: AudioStreamPlayer

func _ready() -> void:
	SettingsManager.pause_tree_when_open = false
	SettingsManager.close_menu()
	_ensure_music_player()
	_play_music()

	botao_jogar.pressed.connect(_on_botao_jogar_pressed)
	botao_voltar.pressed.connect(_on_botao_voltar_pressed)
	botao_configuracao.pressed.connect(_on_botao_configuracao_pressed)
	input_nome.text_submitted.connect(_on_input_nome_submitted)
	input_codigo.text_submitted.connect(_on_input_codigo_submitted)
	input_nome.grab_focus()

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
	GameState.start_session(nome_aluno, codigo_sala)
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
