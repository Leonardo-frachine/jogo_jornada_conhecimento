extends RefCounted
class_name UITheme

const FONT_RESOURCE := preload("res://fonts/Fredoka-Bold.ttf")

const TEXT_PRIMARY := Color(0.12, 0.16, 0.27, 1.0)
const TEXT_MUTED := Color(0.31, 0.37, 0.50, 1.0)
const TEXT_INVERSE := Color(0.96, 0.98, 1.0, 1.0)

const BUTTON_PRIMARY := "primary"
const BUTTON_SECONDARY := "secondary"
const BUTTON_SURFACE := "surface"
const BUTTON_DANGER := "danger"
const BUTTON_TAB_ACTIVE := "tab_active"
const BUTTON_TAB_INACTIVE := "tab_inactive"

static func apply_font_only(control: Control, font_size: int = -1) -> void:
	if control == null:
		return

	control.add_theme_font_override("font", FONT_RESOURCE)
	if font_size > 0:
		control.add_theme_font_size_override("font_size", font_size)

static func apply_font_tree(root: Node) -> void:
	if root == null:
		return

	if root is Control:
		apply_font_only(root as Control)

	for child in root.get_children():
		apply_font_tree(child)

static func apply_title(label: Label, font_size: int = 40, color: Color = TEXT_PRIMARY) -> void:
	if label == null:
		return

	apply_font_only(label, font_size)
	label.add_theme_color_override("font_color", color)

static func apply_subtitle(label: Label, font_size: int = 16, color: Color = TEXT_MUTED) -> void:
	if label == null:
		return

	apply_font_only(label, font_size)
	label.add_theme_color_override("font_color", color)

static func apply_field_label(label: Label, font_size: int = 17, color: Color = TEXT_PRIMARY) -> void:
	if label == null:
		return

	apply_font_only(label, font_size)
	label.add_theme_color_override("font_color", color)

static func apply_surface_panel(panel: Control) -> void:
	if panel == null:
		return

	panel.add_theme_stylebox_override("panel", _make_surface_style(
		Color(0.99, 0.96, 0.90, 0.98),
		Color(0.83, 0.62, 0.18, 1.0),
		3,
		28,
		18,
		18,
		Color(0.18, 0.11, 0.03, 0.18),
		18
	))

static func apply_page_shell(panel: Control) -> void:
	if panel == null:
		return

	panel.add_theme_stylebox_override("panel", _make_surface_style(
		Color(0.98, 0.95, 0.90, 0.10),
		Color(0.0, 0.0, 0.0, 0.0),
		0,
		0,
		0,
		0,
		Color(0.0, 0.0, 0.0, 0.0),
		0
	))

static func apply_overlay_panel(panel: Control) -> void:
	if panel == null:
		return

	panel.add_theme_stylebox_override("panel", _make_surface_style(
		Color(0.17, 0.21, 0.30, 0.98),
		Color(0.39, 0.48, 0.69, 1.0),
		2,
		24,
		18,
		18,
		Color(0.0, 0.0, 0.0, 0.30),
		16
	))

static func apply_line_edit(line_edit: LineEdit, font_size: int = 18) -> void:
	if line_edit == null:
		return

	apply_font_only(line_edit, font_size)
	line_edit.add_theme_stylebox_override("normal", _make_surface_style(
		Color(1.0, 1.0, 1.0, 0.98),
		Color(0.78, 0.82, 0.90, 1.0),
		2,
		16,
		18,
		14
	))
	line_edit.add_theme_stylebox_override("focus", _make_surface_style(
		Color(1.0, 1.0, 1.0, 1.0),
		Color(0.34, 0.51, 0.94, 1.0),
		2,
		16,
		18,
		14,
		Color(0.20, 0.32, 0.60, 0.14),
		8
	))
	line_edit.add_theme_stylebox_override("read_only", _make_surface_style(
		Color(0.95, 0.96, 0.99, 0.98),
		Color(0.82, 0.85, 0.92, 1.0),
		2,
		16,
		18,
		14
	))
	line_edit.add_theme_color_override("font_color", TEXT_PRIMARY)
	line_edit.add_theme_color_override("font_placeholder_color", TEXT_MUTED)
	line_edit.add_theme_color_override("caret_color", TEXT_PRIMARY)
	line_edit.add_theme_color_override("selection_color", Color(0.89, 0.93, 1.0, 1.0))

static func apply_button(button: Button, variant: String = BUTTON_PRIMARY, font_size: int = 19) -> void:
	if button == null:
		return

	var scheme := _button_scheme(variant)
	var radius := 18
	var padding_horizontal := 20
	var padding_vertical := 14
	if button.custom_minimum_size.y > 0.0 and button.custom_minimum_size.y <= 46.0:
		radius = 16
		padding_horizontal = 18
		padding_vertical = 12

	apply_font_only(button, font_size)
	button.add_theme_constant_override("h_separation", 10)
	button.add_theme_color_override("font_color", scheme["font"])
	button.add_theme_color_override("font_hover_color", scheme["font"])
	button.add_theme_color_override("font_pressed_color", scheme["font"])
	button.add_theme_color_override("font_focus_color", scheme["font"])
	button.add_theme_color_override("font_disabled_color", scheme["font"].lerp(Color(1.0, 1.0, 1.0, 1.0), 0.35))
	button.add_theme_stylebox_override("normal", _make_surface_style(
		scheme["background"],
		scheme["border"],
		2,
		radius,
		padding_horizontal,
		padding_vertical,
		Color(0.0, 0.0, 0.0, 0.15),
		8
	))
	button.add_theme_stylebox_override("hover", _make_surface_style(
		_tint(scheme["background"], 0.08),
		scheme["border"],
		2,
		radius,
		padding_horizontal,
		padding_vertical,
		Color(0.0, 0.0, 0.0, 0.18),
		10
	))
	button.add_theme_stylebox_override("pressed", _make_surface_style(
		_shade(scheme["background"], 0.10),
		scheme["border"],
		2,
		radius,
		padding_horizontal,
		padding_vertical,
		Color(0.0, 0.0, 0.0, 0.10),
		4
	))
	button.add_theme_stylebox_override("focus", _make_surface_style(
		_tint(scheme["background"], 0.03),
		scheme["border"],
		3,
		radius,
		padding_horizontal,
		padding_vertical,
		Color(0.0, 0.0, 0.0, 0.15),
		8
	))
	button.add_theme_stylebox_override("disabled", _make_surface_style(
		_tint(scheme["background"], 0.22),
		_tint(scheme["border"], 0.18),
		2,
		radius,
		padding_horizontal,
		padding_vertical,
		Color(0.0, 0.0, 0.0, 0.06),
		4
	))

static func apply_toggle_button(button: Button, enabled: bool, font_size: int = 16) -> void:
	if button == null:
		return

	var variant := BUTTON_SECONDARY
	if enabled:
		variant = BUTTON_PRIMARY

	apply_button(button, variant, font_size)

static func _button_scheme(variant: String) -> Dictionary:
	match variant:
		BUTTON_SECONDARY:
			return {
				"background": Color(0.26, 0.35, 0.60, 1.0),
				"border": Color(0.12, 0.16, 0.29, 1.0),
				"font": TEXT_INVERSE,
			}
		BUTTON_SURFACE:
			return {
				"background": Color(0.96, 0.97, 1.0, 1.0),
				"border": Color(0.76, 0.80, 0.89, 1.0),
				"font": TEXT_PRIMARY,
			}
		BUTTON_DANGER:
			return {
				"background": Color(0.84, 0.29, 0.26, 1.0),
				"border": Color(0.46, 0.12, 0.12, 1.0),
				"font": TEXT_INVERSE,
			}
		BUTTON_TAB_ACTIVE:
			return {
				"background": Color(0.99, 0.78, 0.22, 1.0),
				"border": Color(0.50, 0.32, 0.06, 1.0),
				"font": TEXT_PRIMARY,
			}
		BUTTON_TAB_INACTIVE:
			return {
				"background": Color(0.95, 0.97, 1.0, 0.96),
				"border": Color(0.76, 0.80, 0.89, 1.0),
				"font": TEXT_PRIMARY,
			}
		_:
			return {
				"background": Color(0.99, 0.78, 0.22, 1.0),
				"border": Color(0.50, 0.32, 0.06, 1.0),
				"font": TEXT_PRIMARY,
			}

static func _make_surface_style(
	background: Color,
	border: Color,
	border_width: int = 2,
	radius: int = 18,
	padding_horizontal: int = 18,
	padding_vertical: int = 14,
	shadow_color: Color = Color(0.0, 0.0, 0.0, 0.12),
	shadow_size: int = 8
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.border_color = border
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = padding_horizontal
	style.content_margin_top = padding_vertical
	style.content_margin_right = padding_horizontal
	style.content_margin_bottom = padding_vertical
	style.shadow_color = shadow_color
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0, 4)
	return style

static func _tint(color_value: Color, amount: float) -> Color:
	return color_value.lerp(Color(1.0, 1.0, 1.0, color_value.a), clampf(amount, 0.0, 1.0))

static func _shade(color_value: Color, amount: float) -> Color:
	return color_value.lerp(Color(0.0, 0.0, 0.0, color_value.a), clampf(amount, 0.0, 1.0))
