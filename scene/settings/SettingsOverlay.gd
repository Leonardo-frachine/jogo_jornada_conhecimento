extends CanvasLayer
class_name SettingsOverlay

signal menu_opened
signal menu_closed

@onready var root: Control = $Root
@onready var close_backdrop: Button = $Root/CloseBackdrop
@onready var panel: PanelContainer = $Root/CenterContainer/Panel

@onready var master_slider: HSlider = $Root/CenterContainer/Panel/Margin/VBox/AudioSection/Margin/Rows/MasterRow/MasterSlider
@onready var master_value: Label = $Root/CenterContainer/Panel/Margin/VBox/AudioSection/Margin/Rows/MasterRow/MasterValue

@onready var sfx_slider: HSlider = $Root/CenterContainer/Panel/Margin/VBox/AudioSection/Margin/Rows/SfxRow/SfxSlider
@onready var sfx_value: Label = $Root/CenterContainer/Panel/Margin/VBox/AudioSection/Margin/Rows/SfxRow/SfxValue

@onready var music_toggle: Button = $Root/CenterContainer/Panel/Margin/VBox/TogglesSection/Margin/Rows/MusicRow/MusicToggle
@onready var vfx_toggle: Button = $Root/CenterContainer/Panel/Margin/VBox/TogglesSection/Margin/Rows/VfxRow/VfxToggle
@onready var subtitle_toggle: Button = $Root/CenterContainer/Panel/Margin/VBox/TogglesSection/Margin/Rows/SubtitleRow/SubtitleToggle

@onready var reset_button: Button = $Root/CenterContainer/Panel/Margin/VBox/Footer/ResetButton
@onready var close_button: Button = $Root/CenterContainer/Panel/Margin/VBox/Footer/CloseButton

var opened := false
var animating := false
var settings_manager: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	root.visible = false
	close_backdrop.focus_mode = Control.FOCUS_NONE

	settings_manager = get_node_or_null("/root/SettingsManager")
	if settings_manager == null:
		push_error("SettingsManager nao encontrado em /root/SettingsManager. Adicione o script em Project > Project Settings > Autoload.")
		return

	_setup_ranges()
	_connect_signals()
	_bind_feedback(reset_button)
	_bind_feedback(close_button)
	_bind_feedback(music_toggle)
	_bind_feedback(vfx_toggle)
	_bind_feedback(subtitle_toggle)

	settings_manager.settings_loaded.connect(_refresh_ui)
	settings_manager.settings_changed.connect(_refresh_ui)

	_refresh_ui()

func _setup_ranges() -> void:
	master_slider.min_value = 0.0
	master_slider.max_value = 1.0
	master_slider.step = 0.01

	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.step = 0.01

func _connect_signals() -> void:
	close_backdrop.pressed.connect(_on_close_pressed)
	close_button.pressed.connect(_on_close_pressed)
	reset_button.pressed.connect(_on_reset_pressed)

	master_slider.value_changed.connect(_on_master_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)

	music_toggle.toggled.connect(_on_music_toggled)
	vfx_toggle.toggled.connect(_on_vfx_toggled)
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
