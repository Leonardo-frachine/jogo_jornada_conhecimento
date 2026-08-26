extends Control

# Entrada do aluno: coleta identidade, codigo da sala e personagem antes do loading.
const UITheme := preload("res://scripts/UITheme.gd")

@onready var painel_central: Panel = $PainelCentral
@onready var titulo: Label = $PainelCentral/MarginContainer/VBoxContainer/Titulo
@onready var subtitulo: Label = $PainelCentral/MarginContainer/VBoxContainer/Subtitulo
@onready var label_personagem: Label = $PainelCentral/MarginContainer/VBoxContainer/LabelPersonagem
@onready var label_nome: Label = $PainelCentral/MarginContainer/VBoxContainer/FieldsRow/NameField/LabelNome
@onready var input_nome: LineEdit = $PainelCentral/MarginContainer/VBoxContainer/FieldsRow/NameField/InputNome
@onready var label_codigo: Label = $PainelCentral/MarginContainer/VBoxContainer/FieldsRow/RoomField/LabelCodigo
@onready var input_codigo: LineEdit = $PainelCentral/MarginContainer/VBoxContainer/FieldsRow/RoomField/InputCodigo
@onready var botoes_personagem: Array[Button] = [
	$PainelCentral/MarginContainer/VBoxContainer/PersonagensContainer/BotaoPersonagem1,
	$PainelCentral/MarginContainer/VBoxContainer/PersonagensContainer/BotaoPersonagem2,
	$PainelCentral/MarginContainer/VBoxContainer/PersonagensContainer/BotaoPersonagem3,
	$PainelCentral/MarginContainer/VBoxContainer/PersonagensContainer/BotaoPersonagem4,
	$PainelCentral/MarginContainer/VBoxContainer/PersonagensContainer/BotaoPersonagem5,
]
@onready var botao_jogar: Button = $PainelCentral/MarginContainer/VBoxContainer/BotoesAcao/BotaoJogar
@onready var botao_voltar: Button = $PainelCentral/MarginContainer/VBoxContainer/BotoesAcao/BotaoVoltar
@onready var botao_configuracao: TextureButton = $BotaoConfiguracao

var nome_aluno: String = ""
var codigo_sala: String = ""
var personagem_selecionado: int = 1
var estilo_personagem_normal: StyleBox
var estilo_personagem_selecionado: StyleBox

const NOMES_PERSONAGENS: Array[String] = ["Cachorro", "Leão", "Tartaruga", "Águia", "Gato"]

func _ready() -> void:
	# Prepara visual, selecao inicial e navegacao por teclado.
	SettingsManager.pause_tree_when_open = false
	SettingsManager.close_menu()
	AudioManager.play_menu_music()
	_apply_visual_refresh()

	_preparar_botoes_personagem()
	botao_jogar.pressed.connect(_on_botao_jogar_pressed)
	botao_voltar.pressed.connect(_on_botao_voltar_pressed)
	botao_configuracao.pressed.connect(_on_botao_configuracao_pressed)
	input_nome.text_submitted.connect(_on_input_nome_submitted)
	input_codigo.text_submitted.connect(_on_input_codigo_submitted)
	input_nome.grab_focus()
	# Resize do desktop/Web reposiciona o painel e redistribui personagens.
	if not get_viewport().size_changed.is_connected(_update_responsive_layout):
		get_viewport().size_changed.connect(_update_responsive_layout)
	# Mudanca de acessibilidade reestiliza e recalcula os limites do formulario.
	if not SettingsManager.font_scale_changed.is_connected(_on_font_scale_changed):
		SettingsManager.font_scale_changed.connect(_on_font_scale_changed)
	_update_responsive_layout()

func _apply_visual_refresh() -> void:
	# Aplica a mesma tipografia a cada nome de personagem.
	UITheme.apply_surface_panel(painel_central)
	UITheme.apply_font_tree(painel_central)
	UITheme.apply_title(titulo, 38)
	UITheme.apply_subtitle(subtitulo, 16)
	UITheme.apply_font_only(label_personagem, 18)
	UITheme.apply_field_label(label_nome)
	UITheme.apply_field_label(label_codigo)
	UITheme.apply_line_edit(input_nome, 18)
	UITheme.apply_line_edit(input_codigo, 18)
	UITheme.apply_button(botao_jogar, UITheme.BUTTON_PRIMARY, 20)
	UITheme.apply_button(botao_voltar, UITheme.BUTTON_SECONDARY, 19)
	subtitulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Uniformiza fonte e cor dos nomes exibidos nos cards de personagem.
	for botao in botoes_personagem:
		var nome_personagem := botao.get_node("Content/Nome") as Label
		UITheme.apply_font_only(nome_personagem, 15)
		nome_personagem.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)

func _update_responsive_layout() -> void:
	# O painel usa quase todo o viewport, mas respeita dimensoes adequadas para desktop.
	var viewport_size := get_viewport_rect().size
	var font_scale := SettingsManager.font_scale
	var panel_width := minf(viewport_size.x - 32.0, 1120.0 + 100.0 * (font_scale - 1.0))
	var panel_height := minf(viewport_size.y - 24.0, 540.0 + 100.0 * (font_scale - 1.0))
	painel_central.offset_left = -panel_width * 0.5
	painel_central.offset_right = panel_width * 0.5
	painel_central.offset_top = -panel_height * 0.5
	painel_central.offset_bottom = panel_height * 0.5
	painel_central.custom_minimum_size = Vector2(panel_width, panel_height)
	var character_height := 165.0 if viewport_size.y <= 720.0 else 190.0
	var character_width := maxf(100.0, floorf((panel_width - 108.0) / float(botoes_personagem.size())))
	# Cada card recebe uma fracao uniforme da largura disponivel.
	for botao in botoes_personagem:
		botao.custom_minimum_size = Vector2(character_width, character_height)

func _on_font_scale_changed(_value: float) -> void:
	_apply_visual_refresh()
	call_deferred("_update_responsive_layout")

func _preparar_botoes_personagem() -> void:
	# Reaproveita os estilos da cena para representar selecao e estado normal.
	estilo_personagem_selecionado = botoes_personagem[0].get_theme_stylebox("normal").duplicate()
	estilo_personagem_normal = botoes_personagem[1].get_theme_stylebox("normal").duplicate()

	# Liga cada botao ao indice de personagem correspondente, iniciado em 1.
	for indice in botoes_personagem.size():
		botoes_personagem[indice].pressed.connect(_selecionar_personagem.bind(indice + 1))
	_atualizar_selecao_personagem()

func _selecionar_personagem(indice: int) -> void:
	# Guarda a escolha para a sessao que sera iniciada ao validar o formulario.
	personagem_selecionado = indice
	_atualizar_selecao_personagem()

func _atualizar_selecao_personagem() -> void:
	# Atualiza todos os cards para que somente o escolhido use o estilo selecionado.
	label_personagem.text = "Seu companheiro: %s" % NOMES_PERSONAGENS[personagem_selecionado - 1]
	# Compara cada indice com a escolha atual para atualizar seu estilo.
	for indice in botoes_personagem.size():
		_aplicar_estilo_personagem(botoes_personagem[indice], personagem_selecionado == indice + 1)

func _aplicar_estilo_personagem(botao: Button, selecionado: bool) -> void:
	var estilo_base: StyleBox = estilo_personagem_selecionado if selecionado else estilo_personagem_normal
	var estilo_interacao: StyleBox = estilo_personagem_selecionado

	botao.add_theme_stylebox_override("normal", estilo_base)
	botao.add_theme_stylebox_override("hover", estilo_interacao)
	botao.add_theme_stylebox_override("pressed", estilo_interacao)
	botao.add_theme_stylebox_override("focus", estilo_base)

func _on_input_nome_submitted(_texto: String) -> void:
	input_codigo.grab_focus()

func _on_input_codigo_submitted(_texto: String) -> void:
	_on_botao_jogar_pressed()

func _on_botao_configuracao_pressed() -> void:
	SettingsManager.open_menu()

func _on_botao_voltar_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/selecao_perfil.tscn")

func _on_botao_jogar_pressed() -> void:
	# Nao inicia loading enquanto nome ou codigo estiverem ausentes.
	if not validar_campos():
		return

	SettingsManager.close_menu()
	GameState.start_session(nome_aluno, codigo_sala, personagem_selecionado)
	get_tree().change_scene_to_file("res://scene/loading_screen.tscn")

func validar_campos() -> bool:
	# Remove espacos acidentais antes de aplicar as regras obrigatorias.
	nome_aluno = input_nome.text.strip_edges()
	codigo_sala = input_codigo.text.strip_edges()

	# Nome vazio impede identificar o aluno na sala e nos relatorios.
	if nome_aluno.is_empty():
		mostrar_alerta("Por favor, informe o nome do aluno.")
		input_nome.grab_focus()
		return false

	# Codigo vazio impede resolver a turma correta no backend.
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
	# Somente dados validados entram no estado global da nova sessao.
