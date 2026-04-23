extends Node

signal settings_loaded
signal settings_changed

const CONFIG_PATH := "user://settings.cfg"
const OVERLAY_SCENE := preload("res://ui/settings/SettingsOverlay.tscn")
const ALLOWED_OVERLAY_SCENES := {
	"res://scene/tela_inicial.tscn": true,
	"res://scene/game.tscn": true,
}

const DEFAULT_MASTER_VOLUME := 0.85
const DEFAULT_SFX_VOLUME := 0.80
const DEFAULT_MUSIC_ENABLED := true
const DEFAULT_VFX_ENABLED := true
const DEFAULT_SUBTITLES_ENABLED := true

var master_volume: float = DEFAULT_MASTER_VOLUME
var sfx_volume: float = DEFAULT_SFX_VOLUME
var music_enabled: bool = DEFAULT_MUSIC_ENABLED
var vfx_enabled: bool = DEFAULT_VFX_ENABLED
var subtitles_enabled: bool = DEFAULT_SUBTITLES_ENABLED

var overlay = null
var pause_tree_when_open := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	_spawn_overlay()

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if overlay != null and overlay.is_open():
		close_menu()
		get_viewport().set_input_as_handled()
		return

	if _can_open_in_current_scene():
		open_menu()
		get_viewport().set_input_as_handled()

func _can_open_in_current_scene() -> bool:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return false
	return ALLOWED_OVERLAY_SCENES.has(current_scene.scene_file_path)

func _spawn_overlay() -> void:
	if overlay != null and is_instance_valid(overlay):
		return

	overlay = OVERLAY_SCENE.instantiate()
	get_tree().root.call_deferred("add_child", overlay)
	await get_tree().process_frame

	if overlay == null:
		return

	if overlay.has_signal("menu_opened") and not overlay.menu_opened.is_connected(_on_menu_opened):
		overlay.menu_opened.connect(_on_menu_opened)

	if overlay.has_signal("menu_closed") and not overlay.menu_closed.is_connected(_on_menu_closed):
		overlay.menu_closed.connect(_on_menu_closed)

func _on_menu_opened() -> void:
	if pause_tree_when_open:
		get_tree().paused = true

func _on_menu_closed() -> void:
	if pause_tree_when_open:
		get_tree().paused = false

func open_menu() -> void:
	if not _can_open_in_current_scene():
		return
	if overlay == null or not is_instance_valid(overlay):
		await _spawn_overlay()
	if overlay == null:
		return
	overlay.open()

func close_menu() -> void:
	if overlay == null or not is_instance_valid(overlay):
		return
	overlay.close()

func toggle_menu() -> void:
	if overlay == null or not is_instance_valid(overlay):
		return

	if overlay.is_open():
		close_menu()
	else:
		open_menu()

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume("Master", master_volume)
	save_settings()
	settings_changed.emit()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply_bus_volume("SFX", sfx_volume)
	save_settings()
	settings_changed.emit()

func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	_apply_music_enabled()
	save_settings()
	settings_changed.emit()

func set_vfx_enabled(enabled: bool) -> void:
	vfx_enabled = enabled
	save_settings()
	settings_changed.emit()

func set_subtitles_enabled(enabled: bool) -> void:
	subtitles_enabled = enabled
	save_settings()
	settings_changed.emit()

func reset_settings() -> void:
	master_volume = DEFAULT_MASTER_VOLUME
	sfx_volume = DEFAULT_SFX_VOLUME
	music_enabled = DEFAULT_MUSIC_ENABLED
	vfx_enabled = DEFAULT_VFX_ENABLED
	subtitles_enabled = DEFAULT_SUBTITLES_ENABLED

	apply_settings()
	save_settings()
	settings_changed.emit()

func apply_settings() -> void:
	_apply_bus_volume("Master", master_volume)
	_apply_bus_volume("SFX", sfx_volume)
	_apply_music_enabled()

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "music_enabled", music_enabled)
	config.set_value("graphics", "vfx_enabled", vfx_enabled)
	config.set_value("accessibility", "subtitles_enabled", subtitles_enabled)

	var err := config.save(CONFIG_PATH)
	if err != OK:
		push_warning("Erro ao salvar configuracoes em: %s" % CONFIG_PATH)

func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(CONFIG_PATH)

	if err != OK:
		apply_settings()
		save_settings()
		settings_loaded.emit()
		return

	master_volume = float(config.get_value("audio", "master_volume", DEFAULT_MASTER_VOLUME))
	sfx_volume = float(config.get_value("audio", "sfx_volume", DEFAULT_SFX_VOLUME))
	music_enabled = bool(config.get_value("audio", "music_enabled", DEFAULT_MUSIC_ENABLED))
	vfx_enabled = bool(config.get_value("graphics", "vfx_enabled", DEFAULT_VFX_ENABLED))
	subtitles_enabled = bool(config.get_value("accessibility", "subtitles_enabled", DEFAULT_SUBTITLES_ENABLED))

	apply_settings()
	settings_loaded.emit()

func _apply_bus_volume(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		push_warning("Bus de audio nao encontrado: %s" % bus_name)
		return

	if value <= 0.001:
		AudioServer.set_bus_mute(bus_index, true)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(0.001))
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

func _apply_music_enabled() -> void:
	var bus_index := AudioServer.get_bus_index("Music")
	if bus_index == -1:
		push_warning("Bus de audio 'Music' nao encontrado.")
		return

	AudioServer.set_bus_mute(bus_index, not music_enabled)
