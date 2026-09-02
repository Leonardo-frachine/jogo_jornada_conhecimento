extends Control

# Painel administrativo: gerencia salas, alunos, perguntas, importacao, IA e indicadores.
const UITheme := preload("res://scripts/UITheme.gd")
const SettingsButtonLayout := preload("res://ui/settings/SettingsButtonLayout.gd")
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
const TEMPLATE_SPREADSHEET_FILENAME := "modelo_perguntas.csv"
const TEMPLATE_SPREADSHEET_HEADER := "enunciado,alternativaA,alternativaB,alternativaC,alternativaD,respostaCorreta,materia,dificuldade,titulo,pontuacao,tempoLimite"
const TEMPLATE_SPREADSHEET_EXAMPLE := "Quanto e 2 + 2?,3,4,5,6,B,Matematica,Facil,Exemplo de pergunta,100,30"

const IA_STATUS_PENDING := "pendente"
const IA_STATUS_APPROVED := "aprovada"
const IA_STATUS_REJECTED := "rejeitada"
const IA_DIFFICULTIES: Array[String] = ["Facil", "Medio", "Dificil", "Especial"]
const QUESTION_CORRECT_OPTIONS: Array[String] = ["A", "B", "C", "D"]
const STUDENT_STATUS_AGUARDANDO := "aguardando"
const STUDENT_STATUS_INICIADO := "iniciado"
const STUDENT_STATUS_JOGANDO := "jogando"
const STUDENT_STATUS_FINALIZADO := "finalizado"
const STUDENT_TOTAL_BOARD_HOUSES := 28
const DASHBOARD_AUTO_REFRESH_SECONDS := 5.0

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
@onready var ranking_final_panel: PanelContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/RankingFinalPanel
@onready var ranking_final_summary: Label = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/RankingFinalPanel/RankingFinalMargin/RankingFinalVBox/RankingFinalSummary
@onready var ranking_final_list: VBoxContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/RankingFinalPanel/RankingFinalMargin/RankingFinalVBox/RankingFinalList
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
@onready var botao_exportar_pdf_turma: Button = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/AcompanhamentoPage/AcompanhamentoHero/AcompanhamentoHeroMargin/AcompanhamentoHeroVBox/AcompanhamentoActions/BotaoExportarPdfTurma
@onready var botao_exportar_csv: Button = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/AcompanhamentoPage/AcompanhamentoHero/AcompanhamentoHeroMargin/AcompanhamentoHeroVBox/AcompanhamentoActions/BotaoExportarCsv
@onready var acompanhamento_grid: GridContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/AcompanhamentoPage/AcompanhamentoGrid

@onready var resumo_banco_perguntas: Label = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasHeaderCard/PerguntasHeaderMargin/PerguntasHeaderVBox/PerguntasHeaderTop/PerguntasTituloBox/ResumoBancoPerguntas
@onready var contador_banco_perguntas: Label = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasHeaderCard/PerguntasHeaderMargin/PerguntasHeaderVBox/PerguntasHeaderTop/PerguntasContador
@onready var botao_atualizar_perguntas: Button = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasHeaderCard/PerguntasHeaderMargin/PerguntasHeaderVBox/PerguntasActions/BotaoAtualizarPerguntas
@onready var botao_expandir_todas: Button = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasHeaderCard/PerguntasHeaderMargin/PerguntasHeaderVBox/PerguntasActions/BotaoExpandirTodas
@onready var botao_recolher_todas: Button = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasHeaderCard/PerguntasHeaderMargin/PerguntasHeaderVBox/PerguntasActions/BotaoRecolherTodas
@onready var botao_eliminar_perguntas: Button = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasHeaderCard/PerguntasHeaderMargin/PerguntasHeaderVBox/PerguntasActions/BotaoEliminarPerguntas
@onready var perguntas_actions: GridContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasHeaderCard/PerguntasHeaderMargin/PerguntasHeaderVBox/PerguntasActions
@onready var perguntas_filters_grid: GridContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasFiltersCard/PerguntasFiltersMargin/PerguntasFiltersGrid
@onready var input_busca_perguntas: LineEdit = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasFiltersCard/PerguntasFiltersMargin/PerguntasFiltersGrid/InputBuscaPerguntas
@onready var filtro_materia_perguntas: OptionButton = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasFiltersCard/PerguntasFiltersMargin/PerguntasFiltersGrid/FiltroMateriaPerguntas
@onready var filtro_dificuldade_perguntas: OptionButton = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasFiltersCard/PerguntasFiltersMargin/PerguntasFiltersGrid/FiltroDificuldadePerguntas
@onready var lista_banco_perguntas: VBoxContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/ListaBancoPerguntas

@onready var import_room_selector: OptionButton = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/ImportarPerguntasPage/ImportarIntroCard/ImportarIntroMargin/ImportarIntroVBox/ImportRoomSelector
@onready var importar_feedback: Label = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/ImportarPerguntasPage/ImportarIntroCard/ImportarIntroMargin/ImportarIntroVBox/ImportarFeedback
@onready var botao_baixar_modelo: Button = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/ImportarPerguntasPage/ImportarIntroCard/ImportarIntroMargin/ImportarIntroVBox/ImportarActions/BotaoBaixarModelo
@onready var botao_importar: Button = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/ImportarPerguntasPage/ImportarIntroCard/ImportarIntroMargin/ImportarIntroVBox/ImportarActions/BotaoImportar

@onready var ia_form_grid: GridContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaFormCard/IaFormMargin/IaFormGrid
@onready var ia_room_selector: OptionButton = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaFormCard/IaFormMargin/IaFormGrid/IaRoomSelector
@onready var ia_tema_input: LineEdit = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaFormCard/IaFormMargin/IaFormGrid/IaTemaInput
@onready var ia_materia_input: LineEdit = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaFormCard/IaFormMargin/IaFormGrid/IaMateriaInput
@onready var ia_dificuldade_select: OptionButton = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaFormCard/IaFormMargin/IaFormGrid/IaDificuldadeSelect
@onready var ia_quantidade_input: SpinBox = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaFormCard/IaFormMargin/IaFormGrid/IaQuantidadeInput
@onready var ia_pontuacao_input: SpinBox = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaFormCard/IaFormMargin/IaFormGrid/IaPontuacaoInput
@onready var ia_tempo_input: SpinBox = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaFormCard/IaFormMargin/IaFormGrid/IaTempoInput
@onready var ia_actions_grid: GridContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaActionsGrid
@onready var ia_botao_gerar: Button = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaActionsGrid/IaBotaoGerar
@onready var ia_botao_salvar: Button = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaActionsGrid/IaBotaoSalvar
@onready var ia_botao_aprovar_todas: Button = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaActionsGrid/IaBotaoAprovarTodas
@onready var ia_botao_rejeitar_todas: Button = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaActionsGrid/IaBotaoRejeitarTodas
@onready var ia_label_feedback: Label = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaIntroCard/IaIntroMargin/IaIntroVBox/IaLabelFeedback
@onready var ia_label_resumo: Label = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaSummaryCard/IaSummaryMargin/IaLabelResumo
@onready var ia_lista: VBoxContainer = $SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaLista

@onready var confirmacao_apagar_sala: ConfirmationDialog = $ConfirmacaoApagarSala
@onready var confirmacao_apagar_perguntas: ConfirmationDialog = $ConfirmacaoApagarPerguntas

var salas: Array[Dictionary] = []
var carregando := false
var importando_perguntas := false
var carregando_banco_perguntas := false
var ia_processando := false
var ia_salvando := false
var sidebar_expanded := true
var import_dialog: FileDialog
var template_download_dialog: FileDialog
var report_download_dialog: FileDialog
var relatorio_exportando := false
var pending_report_data := PackedByteArray()
var pending_report_extension := ""

var current_view := VIEW_DASHBOARD
var dashboard_payload: Dictionary = {}
var respostas_sala: Array[Dictionary] = []
var alunos_sala: Array[Dictionary] = []
var banco_perguntas: Array[Dictionary] = []
var perguntas_geradas: Array[Dictionary] = []
var perguntas_geradas_sala_id := 0
var importacao_sala_id := 0
var expanded_bank_question_ids := {}
var expanded_generated_question_ids := {}
var dashboard_refresh_timer: Timer
var dashboard_refresh_in_progress := false
var panel_exiting := false
var pergunta_exclusao_id := 0
var pergunta_exclusao_sala_id := 0
var pergunta_exclusao_todas := false

func _ready() -> void:
	# Valida sessao antes de montar controles que dependem do professor autenticado.
	SettingsManager.pause_tree_when_open = false
	SettingsManager.close_menu()

	# Sem sessao valida retorna ao login e impede acesso ao painel.
	if not ProfessorSession.has_session():
		get_tree().change_scene_to_file("res://scene/acesso_professor.tscn")
		return

	_ensure_import_dialog()
	_connect_signals()
	_apply_theme()
	_configure_action_groups()
	_prepare_dashboard_layout()
	_setup_ia_form()
	_update_responsive_layout()
	call_deferred("_update_responsive_layout")
	_set_current_view(VIEW_DASHBOARD)
	_render_empty_dashboard()
	_render_students([])
	_render_question_bank()
	_render_generated_questions()
	_set_import_feedback("Aguardando o envio de uma planilha .csv ou .xlsx.", STATUS_INFO)
	_show_ia_feedback("Preencha os dados para gerar uma previa de perguntas.", STATUS_INFO)
	_show_status("Painel pronto para carregar as salas do professor.", STATUS_INFO)

	# Resize de desktop/Web recalcula grids e largura da barra lateral.
	if not get_viewport().size_changed.is_connected(_update_responsive_layout):
		get_viewport().size_changed.connect(_update_responsive_layout)
	# Escala de fonte altera os limites considerados compactos.
	if not SettingsManager.font_scale_changed.is_connected(_on_font_scale_changed):
		SettingsManager.font_scale_changed.connect(_on_font_scale_changed)

	_setup_dashboard_auto_refresh()
	call_deferred("_load_initial_data")

func _exit_tree() -> void:
	# Marca encerramento antes de parar timers para descartar respostas HTTP tardias.
	panel_exiting = true
	_stop_dashboard_auto_refresh()

func _setup_dashboard_auto_refresh() -> void:
	# Reutiliza o timer existente para nao duplicar atualizacoes a cada cinco segundos.
	if dashboard_refresh_timer != null and is_instance_valid(dashboard_refresh_timer):
		return

	dashboard_refresh_timer = Timer.new()
	dashboard_refresh_timer.name = "DashboardAutoRefreshTimer"
	dashboard_refresh_timer.wait_time = DASHBOARD_AUTO_REFRESH_SECONDS
	dashboard_refresh_timer.one_shot = false
	dashboard_refresh_timer.timeout.connect(_on_dashboard_auto_refresh_timeout)
	add_child(dashboard_refresh_timer)
	dashboard_refresh_timer.start()

func _stop_dashboard_auto_refresh() -> void:
	# Encerramento e seguro mesmo se o timer nunca foi criado ou ja foi liberado.
	if dashboard_refresh_timer == null or not is_instance_valid(dashboard_refresh_timer):
		return
	dashboard_refresh_timer.stop()

func _on_dashboard_auto_refresh_timeout() -> void:
	# Nao sobrepoe refresh nem atualiza enquanto a tela carrega/sai.
	if panel_exiting or carregando or dashboard_refresh_in_progress:
		return
	# Sem sala selecionada nao existe dashboard isolado para consultar.
	if not ProfessorSession.has_current_room():
		return
	await _refresh_dashboard(false)

func _connect_signals() -> void:
	sidebar_toggle.pressed.connect(_on_sidebar_toggle_pressed)
	botao_dashboard.pressed.connect(_on_navigation_pressed.bind(VIEW_DASHBOARD))
	botao_gerenciar_sala_menu.pressed.connect(_on_navigation_pressed.bind(VIEW_ROOM))
	botao_acompanhamento.pressed.connect(_on_navigation_pressed.bind(VIEW_STUDENTS))
	botao_banco_perguntas.pressed.connect(_on_navigation_pressed.bind(VIEW_BANK))
	botao_importar_pagina.pressed.connect(_on_navigation_pressed.bind(VIEW_IMPORT))
	botao_gerar_ia_pagina.pressed.connect(_on_navigation_pressed.bind(VIEW_AI))

	seletor_salas.item_selected.connect(_on_seletor_salas_item_selected)
	botao_atualizar_salas_header.pressed.connect(_on_botao_atualizar_salas_pressed)
	botao_sair.pressed.connect(_on_botao_sair_pressed)

	botao_criar_sala.pressed.connect(_on_botao_criar_sala_pressed)
	botao_atualizar_salas.pressed.connect(_on_botao_atualizar_salas_pressed)
	botao_apagar_sala.pressed.connect(_on_botao_apagar_sala_pressed)
	botao_exportar_pdf_turma.pressed.connect(_on_exportar_pdf_turma_pressed)
	botao_exportar_csv.pressed.connect(_on_exportar_csv_pressed)
	confirmacao_apagar_sala.confirmed.connect(_on_confirmacao_apagar_sala_confirmed)
	confirmacao_apagar_perguntas.confirmed.connect(_on_confirmacao_apagar_perguntas_confirmed)

	botao_atualizar_perguntas.pressed.connect(_on_botao_atualizar_banco_perguntas_pressed)
	botao_expandir_todas.pressed.connect(_on_botao_expandir_todas_pressed)
	botao_recolher_todas.pressed.connect(_on_botao_recolher_todas_pressed)
	botao_eliminar_perguntas.pressed.connect(_on_botao_eliminar_perguntas_pressed)
	input_busca_perguntas.text_changed.connect(_on_question_filter_changed)
	filtro_materia_perguntas.item_selected.connect(_on_question_filter_changed)
	filtro_dificuldade_perguntas.item_selected.connect(_on_question_filter_changed)

	botao_importar.pressed.connect(_on_botao_importar_pressed)
	botao_baixar_modelo.pressed.connect(_on_botao_baixar_modelo_pressed)

	ia_botao_gerar.pressed.connect(_on_botao_gerar_ia_pressed)
	ia_botao_salvar.pressed.connect(_on_botao_salvar_aprovadas_pressed)
	ia_botao_aprovar_todas.pressed.connect(_on_botao_aprovar_todas_pressed)
	ia_botao_rejeitar_todas.pressed.connect(_on_botao_rejeitar_todas_pressed)

func _prepare_dashboard_layout() -> void:
	var painel_atividades := dashboard_secondary_grid.get_node_or_null("PainelAtividades") as Control
	# Move atividades para o grid secundario apenas quando a cena antiga ainda usa outro pai.
	if painel_atividades != null and painel_atividades.get_parent() != dashboard_body_grid:
		dashboard_secondary_grid.remove_child(painel_atividades)
		dashboard_body_grid.add_child(painel_atividades)

	dashboard_secondary_grid.visible = dashboard_secondary_grid.get_child_count() > 0

func _load_initial_data() -> void:
	await _fetch_rooms(true)
	await _refresh_question_bank()

func _apply_theme() -> void:
	UITheme.apply_font_tree(self)
	background.color = COLOR_BACKGROUND
	soft_glow_top.color = COLOR_GLOW_PRIMARY
	soft_glow_bottom.color = COLOR_GLOW_SECONDARY
	_apply_surface_panel(sidebar, COLOR_SIDEBAR, COLOR_SIDEBAR_BORDER, 28, 0.05)
	_apply_surface_panel(header, COLOR_SURFACE, COLOR_BORDER, 24, 0.08)
	_apply_surface_panel(content_shell, COLOR_SURFACE, COLOR_BORDER, 26, 0.06)

	# Aplica superficie consistente aos cards estaticos das seis paginas.
	for panel in [
		dashboard_hero_card,
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerenciarSalaPage/GerenciarSalaHero"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerenciarSalaPage/GerenciarSalaGrid/PainelSalaGerenciar"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardBodyGrid/PainelMaterias"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardBodyGrid/PainelDificuldades"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardSecondaryGrid/PainelAtividades"),
		ranking_final_panel,
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/AcompanhamentoPage/AcompanhamentoHero"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasHeaderCard"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasFiltersCard"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/ImportarPerguntasPage/ImportarIntroCard"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaIntroCard"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaFormCard"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaSummaryCard"),
	]:
		_apply_surface_panel(panel as PanelContainer, COLOR_SURFACE, COLOR_BORDER, 22, 0.05)

	UITheme.apply_title(page_title, 32, COLOR_TEXT)
	UITheme.apply_subtitle(page_subtitle, 17, COLOR_MUTED)
	UITheme.apply_subtitle(status_label, 15, COLOR_MUTED)
	UITheme.apply_subtitle(current_room_label, 15, COLOR_ACCENT_DARK)
	page_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_apply_badge_panel(current_room_badge, _tint_color(COLOR_ACCENT, 0.86), COLOR_ACCENT)

	UITheme.apply_title(dashboard_hero_title, 24, COLOR_TEXT)
	UITheme.apply_subtitle(dashboard_hero_description, 15, COLOR_MUTED)
	UITheme.apply_title(get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerenciarSalaPage/GerenciarSalaHero/GerenciarSalaHeroMargin/GerenciarSalaHeroVBox/TituloGerenciarSala"), 22, COLOR_TEXT)
	UITheme.apply_title(get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerenciarSalaPage/GerenciarSalaGrid/PainelSalaGerenciar/SalaGerenciarMargin/SalaGerenciarVBox/TituloSalaCardGerenciar"), 20, COLOR_TEXT)
	UITheme.apply_title(get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardBodyGrid/PainelMaterias/MateriasMargin/MateriasVBox/TituloMaterias"), 20, COLOR_TEXT)
	UITheme.apply_title(get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardBodyGrid/PainelDificuldades/DificuldadesMargin/DificuldadesVBox/TituloDificuldades"), 20, COLOR_TEXT)
	UITheme.apply_title(get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardSecondaryGrid/PainelAtividades/AtividadesMargin/AtividadesVBox/TituloAtividades"), 20, COLOR_TEXT)
	UITheme.apply_title(get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/RankingFinalPanel/RankingFinalMargin/RankingFinalVBox/RankingFinalTitle"), 20, COLOR_TEXT)
	UITheme.apply_title(get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/AcompanhamentoPage/AcompanhamentoHero/AcompanhamentoHeroMargin/AcompanhamentoHeroVBox/TituloAcompanhamento"), 22, COLOR_TEXT)
	UITheme.apply_button(botao_exportar_pdf_turma, UITheme.BUTTON_SECONDARY, 15)
	UITheme.apply_button(botao_exportar_csv, UITheme.BUTTON_PRIMARY, 15)
	UITheme.apply_title(get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/BancoPerguntasPage/PerguntasHeaderCard/PerguntasHeaderMargin/PerguntasHeaderVBox/PerguntasHeaderTop/PerguntasTituloBox/TituloBancoPerguntas"), 22, COLOR_TEXT)
	UITheme.apply_title(get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/ImportarPerguntasPage/ImportarIntroCard/ImportarIntroMargin/ImportarIntroVBox/TituloImportar"), 22, COLOR_TEXT)
	UITheme.apply_title(get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaIntroCard/IaIntroMargin/IaIntroVBox/TituloIa"), 22, COLOR_TEXT)

	# Aplica tipografia secundaria aos textos descritivos do painel.
	for label in [
		sidebar_brand_title,
		sidebar_brand_subtitle,
		sidebar_description,
		sidebar_footer_title,
		sidebar_footer_subtitle,
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardBodyGrid/PainelMaterias/MateriasMargin/MateriasVBox/DescricaoMaterias"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardBodyGrid/PainelDificuldades/DificuldadesMargin/DificuldadesVBox/DescricaoDificuldades"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/DashboardSecondaryGrid/PainelAtividades/AtividadesMargin/AtividadesVBox/DescricaoAtividades"),
		get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/DashboardPage/RankingFinalPanel/RankingFinalMargin/RankingFinalVBox/RankingFinalDescription"),
		ranking_final_summary,
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
		UITheme.apply_subtitle(label as Label, 16, COLOR_MUTED if label != contador_banco_perguntas else COLOR_ACCENT_DARK)

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
	_apply_option_button_palette(import_room_selector)
	_apply_option_button_palette(ia_room_selector)
	_apply_option_button_palette(ia_dificuldade_select)
	_apply_spin_box_palette(ia_quantidade_input)
	_apply_spin_box_palette(ia_pontuacao_input)
	_apply_spin_box_palette(ia_tempo_input)
	# Estiliza todos os rotulos do formulario de geracao por IA.
	for label_name in [
		"IaSalaLabel",
		"IaTemaLabel",
		"IaMateriaLabel",
		"IaDificuldadeLabel",
		"IaQuantidadeLabel",
		"IaPontuacaoLabel",
		"IaTempoLabel",
	]:
		UITheme.apply_field_label(ia_form_grid.get_node(label_name) as Label, 16, COLOR_TEXT)

	_apply_button_palette(botao_atualizar_salas_header, COLOR_SURFACE_ALT, COLOR_BORDER, COLOR_TEXT)
	_apply_button_palette(botao_sair, STATUS_ERROR, _shade_color(STATUS_ERROR, 0.24))
	_apply_button_palette(botao_criar_sala, COLOR_ACCENT, COLOR_ACCENT_DARK)
	_apply_button_palette(botao_atualizar_salas, STATUS_INFO, _shade_color(STATUS_INFO, 0.24))
	_apply_button_palette(botao_apagar_sala, STATUS_ERROR, _shade_color(STATUS_ERROR, 0.24))
	_apply_button_palette(botao_atualizar_perguntas, STATUS_INFO, _shade_color(STATUS_INFO, 0.24))
	_apply_button_palette(botao_expandir_todas, COLOR_SURFACE_ALT, COLOR_BORDER, COLOR_TEXT)
	_apply_button_palette(botao_recolher_todas, COLOR_SURFACE_ALT, COLOR_BORDER, COLOR_TEXT)
	_apply_button_palette(botao_eliminar_perguntas, STATUS_ERROR, _shade_color(STATUS_ERROR, 0.24))
	_apply_button_palette(botao_baixar_modelo, COLOR_SURFACE_ALT, COLOR_BORDER, COLOR_TEXT)
	_apply_button_palette(botao_importar, COLOR_ACCENT, COLOR_ACCENT_DARK)
	_apply_button_palette(ia_botao_gerar, COLOR_ACCENT, COLOR_ACCENT_DARK)
	_apply_button_palette(ia_botao_salvar, STATUS_OK, _shade_color(STATUS_OK, 0.22))
	_apply_button_palette(ia_botao_aprovar_todas, STATUS_OK, _shade_color(STATUS_OK, 0.22))
	_apply_button_palette(ia_botao_rejeitar_todas, STATUS_ERROR, _shade_color(STATUS_ERROR, 0.22))

	sidebar_toggle.modulate = Color.WHITE
	_apply_surface_panel(current_room_badge, _tint_color(COLOR_ACCENT, 0.88), COLOR_ACCENT, 999, 0.0)

	_apply_sidebar_styles()
	_refresh_header_context()

func _setup_ia_form() -> void:
	ia_dificuldade_select.clear()
	# Preenche o seletor com os quatro niveis aceitos pelo jogo.
	for difficulty in IA_DIFFICULTIES:
		ia_dificuldade_select.add_item(difficulty)
	ia_dificuldade_select.select(1)
	_configure_spin_box(ia_quantidade_input, 1, 20, 5)
	_configure_spin_box(ia_pontuacao_input, 1, 10000, 100)
	_configure_spin_box(ia_tempo_input, 0, 3600, 30)
	ia_quantidade_input.suffix = " perguntas"
	ia_pontuacao_input.suffix = " pontos"
	ia_tempo_input.suffix = " segundos"

func _update_responsive_layout() -> void:
	# Define grades e tamanhos a partir da largura efetiva apos escala de fonte.
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var font_scale: float = SettingsManager.font_scale
	var compact := viewport_size.x < 1260.0 * font_scale
	var content_width: float = content_shell.size.x
	# Antes do primeiro frame estima a largura porque o container ainda pode medir zero.
	if content_width <= 0.0:
		content_width = viewport_size.x - (sidebar.custom_minimum_size.x + (32.0 if compact else 48.0))
	var effective_content_width := content_width / font_scale
	var compact_content: bool = effective_content_width < 980.0

	safe_area.add_theme_constant_override("margin_left", 16 if compact else 24)
	safe_area.add_theme_constant_override("margin_top", 16 if viewport_size.y < 760.0 else 24)
	# Mantem uma faixa livre para a engrenagem flutuante, inclusive ao rolar o painel.
	safe_area.add_theme_constant_override("margin_right", roundi(SettingsButtonLayout.CONTENT_SAFE_MARGIN))
	safe_area.add_theme_constant_override("margin_bottom", 16 if viewport_size.y < 760.0 else 24)
	shell.add_theme_constant_override("separation", 16 if compact else 22)
	content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	metrics_grid.columns = 1 if effective_content_width < 700.0 else (2 if effective_content_width < 1080.0 else (3 if effective_content_width < 1420.0 else 4))
	dashboard_body_grid.columns = 1 if effective_content_width < 900.0 else (2 if effective_content_width < 1320.0 else 3)
	dashboard_secondary_grid.columns = 1
	gerenciar_sala_grid.columns = 1
	acoes_sala.columns = 1 if effective_content_width < 900.0 else 3
	acompanhamento_grid.columns = 1 if effective_content_width < 1180.0 else 2
	perguntas_actions.columns = 1 if effective_content_width < 760.0 else (2 if effective_content_width < 1180.0 else 4)
	perguntas_filters_grid.columns = 1 if effective_content_width < 900.0 else 3
	get_node("SafeArea/Shell/MainColumn/ContentShell/ContentScroll/PageStack/GerarIAPage/IaFormCard/IaFormMargin/IaFormGrid").columns = 1 if effective_content_width < 980.0 else 2
	ia_actions_grid.columns = 1 if effective_content_width < 900.0 else (2 if effective_content_width < 1280.0 else 4)
	header_actions.alignment = BoxContainer.ALIGNMENT_BEGIN if compact_content else BoxContainer.ALIGNMENT_END
	header_actions.add_theme_constant_override("separation", 8 if compact_content else 12)
	seletor_salas.custom_minimum_size = Vector2(180.0 if compact_content else 250.0, 44.0)
	botao_atualizar_salas_header.custom_minimum_size = Vector2(140.0 if compact_content else 150.0, 44.0)
	botao_sair.custom_minimum_size = Vector2(140.0 if compact_content else 160.0, 44.0)
	header.custom_minimum_size.y = 116.0 + roundf(36.0 * (font_scale - 1.0))
	current_room_badge.visible = effective_content_width >= 760.0
	sidebar.size.x = 278.0 if sidebar_expanded else 94.0
	_configure_action_groups()

func _configure_action_groups() -> void:
	_configure_action_grid(acoes_sala, [botao_criar_sala, botao_atualizar_salas, botao_apagar_sala])
	_configure_action_grid(perguntas_actions, [
		botao_atualizar_perguntas,
		botao_expandir_todas,
		botao_recolher_todas,
		botao_eliminar_perguntas,
	])
	_configure_action_grid(ia_actions_grid, [
		ia_botao_gerar,
		ia_botao_salvar,
		ia_botao_aprovar_todas,
		ia_botao_rejeitar_todas,
	])

	perguntas_filters_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	perguntas_filters_grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	# Filtros compartilham as mesmas regras de largura e expansao.
	for filter_control in [input_busca_perguntas, filtro_materia_perguntas, filtro_dificuldade_perguntas]:
		filter_control.custom_minimum_size.x = 180.0
		filter_control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		filter_control.size_flags_vertical = Control.SIZE_SHRINK_BEGIN

func _configure_action_grid(grid: GridContainer, buttons: Array) -> void:
	# Uniformiza botoes de acao para que grids responsivos nao cortem os textos.
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	# Percorre as referencias recebidas e configura somente Buttons validos.
	for button_value in buttons:
		var button := button_value as Button
		# Variantes de cena podem omitir uma acao sem quebrar as demais.
		if button == null:
			continue
		button.custom_minimum_size.x = 160.0
		button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 48.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		button.autowrap_mode = TextServer.AUTOWRAP_OFF
		button.clip_text = false
		button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING

func _on_font_scale_changed(_value: float) -> void:
	call_deferred("_update_responsive_layout")

func _on_sidebar_toggle_pressed() -> void:
	sidebar_expanded = not sidebar_expanded
	_apply_sidebar_styles()

func _apply_sidebar_styles() -> void:
	# Expansao controla largura, textos e estado ativo de toda a navegacao.
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

	# Percorre cada pagina para aplicar visibilidade e destaque correspondente.
	for view_name in buttons.keys():
		var button: Button = buttons[view_name]
		var label: Label = button.get_node("Layout/Label") as Label
		var icon: TextureRect = button.get_node("Layout/Icon") as TextureRect
		label.visible = sidebar_expanded
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_apply_sidebar_button_style(button, label, icon, view_name == current_view)

func _apply_sidebar_button_style(button: Button, label: Label, icon: TextureRect, active: bool) -> void:
	var background := _tint_color(COLOR_SIDEBAR, 0.025)
	var border := _tint_color(COLOR_SIDEBAR_BORDER, 0.04)
	var text_color := COLOR_SIDEBAR_MUTED
	var shadow_opacity := 0.02
	# Item ativo troca a superficie escura pelo destaque amarelo.
	if active:
		background = COLOR_ACCENT
		border = COLOR_ACCENT_DARK
		text_color = COLOR_TEXT
		shadow_opacity = 0.12

	button.add_theme_stylebox_override("normal", _create_surface_style(background, border, 1, 18, 14, 12, shadow_opacity))
	button.add_theme_stylebox_override("hover", _create_surface_style(_tint_color(background, 0.08), border, 1, 18, 14, 12, maxf(shadow_opacity, 0.05)))
	button.add_theme_stylebox_override("pressed", _create_surface_style(_shade_color(background, 0.08), border, 1, 18, 14, 12, shadow_opacity))
	button.add_theme_stylebox_override("focus", _create_surface_style(_tint_color(background, 0.04), border, 2, 18, 14, 12, maxf(shadow_opacity, 0.06)))
	button.add_theme_stylebox_override("disabled", _create_surface_style(_tint_color(background, 0.18), _tint_color(border, 0.12), 1, 18, 14, 12, 0.0))
	button.add_theme_color_override("font_color", Color(0, 0, 0, 0))
	button.add_theme_color_override("font_hover_color", Color(0, 0, 0, 0))
	button.add_theme_color_override("font_pressed_color", Color(0, 0, 0, 0))
	# Label opcional recebe fonte e cor calculada.
	if label != null:
		UITheme.apply_font_only(label, 16)
		label.add_theme_color_override("font_color", text_color)
	# Icone opcional permanece branco para contraste nos dois estados.
	if icon != null:
		icon.modulate = Color.WHITE

func _on_navigation_pressed(view_name: String) -> void:
	_set_current_view(view_name)

func _set_current_view(view_name: String) -> void:
	# Somente a pagina selecionada permanece visivel e o scroll volta ao topo.
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
	# Cabecalho combina metadados da pagina com a sala ativa da sessao.
	var page_info: Dictionary = PAGE_META.get(current_view, PAGE_META[VIEW_DASHBOARD])
	page_title.text = str(page_info.get("title", "Painel do Professor"))
	page_subtitle.text = str(page_info.get("subtitle", ""))

	# Sala ativa atualiza badge, pagina de gerenciamento e rodape lateral.
	if ProfessorSession.has_current_room():
		var room_name := ProfessorSession.current_room_name.strip_edges()
		var room_code := ProfessorSession.current_room_code.strip_edges().to_upper()
		current_room_label.text = "%s (%s)" % [room_name if not room_name.is_empty() else "Sala ativa", room_code if not room_code.is_empty() else "--"]
		sala_atual_info.text = "Sala ativa: %s" % (room_name if not room_name.is_empty() else "Sem nome")
		sala_codigo_info.text = "Codigo: %s" % (room_code if not room_code.is_empty() else "--")
		resumo_gerenciar_sala.text = "Sala atual selecionada: %s. As acoes desta pagina afetam o contexto usado nas outras telas." % (room_name if not room_name.is_empty() else "selecionada")
		sidebar_footer_subtitle.text = "Trabalhando na sala %s." % (room_name if not room_name.is_empty() else "selecionada")
		_apply_badge_panel(current_room_badge, _tint_color(COLOR_ACCENT, 0.88), COLOR_ACCENT)
	# Sem sala, exibe instrucoes neutras e remove o destaque de contexto.
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
	botao_exportar_pdf_turma.disabled = enabled or relatorio_exportando or not ProfessorSession.has_current_room()
	botao_exportar_csv.disabled = enabled or relatorio_exportando or not ProfessorSession.has_current_room()
	seletor_salas.disabled = enabled or salas.is_empty()
	_update_question_bank_controls_state()
	_update_ia_controls_state()

func _ensure_import_dialog() -> void:
	# Cria dialogos em runtime para aceitar cenas antigas que ainda nao os possuem.
	import_dialog = get_node_or_null("ImportDialog")
	# Dialogo de abertura permite escolher CSV ou XLSX no desktop.
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

	# Selecao de arquivo inicia uma unica importacao.
	if not import_dialog.file_selected.is_connected(_on_import_file_selected):
		import_dialog.file_selected.connect(_on_import_file_selected)

	template_download_dialog = get_node_or_null("TemplateDownloadDialog")
	# Dialogo separado escolhe onde salvar o CSV modelo.
	if template_download_dialog == null:
		template_download_dialog = FileDialog.new()
		template_download_dialog.name = "TemplateDownloadDialog"
		template_download_dialog.access = FileDialog.ACCESS_FILESYSTEM
		template_download_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		template_download_dialog.use_native_dialog = true
		template_download_dialog.title = "Salvar modelo de planilha"
		template_download_dialog.current_file = TEMPLATE_SPREADSHEET_FILENAME
		template_download_dialog.add_filter("*.csv", "Arquivos CSV")
		add_child(template_download_dialog)

	# Caminho escolhido e processado uma unica vez por confirmacao.
	if not template_download_dialog.file_selected.is_connected(_on_template_download_file_selected):
		template_download_dialog.file_selected.connect(_on_template_download_file_selected)

	report_download_dialog = get_node_or_null("ReportDownloadDialog")
	if report_download_dialog == null:
		report_download_dialog = FileDialog.new()
		report_download_dialog.name = "ReportDownloadDialog"
		report_download_dialog.access = FileDialog.ACCESS_FILESYSTEM
		report_download_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		report_download_dialog.use_native_dialog = true
		report_download_dialog.title = "Salvar relatorio"
		add_child(report_download_dialog)
	if not report_download_dialog.file_selected.is_connected(_on_report_download_file_selected):
		report_download_dialog.file_selected.connect(_on_report_download_file_selected)
	if not report_download_dialog.canceled.is_connected(_clear_pending_report):
		report_download_dialog.canceled.connect(_clear_pending_report)

func _fetch_rooms(refresh_dashboard_after_load: bool) -> void:
	# Impede consultas concorrentes acionadas por botoes ou inicializacao.
	if carregando:
		return

	_set_loading_state(true)
	_show_status("Carregando salas do professor...", STATUS_INFO)
	var response: Dictionary = await ApiClient.fetch_rooms_by_teacher(ProfessorSession.professor_id)
	_set_loading_state(false)

	# Falha limpa o contexto para nao manter uma sala antiga como se estivesse valida.
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
	# Lista vazia limpa sala ativa e orienta a criar a primeira turma.
	if salas.is_empty():
		ProfessorSession.set_current_room({})
		_refresh_header_context()
		_render_empty_dashboard()
		_render_students([])
		_show_status("Nenhuma sala criada ainda. Crie a primeira para iniciar o painel.", STATUS_INFO)
		return

	var selected_index := _find_selected_room_index()
	# Se a sala anterior nao existe mais, seleciona a primeira disponivel.
	if selected_index < 0:
		selected_index = 0
	seletor_salas.select(selected_index)
	_apply_selected_room(selected_index)
	_show_status("Salas carregadas com sucesso.", STATUS_OK)

	# Chamadores interativos podem pedir dados da sala logo apos a listagem.
	if refresh_dashboard_after_load:
		await _refresh_dashboard()

func _populate_room_selector() -> void:
	# Reconstrói o seletor principal a partir do snapshot de salas.
	seletor_salas.clear()
	# Estado vazio desabilita selecao e tambem atualiza seletores de destino.
	if salas.is_empty():
		seletor_salas.add_item("Nenhuma sala criada")
		seletor_salas.disabled = true
		_populate_question_room_selectors()
		return

	# Cada sala recebe texto amigavel e o dicionario completo como metadata.
	for index in range(salas.size()):
		var sala: Dictionary = salas[index]
		var nome: String = str(sala.get("nome", "Sala"))
		var codigo: String = str(sala.get("codigo", ""))
		seletor_salas.add_item("%s (%s)" % [nome, codigo])
		seletor_salas.set_item_metadata(index, sala)
	seletor_salas.disabled = carregando
	_populate_question_room_selectors()

func _populate_question_room_selectors() -> void:
	# Importacao segue a sala atual; previa de IA preserva sua sala de origem.
	var preferred_room_id := ProfessorSession.current_room_id if ProfessorSession.has_current_room() else 0
	_populate_question_room_selector(import_room_selector, preferred_room_id)
	var ia_preferred_room_id := perguntas_geradas_sala_id if not perguntas_geradas.is_empty() and perguntas_geradas_sala_id > 0 else preferred_room_id
	_populate_question_room_selector(ia_room_selector, ia_preferred_room_id)
	_update_question_bank_controls_state()
	_update_ia_controls_state()

func _populate_question_room_selector(selector: OptionButton, preferred_room_id: int) -> void:
	selector.clear()
	# Sem salas, desabilita o destino para impedir importacao/geracao solta.
	if salas.is_empty():
		selector.add_item("Nenhuma sala disponivel")
		selector.set_item_metadata(0, 0)
		selector.disabled = true
		return

	var selected_index := 0
	# Adiciona todas as salas e procura simultaneamente a preferida.
	for index in range(salas.size()):
		var sala: Dictionary = salas[index]
		var sala_id := int(sala.get("id", 0))
		var nome := str(sala.get("nome", "Sala"))
		var codigo := str(sala.get("codigo", "")).strip_edges().to_upper()
		selector.add_item("Sala de destino: %s (%s)" % [nome, codigo])
		selector.set_item_metadata(index, sala_id)
		# Guarda o indice que corresponde ao contexto atual.
		if sala_id == preferred_room_id:
			selected_index = index
	selector.select(selected_index)

func _select_question_target_room(sala_id: int) -> void:
	var selectors: Array[OptionButton] = [import_room_selector]
	# Se existe previa de IA, nao troca seu destino silenciosamente.
	if perguntas_geradas.is_empty():
		selectors.append(ia_room_selector)
	# Sincroniza os seletores permitidos com a sala escolhida no cabecalho.
	for selector in selectors:
		# Procura a metadata do ID dentro de cada seletor.
		for index in range(selector.item_count):
			# Ao encontrar, seleciona e interrompe a busca neste controle.
			if int(selector.get_item_metadata(index)) == sala_id:
				selector.select(index)
				break

func _get_question_target_room_id(selector: OptionButton) -> int:
	# Seletor vazio ou sem escolha nao representa uma sala valida.
	if selector.item_count == 0 or selector.selected < 0:
		return 0
	return int(selector.get_item_metadata(selector.selected))

func _find_selected_room_index() -> int:
	# Sem contexto anterior nao existe indice para restaurar.
	if not ProfessorSession.has_current_room():
		return -1
	# Procura o ID da sessao no snapshot recem-carregado.
	for index in range(salas.size()):
		# O primeiro ID correspondente e o item que deve permanecer selecionado.
		if int(salas[index].get("id", 0)) == ProfessorSession.current_room_id:
			return index
	return -1

func _apply_selected_room(index: int) -> void:
	# Indice fora da lista limpa o contexto em vez de acessar item invalido.
	if index < 0 or index >= salas.size():
		ProfessorSession.set_current_room({})
	# Indice valido copia metadados da sala para a sessao global.
	else:
		ProfessorSession.set_current_room(salas[index])
	# Sala valida tambem vira destino padrao de perguntas.
	if ProfessorSession.has_current_room():
		_select_question_target_room(ProfessorSession.current_room_id)
	_refresh_header_context()

func _on_seletor_salas_item_selected(index: int) -> void:
	# Ignora mudanca durante carga ou indice invalido emitido pelo controle.
	if carregando or index < 0 or index >= salas.size():
		return
	_apply_selected_room(index)
	await _refresh_dashboard()
	await _refresh_question_bank()

func _on_botao_atualizar_salas_pressed() -> void:
	await _fetch_rooms(true)

func _on_botao_criar_sala_pressed() -> void:
	# Bloqueia criacao duplicada enquanto outra operacao de sala esta ativa.
	if carregando:
		return
	var nome_sala := input_nome_sala.text.strip_edges()
	_set_loading_state(true)
	_show_status("Criando nova sala...", STATUS_INFO)
	var response: Dictionary = await ApiClient.create_room(ProfessorSession.professor_id, nome_sala)
	_set_loading_state(false)

	# Falha mantem o formulario e exibe a mensagem do backend.
	if not response.get("ok", false):
		_show_status(response.get("error", "Nao foi possivel criar a sala."), STATUS_ERROR)
		return

	input_nome_sala.text = ""
	var payload: Dictionary = response.get("data", {})
	var sala: Dictionary = payload.get("sala", {})
	# Sucesso com payload de sala atualiza imediatamente o contexto preferido.
	if not sala.is_empty():
		ProfessorSession.set_current_room(sala)
	_show_status(payload.get("mensagem", "Sala criada com sucesso."), STATUS_OK)
	await _fetch_rooms(true)

func _on_botao_apagar_sala_pressed() -> void:
	# Exclusao so pode ser solicitada com sala ativa e painel livre.
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
	# Revalida o contexto porque ele pode mudar enquanto o dialogo estava aberto.
	if carregando or not ProfessorSession.has_current_room():
		return

	_set_loading_state(true)
	_show_status("Apagando a sala e os dados vinculados...", STATUS_INFO)
	var response: Dictionary = await ApiClient.delete_room(ProfessorSession.current_room_id)
	_set_loading_state(false)

	# Falha preserva a sala e seus dados na interface.
	if not response.get("ok", false):
		_show_status(response.get("error", "Nao foi possivel apagar a sala."), STATUS_ERROR)
		return

	ProfessorSession.set_current_room({})
	respostas_sala.clear()
	alunos_sala.clear()
	dashboard_payload.clear()
	_render_empty_dashboard()
	_render_students([])
	_show_status(response.get("data", {}).get("mensagem", "Sala apagada com sucesso."), STATUS_OK)
	await _fetch_rooms(true)

func _refresh_dashboard(interactive: bool = true) -> void:
	# Impede atualizacao concorrente, durante carga ou apos inicio da saida.
	if panel_exiting or carregando or dashboard_refresh_in_progress:
		return

	# Sem sala ativa limpa indicadores em vez de consultar dados globais.
	if not ProfessorSession.has_current_room():
		alunos_sala.clear()
		respostas_sala.clear()
		_render_empty_dashboard()
		_render_students([])
		return

	var requested_room_id := ProfessorSession.current_room_id
	dashboard_refresh_in_progress = true
	# Refresh manual exibe bloqueio e status; automatico trabalha silenciosamente.
	if interactive:
		_set_loading_state(true)
		_show_status("Atualizando indicadores da sala...", STATUS_INFO)
	var dashboard_response: Dictionary = await ApiClient.fetch_room_dashboard(requested_room_id)
	# Descarta resposta do dashboard se o painel foi destruido durante o await.
	if panel_exiting or not is_inside_tree():
		dashboard_refresh_in_progress = false
		return
	var answers_response: Dictionary = await ApiClient.fetch_room_answers(requested_room_id)
	# Faz a mesma guarda depois de carregar respostas/alunos.
	if panel_exiting or not is_inside_tree():
		dashboard_refresh_in_progress = false
		return
	# Somente chamada manual precisa liberar os controles bloqueados.
	if interactive:
		_set_loading_state(false)
	dashboard_refresh_in_progress = false

	# Se o professor trocou de sala, nao aplica resposta antiga na nova selecao.
	if not ProfessorSession.has_current_room() or ProfessorSession.current_room_id != requested_room_id:
		return

	# Dashboard e a resposta principal; sua falha interrompe a renderizacao.
	if not dashboard_response.get("ok", false):
		# Refresh manual informa e limpa visualmente a falha.
		if interactive:
			_render_empty_dashboard()
			_render_students([])
			_show_status(dashboard_response.get("error", "Nao foi possivel carregar o dashboard."), STATUS_ERROR)
		return

	dashboard_payload = dashboard_response.get("data", {})
	# Respostas bem-sucedidas alimentam atividades e acompanhamento individual.
	if answers_response.get("ok", false):
		var answers_payload: Dictionary = answers_response.get("data", {})
		respostas_sala = _normalize_answer_list(answers_payload.get("respostas", []))
		alunos_sala = _normalize_answer_list(answers_payload.get("alunos", []))
	# Falha secundaria ainda permite renderizar indicadores agregados.
	else:
		# Apenas refresh manual mostra o aviso da consulta secundaria.
		if interactive:
			respostas_sala.clear()
			alunos_sala.clear()
			_show_status(answers_response.get("error", "Nao foi possivel carregar as respostas da sala."), STATUS_WARNING)

	_render_dashboard_data(dashboard_payload)
	_render_students(_build_student_models(respostas_sala, alunos_sala))
	# Confirma atualizacao somente quando solicitada pelo professor.
	if interactive:
		_show_status("Dashboard atualizado.", STATUS_OK)

func _render_empty_dashboard() -> void:
	dashboard_payload.clear()
	dashboard_hero_title.text = "Visao geral da sala"
	dashboard_hero_description.text = "Selecione uma sala para visualizar indicadores, atividades recentes e o andamento da turma. Se precisar criar ou apagar salas, use a pagina Gerenciar Sala."
	_render_metric_cards([
		{"title": "Total de alunos", "value": "0", "subtitle": "Aguardando respostas vinculadas a uma sala.", "accent": COLOR_ACCENT, "icon": "A"},
		{"title": "Perguntas cadastradas", "value": str(banco_perguntas.size()), "subtitle": "Banco oficial disponivel para a turma.", "accent": STATUS_INFO, "icon": "P"},
		{"title": "Media de acertos", "value": "0%", "subtitle": "Sem historico suficiente para calcular.", "accent": STATUS_OK, "icon": "M"},
		{"title": "Pontuacao da turma", "value": "0", "subtitle": "Saldo de acertos e descontos por erros.", "accent": COLOR_ACCENT, "icon": "S"},
		{"title": "Respostas realizadas", "value": "0", "subtitle": "Nenhuma atividade concluida ainda.", "accent": STATUS_WARNING, "icon": "R"},
		{"title": "Alunos em andamento", "value": "0", "subtitle": "Aguardando inicio das partidas.", "accent": COLOR_ACCENT, "icon": "E"},
		{"title": "Alunos finalizados", "value": "0", "subtitle": "Nenhum encerramento oficial registrado.", "accent": STATUS_OK, "icon": "F"},
	])
	_render_group_summary_list(lista_materias_dashboard, [], "materia", "Nenhum dado por materia disponivel ainda.")
	_render_group_summary_list(lista_dificuldades_dashboard, [], "dificuldade", "Nenhum dado por dificuldade disponivel ainda.")
	_render_recent_activity([])
	_render_teacher_ranking([])
	_refresh_header_context()

func _render_dashboard_data(payload: Dictionary) -> void:
	# Combina agregados do endpoint com estados individuais das respostas/alunos.
	var indicadores: Dictionary = payload.get("indicadores", {})
	var student_models: Array[Dictionary] = _build_student_models(respostas_sala, alunos_sala)
	var states: Dictionary = _summarize_student_states(student_models)
	var total_alunos: int = int(indicadores.get("totalAlunos", 0))
	var total_respostas: int = int(indicadores.get("totalPerguntasRespondidas", 0))
	var pontuacao_total: int = int(indicadores.get("pontuacaoTotalTurma", 0))
	var room_name := ProfessorSession.current_room_name.strip_edges()

	dashboard_hero_title.text = "Visao geral da sala %s" % (room_name if not room_name.is_empty() else "selecionada")
	# Sala sem atividade recebe texto de orientacao inicial.
	if total_respostas <= 0:
		dashboard_hero_description.text = "A estrutura da sala ja esta pronta. Assim que a turma responder perguntas, este dashboard mostrara medias, distribuicoes e atividade recente."
	# Sala ativa resume participacao e numero de respostas.
	else:
		dashboard_hero_description.text = "%d alunos ja registraram %d respostas. Use os cards abaixo para identificar oportunidades de reforco e acompanhar a participacao da turma." % [total_alunos, total_respostas]

	_render_metric_cards([
		{"title": "Total de alunos", "value": str(total_alunos), "subtitle": "Participantes com respostas registradas na sala.", "accent": COLOR_ACCENT, "icon": "A"},
		{"title": "Perguntas cadastradas", "value": str(banco_perguntas.size()), "subtitle": "Itens disponiveis hoje no banco oficial.", "accent": STATUS_INFO, "icon": "P"},
		{"title": "Media de acertos", "value": "%d%%" % int(indicadores.get("percentualAcertoTurma", 0)), "subtitle": "%d acertos e %d erros no agregado." % [int(indicadores.get("quantidadeAcertos", 0)), int(indicadores.get("quantidadeErros", 0))], "accent": STATUS_OK, "icon": "M"},
		{"title": "Pontuacao da turma", "value": str(pontuacao_total), "subtitle": "Total liquido apos os descontos por respostas incorretas.", "accent": STATUS_ERROR if pontuacao_total < 0 else COLOR_ACCENT, "icon": "S"},
		{"title": "Respostas realizadas", "value": str(total_respostas), "subtitle": "Historico usado para acompanhar a sala.", "accent": STATUS_WARNING, "icon": "R"},
		{"title": "Alunos em andamento", "value": str(int(states.get(STUDENT_STATUS_JOGANDO, 0))), "subtitle": "Partidas com status jogando no backend.", "accent": COLOR_ACCENT, "icon": "E"},
		{"title": "Alunos finalizados", "value": str(int(states.get(STUDENT_STATUS_FINALIZADO, 0))), "subtitle": "Somente encerramentos oficiais da partida.", "accent": STATUS_OK, "icon": "F"},
	])

	_render_group_summary_list(lista_materias_dashboard, payload.get("desempenhoPorMateria", []), "materia", "Nenhum dado por materia disponivel ainda.")
	_render_group_summary_list(lista_dificuldades_dashboard, payload.get("desempenhoPorDificuldade", []), "dificuldade", "Nenhum dado por dificuldade disponivel ainda.")
	_render_recent_activity(respostas_sala)
	_render_teacher_ranking(_extract_dictionary_array(payload.get("ranking", [])))
	_refresh_header_context()

func _render_metric_cards(metrics: Array[Dictionary]) -> void:
	# Recria cards a partir do modelo atual para evitar dados residuais.
	_clear_container(metrics_grid)
	# Cada metrica instancia o componente reutilizavel e aplica seus valores.
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
	# Substitui a lista anterior por agrupamentos atuais de materia ou dificuldade.
	_clear_container(container)
	# Payload ausente/vazio recebe um card explicativo.
	if groups is not Array or groups.is_empty():
		container.add_child(_create_empty_state_panel("Sem dados ainda", empty_message))
		return

	# Converte cada agrupamento valido em uma linha de resumo.
	for item in groups:
		# Ignora valores inesperados sem impedir os demais grupos.
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
	# Sem respostas exibe orientacao em vez de lista vazia.
	if respostas.is_empty():
		lista_atividades.add_child(_create_empty_state_panel("Sem atividades recentes", "As respostas mais recentes da sala aparecerao aqui assim que os alunos jogarem."))
		return

	var limit: int = min(5, respostas.size())
	# Mostra no maximo as cinco respostas mais recentes ja ordenadas pelo backend.
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
		var pontos_resposta: int = int(resposta.get("pontuacaoGanha", 0))
		var pontos_label := "+%d" % pontos_resposta if pontos_resposta >= 0 else str(pontos_resposta)
		detail.text = "%s | %s | Pontos: %s | Fase %d | %s" % [
			str(resposta.get("materia", "Sem materia")),
			str(resposta.get("dificuldade", "Sem dificuldade")),
			pontos_label,
			int(resposta.get("fase", 0)),
			_format_datetime(resposta.get("respondidoEm", "")),
		]
		detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UITheme.apply_font_only(detail, 13)
		detail.add_theme_color_override("font_color", COLOR_MUTED)
		box.add_child(detail)
		lista_atividades.add_child(panel)

func _render_teacher_ranking(items: Array[Dictionary]) -> void:
	# Ranking final considera somente partidas oficialmente encerradas e IDs unicos.
	_clear_container(ranking_final_list)
	var finalizados: Array[Dictionary] = []
	var jogadores_exibidos := {}
	# Filtra os itens devolvidos pelo endpoint da sala.
	for item in items:
		# Jogador iniciado/em andamento nao participa da classificacao final.
		if _normalize_student_status(str(item.get("statusPartida", ""))) != STUDENT_STATUS_FINALIZADO:
			continue
		var jogador_id := int(item.get("jogadorId", 0))
		# ID invalido ou duplicado nao gera outra colocacao.
		if jogador_id <= 0 or jogadores_exibidos.has(jogador_id):
			continue
		jogadores_exibidos[jogador_id] = true
		finalizados.append(item)

	# Nenhuma conclusao oficial produz estado vazio informativo.
	if finalizados.is_empty():
		ranking_final_summary.text = "Nenhum aluno possui encerramento oficial nesta sala."
		var empty_label := Label.new()
		empty_label.text = "O ranking sera preenchido quando as partidas forem finalizadas."
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		UITheme.apply_font_only(empty_label, 14)
		empty_label.add_theme_color_override("font_color", COLOR_MUTED)
		ranking_final_list.add_child(empty_label)
		return

	ranking_final_summary.text = "%d alunos finalizados, ordenados pela pontuacao e pelo horario de termino em caso de empate." % finalizados.size()
	# Renderiza uma linha por colocacao recebida do backend.
	for index in range(finalizados.size()):
		ranking_final_list.add_child(_create_teacher_ranking_row(finalizados[index]))
		# Adiciona separadores apenas entre participantes.
		if index < finalizados.size() - 1:
			ranking_final_list.add_child(HSeparator.new())

func _create_teacher_ranking_row(item: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 64)
	row.add_theme_constant_override("separation", 12)

	var position_label := Label.new()
	position_label.custom_minimum_size = Vector2(52, 0)
	position_label.text = "#%d" % int(item.get("posicao", 0))
	UITheme.apply_font_only(position_label, 20)
	position_label.add_theme_color_override("font_color", COLOR_ACCENT_DARK)
	row.add_child(position_label)

	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	identity.add_theme_constant_override("separation", 2)
	var name_label := Label.new()
	name_label.text = str(item.get("nome", "Aluno"))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	UITheme.apply_font_only(name_label, 16)
	name_label.add_theme_color_override("font_color", COLOR_TEXT)
	identity.add_child(name_label)
	var finished_label := Label.new()
	finished_label.text = "Termino: %s" % _format_datetime(item.get("finalizadoEm", ""))
	UITheme.apply_font_only(finished_label, 13)
	finished_label.add_theme_color_override("font_color", COLOR_MUTED)
	identity.add_child(finished_label)
	row.add_child(identity)

	var score_label := Label.new()
	score_label.custom_minimum_size = Vector2(110, 0)
	score_label.text = "%d pontos" % int(item.get("pontuacao", 0))
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	UITheme.apply_font_only(score_label, 16)
	score_label.add_theme_color_override("font_color", COLOR_TEXT)
	row.add_child(score_label)
	row.add_child(_create_inline_badge("Finalizado", _tint_color(STATUS_OK, 0.90), STATUS_OK, _shade_color(STATUS_OK, 0.25)))
	return row

func _render_students(models: Array[Dictionary]) -> void:
	_clear_container(acompanhamento_grid)
	# Sala sem alunos recebe explicacao do que aparecera apos o inicio.
	if models.is_empty():
		resumo_acompanhamento.text = "Nenhum aluno apareceu no acompanhamento ainda."
		resumo_acompanhamento.add_theme_color_override("font_color", COLOR_MUTED)
		acompanhamento_grid.add_child(_create_empty_state_panel("Acompanhamento aguardando atividade", "Assim que a turma iniciar uma partida, esta pagina mostrara status, pontuacao, progresso e ultima atividade por aluno."))
		return

	resumo_acompanhamento.text = "%d alunos na sala. O status atual vem do backend e separa inicio, jogo em andamento e encerramento oficial." % models.size()
	resumo_acompanhamento.add_theme_color_override("font_color", COLOR_TEXT)
	# Cada modelo consolidado vira um card individual de acompanhamento.
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
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.apply_font_only(name_label, 18)
	name_label.add_theme_color_override("font_color", COLOR_TEXT)
	top.add_child(name_label)

	var status_badge := _create_inline_badge(
		_get_student_status_label(str(item.get("status", STUDENT_STATUS_AGUARDANDO))),
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
	meta_row.add_child(_create_inline_badge("Progresso: %s" % str(item.get("progressoLabel", "Casa 1/28")), _tint_color(STATUS_INFO, 0.90), STATUS_INFO))

	var bottom := Label.new()
	bottom.text = "Ultima atividade: %s | Aproveitamento: %d%%" % [
		str(item.get("ultimaAtividade", "Sem registro")),
		int(item.get("aproveitamento", 0)),
	]
	bottom.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UITheme.apply_font_only(bottom, 14)
	bottom.add_theme_color_override("font_color", COLOR_MUTED)
	box.add_child(bottom)

	var export_button := Button.new()
	export_button.text = "Exportar relatorio em PDF"
	export_button.custom_minimum_size.y = 42
	export_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	export_button.disabled = relatorio_exportando
	UITheme.apply_button(export_button, UITheme.BUTTON_SECONDARY, 14)
	export_button.pressed.connect(_on_exportar_pdf_aluno_pressed.bind(item, export_button))
	box.add_child(export_button)
	return panel

func _on_exportar_csv_pressed() -> void:
	if relatorio_exportando or not ProfessorSession.has_current_room():
		return
	relatorio_exportando = true
	botao_exportar_pdf_turma.disabled = true
	botao_exportar_csv.disabled = true
	_show_status("Preparando a base CSV da sala...", STATUS_INFO)
	var response: Dictionary = await ApiClient.download_room_report_csv(
		ProfessorSession.current_room_id,
		ProfessorSession.professor_id
	)
	relatorio_exportando = false
	botao_exportar_pdf_turma.disabled = not ProfessorSession.has_current_room()
	botao_exportar_csv.disabled = not ProfessorSession.has_current_room()
	if not response.get("ok", false):
		_show_status(response.get("error", "Nao foi possivel exportar o CSV."), STATUS_ERROR)
		return
	_open_report_save_dialog(
		response.get("data", PackedByteArray()),
		str(response.get("file_name", "desempenho_sala.csv")),
		"csv"
	)

func _on_exportar_pdf_turma_pressed() -> void:
	if relatorio_exportando or not ProfessorSession.has_current_room():
		return
	relatorio_exportando = true
	botao_exportar_pdf_turma.disabled = true
	botao_exportar_csv.disabled = true
	_show_status("Gerando o relatorio consolidado da turma...", STATUS_INFO)
	var response: Dictionary = await ApiClient.download_class_report_pdf(
		ProfessorSession.current_room_id,
		ProfessorSession.professor_id
	)
	relatorio_exportando = false
	botao_exportar_pdf_turma.disabled = not ProfessorSession.has_current_room()
	botao_exportar_csv.disabled = not ProfessorSession.has_current_room()
	if not response.get("ok", false):
		_show_status(response.get("error", "Nao foi possivel exportar o PDF da turma."), STATUS_ERROR)
		return
	_open_report_save_dialog(
		response.get("data", PackedByteArray()),
		str(response.get("file_name", "relatorio_turma.pdf")),
		"pdf"
	)

func _on_exportar_pdf_aluno_pressed(item: Dictionary, button: Button) -> void:
	if relatorio_exportando or not ProfessorSession.has_current_room():
		return
	var jogador_id := int(item.get("jogadorId", 0))
	if jogador_id <= 0:
		_show_status("O aluno selecionado nao possui um identificador valido.", STATUS_ERROR)
		return
	relatorio_exportando = true
	button.disabled = true
	botao_exportar_pdf_turma.disabled = true
	botao_exportar_csv.disabled = true
	_show_status("Gerando o relatorio profissional de %s..." % str(item.get("nome", "aluno")), STATUS_INFO)
	var response: Dictionary = await ApiClient.download_student_report_pdf(
		ProfessorSession.current_room_id,
		jogador_id,
		ProfessorSession.professor_id
	)
	relatorio_exportando = false
	if is_instance_valid(button):
		button.disabled = false
	botao_exportar_pdf_turma.disabled = not ProfessorSession.has_current_room()
	botao_exportar_csv.disabled = not ProfessorSession.has_current_room()
	if not response.get("ok", false):
		_show_status(response.get("error", "Nao foi possivel exportar o PDF."), STATUS_ERROR)
		return
	_open_report_save_dialog(
		response.get("data", PackedByteArray()),
		str(response.get("file_name", "relatorio_aluno.pdf")),
		"pdf"
	)

func _open_report_save_dialog(data: PackedByteArray, suggested_name: String, extension: String) -> void:
	if report_download_dialog == null or data.is_empty():
		_show_status("O arquivo de relatorio recebido esta vazio.", STATUS_ERROR)
		return
	pending_report_data = data
	pending_report_extension = extension.to_lower()
	report_download_dialog.clear_filters()
	report_download_dialog.add_filter("*.%s" % pending_report_extension, "Arquivo %s" % pending_report_extension.to_upper())
	report_download_dialog.current_file = suggested_name if not suggested_name.is_empty() else "relatorio.%s" % pending_report_extension
	report_download_dialog.title = "Salvar relatorio %s" % pending_report_extension.to_upper()
	report_download_dialog.popup_centered_ratio(0.72)
	_show_status("Relatorio pronto. Escolha onde salvar o arquivo.", STATUS_OK)

func _on_report_download_file_selected(path: String) -> void:
	if pending_report_data.is_empty() or pending_report_extension.is_empty():
		_show_status("Nao ha um relatorio pronto para salvar.", STATUS_ERROR)
		return
	var target_path := path
	if target_path.get_extension().to_lower() != pending_report_extension:
		target_path = "%s.%s" % [target_path, pending_report_extension]
	var target_file := FileAccess.open(target_path, FileAccess.WRITE)
	if target_file == null:
		_show_status("Nao foi possivel salvar o relatorio no local escolhido.", STATUS_ERROR)
		return
	target_file.store_buffer(pending_report_data)
	var write_error := target_file.get_error()
	target_file.close()
	if write_error != OK:
		_show_status("Falha ao concluir a gravacao do relatorio.", STATUS_ERROR)
		return
	_clear_pending_report()
	_show_status("Relatorio salvo com sucesso em %s." % target_path.get_file(), STATUS_OK)

func _clear_pending_report() -> void:
	pending_report_data = PackedByteArray()
	pending_report_extension = ""

func _build_student_models(respostas: Array[Dictionary], alunos: Array[Dictionary] = []) -> Array[Dictionary]:
	# Une estado corrente do jogador com seu historico de respostas.
	var grouped := {}
	# Primeiro cria modelos para todos os alunos, inclusive quem ainda nao respondeu.
	for aluno in alunos:
		var aluno_id: int = int(aluno.get("jogadorId", aluno.get("id", 0)))
		# Identidade sem ID nao pode agrupar respostas com seguranca.
		if aluno_id <= 0:
			continue
		var aluno_model := _create_student_model_base(aluno)
		aluno_model["estadoAtualBackend"] = true
		grouped[aluno_id] = aluno_model

	# Depois agrega cada resposta ao modelo do respectivo jogador.
	for resposta in respostas:
		var jogador_id: int = int(resposta.get("jogadorId", 0))
		# Resposta sem jogador identificavel e ignorada.
		if jogador_id <= 0:
			continue
		# Historico legado pode conter jogador ausente no endpoint de alunos.
		if not grouped.has(jogador_id):
			grouped[jogador_id] = _create_student_model_base({
				"jogadorId": jogador_id,
				"nome": str(resposta.get("aluno", "Aluno")),
			})

		var row: Dictionary = grouped[jogador_id]
		row["pontuacao"] = int(row.get("pontuacao", 0)) + int(resposta.get("pontuacaoGanha", 0))
		row["acertos"] = int(row.get("acertos", 0)) + (1 if bool(resposta.get("acertou", false)) else 0)
		row["erros"] = int(row.get("erros", 0)) + (0 if bool(resposta.get("acertou", false)) else 1)
		row["respostas"] = int(row.get("respostas", 0)) + 1
		row["maxFase"] = max(int(row.get("maxFase", 0)), int(resposta.get("fase", 0)))
		# Sem snapshot atual, deriva casa e status a partir do historico.
		if not bool(row.get("estadoAtualBackend", false)):
			row["casaAtual"] = max(int(row.get("casaAtual", 1)), int(resposta.get("casaAtual", 1)))
			# Qualquer resposta transforma um estado legado de aguardando em jogando.
			if _normalize_student_status(str(row.get("statusPartida", ""))) == STUDENT_STATUS_AGUARDANDO:
				row["statusPartida"] = STUDENT_STATUS_JOGANDO
		# Como respostas chegam recentes primeiro, a primeira data e a ultima atividade.
		if str(row.get("ultimaRespostaRaw", "")).is_empty():
			row["ultimaRespostaRaw"] = resposta.get("respondidoEm", "")
		grouped[jogador_id] = row

	var students: Array[Dictionary] = []
	# Finaliza calculos derivados e converte o Map em lista renderizavel.
	for item in grouped.values():
		var respostas_total: int = int(item.get("respostas", 0))
		var acertos_total: int = int(item.get("acertos", 0))
		var casa_atual: int = clampi(int(item.get("casaAtual", 1)), 1, STUDENT_TOTAL_BOARD_HOUSES)
		var aproveitamento := 0 if respostas_total == 0 else int(round((float(acertos_total) / float(respostas_total)) * 100.0))
		var status := _normalize_student_status(str(item.get("statusPartida", STUDENT_STATUS_AGUARDANDO)))
		# Sem estado atual, respostas existentes indicam partida em andamento.
		if not bool(item.get("estadoAtualBackend", false)) and status != STUDENT_STATUS_FINALIZADO:
			status = STUDENT_STATUS_JOGANDO if respostas_total > 0 or status == STUDENT_STATUS_JOGANDO else STUDENT_STATUS_AGUARDANDO
		item["pontuacao"] = int(item.get("pontuacao", 0)) if respostas_total > 0 else int(item.get("pontuacaoBackend", 0))
		item["aproveitamento"] = aproveitamento
		item["status"] = status
		item["progressoLabel"] = "Casa %d/%d" % [casa_atual, STUDENT_TOTAL_BOARD_HOUSES]
		item["ultimaAtividade"] = _format_datetime(item.get("ultimaRespostaRaw", ""))
		students.append(item)

	students.sort_custom(func(a, b):
		# Empate de pontuacao usa o nome para manter ordem deterministica.
		if int(a.get("pontuacao", 0)) == int(b.get("pontuacao", 0)):
			return str(a.get("nome", "")) < str(b.get("nome", ""))
		return int(a.get("pontuacao", 0)) > int(b.get("pontuacao", 0))
	)
	return students

func _create_student_model_base(source: Dictionary) -> Dictionary:
	return {
		"jogadorId": int(source.get("jogadorId", source.get("id", 0))),
		"nome": str(source.get("nome", source.get("aluno", "Aluno"))),
		"pontuacao": 0,
		"pontuacaoBackend": int(source.get("pontuacao", 0)),
		"acertos": 0,
		"erros": 0,
		"respostas": 0,
		"maxFase": int(source.get("faseAtual", 0)),
		"casaAtual": max(1, int(source.get("casaAtual", 1))),
		"statusPartida": _normalize_student_status(str(source.get("statusPartida", source.get("status", STUDENT_STATUS_AGUARDANDO)))),
		"estadoAtualBackend": false,
		"ultimaRespostaRaw": "",
	}

func _summarize_student_states(models: Array[Dictionary]) -> Dictionary:
	# Conta os tres estados exibidos nos cards do dashboard.
	var summary := {
		STUDENT_STATUS_AGUARDANDO: 0,
		STUDENT_STATUS_JOGANDO: 0,
		STUDENT_STATUS_FINALIZADO: 0,
	}
	# Cada aluno incrementa exatamente o estado normalizado correspondente.
	for item in models:
		var status: String = _normalize_student_status(str(item.get("status", STUDENT_STATUS_AGUARDANDO)))
		# Guarda contra status desconhecido que nao pertence ao resumo.
		if summary.has(status):
			summary[status] = int(summary[status]) + 1
	return summary

func _normalize_student_status(status: String) -> String:
	var normalized := status.strip_edges().to_lower()
	match normalized:
		STUDENT_STATUS_FINALIZADO:
			return STUDENT_STATUS_FINALIZADO
		STUDENT_STATUS_JOGANDO:
			return STUDENT_STATUS_JOGANDO
		STUDENT_STATUS_INICIADO, STUDENT_STATUS_AGUARDANDO:
			return STUDENT_STATUS_AGUARDANDO
		_:
			return STUDENT_STATUS_AGUARDANDO

func _get_student_status_label(status: String) -> String:
	match _normalize_student_status(status):
		STUDENT_STATUS_FINALIZADO:
			return "Finalizado"
		STUDENT_STATUS_JOGANDO:
			return "Jogando"
		_:
			return "Iniciado"

func _normalize_answer_list(payload: Variant) -> Array[Dictionary]:
	return _extract_dictionary_array(payload)

func _refresh_question_bank() -> void:
	# Impede duas consultas simultaneas do mesmo banco.
	if carregando_banco_perguntas:
		return
	# Sem sala limpa dados e solicita ao professor escolher um contexto.
	if not ProfessorSession.has_current_room():
		banco_perguntas.clear()
		_populate_question_filters()
		_render_question_bank()
		_set_question_bank_feedback("Selecione uma sala para carregar seu banco de perguntas.", STATUS_INFO)
		return

	var requested_room_id := ProfessorSession.current_room_id
	carregando_banco_perguntas = true
	_update_question_bank_controls_state()
	_set_question_bank_feedback("Atualizando as perguntas da sala selecionada...", STATUS_INFO)
	var response: Dictionary = await ApiClient.fetch_questions(requested_room_id)
	carregando_banco_perguntas = false
	_update_question_bank_controls_state()
	# Troca de sala durante o await descarta a resposta antiga.
	if not ProfessorSession.has_current_room() or ProfessorSession.current_room_id != requested_room_id:
		return

	# Falha zera o snapshot para nao exibir perguntas desatualizadas como atuais.
	if not response.get("ok", false):
		banco_perguntas.clear()
		_render_question_bank()
		_set_question_bank_feedback(response.get("error", "Nao foi possivel carregar o banco de perguntas."), STATUS_ERROR)
		return

	banco_perguntas = _normalize_questions(response.get("data", []))
	_populate_question_filters()
	_render_question_bank()
	# Contagem de perguntas atualiza os cards vazios ou o dashboard ja carregado.
	if dashboard_payload.is_empty():
		_render_empty_dashboard()
	# Quando existem indicadores, renderiza novamente preservando os demais dados.
	else:
		_render_dashboard_data(dashboard_payload)

func _normalize_questions(raw_questions: Variant) -> Array[Dictionary]:
	var normalized: Array[Dictionary] = []
	# Payload que nao e lista nao contem um banco valido.
	if raw_questions is not Array:
		return normalized

	# Normaliza tipos e defaults de cada pergunta recebida.
	for item in raw_questions:
		# Ignora itens malformados sem perder os demais.
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
	# Preserva selecoes atuais enquanto recompila valores unicos do banco.
	var selected_materia := _get_selected_option_metadata(filtro_materia_perguntas)
	var selected_dificuldade := _get_selected_option_metadata(filtro_dificuldade_perguntas)

	var materias := {}
	var dificuldades := {}
	# Coleta materias e dificuldades distintas sem duplicacao.
	for question in banco_perguntas:
		var materia := str(question.get("materia", "")).strip_edges()
		var dificuldade := str(question.get("dificuldade", "")).strip_edges()
		# Materia vazia nao vira uma opcao de filtro sem nome.
		if not materia.is_empty():
			materias[materia] = true
		# Dificuldade vazia tambem e omitida do seletor.
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
	# Adiciona valores em ordem alfabetica para facilitar localizacao.
	for value in sorted_values:
		option_button.add_item(str(value))
		option_button.set_item_metadata(option_button.item_count - 1, str(value))
	_select_option_button_by_metadata(option_button, selected_value)

func _select_option_button_by_metadata(option_button: OptionButton, expected: String) -> void:
	# Procura a metadata anteriormente selecionada apos reconstruir o controle.
	for index in range(option_button.item_count):
		# Ao encontrar, seleciona e encerra a busca.
		if str(option_button.get_item_metadata(index)) == expected:
			option_button.select(index)
			return
	option_button.select(0)

func _get_selected_option_metadata(option_button: OptionButton) -> String:
	# Controle vazio representa filtro neutro.
	if option_button.item_count == 0:
		return ""
	var selected := option_button.selected
	# Indice invalido tambem volta ao filtro neutro.
	if selected < 0 or selected >= option_button.item_count:
		return ""
	return str(option_button.get_item_metadata(selected))

func _on_question_filter_changed(_unused: Variant = null) -> void:
	_render_question_bank()

func _get_filtered_question_entries() -> Array[Dictionary]:
	# Aplica busca textual, materia e dificuldade em conjunto.
	var filtered: Array[Dictionary] = []
	var search_term := input_busca_perguntas.text.strip_edges().to_lower()
	var materia_filter := _get_selected_option_metadata(filtro_materia_perguntas)
	var dificuldade_filter := _get_selected_option_metadata(filtro_dificuldade_perguntas)

	# Avalia cada pergunta mantendo seu indice original para edicao/exclusao.
	for index in range(banco_perguntas.size()):
		var question: Dictionary = banco_perguntas[index]
		var composite := "%s %s %s" % [
			str(question.get("titulo", "")),
			str(question.get("enunciado", "")),
			str(question.get("materia", "")),
		]
		# Busca nao encontrada elimina o item antes dos outros filtros.
		if not search_term.is_empty() and composite.to_lower().find(search_term) == -1:
			continue
		# Materia selecionada exige correspondencia exata.
		if not materia_filter.is_empty() and str(question.get("materia", "")) != materia_filter:
			continue
		# Dificuldade selecionada exige correspondencia exata.
		if not dificuldade_filter.is_empty() and str(question.get("dificuldade", "")) != dificuldade_filter:
			continue
		filtered.append({
			"index": index,
			"question": question,
		})
	return filtered

func _render_question_bank() -> void:
	# Renderiza o snapshot filtrado e estados vazios distintos.
	_clear_container(lista_banco_perguntas)
	_update_question_count_badge()
	var entries: Array[Dictionary] = _get_filtered_question_entries()

	# Banco realmente vazio sugere importar ou gerar conteudo.
	if banco_perguntas.is_empty():
		_set_question_bank_feedback("Nenhuma pergunta salva no banco ainda.", COLOR_MUTED)
		lista_banco_perguntas.add_child(_create_empty_state_panel("Banco vazio", "Importe uma planilha ou aprove perguntas geradas pela IA para comecar a montar seu banco oficial."))
		return

	# Banco com itens, mas sem correspondencia, indica filtros restritivos.
	if entries.is_empty():
		_set_question_bank_feedback("Nenhuma pergunta combina com os filtros aplicados.", STATUS_WARNING)
		lista_banco_perguntas.add_child(_create_empty_state_panel("Sem resultados", "Tente limpar a busca ou ajustar os filtros de materia e dificuldade."))
		return

	_set_question_bank_feedback("%d perguntas visiveis para revisao." % entries.size(), COLOR_TEXT)
	# Cada resultado filtrado vira um card editavel.
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
	# Badge de tempo aparece apenas quando existe limite configurado.
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
	delete_button.text = "Eliminar"
	delete_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_apply_button_palette(delete_button, STATUS_ERROR, _shade_color(STATUS_ERROR, 0.22))
	delete_button.pressed.connect(_on_bank_question_delete_pressed.bind(index))
	action_row.add_child(delete_button)

	var question_id: int = int(question.get("id", index))
	var expanded := expanded_bank_question_ids.has(question_id)
	_set_question_card_expanded(detail_container, action_row, toggle_button, expanded)
	toggle_button.pressed.connect(_on_bank_card_toggle_pressed.bind(question_id))
	return card

# Alterna a abertura de um card sem perder o estado dos demais cards do banco.
func _on_bank_card_toggle_pressed(question_id: int) -> void:
	# Remove o identificador quando o card ja esta aberto para que ele seja recolhido.
	if expanded_bank_question_ids.has(question_id):
		expanded_bank_question_ids.erase(question_id)
	# Registra o identificador quando o card ainda esta fechado para exibir seus detalhes.
	else:
		expanded_bank_question_ids[question_id] = true
	_render_question_bank()

# Abre todos os cards das perguntas atualmente carregadas no banco.
func _on_botao_expandir_todas_pressed() -> void:
	expanded_bank_question_ids.clear()
	# Registra cada pergunta pelo ID para que a renderizacao considere todos os cards abertos.
	for question in banco_perguntas:
		expanded_bank_question_ids[int(question.get("id", 0))] = true
	_render_question_bank()

# Fecha todos os cards ao limpar o conjunto de identificadores expandidos.
func _on_botao_recolher_todas_pressed() -> void:
	expanded_bank_question_ids.clear()
	_render_question_bank()

# Mantem detalhes, acoes e texto do botao coerentes com o estado aberto ou fechado do card.
func _set_question_card_expanded(detail_container: VBoxContainer, action_row: HBoxContainer, toggle_button: Button, expanded: bool) -> void:
	detail_container.visible = expanded
	action_row.visible = expanded
	toggle_button.text = "Recolher" if expanded else "Expandir"
	_apply_button_palette(toggle_button, COLOR_SURFACE, COLOR_BORDER, COLOR_TEXT)

# Atualiza no modelo local um campo de texto simples editado no card da pergunta.
func _on_bank_question_text_changed(new_text: String, index: int, field_name: String) -> void:
	# Ignora eventos atrasados de controles cujo indice nao existe mais apos uma nova renderizacao.
	if not _has_bank_question(index):
		return
	banco_perguntas[index][field_name] = new_text.strip_edges()

# Atualiza no modelo local um campo de texto multilinha editado no card.
func _on_bank_question_text_edit_changed(index: int, field_name: String, text_edit: TextEdit) -> void:
	# Ignora eventos atrasados de controles cujo indice nao existe mais apos uma nova renderizacao.
	if not _has_bank_question(index):
		return
	banco_perguntas[index][field_name] = text_edit.text.strip_edges()

# Armazena no modelo local a opcao escolhida em um seletor da pergunta.
func _on_bank_question_option_selected(selected_index: int, index: int, field_name: String, option_button: OptionButton) -> void:
	# Ignora eventos atrasados de controles cujo indice nao existe mais apos uma nova renderizacao.
	if not _has_bank_question(index):
		return
	banco_perguntas[index][field_name] = option_button.get_item_text(selected_index)

# Converte o valor numerico do controle para inteiro antes de atualizar o modelo local.
func _on_bank_question_number_changed(value: float, index: int, field_name: String) -> void:
	# Ignora eventos atrasados de controles cujo indice nao existe mais apos uma nova renderizacao.
	if not _has_bank_question(index):
		return
	banco_perguntas[index][field_name] = int(round(value))

# Valida e persiste somente a pergunta correspondente ao card acionado.
func _on_bank_question_save_pressed(index: int) -> void:
	# Impede salvamentos concorrentes e eventos de cards que deixaram de existir.
	if carregando_banco_perguntas or not _has_bank_question(index):
		return
	var question: Dictionary = banco_perguntas[index]
	var validation_error := _validate_question_payload(question, index + 1)
	# Interrompe antes da API quando algum campo viola as regras minimas da pergunta.
	if not validation_error.is_empty():
		_set_question_bank_feedback(validation_error, STATUS_ERROR)
		return

	carregando_banco_perguntas = true
	_update_question_bank_controls_state()
	_set_question_bank_feedback("Salvando alteracoes de %s..." % _question_title(question), STATUS_INFO)
	var sala_id := ProfessorSession.current_room_id if ProfessorSession.has_current_room() else 0
	# Exige uma sala ativa porque toda pergunta deve permanecer isolada em seu banco de origem.
	if sala_id <= 0:
		carregando_banco_perguntas = false
		_update_question_bank_controls_state()
		_set_question_bank_feedback("Selecione uma sala antes de salvar a pergunta.", STATUS_ERROR)
		return
	var response: Dictionary = await ApiClient.update_question(int(question.get("id", 0)), sala_id, _build_question_payload(question))
	carregando_banco_perguntas = false
	_update_question_bank_controls_state()

	# Mantem a edicao na tela e apresenta o erro quando o backend rejeita a atualizacao.
	if not response.get("ok", false):
		_set_question_bank_feedback(response.get("error", "Nao foi possivel salvar a pergunta."), STATUS_ERROR)
		return

	_set_question_bank_feedback("%s atualizada com sucesso." % _question_title(question), STATUS_OK)
	await _refresh_question_bank()

# Prepara a confirmacao para exclusao logica de uma unica pergunta da sala atual.
func _on_bank_question_delete_pressed(index: int) -> void:
	# Ignora a acao durante outra operacao ou quando o card ja nao corresponde a uma pergunta valida.
	if carregando_banco_perguntas or not _has_bank_question(index):
		return
	var sala_id := ProfessorSession.current_room_id if ProfessorSession.has_current_room() else 0
	# Nao permite excluir sem sala, evitando que uma pergunta de outro banco seja atingida.
	if sala_id <= 0:
		_set_question_bank_feedback("Selecione uma sala antes de eliminar a pergunta.", STATUS_ERROR)
		return

	var question: Dictionary = banco_perguntas[index]
	pergunta_exclusao_id = int(question.get("id", 0))
	pergunta_exclusao_sala_id = sala_id
	pergunta_exclusao_todas = false
	confirmacao_apagar_perguntas.title = "Eliminar pergunta"
	confirmacao_apagar_perguntas.ok_button_text = "Eliminar pergunta"
	confirmacao_apagar_perguntas.dialog_text = "Tem certeza que deseja eliminar '%s' da sala %s (%s)?\n\nA pergunta deixara de aparecer no banco e no jogo. Salas, alunos, ranking e historico de respostas serao preservados." % [
		_question_title(question),
		ProfessorSession.current_room_name,
		ProfessorSession.current_room_code,
	]
	confirmacao_apagar_perguntas.popup_centered()

# Prepara uma confirmacao explicita antes de excluir todas as perguntas ativas da sala selecionada.
func _on_botao_eliminar_perguntas_pressed() -> void:
	# Desabilita a exclusao quando ha operacao em curso, banco vazio ou nenhuma sala selecionada.
	if carregando_banco_perguntas or banco_perguntas.is_empty() or not ProfessorSession.has_current_room():
		return

	pergunta_exclusao_id = 0
	pergunta_exclusao_sala_id = ProfessorSession.current_room_id
	pergunta_exclusao_todas = true
	confirmacao_apagar_perguntas.title = "Eliminar perguntas da sala"
	confirmacao_apagar_perguntas.ok_button_text = "Eliminar %d perguntas" % banco_perguntas.size()
	confirmacao_apagar_perguntas.dialog_text = "Tem certeza que deseja eliminar as %d perguntas ativas da sala %s (%s)?\n\nElas deixarao de aparecer no banco e no jogo. A sala, os alunos, o ranking e todo o historico de respostas serao preservados." % [
		banco_perguntas.size(),
		ProfessorSession.current_room_name,
		ProfessorSession.current_room_code,
	]
	confirmacao_apagar_perguntas.popup_centered()

# Direciona a confirmacao para exclusao individual ou em lote conforme a acao que abriu o dialogo.
func _on_confirmacao_apagar_perguntas_confirmed() -> void:
	# Descarta confirmacoes atrasadas e requisicoes sem uma sala de destino valida.
	if carregando_banco_perguntas or pergunta_exclusao_sala_id <= 0:
		return
	# Usa o fluxo em lote quando o professor confirmou a limpeza completa da sala.
	if pergunta_exclusao_todas:
		await _eliminar_todas_perguntas_confirmadas()
	# Caso contrario, remove somente a pergunta registrada no momento da abertura do dialogo.
	else:
		await _eliminar_pergunta_confirmada()
	pergunta_exclusao_id = 0
	pergunta_exclusao_sala_id = 0
	pergunta_exclusao_todas = false

# Executa a exclusao logica de uma pergunta e atualiza banco e indicadores sem apagar o historico.
func _eliminar_pergunta_confirmada() -> void:
	var question_id := pergunta_exclusao_id
	var sala_id := pergunta_exclusao_sala_id
	# Cancela quando o dialogo nao preservou um identificador de pergunta valido.
	if question_id <= 0:
		return

	carregando_banco_perguntas = true
	_update_question_bank_controls_state()
	_set_question_bank_feedback("Eliminando a pergunta #%d..." % question_id, STATUS_INFO)
	var response: Dictionary = await ApiClient.delete_question(question_id, sala_id)
	carregando_banco_perguntas = false
	_update_question_bank_controls_state()

	# Mantem os dados locais quando a API nao confirma a exclusao.
	if not response.get("ok", false):
		_set_question_bank_feedback(response.get("error", "Nao foi possivel eliminar a pergunta."), STATUS_ERROR)
		return

	expanded_bank_question_ids.erase(question_id)
	await _refresh_question_bank()
	await _refresh_dashboard()
	_set_question_bank_feedback("Pergunta #%d eliminada. O historico foi preservado." % question_id, STATUS_OK)

# Exclui logicamente todas as perguntas ativas da sala confirmada e preserva seus registros historicos.
func _eliminar_todas_perguntas_confirmadas() -> void:
	var sala_id := pergunta_exclusao_sala_id
	carregando_banco_perguntas = true
	_update_question_bank_controls_state()
	_set_question_bank_feedback("Eliminando as perguntas da sala selecionada...", STATUS_INFO)
	var response: Dictionary = await ApiClient.delete_all_questions(sala_id)
	carregando_banco_perguntas = false
	_update_question_bank_controls_state()

	# Mantem os dados locais quando a API nao confirma a exclusao em lote.
	if not response.get("ok", false):
		_set_question_bank_feedback(response.get("error", "Nao foi possivel eliminar as perguntas da sala."), STATUS_ERROR)
		return

	var total := int(response.get("data", {}).get("total", 0))
	expanded_bank_question_ids.clear()
	await _refresh_question_bank()
	await _refresh_dashboard()
	_set_question_bank_feedback("%d perguntas eliminadas da sala. O historico foi preservado." % total, STATUS_OK)

# Confirma se um indice ainda aponta para uma pergunta do banco carregado.
func _has_bank_question(index: int) -> bool:
	return index >= 0 and index < banco_perguntas.size()

# Remove campos exclusivos da interface e valores opcionais vazios antes de enviar a pergunta a API.
func _build_question_payload(question: Dictionary) -> Dictionary:
	var payload: Dictionary = question.duplicate(true)
	payload.erase("id")
	# Omite o titulo vazio para que o backend aplique sua regra de campo opcional.
	if str(payload.get("titulo", "")).strip_edges().is_empty():
		payload.erase("titulo")
	# Omite tempo zero para que a ausencia de limite seja tratada de forma consistente pelo backend.
	if int(payload.get("tempoLimite", 0)) <= 0:
		payload.erase("tempoLimite")
	return payload

# Aplica no cliente as mesmas validacoes essenciais esperadas pelo cadastro de perguntas.
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
	# Verifica todos os campos textuais obrigatorios e informa exatamente qual pergunta precisa de ajuste.
	for field_name in required_fields:
		# Rejeita valores vazios ou compostos apenas por espacos.
		if str(question.get(field_name, "")).strip_edges().is_empty():
			return "A pergunta %d precisa preencher o campo %s antes de salvar." % [display_index, field_name]

	var resposta_correta := str(question.get("respostaCorreta", "")).strip_edges().to_upper()
	# Limita a resposta correta as quatro alternativas que o jogo consegue apresentar e avaliar.
	if not QUESTION_CORRECT_OPTIONS.has(resposta_correta):
		return "A pergunta %d precisa ter uma resposta correta entre A, B, C ou D." % display_index
	# Exige valor positivo para que uma resposta correta possa contribuir para o ranking.
	if int(question.get("pontuacao", 0)) <= 0:
		return "A pergunta %d precisa ter pontuacao maior que zero." % display_index
	# Aceita zero como ausencia de cronometro, mas nunca um tempo negativo.
	if int(question.get("tempoLimite", 0)) < 0:
		return "A pergunta %d possui tempo limite invalido." % display_index
	return ""

# Centraliza o bloqueio e os rotulos dos controles durante carregamento, importacao ou alteracoes no banco.
func _update_question_bank_controls_state() -> void:
	botao_atualizar_perguntas.disabled = carregando or carregando_banco_perguntas or importando_perguntas
	botao_atualizar_perguntas.text = "Atualizando..." if carregando_banco_perguntas else "Atualizar Banco"
	botao_expandir_todas.disabled = banco_perguntas.is_empty()
	botao_recolher_todas.disabled = banco_perguntas.is_empty()
	botao_eliminar_perguntas.disabled = carregando or carregando_banco_perguntas or banco_perguntas.is_empty() or not ProfessorSession.has_current_room()
	botao_baixar_modelo.disabled = carregando or importando_perguntas
	import_room_selector.disabled = carregando or carregando_banco_perguntas or importando_perguntas or salas.is_empty()
	botao_importar.disabled = carregando or carregando_banco_perguntas or importando_perguntas or salas.is_empty()
	botao_baixar_modelo.text = "Preparando..." if carregando or importando_perguntas else "Baixar Modelo"
	botao_importar.text = "Importando..." if importando_perguntas else "Selecionar Planilha"

# Mostra quantas perguntas passam pelos filtros em relacao ao total carregado da sala.
func _update_question_count_badge() -> void:
	# Durante a requisicao, troca a contagem por um estado que nao sugira dados definitivos.
	if carregando_banco_perguntas:
		contador_banco_perguntas.text = "Atualizando..."
		return
	var visible_count := _get_filtered_question_entries().size()
	contador_banco_perguntas.text = "%d de %d perguntas" % [visible_count, banco_perguntas.size()]

# Exibe o retorno da ultima operacao e recalcula o contador do banco.
func _set_question_bank_feedback(message: String, color_value: Color) -> void:
	resumo_banco_perguntas.text = message
	resumo_banco_perguntas.add_theme_color_override("font_color", color_value)
	_update_question_count_badge()

# Solicita novamente as perguntas ativas da sala selecionada.
func _on_botao_atualizar_banco_perguntas_pressed() -> void:
	await _refresh_question_bank()

# Abre a escolha de planilha somente depois de fixar uma sala valida como destino da importacao.
func _on_botao_importar_pressed() -> void:
	# Evita abrir dialogos concorrentes ou usar um dialogo que ainda nao foi criado.
	if carregando or importando_perguntas or import_dialog == null:
		return
	importacao_sala_id = _get_question_target_room_id(import_room_selector)
	# Exige a sala antes do arquivo para impedir a importacao em um banco indefinido.
	if importacao_sala_id <= 0:
		_set_import_feedback("Selecione uma sala de destino antes de importar.", STATUS_ERROR)
		return
	_set_import_feedback("Selecione uma planilha .csv ou .xlsx para importar perguntas.", STATUS_INFO)
	import_dialog.popup_centered_ratio(0.72)

# Abre o seletor de destino para salvar uma copia do modelo CSV compativel com a importacao.
func _on_botao_baixar_modelo_pressed() -> void:
	# Evita abrir o dialogo enquanto outra operacao utiliza os controles de importacao.
	if carregando or importando_perguntas or template_download_dialog == null:
		return
	_set_import_feedback("Escolha onde salvar o modelo de planilha.", STATUS_INFO)
	template_download_dialog.current_file = TEMPLATE_SPREADSHEET_FILENAME
	template_download_dialog.popup_centered_ratio(0.72)

# Grava o cabecalho e um exemplo do modelo CSV no caminho escolhido pelo professor.
func _on_template_download_file_selected(path: String) -> void:
	var target_path := path if path.get_extension().to_lower() == "csv" else "%s.csv" % path
	var target_file := FileAccess.open(target_path, FileAccess.WRITE)
	# Informa falha de permissao ou caminho sem tentar escrever em um arquivo inexistente.
	if target_file == null:
		_set_import_feedback("Nao foi possivel salvar o modelo no local escolhido.", STATUS_ERROR)
		_show_status("Nao foi possivel salvar o modelo no local escolhido.", STATUS_ERROR)
		return

	target_file.store_string("%s\r\n%s\r\n" % [TEMPLATE_SPREADSHEET_HEADER, TEMPLATE_SPREADSHEET_EXAMPLE])
	var write_error := target_file.get_error()
	target_file.close()
	# Trata erros ocorridos durante a gravacao mesmo quando o arquivo foi aberto corretamente.
	if write_error != OK:
		_set_import_feedback("Nao foi possivel concluir a gravacao do modelo.", STATUS_ERROR)
		_show_status("Falha ao gravar o modelo de planilha.", STATUS_ERROR)
		return

	_set_import_feedback("Modelo CSV salvo com sucesso em %s." % target_path.get_file(), STATUS_OK)
	_show_status("Modelo de planilha salvo com sucesso.", STATUS_OK)

# Envia a planilha selecionada para a API e atualiza o banco quando a importacao pertence a sala visivel.
func _on_import_file_selected(path: String) -> void:
	# Impede que dois arquivos sejam enviados ao mesmo tempo.
	if importando_perguntas:
		return
	# Revalida a sala capturada antes de abrir o seletor para evitar destino obsoleto ou inexistente.
	if importacao_sala_id <= 0:
		_set_import_feedback("A sala de destino da importacao nao e valida.", STATUS_ERROR)
		return

	importando_perguntas = true
	_update_question_bank_controls_state()
	_update_ia_controls_state()
	_set_import_feedback("Importando perguntas para o banco de dados...", STATUS_INFO)
	_show_status("Importando perguntas para o banco de dados...", STATUS_INFO)
	var response: Dictionary = await ApiClient.import_questions_spreadsheet(path, importacao_sala_id)
	importando_perguntas = false
	_update_question_bank_controls_state()
	_update_ia_controls_state()

	# Exibe a mensagem do backend e preserva a lista atual quando a importacao falha.
	if not response.get("ok", false):
		_set_import_feedback(response.get("error", "Nao foi possivel importar a planilha."), STATUS_ERROR)
		_show_status(response.get("error", "Nao foi possivel importar a planilha."), STATUS_ERROR)
		return

	var payload: Dictionary = response.get("data", {})
	var imported_count: int = int(payload.get("total", 0))
	_set_import_feedback("%d perguntas importadas com sucesso." % imported_count, STATUS_OK)
	_show_status("%d perguntas importadas com sucesso." % imported_count, STATUS_OK)
	# Recarrega imediatamente somente se a sala importada ainda e a que o professor esta consultando.
	if ProfessorSession.has_current_room() and ProfessorSession.current_room_id == importacao_sala_id:
		await _refresh_question_bank()

# Atualiza a mensagem dedicada as operacoes de planilha.
func _set_import_feedback(message: String, color_value: Color) -> void:
	importar_feedback.text = message
	importar_feedback.add_theme_color_override("font_color", color_value)

# Valida os parametros, solicita a geracao por IA e mantem as perguntas em revisao antes de salvar.
func _on_botao_gerar_ia_pressed() -> void:
	# Impede uma nova geracao durante requisicao, salvamento ou atualizacao geral do painel.
	if ia_processando or ia_salvando or carregando:
		return

	var tema := ia_tema_input.text.strip_edges()
	var materia := ia_materia_input.text.strip_edges()
	var dificuldade := ""
	# Le a dificuldade somente quando o seletor possui uma opcao valida.
	if ia_dificuldade_select.selected >= 0:
		dificuldade = ia_dificuldade_select.get_item_text(ia_dificuldade_select.selected).strip_edges()
	var quantidade := int(ia_quantidade_input.value)
	var pontuacao := int(ia_pontuacao_input.value)
	var tempo_limite := int(ia_tempo_input.value)
	var sala_id := _get_question_target_room_id(ia_room_selector)

	# Toda geracao precisa de uma sala para que as perguntas aprovadas tenham destino definido.
	if sala_id <= 0:
		_show_ia_validation_error("Selecione uma sala de destino para as perguntas.", ia_room_selector)
		return

	# O tema orienta o conteudo e, por isso, nao pode ser vazio.
	if tema.is_empty():
		_show_ia_validation_error("Informe um tema para gerar perguntas.", ia_tema_input)
		return
	# A materia e obrigatoria para classificar e filtrar as perguntas geradas.
	if materia.is_empty():
		_show_ia_validation_error("Informe uma materia para gerar perguntas.", ia_materia_input)
		return
	# A dificuldade precisa corresponder a uma opcao conhecida pela interface e pela API.
	if dificuldade.is_empty():
		_show_ia_validation_error("Selecione uma dificuldade para a geracao.", ia_dificuldade_select)
		return
	# A API so deve ser acionada quando existe ao menos uma pergunta a gerar.
	if quantidade <= 0:
		_show_ia_validation_error("A quantidade de perguntas deve ser maior que zero.", ia_quantidade_input)
		return
	# Perguntas aprovadas precisam oferecer pontuacao positiva aos alunos.
	if pontuacao <= 0:
		_show_ia_validation_error("A pontuacao por pergunta deve ser maior que zero.", ia_pontuacao_input)
		return
	# Zero representa pergunta sem limite; valores negativos sao invalidos.
	if tempo_limite < 0:
		_show_ia_validation_error("O tempo de resposta nao pode ser negativo.", ia_tempo_input)
		return

	ia_processando = true
	_update_ia_controls_state()
	_show_ia_feedback("Gerando perguntas com IA. Aguarde alguns instantes...", STATUS_INFO)
	_show_status("Gerando perguntas com IA para auditoria...", STATUS_INFO)

	var response: Dictionary = await ApiClient.generate_questions_ai(sala_id, tema, materia, dificuldade, quantidade, pontuacao, tempo_limite)
	ia_processando = false
	_update_ia_controls_state()

	# Mantem a area de revisao intacta e apresenta a falha quando a IA ou a API nao responde corretamente.
	if not response.get("ok", false):
		_show_ia_feedback(response.get("error", "Nao foi possivel gerar perguntas com IA."), STATUS_ERROR)
		_show_status(response.get("error", "Nao foi possivel gerar perguntas com IA."), STATUS_ERROR)
		return

	var payload: Dictionary = response.get("data", {})
	perguntas_geradas = _normalize_generated_questions(payload.get("perguntas", []))
	perguntas_geradas_sala_id = sala_id
	expanded_generated_question_ids.clear()
	_render_generated_questions()
	_show_ia_feedback("%d perguntas foram geradas e estao prontas para revisao." % perguntas_geradas.size(), STATUS_OK)
	_show_status("Perguntas geradas com IA. Revise, aprove ou rejeite cada item.", STATUS_OK)

# Converte a resposta variavel da API em uma lista segura e padronizada para a etapa de auditoria.
func _normalize_generated_questions(raw_questions: Variant) -> Array[Dictionary]:
	var normalized: Array[Dictionary] = []
	# Uma resposta fora do formato de lista nao pode ser transformada em cards de perguntas.
	if raw_questions is not Array:
		return normalized
	# Normaliza cada item individualmente para limitar os tipos e aplicar valores padrao da interface.
	for item in raw_questions:
		# Ignora valores estranhos sem impedir que as demais perguntas validas sejam revisadas.
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

# Reconstroi a lista de previa com uma mensagem vazia ou um card para cada pergunta gerada.
func _render_generated_questions() -> void:
	_clear_container(ia_lista)
	# Explica o proximo passo quando ainda nao existe conteudo gerado para auditar.
	if perguntas_geradas.is_empty():
		ia_lista.add_child(_create_empty_state_panel("Nenhuma previa gerada", "Depois de preencher o formulario e gerar perguntas, elas aparecerao aqui em cards expansivos para revisao."))
		_update_ia_summary()
		return

	# Mantem o indice de cada pergunta associado aos eventos de edicao e aprovacao do respectivo card.
	for index in range(perguntas_geradas.size()):
		ia_lista.add_child(_create_generated_question_card(index, perguntas_geradas[index]))
	_update_ia_summary()

# Monta um card editavel para o professor revisar, aprovar ou rejeitar uma sugestao da IA.
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

# Alterna a abertura de um card gerado e preserva o estado dos demais cards.
func _on_generated_card_toggle_pressed(index: int) -> void:
	# Remove o indice quando a pergunta ja esta expandida para recolher seus detalhes.
	if expanded_generated_question_ids.has(index):
		expanded_generated_question_ids.erase(index)
	# Adiciona o indice quando a pergunta esta fechada para mostrar a area de auditoria.
	else:
		expanded_generated_question_ids[index] = true
	_render_generated_questions()

# Atualiza um campo simples da pergunta gerada enquanto ela ainda esta em revisao local.
func _on_generated_question_text_changed(new_text: String, index: int, field_name: String) -> void:
	# Ignora eventos atrasados de um card removido ou recriado.
	if not _has_generated_question(index):
		return
	perguntas_geradas[index][field_name] = new_text.strip_edges()

# Atualiza um campo multilinha da pergunta gerada enquanto ela ainda esta em revisao local.
func _on_generated_question_text_edit_changed(index: int, field_name: String, text_edit: TextEdit) -> void:
	# Ignora eventos atrasados de um card removido ou recriado.
	if not _has_generated_question(index):
		return
	perguntas_geradas[index][field_name] = text_edit.text.strip_edges()

# Registra a opcao selecionada em um dos campos controlados da pergunta gerada.
func _on_generated_question_option_selected(selected_index: int, index: int, field_name: String, option_button: OptionButton) -> void:
	# Ignora eventos atrasados de um card removido ou recriado.
	if not _has_generated_question(index):
		return
	perguntas_geradas[index][field_name] = option_button.get_item_text(selected_index)

# Arredonda e registra valores numericos editados na previa da pergunta gerada.
func _on_generated_question_number_changed(value: float, index: int, field_name: String) -> void:
	# Ignora eventos atrasados de um card removido ou recriado.
	if not _has_generated_question(index):
		return
	perguntas_geradas[index][field_name] = int(round(value))

# Muda a decisao de auditoria da pergunta e redesenha o card com o novo estado visual.
func _on_generated_question_status_changed(index: int, new_status: String) -> void:
	# Nao altera uma posicao que deixou de existir apos uma nova geracao ou salvamento.
	if not _has_generated_question(index):
		return
	perguntas_geradas[index]["statusAuditoria"] = new_status
	_render_generated_questions()

# Marca de uma vez todas as sugestoes como aprovadas para agilizar a auditoria.
func _on_botao_aprovar_todas_pressed() -> void:
	_set_all_generated_questions_status(IA_STATUS_APPROVED)

# Marca de uma vez todas as sugestoes como rejeitadas sem persisti-las no banco.
func _on_botao_rejeitar_todas_pressed() -> void:
	_set_all_generated_questions_status(IA_STATUS_REJECTED)

# Aplica a mesma decisao de auditoria a todas as perguntas geradas localmente.
func _set_all_generated_questions_status(new_status: String) -> void:
	# Ignora a acao sem previa ou durante operacoes que poderiam concorrer com a alteracao.
	if perguntas_geradas.is_empty() or ia_processando or ia_salvando:
		return
	# Percorre todas as sugestoes para substituir apenas o estado de auditoria.
	for index in range(perguntas_geradas.size()):
		perguntas_geradas[index]["statusAuditoria"] = new_status
	_render_generated_questions()
	_show_ia_feedback("Todas as perguntas foram marcadas como %s." % _get_bulk_status_text(new_status), _status_color(new_status))

# Recalcula o resumo de pendentes, aprovadas e rejeitadas exibido ao professor.
func _update_ia_summary() -> void:
	var pendentes := _count_generated_questions_with_status(IA_STATUS_PENDING)
	var aprovadas := _count_generated_questions_with_status(IA_STATUS_APPROVED)
	var rejeitadas := _count_generated_questions_with_status(IA_STATUS_REJECTED)
	ia_label_resumo.text = "Pendentes: %d | Aprovadas: %d | Rejeitadas: %d" % [pendentes, aprovadas, rejeitadas]
	ia_label_resumo.add_theme_color_override("font_color", COLOR_TEXT)
	_update_ia_controls_state()

# Conta quantas perguntas geradas possuem um estado de auditoria especifico.
func _count_generated_questions_with_status(status: String) -> int:
	var total := 0
	# Examina cada sugestao porque a contagem controla botoes e o resumo da auditoria.
	for question in perguntas_geradas:
		# Incrementa somente quando o estado armazenado corresponde ao estado solicitado.
		if str(question.get("statusAuditoria", IA_STATUS_PENDING)) == status:
			total += 1
	return total

# Bloqueia os campos durante operacoes assincronas e habilita o salvamento apenas com perguntas aprovadas.
func _update_ia_controls_state() -> void:
	var controls_locked := carregando or importando_perguntas or ia_processando or ia_salvando or carregando_banco_perguntas
	ia_tema_input.editable = not controls_locked
	ia_materia_input.editable = not controls_locked
	ia_dificuldade_select.disabled = controls_locked
	ia_room_selector.disabled = controls_locked or salas.is_empty() or not perguntas_geradas.is_empty()
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

# Exibe uma mensagem especifica da area de geracao e auditoria por IA.
func _show_ia_feedback(message: String, color_value: Color) -> void:
	ia_label_feedback.text = message
	ia_label_feedback.add_theme_color_override("font_color", color_value)

# Mostra a regra de validacao violada e direciona o foco ao campo que precisa ser corrigido.
func _show_ia_validation_error(message: String, field: Control) -> void:
	_show_ia_feedback(message, STATUS_ERROR)
	_show_status(message, STATUS_ERROR)
	# Move o foco somente quando o erro esta associado a um controle existente.
	if field != null:
		field.grab_focus()

# Persiste exclusivamente as perguntas que o professor aprovou durante a auditoria.
func _on_botao_salvar_aprovadas_pressed() -> void:
	# Impede salvamento concorrente com outra requisicao da IA.
	if ia_salvando or ia_processando:
		return
	var payload := _build_approved_questions_payload()
	# Nao chama a API quando nenhuma pergunta passou pela aprovacao do professor.
	if payload.is_empty():
		_show_ia_feedback("Nenhuma pergunta aprovada foi selecionada para salvar.", STATUS_ERROR)
		return
	# Revalida a sala capturada na geracao para evitar salvar as sugestoes em destino indefinido.
	if perguntas_geradas_sala_id <= 0:
		_show_ia_feedback("A sala de destino das perguntas geradas nao e valida.", STATUS_ERROR)
		return

	var sala_destino_id := perguntas_geradas_sala_id
	ia_salvando = true
	_update_ia_controls_state()
	_show_ia_feedback("Salvando perguntas aprovadas no banco oficial...", STATUS_INFO)
	_show_status("Salvando perguntas aprovadas...", STATUS_INFO)
	var response: Dictionary = await ApiClient.save_generated_questions(sala_destino_id, payload)
	ia_salvando = false
	_update_ia_controls_state()

	# Preserva a previa para nova tentativa quando o backend rejeita o lote aprovado.
	if not response.get("ok", false):
		_show_ia_feedback(response.get("error", "Nao foi possivel salvar as perguntas aprovadas."), STATUS_ERROR)
		_show_status(response.get("error", "Nao foi possivel salvar as perguntas aprovadas."), STATUS_ERROR)
		return

	var saved_count: int = int(response.get("data", {}).get("total", payload.size()))
	perguntas_geradas.clear()
	perguntas_geradas_sala_id = 0
	# Depois do salvamento, volta o seletor para a sala corrente quando ainda existe uma sessao ativa.
	if ProfessorSession.has_current_room():
		_select_question_target_room(ProfessorSession.current_room_id)
	expanded_generated_question_ids.clear()
	_render_generated_questions()
	_show_ia_feedback("%d perguntas aprovadas foram salvas com sucesso." % saved_count, STATUS_OK)
	_show_status("%d perguntas aprovadas foram salvas no banco." % saved_count, STATUS_OK)
	# Atualiza o banco imediatamente quando as perguntas foram salvas na sala que esta sendo visualizada.
	if ProfessorSession.has_current_room() and ProfessorSession.current_room_id == sala_destino_id:
		await _refresh_question_bank()

# Filtra, valida e limpa os metadados locais antes de montar o lote aprovado para a API.
func _build_approved_questions_payload() -> Array[Dictionary]:
	var payload: Array[Dictionary] = []
	# Preserva a ordem visual para que mensagens de validacao indiquem o numero correto do card.
	for index in range(perguntas_geradas.size()):
		var question: Dictionary = perguntas_geradas[index]
		# Ignora pendentes e rejeitadas porque somente a aprovacao explicita autoriza a persistencia.
		if str(question.get("statusAuditoria", IA_STATUS_PENDING)) != IA_STATUS_APPROVED:
			continue
		var validation_error := _validate_question_payload(question, index + 1)
		# Interrompe todo o lote quando uma aprovada ainda viola as regras obrigatorias.
		if not validation_error.is_empty():
			_show_ia_feedback(validation_error, STATUS_ERROR)
			return []
		var question_payload: Dictionary = question.duplicate(true)
		question_payload.erase("statusAuditoria")
		# Remove o titulo vazio porque ele e opcional no contrato do backend.
		if str(question_payload.get("titulo", "")).strip_edges().is_empty():
			question_payload.erase("titulo")
		# Remove tempo zero para representar corretamente uma pergunta sem limite configurado.
		if int(question_payload.get("tempoLimite", 0)) <= 0:
			question_payload.erase("tempoLimite")
		payload.append(question_payload)
	return payload

# Confirma se um indice ainda aponta para uma sugestao da IA em memoria.
func _has_generated_question(index: int) -> bool:
	return index >= 0 and index < perguntas_geradas.size()

# Traduz o estado interno de auditoria para o rotulo apresentado no card.
func _get_ia_status_label(status: String) -> String:
	match status:
		IA_STATUS_APPROVED:
			return "Aprovada"
		IA_STATUS_REJECTED:
			return "Rejeitada"
		_:
			return "Pendente"

# Traduz o estado interno para a forma plural usada no retorno de acoes em lote.
func _get_bulk_status_text(status: String) -> String:
	match status:
		IA_STATUS_APPROVED:
			return "aprovadas"
		IA_STATUS_REJECTED:
			return "rejeitadas"
		_:
			return "pendentes"

# Define a cor semantica compartilhada pelos estados de auditoria.
func _status_color(status: String) -> Color:
	match status:
		IA_STATUS_APPROVED:
			return STATUS_OK
		IA_STATUS_REJECTED:
			return STATUS_ERROR
		_:
			return STATUS_WARNING

# Produz um fundo suave a partir da cor semantica do estado da pergunta.
func _status_surface_color(status: String) -> Color:
	return _tint_color(_status_color(status), 0.92)

# Destaca o botao correspondente ao estado atual e suaviza as demais opcoes.
func _button_bg_for_status(target_status: String, current_status: String) -> Color:
	return _status_color(target_status) if target_status == current_status else _tint_color(_status_color(target_status), 0.92)

# Garante contraste do texto conforme o botao represente ou nao o estado selecionado.
func _button_text_for_status(target_status: String, current_status: String) -> Color:
	return Color(1.0, 1.0, 1.0, 1.0) if target_status == current_status else _shade_color(_status_color(target_status), 0.28)

# Encerra a sessao do professor e interrompe atualizacoes antes de voltar ao acesso.
func _on_botao_sair_pressed() -> void:
	panel_exiting = true
	_stop_dashboard_auto_refresh()
	ProfessorSession.clear_session()
	get_tree().change_scene_to_file("res://scene/acesso_professor.tscn")

# Cria um campo de texto curto com rotulo e conecta seu evento ao modelo correspondente.
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

# Cria um campo multilinha com rotulo para enunciados e outros textos extensos.
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

# Cria um seletor rotulado e seleciona o valor atual antes de conectar o callback.
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
	# Adiciona todas as opcoes permitidas ao controle na mesma ordem recebida.
	for option in options:
		option_button.add_item(option)
	_select_option_button_by_text(option_button, current_value)
	option_button.item_selected.connect(callback.bind(option_button))
	wrapper.add_child(option_button)
	return wrapper

# Cria um campo numerico rotulado dentro dos limites aceitos pela regra correspondente.
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

# Seleciona no controle a opcao que corresponde ao valor atual ou usa a primeira como alternativa segura.
func _select_option_button_by_text(option_button: OptionButton, current_value: String) -> void:
	# Compara o texto de cada item porque os valores persistidos sao nomes, nao indices da interface.
	for item_index in range(option_button.item_count):
		# Encerra assim que encontra a opcao equivalente para nao substituir a selecao correta.
		if option_button.get_item_text(item_index) == current_value:
			option_button.select(item_index)
			return
	# Quando o valor atual nao existe, seleciona a primeira opcao somente se o controle nao estiver vazio.
	if option_button.item_count > 0:
		option_button.select(0)

# Configura um campo numerico inteiro e impede valores fora dos limites definidos pela tela.
func _configure_spin_box(spin_box: SpinBox, min_value: float, max_value: float, default_value: float) -> void:
	spin_box.min_value = min_value
	spin_box.max_value = max_value
	spin_box.step = 1
	spin_box.value = default_value
	spin_box.allow_greater = false
	spin_box.allow_lesser = false
	spin_box.rounded = true
	spin_box.custom_minimum_size = Vector2(0, 42)

# Monta um aviso reutilizavel para secoes que ainda nao possuem dados a exibir.
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

# Cria um selo compacto usado para comunicar status e metadados dos registros.
func _create_inline_badge(text_value: String, background: Color, border: Color, text_color: Color = COLOR_TEXT) -> PanelContainer:
	var badge := PanelContainer.new()
	_apply_surface_panel(badge, background, border, 999, 0.0)
	var label := Label.new()
	label.text = text_value
	UITheme.apply_font_only(label, 13)
	label.add_theme_color_override("font_color", text_color)
	badge.add_child(label)
	return badge

# Retorna o titulo informado ou um identificador previsivel para perguntas sem titulo opcional.
func _question_title(question: Dictionary) -> String:
	var title := str(question.get("titulo", "")).strip_edges()
	# Prioriza o titulo editorial quando o professor o preencheu.
	if not title.is_empty():
		return title
	return "Pergunta #%d" % int(question.get("id", 0))

# Encurta textos longos sem modificar o valor original mantido no modelo.
func _truncate_text(value: String, max_length: int) -> String:
	var normalized := value.strip_edges()
	# Mantem o texto completo quando ele ja cabe no limite visual solicitado.
	if normalized.length() <= max_length:
		return normalized
	return "%s..." % normalized.substr(0, max_length)

# Extrai apenas dicionarios de uma resposta variavel para proteger as rotinas que esperam registros estruturados.
func _extract_dictionary_array(payload: Variant) -> Array[Dictionary]:
	var extracted: Array[Dictionary] = []
	# Retorna uma colecao vazia quando a API nao entrega uma lista.
	if payload is not Array:
		return extracted
	# Analisa cada item para aproveitar os registros validos mesmo se houver valores inesperados no retorno.
	for item in payload:
		# Adiciona somente dicionarios, que sao o formato usado pelos modelos do painel.
		if item is Dictionary:
			extracted.append(item)
	return extracted

# Converte a data recebida da API em uma representacao curta e legivel no painel.
func _format_datetime(raw_value: Variant) -> String:
	var value := str(raw_value).strip_edges()
	# Evita exibir um campo em branco quando ainda nao existe registro de data.
	if value.is_empty():
		return "Sem registro"
	var normalized := value.replace("T", " ")
	var dot_index := normalized.find(".")
	# Remove a fracao de segundos porque ela nao agrega informacao relevante ao acompanhamento do professor.
	if dot_index != -1:
		normalized = normalized.substr(0, dot_index)
	return normalized

# Associa o status normalizado do aluno a uma cor semantica consistente em todos os cards.
func _get_student_status_color(status: String) -> Color:
	match _normalize_student_status(status):
		STUDENT_STATUS_FINALIZADO:
			return STATUS_OK
		STUDENT_STATUS_JOGANDO:
			return STATUS_INFO
		_:
			return STATUS_WARNING

# Libera todos os controles dinamicos de um container antes de reconstruir uma lista.
func _clear_container(container: Node) -> void:
	# Aceita referencias opcionais para que a limpeza seja segura durante criacao ou destruicao de telas.
	if container == null:
		return
	# Desanexa e agenda a liberacao de cada filho para impedir cards duplicados na proxima renderizacao.
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

# Aplica a aparencia padrao dos paineis de conteudo.
func _apply_surface_panel(panel: PanelContainer, background: Color, border: Color, radius: int, shadow_opacity: float) -> void:
	panel.add_theme_stylebox_override("panel", _create_surface_style(background, border, 1, radius, 16, 14, shadow_opacity))

# Aplica a aparencia compacta e totalmente arredondada dos selos.
func _apply_badge_panel(panel: PanelContainer, background: Color, border: Color) -> void:
	panel.add_theme_stylebox_override("panel", _create_surface_style(background, border, 1, 999, 12, 8, 0.0))

# Constroi um estilo reutilizavel com bordas, espacamento e sombra padronizados.
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

# Aplica aos botoes os estados visualmente coerentes de repouso, foco, clique e bloqueio.
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

# Reutiliza a paleta de botoes nos seletores para manter a identidade visual.
func _apply_option_button_palette(option_button: OptionButton) -> void:
	_apply_button_palette(option_button, COLOR_SURFACE, COLOR_BORDER, COLOR_TEXT)

# Aplica tipografia, borda e cores padrao aos campos de texto curto.
func _apply_line_edit_palette(line_edit: LineEdit) -> void:
	UITheme.apply_font_only(line_edit, 15)
	line_edit.add_theme_stylebox_override("normal", _create_surface_style(COLOR_SURFACE, COLOR_BORDER, 1, 14, 12, 10, 0.0))
	line_edit.add_theme_stylebox_override("focus", _create_surface_style(COLOR_SURFACE, COLOR_ACCENT, 2, 14, 12, 10, 0.0))
	line_edit.add_theme_stylebox_override("read_only", _create_surface_style(COLOR_SURFACE_ALT, COLOR_BORDER, 1, 14, 12, 10, 0.0))
	line_edit.add_theme_color_override("font_color", COLOR_TEXT)
	line_edit.add_theme_color_override("font_placeholder_color", COLOR_MUTED)

# Aplica tipografia, borda e cores padrao aos campos de texto multilinha.
func _apply_text_edit_palette(text_edit: TextEdit) -> void:
	UITheme.apply_font_only(text_edit, 15)
	text_edit.add_theme_stylebox_override("normal", _create_surface_style(COLOR_SURFACE, COLOR_BORDER, 1, 14, 12, 10, 0.0))
	text_edit.add_theme_stylebox_override("focus", _create_surface_style(COLOR_SURFACE, COLOR_ACCENT, 2, 14, 12, 10, 0.0))
	text_edit.add_theme_color_override("font_color", COLOR_TEXT)

# Estiliza o campo de texto interno que representa o valor do controle numerico.
func _apply_spin_box_palette(spin_box: SpinBox) -> void:
	var line_edit := spin_box.get_line_edit()
	# Algumas configuracoes podem nao expor o campo interno; nesse caso, evita acessar uma referencia nula.
	if line_edit != null:
		_apply_line_edit_palette(line_edit)

# Clareia uma cor pela proporcao informada, preservando seu canal de transparencia.
func _tint_color(color_value: Color, amount: float) -> Color:
	return color_value.lerp(Color(1.0, 1.0, 1.0, color_value.a), clampf(amount, 0.0, 1.0))

# Escurece uma cor pela proporcao informada, preservando seu canal de transparencia.
func _shade_color(color_value: Color, amount: float) -> Color:
	return color_value.lerp(Color(0.0, 0.0, 0.0, color_value.a), clampf(amount, 0.0, 1.0))
