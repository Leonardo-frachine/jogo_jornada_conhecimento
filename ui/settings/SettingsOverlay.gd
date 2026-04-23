extends CanvasLayer
class_name SettingsOverlay

signal menu_opened
signal menu_closed

@onready var root: Control = $Root
@onready var close_backdrop: Button = $Root/CloseBackdrop
@onready var panel: PanelContainer = $Root/CenterContainer/Panel

var master_slider: HSlider
var master_value: Label
var sfx_slider: HSlider
var sfx_value: Label
var music_toggle: Button
var vfx_toggle: Button
var subtitle_toggle: Button
var reset_button: Button
var close_button: Button
var settings_manager: Node = null
var opened := false
var animating := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	root.visible = false
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	close_backdrop.focus_mode = Control.FOCUS_NONE

	settings_manager = get_node_or_null("/root/SettingsManager")
	if settings_manager == null:
		push_error("SettingsManager nao encontrado em /root/SettingsManager.")
		return

	_cache_controls()
	_create_missing_controls_if_needed()
	_setup_ranges()
	_connect_signals()
	_bind_feedback(reset_button)
	_bind_feedback(close_button)
	_bind_feedback(music_toggle)
	_bind_feedback(vfx_toggle)
	_bind_feedback(subtitle_toggle)

	if not settings_manager.settings_loaded.is_connected(_refresh_ui):
		settings_manager.settings_loaded.connect(_refresh_ui)
	if not settings_manager.settings_changed.is_connected(_refresh_ui):
		settings_manager.settings_changed.connect(_refresh_ui)

	_refresh_ui()

func _cache_controls() -> void:
	master_slider = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/AudioSection/Margin/Rows/MasterRow/MasterSlider")
	master_value = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/AudioSection/Margin/Rows/MasterRow/MasterValue")
	sfx_slider = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/AudioSection/Margin/Rows/SfxRow/SfxSlider")
	sfx_value = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/AudioSection/Margin/Rows/SfxRow/SfxValue")
	music_toggle = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/TogglesSection/Margin/Rows/MusicRow/MusicToggle")
	vfx_toggle = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/TogglesSection/Margin/Rows/VfxRow/VfxToggle")
	subtitle_toggle = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/TogglesSection/Margin/Rows/SubtitleRow/SubtitleToggle")
	reset_button = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/Footer/ResetButton")
	close_button = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/Footer/CloseButton")

func _create_missing_controls_if_needed() -> void:
	var master_row: HBoxContainer = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/AudioSection/Margin/Rows/MasterRow")
	var sfx_row: HBoxContainer = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/AudioSection/Margin/Rows/SfxRow")
	var vfx_row: HBoxContainer = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/TogglesSection/Margin/Rows/VfxRow")
	var music_text: Label = get_node_or_null("Root/CenterContainer/Panel/Margin/VBox/TogglesSection/Margin/Rows/MusicRow/MusicText")

	if master_value == null and master_row != null:
		master_value = _make_value_label()
		master_value.name = "MasterValue"
		master_row.add_child(master_value)

	if sfx_value == null and sfx_row != null:
		sfx_value = _make_value_label()
		sfx_value.name = "SfxValue"
		sfx_row.add_child(sfx_value)

	if vfx_row != null and vfx_toggle == null:
		var label := Label.new()
		label.name = "VfxText"
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = "Efeitos Visuais"
		if music_text != null:
			label.add_theme_font_size_override("font_size", music_text.get_theme_font_size("font_size"))
			label.add_theme_color_override("font_color", music_text.get_theme_color("font_color"))
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		vfx_row.add_child(label)

		vfx_toggle = _make_toggle_button(music_toggle)
		vfx_toggle.name = "VfxToggle"
		vfx_row.add_child(vfx_toggle)

func _make_value_label() -> Label:
	var label := Label.new()
	label.custom_minimum_size = Vector2(62, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.96, 0.97, 0.98, 1.0))
	return label

func _make_toggle_button(reference_button: Button) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(112, 42)
	button.toggle_mode = true
	button.text = "ON"
	button.add_theme_color_override("font_color", reference_button.get_theme_color("font_color"))
	button.add_theme_color_override("font_pressed_color", reference_button.get_theme_color("font_pressed_color"))
	button.add_theme_color_override("font_hover_color", reference_button.get_theme_color("font_hover_color"))
	button.add_theme_stylebox_override("normal", reference_button.get_theme_stylebox("normal"))
	button.add_theme_stylebox_override("pressed", reference_button.get_theme_stylebox("pressed"))
	button.add_theme_stylebox_override("hover", reference_button.get_theme_stylebox("hover"))
	button.add_theme_stylebox_override("hover_pressed", reference_button.get_theme_stylebox("hover_pressed"))
	return button

func _setup_ranges() -> void:
	master_slider.min_value = 0.0
	master_slider.max_value = 1.0
	master_slider.step = 0.01

	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.01

func _connect_signals() -> void:
	if not close_backdrop.pressed.is_connected(_on_close_pressed):
		close_backdrop.pressed.connect(_on_close_pressed)
	if not close_button.pressed.is_connected(_on_close_pressed):
		close_button.pressed.connect(_on_close_pressed)
	if not reset_button.pressed.is_connected(_on_reset_pressed):
		reset_button.pressed.connect(_on_reset_pressed)

	if not master_slider.value_changed.is_connected(_on_master_slider_changed):
		master_slider.value_changed.connect(_on_master_slider_changed)
	if not sfx_slider.value_changed.is_connected(_on_sfx_slider_changed):
		sfx_slider.value_changed.connect(_on_sfx_slider_changed)

	if not music_toggle.toggled.is_connected(_on_music_toggled):
		music_toggle.toggled.connect(_on_music_toggled)
	if not vfx_toggle.toggled.is_connected(_on_vfx_toggled):
		vfx_toggle.toggled.connect(_on_vfx_toggled)
	if not subtitle_toggle.toggled.is_connected(_on_subtitles_toggled):
		subtitle_toggle.toggled.connect(_on_subtitles_toggled)

func is_open() -> bool:
	return opened

func open() -> void:
	if opened or animating:
		return

	opened = true
	animating = true
	root.visible = true
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.modulate = Color(1, 1, 1, 0)
	panel.scale = Vector2(0.96, 0.96)

	_refresh_ui()
	menu_opened.emit()

	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(root, "modulate", Color(1, 1, 1, 1), 0.18)
	tween.parallel().tween_property(panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func() -> void:
		animating = false
		master_slider.grab_focus()
	)

func close() -> void:
	if not opened or animating:
		return

	opened = false
	animating = true

	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(root, "modulate", Color(1, 1, 1, 0), 0.12)
	tween.parallel().tween_property(panel, "scale", Vector2(0.96, 0.96), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.finished.connect(func() -> void:
		root.visible = false
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		animating = false
		menu_closed.emit()
	)

func _refresh_ui() -> void:
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

func _on_master_slider_changed(value: float) -> void:
	if settings_manager == null:
		return
	settings_manager.set_master_volume(value)
	master_value.text = "%d%%" % roundi(value * 100.0)

func _on_sfx_slider_changed(value: float) -> void:
	if settings_manager == null:
		return
	settings_manager.set_sfx_volume(value)
	sfx_value.text = "%d%%" % roundi(value * 100.0)

func _on_music_toggled(enabled: bool) -> void:
	if settings_manager == null:
		return
	settings_manager.set_music_enabled(enabled)
	music_toggle.text = "ON" if enabled else "OFF"

func _on_vfx_toggled(enabled: bool) -> void:
	if settings_manager == null:
		return
	settings_manager.set_vfx_enabled(enabled)
	vfx_toggle.text = "ON" if enabled else "OFF"

func _on_subtitles_toggled(enabled: bool) -> void:
	if settings_manager == null:
		return
	settings_manager.set_subtitles_enabled(enabled)
	subtitle_toggle.text = "ON" if enabled else "OFF"

func _on_reset_pressed() -> void:
	if settings_manager == null:
		return
	settings_manager.reset_settings()

func _on_close_pressed() -> void:
	if settings_manager == null:
		return
	settings_manager.close_menu()

func _bind_feedback(control: Control) -> void:
	control.mouse_entered.connect(func() -> void:
		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(control, "scale", Vector2(1.03, 1.03), 0.08)
	)
	control.mouse_exited.connect(func() -> void:
		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(control, "scale", Vector2.ONE, 0.08)
	)
