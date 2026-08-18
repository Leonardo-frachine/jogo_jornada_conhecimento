extends Node

const META_BASE_FONT_SIZE := &"accessibility_base_font_size"
const META_BASE_MIN_HEIGHT := &"accessibility_base_min_height"
const MIN_TOUCH_HEIGHT := 44.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not SettingsManager.font_scale_changed.is_connected(_on_font_scale_changed):
		SettingsManager.font_scale_changed.connect(_on_font_scale_changed)
	if not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)
	call_deferred("refresh_all")

func apply_font_size(control: Control, base_font_size: int) -> void:
	if control == null or base_font_size <= 0:
		return
	control.set_meta(META_BASE_FONT_SIZE, base_font_size)
	_apply_control(control)

func refresh_all() -> void:
	_apply_subtree(get_tree().root)

func _on_font_scale_changed(_value: float) -> void:
	call_deferred("refresh_all")

func _on_node_added(node: Node) -> void:
	if node is Control:
		call_deferred("_apply_new_control", node)

func _apply_new_control(control: Control) -> void:
	if not is_instance_valid(control) or not control.is_inside_tree():
		return
	_apply_subtree(control)

func _apply_subtree(node: Node) -> void:
	if node == null:
		return
	if node is Control and _is_text_control(node as Control):
		_apply_control(node as Control)
	for child in node.get_children():
		_apply_subtree(child)

func _apply_control(control: Control) -> void:
	if not control.has_meta(META_BASE_FONT_SIZE):
		control.set_meta(META_BASE_FONT_SIZE, control.get_theme_font_size("font_size"))

	var base_font_size := maxi(int(control.get_meta(META_BASE_FONT_SIZE, 16)), 1)
	var scaled_font_size := maxi(roundi(float(base_font_size) * SettingsManager.font_scale), 1)
	control.add_theme_font_size_override("font_size", scaled_font_size)

	if control is Button:
		_prepare_button(control as Button, scaled_font_size)
	elif control is LineEdit or control is TextEdit:
		_prepare_input(control, scaled_font_size)
	elif control is Label:
		var label := control as Label
		if label.autowrap_mode != TextServer.AUTOWRAP_OFF:
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

func _prepare_button(button: Button, scaled_font_size: int) -> void:
	button.clip_text = false
	button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	# A largura minima do texto deve participar do layout dos toolbars e grids.
	button.autowrap_mode = TextServer.AUTOWRAP_OFF
	_apply_minimum_height(button, maxf(MIN_TOUCH_HEIGHT, float(scaled_font_size) + 26.0))

func _prepare_input(control: Control, scaled_font_size: int) -> void:
	_apply_minimum_height(control, maxf(MIN_TOUCH_HEIGHT, float(scaled_font_size) + 28.0))

func _apply_minimum_height(control: Control, required_height: float) -> void:
	if not control.has_meta(META_BASE_MIN_HEIGHT):
		control.set_meta(META_BASE_MIN_HEIGHT, control.custom_minimum_size.y)
	var base_height := float(control.get_meta(META_BASE_MIN_HEIGHT, 0.0))
	control.custom_minimum_size.y = maxf(base_height, required_height)

func _is_text_control(control: Control) -> bool:
	return (
		control is Label
		or control is Button
		or control is LineEdit
		or control is TextEdit
		or control is RichTextLabel
	)
