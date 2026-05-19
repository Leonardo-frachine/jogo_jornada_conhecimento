extends Control

const STATUS_INFO := Color(0.13, 0.22, 0.44, 1.0)
const STATUS_OK := Color(0.18, 0.58, 0.26, 1.0)
const STATUS_ERROR := Color(0.70, 0.17, 0.17, 1.0)

const IA_STATUS_PENDING := "pendente"
const IA_STATUS_APPROVED := "aprovada"
const IA_STATUS_REJECTED := "rejeitada"
const IA_DIFFICULTIES: Array[String] = ["Facil", "Medio", "Dificil", "Especial"]
const IA_CORRECT_OPTIONS: Array[String] = ["A", "B", "C", "D"]

@onready var label_professor: Label = $PainelCentral/MarginContainer/VBoxContainer/Header/LabelProfessor
@onready var label_sala_atual: Label = $PainelCentral/MarginContainer/VBoxContainer/Header/LabelSalaAtual
@onready var label_status: Label = $PainelCentral/MarginContainer/VBoxContainer/LabelStatus
@onready var input_nome_sala: LineEdit = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/BlocoSala/VBoxSala/InputNomeSala
@onready var botao_criar_sala: Button = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/BlocoSala/VBoxSala/AcoesSala/BotaoCriarSala
@onready var seletor_salas: OptionButton = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/BlocoSala/VBoxSala/AcoesSala/SeletorSalas
@onready var botao_atualizar: Button = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/BlocoSala/VBoxSala/AcoesSala/BotaoAtualizar
@onready var botao_importar: Button = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/BlocoPerguntas/VBoxPerguntas/BotaoImportar
@onready var ia_area: VBoxContainer = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/BlocoPerguntas/VBoxPerguntas/IaArea
@onready var label_indicadores: Label = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/BlocoDashboard/VBoxDashboard/LabelIndicadores
@onready var label_materias: Label = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/BlocoDashboard/VBoxDashboard/LabelMaterias
@onready var label_dificuldades: Label = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/BlocoDashboard/VBoxDashboard/LabelDificuldades
@onready var respostas_box: RichTextLabel = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/BlocoRespostas/VBoxRespostas/ListaRespostas
@onready var botao_sair: Button = $PainelCentral/MarginContainer/VBoxContainer/Footer/BotaoSair
@onready var botao_configuracao: TextureButton = $BotaoConfiguracao

var salas: Array[Dictionary] = []
var carregando := false
var importando_perguntas := false
var ia_processando := false
var ia_salvando := false
var import_dialog: FileDialog

var perguntas_geradas: Array[Dictionary] = []
var cards_perguntas_ia: Array[Dictionary] = []

var ia_tema_input: LineEdit
var ia_materia_input: LineEdit
var ia_dificuldade_select: OptionButton
var ia_quantidade_input: SpinBox
var ia_pontuacao_input: SpinBox
var ia_tempo_input: SpinBox
var ia_botao_gerar: Button
var ia_botao_salvar: Button
var ia_label_feedback: Label
var ia_label_resumo: Label
var ia_lista: VBoxContainer

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
	_build_ai_section()

	_refresh_header()
	_render_empty_dashboard()
	_render_generated_questions()
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
	_update_ia_controls_state()

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

func _build_ai_section() -> void:
	if ia_area == null:
		return

	for child in ia_area.get_children():
		child.queue_free()

	var title: Label = Label.new()
	title.text = "Gerar perguntas com IA"
	ia_area.add_child(title)

	var description: Label = Label.new()
	description.text = "Use o Gemini para sugerir perguntas, revise cada item e salve apenas o que for aprovado."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ia_area.add_child(description)

	var form_grid: GridContainer = GridContainer.new()
	form_grid.columns = 2
	form_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form_grid.add_theme_constant_override("h_separation", 12)
	form_grid.add_theme_constant_override("v_separation", 10)
	ia_area.add_child(form_grid)

	ia_tema_input = _create_line_edit("Tema das perguntas")
	_add_labeled_control(form_grid, "Tema", ia_tema_input)

	ia_materia_input = _create_line_edit("Materia")
	_add_labeled_control(form_grid, "Materia", ia_materia_input)

	ia_dificuldade_select = OptionButton.new()
	ia_dificuldade_select.custom_minimum_size = Vector2(0, 44)
	for difficulty in IA_DIFFICULTIES:
		ia_dificuldade_select.add_item(difficulty)
	ia_dificuldade_select.select(1)
	_add_labeled_control(form_grid, "Dificuldade", ia_dificuldade_select)

	ia_quantidade_input = _create_spin_box(1, 20, 5)
	_add_labeled_control(form_grid, "Quantidade", ia_quantidade_input)

	ia_pontuacao_input = _create_spin_box(1, 10000, 100)
	_add_labeled_control(form_grid, "Pontuacao", ia_pontuacao_input)

	ia_tempo_input = _create_spin_box(0, 3600, 30)
	_add_labeled_control(form_grid, "Tempo limite (0 = opcional)", ia_tempo_input)

	var button_row: HBoxContainer = HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 10)
	ia_area.add_child(button_row)

	ia_botao_gerar = Button.new()
	ia_botao_gerar.custom_minimum_size = Vector2(0, 44)
	ia_botao_gerar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ia_botao_gerar.text = "Gerar com IA"
	ia_botao_gerar.pressed.connect(_on_botao_gerar_ia_pressed)
	button_row.add_child(ia_botao_gerar)

	ia_botao_salvar = Button.new()
	ia_botao_salvar.custom_minimum_size = Vector2(0, 44)
	ia_botao_salvar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ia_botao_salvar.text = "Salvar perguntas aprovadas"
	ia_botao_salvar.pressed.connect(_on_botao_salvar_aprovadas_pressed)
	button_row.add_child(ia_botao_salvar)

	ia_label_feedback = Label.new()
	ia_label_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ia_area.add_child(ia_label_feedback)

	ia_label_resumo = Label.new()
	ia_label_resumo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ia_area.add_child(ia_label_resumo)

	ia_lista = VBoxContainer.new()
	ia_lista.add_theme_constant_override("separation", 14)
	ia_lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ia_area.add_child(ia_lista)

	_show_ia_feedback("Preencha os dados e clique em \"Gerar com IA\" para iniciar a auditoria.", STATUS_INFO)
	_update_ia_controls_state()

func _create_line_edit(placeholder: String) -> LineEdit:
	var line_edit: LineEdit = LineEdit.new()
	line_edit.custom_minimum_size = Vector2(0, 44)
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.placeholder_text = placeholder
	return line_edit

func _create_spin_box(min_value: float, max_value: float, default_value: float) -> SpinBox:
	var spin_box: SpinBox = SpinBox.new()
	spin_box.custom_minimum_size = Vector2(0, 44)
	spin_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin_box.min_value = min_value
	spin_box.max_value = max_value
	spin_box.step = 1
	spin_box.value = default_value
	spin_box.allow_greater = false
	spin_box.allow_lesser = false
	spin_box.rounded = true
	return spin_box

func _add_labeled_control(parent: GridContainer, label_text: String, control: Control) -> void:
	var wrapper: VBoxContainer = VBoxContainer.new()
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.add_theme_constant_override("separation", 4)

	var label: Label = Label.new()
	label.text = label_text
	wrapper.add_child(label)
	wrapper.add_child(control)

	parent.add_child(wrapper)

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
	_update_ia_controls_state()
	_show_status("Importando perguntas para o banco de dados...", STATUS_INFO)

	var response: Dictionary = await ApiClient.import_questions_spreadsheet(path)

	importando_perguntas = false
	botao_importar.disabled = carregando
	botao_importar.text = "Importar Perguntas"
	_update_ia_controls_state()

	if not response.get("ok", false):
		_show_status(response.get("error", "Nao foi possivel importar a planilha."), STATUS_ERROR)
		return

	var payload: Dictionary = response.get("data", {})
	var imported_count: int = int(payload.get("total", 0))
	_show_status("%d perguntas importadas com sucesso." % imported_count, STATUS_OK)

func _on_botao_gerar_ia_pressed() -> void:
	if ia_processando or ia_salvando or carregando:
		return

	var tema: String = ia_tema_input.text.strip_edges()
	var materia: String = ia_materia_input.text.strip_edges()
	var dificuldade: String = ia_dificuldade_select.get_item_text(ia_dificuldade_select.selected).strip_edges()
	var quantidade: int = int(ia_quantidade_input.value)
	var pontuacao: int = int(ia_pontuacao_input.value)
	var tempo_limite: int = int(ia_tempo_input.value)

	if tema.is_empty():
		_show_ia_feedback("Informe um tema para gerar perguntas.", STATUS_ERROR)
		return
	if materia.is_empty():
		_show_ia_feedback("Informe uma materia para gerar perguntas.", STATUS_ERROR)
		return
	if dificuldade.is_empty():
		_show_ia_feedback("Selecione uma dificuldade para a geracao.", STATUS_ERROR)
		return
	if quantidade < 1 or quantidade > 20:
		_show_ia_feedback("A quantidade precisa ficar entre 1 e 20 perguntas.", STATUS_ERROR)
		return
	if pontuacao <= 0:
		_show_ia_feedback("A pontuacao precisa ser maior que zero.", STATUS_ERROR)
		return

	ia_processando = true
	_update_ia_controls_state()
	_show_ia_feedback("Gerando perguntas com IA. Aguarde alguns instantes...", STATUS_INFO)
	_show_status("Gerando perguntas com IA para auditoria...", STATUS_INFO)

	var response: Dictionary = await ApiClient.generate_questions_ai(
		tema,
		materia,
		dificuldade,
		quantidade,
		pontuacao,
		tempo_limite
	)

	ia_processando = false
	_update_ia_controls_state()

	if not response.get("ok", false):
		_show_ia_feedback(response.get("error", "Nao foi possivel gerar perguntas com IA."), STATUS_ERROR)
		_show_status(response.get("error", "Nao foi possivel gerar perguntas com IA."), STATUS_ERROR)
		return

	var payload: Dictionary = response.get("data", {})
	perguntas_geradas = _normalize_generated_questions(payload.get("perguntas", []))
	_render_generated_questions()
	_show_ia_feedback("%d perguntas foram geradas e estao prontas para auditoria." % perguntas_geradas.size(), STATUS_OK)
	_show_status("Perguntas geradas com IA. Revise, aprove ou rejeite cada item.", STATUS_OK)

func _normalize_generated_questions(raw_questions: Variant) -> Array[Dictionary]:
	var normalized: Array[Dictionary] = []
	if raw_questions is not Array:
		return normalized

	for item in raw_questions:
		if item is not Dictionary:
			continue

		var question: Dictionary = item
		var normalized_question: Dictionary = {
			"titulo": str(question.get("titulo", "")).strip_edges(),
			"enunciado": str(question.get("enunciado", "")).strip_edges(),
			"alternativaA": str(question.get("alternativaA", "")).strip_edges(),
			"alternativaB": str(question.get("alternativaB", "")).strip_edges(),
			"alternativaC": str(question.get("alternativaC", "")).strip_edges(),
			"alternativaD": str(question.get("alternativaD", "")).strip_edges(),
			"respostaCorreta": str(question.get("respostaCorreta", "A")).strip_edges().to_upper(),
			"materia": str(question.get("materia", "")).strip_edges(),
			"dificuldade": str(question.get("dificuldade", "Facil")).strip_edges(),
			"pontuacao": max(1, int(question.get("pontuacao", 100))),
			"tempoLimite": max(0, int(question.get("tempoLimite", 0))),
			"statusAuditoria": IA_STATUS_PENDING,
		}
		normalized.append(normalized_question)

	return normalized

func _render_generated_questions() -> void:
	if ia_lista == null:
		return

	for child in ia_lista.get_children():
		child.queue_free()

	cards_perguntas_ia.clear()

	if perguntas_geradas.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "Nenhuma pergunta gerada para auditoria ainda."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ia_lista.add_child(empty_label)
		_update_ia_summary()
		return

	for index in range(perguntas_geradas.size()):
		var question: Dictionary = perguntas_geradas[index]
		ia_lista.add_child(_create_generated_question_card(question, index))

	_update_ia_summary()

func _create_generated_question_card(question: Dictionary, index: int) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _create_question_card_style())
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	card.add_child(content)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	content.add_child(header)

	var title: Label = Label.new()
	title.text = "Pergunta %d" % (index + 1)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var status_label: Label = Label.new()
	header.add_child(status_label)

	cards_perguntas_ia.append({
		"status_label": status_label,
	})

	content.add_child(_create_card_line_edit("Titulo", str(question.get("titulo", "")), index, "titulo"))
	content.add_child(_create_card_text_edit("Enunciado", str(question.get("enunciado", "")), index, "enunciado"))
	content.add_child(_create_card_line_edit("Alternativa A", str(question.get("alternativaA", "")), index, "alternativaA"))
	content.add_child(_create_card_line_edit("Alternativa B", str(question.get("alternativaB", "")), index, "alternativaB"))
	content.add_child(_create_card_line_edit("Alternativa C", str(question.get("alternativaC", "")), index, "alternativaC"))
	content.add_child(_create_card_line_edit("Alternativa D", str(question.get("alternativaD", "")), index, "alternativaD"))

	var meta_grid: GridContainer = GridContainer.new()
	meta_grid.columns = 2
	meta_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_grid.add_theme_constant_override("h_separation", 12)
	meta_grid.add_theme_constant_override("v_separation", 10)
	content.add_child(meta_grid)

	meta_grid.add_child(_create_card_line_edit("Materia", str(question.get("materia", "")), index, "materia"))
	meta_grid.add_child(_create_card_line_edit("Dificuldade", str(question.get("dificuldade", "")), index, "dificuldade"))
	meta_grid.add_child(_create_card_option_field("Resposta correta", IA_CORRECT_OPTIONS, str(question.get("respostaCorreta", "A")), index, "respostaCorreta"))
	meta_grid.add_child(_create_card_spin_field("Pontuacao", int(question.get("pontuacao", 100)), 1, 10000, index, "pontuacao"))
	meta_grid.add_child(_create_card_spin_field("Tempo limite", int(question.get("tempoLimite", 0)), 0, 3600, index, "tempoLimite"))

	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	content.add_child(actions)

	var botao_pendente: Button = Button.new()
	botao_pendente.text = "Marcar pendente"
	botao_pendente.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botao_pendente.pressed.connect(_on_generated_question_status_changed.bind(index, IA_STATUS_PENDING))
	actions.add_child(botao_pendente)

	var botao_aprovar: Button = Button.new()
	botao_aprovar.text = "Aprovar"
	botao_aprovar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botao_aprovar.pressed.connect(_on_generated_question_status_changed.bind(index, IA_STATUS_APPROVED))
	actions.add_child(botao_aprovar)

	var botao_rejeitar: Button = Button.new()
	botao_rejeitar.text = "Rejeitar"
	botao_rejeitar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botao_rejeitar.pressed.connect(_on_generated_question_status_changed.bind(index, IA_STATUS_REJECTED))
	actions.add_child(botao_rejeitar)

	_update_generated_question_status_visual(index)
	return card

func _create_question_card_style() -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(1.0, 1.0, 1.0, 0.92)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.20, 0.20, 0.24, 0.45)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 14
	style.content_margin_top = 14
	style.content_margin_right = 14
	style.content_margin_bottom = 14
	return style

func _create_card_line_edit(label_text: String, value: String, index: int, field_name: String) -> VBoxContainer:
	var wrapper: VBoxContainer = VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label: Label = Label.new()
	label.text = label_text
	wrapper.add_child(label)

	var line_edit: LineEdit = LineEdit.new()
	line_edit.custom_minimum_size = Vector2(0, 42)
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.text = value
	line_edit.text_changed.connect(_on_generated_question_text_changed.bind(index, field_name))
	wrapper.add_child(line_edit)

	return wrapper

func _create_card_text_edit(label_text: String, value: String, index: int, field_name: String) -> VBoxContainer:
	var wrapper: VBoxContainer = VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label: Label = Label.new()
	label.text = label_text
	wrapper.add_child(label)

	var text_edit: TextEdit = TextEdit.new()
	text_edit.custom_minimum_size = Vector2(0, 100)
	text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_edit.text = value
	text_edit.text_changed.connect(_on_generated_question_text_edit_changed.bind(index, field_name, text_edit))
	wrapper.add_child(text_edit)

	return wrapper

func _create_card_option_field(label_text: String, options: Array[String], current_value: String, index: int, field_name: String) -> VBoxContainer:
	var wrapper: VBoxContainer = VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label: Label = Label.new()
	label.text = label_text
	wrapper.add_child(label)

	var option_button: OptionButton = OptionButton.new()
	option_button.custom_minimum_size = Vector2(0, 42)
	option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for option in options:
		option_button.add_item(option)
	_select_option_button_item(option_button, current_value)
	option_button.item_selected.connect(_on_generated_question_option_selected.bind(index, field_name, option_button))
	wrapper.add_child(option_button)

	return wrapper

func _create_card_spin_field(label_text: String, current_value: int, min_value: float, max_value: float, index: int, field_name: String) -> VBoxContainer:
	var wrapper: VBoxContainer = VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label: Label = Label.new()
	label.text = label_text
	wrapper.add_child(label)

	var spin_box: SpinBox = _create_spin_box(min_value, max_value, current_value)
	spin_box.value_changed.connect(_on_generated_question_number_changed.bind(index, field_name))
	wrapper.add_child(spin_box)

	return wrapper

func _select_option_button_item(option_button: OptionButton, current_value: String) -> void:
	for item_index in range(option_button.item_count):
		if option_button.get_item_text(item_index) == current_value:
			option_button.select(item_index)
			return

	if option_button.item_count > 0:
		option_button.select(0)

func _on_generated_question_text_changed(new_text: String, index: int, field_name: String) -> void:
	if not _has_generated_question(index):
		return

	perguntas_geradas[index][field_name] = new_text.strip_edges()

func _on_generated_question_text_edit_changed(index: int, field_name: String, text_edit: TextEdit) -> void:
	if not _has_generated_question(index):
		return

	perguntas_geradas[index][field_name] = text_edit.text.strip_edges()

func _on_generated_question_option_selected(selected_index: int, index: int, field_name: String, option_button: OptionButton) -> void:
	if not _has_generated_question(index):
		return

	perguntas_geradas[index][field_name] = option_button.get_item_text(selected_index)

func _on_generated_question_number_changed(value: float, index: int, field_name: String) -> void:
	if not _has_generated_question(index):
		return

	perguntas_geradas[index][field_name] = int(round(value))

func _on_generated_question_status_changed(index: int, new_status: String) -> void:
	if not _has_generated_question(index):
		return

	perguntas_geradas[index]["statusAuditoria"] = new_status
	_update_generated_question_status_visual(index)
	_update_ia_summary()

func _update_generated_question_status_visual(index: int) -> void:
	if index < 0 or index >= cards_perguntas_ia.size():
		return

	var card_info: Dictionary = cards_perguntas_ia[index]
	var status_label: Label = card_info.get("status_label", null) as Label
	if status_label == null:
		return

	var status: String = str(perguntas_geradas[index].get("statusAuditoria", IA_STATUS_PENDING))
	status_label.text = "Status: %s" % status.capitalize()
	status_label.modulate = _get_ia_status_color(status)

func _get_ia_status_color(status: String) -> Color:
	match status:
		IA_STATUS_APPROVED:
			return STATUS_OK
		IA_STATUS_REJECTED:
			return STATUS_ERROR
		_:
			return STATUS_INFO

func _update_ia_summary() -> void:
	if ia_label_resumo == null:
		return

	var pendentes := _count_generated_questions_with_status(IA_STATUS_PENDING)
	var aprovadas := _count_generated_questions_with_status(IA_STATUS_APPROVED)
	var rejeitadas := _count_generated_questions_with_status(IA_STATUS_REJECTED)
	ia_label_resumo.text = "Pendentes: %d | Aprovadas: %d | Rejeitadas: %d" % [
		pendentes,
		aprovadas,
		rejeitadas,
	]

	_update_ia_controls_state()

func _count_generated_questions_with_status(status: String) -> int:
	var total := 0
	for question in perguntas_geradas:
		if str(question.get("statusAuditoria", IA_STATUS_PENDING)) == status:
			total += 1
	return total

func _update_ia_controls_state() -> void:
	var controls_locked := carregando or importando_perguntas or ia_processando or ia_salvando

	if ia_tema_input != null:
		ia_tema_input.editable = not controls_locked
	if ia_materia_input != null:
		ia_materia_input.editable = not controls_locked
	if ia_dificuldade_select != null:
		ia_dificuldade_select.disabled = controls_locked
	if ia_quantidade_input != null:
		ia_quantidade_input.editable = not controls_locked
	if ia_pontuacao_input != null:
		ia_pontuacao_input.editable = not controls_locked
	if ia_tempo_input != null:
		ia_tempo_input.editable = not controls_locked
	if ia_botao_gerar != null:
		ia_botao_gerar.disabled = controls_locked
		ia_botao_gerar.text = "Gerando..." if ia_processando else "Gerar com IA"
	if ia_botao_salvar != null:
		ia_botao_salvar.disabled = controls_locked or _count_generated_questions_with_status(IA_STATUS_APPROVED) == 0
		ia_botao_salvar.text = "Salvando aprovadas..." if ia_salvando else "Salvar perguntas aprovadas"

	botao_sair.disabled = carregando or ia_processando or ia_salvando

func _show_ia_feedback(message: String, color_value: Color) -> void:
	if ia_label_feedback == null:
		return

	ia_label_feedback.text = message
	ia_label_feedback.modulate = color_value

func _on_botao_salvar_aprovadas_pressed() -> void:
	if ia_salvando or ia_processando:
		return

	var perguntas_aprovadas: Array[Dictionary] = _build_approved_questions_payload()
	if perguntas_aprovadas.is_empty():
		_show_ia_feedback("Nenhuma pergunta aprovada foi selecionada para salvar.", STATUS_ERROR)
		return

	ia_salvando = true
	_update_ia_controls_state()
	_show_ia_feedback("Salvando perguntas aprovadas no banco oficial...", STATUS_INFO)
	_show_status("Salvando perguntas aprovadas...", STATUS_INFO)

	var response: Dictionary = await ApiClient.save_generated_questions(perguntas_aprovadas)

	ia_salvando = false
	_update_ia_controls_state()

	if not response.get("ok", false):
		_show_ia_feedback(response.get("error", "Nao foi possivel salvar as perguntas aprovadas."), STATUS_ERROR)
		_show_status(response.get("error", "Nao foi possivel salvar as perguntas aprovadas."), STATUS_ERROR)
		return

	var payload: Dictionary = response.get("data", {})
	var saved_count: int = int(payload.get("total", perguntas_aprovadas.size()))
	perguntas_geradas.clear()
	_render_generated_questions()
	_show_ia_feedback("%d perguntas aprovadas foram salvas com sucesso." % saved_count, STATUS_OK)
	_show_status("%d perguntas aprovadas foram salvas no banco." % saved_count, STATUS_OK)

func _build_approved_questions_payload() -> Array[Dictionary]:
	var payload: Array[Dictionary] = []

	for index in range(perguntas_geradas.size()):
		var question: Dictionary = perguntas_geradas[index]
		if str(question.get("statusAuditoria", IA_STATUS_PENDING)) != IA_STATUS_APPROVED:
			continue

		var validation_error: String = _validate_generated_question(question, index)
		if not validation_error.is_empty():
			_show_ia_feedback(validation_error, STATUS_ERROR)
			return []

		var question_payload: Dictionary = question.duplicate(true)
		question_payload.erase("statusAuditoria")
		if str(question_payload.get("titulo", "")).strip_edges().is_empty():
			question_payload.erase("titulo")
		if int(question_payload.get("tempoLimite", 0)) <= 0:
			question_payload.erase("tempoLimite")

		payload.append(question_payload)

	return payload

func _validate_generated_question(question: Dictionary, index: int) -> String:
	var required_fields: Array[String] = [
		"enunciado",
		"alternativaA",
		"alternativaB",
		"alternativaC",
		"alternativaD",
		"materia",
		"dificuldade",
	]

	for field_name in required_fields:
		if str(question.get(field_name, "")).strip_edges().is_empty():
			return "A pergunta %d precisa preencher o campo %s antes de salvar." % [index + 1, field_name]

	var resposta_correta: String = str(question.get("respostaCorreta", "")).strip_edges().to_upper()
	if not IA_CORRECT_OPTIONS.has(resposta_correta):
		return "A pergunta %d precisa ter uma resposta correta entre A, B, C ou D." % (index + 1)

	var pontuacao: int = int(question.get("pontuacao", 0))
	if pontuacao <= 0:
		return "A pergunta %d precisa ter pontuacao maior que zero." % (index + 1)

	var tempo_limite: int = int(question.get("tempoLimite", 0))
	if tempo_limite < 0:
		return "A pergunta %d possui tempo limite invalido." % (index + 1)

	return ""

func _has_generated_question(index: int) -> bool:
	return index >= 0 and index < perguntas_geradas.size()

func _on_botao_sair_pressed() -> void:
	ProfessorSession.clear_session()
	get_tree().change_scene_to_file("res://scene/acesso_professor.tscn")

func _on_botao_configuracao_pressed() -> void:
	SettingsManager.open_menu()

func _show_status(message: String, color_value: Color) -> void:
	label_status.text = message
	label_status.modulate = color_value
