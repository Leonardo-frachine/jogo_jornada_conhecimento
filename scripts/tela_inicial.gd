extends Control

@onready var input_nome: LineEdit = $PainelCentral/MarginContainer/VBoxContainer/InputNome
@onready var input_codigo: LineEdit = $PainelCentral/MarginContainer/VBoxContainer/InputCodigo
@onready var botao_jogar: Button = $PainelCentral/MarginContainer/VBoxContainer/BotaoJogar
@onready var botao_configuracao: TextureButton = $BotaoConfiguracao

var nome_aluno: String = ""
var codigo_sala: String = ""

func _ready() -> void:
	botao_jogar.pressed.connect(_on_botao_jogar_pressed)
	botao_configuracao.pressed.connect(_on_botao_configuracao_pressed)

	input_nome.text_submitted.connect(_on_input_nome_submitted)
	input_codigo.text_submitted.connect(_on_input_codigo_submitted)

	input_nome.grab_focus()
	
func _on_input_nome_submitted(_texto: String) -> void:
	input_codigo.grab_focus()

func _on_input_codigo_submitted(_texto: String) -> void:
	_on_botao_jogar_pressed()

func _on_botao_configuracao_pressed() -> void:
	# Anexar a rota da tela de configuração aqui
	get_tree().change_scene_to_file("res://scene/settings/root.tscn")
	print("Botão de configuração clicado.")

func _on_botao_jogar_pressed() -> void:
	if not validar_campos():
		return

	print("Nome do aluno: ", nome_aluno)
	print("Código da sala: ", codigo_sala)

	# Anexar a rota da tela de carregamento aqui
	get_tree().change_scene_to_file("res://scene/loading_screen.tscn")
	print("Botão jogar clicado.")

func validar_campos() -> bool:
	nome_aluno = input_nome.text.strip_edges()
	codigo_sala = input_codigo.text.strip_edges()

	if nome_aluno.is_empty():
		mostrar_alerta("Por favor, informe o nome do aluno.")
		input_nome.grab_focus()
		return false

	if codigo_sala.is_empty():
		mostrar_alerta("Por favor, informe o código da sala.")
		input_codigo.grab_focus()
		return false

	return true

func mostrar_alerta(mensagem: String) -> void:
	var dialog := AcceptDialog.new()
	add_child(dialog)
	dialog.title = "Atenção"
	dialog.dialog_text = mensagem
	dialog.popup_centered()
