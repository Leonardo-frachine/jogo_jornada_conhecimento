extends SceneTree

const COMPONENT_PATH := "res://ui/settings/SettingsButton.tscn"
const SCRIPT_PATH := "res://ui/settings/SettingsButton.gd"
const SettingsButtonLayout := preload("res://ui/settings/SettingsButtonLayout.gd")
const EXPECTED_SIZE := Vector2(84.0, 84.0)
const EXPECTED_MARGIN := 24.0
const SCENES := [
	"res://scene/selecao_perfil.tscn",
	"res://scene/tela_inicial.tscn",
	"res://scene/acesso_professor.tscn",
	"res://scene/loading_screen.tscn",
	"res://scene/game.tscn",
	"res://scene/end_game_screen.tscn",
	"res://scene/painel_professor.tscn",
]

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var component := load(COMPONENT_PATH) as PackedScene
	_expect(component != null, "Componente compartilhado nao carregou.")
	if component == null:
		_finish()
		return

	for viewport_size in [Vector2(1280.0, 720.0), Vector2(1920.0, 1080.0)]:
		for font_scale in [1.0, 1.15, 1.30]:
			await _validate_layout(component, viewport_size, font_scale)
		await _validate_canvas_layer_layout(component, viewport_size)
		_validate_centered_content_clearance(viewport_size)

	for scene_path in SCENES:
		_validate_scene(scene_path)
		await _validate_menu_behavior(scene_path)

	_validate_sidebar()
	_finish()


func _validate_layout(component: PackedScene, viewport_size: Vector2, font_scale: float) -> void:
	var settings_manager := root.get_node_or_null("SettingsManager")
	if settings_manager != null:
		settings_manager.set("font_scale", font_scale)
	var host := Control.new()
	host.size = viewport_size
	root.add_child(host)
	var button := component.instantiate() as TextureButton
	host.add_child(button)
	await process_frame

	var expected_position := viewport_size - EXPECTED_SIZE - Vector2.ONE * EXPECTED_MARGIN
	var context := "%dx%d em %.0f%%" % [viewport_size.x, viewport_size.y, font_scale * 100.0]
	_expect(button.size.is_equal_approx(EXPECTED_SIZE), "%s: tamanho %s." % [context, button.size])
	_expect(button.position.is_equal_approx(expected_position), "%s: posicao %s." % [context, button.position])
	_expect(
		is_equal_approx(button.anchor_left, 1.0)
		and is_equal_approx(button.anchor_top, 1.0)
		and is_equal_approx(button.anchor_right, 1.0)
		and is_equal_approx(button.anchor_bottom, 1.0),
		"%s: ancoras nao apontam para o canto inferior direito." % context
	)
	_expect(button.pressed.get_connections().size() == 1, "%s: callback central nao conectado." % context)
	host.queue_free()
	await process_frame


func _validate_scene(scene_path: String) -> void:
	var packed := load(scene_path) as PackedScene
	_expect(packed != null, "%s nao carregou." % scene_path)
	if packed == null:
		return
	var instance := packed.instantiate()
	var button := instance.find_child("BotaoConfiguracao", true, false) as TextureButton
	_expect(button != null, "%s nao possui BotaoConfiguracao." % scene_path)
	if button != null:
		var button_script := button.get_script() as Script
		_expect(
			button_script != null and button_script.resource_path == SCRIPT_PATH,
			"%s nao usa o componente padrao." % scene_path
		)
	instance.free()


func _validate_canvas_layer_layout(component: PackedScene, viewport_size: Vector2) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(viewport_size)
	root.add_child(viewport)
	var canvas_layer := CanvasLayer.new()
	viewport.add_child(canvas_layer)
	var button := component.instantiate() as TextureButton
	canvas_layer.add_child(button)
	await process_frame

	var expected_position := viewport_size - EXPECTED_SIZE - Vector2.ONE * EXPECTED_MARGIN
	_expect(
		button.position.is_equal_approx(expected_position),
		"CanvasLayer %dx%d: posicao %s." % [viewport_size.x, viewport_size.y, button.position]
	)
	viewport.queue_free()
	await process_frame


func _validate_menu_behavior(scene_path: String) -> void:
	var settings_manager := root.get_node_or_null("SettingsManager")
	_expect(settings_manager != null, "SettingsManager nao esta disponivel para %s." % scene_path)
	if settings_manager == null:
		return

	# Usa apenas a raiz instanciada para validar a permissao da cena sem executar sua logica.
	var packed := load(scene_path) as PackedScene
	var scene_stub := packed.instantiate()
	scene_stub.set_script(null)
	for child in scene_stub.get_children():
		scene_stub.remove_child(child)
		child.free()
	root.add_child(scene_stub)
	current_scene = scene_stub
	settings_manager.open_menu()
	await process_frame
	_expect(settings_manager.overlay.is_open(), "%s nao abriu o menu de configuracoes." % scene_path)
	await create_timer(0.20).timeout
	settings_manager.close_menu()
	await process_frame
	_expect(not settings_manager.overlay.is_open(), "%s nao fechou o menu de configuracoes." % scene_path)
	await create_timer(0.15).timeout
	current_scene = null
	scene_stub.queue_free()
	await process_frame


func _validate_sidebar() -> void:
	var sidebar_scene := load("res://scene/professor/components/ProfessorSidebar.tscn") as PackedScene
	var sidebar := sidebar_scene.instantiate()
	_expect(
		sidebar.find_child("BotaoConfiguracoes", true, false) == null,
		"A sidebar ainda possui uma implementacao duplicada das configuracoes."
	)
	sidebar.free()


func _validate_centered_content_clearance(viewport_size: Vector2) -> void:
	var button_left := viewport_size.x - EXPECTED_SIZE.x - EXPECTED_MARGIN
	for desired_width in [1150.0, 1180.0]:
		var content_width := SettingsButtonLayout.fit_centered_content_width(viewport_size.x, desired_width)
		var content_right := (viewport_size.x + content_width) * 0.5
		_expect(
			content_right <= button_left - EXPECTED_MARGIN,
			"%dx%d: conteudo central invade a area segura da engrenagem." % [viewport_size.x, viewport_size.y]
		)

	var professor_scene := load("res://scene/painel_professor.tscn") as PackedScene
	var professor_panel := professor_scene.instantiate()
	var safe_area := professor_panel.get_node("SafeArea") as MarginContainer
	_expect(
		safe_area.get_theme_constant("margin_right") == roundi(SettingsButtonLayout.CONTENT_SAFE_MARGIN),
		"Painel do professor nao reserva a faixa lateral da engrenagem."
	)
	professor_panel.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _finish() -> void:
	if failures.is_empty():
		print("SettingsButton validado em 7 cenas, 2 resolucoes e 3 escalas de fonte.")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)
