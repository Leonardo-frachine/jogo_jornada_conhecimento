extends Control

const UITheme := preload("res://scripts/UITheme.gd")
const MetricCardScene := preload("res://scene/professor/components/MetricCard.tscn")
const QuestionCardScene := preload("res://scene/professor/components/QuestionCard.tscn")

const VIEW_DASHBOARD := "dashboard"
const VIEW_ROOM := "room"
const VIEW_STUDENTS := "students"
const VIEW_BANK := "bank"
const VIEW_IMPORT := "import"
const VIEW_AI := "ai"

const STATUS_INFO := UITheme.STATUS_INFO
const STATUS_OK := UITheme.STATUS_SUCCESS
const STATUS_WARNING := UITheme.STATUS_WARNING
const STATUS_ERROR := UITheme.STATUS_ERROR

const COLOR_BACKGROUND := UITheme.PROFESSOR_BACKGROUND
const COLOR_SURFACE := UITheme.PROFESSOR_SURFACE
const COLOR_SURFACE_ALT := UITheme.PROFESSOR_SURFACE_ALT
const COLOR_BORDER := UITheme.PROFESSOR_BORDER
const COLOR_TEXT := UITheme.PROFESSOR_TEXT
const COLOR_MUTED := UITheme.PROFESSOR_MUTED
const COLOR_ACCENT := UITheme.PROFESSOR_ACCENT
const COLOR_ACCENT_DARK := UITheme.PROFESSOR_ACCENT_DARK
const COLOR_SIDEBAR := UITheme.PROFESSOR_SIDEBAR
const COLOR_SIDEBAR_BORDER := UITheme.PROFESSOR_SIDEBAR_BORDER
const COLOR_SIDEBAR_TEXT := UITheme.PROFESSOR_SIDEBAR_TEXT
const COLOR_SIDEBAR_MUTED := UITheme.PROFESSOR_SIDEBAR_MUTED
const COLOR_GLOW_PRIMARY := UITheme.APP_GLOW_PRIMARY
const COLOR_GLOW_SECONDARY := UITheme.APP_GLOW_SECONDARY

const IA_STATUS_PENDING := "pendente"
const IA_STATUS_APPROVED := "aprovada"
const IA_STATUS_REJECTED := "rejeitada"
const IA_DIFFICULTIES: Array[String] = ["Facil", "Medio", "Dificil", "Especial"]
const QUESTION_CORRECT_OPTIONS: Array[String] = ["A", "B", "C", "D"]
# Heuristica provisoria ate o backend expor um status formal de partida por aluno.
const STUDENT_FINAL_PHASE_ESTIMATE := 10

const PAGE_META := {
	VIEW_DASHBOARD: {
		"title": "Dashboard",
		"subtitle": "Indicadores visuais e resumo da sala selecionada.",
	},
	VIEW_ROOM: {
		"title": "Gerenciar Sala",
		"subtitle": "Crie, atualize e remova salas mantendo o mesmo contexto do painel.",
	},
	VIEW_STUDENTS: {
		"title": "Acompanhamento",
		"subtitle": "Progresso individual dos alunos e estado atual da turma.",
	},
	VIEW_BANK: {
		"title": "Banco de Perguntas",
		"subtitle": "Cards mais leves para revisar, editar e organizar o banco oficial.",
	},
	VIEW_IMPORT: {
		"title": "Importar Perguntas",
		"subtitle": "Envie planilhas e acompanhe o status da importacao em um fluxo mais claro.",
	},
	VIEW_AI: {
		"title": "Gerar com IA",
		"subtitle": "Gere perguntas via backend, revise a previa e aprove somente o que fizer sentido.",
	},
}

@onready var background: ColorRect = $Background
@onready var soft_glow_top: ColorRect = $SoftGlowTop
@onready var soft_glow_bottom: ColorRect = $SoftGlowBottom
@onready var safe_area: MarginContainer = $SafeArea
@onready var shell: HBoxContainer = $SafeArea/Shell
@onready var sidebar: PanelContainer = $SafeArea/Shell/Sidebar
@onready var sidebar_brand_title: Label = $SafeArea/Shell/Sidebar/Margin/VBox/TopRow/BrandText/BrandTitle
@onready var sidebar_brand_subtitle: Label = $SafeArea/Shell/Sidebar/Margin/VBox/TopRow/BrandText/BrandSubtitle
@onready var sidebar_description: Label = $SafeArea/Shell/Sidebar/Margin/VBox/SidebarDescription
@onready var sidebar_toggle: TextureButton = $SafeArea/Shell/Sidebar/Margin/VBox/TopRow/BotaoToggleSidebar
@onready var sidebar_footer_title: Label = $SafeArea/Shell/Sidebar/Margin/VBox/SidebarFooter/FooterMargin/FooterText/FooterTitle
@onready var sidebar_footer_subtitle: Label = $SafeArea/Shell/Sidebar/Margin/VBox/SidebarFooter/FooterMargin/FooterText/FooterSubtitle
@onready var botao_dashboard: Button = $SafeArea/Shell/Sidebar/Margin/VBox/NavList/BotaoDashboard
@onready var botao_gerenciar_sala_menu: Button = $SafeArea/Shell/Sidebar/Margin/VBox/NavList/BotaoGerenciarSala
@onready var botao_acompanhamento: Button = $SafeArea/Shell/Sidebar/Margin/VBox/NavList/BotaoAcompanhamento
@onready var botao_banco_perguntas: Button = $SafeArea/Shell/Sidebar/Margin/VBox/NavList/BotaoBancoPerguntas
@onready var botao_importar_pagina: Button = $SafeArea/Shell/Sidebar/Margin/VBox/NavList/BotaoImportarPerguntas
@onready var botao_gerar_ia_pagina: Button = $SafeArea/Shell/Sidebar/Margin/VBox/NavList/BotaoGerarIa
@onready var botao_configuracoes_menu: Button = $SafeArea/Shell/Sidebar/Margin/VBox/NavList/BotaoConfiguracoes

@onready var header: PanelContainer = $SafeArea/Shell/MainColumn/Header
@onready var page_title: Label = $SafeArea/Shell/MainColumn/Header/Margin/HeaderLayout/TitleColumn/PageTitle
@onready var page_subtitle: Label = $SafeArea/Shell/MainColumn/Header/Margin/HeaderLayout/TitleColumn/PageSubtitle
@onready var status_label: Label = $SafeArea/Shell/MainColumn/Header/Margin/HeaderLayout/TitleColumn/StatusLabel
@onready var header_actions: HBoxContainer = $SafeArea/Shell/MainColumn/Header/Margin/HeaderLayout/Actions
@onready var current_room_badge: PanelContainer = $SafeArea/Shell/MainColumn/Header/Margin/HeaderLayout/Actions/CurrentRoomBadge
@onready var current_room_label: Label = $SafeArea/Shell/MainColumn/Header/Margin/HeaderLayout/Actions/CurrentRoomBadge/CurrentRoomMargin/CurrentRoomLabel
@onready var seletor_salas: OptionButton = $SafeArea/Shell/MainColumn/Header/Margin/HeaderLayout/Actions/SeletorSalas
@onready var botao_atualizar_salas_header: Button = $SafeArea/Shell/MainColumn/Header/Margin/HeaderLayout/Actions/BotaoAtualizarSala
@onready var botao_sair: Button = $SafeArea/Shell/MainColumn/Header/Margin/HeaderLayout/Actions/BotaoSair

@onready var content_shell: PanelContainer = $SafeArea/Shell/MainColumn/ContentShell
@onready var content_scroll: ScrollContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll
@onready var dashboard_page: VBoxContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage
@onready var gerenciar_sala_page: VBoxContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerenciarSalaPage
@onready var acompanhamento_page: VBoxContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/AcompanhamentoPage
@onready var banco_page: VBoxContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage
@onready var importar_page: VBoxContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/ImportarPerguntasPage
@onready var ia_page: VBoxContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage

@onready var dashboard_hero_card: PanelContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardHeroCard
@onready var dashboard_hero_title: Label = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardHeroCard/HeroMargin/HeroVBox/DashboardHeroTitle
@onready var dashboard_hero_description: Label = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardHeroCard/HeroMargin/HeroVBox/DashboardHeroDescription
@onready var metrics_grid: GridContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/MetricsGrid
@onready var dashboard_body_grid: GridContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardBodyGrid
@onready var lista_materias_dashboard: VBoxContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardBodyGrid/PainelMaterias/MateriasMargin/MateriasVBox/ListaMaterias
@onready var lista_dificuldades_dashboard: VBoxContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardBodyGrid/PainelDificuldades/DificuldadesMargin/DificuldadesVBox/ListaDificuldades
@onready var dashboard_secondary_grid: GridContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardSecondaryGrid
@onready var lista_atividades: VBoxContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardSecondaryGrid/PainelAtividades/AtividadesMargin/AtividadesVBox/ListaAtividades
@onready var gerenciar_sala_grid: GridContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerenciarSalaPage/GerenciarSalaGrid
@onready var resumo_gerenciar_sala: Label = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerenciarSalaPage/GerenciarSalaHero/GerenciarSalaHeroMargin/GerenciarSalaHeroVBox/ResumoGerenciarSala
@onready var sala_atual_info: Label = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerenciarSalaPage/GerenciarSalaGrid/PainelSalaGerenciar/SalaGerenciarMargin/SalaGerenciarVBox/SalaAtualInfo
@onready var sala_codigo_info: Label = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerenciarSalaPage/GerenciarSalaGrid/PainelSalaGerenciar/SalaGerenciarMargin/SalaGerenciarVBox/SalaCodigoInfo
@onready var input_nome_sala: LineEdit = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerenciarSalaPage/GerenciarSalaGrid/PainelSalaGerenciar/SalaGerenciarMargin/SalaGerenciarVBox/InputNomeSalaGerenciar
@onready var acoes_sala: GridContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerenciarSalaPage/GerenciarSalaGrid/PainelSalaGerenciar/SalaGerenciarMargin/SalaGerenciarVBox/AcoesSalaGerenciar
@onready var botao_criar_sala: Button = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerenciarSalaPage/GerenciarSalaGrid/PainelSalaGerenciar/SalaGerenciarMargin/SalaGerenciarVBox/AcoesSalaGerenciar/BotaoCriarSalaGerenciar
@onready var botao_atualizar_salas: Button = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerenciarSalaPage/GerenciarSalaGrid/PainelSalaGerenciar/SalaGerenciarMargin/SalaGerenciarVBox/AcoesSalaGerenciar/BotaoAtualizarSalasGerenciar
@onready var botao_apagar_sala: Button = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerenciarSalaPage/GerenciarSalaGrid/PainelSalaGerenciar/SalaGerenciarMargin/SalaGerenciarVBox/AcoesSalaGerenciar/BotaoApagarSalaGerenciar

@onready var resumo_acompanhamento: Label = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/AcompanhamentoPage/AcompanhamentoHero/AcompanhamentoHeroMargin/AcompanhamentoHeroVBox/ResumoAcompanhamento
@onready var acompanhamento_grid: GridContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/AcompanhamentoPage/AcompanhamentoGrid

@onready var resumo_banco_perguntas: Label = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasHeaderCard/PerguntasHeaderMargin/PerguntasHeaderVBox/PerguntasHeaderTop/PerguntasTituloBox/ResumoBancoPerguntas
@onready var contador_banco_perguntas: Label = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasHeaderCard/PerguntasHeaderMargin/PerguntasHeaderVBox/PerguntasHeaderTop/PerguntasContador
@onready var botao_atualizar_perguntas: Button = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasHeaderCard/PerguntasHeaderMargin/PerguntasHeaderVBox/PerguntasActions/BotaoAtualizarPerguntas
@onready var botao_expandir_todas: Button = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasHeaderCard/PerguntasHeaderMargin/PerguntasHeaderVBox/PerguntasActions/BotaoExpandirTodas
@onready var botao_recolher_todas: Button = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasHeaderCard/PerguntasHeaderMargin/PerguntasHeaderVBox/PerguntasActions/BotaoRecolherTodas
@onready var input_busca_perguntas: LineEdit = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasFiltersCard/PerguntasFiltersMargin/PerguntasFiltersGrid/InputBuscaPerguntas
@onready var filtro_materia_perguntas: OptionButton = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasFiltersCard/PerguntasFiltersMargin/PerguntasFiltersGrid/FiltroMateriaPerguntas
@onready var filtro_dificuldade_perguntas: OptionButton = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasFiltersCard/PerguntasFiltersMargin/PerguntasFiltersGrid/FiltroDificuldadePerguntas
@onready var lista_banco_perguntas: VBoxContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/ListaBancoPerguntas

@onready var importar_feedback: Label = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/ImportarPerguntasPage/ImportarIntroCard/ImportarIntroMargin/ImportarIntroVBox/ImportarFeedback
@onready var botao_importar: Button = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/ImportarPerguntasPage/ImportarIntroCard/ImportarIntroMargin/ImportarIntroVBox/BotaoImportar

@onready var ia_tema_input: LineEdit = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaFormCard/IaFormMargin/IaFormGrid/IaTemaInput
@onready var ia_materia_input: LineEdit = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaFormCard/IaFormMargin/IaFormGrid/IaMateriaInput
@onready var ia_dificuldade_select: OptionButton = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaFormCard/IaFormMargin/IaFormGrid/IaDificuldadeSelect
@onready var ia_quantidade_input: SpinBox = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaFormCard/IaFormMargin/IaFormGrid/IaQuantidadeInput
@onready var ia_pontuacao_input: SpinBox = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaFormCard/IaFormMargin/IaFormGrid/IaPontuacaoInput
@onready var ia_tempo_input: SpinBox = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaFormCard/IaFormMargin/IaFormGrid/IaTempoInput
@onready var ia_botao_gerar: Button = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaActionsGrid/IaBotaoGerar
@onready var ia_botao_salvar: Button = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaActionsGrid/IaBotaoSalvar
@onready var ia_botao_aprovar_todas: Button = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaActionsGrid/IaBotaoAprovarTodas
@onready var ia_botao_rejeitar_todas: Button = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaActionsGrid/IaBotaoRejeitarTodas
@onready var ia_label_feedback: Label = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaIntroCard/IaIntroMargin/IaIntroVBox/IaLabelFeedback
@onready var ia_label_resumo: Label = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaSummaryCard/IaSummaryMargin/IaLabelResumo
@onready var ia_lista: VBoxContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaLista

@onready var confirmacao_apagar_sala: ConfirmationDialog = $ConfirmacaoApagarSala

var salas: Array[Dictionary] = []
var carregando := false
var importando_perguntas := false
var carregando_banco_perguntas := false
var ia_processando := false
var ia_salvando := false
var sidebar_expanded := true
var import_dialog: FileDialog

var current_view := VIEW_DASHBOARD
var dashboard_payload: Dictionary = {}
var respostas_sala: Array[Dictionary] = []
var banco_perguntas: Array[Dictionary] = []
var perguntas_geradas: Array[Dictionary] = []
var expanded_bank_question_ids := {}
var expanded_generated_question_ids := {}
var settings_overlay_bound := false

func _ready() -> void:
	SettingsManager.pause_tree_when_open = false
	SettingsManager.close_menu()

	if not ProfessorSession.has_session():
		get_tree().change_scene_to_file("res://scene/acesso_professor.tscn")
		return

	_ensure_import_dialog()
	_connect_signals()
	_bind_settings_overlay_signals()
	_apply_theme()
	_setup_ia_form()
	_update_responsive_layout()
	_set_current_view(VIEW_DASHBOARD)
	_render_empty_dashboard()
	_render_students([])
	_render_question_bank()
	_render_generated_questions()
	_set_import_feedback("Aguardando o envio de uma planilha .csv ou .xlsx.", STATUS_INFO)
	_show_ia_feedback("Preencha os dados para gerar uma previa de perguntas.", STATUS_INFO)
	_show_status("Painel pronto para carregar as salas do professor.", STATUS_INFO)

	if not get_viewport().size_changed.is_connected(_update_responsive_layout):
		get_viewport().size_changed.connect(_update_responsive_layout)

	call_deferred("_load_initial_data")

func _connect_signals() -> void:
	sidebar_toggle.pressed.connect(_on_sidebar_toggle_pressed)
	botao_dashboard.pressed.connect(_on_navigation_pressed.bind(VIEW_DASHBOARD))
	botao_gerenciar_sala_menu.pressed.connect(_on_navigation_pressed.bind(VIEW_ROOM))
	botao_acompanhamento.pressed.connect(_on_navigation_pressed.bind(VIEW_STUDENTS))
	botao_banco_perguntas.pressed.connect(_on_navigation_pressed.bind(VIEW_BANK))
	botao_importar_pagina.pressed.connect(_on_navigation_pressed.bind(VIEW_IMPORT))
	botao_gerar_ia_pagina.pressed.connect(_on_navigation_pressed.bind(VIEW_AI))
	botao_configuracoes_menu.pressed.connect(_on_botao_configuracao_pressed)

	seletor_salas.item_selected.connect(_on_seletor_salas_item_selected)
	botao_atualizar_salas_header.pressed.connect(_on_botao_atualizar_salas_pressed)
	botao_sair.pressed.connect(_on_botao_sair_pressed)

	botao_criar_sala.pressed.connect(_on_botao_criar_sala_pressed)
	botao_atualizar_salas.pressed.connect(_on_botao_atualizar_salas_pressed)
	botao_apagar_sala.pressed.connect(_on_botao_apagar_sala_pressed)
	confirmacao_apagar_sala.confirmed.connect(_on_confirmacao_apagar_sala_confirmed)

	botao_atualizar_perguntas.pressed.connect(_on_botao_atualizar_banco_perguntas_pressed)
	botao_expandir_todas.pressed.connect(_on_botao_expandir_todas_pressed)
	botao_recolher_todas.pressed.connect(_on_botao_recolher_todas_pressed)
	input_busca_perguntas.text_changed.connect(_on_question_filter_changed)
	filtro_materia_perguntas.item_selected.connect(_on_question_filter_changed)
	filtro_dificuldade_perguntas.item_selected.connect(_on_question_filter_changed)

	botao_importar.pressed.connect(_on_botao_importar_pressed)

	ia_botao_gerar.pressed.connect(_on_botao_gerar_ia_pressed)
	ia_botao_salvar.pressed.connect(_on_botao_salvar_aprovadas_pressed)
	ia_botao_aprovar_todas.pressed.connect(_on_botao_aprovar_todas_pressed)
	ia_botao_rejeitar_todas.pressed.connect(_on_botao_rejeitar_todas_pressed)

func _load_initial_data() -> void:
	await _fetch_rooms(true)
	await _refresh_question_bank()

func _bind_settings_overlay_signals() -> void:
	if settings_overlay_bound:
		return
	var overlay = SettingsManager.overlay
	if overlay == null or not is_instance_valid(overlay):
		call_deferred("_bind_settings_overlay_signals")
		return
	if overlay.has_signal("menu_opened") and not overlay.menu_opened.is_connected(_on_settings_overlay_opened):
		overlay.menu_opened.connect(_on_settings_overlay_opened)
	if overlay.has_signal("menu_closed") and not overlay.menu_closed.is_connected(_on_settings_overlay_closed):
		overlay.menu_closed.connect(_on_settings_overlay_closed)
	settings_overlay_bound = true

func _apply_theme() -> void:
	UITheme.apply_font_tree(self)
	background.color = COLOR_BACKGROUND
	soft_glow_top.color = COLOR_GLOW_PRIMARY
	soft_glow_bottom.color = COLOR_GLOW_SECONDARY
	_apply_surface_panel(sidebar, COLOR_SIDEBAR, COLOR_SIDEBAR_BORDER, 28, 0.05)
	_apply_surface_panel(header, COLOR_SURFACE, COLOR_BORDER, 24, 0.08)
	_apply_surface_panel(content_shell, COLOR_SURFACE, COLOR_BORDER, 26, 0.06)

	for panel in [
		dashboard_hero_card,
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerenciarSalaPage/GerenciarSalaHero"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerenciarSalaPage/GerenciarSalaGrid/PainelSalaGerenciar"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardBodyGrid/PainelMaterias"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardBodyGrid/PainelDificuldades"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardSecondaryGrid/PainelAtividades"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/AcompanhamentoPage/AcompanhamentoHero"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasHeaderCard"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasFiltersCard"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/ImportarPerguntasPage/ImportarIntroCard"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaIntroCard"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaFormCard"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaSummaryCard"),
	]:
		_apply_surface_panel(panel as PanelContainer, COLOR_SURFACE, COLOR_BORDER, 22, 0.05)

	UITheme.apply_title(page_title, 30, COLOR_TEXT)
	UITheme.apply_subtitle(page_subtitle, 15, COLOR_MUTED)
	UITheme.apply_subtitle(status_label, 14, COLOR_MUTED)
	UITheme.apply_subtitle(current_room_label, 14, COLOR_ACCENT_DARK)
	_apply_badge_panel(current_room_badge, _tint_color(COLOR_ACCENT, 0.86), COLOR_ACCENT)

	UITheme.apply_title(dashboard_hero_title, 24, COLOR_TEXT)
	UITheme.apply_subtitle(dashboard_hero_description, 15, COLOR_MUTED)
	UITheme.apply_title(get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerenciarSalaPage/GerenciarSalaHero/GerenciarSalaHeroMargin/GerenciarSalaHeroVBox/TituloGerenciarSala"), 22, COLOR_TEXT)
	UITheme.apply_title(get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerenciarSalaPage/GerenciarSalaGrid/PainelSalaGerenciar/SalaGerenciarMargin/SalaGerenciarVBox/TituloSalaCardGerenciar"), 20, COLOR_TEXT)
	UITheme.apply_title(get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardBodyGrid/PainelMaterias/MateriasMargin/MateriasVBox/TituloMaterias"), 20, COLOR_TEXT)
	UITheme.apply_title(get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardBodyGrid/PainelDificuldades/DificuldadesMargin/DificuldadesVBox/TituloDificuldades"), 20, COLOR_TEXT)
	UITheme.apply_title(get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardSecondaryGrid/PainelAtividades/AtividadesMargin/AtividadesVBox/TituloAtividades"), 20, COLOR_TEXT)
	UITheme.apply_title(get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/AcompanhamentoPage/AcompanhamentoHero/AcompanhamentoHeroMargin/AcompanhamentoHeroVBox/TituloAcompanhamento"), 22, COLOR_TEXT)
	UITheme.apply_title(get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasHeaderCard/PerguntasHeaderMargin/PerguntasHeaderVBox/PerguntasHeaderTop/PerguntasTituloBox/TituloBancoPerguntas"), 22, COLOR_TEXT)
	UITheme.apply_title(get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/ImportarPerguntasPage/ImportarIntroCard/ImportarIntroMargin/ImportarIntroVBox/TituloImportar"), 22, COLOR_TEXT)
	UITheme.apply_title(get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaIntroCard/IaIntroMargin/IaIntroVBox/TituloIa"), 22, COLOR_TEXT)

	for label in [
		sidebar_brand_title,
		sidebar_brand_subtitle,
		sidebar_description,
		sidebar_footer_title,
		sidebar_footer_subtitle,
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardBodyGrid/PainelMaterias/MateriasMargin/MateriasVBox/DescricaoMaterias"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardBodyGrid/PainelDificuldades/DificuldadesMargin/DificuldadesVBox/DescricaoDificuldades"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardSecondaryGrid/PainelAtividades/AtividadesMargin/AtividadesVBox/DescricaoAtividades"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/ImportarPerguntasPage/ImportarIntroCard/ImportarIntroMargin/ImportarIntroVBox/DescricaoImportar"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaIntroCard/IaIntroMargin/IaIntroVBox/DescricaoIa"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerenciarSalaPage/GerenciarSalaGrid/PainelSalaGerenciar/SalaGerenciarMargin/SalaGerenciarVBox/DescricaoSalaCardGerenciar"),
		resumo_acompanhamento,
		resumo_banco_perguntas,
		contador_banco_perguntas,
		importar_feedback,
		ia_label_feedback,
		ia_label_resumo,
		resumo_gerenciar_sala,
		sala_atual_info,
		sala_codigo_info,
	]:
		UITheme.apply_subtitle(label as Label, 15, COLOR_MUTED if label != contador_banco_perguntas else COLOR_ACCENT_DARK)

	UITheme.apply_subtitle(sidebar_brand_title, 18, COLOR_SIDEBAR_TEXT)
	UITheme.apply_subtitle(sidebar_brand_subtitle, 13, COLOR_SIDEBAR_MUTED)
	UITheme.apply_subtitle(sidebar_description, 14, COLOR_SIDEBAR_MUTED)
	UITheme.apply_subtitle(sidebar_footer_title, 14, COLOR_SIDEBAR_TEXT)
	UITheme.apply_subtitle(sidebar_footer_subtitle, 13, COLOR_SIDEBAR_MUTED)

	_apply_line_edit_palette(input_nome_sala)
	_apply_line_edit_palette(input_busca_perguntas)
	_apply_line_edit_palette(ia_tema_input)
	_apply_line_edit_palette(ia_materia_input)
	_apply_option_button_palette(seletor_salas)
	_apply_option_button_palette(filtro_materia_perguntas)
	_apply_option_button_palette(filtro_dificuldade_perguntas)
	_apply_option_button_palette(ia_dificuldade_select)
	_apply_spin_box_palette(ia_quantidade_input)
	_apply_spin_box_palette(ia_pontuacao_input)
	_apply_spin_box_palette(ia_tempo_input)

	_apply_button_palette(botao_atualizar_salas_header, COLOR_SURFACE_ALT, COLOR_BORDER, COLOR_TEXT)
	_apply_button_palette(botao_sair, STATUS_ERROR, _shade_color(STATUS_ERROR, 0.24))
	_apply_button_palette(botao_criar_sala, COLOR_ACCENT, COLOR_ACCENT_DARK)
	_apply_button_palette(botao_atualizar_salas, STATUS_INFO, _shade_color(STATUS_INFO, 0.24))
	_apply_button_palette(botao_apagar_sala, STATUS_ERROR, _shade_color(STATUS_ERROR, 0.24))
	_apply_button_palette(botao_atualizar_perguntas, STATUS_INFO, _shade_color(STATUS_INFO, 0.24))
	_apply_button_palette(botao_expandir_todas, COLOR_SURFACE_ALT, COLOR_BORDER, COLOR_TEXT)
	_apply_button_palette(botao_recolher_todas, COLOR_SURFACE_ALT, COLOR_BORDER, COLOR_TEXT)
	_apply_button_palette(botao_importar, COLOR_ACCENT, COLOR_ACCENT_DARK)
	_apply_button_palette(ia_botao_gerar, COLOR_ACCENT, COLOR_ACCENT_DARK)
	_apply_button_palette(ia_botao_salvar, STATUS_OK, _shade_color(STATUS_OK, 0.22))
	_apply_button_palette(ia_botao_aprovar_todas, STATUS_OK, _shade_color(STATUS_OK, 0.22))
	_apply_button_palette(ia_botao_rejeitar_todas, STATUS_ERROR, _shade_color(STATUS_ERROR, 0.22))

	sidebar_toggle.modulate = COLOR_SIDEBAR_TEXT
	_apply_surface_panel(current_room_badge, _tint_color(COLOR_ACCENT, 0.88), COLOR_ACCENT, 999, 0.0)

	_apply_sidebar_styles()
	_refresh_header_context()

func _setup_ia_form() -> void:
	ia_dificuldade_select.clear()
	for difficulty in IA_DIFFICULTIES:
		ia_dificuldade_select.add_item(difficulty)
	ia_dificuldade_select.select(1)
	_configure_spin_box(ia_quantidade_input, 1, 20, 5)
	_configure_spin_box(ia_pontuacao_input, 1, 10000, 100)
	_configure_spin_box(ia_tempo_input, 0, 3600, 30)

func _update_responsive_layout() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var compact := viewport_size.x < 1260.0
	var content_width: float = content_shell.size.x
	if content_width <= 0.0:
		content_width = viewport_size.x - (sidebar.custom_minimum_size.x + (32.0 if compact else 48.0))
	var compact_content: bool = content_width < 980.0

	safe_area.add_theme_constant_override("margin_left", 16 if compact else 24)
	safe_area.add_theme_constant_override("margin_top", 16 if viewport_size.y < 760.0 else 24)
	safe_area.add_theme_constant_override("margin_right", 16 if compact else 24)
	safe_area.add_theme_constant_override("margin_bottom", 16 if viewport_size.y < 760.0 else 24)
	shell.add_theme_constant_override("separation", 16 if compact else 22)
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	metrics_grid.columns = 1 if content_width < 700.0 else (2 if content_width < 1080.0 else (3 if content_width < 1420.0 else 4))
	dashboard_body_grid.columns = 1 if content_width < 1040.0 else 2
	dashboard_secondary_grid.columns = 1
	gerenciar_sala_grid.columns = 1
	acoes_sala.columns = 1 if content_width < 900.0 else 3
	acompanhamento_grid.columns = 1 if content_width < 1180.0 else 2
	get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasHeaderCard/PerguntasHeaderMargin/PerguntasHeaderVBox/PerguntasActions").columns = 1 if content_width < 760.0 else (2 if content_width < 1080.0 else 3)
	get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasFiltersCard/PerguntasFiltersMargin/PerguntasFiltersGrid").columns = 1 if content_width < 900.0 else 3
	get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaFormCard/IaFormMargin/IaFormGrid").columns = 1 if content_width < 980.0 else 2
	get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaActionsGrid").columns = 1 if content_width < 900.0 else (2 if content_width < 1280.0 else 4)
	header_actions.alignment = BoxContainer.ALIGNMENT_BEGIN if compact_content else BoxContainer.ALIGNMENT_END
	header_actions.add_theme_constant_override("separation", 8 if compact_content else 12)
	seletor_salas.custom_minimum_size = Vector2(160.0 if compact_content else 240.0, 44.0)
	botao_atualizar_salas_header.custom_minimum_size = Vector2(110.0 if compact_content else 132.0, 44.0)
	botao_sair.custom_minimum_size = Vector2(118.0 if compact_content else 154.0, 44.0)
	sidebar.size.x = 278.0 if sidebar_expanded else 94.0

func _on_sidebar_toggle_pressed() -> void:
	sidebar_expanded = not sidebar_expanded
	_apply_sidebar_styles()

func _apply_sidebar_styles() -> void:
	sidebar.custom_minimum_size.x = 278 if sidebar_expanded else 94
	sidebar.size.x = sidebar.custom_minimum_size.x
	sidebar_description.visible = sidebar_expanded
	sidebar_brand_title.visible = sidebar_expanded
	sidebar_brand_subtitle.visible = sidebar_expanded
	sidebar_footer_title.visible = sidebar_expanded
	sidebar_footer_subtitle.visible = sidebar_expanded

	var buttons := {
		VIEW_DASHBOARD: botao_dashboard,
		VIEW_ROOM: botao_gerenciar_sala_menu,
		VIEW_STUDENTS: botao_acompanhamento,
		VIEW_BANK: botao_banco_perguntas,
		VIEW_IMPORT: botao_importar_pagina,
		VIEW_AI: botao_gerar_ia_pagina,
	}

	for view_name in buttons.keys():
		var button: Button = buttons[view_name]
		var label: Label = button.get_node("Layout/Label") as Label
		var icon: TextureRect = button.get_node("Layout/Icon") as TextureRect
		label.visible = sidebar_expanded
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_apply_sidebar_button_style(button, label, icon, view_name == current_view)

	var settings_label: Label = botao_configuracoes_menu.get_node("Layout/Label") as Label
	var settings_icon: TextureRect = botao_configuracoes_menu.get_node("Layout/Icon") as TextureRect
	settings_label.visible = sidebar_expanded
	settings_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_sidebar_button_style(botao_configuracoes_menu, settings_label, settings_icon, _is_settings_overlay_open())

func _apply_sidebar_button_style(button: Button, label: Label, icon: TextureRect, active: bool) -> void:
	var background := COLOR_SIDEBAR
	var border := COLOR_SIDEBAR_BORDER
	var text_color := COLOR_SIDEBAR_MUTED
	if active:
		background = COLOR_ACCENT
		border = _shade_color(COLOR_ACCENT, 0.22)
		text_color = Color(1.0, 1.0, 1.0, 1.0)

	button.add_theme_stylebox_override("normal", _create_surface_style(background, border, 1, 18, 14, 12, 0.0))
	button.add_theme_stylebox_override("hover", _create_surface_style(_tint_color(background, 0.08), border, 1, 18, 14, 12, 0.0))
	button.add_theme_stylebox_override("pressed", _create_surface_style(_shade_color(background, 0.08), border, 1, 18, 14, 12, 0.0))
	button.add_theme_stylebox_override("focus", _create_surface_style(_tint_color(background, 0.04), border, 2, 18, 14, 12, 0.0))
	button.add_theme_stylebox_override("disabled", _create_surface_style(_tint_color(background, 0.18), _tint_color(border, 0.12), 1, 18, 14, 12, 0.0))
	button.add_theme_color_override("font_color", Color(0, 0, 0, 0))
	button.add_theme_color_override("font_hover_color", Color(0, 0, 0, 0))
	button.add_theme_color_override("font_pressed_color", Color(0, 0, 0, 0))
	if label != null:
		UITheme.apply_font_only(label, 15)
		label.add_theme_color_override("font_color", text_color)
	if icon != null:
		icon.modulate = text_color

func _on_navigation_pressed(view_name: String) -> void:
	_set_current_view(view_name)

func _set_current_view(view_name: String) -> void:
	current_view = view_name
	dashboard_page.visible = view_name == VIEW_DASHBOARD
	gerenciar_sala_page.visible = view_name == VIEW_ROOM
	acompanhamento_page.visible = view_name == VIEW_STUDENTS
	banco_page.visible = view_name == VIEW_BANK
	importar_page.visible = view_name == VIEW_IMPORT
	ia_page.visible = view_name == VIEW_AI
	content_scroll.scroll_vertical = 0
	_apply_sidebar_styles()
	_refresh_header_context()

func _refresh_header_context() -> void:
	var page_info: Dictionary = PAGE_META.get(current_view, PAGE_META[VIEW_DASHBOARD])
	page_title.text = str(page_info.get("title", "Painel do Professor"))
	page_subtitle.text = str(page_info.get("subtitle", ""))

	if ProfessorSession.has_current_room():
		var room_name := ProfessorSession.current_room_name.strip_edges()
		var room_code := ProfessorSession.current_room_code.strip_edges().to_upper()
		current_room_label.text = "%s (%s)" % [room_name if not room_name.is_empty() else "Sala ativa", room_code if not room_code.is_empty() else "--"]
		sala_atual_info.text = "Sala ativa: %s" % (room_name if not room_name.is_empty() else "Sem nome")
		sala_codigo_info.text = "Codigo: %s" % (room_code if not room_code.is_empty() else "--")
		resumo_gerenciar_sala.text = "Sala atual selecionada: %s. As acoes desta pagina afetam o contexto usado nas outras telas." % (room_name if not room_name.is_empty() else "selecionada")
		sidebar_footer_subtitle.text = "Trabalhando na sala %s." % (room_name if not room_name.is_empty() else "selecionada")
		_apply_badge_panel(current_room_badge, _tint_color(COLOR_ACCENT, 0.88), COLOR_ACCENT)
	else:
		current_room_label.text = "Sem sala ativa"
		sala_atual_info.text = "Sala ativa: nenhuma"
		sala_codigo_info.text = "Codigo: --"
		resumo_gerenciar_sala.text = "Crie uma nova sala ou selecione uma turma existente para sincronizar o restante do painel."
		sidebar_footer_subtitle.text = "Selecione uma turma no topo para sincronizar o painel."
		_apply_badge_panel(current_room_badge, _tint_color(COLOR_BORDER, 0.50), COLOR_BORDER)

func _show_status(message: String, color_value: Color) -> void:
	status_label.text = message
	status_label.add_theme_color_override("font_color", color_value)

func _set_loading_state(enabled: bool) -> void:
	carregando = enabled
	input_nome_sala.editable = not enabled
	botao_criar_sala.disabled = enabled
	botao_atualizar_salas.disabled = enabled
	botao_apagar_sala.disabled = enabled or salas.is_empty() or not ProfessorSession.has_current_room()
	botao_atualizar_salas_header.disabled = enabled
	seletor_salas.disabled = enabled or salas.is_empty()
	_update_question_bank_controls_state()
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

func _fetch_rooms(refresh_dashboard_after_load: bool) -> void:
	if carregando:
		return

	_set_loading_state(true)
	_show_status("Carregando salas do professor...", STATUS_INFO)
	var response: Dictionary = await ApiClient.fetch_rooms_by_teacher(ProfessorSession.professor_id)
	_set_loading_state(false)

	if not response.get("ok", false):
		salas.clear()
		_populate_room_selector()
		ProfessorSession.set_current_room({})
		_refresh_header_context()
		_render_empty_dashboard()
		_render_students([])
		_show_status(response.get("error", "Nao foi possivel carregar as salas."), STATUS_ERROR)
		return

	salas = _extract_dictionary_array(response.get("data", []))
	_populate_room_selector()
	if salas.is_empty():
		ProfessorSession.set_current_room({})
		_refresh_header_context()
		_render_empty_dashboard()
		_render_students([])
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
	else:
		ProfessorSession.set_current_room(salas[index])
	_refresh_header_context()

func _on_seletor_salas_item_selected(index: int) -> void:
	if carregando or index < 0 or index >= salas.size():
		return
	_apply_selected_room(index)
	await _refresh_dashboard()

func _on_botao_atualizar_salas_pressed() -> void:
	await _fetch_rooms(true)

func _on_botao_criar_sala_pressed() -> void:
	if carregando:
		return
	var nome_sala := input_nome_sala.text.strip_edges()
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

func _on_botao_apagar_sala_pressed() -> void:
	if carregando or not ProfessorSession.has_current_room():
		return
	var room_name := ProfessorSession.current_room_name.strip_edges()
	var room_code := ProfessorSession.current_room_code.strip_edges().to_upper()
	confirmacao_apagar_sala.dialog_text = "Tem certeza que deseja apagar a sala %s%s e todos os dados vinculados a ela?" % [
		room_name if not room_name.is_empty() else "selecionada",
		" (%s)" % room_code if not room_code.is_empty() else "",
	]
	confirmacao_apagar_sala.popup_centered()

func _on_confirmacao_apagar_sala_confirmed() -> void:
	if carregando or not ProfessorSession.has_current_room():
		return

	_set_loading_state(true)
	_show_status("Apagando a sala e os dados vinculados...", STATUS_INFO)
	var response: Dictionary = await ApiClient.delete_room(ProfessorSession.current_room_id)
	_set_loading_state(false)

	if not response.get("ok", false):
		_show_status(response.get("error", "Nao foi possivel apagar a sala."), STATUS_ERROR)
		return

	ProfessorSession.set_current_room({})
	respostas_sala.clear()
	dashboard_payload.clear()
	_render_empty_dashboard()
	_render_students([])
	_show_status(response.get("data", {}).get("mensagem", "Sala apagada com sucesso."), STATUS_OK)
	await _fetch_rooms(true)

func _refresh_dashboard() -> void:
	if carregando:
		return

	if not ProfessorSession.has_current_room():
		_render_empty_dashboard()
		_render_students([])
		return

	_set_loading_state(true)
	_show_status("Atualizando indicadores da sala...", STATUS_INFO)
	var dashboard_response: Dictionary = await ApiClient.fetch_room_dashboard(ProfessorSession.current_room_id)
	var answers_response: Dictionary = await ApiClient.fetch_room_answers(ProfessorSession.current_room_id)
	_set_loading_state(false)

	if not dashboard_response.get("ok", false):
		_render_empty_dashboard()
		_render_students([])
		_show_status(dashboard_response.get("error", "Nao foi possivel carregar o dashboard."), STATUS_ERROR)
		return

	dashboard_payload = dashboard_response.get("data", {})
	if answers_response.get("ok", false):
		respostas_sala = _normalize_answer_list(answers_response.get("data", {}).get("respostas", []))
	else:
		respostas_sala.clear()
		_show_status(answers_response.get("error", "Nao foi possivel carregar as respostas da sala."), STATUS_WARNING)

	_render_dashboard_data(dashboard_payload)
	_render_students(_build_student_models(respostas_sala))
	_show_status("Dashboard atualizado.", STATUS_OK)

func _render_empty_dashboard() -> void:
	dashboard_payload.clear()
	dashboard_hero_title.text = "Visao geral da sala"
	dashboard_hero_description.text = "Selecione uma sala para visualizar indicadores, atividades recentes e o andamento da turma. Se precisar criar ou apagar salas, use a pagina Gerenciar Sala."
	_render_metric_cards([
		{"title": "Total de alunos", "value": "0", "subtitle": "Aguardando respostas vinculadas a uma sala.", "accent": COLOR_ACCENT, "icon": "A"},
		{"title": "Perguntas cadastradas", "value": str(banco_perguntas.size()), "subtitle": "Banco oficial disponivel para a turma.", "accent": STATUS_INFO, "icon": "P"},
		{"title": "Media de acertos", "value": "0%", "subtitle": "Sem historico suficiente para calcular.", "accent": STATUS_OK, "icon": "M"},
		{"title": "Respostas realizadas", "value": "0", "subtitle": "Nenhuma atividade concluida ainda.", "accent": STATUS_WARNING, "icon": "R"},
		{"title": "Alunos em andamento", "value": "0", "subtitle": "Aguardando inicio das partidas.", "accent": COLOR_ACCENT, "icon": "E"},
		{"title": "Alunos finalizados", "value": "0", "subtitle": "O backend ainda nao enviou finalizacoes.", "accent": STATUS_OK, "icon": "F"},
	])
	_render_group_summary_list(lista_materias_dashboard, [], "materia", "Nenhum dado por materia disponivel ainda.")
	_render_group_summary_list(lista_dificuldades_dashboard, [], "dificuldade", "Nenhum dado por dificuldade disponivel ainda.")
	_render_recent_activity([])
	_refresh_header_context()

func _render_dashboard_data(payload: Dictionary) -> void:
	var indicadores: Dictionary = payload.get("indicadores", {})
	var student_models: Array[Dictionary] = _build_student_models(respostas_sala)
	var states: Dictionary = _summarize_student_states(student_models)
	var total_alunos: int = int(indicadores.get("totalAlunos", 0))
	var total_respostas: int = int(indicadores.get("totalPerguntasRespondidas", 0))
	var room_name := ProfessorSession.current_room_name.strip_edges()

	dashboard_hero_title.text = "Visao geral da sala %s" % (room_name if not room_name.is_empty() else "selecionada")
	if total_respostas <= 0:
		dashboard_hero_description.text = "A estrutura da sala ja esta pronta. Assim que a turma responder perguntas, este dashboard mostrara medias, distribuicoes e atividade recente."
	else:
		dashboard_hero_description.text = "%d alunos ja registraram %d respostas. Use os cards abaixo para identificar oportunidades de reforco e acompanhar a participacao da turma." % [total_alunos, total_respostas]

	_render_metric_cards([
		{"title": "Total de alunos", "value": str(total_alunos), "subtitle": "Participantes com respostas registradas na sala.", "accent": COLOR_ACCENT, "icon": "A"},
		{"title": "Perguntas cadastradas", "value": str(banco_perguntas.size()), "subtitle": "Itens disponiveis hoje no banco oficial.", "accent": STATUS_INFO, "icon": "P"},
		{"title": "Media de acertos", "value": "%d%%" % int(indicadores.get("percentualAcertoTurma", 0)), "subtitle": "%d acertos e %d erros no agregado." % [int(indicadores.get("quantidadeAcertos", 0)), int(indicadores.get("quantidadeErros", 0))], "accent": STATUS_OK, "icon": "M"},
		{"title": "Respostas realizadas", "value": str(total_respostas), "subtitle": "Historico usado para acompanhar a sala.", "accent": STATUS_WARNING, "icon": "R"},
		{"title": "Alunos em andamento", "value": str(int(states.get("jogando", 0))), "subtitle": "Em progresso com base no historico atual.", "accent": COLOR_ACCENT, "icon": "E"},
		{"title": "Alunos finalizados", "value": str(int(states.get("finalizado", 0))), "subtitle": "Estimativa provisoria ate existir status explicito no backend.", "accent": STATUS_OK, "icon": "F"},
	])

	_render_group_summary_list(lista_materias_dashboard, payload.get("desempenhoPorMateria", []), "materia", "Nenhum dado por materia disponivel ainda.")
	_render_group_summary_list(lista_dificuldades_dashboard, payload.get("desempenhoPorDificuldade", []), "dificuldade", "Nenhum dado por dificuldade disponivel ainda.")
	_render_recent_activity(respostas_sala)
	_refresh_header_context()

func _render_metric_cards(metrics: Array[Dictionary]) -> void:
	_clear_container(metrics_grid)
	for item in metrics:
		var card: PanelContainer = MetricCardScene.instantiate() as PanelContainer
		_apply_surface_panel(card, COLOR_SURFACE_ALT, COLOR_BORDER, 22, 0.05)
		var accent: Color = item.get("accent", COLOR_ACCENT)
		var accent_badge: PanelContainer = card.get_node("Margin/VBox/TopRow/AccentBadge") as PanelContainer
		var accent_label: Label = card.get_node("Margin/VBox/TopRow/AccentBadge/AccentLabel") as Label
		var title_label: Label = card.get_node("Margin/VBox/TopRow/TitleLabel") as Label
		var value_label: Label = card.get_node("Margin/VBox/ValueLabel") as Label
		var subtitle_label: Label = card.get_node("Margin/VBox/SubtitleLabel") as Label

		_apply_surface_panel(accent_badge, _tint_color(accent, 0.88), accent, 999, 0.0)
		UITheme.apply_font_only(accent_label, 16)
		accent_label.text = str(item.get("icon", "I"))
		accent_label.add_theme_color_override("font_color", accent)
		UITheme.apply_font_only(title_label, 16)
		title_label.text = str(item.get("title", "Indicador"))
		title_label.add_theme_color_override("font_color", COLOR_TEXT)
		UITheme.apply_font_only(value_label, 32)
		value_label.text = str(item.get("value", "0"))
		value_label.add_theme_color_override("font_color", accent)
		UITheme.apply_font_only(subtitle_label, 14)
		subtitle_label.text = str(item.get("subtitle", ""))
		subtitle_label.add_theme_color_override("font_color", COLOR_MUTED)
		metrics_grid.add_child(card)

func _render_group_summary_list(container: VBoxContainer, groups: Variant, key_name: String, empty_message: String) -> void:
	_clear_container(container)
	if groups is not Array or groups.is_empty():
		container.add_child(_create_empty_state_panel("Sem dados ainda", empty_message))
		return

	for item in groups:
		if item is not Dictionary:
			continue
		container.add_child(_create_group_summary_row(item, key_name))

func _create_group_summary_row(item: Dictionary, key_name: String) -> PanelContainer:
	var row := PanelContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_surface_panel(row, COLOR_SURFACE_ALT, COLOR_BORDER, 18, 0.03)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	row.add_child(content)

	var title := Label.new()
	title.text = str(item.get(key_name, "Sem nome"))
	UITheme.apply_font_only(title, 16)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	content.add_child(title)

	var detail := Label.new()
	detail.text = "%d resp. | %d acertos | %d erros | %d%%" % [
		int(item.get("respondidas", 0)),
		int(item.get("acertos", 0)),
		int(item.get("erros", 0)),
		int(item.get("percentualAcerto", 0)),
	]
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.apply_font_only(detail, 14)
	detail.add_theme_color_override("font_color", COLOR_MUTED)
	content.add_child(detail)
	return row

func _render_recent_activity(respostas: Array[Dictionary]) -> void:
	_clear_container(lista_atividades)
	if respostas.is_empty():
		lista_atividades.add_child(_create_empty_state_panel("Sem atividades recentes", "As respostas mais recentes da sala aparecerao aqui assim que os alunos jogarem."))
		return

	var limit: int = min(5, respostas.size())
	for index in range(limit):
		var resposta: Dictionary = respostas[index]
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_apply_surface_panel(panel, COLOR_SURFACE_ALT, COLOR_BORDER, 18, 0.03)
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 4)
		panel.add_child(box)

		var title := Label.new()
		title.text = "%s respondeu %s" % [
			str(resposta.get("aluno", "Aluno")),
			"corretamente" if bool(resposta.get("acertou", false)) else "incorretamente",
		]
		UITheme.apply_font_only(title, 15)
		title.add_theme_color_override("font_color", COLOR_TEXT)
		box.add_child(title)

		var detail := Label.new()
		detail.text = "%s | %s | Fase %d | %s" % [
			str(resposta.get("materia", "Sem materia")),
			str(resposta.get("dificuldade", "Sem dificuldade")),
			int(resposta.get("fase", 0)),
			_format_datetime(resposta.get("respondidoEm", "")),
		]
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UITheme.apply_font_only(detail, 13)
		detail.add_theme_color_override("font_color", COLOR_MUTED)
		box.add_child(detail)
		lista_atividades.add_child(panel)

func _render_students(models: Array[Dictionary]) -> void:
	_clear_container(acompanhamento_grid)
	if models.is_empty():
		resumo_acompanhamento.text = "Nenhum aluno apareceu no acompanhamento ainda."
		resumo_acompanhamento.add_theme_color_override("font_color", COLOR_MUTED)
		acompanhamento_grid.add_child(_create_empty_state_panel("Acompanhamento aguardando atividade", "Assim que a turma responder perguntas, esta pagina mostrara status, pontuacao, progresso e ultima atividade por aluno."))
		return

	resumo_acompanhamento.text = "%d alunos com historico de respostas. O status atual usa o progresso registrado da sala e uma estimativa provisoria de finalizacao." % models.size()
	resumo_acompanhamento.add_theme_color_override("font_color", COLOR_TEXT)
	for item in models:
		acompanhamento_grid.add_child(_create_student_card(item))

func _create_student_card(item: Dictionary) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_surface_panel(panel, COLOR_SURFACE_ALT, COLOR_BORDER, 22, 0.05)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	box.add_child(top)

	var name_label := Label.new()
	name_label.text = str(item.get("nome", "Aluno"))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UITheme.apply_font_only(name_label, 18)
	name_label.add_theme_color_override("font_color", COLOR_TEXT)
	top.add_child(name_label)

	var status_badge := _create_inline_badge(
		str(item.get("status", "aguardando")).capitalize(),
		_tint_color(_get_student_status_color(str(item.get("status", ""))), 0.86),
		_get_student_status_color(str(item.get("status", ""))),
		_shade_color(_get_student_status_color(str(item.get("status", ""))), 0.22)
	)
	top.add_child(status_badge)

	var meta_row := HFlowContainer.new()
	meta_row.add_theme_constant_override("h_separation", 8)
	meta_row.add_theme_constant_override("v_separation", 8)
	box.add_child(meta_row)
	meta_row.add_child(_create_inline_badge("Pontuacao: %d" % int(item.get("pontuacao", 0)), _tint_color(COLOR_ACCENT, 0.90), COLOR_ACCENT))
	meta_row.add_child(_create_inline_badge("Acertos: %d" % int(item.get("acertos", 0)), _tint_color(STATUS_OK, 0.90), STATUS_OK))
	meta_row.add_child(_create_inline_badge("Incorretas: %d" % int(item.get("erros", 0)), _tint_color(STATUS_ERROR, 0.90), STATUS_ERROR))
	meta_row.add_child(_create_inline_badge("Progresso: %s" % str(item.get("progressoLabel", "Fase 0/10")), _tint_color(STATUS_INFO, 0.90), STATUS_INFO))

	var bottom := Label.new()
	bottom.text = "Ultima atividade: %s | Aproveitamento: %d%%" % [
		str(item.get("ultimaAtividade", "Sem registro")),
		int(item.get("aproveitamento", 0)),
	]
	bottom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.apply_font_only(bottom, 14)
	bottom.add_theme_color_override("font_color", COLOR_MUTED)
	box.add_child(bottom)
	return panel

func _build_student_models(respostas: Array[Dictionary]) -> Array[Dictionary]:
	var grouped := {}
	for resposta in respostas:
		var jogador_id: int = int(resposta.get("jogadorId", 0))
		if not grouped.has(jogador_id):
			grouped[jogador_id] = {
				"jogadorId": jogador_id,
				"nome": str(resposta.get("aluno", "Aluno")),
				"pontuacao": 0,
				"acertos": 0,
				"erros": 0,
				"respostas": 0,
				"maxFase": 0,
				"ultimaRespostaRaw": "",
			}

		var row: Dictionary = grouped[jogador_id]
		row["pontuacao"] = int(row.get("pontuacao", 0)) + int(resposta.get("pontuacaoGanha", 0))
		row["acertos"] = int(row.get("acertos", 0)) + (1 if bool(resposta.get("acertou", false)) else 0)
		row["erros"] = int(row.get("erros", 0)) + (0 if bool(resposta.get("acertou", false)) else 1)
		row["respostas"] = int(row.get("respostas", 0)) + 1
		row["maxFase"] = max(int(row.get("maxFase", 0)), int(resposta.get("fase", 0)))
		if str(row.get("ultimaRespostaRaw", "")).is_empty():
			row["ultimaRespostaRaw"] = resposta.get("respondidoEm", "")
		grouped[jogador_id] = row

	var students: Array[Dictionary] = []
	for item in grouped.values():
		var respostas_total: int = int(item.get("respostas", 0))
		var acertos_total: int = int(item.get("acertos", 0))
		var fase_atual: int = int(item.get("maxFase", 0))
		var aproveitamento := 0 if respostas_total == 0 else int(round((float(acertos_total) / float(respostas_total)) * 100.0))
		var status := "aguardando"
		if respostas_total > 0:
			status = "finalizado" if fase_atual >= STUDENT_FINAL_PHASE_ESTIMATE or respostas_total >= STUDENT_FINAL_PHASE_ESTIMATE else "jogando"
		item["aproveitamento"] = aproveitamento
		item["status"] = status
		item["progressoLabel"] = "Fase %d/%d" % [fase_atual, STUDENT_FINAL_PHASE_ESTIMATE]
		item["ultimaAtividade"] = _format_datetime(item.get("ultimaRespostaRaw", ""))
		students.append(item)

	students.sort_custom(func(a, b):
		if int(a.get("pontuacao", 0)) == int(b.get("pontuacao", 0)):
			return str(a.get("nome", "")) < str(b.get("nome", ""))
		return int(a.get("pontuacao", 0)) > int(b.get("pontuacao", 0))
	)
	return students

func _summarize_student_states(models: Array[Dictionary]) -> Dictionary:
	var summary := {
		"aguardando": 0,
		"jogando": 0,
		"finalizado": 0,
	}
	for item in models:
		var status: String = str(item.get("status", "aguardando"))
		if summary.has(status):
			summary[status] = int(summary[status]) + 1
	return summary

func _normalize_answer_list(payload: Variant) -> Array[Dictionary]:
	return _extract_dictionary_array(payload)

func _refresh_question_bank() -> void:
	if carregando_banco_perguntas:
		return

	carregando_banco_perguntas = true
	_update_question_bank_controls_state()
	_set_question_bank_feedback("Atualizando o banco oficial de perguntas...", STATUS_INFO)
	var response: Dictionary = await ApiClient.fetch_questions()
	carregando_banco_perguntas = false
	_update_question_bank_controls_state()

	if not response.get("ok", false):
		banco_perguntas.clear()
		_render_question_bank()
		_set_question_bank_feedback(response.get("error", "Nao foi possivel carregar o banco de perguntas."), STATUS_ERROR)
		return

	banco_perguntas = _normalize_questions(response.get("data", []))
	_populate_question_filters()
	_render_question_bank()
	if dashboard_payload.is_empty():
		_render_empty_dashboard()
	else:
		_render_dashboard_data(dashboard_payload)

func _normalize_questions(raw_questions: Variant) -> Array[Dictionary]:
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

func _populate_question_filters() -> void:
	var selected_materia := _get_selected_option_metadata(filtro_materia_perguntas)
	var selected_dificuldade := _get_selected_option_metadata(filtro_dificuldade_perguntas)

	var materias := {}
	var dificuldades := {}
	for question in banco_perguntas:
		var materia := str(question.get("materia", "")).strip_edges()
		var dificuldade := str(question.get("dificuldade", "")).strip_edges()
		if not materia.is_empty():
			materias[materia] = true
		if not dificuldade.is_empty():
			dificuldades[dificuldade] = true

	_populate_filter_option_button(filtro_materia_perguntas, "Todas as materias", materias.keys(), selected_materia)
	_populate_filter_option_button(filtro_dificuldade_perguntas, "Todas as dificuldades", dificuldades.keys(), selected_dificuldade)

func _populate_filter_option_button(option_button: OptionButton, default_label: String, values: Array, selected_value: String) -> void:
	option_button.clear()
	option_button.add_item(default_label)
	option_button.set_item_metadata(0, "")
	var sorted_values: Array = values.duplicate()
	sorted_values.sort()
	for value in sorted_values:
		option_button.add_item(str(value))
		option_button.set_item_metadata(option_button.item_count - 1, str(value))
	_select_option_button_by_metadata(option_button, selected_value)

func _select_option_button_by_metadata(option_button: OptionButton, expected: String) -> void:
	for index in range(option_button.item_count):
		if str(option_button.get_item_metadata(index)) == expected:
			option_button.select(index)
			return
	option_button.select(0)

func _get_selected_option_metadata(option_button: OptionButton) -> String:
	if option_button.item_count == 0:
		return ""
	var selected := option_button.selected
	if selected < 0 or selected >= option_button.item_count:
		return ""
	return str(option_button.get_item_metadata(selected))

func _on_question_filter_changed(_unused: Variant = null) -> void:
	_render_question_bank()

func _get_filtered_question_entries() -> Array[Dictionary]:
	var filtered: Array[Dictionary] = []
	var search_term := input_busca_perguntas.text.strip_edges().to_lower()
	var materia_filter := _get_selected_option_metadata(filtro_materia_perguntas)
	var dificuldade_filter := _get_selected_option_metadata(filtro_dificuldade_perguntas)

	for index in range(banco_perguntas.size()):
		var question: Dictionary = banco_perguntas[index]
		var composite := "%s %s %s" % [
			str(question.get("titulo", "")),
			str(question.get("enunciado", "")),
			str(question.get("materia", "")),
		]
		if not search_term.is_empty() and composite.to_lower().find(search_term) == -1:
			continue
		if not materia_filter.is_empty() and str(question.get("materia", "")) != materia_filter:
			continue
		if not dificuldade_filter.is_empty() and str(question.get("dificuldade", "")) != dificuldade_filter:
			continue
		filtered.append({
			"index": index,
			"question": question,
		})
	return filtered

func _render_question_bank() -> void:
	_clear_container(lista_banco_perguntas)
	_update_question_count_badge()
	var entries: Array[Dictionary] = _get_filtered_question_entries()

	if banco_perguntas.is_empty():
		_set_question_bank_feedback("Nenhuma pergunta salva no banco ainda.", COLOR_MUTED)
		lista_banco_perguntas.add_child(_create_empty_state_panel("Banco vazio", "Importe uma planilha ou aprove perguntas geradas pela IA para comecar a montar seu banco oficial."))
		return

	if entries.is_empty():
		_set_question_bank_feedback("Nenhuma pergunta combina com os filtros aplicados.", STATUS_WARNING)
		lista_banco_perguntas.add_child(_create_empty_state_panel("Sem resultados", "Tente limpar a busca ou ajustar os filtros de materia e dificuldade."))
		return

	_set_question_bank_feedback("%d perguntas visiveis para revisao." % entries.size(), COLOR_TEXT)
	for entry in entries:
		lista_banco_perguntas.add_child(_create_bank_question_card(entry))

func _create_bank_question_card(entry: Dictionary) -> PanelContainer:
	var index: int = int(entry.get("index", -1))
	var question: Dictionary = entry.get("question", {})
	var card: PanelContainer = QuestionCardScene.instantiate() as PanelContainer
	_apply_surface_panel(card, COLOR_SURFACE_ALT, COLOR_BORDER, 22, 0.05)

	var title_label: Label = card.get_node("Margin/Content/HeaderRow/HeaderText/TitleLabel") as Label
	var summary_label: Label = card.get_node("Margin/Content/HeaderRow/HeaderText/SummaryLabel") as Label
	var toggle_button: Button = card.get_node("Margin/Content/HeaderRow/ToggleExpandButton") as Button
	var badge_row: HFlowContainer = card.get_node("Margin/Content/BadgeRow") as HFlowContainer
	var detail_container: VBoxContainer = card.get_node("Margin/Content/DetailContainer") as VBoxContainer
	var action_row: HBoxContainer = card.get_node("Margin/Content/ActionRow") as HBoxContainer

	title_label.text = _question_title(question)
	summary_label.text = _truncate_text(str(question.get("enunciado", "")), 180)
	UITheme.apply_font_only(title_label, 18)
	title_label.add_theme_color_override("font_color", COLOR_TEXT)
	UITheme.apply_font_only(summary_label, 14)
	summary_label.add_theme_color_override("font_color", COLOR_MUTED)

	_clear_container(badge_row)
	badge_row.add_child(_create_inline_badge("Materia: %s" % str(question.get("materia", "Sem materia")), _tint_color(STATUS_INFO, 0.90), STATUS_INFO))
	badge_row.add_child(_create_inline_badge("Dificuldade: %s" % str(question.get("dificuldade", "Facil")), _tint_color(STATUS_WARNING, 0.90), STATUS_WARNING))
	badge_row.add_child(_create_inline_badge("Pontuacao: %d" % int(question.get("pontuacao", 100)), _tint_color(STATUS_OK, 0.90), STATUS_OK))
	if int(question.get("tempoLimite", 0)) > 0:
		badge_row.add_child(_create_inline_badge("Tempo: %ds" % int(question.get("tempoLimite", 0)), _tint_color(COLOR_ACCENT, 0.90), COLOR_ACCENT))

	_clear_container(detail_container)
	detail_container.add_child(_create_labeled_line_edit("Titulo", str(question.get("titulo", "")), _on_bank_question_text_changed.bind(index, "titulo")))
	detail_container.add_child(_create_labeled_text_edit("Enunciado", str(question.get("enunciado", "")), _on_bank_question_text_edit_changed.bind(index, "enunciado")))
	detail_container.add_child(_create_labeled_line_edit("Alternativa A", str(question.get("alternativaA", "")), _on_bank_question_text_changed.bind(index, "alternativaA")))
	detail_container.add_child(_create_labeled_line_edit("Alternativa B", str(question.get("alternativaB", "")), _on_bank_question_text_changed.bind(index, "alternativaB")))
	detail_container.add_child(_create_labeled_line_edit("Alternativa C", str(question.get("alternativaC", "")), _on_bank_question_text_changed.bind(index, "alternativaC")))
	detail_container.add_child(_create_labeled_line_edit("Alternativa D", str(question.get("alternativaD", "")), _on_bank_question_text_changed.bind(index, "alternativaD")))

	var meta_grid := GridContainer.new()
	meta_grid.columns = 2
	meta_grid.add_theme_constant_override("h_separation", 10)
	meta_grid.add_theme_constant_override("v_separation", 10)
	meta_grid.add_child(_create_labeled_line_edit("Materia", str(question.get("materia", "")), _on_bank_question_text_changed.bind(index, "materia")))
	meta_grid.add_child(_create_labeled_line_edit("Dificuldade", str(question.get("dificuldade", "")), _on_bank_question_text_changed.bind(index, "dificuldade")))
	meta_grid.add_child(_create_labeled_option_button("Resposta correta", QUESTION_CORRECT_OPTIONS, str(question.get("respostaCorreta", "A")), _on_bank_question_option_selected.bind(index, "respostaCorreta")))
	meta_grid.add_child(_create_labeled_spin_box("Pontuacao", int(question.get("pontuacao", 100)), 1, 10000, _on_bank_question_number_changed.bind(index, "pontuacao")))
	meta_grid.add_child(_create_labeled_spin_box("Tempo limite", int(question.get("tempoLimite", 0)), 0, 3600, _on_bank_question_number_changed.bind(index, "tempoLimite")))
	detail_container.add_child(meta_grid)

	_clear_container(action_row)
	var save_button := Button.new()
	save_button.text = "Salvar Alteracoes"
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_palette(save_button, STATUS_OK, _shade_color(STATUS_OK, 0.22))
	save_button.pressed.connect(_on_bank_question_save_pressed.bind(index))
	action_row.add_child(save_button)

	var delete_button := Button.new()
	delete_button.text = "Excluir"
	delete_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_palette(delete_button, STATUS_ERROR, _shade_color(STATUS_ERROR, 0.22))
	delete_button.pressed.connect(_on_bank_question_delete_pressed.bind(index))
	action_row.add_child(delete_button)

	var question_id: int = int(question.get("id", index))
	var expanded := expanded_bank_question_ids.has(question_id)
	_set_question_card_expanded(detail_container, action_row, toggle_button, expanded)
	toggle_button.pressed.connect(_on_bank_card_toggle_pressed.bind(question_id))
	return card

func _on_bank_card_toggle_pressed(question_id: int) -> void:
	if expanded_bank_question_ids.has(question_id):
		expanded_bank_question_ids.erase(question_id)
	else:
		expanded_bank_question_ids[question_id] = true
	_render_question_bank()

func _on_botao_expandir_todas_pressed() -> void:
	expanded_bank_question_ids.clear()
	for question in banco_perguntas:
		expanded_bank_question_ids[int(question.get("id", 0))] = true
	_render_question_bank()

func _on_botao_recolher_todas_pressed() -> void:
	expanded_bank_question_ids.clear()
	_render_question_bank()

func _set_question_card_expanded(detail_container: VBoxContainer, action_row: HBoxContainer, toggle_button: Button, expanded: bool) -> void:
	detail_container.visible = expanded
	action_row.visible = expanded
	toggle_button.text = "Recolher" if expanded else "Expandir"
	_apply_button_palette(toggle_button, COLOR_SURFACE, COLOR_BORDER, COLOR_TEXT)

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
	var validation_error := _validate_question_payload(question, index + 1)
	if not validation_error.is_empty():
		_set_question_bank_feedback(validation_error, STATUS_ERROR)
		return

	carregando_banco_perguntas = true
	_update_question_bank_controls_state()
	_set_question_bank_feedback("Salvando alteracoes de %s..." % _question_title(question), STATUS_INFO)
	var response: Dictionary = await ApiClient.update_question(int(question.get("id", 0)), _build_question_payload(question))
	carregando_banco_perguntas = false
	_update_question_bank_controls_state()

	if not response.get("ok", false):
		_set_question_bank_feedback(response.get("error", "Nao foi possivel salvar a pergunta."), STATUS_ERROR)
		return

	_set_question_bank_feedback("%s atualizada com sucesso." % _question_title(question), STATUS_OK)
	await _refresh_question_bank()

func _on_bank_question_delete_pressed(index: int) -> void:
	if carregando_banco_perguntas or not _has_bank_question(index):
		return
	var question_id: int = int(banco_perguntas[index].get("id", 0))
	carregando_banco_perguntas = true
	_update_question_bank_controls_state()
	_set_question_bank_feedback("Excluindo a pergunta #%d..." % question_id, STATUS_INFO)
	var response: Dictionary = await ApiClient.delete_question(question_id)
	carregando_banco_perguntas = false
	_update_question_bank_controls_state()

	if not response.get("ok", false):
		_set_question_bank_feedback(response.get("error", "Nao foi possivel excluir a pergunta."), STATUS_ERROR)
		return

	expanded_bank_question_ids.erase(question_id)
	_set_question_bank_feedback("Pergunta #%d excluida com sucesso." % question_id, STATUS_OK)
	await _refresh_question_bank()

func _has_bank_question(index: int) -> bool:
	return index >= 0 and index < banco_perguntas.size()

func _build_question_payload(question: Dictionary) -> Dictionary:
	var payload: Dictionary = question.duplicate(true)
	payload.erase("id")
	if str(payload.get("titulo", "")).strip_edges().is_empty():
		payload.erase("titulo")
	if int(payload.get("tempoLimite", 0)) <= 0:
		payload.erase("tempoLimite")
	return payload

func _validate_question_payload(question: Dictionary, display_index: int) -> String:
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
			return "A pergunta %d precisa preencher o campo %s antes de salvar." % [display_index, field_name]

	var resposta_correta := str(question.get("respostaCorreta", "")).strip_edges().to_upper()
	if not QUESTION_CORRECT_OPTIONS.has(resposta_correta):
		return "A pergunta %d precisa ter uma resposta correta entre A, B, C ou D." % display_index
	if int(question.get("pontuacao", 0)) <= 0:
		return "A pergunta %d precisa ter pontuacao maior que zero." % display_index
	if int(question.get("tempoLimite", 0)) < 0:
		return "A pergunta %d possui tempo limite invalido." % display_index
	return ""

func _update_question_bank_controls_state() -> void:
	botao_atualizar_perguntas.disabled = carregando or carregando_banco_perguntas or importando_perguntas
	botao_atualizar_perguntas.text = "Atualizando..." if carregando_banco_perguntas else "Atualizar Banco"
	botao_expandir_todas.disabled = banco_perguntas.is_empty()
	botao_recolher_todas.disabled = banco_perguntas.is_empty()
	botao_importar.disabled = carregando or carregando_banco_perguntas or importando_perguntas
	botao_importar.text = "Importando..." if importando_perguntas else "Selecionar Planilha"

func _update_question_count_badge() -> void:
	if carregando_banco_perguntas:
		contador_banco_perguntas.text = "Atualizando..."
		return
	var visible_count := _get_filtered_question_entries().size()
	contador_banco_perguntas.text = "%d de %d perguntas" % [visible_count, banco_perguntas.size()]

func _set_question_bank_feedback(message: String, color_value: Color) -> void:
	resumo_banco_perguntas.text = message
	resumo_banco_perguntas.add_theme_color_override("font_color", color_value)
	_update_question_count_badge()

func _on_botao_atualizar_banco_perguntas_pressed() -> void:
	await _refresh_question_bank()

func _on_botao_importar_pressed() -> void:
	if carregando or importando_perguntas or import_dialog == null:
		return
	_set_import_feedback("Selecione uma planilha .csv ou .xlsx para importar perguntas.", STATUS_INFO)
	import_dialog.popup_centered_ratio(0.72)

func _on_import_file_selected(path: String) -> void:
	if importando_perguntas:
		return

	importando_perguntas = true
	_update_question_bank_controls_state()
	_update_ia_controls_state()
	_set_import_feedback("Importando perguntas para o banco de dados...", STATUS_INFO)
	_show_status("Importando perguntas para o banco de dados...", STATUS_INFO)
	var response: Dictionary = await ApiClient.import_questions_spreadsheet(path)
	importando_perguntas = false
	_update_question_bank_controls_state()
	_update_ia_controls_state()

	if not response.get("ok", false):
		_set_import_feedback(response.get("error", "Nao foi possivel importar a planilha."), STATUS_ERROR)
		_show_status(response.get("error", "Nao foi possivel importar a planilha."), STATUS_ERROR)
		return

	var payload: Dictionary = response.get("data", {})
	var imported_count: int = int(payload.get("total", 0))
	_set_import_feedback("%d perguntas importadas com sucesso." % imported_count, STATUS_OK)
	_show_status("%d perguntas importadas com sucesso." % imported_count, STATUS_OK)
	await _refresh_question_bank()

func _set_import_feedback(message: String, color_value: Color) -> void:
	importar_feedback.text = message
	importar_feedback.add_theme_color_override("font_color", color_value)

func _on_botao_gerar_ia_pressed() -> void:
	if ia_processando or ia_salvando or carregando:
		return

	var tema := ia_tema_input.text.strip_edges()
	var materia := ia_materia_input.text.strip_edges()
	var dificuldade := ia_dificuldade_select.get_item_text(ia_dificuldade_select.selected).strip_edges()
	var quantidade := int(ia_quantidade_input.value)
	var pontuacao := int(ia_pontuacao_input.value)
	var tempo_limite := int(ia_tempo_input.value)

	if tema.is_empty():
		_show_ia_feedback("Informe um tema para gerar perguntas.", STATUS_ERROR)
		return
	if materia.is_empty():
		_show_ia_feedback("Informe uma materia para gerar perguntas.", STATUS_ERROR)
		return
	if dificuldade.is_empty():
		_show_ia_feedback("Selecione uma dificuldade para a geracao.", STATUS_ERROR)
		return

	ia_processando = true
	_update_ia_controls_state()
	_show_ia_feedback("Gerando perguntas com IA. Aguarde alguns instantes...", STATUS_INFO)
	_show_status("Gerando perguntas com IA para auditoria...", STATUS_INFO)

	var response: Dictionary = await ApiClient.generate_questions_ai(tema, materia, dificuldade, quantidade, pontuacao, tempo_limite)
	ia_processando = false
	_update_ia_controls_state()

	if not response.get("ok", false):
		_show_ia_feedback(response.get("error", "Nao foi possivel gerar perguntas com IA."), STATUS_ERROR)
		_show_status(response.get("error", "Nao foi possivel gerar perguntas com IA."), STATUS_ERROR)
		return

	var payload: Dictionary = response.get("data", {})
	perguntas_geradas = _normalize_generated_questions(payload.get("perguntas", []))
	expanded_generated_question_ids.clear()
	_render_generated_questions()
	_show_ia_feedback("%d perguntas foram geradas e estao prontas para revisao." % perguntas_geradas.size(), STATUS_OK)
	_show_status("Perguntas geradas com IA. Revise, aprove ou rejeite cada item.", STATUS_OK)

func _normalize_generated_questions(raw_questions: Variant) -> Array[Dictionary]:
	var normalized: Array[Dictionary] = []
	if raw_questions is not Array:
		return normalized
	for item in raw_questions:
		if item is not Dictionary:
			continue
		var question: Dictionary = item
		normalized.append({
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
		})
	return normalized

func _render_generated_questions() -> void:
	_clear_container(ia_lista)
	if perguntas_geradas.is_empty():
		ia_lista.add_child(_create_empty_state_panel("Nenhuma previa gerada", "Depois de preencher o formulario e gerar perguntas, elas aparecerao aqui em cards expansivos para revisao."))
		_update_ia_summary()
		return

	for index in range(perguntas_geradas.size()):
		ia_lista.add_child(_create_generated_question_card(index, perguntas_geradas[index]))
	_update_ia_summary()

func _create_generated_question_card(index: int, question: Dictionary) -> PanelContainer:
	var card: PanelContainer = QuestionCardScene.instantiate() as PanelContainer
	var status: String = str(question.get("statusAuditoria", IA_STATUS_PENDING))
	_apply_surface_panel(card, _status_surface_color(status), _status_color(status), 22, 0.05)

	var title_label: Label = card.get_node("Margin/Content/HeaderRow/HeaderText/TitleLabel") as Label
	var summary_label: Label = card.get_node("Margin/Content/HeaderRow/HeaderText/SummaryLabel") as Label
	var toggle_button: Button = card.get_node("Margin/Content/HeaderRow/ToggleExpandButton") as Button
	var badge_row: HFlowContainer = card.get_node("Margin/Content/BadgeRow") as HFlowContainer
	var detail_container: VBoxContainer = card.get_node("Margin/Content/DetailContainer") as VBoxContainer
	var action_row: HBoxContainer = card.get_node("Margin/Content/ActionRow") as HBoxContainer

	title_label.text = "Pergunta %d" % (index + 1)
	summary_label.text = _truncate_text(str(question.get("enunciado", "")), 180)
	UITheme.apply_font_only(title_label, 18)
	title_label.add_theme_color_override("font_color", COLOR_TEXT)
	UITheme.apply_font_only(summary_label, 14)
	summary_label.add_theme_color_override("font_color", COLOR_MUTED)

	_clear_container(badge_row)
	badge_row.add_child(_create_inline_badge("Status: %s" % _get_ia_status_label(status), _tint_color(_status_color(status), 0.90), _status_color(status), _shade_color(_status_color(status), 0.20)))
	badge_row.add_child(_create_inline_badge("Materia: %s" % str(question.get("materia", "Sem materia")), _tint_color(STATUS_INFO, 0.90), STATUS_INFO))
	badge_row.add_child(_create_inline_badge("Dificuldade: %s" % str(question.get("dificuldade", "Facil")), _tint_color(STATUS_WARNING, 0.90), STATUS_WARNING))
	badge_row.add_child(_create_inline_badge("Pontuacao: %d" % int(question.get("pontuacao", 100)), _tint_color(STATUS_OK, 0.90), STATUS_OK))

	_clear_container(detail_container)
	detail_container.add_child(_create_labeled_line_edit("Titulo", str(question.get("titulo", "")), _on_generated_question_text_changed.bind(index, "titulo")))
	detail_container.add_child(_create_labeled_text_edit("Enunciado", str(question.get("enunciado", "")), _on_generated_question_text_edit_changed.bind(index, "enunciado")))
	detail_container.add_child(_create_labeled_line_edit("Alternativa A", str(question.get("alternativaA", "")), _on_generated_question_text_changed.bind(index, "alternativaA")))
	detail_container.add_child(_create_labeled_line_edit("Alternativa B", str(question.get("alternativaB", "")), _on_generated_question_text_changed.bind(index, "alternativaB")))
	detail_container.add_child(_create_labeled_line_edit("Alternativa C", str(question.get("alternativaC", "")), _on_generated_question_text_changed.bind(index, "alternativaC")))
	detail_container.add_child(_create_labeled_line_edit("Alternativa D", str(question.get("alternativaD", "")), _on_generated_question_text_changed.bind(index, "alternativaD")))

	var meta_grid := GridContainer.new()
	meta_grid.columns = 2
	meta_grid.add_theme_constant_override("h_separation", 10)
	meta_grid.add_theme_constant_override("v_separation", 10)
	meta_grid.add_child(_create_labeled_line_edit("Materia", str(question.get("materia", "")), _on_generated_question_text_changed.bind(index, "materia")))
	meta_grid.add_child(_create_labeled_line_edit("Dificuldade", str(question.get("dificuldade", "")), _on_generated_question_text_changed.bind(index, "dificuldade")))
	meta_grid.add_child(_create_labeled_option_button("Resposta correta", QUESTION_CORRECT_OPTIONS, str(question.get("respostaCorreta", "A")), _on_generated_question_option_selected.bind(index, "respostaCorreta")))
	meta_grid.add_child(_create_labeled_spin_box("Pontuacao", int(question.get("pontuacao", 100)), 1, 10000, _on_generated_question_number_changed.bind(index, "pontuacao")))
	meta_grid.add_child(_create_labeled_spin_box("Tempo limite", int(question.get("tempoLimite", 0)), 0, 3600, _on_generated_question_number_changed.bind(index, "tempoLimite")))
	detail_container.add_child(meta_grid)

	_clear_container(action_row)
	var botao_pendente := Button.new()
	botao_pendente.text = "Pendente"
	botao_pendente.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_palette(botao_pendente, _button_bg_for_status(IA_STATUS_PENDING, status), _status_color(IA_STATUS_PENDING), _button_text_for_status(IA_STATUS_PENDING, status))
	botao_pendente.pressed.connect(_on_generated_question_status_changed.bind(index, IA_STATUS_PENDING))
	action_row.add_child(botao_pendente)

	var botao_aprovar := Button.new()
	botao_aprovar.text = "Aprovar"
	botao_aprovar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_palette(botao_aprovar, _button_bg_for_status(IA_STATUS_APPROVED, status), _status_color(IA_STATUS_APPROVED), _button_text_for_status(IA_STATUS_APPROVED, status))
	botao_aprovar.pressed.connect(_on_generated_question_status_changed.bind(index, IA_STATUS_APPROVED))
	action_row.add_child(botao_aprovar)

	var botao_rejeitar := Button.new()
	botao_rejeitar.text = "Rejeitar"
	botao_rejeitar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_palette(botao_rejeitar, _button_bg_for_status(IA_STATUS_REJECTED, status), _status_color(IA_STATUS_REJECTED), _button_text_for_status(IA_STATUS_REJECTED, status))
	botao_rejeitar.pressed.connect(_on_generated_question_status_changed.bind(index, IA_STATUS_REJECTED))
	action_row.add_child(botao_rejeitar)

	var expanded := expanded_generated_question_ids.has(index)
	_set_question_card_expanded(detail_container, action_row, toggle_button, expanded)
	toggle_button.pressed.connect(_on_generated_card_toggle_pressed.bind(index))
	return card

func _on_generated_card_toggle_pressed(index: int) -> void:
	if expanded_generated_question_ids.has(index):
		expanded_generated_question_ids.erase(index)
	else:
		expanded_generated_question_ids[index] = true
	_render_generated_questions()

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
	_render_generated_questions()

func _on_botao_aprovar_todas_pressed() -> void:
	_set_all_generated_questions_status(IA_STATUS_APPROVED)

func _on_botao_rejeitar_todas_pressed() -> void:
	_set_all_generated_questions_status(IA_STATUS_REJECTED)

func _set_all_generated_questions_status(new_status: String) -> void:
	if perguntas_geradas.is_empty() or ia_processando or ia_salvando:
		return
	for index in range(perguntas_geradas.size()):
		perguntas_geradas[index]["statusAuditoria"] = new_status
	_render_generated_questions()
	_show_ia_feedback("Todas as perguntas foram marcadas como %s." % _get_bulk_status_text(new_status), _status_color(new_status))

func _update_ia_summary() -> void:
	var pendentes := _count_generated_questions_with_status(IA_STATUS_PENDING)
	var aprovadas := _count_generated_questions_with_status(IA_STATUS_APPROVED)
	var rejeitadas := _count_generated_questions_with_status(IA_STATUS_REJECTED)
	ia_label_resumo.text = "Pendentes: %d | Aprovadas: %d | Rejeitadas: %d" % [pendentes, aprovadas, rejeitadas]
	ia_label_resumo.add_theme_color_override("font_color", COLOR_TEXT)
	_update_ia_controls_state()

func _count_generated_questions_with_status(status: String) -> int:
	var total := 0
	for question in perguntas_geradas:
		if str(question.get("statusAuditoria", IA_STATUS_PENDING)) == status:
			total += 1
	return total

func _update_ia_controls_state() -> void:
	var controls_locked := carregando or importando_perguntas or ia_processando or ia_salvando or carregando_banco_perguntas
	ia_tema_input.editable = not controls_locked
	ia_materia_input.editable = not controls_locked
	ia_dificuldade_select.disabled = controls_locked
	ia_quantidade_input.editable = not controls_locked
	ia_pontuacao_input.editable = not controls_locked
	ia_tempo_input.editable = not controls_locked
	ia_botao_gerar.disabled = controls_locked
	ia_botao_salvar.disabled = controls_locked or _count_generated_questions_with_status(IA_STATUS_APPROVED) == 0
	ia_botao_aprovar_todas.disabled = controls_locked or perguntas_geradas.is_empty() or _count_generated_questions_with_status(IA_STATUS_APPROVED) == perguntas_geradas.size()
	ia_botao_rejeitar_todas.disabled = controls_locked or perguntas_geradas.is_empty() or _count_generated_questions_with_status(IA_STATUS_REJECTED) == perguntas_geradas.size()
	ia_botao_gerar.text = "Gerando..." if ia_processando else "Gerar com IA"
	ia_botao_salvar.text = "Salvando..." if ia_salvando else "Salvar Perguntas"
	botao_sair.disabled = controls_locked

func _show_ia_feedback(message: String, color_value: Color) -> void:
	ia_label_feedback.text = message
	ia_label_feedback.add_theme_color_override("font_color", color_value)

func _on_botao_salvar_aprovadas_pressed() -> void:
	if ia_salvando or ia_processando:
		return
	var payload := _build_approved_questions_payload()
	if payload.is_empty():
		_show_ia_feedback("Nenhuma pergunta aprovada foi selecionada para salvar.", STATUS_ERROR)
		return

	ia_salvando = true
	_update_ia_controls_state()
	_show_ia_feedback("Salvando perguntas aprovadas no banco oficial...", STATUS_INFO)
	_show_status("Salvando perguntas aprovadas...", STATUS_INFO)
	var response: Dictionary = await ApiClient.save_generated_questions(payload)
	ia_salvando = false
	_update_ia_controls_state()

	if not response.get("ok", false):
		_show_ia_feedback(response.get("error", "Nao foi possivel salvar as perguntas aprovadas."), STATUS_ERROR)
		_show_status(response.get("error", "Nao foi possivel salvar as perguntas aprovadas."), STATUS_ERROR)
		return

	var saved_count: int = int(response.get("data", {}).get("total", payload.size()))
	perguntas_geradas.clear()
	expanded_generated_question_ids.clear()
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
		var validation_error := _validate_question_payload(question, index + 1)
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

func _has_generated_question(index: int) -> bool:
	return index >= 0 and index < perguntas_geradas.size()

func _get_ia_status_label(status: String) -> String:
	match status:
		IA_STATUS_APPROVED:
			return "Aprovada"
		IA_STATUS_REJECTED:
			return "Rejeitada"
		_:
			return "Pendente"

func _get_bulk_status_text(status: String) -> String:
	match status:
		IA_STATUS_APPROVED:
			return "aprovadas"
		IA_STATUS_REJECTED:
			return "rejeitadas"
		_:
			return "pendentes"

func _status_color(status: String) -> Color:
	match status:
		IA_STATUS_APPROVED:
			return STATUS_OK
		IA_STATUS_REJECTED:
			return STATUS_ERROR
		_:
			return STATUS_WARNING

func _status_surface_color(status: String) -> Color:
	return _tint_color(_status_color(status), 0.92)

func _button_bg_for_status(target_status: String, current_status: String) -> Color:
	return _status_color(target_status) if target_status == current_status else _tint_color(_status_color(target_status), 0.92)

func _button_text_for_status(target_status: String, current_status: String) -> Color:
	return Color(1.0, 1.0, 1.0, 1.0) if target_status == current_status else _shade_color(_status_color(target_status), 0.28)

func _on_botao_sair_pressed() -> void:
	ProfessorSession.clear_session()
	get_tree().change_scene_to_file("res://scene/acesso_professor.tscn")

func _on_botao_configuracao_pressed() -> void:
	SettingsManager.open_menu()

func _on_settings_overlay_opened() -> void:
	_apply_sidebar_styles()

func _on_settings_overlay_closed() -> void:
	_apply_sidebar_styles()

func _is_settings_overlay_open() -> bool:
	var overlay = SettingsManager.overlay
	if overlay == null or not is_instance_valid(overlay):
		return false
	if overlay.has_method("is_open"):
		return overlay.is_open()
	return false

func _create_labeled_line_edit(label_text: String, value: String, callback: Callable) -> VBoxContainer:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.text = label_text
	UITheme.apply_font_only(label, 14)
	label.add_theme_color_override("font_color", COLOR_TEXT)
	wrapper.add_child(label)
	var line_edit := LineEdit.new()
	line_edit.text = value
	line_edit.custom_minimum_size = Vector2(0, 42)
	_apply_line_edit_palette(line_edit)
	line_edit.text_changed.connect(callback)
	wrapper.add_child(line_edit)
	return wrapper

func _create_labeled_text_edit(label_text: String, value: String, callback: Callable) -> VBoxContainer:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.text = label_text
	UITheme.apply_font_only(label, 14)
	label.add_theme_color_override("font_color", COLOR_TEXT)
	wrapper.add_child(label)
	var text_edit := TextEdit.new()
	text_edit.text = value
	text_edit.custom_minimum_size = Vector2(0, 104)
	_apply_text_edit_palette(text_edit)
	text_edit.text_changed.connect(callback.bind(text_edit))
	wrapper.add_child(text_edit)
	return wrapper

func _create_labeled_option_button(label_text: String, options: Array[String], current_value: String, callback: Callable) -> VBoxContainer:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.text = label_text
	UITheme.apply_font_only(label, 14)
	label.add_theme_color_override("font_color", COLOR_TEXT)
	wrapper.add_child(label)
	var option_button := OptionButton.new()
	option_button.custom_minimum_size = Vector2(0, 42)
	_apply_option_button_palette(option_button)
	for option in options:
		option_button.add_item(option)
	_select_option_button_by_text(option_button, current_value)
	option_button.item_selected.connect(callback.bind(option_button))
	wrapper.add_child(option_button)
	return wrapper

func _create_labeled_spin_box(label_text: String, current_value: int, min_value: float, max_value: float, callback: Callable) -> VBoxContainer:
	var wrapper := VBoxContainer.new()
	wrapper.add_theme_constant_override("separation", 4)
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var label := Label.new()
	label.text = label_text
	UITheme.apply_font_only(label, 14)
	label.add_theme_color_override("font_color", COLOR_TEXT)
	wrapper.add_child(label)
	var spin_box := SpinBox.new()
	_configure_spin_box(spin_box, min_value, max_value, current_value)
	_apply_spin_box_palette(spin_box)
	spin_box.value_changed.connect(callback)
	wrapper.add_child(spin_box)
	return wrapper

func _select_option_button_by_text(option_button: OptionButton, current_value: String) -> void:
	for item_index in range(option_button.item_count):
		if option_button.get_item_text(item_index) == current_value:
			option_button.select(item_index)
			return
	if option_button.item_count > 0:
		option_button.select(0)

func _configure_spin_box(spin_box: SpinBox, min_value: float, max_value: float, default_value: float) -> void:
	spin_box.min_value = min_value
	spin_box.max_value = max_value
	spin_box.step = 1
	spin_box.value = default_value
	spin_box.allow_greater = false
	spin_box.allow_lesser = false
	spin_box.rounded = true
	spin_box.custom_minimum_size = Vector2(0, 42)

func _create_empty_state_panel(title_text: String, description_text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_surface_panel(panel, COLOR_SURFACE_ALT, COLOR_BORDER, 20, 0.03)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 4)
	panel.add_child(content)
	var title := Label.new()
	title.text = title_text
	UITheme.apply_font_only(title, 18)
	title.add_theme_color_override("font_color", COLOR_TEXT)
	content.add_child(title)
	var description := Label.new()
	description.text = description_text
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.apply_font_only(description, 15)
	description.add_theme_color_override("font_color", COLOR_MUTED)
	content.add_child(description)
	return panel

func _create_inline_badge(text_value: String, background: Color, border: Color, text_color: Color = COLOR_TEXT) -> PanelContainer:
	var badge := PanelContainer.new()
	_apply_surface_panel(badge, background, border, 999, 0.0)
	var label := Label.new()
	label.text = text_value
	UITheme.apply_font_only(label, 13)
	label.add_theme_color_override("font_color", text_color)
	badge.add_child(label)
	return badge

func _question_title(question: Dictionary) -> String:
	var title := str(question.get("titulo", "")).strip_edges()
	if not title.is_empty():
		return title
	return "Pergunta #%d" % int(question.get("id", 0))

func _truncate_text(value: String, max_length: int) -> String:
	var normalized := value.strip_edges()
	if normalized.length() <= max_length:
		return normalized
	return "%s..." % normalized.substr(0, max_length)

func _extract_dictionary_array(payload: Variant) -> Array[Dictionary]:
	var extracted: Array[Dictionary] = []
	if payload is not Array:
		return extracted
	for item in payload:
		if item is Dictionary:
			extracted.append(item)
	return extracted

func _format_datetime(raw_value: Variant) -> String:
	var value := str(raw_value).strip_edges()
	if value.is_empty():
		return "Sem registro"
	var normalized := value.replace("T", " ")
	var dot_index := normalized.find(".")
	if dot_index != -1:
		normalized = normalized.substr(0, dot_index)
	return normalized

func _get_student_status_color(status: String) -> Color:
	match status:
		"finalizado":
			return STATUS_OK
		"jogando":
			return STATUS_INFO
		_:
			return STATUS_WARNING

func _clear_container(container: Node) -> void:
	if container == null:
		return
	for child in container.get_children():
		child.queue_free()

func _apply_surface_panel(panel: PanelContainer, background: Color, border: Color, radius: int, shadow_opacity: float) -> void:
	panel.add_theme_stylebox_override("panel", _create_surface_style(background, border, 1, radius, 16, 14, shadow_opacity))

func _apply_badge_panel(panel: PanelContainer, background: Color, border: Color) -> void:
	panel.add_theme_stylebox_override("panel", _create_surface_style(background, border, 1, 999, 12, 8, 0.0))

func _create_surface_style(background: Color, border: Color, border_width: int = 1, corner_radius: int = 18, horizontal_padding: int = 14, vertical_padding: int = 12, shadow_opacity: float = 0.04) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.content_margin_left = horizontal_padding
	style.content_margin_top = vertical_padding
	style.content_margin_right = horizontal_padding
	style.content_margin_bottom = vertical_padding
	style.shadow_color = Color(0.0, 0.0, 0.0, shadow_opacity)
	style.shadow_size = 8 if shadow_opacity > 0.0 else 0
	style.shadow_offset = Vector2(0, 3)
	return style

func _apply_button_palette(button: Button, background: Color, border: Color, font_color: Color = Color(1.0, 1.0, 1.0, 1.0)) -> void:
	UITheme.apply_font_only(button, 16)
	button.add_theme_stylebox_override("normal", _create_surface_style(background, border, 1, 16, 16, 11, 0.02))
	button.add_theme_stylebox_override("hover", _create_surface_style(_tint_color(background, 0.06), border, 1, 16, 16, 11, 0.03))
	button.add_theme_stylebox_override("pressed", _create_surface_style(_shade_color(background, 0.06), border, 1, 16, 16, 11, 0.02))
	button.add_theme_stylebox_override("focus", _create_surface_style(_tint_color(background, 0.03), border, 2, 16, 16, 11, 0.03))
	button.add_theme_stylebox_override("disabled", _create_surface_style(_tint_color(background, 0.18), _tint_color(border, 0.10), 1, 16, 16, 11, 0.01))
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", font_color)
	button.add_theme_color_override("font_pressed_color", font_color)
	button.add_theme_color_override("font_focus_color", font_color)
	button.add_theme_color_override("font_disabled_color", font_color.lerp(Color(1.0, 1.0, 1.0, 1.0), 0.45))

func _apply_option_button_palette(option_button: OptionButton) -> void:
	_apply_button_palette(option_button, COLOR_SURFACE, COLOR_BORDER, COLOR_TEXT)

func _apply_line_edit_palette(line_edit: LineEdit) -> void:
	UITheme.apply_font_only(line_edit, 15)
	line_edit.add_theme_stylebox_override("normal", _create_surface_style(COLOR_SURFACE, COLOR_BORDER, 1, 14, 12, 10, 0.0))
	line_edit.add_theme_stylebox_override("focus", _create_surface_style(COLOR_SURFACE, COLOR_ACCENT, 2, 14, 12, 10, 0.0))
	line_edit.add_theme_stylebox_override("read_only", _create_surface_style(COLOR_SURFACE_ALT, COLOR_BORDER, 1, 14, 12, 10, 0.0))
	line_edit.add_theme_color_override("font_color", COLOR_TEXT)
	line_edit.add_theme_color_override("font_placeholder_color", COLOR_MUTED)

func _apply_text_edit_palette(text_edit: TextEdit) -> void:
	UITheme.apply_font_only(text_edit, 15)
	text_edit.add_theme_stylebox_override("normal", _create_surface_style(COLOR_SURFACE, COLOR_BORDER, 1, 14, 12, 10, 0.0))
	text_edit.add_theme_stylebox_override("focus", _create_surface_style(COLOR_SURFACE, COLOR_ACCENT, 2, 14, 12, 10, 0.0))
	text_edit.add_theme_color_override("font_color", COLOR_TEXT)

func _apply_spin_box_palette(spin_box: SpinBox) -> void:
	var line_edit := spin_box.get_line_edit()
	if line_edit != null:
		_apply_line_edit_palette(line_edit)

func _tint_color(color_value: Color, amount: float) -> Color:
	return color_value.lerp(Color(1.0, 1.0, 1.0, color_value.a), clampf(amount, 0.0, 1.0))

func _shade_color(color_value: Color, amount: float) -> Color:
	return color_value.lerp(Color(0.0, 0.0, 0.0, color_value.a), clampf(amount, 0.0, 1.0))
