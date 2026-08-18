extends Control

const UITheme := preload("res://scripts/UITheme.gd")

@onready var painel_central: Panel = $PainelCentral
@onready var logo: TextureRect = $PainelCentral/MarginContainer/VBoxContainer/Logo
@onready var titulo: Label = $PainelCentral/MarginContainer/VBoxContainer/Titulo
@onready var subtitulo: Label = $PainelCentral/MarginContainer/VBoxContainer/Subtitulo
@onready var botao_aluno: Button = $PainelCentral/MarginContainer/VBoxContainer/BotaoAluno
@onready var botao_professor: Button = $PainelCentral/MarginContainer/VBoxContainer/BotaoProfessor
@onready var botao_configuracao: TextureButton = $BotaoConfiguracao

func _ready() -> void:
	SettingsManager.pause_tree_when_open = false
	SettingsManager.close_menu()
	AudioManager.play_menu_music()
	_apply_visual_refresh()
	_update_responsive_layout()

	botao_aluno.pressed.connect(_on_botao_aluno_pressed)
	botao_professor.pressed.connect(_on_botao_professor_pressed)
	botao_configuracao.pressed.connect(_on_botao_configuracao_pressed)
	botao_aluno.grab_focus()
	if not SettingsManager.font_scale_changed.is_connected(_on_font_scale_changed):
		SettingsManager.font_scale_changed.connect(_on_font_scale_changed)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_update_responsive_layout()

func _apply_visual_refresh() -> void:
	UITheme.apply_surface_panel(painel_central)
	UITheme.apply_font_tree(painel_central)
	UITheme.apply_title(titulo, 40)
	UITheme.apply_subtitle(subtitulo, 16)
	UITheme.apply_button(botao_aluno, UITheme.BUTTON_PRIMARY, 19)
	UITheme.apply_button(botao_professor, UITheme.BUTTON_SECONDARY, 19)
	subtitulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _update_responsive_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var font_scale := SettingsManager.font_scale
	var panel_width := clampf(viewport_size.x * 0.86, 380.0, 520.0 + 120.0 * (font_scale - 1.0))
	var panel_height := clampf(viewport_size.y * 0.88, 520.0, 640.0 + 120.0 * (font_scale - 1.0))

	painel_central.offset_left = -panel_width * 0.5
	painel_central.offset_right = panel_width * 0.5
	painel_central.offset_top = -panel_height * 0.5
	painel_central.offset_bottom = panel_height * 0.5
	painel_central.custom_minimum_size = Vector2(panel_width, panel_height)
	logo.custom_minimum_size = Vector2(0.0, clampf(panel_height * 0.42, 220.0, 285.0))

func _on_font_scale_changed(_value: float) -> void:
	_apply_visual_refresh()
	call_deferred("_update_responsive_layout")

func _on_botao_aluno_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/tela_inicial.tscn")

func _on_botao_professor_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/acesso_professor.tscn")

func _on_botao_configuracao_pressed() -> void:
	SettingsManager.open_menu()
