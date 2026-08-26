extends RefCounted
class_name UITheme

# Biblioteca estatica do tema visual; centraliza cores, fontes e estados dos controles.
const FONT_RESOURCE := preload("res://fonts/Fredoka-Bold.ttf")

const TEXT_PRIMARY := Color(0.12, 0.16, 0.27, 1.0)
const TEXT_MUTED := Color(0.22, 0.29, 0.43, 1.0)
const TEXT_INVERSE := Color(0.96, 0.98, 1.0, 1.0)
const TEXT_PRIMARY_COLOR := TEXT_PRIMARY
const TEXT_SECONDARY_COLOR := TEXT_MUTED
const TEXT_ON_DARK_COLOR := TEXT_INVERSE

const APP_BACKGROUND := Color(0.98, 0.95, 0.89, 1.0)
const APP_SURFACE := Color(0.99, 0.96, 0.90, 0.98)
const APP_SURFACE_ALT := Color(1.0, 0.98, 0.95, 1.0)
const APP_BORDER := Color(0.83, 0.62, 0.18, 1.0)
const APP_TEXT := TEXT_PRIMARY
const APP_MUTED := TEXT_MUTED
const APP_ACCENT := Color(0.99, 0.78, 0.22, 1.0)
const APP_ACCENT_DARK := Color(0.50, 0.32, 0.06, 1.0)
const APP_SIDEBAR := Color(0.12, 0.16, 0.27, 0.98)
const APP_SIDEBAR_BORDER := Color(0.26, 0.35, 0.60, 1.0)
const APP_SIDEBAR_TEXT := TEXT_INVERSE
const APP_SIDEBAR_MUTED := Color(0.79, 0.84, 0.94, 1.0)
const APP_GLOW_PRIMARY := Color(1.0, 0.83, 0.43, 0.26)
const APP_GLOW_SECONDARY := Color(0.34, 0.44, 0.70, 0.18)

const PROFESSOR_BACKGROUND := APP_BACKGROUND
const PROFESSOR_SURFACE := APP_SURFACE
const PROFESSOR_SURFACE_ALT := APP_SURFACE_ALT
const PROFESSOR_BORDER := APP_BORDER
const PROFESSOR_TEXT := APP_TEXT
const PROFESSOR_MUTED := APP_MUTED
const PROFESSOR_ACCENT := APP_ACCENT
const PROFESSOR_ACCENT_DARK := APP_ACCENT_DARK
const PROFESSOR_SIDEBAR := APP_SIDEBAR
const PROFESSOR_SIDEBAR_BORDER := APP_SIDEBAR_BORDER
const PROFESSOR_SIDEBAR_TEXT := APP_SIDEBAR_TEXT
const PROFESSOR_SIDEBAR_MUTED := APP_SIDEBAR_MUTED
const STATUS_SUCCESS := Color(0.15, 0.60, 0.38, 1.0)
const STATUS_WARNING := Color(0.82, 0.56, 0.16, 1.0)
const STATUS_ERROR := Color(0.76, 0.24, 0.26, 1.0)
const STATUS_INFO := Color(0.26, 0.35, 0.60, 1.0)

const BUTTON_PRIMARY := "primary"
const BUTTON_SECONDARY := "secondary"
const BUTTON_SURFACE := "surface"
const BUTTON_DANGER := "danger"
const BUTTON_TAB_ACTIVE := "tab_active"
const BUTTON_TAB_INACTIVE := "tab_inactive"

static func apply_font_only(control: Control, font_size: int = -1) -> void:
	# Chamadores podem usar referencias opcionais sem testar null previamente.
	if control == null:
		return

	control.add_theme_font_override("font", FONT_RESOURCE)
	# Tamanho negativo significa aplicar apenas a familia da fonte.
	if font_size > 0:
		var accessibility_manager := _get_accessibility_manager()
		# Delega escala acessivel ao autoload quando ele estiver disponivel.
		if accessibility_manager != null and accessibility_manager.has_method("apply_font_size"):
			accessibility_manager.call("apply_font_size", control, font_size)
		else:
			control.add_theme_font_size_override("font_size", font_size)

static func apply_font_tree(root: Node) -> void:
	# Encerra a recursao com seguranca para uma raiz opcional.
	if root == null:
		return

	# Nodes visuais recebem a fonte antes de visitar seus descendentes.
	if root is Control:
		apply_font_only(root as Control)

	# Percorre toda a subarvore para uniformizar controles aninhados.
	for child in root.get_children():
		apply_font_tree(child)

static func apply_title(label: Label, font_size: int = 40, color: Color = TEXT_PRIMARY) -> void:
	# Permite estilizar labels opcionais sem erro.
	if label == null:
		return

	apply_font_only(label, font_size)
	label.add_theme_color_override("font_color", color)

static func apply_subtitle(label: Label, font_size: int = 16, color: Color = TEXT_MUTED) -> void:
	# Permite estilizar labels opcionais sem erro.
	if label == null:
		return

	apply_font_only(label, font_size)
	label.add_theme_color_override("font_color", color)

static func apply_field_label(label: Label, font_size: int = 17, color: Color = TEXT_PRIMARY) -> void:
	# Permite estilizar labels opcionais sem erro.
	if label == null:
		return

	apply_font_only(label, font_size)
	label.add_theme_color_override("font_color", color)

static func apply_surface_panel(panel: Control) -> void:
	# Painel ausente nao exige estilo e pode ocorrer em variantes de cena.
	if panel == null:
		return

	panel.add_theme_stylebox_override("panel", _make_surface_style(
		APP_SURFACE,
		APP_BORDER,
		3,
		28,
		18,
		18,
		Color(0.18, 0.11, 0.03, 0.18),
		18
	))

static func apply_page_shell(panel: Control) -> void:
	# Painel ausente nao exige estilo e pode ocorrer em variantes de cena.
	if panel == null:
		return

	panel.add_theme_stylebox_override("panel", _make_surface_style(
		Color(APP_SURFACE_ALT.r, APP_SURFACE_ALT.g, APP_SURFACE_ALT.b, 0.10),
		Color(0.0, 0.0, 0.0, 0.0),
		0,
		0,
		0,
		0,
		Color(0.0, 0.0, 0.0, 0.0),
		0
	))

static func apply_overlay_panel(panel: Control) -> void:
	# Painel ausente nao exige estilo e pode ocorrer em variantes de cena.
	if panel == null:
		return

	panel.add_theme_stylebox_override("panel", _make_surface_style(
		APP_SIDEBAR,
		APP_SIDEBAR_BORDER,
		2,
		24,
		18,
		18,
		Color(0.0, 0.0, 0.0, 0.30),
		16
	))

static func apply_line_edit(line_edit: LineEdit, font_size: int = 18) -> void:
	# Campos opcionais podem nao existir em todos os modos da tela.
	if line_edit == null:
		return

	line_edit.custom_minimum_size.y = maxf(line_edit.custom_minimum_size.y, 48.0)
	apply_font_only(line_edit, font_size)
	line_edit.add_theme_stylebox_override("normal", _make_surface_style(
		Color(1.0, 0.995, 0.985, 0.98),
		_tint(APP_BORDER, 0.28),
		2,
		16,
		18,
		14
	))
	line_edit.add_theme_stylebox_override("focus", _make_surface_style(
		Color(1.0, 0.995, 0.985, 1.0),
		APP_SIDEBAR_BORDER,
		2,
		16,
		18,
		14,
		Color(APP_SIDEBAR_BORDER.r, APP_SIDEBAR_BORDER.g, APP_SIDEBAR_BORDER.b, 0.14),
		8
	))
	line_edit.add_theme_stylebox_override("read_only", _make_surface_style(
		Color(APP_SURFACE_ALT.r, APP_SURFACE_ALT.g, APP_SURFACE_ALT.b, 0.98),
		_tint(APP_BORDER, 0.20),
		2,
		16,
		18,
		14
	))
	line_edit.add_theme_color_override("font_color", TEXT_PRIMARY)
	line_edit.add_theme_color_override("font_placeholder_color", TEXT_MUTED)
	line_edit.add_theme_color_override("caret_color", TEXT_PRIMARY)
	line_edit.add_theme_color_override("selection_color", Color(APP_ACCENT.r, APP_ACCENT.g, APP_ACCENT.b, 0.38))

static func apply_button(button: Button, variant: String = BUTTON_PRIMARY, font_size: int = 19) -> void:
	# Evita aplicar overrides em referencias opcionais inexistentes.
	if button == null:
		return

	var scheme := _button_scheme(variant)
	var radius := 18
	var padding_horizontal := 20
	var padding_vertical := 14
	# Botoes compactos usam raio e padding menores para caber em toolbars.
	if button.custom_minimum_size.y > 0.0 and button.custom_minimum_size.y <= 46.0:
		radius = 16
		padding_horizontal = 18
		padding_vertical = 12

	apply_font_only(button, font_size)
	button.clip_text = false
	button.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	# Dentro de Container, permite quebra de linha para preservar o layout responsivo.
	if button.get_parent() is Container:
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	# Toggle opcional nao precisa de tratamento pelo chamador.
	if button == null:
		return

	var variant := BUTTON_SECONDARY
	# Estado ligado recebe destaque primario; desligado usa contraste secundario.
	if enabled:
		variant = BUTTON_PRIMARY

	apply_button(button, variant, font_size)

static func _button_scheme(variant: String) -> Dictionary:
	# Cada variante retorna cores coerentes para fundo, borda e texto em todos os estados.
	match variant:
		BUTTON_SECONDARY:
			return {
				"background": APP_SIDEBAR_BORDER,
				"border": APP_SIDEBAR,
				"font": TEXT_INVERSE,
			}
		BUTTON_SURFACE:
			return {
				"background": APP_SURFACE_ALT,
				"border": _tint(APP_BORDER, 0.22),
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
				"background": APP_ACCENT,
				"border": APP_ACCENT_DARK,
				"font": TEXT_PRIMARY,
			}
		BUTTON_TAB_INACTIVE:
			return {
				"background": APP_SURFACE_ALT,
				"border": _tint(APP_BORDER, 0.22),
				"font": TEXT_PRIMARY,
			}
		_:
			return {
				"background": APP_ACCENT,
				"border": APP_ACCENT_DARK,
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
	# Constroi um StyleBox novo para evitar compartilhar e mutar estilos entre controles.
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

static func _get_accessibility_manager() -> Node:
	var main_loop := Engine.get_main_loop()
	# Fora de uma SceneTree, como em alguns testes/editor, o autoload nao pode ser acessado.
	if not main_loop is SceneTree:
		return null
	return (main_loop as SceneTree).root.get_node_or_null("AccessibilityManager")
