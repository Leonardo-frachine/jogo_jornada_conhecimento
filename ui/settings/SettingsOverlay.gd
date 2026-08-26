extends CanvasLayer
class_name SettingsOverlay

# Overlay global de configuracoes; funciona mesmo quando a cena principal esta pausada.
const UITheme := preload("res://scripts/UITheme.gd")
const FONT_SCALE_OPTIONS: Array[float] = [1.0, 1.15, 1.30]

signal menu_opened
signal menu_closed

@onready var root: Control = $Root
@onready var close_backdrop: Button = $Root/CloseBackdrop
@onready var panel: PanelContainer = $Root/CenterContainer/Panel
@onready var title_label: Label = $Root/CenterContainer/Panel/Margin/VBox/Header/Title

var master_slider: HSlider
var master_value: Label
var sfx_slider: HSlider
var sfx_value: Label
var music_toggle: Button
var vfx_toggle: Button
var subtitle_toggle: Button
var font_scale_buttons: Array[Button] = []
var font_scale_group: ButtonGroup
var reset_button: Button
var exit_button: Button
var close_button: Button
var settings_manager: Node = null
var opened := false
var animating := false
var panel_base_size := Vector2(760, 680)

func _ready() -> void:
	# Mantem o menu interativo acima das cenas e inicialmente invisivel.
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	root.visible = false
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	close_backdrop.focus_mode = Control.FOCUS_NONE

	settings_manager = get_node_or_null("/root/SettingsManager")
	# Sem o autoload nao ha estado para exibir nem persistir.
	if settings_manager == null:
		push_error("SettingsManager nao encontrado em /root/SettingsManager.")
		return

	_cache_controls()
	_create_missing_controls_if_needed()
	_apply_visual_refresh()
	_setup_ranges()
	_connect_signals()
	_bind_feedback(reset_button)
	_bind_feedback(exit_button)
	_bind_feedback(close_button)
	_bind_feedback(music_toggle)
	_bind_feedback(vfx_toggle)
	_bind_feedback(subtitle_toggle)
	# Aplica feedback aos tres botoes de escala criados em tempo de execucao.
	for button in font_scale_buttons:
		_bind_feedback(button)

	# Atualiza a interface quando preferencias sao carregadas do disco.
	if not settings_manager.settings_loaded.is_connected(_refresh_ui):
		settings_manager.settings_loaded.connect(_refresh_ui)
	# Reflete qualquer alteracao realizada por outro controle/cena.
	if not settings_manager.settings_changed.is_connected(_refresh_ui):
		settings_manager.settings_changed.connect(_refresh_ui)

	_refresh_ui()
	# Redimensiona o painel junto com desktop, navegador ou dispositivo movel.
	if not get_viewport().size_changed.is_connected(_update_panel_bounds):
		get_viewport().size_changed.connect(_update_panel_bounds)
	call_deferred("_update_panel_bounds")

func _apply_visual_refresh() -> void:
	# Reestiliza cada opcao de fonte de acordo com seu estado selecionado.
	UITheme.apply_overlay_panel(panel)
	UITheme.apply_font_tree(panel)
	UITheme.apply_title(title_label, 30, title_label.get_theme_color("font_color"))
	UITheme.apply_button(reset_button, UITheme.BUTTON_SURFACE, 17)
	UITheme.apply_button(exit_button, UITheme.BUTTON_DANGER, 17)
	UITheme.apply_button(close_button, UITheme.BUTTON_DANGER, 17)
	# Reaplica o visual ligado/desligado de cada opcao de escala.
	for button in font_scale_buttons:
		UITheme.apply_toggle_button(button, button.button_pressed, 16)

func _cache_controls() -> void:
	master_slider = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/Scroll/Content/AudioSection/Margin/Rows/MasterRow/MasterSlider")
	master_value = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/Scroll/Content/AudioSection/Margin/Rows/MasterRow/MasterValue")
	sfx_slider = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/Scroll/Content/AudioSection/Margin/Rows/SfxRow/SfxSlider")
	sfx_value = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/Scroll/Content/AudioSection/Margin/Rows/SfxRow/SfxValue")
	music_toggle = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/Scroll/Content/TogglesSection/Margin/Rows/MusicRow/MusicToggle")
	vfx_toggle = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/Scroll/Content/TogglesSection/Margin/Rows/VfxRow/VfxToggle")
	subtitle_toggle = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/Scroll/Content/TogglesSection/Margin/Rows/SubtitleRow/SubtitleToggle")
	reset_button = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/Footer/ResetButton")
	exit_button = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/Footer/ExitButton")
	close_button = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/Footer/CloseButton")

func _create_missing_controls_if_needed() -> void:
	# Controles criados aqui mantem compatibilidade com cenas antigas que nao os continham.
	var master_row: HBoxContainer = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/Scroll/Content/AudioSection/Margin/Rows/MasterRow")
	var sfx_row: HBoxContainer = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/Scroll/Content/AudioSection/Margin/Rows/SfxRow")
	var vfx_row: HBoxContainer = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/Scroll/Content/TogglesSection/Margin/Rows/VfxRow")
	var music_text: Label = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/Scroll/Content/TogglesSection/Margin/Rows/MusicRow/MusicText")
	var toggle_rows: VBoxContainer = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/Scroll/Content/TogglesSection/Margin/Rows")

	# Cria o valor percentual do volume master quando estiver ausente na cena.
	if master_value == null and master_row != null:
		master_value = _make_value_label()
		master_value.name = "MasterValue"
		master_row.add_child(master_value)

	# Cria o valor percentual dos efeitos quando estiver ausente na cena.
	if sfx_value == null and sfx_row != null:
		sfx_value = _make_value_label()
		sfx_value.name = "SfxValue"
		sfx_row.add_child(sfx_value)

	# Monta o toggle de efeitos visuais para layouts anteriores a essa configuracao.
	if vfx_row != null and vfx_toggle == null:
		var label := Label.new()
		label.name = "VfxText"
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "Efeitos Visuais"
		# Copia tipografia do texto de musica para manter as linhas coerentes.
		if music_text != null:
			label.add_theme_font_size_override("font_size", music_text.get_theme_font_size("font_size"))
			label.add_theme_color_override("font_color", music_text.get_theme_color("font_color"))
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		vfx_row.add_child(label)

		vfx_toggle = _make_toggle_button(music_toggle)
		vfx_toggle.name = "VfxToggle"
		vfx_row.add_child(vfx_toggle)

	# A linha de tamanho de fonte e inteiramente dinamica e precisa do container de toggles.
	if toggle_rows != null:
		_create_font_scale_row(toggle_rows, music_text)

func _create_font_scale_row(rows: VBoxContainer, reference_label: Label) -> void:
	# Constroi uma unica linha com label e opcoes mutuamente exclusivas.
	var row := HBoxContainer.new()
	row.name = "FontScaleRow"
	row.add_theme_constant_override("separation", 12)
	rows.add_child(row)

	var label := Label.new()
	label.name = "FontScaleText"
	label.text = "Tamanho do texto"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# Reaproveita a cor da secao quando existe um label de referencia.
	if reference_label != null:
		label.add_theme_color_override("font_color", reference_label.get_theme_color("font_color"))
	UITheme.apply_subtitle(label, 18, Color(0.96, 0.97, 0.98, 1.0))
	row.add_child(label)

	var options := HBoxContainer.new()
	options.name = "FontScaleOptions"
	options.add_theme_constant_override("separation", 6)
	row.add_child(options)
	font_scale_group = ButtonGroup.new()
	# Cada escala homologada ganha um botao ligado ao mesmo ButtonGroup.
	for scale_value in FONT_SCALE_OPTIONS:
		var button := Button.new()
		button.custom_minimum_size = Vector2(96, 40)
		button.toggle_mode = true
		button.button_group = font_scale_group
		button.text = "%d%%" % roundi(scale_value * 100.0)
		button.pressed.connect(_on_font_scale_pressed.bind(scale_value))
		options.add_child(button)
		font_scale_buttons.append(button)

func _make_value_label() -> Label:
	var label := Label.new()
	label.custom_minimum_size = Vector2(62, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	UITheme.apply_subtitle(label, 18, Color(0.96, 0.97, 0.98, 1.0))
	return label

func _make_toggle_button(reference_button: Button) -> Button:
	# O parametro permanece para compatibilidade; o tema compartilhado define a aparencia.
	var button := Button.new()
	button.custom_minimum_size = Vector2(96, 38)
	button.toggle_mode = true
	button.text = "ON"
	UITheme.apply_toggle_button(button, true, 16)
	return button

func _setup_ranges() -> void:
	master_slider.min_value = 0.0
	master_slider.max_value = 1.0
	master_slider.step = 0.01

	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.01

func _connect_signals() -> void:
	# Cada guarda evita callback duplicado caso a configuracao seja refeita.
	if not close_backdrop.pressed.is_connected(_on_close_pressed):
		close_backdrop.pressed.connect(_on_close_pressed)
	# Botao explicito de fechar executa o mesmo fluxo do backdrop.
	if not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)
	# Reset volta todas as preferencias ao padrao.
	if not reset_button.pressed.is_connected(_on_reset_pressed):
		reset_button.pressed.connect(_on_reset_pressed)
	# O botao de sair e opcional em variantes compactas do overlay.
	if exit_button != null and not exit_button.pressed.is_connected(_on_exit_pressed):
		exit_button.pressed.connect(_on_exit_pressed)

	# Sliders atualizam volumes em tempo real.
	if not master_slider.value_changed.is_connected(_on_master_slider_changed):
		master_slider.value_changed.connect(_on_master_slider_changed)
	# Efeitos usam um bus separado do volume geral.
	if not sfx_slider.value_changed.is_connected(_on_sfx_slider_changed):
		sfx_slider.value_changed.connect(_on_sfx_slider_changed)

	# Toggling sincroniza estado visual e persistencia no manager.
	if not music_toggle.toggled.is_connected(_on_music_toggled):
		music_toggle.toggled.connect(_on_music_toggled)
	# Efeitos visuais podem ser desligados independentemente.
	if not vfx_toggle.toggled.is_connected(_on_vfx_toggled):
		vfx_toggle.toggled.connect(_on_vfx_toggled)
	# Legendas possuem preferencia independente para uso futuro nas cenas.
	if not subtitle_toggle.toggled.is_connected(_on_subtitles_toggled):
		subtitle_toggle.toggled.connect(_on_subtitles_toggled)

func is_open() -> bool:
	return opened

func open() -> void:
	# Bloqueia reentrada enquanto aberto ou no meio da animacao.
	if opened or animating:
		return

	opened = true
	animating = true
	root.visible = true
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.modulate = Color(1, 1, 1, 0)
	_update_panel_bounds()
	panel.scale = Vector2(0.98, 0.98)

	_refresh_ui()
	menu_opened.emit()

	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(root, "modulate", Color(1, 1, 1, 1), 0.18)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func() -> void:
		animating = false
		# Ao concluir, move o foco para permitir controle por teclado.
		if master_slider != null:
			master_slider.grab_focus()
	)

func close() -> void:
	# So inicia fechamento quando o painel esta aberto e estavel.
	if not opened or animating:
		return

	opened = false
	animating = true

	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(root, "modulate", Color(1, 1, 1, 0), 0.12)
	tween.parallel().tween_property(panel, "scale", Vector2(0.98, 0.98), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		root.visible = false
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		animating = false
		menu_closed.emit()
	)

func _refresh_ui() -> void:
	# Sem manager nao existem valores confiaveis para preencher os controles.
	if settings_manager == null:
		return

	master_slider.set_value_no_signal(settings_manager.master_volume)
	sfx_slider.set_value_no_signal(settings_manager.sfx_volume)
	music_toggle.set_pressed_no_signal(settings_manager.music_enabled)
	vfx_toggle.set_pressed_no_signal(settings_manager.vfx_enabled)
	subtitle_toggle.set_pressed_no_signal(settings_manager.subtitles_enabled)

	master_value.text = "%d%%" % roundi(settings_manager.master_volume * 100.0)
	sfx_value.text = "%d%%" % roundi(settings_manager.sfx_volume * 100.0)
	music_toggle.text = "ON" if settings_manager.music_enabled else "OFF"
	vfx_toggle.text = "ON" if settings_manager.vfx_enabled else "OFF"
	subtitle_toggle.text = "ON" if settings_manager.subtitles_enabled else "OFF"
	UITheme.apply_toggle_button(music_toggle, settings_manager.music_enabled, 16)
	UITheme.apply_toggle_button(vfx_toggle, settings_manager.vfx_enabled, 16)
	UITheme.apply_toggle_button(subtitle_toggle, settings_manager.subtitles_enabled, 16)
	# Marca a opcao de fonte correspondente e atualiza seu estilo visual.
	for index in range(font_scale_buttons.size()):
		var selected := is_equal_approx(settings_manager.font_scale, FONT_SCALE_OPTIONS[index])
		font_scale_buttons[index].set_pressed_no_signal(selected)
		UITheme.apply_toggle_button(font_scale_buttons[index], selected, 16)

func _on_master_slider_changed(value: float) -> void:
	# Ignora evento se o autoload foi removido durante encerramento.
	if settings_manager == null:
		return
	settings_manager.set_master_volume(value)
	master_value.text = "%d%%" % roundi(value * 100.0)

func _on_sfx_slider_changed(value: float) -> void:
	# Ignora evento se o autoload foi removido durante encerramento.
	if settings_manager == null:
		return
	settings_manager.set_sfx_volume(value)
	sfx_value.text = "%d%%" % roundi(value * 100.0)

func _on_music_toggled(enabled: bool) -> void:
	# Ignora evento se o autoload foi removido durante encerramento.
	if settings_manager == null:
		return
	settings_manager.set_music_enabled(enabled)
	music_toggle.text = "ON" if enabled else "OFF"

func _on_vfx_toggled(enabled: bool) -> void:
	# Ignora evento se o autoload foi removido durante encerramento.
	if settings_manager == null:
		return
	settings_manager.set_vfx_enabled(enabled)
	vfx_toggle.text = "ON" if enabled else "OFF"

func _on_subtitles_toggled(enabled: bool) -> void:
	# Ignora evento se o autoload foi removido durante encerramento.
	if settings_manager == null:
		return
	settings_manager.set_subtitles_enabled(enabled)
	subtitle_toggle.text = "ON" if enabled else "OFF"

func _on_font_scale_pressed(value: float) -> void:
	# Ignora evento se o autoload foi removido durante encerramento.
	if settings_manager == null:
		return
	settings_manager.set_font_scale(value)

func _on_reset_pressed() -> void:
	# Ignora evento se o autoload foi removido durante encerramento.
	if settings_manager == null:
		return
	settings_manager.reset_settings()

func _on_close_pressed() -> void:
	# Ignora evento se o autoload foi removido durante encerramento.
	if settings_manager == null:
		return
	settings_manager.close_menu()

func _on_exit_pressed() -> void:
	# Ignora evento se o autoload foi removido durante encerramento.
	if settings_manager == null:
		return
	settings_manager.return_to_access_screen()

func _update_panel_bounds() -> void:
	# Pode ser chamado por sinal depois que o painel ja saiu da arvore.
	if panel == null:
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var target_width: float = minf(panel_base_size.x, maxf(420.0, viewport_size.x - 72.0))
	var target_height: float = minf(panel_base_size.y, maxf(420.0, viewport_size.y - 64.0))
	panel.custom_minimum_size = Vector2(target_width, target_height)
	panel.pivot_offset = panel.custom_minimum_size * 0.5

	# Fora de uma animacao, garante escala final exata apos redimensionar.
	if opened and not animating:
		panel.scale = Vector2.ONE

func _bind_feedback(control: Control) -> void:
	# Controles opcionais sem instancia nao recebem sinais de hover.
	if control == null:
		return

	control.mouse_entered.connect(func() -> void:
		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(control, "scale", Vector2(1.03, 1.03), 0.08)
	)
	control.mouse_exited.connect(func() -> void:
		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(control, "scale", Vector2.ONE, 0.08)
	)
