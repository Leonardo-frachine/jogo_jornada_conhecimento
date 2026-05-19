extends Control

const STATUS_INFO := Color(0.13, 0.22, 0.44, 1.0)
const STATUS_OK := Color(0.18, 0.58, 0.26, 1.0)
const STATUS_ERROR := Color(0.70, 0.17, 0.17, 1.0)

@onready var label_professor: Label = $PainelCentral/MarginContainer/VBoxContainer/Header/LabelProfessor
@onready var label_sala_atual: Label = $PainelCentral/MarginContainer/VBoxContainer/Header/LabelSalaAtual
@onready var label_status: Label = $PainelCentral/MarginContainer/VBoxContainer/LabelStatus
@onready var input_nome_sala: LineEdit = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/BlocoSala/VBoxSala/InputNomeSala
@onready var botao_criar_sala: Button = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/BlocoSala/VBoxSala/AcoesSala/BotaoCriarSala
@onready var seletor_salas: OptionButton = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/BlocoSala/VBoxSala/AcoesSala/SeletorSalas
@onready var botao_atualizar: Button = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/BlocoSala/VBoxSala/AcoesSala/BotaoAtualizar
@onready var botao_importar: Button = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/BlocoPerguntas/VBoxPerguntas/BotaoImportar
@onready var label_indicadores: Label = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/BlocoDashboard/VBoxDashboard/LabelIndicadores
@onready var label_materias: Label = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/BlocoDashboard/VBoxDashboard/LabelMaterias
@onready var label_dificuldades: Label = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/BlocoDashboard/VBoxDashboard/LabelDificuldades
@onready var respostas_box: RichTextLabel = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/BlocoRespostas/VBoxRespostas/ListaRespostas
@onready var botao_sair: Button = $PainelCentral/MarginContainer/VBoxContainer/Footer/BotaoSair
@onready var botao_configuracao: TextureButton = $BotaoConfiguracao

var salas: Array[Dictionary] = []
var carregando := false
var importando_perguntas := false
var import_dialog: FileDialog

func _ready() -> void:
	SettingsManager.pause_tree_when_open = false
	SettingsManager.close_menu()

	if not ProfessorSession.has_session():
		get_tree().change_scene_to_file("res://scene/acesso_professor.tscn")
		return

	botao_criar_sala.pressed.connect(_on_botao_criar_sala_pressed)
	botao_atualizar.pressed.connect(_on_botao_atualizar_pressed)
	botao_importar.pressed.connect(_on_botao_importar_pressed)
	botao_sair.pressed.connect(_on_botao_sair_pressed)
	botao_configuracao.pressed.connect(_on_botao_configuracao_pressed)
	seletor_salas.item_selected.connect(_on_seletor_salas_item_selected)
	_ensure_import_dialog()

	_refresh_header()
	_render_empty_dashboard()
	_load_rooms()

func _refresh_header() -> void:
	label_professor.text = "Professor: %s" % ProfessorSession.professor_name
	if ProfessorSession.has_current_room():
		label_sala_atual.text = "Sala ativa: %s (%s)" % [
			ProfessorSession.current_room_name,
			ProfessorSession.current_room_code,
		]
	else:
		label_sala_atual.text = "Sala ativa: nenhuma sala criada"

func _set_loading_state(enabled: bool) -> void:
	carregando = enabled
	input_nome_sala.editable = not enabled
	botao_criar_sala.disabled = enabled
	botao_atualizar.disabled = enabled
	botao_importar.disabled = enabled or importando_perguntas
	seletor_salas.disabled = enabled or salas.is_empty()
	botao_sair.disabled = enabled

func _ensure_import_dialog() -> void:
	import_dialog = get_node_or_null("ImportDialog")
	if import_dialog == null:
		import_dialog = FileDialog.new()
		import_dialog.name = "ImportDialog"
		import_dialog.access = FileDialog.ACCESS_FILESYSTEM
		import_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		import_dialog.use_native_dialog = true
		import_dialog.title = "Selecionar planilha de perguntas"
		import_dialog.add_filter("*.csv", "Arquivos CSV")
		import_dialog.add_filter("*.xlsx", "Planilhas Excel")
		add_child(import_dialog)

	if not import_dialog.file_selected.is_connected(_on_import_file_selected):
		import_dialog.file_selected.connect(_on_import_file_selected)

func _load_rooms() -> void:
	await _fetch_rooms(true)

func _fetch_rooms(refresh_dashboard_after_load: bool) -> void:
	if carregando:
		return

	_set_loading_state(true)
	_show_status("Carregando salas do professor...", STATUS_INFO)

	var response: Dictionary = await ApiClient.fetch_rooms_by_teacher(ProfessorSession.professor_id)
	_set_loading_state(false)

	if not response.get("ok", false):
		_show_status(response.get("error", "Nao foi possivel carregar as salas."), STATUS_ERROR)
		salas.clear()
		_populate_room_selector()
		_render_empty_dashboard()
		return

	salas = _extract_rooms(response.get("data", []))
	_populate_room_selector()

	if salas.is_empty():
		ProfessorSession.set_current_room({})
		_refresh_header()
		_render_empty_dashboard()
		_show_status("Nenhuma sala criada ainda. Crie a primeira para iniciar o painel.", STATUS_INFO)
		return

	var selected_index := _find_selected_room_index()
	if selected_index < 0:
		selected_index = 0

	seletor_salas.select(selected_index)
	_apply_selected_room(selected_index)
	_show_status("Salas carregadas com sucesso.", STATUS_OK)

	if refresh_dashboard_after_load:
		await _refresh_dashboard()

func _extract_rooms(payload: Variant) -> Array[Dictionary]:
	var extracted: Array[Dictionary] = []
	if payload is not Array:
		return extracted

	for item in payload:
		if item is Dictionary:
			extracted.append(item)

	return extracted

func _populate_room_selector() -> void:
	seletor_salas.clear()

	if salas.is_empty():
		seletor_salas.add_item("Nenhuma sala criada")
		seletor_salas.disabled = true
		return

	for index in range(salas.size()):
		var sala: Dictionary = salas[index]
		var nome: String = str(sala.get("nome", "Sala"))
		var codigo: String = str(sala.get("codigo", ""))
		seletor_salas.add_item("%s (%s)" % [nome, codigo])
		seletor_salas.set_item_metadata(index, sala)

	seletor_salas.disabled = carregando

func _find_selected_room_index() -> int:
	if not ProfessorSession.has_current_room():
		return -1

	for index in range(salas.size()):
		if int(salas[index].get("id", 0)) == ProfessorSession.current_room_id:
			return index

	return -1

func _apply_selected_room(index: int) -> void:
	if index < 0 or index >= salas.size():
		ProfessorSession.set_current_room({})
		_refresh_header()
		return

	ProfessorSession.set_current_room(salas[index])
	_refresh_header()

func _on_seletor_salas_item_selected(index: int) -> void:
	if index < 0 or index >= salas.size() or carregando:
		return

	_apply_selected_room(index)
	await _refresh_dashboard()

func _on_botao_criar_sala_pressed() -> void:
	if carregando:
		return

	var nome_sala: String = input_nome_sala.text.strip_edges()
	_set_loading_state(true)
	_show_status("Criando nova sala...", STATUS_INFO)

	var response: Dictionary = await ApiClient.create_room(ProfessorSession.professor_id, nome_sala)
	_set_loading_state(false)

	if not response.get("ok", false):
		_show_status(response.get("error", "Nao foi possivel criar a sala."), STATUS_ERROR)
		return

	input_nome_sala.text = ""
	var payload: Dictionary = response.get("data", {})
	var sala: Dictionary = payload.get("sala", {})
	if not sala.is_empty():
		ProfessorSession.set_current_room(sala)

	_show_status(payload.get("mensagem", "Sala criada com sucesso."), STATUS_OK)
	await _fetch_rooms(true)

func _on_botao_atualizar_pressed() -> void:
	await _fetch_rooms(true)

func _refresh_dashboard() -> void:
	if carregando:
		return

	if not ProfessorSession.has_current_room():
		_render_empty_dashboard()
		return

	_set_loading_state(true)
	_show_status("Atualizando dashboard da sala...", STATUS_INFO)

	var dashboard_response: Dictionary = await ApiClient.fetch_room_dashboard(ProfessorSession.current_room_id)
	var answers_response: Dictionary = await ApiClient.fetch_room_answers(ProfessorSession.current_room_id)
	_set_loading_state(false)

	if not dashboard_response.get("ok", false):
		_show_status(dashboard_response.get("error", "Nao foi possivel carregar o dashboard."), STATUS_ERROR)
		_render_empty_dashboard()
		return

	if not answers_response.get("ok", false):
		_show_status(answers_response.get("error", "Nao foi possivel carregar as respostas da sala."), STATUS_ERROR)
		_render_answers([])
	else:
		var answers_data: Dictionary = answers_response.get("data", {})
		_render_answers(answers_data.get("respostas", []))

	var dashboard_data: Dictionary = dashboard_response.get("data", {})
	_render_dashboard_data(dashboard_data)
	_show_status("Dashboard atualizado.", STATUS_OK)

func _render_dashboard_data(payload: Dictionary) -> void:
	var indicadores: Dictionary = payload.get("indicadores", {})
	label_indicadores.text = "\n".join([
		"Total de alunos na sala: %d" % int(indicadores.get("totalAlunos", 0)),
		"Total de perguntas respondidas: %d" % int(indicadores.get("totalPerguntasRespondidas", 0)),
		"Quantidade de acertos: %d" % int(indicadores.get("quantidadeAcertos", 0)),
		"Quantidade de erros: %d" % int(indicadores.get("quantidadeErros", 0)),
		"Percentual de acerto da turma: %d%%" % int(indicadores.get("percentualAcertoTurma", 0)),
	])

	label_materias.text = _build_group_text(
		payload.get("desempenhoPorMateria", []),
		"materia",
		"Nenhum dado de materia vinculado ainda."
	)
	label_dificuldades.text = _build_group_text(
		payload.get("desempenhoPorDificuldade", []),
		"dificuldade",
		"Nenhum dado de dificuldade vinculado ainda."
	)

func _build_group_text(groups: Variant, key_name: String, empty_message: String) -> String:
	if groups is not Array or groups.is_empty():
		return empty_message

	var lines: Array[String] = []
	for item in groups:
		if item is not Dictionary:
			continue

		var label_name: String = str(item.get(key_name, "Sem nome"))
		lines.append(
			"%s: %d resp. | %d acertos | %d erros | %d%%" % [
				label_name,
				int(item.get("respondidas", 0)),
				int(item.get("acertos", 0)),
				int(item.get("erros", 0)),
				int(item.get("percentualAcerto", 0)),
			]
		)

	return "\n".join(lines) if not lines.is_empty() else empty_message

func _render_answers(respostas: Variant) -> void:
	if respostas is not Array or respostas.is_empty():
		respostas_box.text = "Nenhuma resposta vinculada a esta sala ainda."
		return

	var lines: Array[String] = []
	for item in respostas:
		if item is not Dictionary:
			continue

		var status: String = "Acertou" if bool(item.get("acertou", false)) else "Errou"
		lines.append(
			"%s | %s | %s | %s | %d pts" % [
				str(item.get("aluno", "Aluno")),
				str(item.get("materia", "Sem materia")),
				str(item.get("dificuldade", "Sem dificuldade")),
				status,
				int(item.get("pontuacaoGanha", 0)),
			]
		)
		lines.append("Pergunta: %s" % str(item.get("enunciado", "")))
		lines.append("")

	respostas_box.text = "\n".join(lines).strip_edges()

func _render_empty_dashboard() -> void:
	label_indicadores.text = "\n".join([
		"Total de alunos na sala: 0",
		"Total de perguntas respondidas: 0",
		"Quantidade de acertos: 0",
		"Quantidade de erros: 0",
		"Percentual de acerto da turma: 0%",
	])
	label_materias.text = "Nenhum dado de materia vinculado ainda."
	label_dificuldades.text = "Nenhum dado de dificuldade vinculado ainda."
	respostas_box.text = "Nenhuma resposta vinculada a esta sala ainda."

func _on_botao_importar_pressed() -> void:
	if carregando or importando_perguntas or import_dialog == null:
		return

	_show_status("Selecione uma planilha .csv ou .xlsx para importar as perguntas.", STATUS_INFO)
	import_dialog.popup_centered_ratio(0.75)

func _on_import_file_selected(path: String) -> void:
	if importando_perguntas:
		return

	importando_perguntas = true
	botao_importar.disabled = true
	botao_importar.text = "Importando..."
	_show_status("Importando perguntas para o banco de dados...", STATUS_INFO)

	var response: Dictionary = await ApiClient.import_questions_spreadsheet(path)

	importando_perguntas = false
	botao_importar.disabled = carregando
	botao_importar.text = "Importar Perguntas"

	if not response.get("ok", false):
		_show_status(response.get("error", "Nao foi possivel importar a planilha."), STATUS_ERROR)
		return

	var payload: Dictionary = response.get("data", {})
	var imported_count: int = int(payload.get("total", 0))
	_show_status("%d perguntas importadas com sucesso." % imported_count, STATUS_OK)

func _on_botao_sair_pressed() -> void:
	ProfessorSession.clear_session()
	get_tree().change_scene_to_file("res://scene/acesso_professor.tscn")

func _on_botao_configuracao_pressed() -> void:
	SettingsManager.open_menu()

func _show_status(message: String, color_value: Color) -> void:
	label_status.text = message
	label_status.modulate = color_value
