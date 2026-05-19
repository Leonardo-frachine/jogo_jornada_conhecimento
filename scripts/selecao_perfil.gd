extends Control

@onready var botao_aluno: Button = $PainelCentral/MarginContainer/VBoxContainer/BotaoAluno
@onready var botao_professor: Button = $PainelCentral/MarginContainer/VBoxContainer/BotaoProfessor
@onready var botao_configuracao: TextureButton = $BotaoConfiguracao

var music_player: AudioStreamPlayer

func _ready() -> void:
	SettingsManager.pause_tree_when_open = false
	SettingsManager.close_menu()
	_ensure_music_player()
	_play_music()

	botao_aluno.pressed.connect(_on_botao_aluno_pressed)
	botao_professor.pressed.connect(_on_botao_professor_pressed)
	botao_configuracao.pressed.connect(_on_botao_configuracao_pressed)
	botao_aluno.grab_focus()

func _ensure_music_player() -> void:
	music_player = get_node_or_null("MenuMusic")
	if music_player != null:
		return

	music_player = AudioStreamPlayer.new()
	music_player.name = "MenuMusic"
	music_player.bus = "Music"
	music_player.stream = load("res://assets/audio/menu_theme.wav")
	add_child(music_player)

func _play_music() -> void:
	if music_player == null or music_player.stream == null:
		return
	if SettingsManager.music_enabled and not music_player.playing:
		music_player.play()

func _on_botao_aluno_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/tela_inicial.tscn")

func _on_botao_professor_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/acesso_professor.tscn")

func _on_botao_configuracao_pressed() -> void:
	SettingsManager.open_menu()
