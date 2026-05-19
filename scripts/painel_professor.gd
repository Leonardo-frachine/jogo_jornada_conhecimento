extends Control

const STATUS_INFO := Color(0.13, 0.22, 0.44, 1.0)
const STATUS_OK := Color(0.18, 0.58, 0.26, 1.0)
const STATUS_ERROR := Color(0.70, 0.17, 0.17, 1.0)

const IA_COLOR_SURFACE := Color(1.0, 0.98, 0.95, 0.98)
const IA_COLOR_SURFACE_ALT := Color(0.98, 0.94, 0.88, 0.98)
const IA_COLOR_BORDER := Color(0.58, 0.42, 0.27, 0.42)
const IA_COLOR_TEXT := Color(0.23, 0.16, 0.12, 1.0)
const IA_COLOR_MUTED := Color(0.45, 0.33, 0.24, 1.0)
const IA_COLOR_ACCENT := Color(0.92, 0.51, 0.18, 1.0)
const IA_COLOR_ACCENT_DARK := Color(0.62, 0.31, 0.10, 1.0)
const IA_COLOR_PENDING := Color(0.74, 0.53, 0.16, 1.0)
const IA_COLOR_PENDING_SOFT := Color(0.99, 0.93, 0.79, 1.0)
const IA_COLOR_APPROVED := Color(0.21, 0.58, 0.35, 1.0)
const IA_COLOR_APPROVED_SOFT := Color(0.88, 0.96, 0.91, 1.0)
const IA_COLOR_REJECTED := Color(0.77, 0.27, 0.23, 1.0)
const IA_COLOR_REJECTED_SOFT := Color(0.98, 0.89, 0.88, 1.0)

const IA_STATUS_PENDING := "pendente"
const IA_STATUS_APPROVED := "aprovada"
const IA_STATUS_REJECTED := "rejeitada"
const IA_DIFFICULTIES: Array[String] = ["Facil", "Medio", "Dificil", "Especial"]
const IA_CORRECT_OPTIONS: Array[String] = ["A", "B", "C", "D"]
const VIEW_DASHBOARD := "dashboard"
const VIEW_STUDENTS := "students"
const VIEW_QUESTIONS := "questions"

@onready var label_professor: Label = $PainelCentral/MarginContainer/VBoxContainer/Header/LabelProfessor
@onready var label_sala_atual: Label = $PainelCentral/MarginContainer/VBoxContainer/Header/LabelSalaAtual
@onready var label_status: Label = $PainelCentral/MarginContainer/VBoxContainer/LabelStatus
@onready var input_nome_sala: LineEdit = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/BlocoSala/VBoxSala/InputNomeSala
@onready var botao_criar_sala: Button = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/BlocoSala/VBoxSala/AcoesSala/BotaoCriarSala
@onready var seletor_salas: OptionButton = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/BlocoSala/VBoxSala/AcoesSala/SeletorSalas
@onready var botao_atualizar: Button = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/BlocoSala/VBoxSala/AcoesSala/BotaoAtualizar
@onready var botao_aba_dashboard: Button = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/NavegacaoAbas/BotaoAbaDashboard
@onready var botao_aba_alunos: Button = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/NavegacaoAbas/BotaoAbaAlunos
@onready var botao_aba_perguntas: Button = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/NavegacaoAbas/BotaoAbaPerguntas
@onready var pagina_dashboard: PanelContainer = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaDashboard
@onready var pagina_alunos: PanelContainer = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaAlunos
@onready var pagina_perguntas: PanelContainer = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaPerguntas
@onready var resumo_dashboard_grid: GridContainer = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaDashboard/VBoxDashboard/GridResumoDashboard
@onready var lista_materias_dashboard: VBoxContainer = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaDashboard/VBoxDashboard/SecoesDashboard/PainelMaterias/VBoxMaterias/ListaMaterias
@onready var lista_dificuldades_dashboard: VBoxContainer = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaDashboard/VBoxDashboard/SecoesDashboard/PainelDificuldades/VBoxDificuldades/ListaDificuldades
@onready var resumo_alunos: Label = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaAlunos/VBoxAlunos/ResumoAlunos
@onready var lista_ranking: VBoxContainer = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaAlunos/VBoxAlunos/ListaRanking
@onready var botao_importar: Button = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaPerguntas/VBoxPerguntas/AcoesPerguntas/BotaoImportar
@onready var botao_atualizar_perguntas: Button = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaPerguntas/VBoxPerguntas/AcoesPerguntas/BotaoAtualizarPerguntas
@onready var resumo_banco_perguntas: Label = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaPerguntas/VBoxPerguntas/ResumoBancoPerguntas
@onready var lista_banco_perguntas: VBoxContainer = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaPerguntas/VBoxPerguntas/PainelBancoPerguntas/VBoxBancoPerguntas/ListaBancoPerguntas
@onready var ia_area: VBoxContainer = $PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaPerguntas/VBoxPerguntas/IaArea
@onready var botao_sair: Button = $PainelCentral/MarginContainer/VBoxContainer/Footer/BotaoSair
@onready var botao_configuracao: TextureButton = $BotaoConfiguracao

var salas: Array[Dictionary] = []
var carregando := false
var importando_perguntas := false
var ia_processando := false
var ia_salvando := false
var carregando_banco_perguntas := false
var import_dialog: FileDialog

var current_view := VIEW_DASHBOARD
var dashboard_payload: Dictionary = {}
var respostas_sala: Array[Dictionary] = []
var banco_perguntas: Array[Dictionary] = []
var perguntas_geradas: Array[Dictionary] = []
var cards_perguntas_ia: Array[Dictionary] = []
var cards_banco_perguntas: Array[Dictionary] = []

var ia_tema_input: LineEdit
var ia_materia_input: LineEdit
var ia_dificuldade_select: OptionButton
var ia_quantidade_input: SpinBox
var ia_pontuacao_input: SpinBox
var ia_tempo_input: SpinBox
var ia_botao_gerar: Button
var ia_botao_salvar: Button
var ia_botao_aprovar_todas: Button
var ia_botao_rejeitar_todas: Button
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
	botao_atualizar_perguntas.pressed.connect(_on_botao_atualizar_banco_perguntas_pressed)
	botao_sair.pressed.connect(_on_botao_sair_pressed)
	botao_configuracao.pressed.connect(_on_botao_configuracao_pressed)
	botao_aba_dashboard.pressed.connect(_on_navigation_pressed.bind(VIEW_DASHBOARD))
	botao_aba_alunos.pressed.connect(_on_navigation_pressed.bind(VIEW_STUDENTS))
	botao_aba_perguntas.pressed.connect(_on_navigation_pressed.bind(VIEW_QUESTIONS))
	seletor_salas.item_selected.connect(_on_seletor_salas_item_selected)
	_ensure_import_dialog()
	_setup_panel_layout()
	_build_ai_section()

	_refresh_header()
	_render_empty_dashboard()
	_render_student_ranking([])
	_render_question_bank()
	_render_generated_questions()
	_set_current_view(VIEW_DASHBOARD)
	call_deferred("_refresh_question_bank")
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

func _setup_panel_layout() -> void:
	_apply_root_panel_styles()
	_apply_navigation_styles()
	_apply_section_title_styles()
	_apply_section_panel_styles()

func _apply_root_panel_styles() -> void:
	_apply_input_palette(input_nome_sala)
	_apply_button_palette(botao_criar_sala, IA_COLOR_ACCENT, IA_COLOR_ACCENT_DARK)
	_apply_button_palette(botao_atualizar, STATUS_INFO, _shade_color(STATUS_INFO, 0.28))
	_apply_button_palette(botao_importar, IA_COLOR_ACCENT, IA_COLOR_ACCENT_DARK)
	_apply_button_palette(botao_atualizar_perguntas, STATUS_INFO, _shade_color(STATUS_INFO, 0.28))
	_apply_button_palette(botao_sair, IA_COLOR_REJECTED, _shade_color(IA_COLOR_REJECTED, 0.28))
	_apply_option_button_palette(seletor_salas)

func _apply_navigation_styles() -> void:
	_apply_navigation_button_style(botao_aba_dashboard, true)
	_apply_navigation_button_style(botao_aba_alunos, false)
	_apply_navigation_button_style(botao_aba_perguntas, false)

func _apply_section_title_styles() -> void:
	var title_paths: Array[String] = [
		"PainelCentral/MarginContainer/VBoxContainer/TituloPainel",
		"PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/BlocoSala/VBoxSala/TituloSala",
		"PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaDashboard/VBoxDashboard/TituloDashboard",
		"PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaDashboard/VBoxDashboard/SecoesDashboard/PainelMaterias/VBoxMaterias/TituloMaterias",
		"PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaDashboard/VBoxDashboard/SecoesDashboard/PainelDificuldades/VBoxDificuldades/TituloDificuldades",
		"PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaAlunos/VBoxAlunos/TituloAlunos",
		"PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaPerguntas/VBoxPerguntas/TituloPerguntas",
		"PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaPerguntas/VBoxPerguntas/PainelBancoPerguntas/VBoxBancoPerguntas/TituloBancoPerguntas",
	]
	for path in title_paths:
		var label: Label = get_node_or_null(path) as Label
		if label != null:
			label.add_theme_color_override("font_color", IA_COLOR_ACCENT_DARK)

	var text_paths: Array[String] = [
		"PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaDashboard/VBoxDashboard/DescricaoDashboard",
		"PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaAlunos/VBoxAlunos/DescricaoAlunos",
		"PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaPerguntas/VBoxPerguntas/DescricaoPerguntas",
		"PainelCentral/MarginContainer/VBoxContainer/Header/LabelProfessor",
		"PainelCentral/MarginContainer/VBoxContainer/Header/LabelSalaAtual",
	]
	for path in text_paths:
		var text_label: Label = get_node_or_null(path) as Label
		if text_label != null:
			text_label.add_theme_color_override("font_color", IA_COLOR_TEXT)

func _apply_section_panel_styles() -> void:
	var panel_paths: Array[String] = [
		"PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/BlocoSala",
		"PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaDashboard",
		"PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaDashboard/VBoxDashboard/SecoesDashboard/PainelMaterias",
		"PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaDashboard/VBoxDashboard/SecoesDashboard/PainelDificuldades",
		"PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaAlunos",
		"PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaPerguntas",
		"PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaPerguntas/VBoxPerguntas/PainelBancoPerguntas",
	]
	for path in panel_paths:
		var panel: PanelContainer = get_node_or_null(path) as PanelContainer
		if panel != null:
			panel.add_theme_stylebox_override("panel", _create_ia_surface_style(IA_COLOR_SURFACE, IA_COLOR_BORDER, 2, 18, 18, 16))

	var ranking_header: HBoxContainer = get_node_or_null("PainelCentral/MarginContainer/VBoxContainer/ScrollContainer/Conteudo/PaginaAlunos/VBoxAlunos/CabecalhoRanking") as HBoxContainer
	if ranking_header != null:
		ranking_header.add_theme_stylebox_override("panel", _create_ia_surface_style(IA_COLOR_SURFACE_ALT, IA_COLOR_BORDER, 2, 12, 12, 10))
		for child in ranking_header.get_children():
			if child is Label:
				(child as Label).add_theme_color_override("font_color", IA_COLOR_MUTED)

func _set_loading_state(enabled: bool) -> void:
	carregando = enabled
	input_nome_sala.editable = not enabled
	botao_criar_sala.disabled = enabled
	botao_atualizar.disabled = enabled
	seletor_salas.disabled = enabled or salas.is_empty()
	_update_ia_controls_state()
	_update_question_bank_controls_state()

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
	title.add_theme_color_override("font_color", IA_COLOR_ACCENT_DARK)
	ia_area.add_child(title)

	var description_panel: PanelContainer = PanelContainer.new()
	description_panel.add_theme_stylebox_override("panel", _create_ia_surface_style(IA_COLOR_SURFACE_ALT, IA_COLOR_ACCENT))
	ia_area.add_child(description_panel)

	var description: Label = Label.new()
	description.text = "Use o Gemini para sugerir perguntas, revise cada item e salve apenas o que for aprovado."
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", IA_COLOR_TEXT)
	description_panel.add_child(description)

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
	_apply_button_palette(ia_dificuldade_select, Color(1.0, 1.0, 1.0, 0.98), IA_COLOR_BORDER, IA_COLOR_TEXT)
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
	ia_botao_gerar.text = "GERAR COM IA"
	_apply_button_palette(ia_botao_gerar, IA_COLOR_ACCENT, IA_COLOR_ACCENT_DARK)
	ia_botao_gerar.pressed.connect(_on_botao_gerar_ia_pressed)
	button_row.add_child(ia_botao_gerar)

	ia_botao_salvar = Button.new()
	ia_botao_salvar.custom_minimum_size = Vector2(0, 44)
	ia_botao_salvar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ia_botao_salvar.text = "SALVAR PERGUNTAS APROVADAS"
	_apply_button_palette(ia_botao_salvar, IA_COLOR_APPROVED, _shade_color(IA_COLOR_APPROVED, 0.28))
	ia_botao_salvar.pressed.connect(_on_botao_salvar_aprovadas_pressed)
	button_row.add_child(ia_botao_salvar)

	ia_label_feedback = Label.new()
	ia_label_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ia_label_feedback.add_theme_color_override("font_color", IA_COLOR_TEXT)
	ia_area.add_child(ia_label_feedback)

	var summary_panel: PanelContainer = PanelContainer.new()
	summary_panel.add_theme_stylebox_override("panel", _create_ia_surface_style(IA_COLOR_SURFACE, IA_COLOR_BORDER))
	ia_area.add_child(summary_panel)

	ia_label_resumo = Label.new()
	ia_label_resumo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ia_label_resumo.add_theme_color_override("font_color", IA_COLOR_TEXT)
	summary_panel.add_child(ia_label_resumo)

	var bulk_actions: HBoxContainer = HBoxContainer.new()
	bulk_actions.add_theme_constant_override("separation", 10)
	ia_area.add_child(bulk_actions)

	ia_botao_aprovar_todas = Button.new()
	ia_botao_aprovar_todas.custom_minimum_size = Vector2(0, 42)
	ia_botao_aprovar_todas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ia_botao_aprovar_todas.text = "APROVAR TODAS"
	_apply_button_palette(ia_botao_aprovar_todas, IA_COLOR_APPROVED, _shade_color(IA_COLOR_APPROVED, 0.28))
	ia_botao_aprovar_todas.pressed.connect(_on_botao_aprovar_todas_pressed)
	bulk_actions.add_child(ia_botao_aprovar_todas)

	ia_botao_rejeitar_todas = Button.new()
	ia_botao_rejeitar_todas.custom_minimum_size = Vector2(0, 42)
	ia_botao_rejeitar_todas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ia_botao_rejeitar_todas.text = "REJEITAR TODAS"
	_apply_button_palette(ia_botao_rejeitar_todas, IA_COLOR_REJECTED, _shade_color(IA_COLOR_REJECTED, 0.28))
	ia_botao_rejeitar_todas.pressed.connect(_on_botao_rejeitar_todas_pressed)
	bulk_actions.add_child(ia_botao_rejeitar_todas)

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
	_apply_line_edit_palette(line_edit)
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
	label.add_theme_color_override("font_color", IA_COLOR_TEXT)
	wrapper.add_child(label)
	wrapper.add_child(control)

	parent.add_child(wrapper)

func _create_ia_surface_style(background: Color, border: Color, border_width: int = 2, corner_radius: int = 16, horizontal_padding: int = 14, vertical_padding: int = 12) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = border
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.content_margin_left = horizontal_padding
	style.content_margin_top = vertical_padding
	style.content_margin_right = horizontal_padding
	style.content_margin_bottom = vertical_padding
	return style

func _tint_color(color_value: Color, amount: float) -> Color:
	return color_value.lerp(Color(1.0, 1.0, 1.0, color_value.a), clampf(amount, 0.0, 1.0))

func _shade_color(color_value: Color, amount: float) -> Color:
	return color_value.lerp(Color(0.0, 0.0, 0.0, color_value.a), clampf(amount, 0.0, 1.0))

func _apply_button_palette(button: Button, background: Color, border: Color, font_color: Color = Color(1.0, 1.0, 1.0, 1.0)) -> void:
	button.add_theme_stylebox_override("normal", _create_ia_surface_style(background, border, 2, 12, 14, 10))
	button.add_theme_stylebox_override("hover", _create_ia_surface_style(_tint_color(background, 0.08), border, 2, 12, 14, 10))
	button.add_theme_stylebox_override("pressed", _create_ia_surface_style(_shade_color(background, 0.10), border, 2, 12, 14, 10))
	button.add_theme_stylebox_override("focus", _create_ia_surface_style(_tint_color(background, 0.04), border, 3, 12, 14, 10))
	button.add_theme_stylebox_override("disabled", _create_ia_surface_style(_tint_color(background, 0.28), _tint_color(border, 0.25), 2, 12, 14, 10))
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_focus_color", font_color)
	button.add_theme_color_override("font_disabled_color", font_color.lerp(Color(1.0, 1.0, 1.0, 1.0), 0.45))

func _apply_navigation_button_style(button: Button, is_active: bool) -> void:
	if is_active:
		_apply_button_palette(button, IA_COLOR_ACCENT, IA_COLOR_ACCENT_DARK)
	else:
		_apply_button_palette(button, IA_COLOR_SURFACE_ALT, IA_COLOR_BORDER, IA_COLOR_TEXT)

func _apply_option_button_palette(option_button: OptionButton) -> void:
	_apply_button_palette(option_button, Color(1.0, 1.0, 1.0, 0.98), IA_COLOR_BORDER, IA_COLOR_TEXT)

func _apply_input_palette(line_edit: LineEdit) -> void:
	_apply_line_edit_palette(line_edit)

func _clear_container(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()

func _apply_line_edit_palette(line_edit: LineEdit) -> void:
	line_edit.add_theme_stylebox_override("normal", _create_ia_surface_style(Color(1.0, 1.0, 1.0, 0.98), IA_COLOR_BORDER, 2, 10, 12, 10))
	line_edit.add_theme_stylebox_override("focus", _create_ia_surface_style(Color(1.0, 1.0, 1.0, 1.0), IA_COLOR_ACCENT, 2, 10, 12, 10))
	line_edit.add_theme_stylebox_override("read_only", _create_ia_surface_style(IA_COLOR_SURFACE_ALT, IA_COLOR_BORDER, 2, 10, 12, 10))
	line_edit.add_theme_color_override("font_color", IA_COLOR_TEXT)
	line_edit.add_theme_color_override("font_placeholder_color", IA_COLOR_MUTED)

func _apply_text_edit_palette(text_edit: TextEdit) -> void:
	text_edit.add_theme_stylebox_override("normal", _create_ia_surface_style(Color(1.0, 1.0, 1.0, 0.98), IA_COLOR_BORDER, 2, 10, 12, 10))
	text_edit.add_theme_stylebox_override("focus", _create_ia_surface_style(Color(1.0, 1.0, 1.0, 1.0), IA_COLOR_ACCENT, 2, 10, 12, 10))
	text_edit.add_theme_stylebox_override("read_only", _create_ia_surface_style(IA_COLOR_SURFACE_ALT, IA_COLOR_BORDER, 2, 10, 12, 10))
	text_edit.add_theme_color_override("font_color", IA_COLOR_TEXT)
	text_edit.add_theme_color_override("font_placeholder_color", IA_COLOR_MUTED)

func _on_navigation_pressed(view_name: String) -> void:
	_set_current_view(view_name)

func _set_current_view(view_name: String) -> void:
	current_view = view_name
	pagina_dashboard.visible = view_name == VIEW_DASHBOARD
	pagina_alunos.visible = view_name == VIEW_STUDENTS
	pagina_perguntas.visible = view_name == VIEW_QUESTIONS

	_apply_navigation_button_style(botao_aba_dashboard, view_name == VIEW_DASHBOARD)
	_apply_navigation_button_style(botao_aba_alunos, view_name == VIEW_STUDENTS)
	_apply_navigation_button_style(botao_aba_perguntas, view_name == VIEW_QUESTIONS)

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
		_render_student_ranking([])
		return

	_set_loading_state(true)
	_show_status("Atualizando dashboard da sala...", STATUS_INFO)

	var dashboard_response: Dictionary = await ApiClient.fetch_room_dashboard(ProfessorSession.current_room_id)
	var answers_response: Dictionary = await ApiClient.fetch_room_answers(ProfessorSession.current_room_id)
	_set_loading_state(false)

	if not dashboard_response.get("ok", false):
		_show_status(dashboard_response.get("error", "Nao foi possivel carregar o dashboard."), STATUS_ERROR)
		_render_empty_dashboard()
		_render_student_ranking([])
		return

	if not answers_response.get("ok", false):
		_show_status(answers_response.get("error", "Nao foi possivel carregar as respostas da sala."), STATUS_ERROR)
		respostas_sala.clear()
		_render_student_ranking([])
	else:
		var answers_data: Dictionary = answers_response.get("data", {})
		respostas_sala = _normalize_answer_list(answers_data.get("respostas", []))
		_render_student_ranking(respostas_sala)

	dashboard_payload = dashboard_response.get("data", {})
	_render_dashboard_data(dashboard_payload)
	_show_status("Dashboard atualizado.", STATUS_OK)

func _render_dashboard_data(payload: Dictionary) -> void:
	var indicadores: Dictionary = payload.get("indicadores", {})
	_clear_container(resumo_dashboard_grid)
	resumo_dashboard_grid.add_child(_create_metric_card("Alunos", str(int(indicadores.get("totalAlunos", 0))), "participando da sala", IA_COLOR_ACCENT))
	resumo_dashboard_grid.add_child(_create_metric_card("Atividades", str(int(indicadores.get("totalPerguntasRespondidas", 0))), "respostas registradas", STATUS_INFO))
	resumo_dashboard_grid.add_child(_create_metric_card("Desempenho Medio", "%d%%" % int(indicadores.get("percentualAcertoTurma", 0)), "aproveitamento da turma", IA_COLOR_APPROVED))
	resumo_dashboard_grid.add_child(_create_metric_card("Evolucao Geral", _build_overview_label(indicadores), _build_overview_caption(indicadores), IA_COLOR_PENDING))

	_render_group_summary_list(
		lista_materias_dashboard,
		payload.get("desempenhoPorMateria", []),
		"materia",
		"Nenhum dado de materia vinculado ainda."
	)
	_render_group_summary_list(
		lista_dificuldades_dashboard,
		payload.get("desempenhoPorDificuldade", []),
		"dificuldade",
		"Nenhum dado de dificuldade vinculado ainda."
	)

func _create_metric_card(title_text: String, value_text: String, subtitle_text: String, accent_color: Color) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _create_ia_surface_style(_tint_color(accent_color, 0.86), accent_color, 2, 16, 16, 14))

	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	panel.add_child(content)

	var title: Label = Label.new()
	title.text = title_text
	title.add_theme_color_override("font_color", IA_COLOR_MUTED)
	content.add_child(title)

	var value: Label = Label.new()
	value.text = value_text
	value.add_theme_color_override("font_color", accent_color)
	content.add_child(value)

	var subtitle: Label = Label.new()
	subtitle.text = subtitle_text
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", IA_COLOR_TEXT)
	content.add_child(subtitle)

	return panel

func _build_overview_label(indicadores: Dictionary) -> String:
	var acertos: int = int(indicadores.get("quantidadeAcertos", 0))
	var erros: int = int(indicadores.get("quantidadeErros", 0))
	return "Positiva" if acertos >= erros else "Instavel"

func _build_overview_caption(indicadores: Dictionary) -> String:
	return "%d acertos x %d erros" % [
		int(indicadores.get("quantidadeAcertos", 0)),
		int(indicadores.get("quantidadeErros", 0)),
	]

func _render_group_summary_list(container: VBoxContainer, groups: Variant, key_name: String, empty_message: String) -> void:
	_clear_container(container)

	if groups is not Array or groups.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = empty_message
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_color_override("font_color", IA_COLOR_MUTED)
		container.add_child(empty_label)
		return

	for item in groups:
		if item is not Dictionary:
			continue
		container.add_child(_create_group_summary_row(item, key_name))

func _create_group_summary_row(item: Dictionary, key_name: String) -> PanelContainer:
	var row: PanelContainer = PanelContainer.new()
	row.add_theme_stylebox_override("panel", _create_ia_surface_style(Color(1.0, 1.0, 1.0, 0.98), IA_COLOR_BORDER, 1, 12, 12, 10))

	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	row.add_child(content)

	var title: Label = Label.new()
	title.text = str(item.get(key_name, "Sem nome"))
	title.add_theme_color_override("font_color", IA_COLOR_TEXT)
	content.add_child(title)

	var detail: Label = Label.new()
	detail.text = "%d resp. | %d acertos | %d erros | %d%%" % [
		int(item.get("respondidas", 0)),
		int(item.get("acertos", 0)),
		int(item.get("erros", 0)),
		int(item.get("percentualAcerto", 0)),
	]
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_theme_color_override("font_color", IA_COLOR_MUTED)
	content.add_child(detail)

	return row

func _normalize_answer_list(respostas: Variant) -> Array[Dictionary]:
	var normalized: Array[Dictionary] = []
	if respostas is not Array:
		return normalized

	for item in respostas:
		if item is Dictionary:
			normalized.append(item)
	return normalized

func _render_student_ranking(respostas: Array[Dictionary]) -> void:
	_clear_container(lista_ranking)

	if respostas.is_empty():
		resumo_alunos.text = "Nenhuma resposta vinculada a esta sala ainda."
		resumo_alunos.add_theme_color_override("font_color", IA_COLOR_MUTED)
		return

	var ranking_data: Array[Dictionary] = _build_student_ranking_data(respostas)
	resumo_alunos.text = "Visao rapida da turma: %d alunos ranqueados com base em pontuacao, acertos e constancia recente." % ranking_data.size()
	resumo_alunos.add_theme_color_override("font_color", IA_COLOR_TEXT)

	for index in range(ranking_data.size()):
		lista_ranking.add_child(_create_student_ranking_row(ranking_data[index], index))

func _build_student_ranking_data(respostas: Array[Dictionary]) -> Array[Dictionary]:
	var grouped := {}

	for item in respostas:
		var jogador_id: int = int(item.get("jogadorId", 0))
		if not grouped.has(jogador_id):
			grouped[jogador_id] = {
				"jogadorId": jogador_id,
				"nome": str(item.get("aluno", "Aluno")),
				"pontuacao": 0,
				"acertos": 0,
				"erros": 0,
				"respostas": 0,
				"historico": [],
			}

		var row: Dictionary = grouped[jogador_id]
		var acertou: bool = bool(item.get("acertou", false))
		row["pontuacao"] = int(row.get("pontuacao", 0)) + int(item.get("pontuacaoGanha", 0))
		row["acertos"] = int(row.get("acertos", 0)) + (1 if acertou else 0)
		row["erros"] = int(row.get("erros", 0)) + (0 if acertou else 1)
		row["respostas"] = int(row.get("respostas", 0)) + 1
		var historico: Array = row.get("historico", [])
		historico.append(acertou)
		row["historico"] = historico
		grouped[jogador_id] = row

	var ranking: Array[Dictionary] = []
	for item in grouped.values():
		var respostas_total: int = int(item.get("respostas", 0))
		var acertos_total: int = int(item.get("acertos", 0))
		var aproveitamento: int = 0 if respostas_total == 0 else int(round((float(acertos_total) / float(respostas_total)) * 100.0))
		item["aproveitamento"] = aproveitamento
		item["status"] = _get_student_status(aproveitamento)
		item["trend"] = _build_student_trend(item.get("historico", []))
		ranking.append(item)

	ranking.sort_custom(func(a, b):
		if int(a.get("pontuacao", 0)) == int(b.get("pontuacao", 0)):
			if int(a.get("aproveitamento", 0)) == int(b.get("aproveitamento", 0)):
				return str(a.get("nome", "")) < str(b.get("nome", ""))
			return int(a.get("aproveitamento", 0)) > int(b.get("aproveitamento", 0))
		return int(a.get("pontuacao", 0)) > int(b.get("pontuacao", 0))
	)

	return ranking

func _get_student_status(aproveitamento: int) -> String:
	if aproveitamento >= 85:
		return "Excelente"
	if aproveitamento >= 70:
		return "Bom"
	if aproveitamento >= 50:
		return "Atencao"
	return "Precisa melhorar"

func _build_student_trend(historico_variant: Variant) -> Dictionary:
	var historico: Array = historico_variant if historico_variant is Array else []
	if historico.size() < 2:
		return {
			"label": "Novo",
			"color": IA_COLOR_PENDING,
		}

	var recent_slice: Array = historico.slice(0, min(3, historico.size()))
	var previous_start: int = recent_slice.size()
	var previous_slice: Array = historico.slice(previous_start, min(previous_start + 3, historico.size()))

	var recent_rate: float = _calculate_boolean_rate(recent_slice)
	var previous_rate: float = _calculate_boolean_rate(previous_slice)

	if previous_slice.is_empty():
		return {
			"label": "Subindo" if recent_rate >= 0.67 else "Estavel",
			"color": IA_COLOR_APPROVED if recent_rate >= 0.67 else IA_COLOR_PENDING,
		}

	if recent_rate > previous_rate + 0.15:
		return {
			"label": "Subindo",
			"color": IA_COLOR_APPROVED,
		}
	if recent_rate + 0.15 < previous_rate:
		return {
			"label": "Caindo",
			"color": IA_COLOR_REJECTED,
		}
	return {
		"label": "Estavel",
		"color": STATUS_INFO,
	}

func _calculate_boolean_rate(values: Array) -> float:
	if values.is_empty():
		return 0.0

	var positives := 0
	for item in values:
		if bool(item):
			positives += 1
	return float(positives) / float(values.size())

func _create_student_ranking_row(data: Dictionary, index: int) -> PanelContainer:
	var accent_color: Color = IA_COLOR_ACCENT
	if index == 0:
		accent_color = IA_COLOR_ACCENT
	elif index == 1:
		accent_color = IA_COLOR_PENDING
	elif index == 2:
		accent_color = STATUS_INFO
	else:
		accent_color = IA_COLOR_BORDER

	var panel: PanelContainer = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _create_ia_surface_style(_tint_color(accent_color, 0.88), accent_color, 2, 14, 12, 10))

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	row.add_child(_create_rank_text_cell("#%d" % (index + 1), 62, accent_color, false))
	row.add_child(_create_rank_text_cell(str(data.get("nome", "Aluno")), 0, IA_COLOR_TEXT, true))
	row.add_child(_create_rank_text_cell(str(int(data.get("pontuacao", 0))), 90, IA_COLOR_ACCENT_DARK, false))
	row.add_child(_create_rank_text_cell(str(int(data.get("acertos", 0))), 70, IA_COLOR_APPROVED, false))
	row.add_child(_create_rank_text_cell(str(int(data.get("erros", 0))), 60, IA_COLOR_REJECTED, false))
	row.add_child(_create_rank_text_cell("%d%%" % int(data.get("aproveitamento", 0)), 92, IA_COLOR_TEXT, false))
	row.add_child(_create_rank_badge_cell(str(data.get("status", "")), 116, _get_status_badge_color(str(data.get("status", "")))))

	var trend: Dictionary = data.get("trend", {})
	row.add_child(_create_rank_badge_cell(str(trend.get("label", "Estavel")), 96, trend.get("color", STATUS_INFO)))
	return panel

func _create_rank_text_cell(text_value: String, min_width: int, color_value: Color, expand: bool) -> Label:
	var label: Label = Label.new()
	label.text = text_value
	label.custom_minimum_size = Vector2(min_width, 0)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL if expand else Control.SIZE_SHRINK_BEGIN
	label.add_theme_color_override("font_color", color_value)
	return label

func _create_rank_badge_cell(text_value: String, min_width: int, color_value: Color) -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(min_width, 0)
	panel.add_theme_stylebox_override("panel", _create_ia_surface_style(_tint_color(color_value, 0.82), color_value, 2, 999, 10, 6))

	var label: Label = Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", _shade_color(color_value, 0.38))
	panel.add_child(label)
	return panel

func _get_status_badge_color(status: String) -> Color:
	match status:
		"Excelente":
			return IA_COLOR_APPROVED
		"Bom":
			return STATUS_INFO
		"Atencao":
			return IA_COLOR_PENDING
		_:
			return IA_COLOR_REJECTED

func _render_empty_dashboard() -> void:
	dashboard_payload.clear()
	_clear_container(resumo_dashboard_grid)
	resumo_dashboard_grid.add_child(_create_metric_card("Alunos", "0", "participando da sala", IA_COLOR_ACCENT))
	resumo_dashboard_grid.add_child(_create_metric_card("Atividades", "0", "respostas registradas", STATUS_INFO))
	resumo_dashboard_grid.add_child(_create_metric_card("Desempenho Medio", "0%", "aproveitamento da turma", IA_COLOR_APPROVED))
	resumo_dashboard_grid.add_child(_create_metric_card("Evolucao Geral", "Sem dados", "aguardando respostas", IA_COLOR_PENDING))
	_render_group_summary_list(lista_materias_dashboard, [], "materia", "Nenhum dado de materia vinculado ainda.")
	_render_group_summary_list(lista_dificuldades_dashboard, [], "dificuldade", "Nenhum dado de dificuldade vinculado ainda.")

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
	botao_importar.text = "IMPORTANDO..."
	_update_ia_controls_state()
	_show_status("Importando perguntas para o banco de dados...", STATUS_INFO)

	var response: Dictionary = await ApiClient.import_questions_spreadsheet(path)

	importando_perguntas = false
	botao_importar.disabled = carregando
	botao_importar.text = "IMPORTAR PERGUNTAS"
	_update_ia_controls_state()

	if not response.get("ok", false):
		_show_status(response.get("error", "Nao foi possivel importar a planilha."), STATUS_ERROR)
		return

	var payload: Dictionary = response.get("data", {})
	var imported_count: int = int(payload.get("total", 0))
	_show_status("%d perguntas importadas com sucesso." % imported_count, STATUS_OK)
	await _refresh_question_bank()

func _on_botao_atualizar_banco_perguntas_pressed() -> void:
	_refresh_question_bank()

func _refresh_question_bank() -> void:
	if carregando_banco_perguntas:
		return

	carregando_banco_perguntas = true
	_update_question_bank_controls_state()
	resumo_banco_perguntas.text = "Atualizando o banco oficial de perguntas..."
	resumo_banco_perguntas.add_theme_color_override("font_color", STATUS_INFO)

	var response: Dictionary = await ApiClient.fetch_questions()

	carregando_banco_perguntas = false
	_update_question_bank_controls_state()

	if not response.get("ok", false):
		resumo_banco_perguntas.text = response.get("error", "Nao foi possivel carregar o banco de perguntas.")
		resumo_banco_perguntas.add_theme_color_override("font_color", STATUS_ERROR)
		banco_perguntas.clear()
		_render_question_bank()
		return

	banco_perguntas = _normalize_question_bank(response.get("data", []))
	_render_question_bank()

func _normalize_question_bank(raw_questions: Variant) -> Array[Dictionary]:
	var normalized: Array[Dictionary] = []
	if raw_questions is not Array:
		return normalized

	for item in raw_questions:
		if item is not Dictionary:
			continue

		var question: Dictionary = item
		normalized.append({
			"id": int(question.get("id", 0)),
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
		})

	return normalized

func _render_question_bank() -> void:
	if lista_banco_perguntas == null:
		return

	_clear_container(lista_banco_perguntas)
	cards_banco_perguntas.clear()

	if banco_perguntas.is_empty():
		resumo_banco_perguntas.text = "Nenhuma pergunta salva no banco ainda."
		resumo_banco_perguntas.add_theme_color_override("font_color", IA_COLOR_MUTED)

		var empty_label: Label = Label.new()
		empty_label.text = "O banco oficial ainda esta vazio. Importe uma planilha ou salve perguntas geradas pela IA."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_color_override("font_color", IA_COLOR_MUTED)
		lista_banco_perguntas.add_child(empty_label)
		return

	resumo_banco_perguntas.text = "%d perguntas cadastradas no banco oficial." % banco_perguntas.size()
	resumo_banco_perguntas.add_theme_color_override("font_color", IA_COLOR_TEXT)

	for index in range(banco_perguntas.size()):
		lista_banco_perguntas.add_child(_create_question_bank_card(banco_perguntas[index], index))

func _create_question_bank_card(question: Dictionary, index: int) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _create_ia_surface_style(Color(1.0, 1.0, 1.0, 0.98), IA_COLOR_BORDER, 2, 14, 14, 14))

	var content: VBoxContainer = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	card.add_child(content)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	content.add_child(header)

	var title: Label = Label.new()
	title.text = "Pergunta #%d" % int(question.get("id", 0))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", IA_COLOR_ACCENT_DARK)
	header.add_child(title)

	var status: PanelContainer = PanelContainer.new()
	status.add_theme_stylebox_override("panel", _create_ia_surface_style(IA_COLOR_SURFACE_ALT, IA_COLOR_PENDING, 2, 999, 10, 6))
	header.add_child(status)

	var status_label: Label = Label.new()
	status_label.text = "Banco oficial"
	status_label.add_theme_color_override("font_color", IA_COLOR_TEXT)
	status.add_child(status_label)

	content.add_child(_create_bank_question_line_edit("Titulo", str(question.get("titulo", "")), index, "titulo"))
	content.add_child(_create_bank_question_text_edit("Enunciado", str(question.get("enunciado", "")), index, "enunciado"))
	content.add_child(_create_bank_question_line_edit("Alternativa A", str(question.get("alternativaA", "")), index, "alternativaA"))
	content.add_child(_create_bank_question_line_edit("Alternativa B", str(question.get("alternativaB", "")), index, "alternativaB"))
	content.add_child(_create_bank_question_line_edit("Alternativa C", str(question.get("alternativaC", "")), index, "alternativaC"))
	content.add_child(_create_bank_question_line_edit("Alternativa D", str(question.get("alternativaD", "")), index, "alternativaD"))

	var meta_grid: GridContainer = GridContainer.new()
	meta_grid.columns = 2
	meta_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	meta_grid.add_theme_constant_override("h_separation", 12)
	meta_grid.add_theme_constant_override("v_separation", 10)
	content.add_child(meta_grid)

	meta_grid.add_child(_create_bank_question_line_edit("Materia", str(question.get("materia", "")), index, "materia"))
	meta_grid.add_child(_create_bank_question_line_edit("Dificuldade", str(question.get("dificuldade", "")), index, "dificuldade"))
	meta_grid.add_child(_create_bank_question_option_field("Resposta correta", IA_CORRECT_OPTIONS, str(question.get("respostaCorreta", "A")), index, "respostaCorreta"))
	meta_grid.add_child(_create_bank_question_spin_field("Pontuacao", int(question.get("pontuacao", 100)), 1, 10000, index, "pontuacao"))
	meta_grid.add_child(_create_bank_question_spin_field("Tempo limite", int(question.get("tempoLimite", 0)), 0, 3600, index, "tempoLimite"))

	var actions: HBoxContainer = HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	content.add_child(actions)

	var botao_salvar_item: Button = Button.new()
	botao_salvar_item.text = "SALVAR ALTERACOES"
	botao_salvar_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_palette(botao_salvar_item, IA_COLOR_APPROVED, _shade_color(IA_COLOR_APPROVED, 0.28))
	botao_salvar_item.pressed.connect(_on_bank_question_save_pressed.bind(index))
	actions.add_child(botao_salvar_item)

	var botao_excluir_item: Button = Button.new()
	botao_excluir_item.text = "EXCLUIR"
	botao_excluir_item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_palette(botao_excluir_item, IA_COLOR_REJECTED, _shade_color(IA_COLOR_REJECTED, 0.28))
	botao_excluir_item.pressed.connect(_on_bank_question_delete_pressed.bind(index))
	actions.add_child(botao_excluir_item)

	return card

func _create_bank_question_line_edit(label_text: String, value: String, index: int, field_name: String) -> VBoxContainer:
	var wrapper: VBoxContainer = VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label: Label = Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", IA_COLOR_TEXT)
	wrapper.add_child(label)

	var line_edit: LineEdit = LineEdit.new()
	line_edit.custom_minimum_size = Vector2(0, 42)
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.text = value
	_apply_line_edit_palette(line_edit)
	line_edit.text_changed.connect(_on_bank_question_text_changed.bind(index, field_name))
	wrapper.add_child(line_edit)
	return wrapper

func _create_bank_question_text_edit(label_text: String, value: String, index: int, field_name: String) -> VBoxContainer:
	var wrapper: VBoxContainer = VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label: Label = Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", IA_COLOR_TEXT)
	wrapper.add_child(label)

	var text_edit: TextEdit = TextEdit.new()
	text_edit.custom_minimum_size = Vector2(0, 92)
	text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_edit.text = value
	_apply_text_edit_palette(text_edit)
	text_edit.text_changed.connect(_on_bank_question_text_edit_changed.bind(index, field_name, text_edit))
	wrapper.add_child(text_edit)
	return wrapper

func _create_bank_question_option_field(label_text: String, options: Array[String], current_value: String, index: int, field_name: String) -> VBoxContainer:
	var wrapper: VBoxContainer = VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label: Label = Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", IA_COLOR_TEXT)
	wrapper.add_child(label)

	var option_button: OptionButton = OptionButton.new()
	option_button.custom_minimum_size = Vector2(0, 42)
	option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_option_button_palette(option_button)
	for option in options:
		option_button.add_item(option)
	_select_option_button_item(option_button, current_value)
	option_button.item_selected.connect(_on_bank_question_option_selected.bind(index, field_name, option_button))
	wrapper.add_child(option_button)
	return wrapper

func _create_bank_question_spin_field(label_text: String, current_value: int, min_value: float, max_value: float, index: int, field_name: String) -> VBoxContainer:
	var wrapper: VBoxContainer = VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label: Label = Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", IA_COLOR_TEXT)
	wrapper.add_child(label)

	var spin_box: SpinBox = _create_spin_box(min_value, max_value, current_value)
	spin_box.value_changed.connect(_on_bank_question_number_changed.bind(index, field_name))
	wrapper.add_child(spin_box)
	return wrapper

func _on_bank_question_text_changed(new_text: String, index: int, field_name: String) -> void:
	if not _has_bank_question(index):
		return
	banco_perguntas[index][field_name] = new_text.strip_edges()

func _on_bank_question_text_edit_changed(index: int, field_name: String, text_edit: TextEdit) -> void:
	if not _has_bank_question(index):
		return
	banco_perguntas[index][field_name] = text_edit.text.strip_edges()

func _on_bank_question_option_selected(selected_index: int, index: int, field_name: String, option_button: OptionButton) -> void:
	if not _has_bank_question(index):
		return
	banco_perguntas[index][field_name] = option_button.get_item_text(selected_index)

func _on_bank_question_number_changed(value: float, index: int, field_name: String) -> void:
	if not _has_bank_question(index):
		return
	banco_perguntas[index][field_name] = int(round(value))

func _on_bank_question_save_pressed(index: int) -> void:
	if carregando_banco_perguntas or not _has_bank_question(index):
		return

	var question: Dictionary = banco_perguntas[index]
	var validation_error: String = _validate_editable_question(question, index)
	if not validation_error.is_empty():
		resumo_banco_perguntas.text = validation_error
		resumo_banco_perguntas.add_theme_color_override("font_color", STATUS_ERROR)
		return

	carregando_banco_perguntas = true
	_update_question_bank_controls_state()
	resumo_banco_perguntas.text = "Salvando alteracoes da pergunta #%d..." % int(question.get("id", 0))
	resumo_banco_perguntas.add_theme_color_override("font_color", STATUS_INFO)

	var response: Dictionary = await ApiClient.update_question(int(question.get("id", 0)), _build_question_payload(question))

	carregando_banco_perguntas = false
	_update_question_bank_controls_state()

	if not response.get("ok", false):
		resumo_banco_perguntas.text = response.get("error", "Nao foi possivel salvar a pergunta.")
		resumo_banco_perguntas.add_theme_color_override("font_color", STATUS_ERROR)
		return

	resumo_banco_perguntas.text = "Pergunta #%d atualizada com sucesso." % int(question.get("id", 0))
	resumo_banco_perguntas.add_theme_color_override("font_color", STATUS_OK)
	await _refresh_question_bank()

func _on_bank_question_delete_pressed(index: int) -> void:
	if carregando_banco_perguntas or not _has_bank_question(index):
		return

	var question_id: int = int(banco_perguntas[index].get("id", 0))
	carregando_banco_perguntas = true
	_update_question_bank_controls_state()
	resumo_banco_perguntas.text = "Excluindo a pergunta #%d..." % question_id
	resumo_banco_perguntas.add_theme_color_override("font_color", STATUS_INFO)

	var response: Dictionary = await ApiClient.delete_question(question_id)

	carregando_banco_perguntas = false
	_update_question_bank_controls_state()

	if not response.get("ok", false):
		resumo_banco_perguntas.text = response.get("error", "Nao foi possivel excluir a pergunta.")
		resumo_banco_perguntas.add_theme_color_override("font_color", STATUS_ERROR)
		return

	resumo_banco_perguntas.text = "Pergunta #%d excluida com sucesso." % question_id
	resumo_banco_perguntas.add_theme_color_override("font_color", STATUS_OK)
	await _refresh_question_bank()

func _build_question_payload(question: Dictionary) -> Dictionary:
	var payload: Dictionary = question.duplicate(true)
	payload.erase("id")
	if str(payload.get("titulo", "")).strip_edges().is_empty():
		payload.erase("titulo")
	if int(payload.get("tempoLimite", 0)) <= 0:
		payload.erase("tempoLimite")
	return payload

func _validate_editable_question(question: Dictionary, index: int) -> String:
	var question_copy: Dictionary = question.duplicate(true)
	question_copy["statusAuditoria"] = IA_STATUS_APPROVED
	return _validate_generated_question(question_copy, index)

func _update_question_bank_controls_state() -> void:
	if botao_atualizar_perguntas != null:
		botao_atualizar_perguntas.disabled = carregando_banco_perguntas or importando_perguntas
		botao_atualizar_perguntas.text = "ATUALIZANDO..." if carregando_banco_perguntas else "ATUALIZAR BANCO"
	if botao_importar != null:
		botao_importar.disabled = carregando or importando_perguntas or carregando_banco_perguntas
		botao_importar.text = "IMPORTANDO..." if importando_perguntas else "IMPORTAR PERGUNTAS"

func _has_bank_question(index: int) -> bool:
	return index >= 0 and index < banco_perguntas.size()

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
		empty_label.add_theme_color_override("font_color", IA_COLOR_MUTED)
		ia_lista.add_child(empty_label)
		_update_ia_summary()
		return

	for index in range(perguntas_geradas.size()):
		var question: Dictionary = perguntas_geradas[index]
		ia_lista.add_child(_create_generated_question_card(question, index))

	_update_ia_summary()

func _create_generated_question_card(question: Dictionary, index: int) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _create_question_card_style(IA_STATUS_PENDING))
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
	title.add_theme_color_override("font_color", IA_COLOR_ACCENT_DARK)
	header.add_child(title)

	var status_badge: PanelContainer = PanelContainer.new()
	status_badge.add_theme_stylebox_override("panel", _create_status_badge_style(IA_STATUS_PENDING))
	header.add_child(status_badge)

	var status_label: Label = Label.new()
	status_badge.add_child(status_label)

	cards_perguntas_ia.append({
		"card": card,
		"status_badge": status_badge,
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
	botao_pendente.text = "PENDENTE"
	botao_pendente.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botao_pendente.pressed.connect(_on_generated_question_status_changed.bind(index, IA_STATUS_PENDING))
	actions.add_child(botao_pendente)

	var botao_aprovar: Button = Button.new()
	botao_aprovar.text = "APROVAR"
	botao_aprovar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botao_aprovar.pressed.connect(_on_generated_question_status_changed.bind(index, IA_STATUS_APPROVED))
	actions.add_child(botao_aprovar)

	var botao_rejeitar: Button = Button.new()
	botao_rejeitar.text = "REJEITAR"
	botao_rejeitar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botao_rejeitar.pressed.connect(_on_generated_question_status_changed.bind(index, IA_STATUS_REJECTED))
	actions.add_child(botao_rejeitar)

	cards_perguntas_ia[index]["button_pending"] = botao_pendente
	cards_perguntas_ia[index]["button_approve"] = botao_aprovar
	cards_perguntas_ia[index]["button_reject"] = botao_rejeitar

	_update_generated_question_status_visual(index)
	return card

func _create_question_card_style(status: String) -> StyleBoxFlat:
	match status:
		IA_STATUS_APPROVED:
			return _create_ia_surface_style(IA_COLOR_APPROVED_SOFT, IA_COLOR_APPROVED, 2, 14, 14, 14)
		IA_STATUS_REJECTED:
			return _create_ia_surface_style(IA_COLOR_REJECTED_SOFT, IA_COLOR_REJECTED, 2, 14, 14, 14)
		_:
			return _create_ia_surface_style(IA_COLOR_SURFACE, IA_COLOR_PENDING, 2, 14, 14, 14)

func _create_status_badge_style(status: String) -> StyleBoxFlat:
	match status:
		IA_STATUS_APPROVED:
			return _create_ia_surface_style(IA_COLOR_APPROVED, _shade_color(IA_COLOR_APPROVED, 0.28), 2, 999, 12, 6)
		IA_STATUS_REJECTED:
			return _create_ia_surface_style(IA_COLOR_REJECTED, _shade_color(IA_COLOR_REJECTED, 0.28), 2, 999, 12, 6)
		_:
			return _create_ia_surface_style(IA_COLOR_PENDING, _shade_color(IA_COLOR_PENDING, 0.28), 2, 999, 12, 6)

func _create_card_line_edit(label_text: String, value: String, index: int, field_name: String) -> VBoxContainer:
	var wrapper: VBoxContainer = VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label: Label = Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", IA_COLOR_TEXT)
	wrapper.add_child(label)

	var line_edit: LineEdit = LineEdit.new()
	line_edit.custom_minimum_size = Vector2(0, 42)
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.text = value
	_apply_line_edit_palette(line_edit)
	line_edit.text_changed.connect(_on_generated_question_text_changed.bind(index, field_name))
	wrapper.add_child(line_edit)

	return wrapper

func _create_card_text_edit(label_text: String, value: String, index: int, field_name: String) -> VBoxContainer:
	var wrapper: VBoxContainer = VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label: Label = Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", IA_COLOR_TEXT)
	wrapper.add_child(label)

	var text_edit: TextEdit = TextEdit.new()
	text_edit.custom_minimum_size = Vector2(0, 100)
	text_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_edit.text = value
	_apply_text_edit_palette(text_edit)
	text_edit.text_changed.connect(_on_generated_question_text_edit_changed.bind(index, field_name, text_edit))
	wrapper.add_child(text_edit)

	return wrapper

func _create_card_option_field(label_text: String, options: Array[String], current_value: String, index: int, field_name: String) -> VBoxContainer:
	var wrapper: VBoxContainer = VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var label: Label = Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", IA_COLOR_TEXT)
	wrapper.add_child(label)

	var option_button: OptionButton = OptionButton.new()
	option_button.custom_minimum_size = Vector2(0, 42)
	option_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_palette(option_button, Color(1.0, 1.0, 1.0, 0.98), IA_COLOR_BORDER, IA_COLOR_TEXT)
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
	label.add_theme_color_override("font_color", IA_COLOR_TEXT)
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

func _on_botao_aprovar_todas_pressed() -> void:
	_set_all_generated_questions_status(IA_STATUS_APPROVED)

func _on_botao_rejeitar_todas_pressed() -> void:
	_set_all_generated_questions_status(IA_STATUS_REJECTED)

func _set_all_generated_questions_status(new_status: String) -> void:
	if perguntas_geradas.is_empty() or ia_processando or ia_salvando:
		return

	for index in range(perguntas_geradas.size()):
		perguntas_geradas[index]["statusAuditoria"] = new_status
		_update_generated_question_status_visual(index)

	_update_ia_summary()
	_show_ia_feedback("Todas as perguntas foram marcadas como %s." % _get_bulk_status_text(new_status), _get_ia_status_color(new_status))

func _get_bulk_status_text(status: String) -> String:
	match status:
		IA_STATUS_APPROVED:
			return "aprovadas"
		IA_STATUS_REJECTED:
			return "rejeitadas"
		_:
			return "pendentes"

func _update_generated_question_status_visual(index: int) -> void:
	if index < 0 or index >= cards_perguntas_ia.size():
		return

	var card_info: Dictionary = cards_perguntas_ia[index]
	var card: PanelContainer = card_info.get("card", null) as PanelContainer
	var status_badge: PanelContainer = card_info.get("status_badge", null) as PanelContainer
	var status_label: Label = card_info.get("status_label", null) as Label
	if status_label == null:
		return

	var status: String = str(perguntas_geradas[index].get("statusAuditoria", IA_STATUS_PENDING))
	status_label.text = _get_ia_status_label(status)
	status_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))

	if card != null:
		card.add_theme_stylebox_override("panel", _create_question_card_style(status))
	if status_badge != null:
		status_badge.add_theme_stylebox_override("panel", _create_status_badge_style(status))

	_update_generated_question_action_buttons(card_info, status)

func _get_ia_status_label(status: String) -> String:
	match status:
		IA_STATUS_APPROVED:
			return "Aprovada"
		IA_STATUS_REJECTED:
			return "Rejeitada"
		_:
			return "Pendente"

func _update_generated_question_action_buttons(card_info: Dictionary, current_status: String) -> void:
	var button_pending: Button = card_info.get("button_pending", null) as Button
	var button_approve: Button = card_info.get("button_approve", null) as Button
	var button_reject: Button = card_info.get("button_reject", null) as Button

	if button_pending != null:
		if current_status == IA_STATUS_PENDING:
			_apply_button_palette(button_pending, IA_COLOR_PENDING, _shade_color(IA_COLOR_PENDING, 0.28))
		else:
			_apply_button_palette(button_pending, IA_COLOR_PENDING_SOFT, IA_COLOR_PENDING, IA_COLOR_TEXT)

	if button_approve != null:
		if current_status == IA_STATUS_APPROVED:
			_apply_button_palette(button_approve, IA_COLOR_APPROVED, _shade_color(IA_COLOR_APPROVED, 0.28))
		else:
			_apply_button_palette(button_approve, IA_COLOR_APPROVED_SOFT, IA_COLOR_APPROVED, IA_COLOR_TEXT)

	if button_reject != null:
		if current_status == IA_STATUS_REJECTED:
			_apply_button_palette(button_reject, IA_COLOR_REJECTED, _shade_color(IA_COLOR_REJECTED, 0.28))
		else:
			_apply_button_palette(button_reject, IA_COLOR_REJECTED_SOFT, IA_COLOR_REJECTED, IA_COLOR_TEXT)

func _get_ia_status_color(status: String) -> Color:
	match status:
		IA_STATUS_APPROVED:
			return IA_COLOR_APPROVED
		IA_STATUS_REJECTED:
			return IA_COLOR_REJECTED
		_:
			return IA_COLOR_PENDING

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
		ia_botao_gerar.text = "GERANDO..." if ia_processando else "GERAR COM IA"
	if ia_botao_salvar != null:
		ia_botao_salvar.disabled = controls_locked or _count_generated_questions_with_status(IA_STATUS_APPROVED) == 0
		ia_botao_salvar.text = "SALVANDO APROVADAS..." if ia_salvando else "SALVAR PERGUNTAS APROVADAS"
	if ia_botao_aprovar_todas != null:
		ia_botao_aprovar_todas.disabled = controls_locked or perguntas_geradas.is_empty() or _count_generated_questions_with_status(IA_STATUS_APPROVED) == perguntas_geradas.size()
	if ia_botao_rejeitar_todas != null:
		ia_botao_rejeitar_todas.disabled = controls_locked or perguntas_geradas.is_empty() or _count_generated_questions_with_status(IA_STATUS_REJECTED) == perguntas_geradas.size()

	_update_question_bank_controls_state()
	botao_sair.disabled = carregando or ia_processando or ia_salvando or carregando_banco_perguntas

func _show_ia_feedback(message: String, color_value: Color) -> void:
	if ia_label_feedback == null:
		return

	ia_label_feedback.text = message
	ia_label_feedback.modulate = Color(1.0, 1.0, 1.0, 1.0)
	ia_label_feedback.add_theme_color_override("font_color", color_value)

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
	await _refresh_question_bank()

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
