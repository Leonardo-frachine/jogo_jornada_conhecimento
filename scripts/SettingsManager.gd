extends Node

# Fonte unica das preferencias persistentes e do menu global de configuracoes.
signal settings_loaded
signal settings_changed
signal font_scale_changed(value: float)

const CONFIG_PATH := "user://settings.cfg"
const OVERLAY_SCENE := preload("res://ui/settings/SettingsOverlay.tscn")
const ACCESS_SCENE_PATH := "res://scene/selecao_perfil.tscn"
const ALLOWED_OVERLAY_SCENES := {
	"res://scene/selecao_perfil.tscn": true,
	"res://scene/tela_inicial.tscn": true,
	"res://scene/loading_screen.tscn": true,
	"res://scene/game.tscn": true,
	"res://scene/acesso_professor.tscn": true,
	"res://scene/painel_professor.tscn": true,
	"res://scene/end_game_screen.tscn": true,
}

const DEFAULT_MASTER_VOLUME := 0.85
const DEFAULT_SFX_VOLUME := 0.80
const DEFAULT_MUSIC_ENABLED := true
const DEFAULT_VFX_ENABLED := true
const DEFAULT_SUBTITLES_ENABLED := true
const DEFAULT_FONT_SCALE := 1.0
const FONT_SCALE_OPTIONS: Array[float] = [1.0, 1.15, 1.30]

var master_volume: float = DEFAULT_MASTER_VOLUME
var sfx_volume: float = DEFAULT_SFX_VOLUME
var music_enabled: bool = DEFAULT_MUSIC_ENABLED
var vfx_enabled: bool = DEFAULT_VFX_ENABLED
var subtitles_enabled: bool = DEFAULT_SUBTITLES_ENABLED
var font_scale: float = DEFAULT_FONT_SCALE

var overlay = null
var pause_tree_when_open := false

func _ready() -> void:
	# Autoload continua disponivel durante pausas e trocas de cena.
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	_spawn_overlay()

func _input(event: InputEvent) -> void:
	# Ignora qualquer evento que nao seja a acao global de voltar/ESC.
	if not event.is_action_pressed("ui_cancel"):
		return

	# ESC fecha primeiro um menu ja aberto, sem propagar o evento para a cena.
	if overlay != null and overlay.is_open():
		close_menu()
		get_viewport().set_input_as_handled()
		return

	# Abre configuracoes somente nas cenas declaradas como seguras.
	if _can_open_in_current_scene():
		open_menu()
		get_viewport().set_input_as_handled()

func _can_open_in_current_scene() -> bool:
	var current_scene := get_tree().current_scene
	# Durante transicao pode nao existir uma cena corrente.
	if current_scene == null:
		return false
	return ALLOWED_OVERLAY_SCENES.has(current_scene.scene_file_path)

func _spawn_overlay() -> void:
	# O overlay e global e deve existir uma unica vez.
	if overlay != null and is_instance_valid(overlay):
		return

	overlay = OVERLAY_SCENE.instantiate()
	get_tree().root.call_deferred("add_child", overlay)
	await get_tree().process_frame

	# A instancia pode falhar ou ser removida durante a espera de um frame.
	if overlay == null:
		return

	# Conecta sinais apenas quando existem e ainda nao possuem este callback.
	if overlay.has_signal("menu_opened") and not overlay.menu_opened.is_connected(_on_menu_opened):
		overlay.menu_opened.connect(_on_menu_opened)

	# A mesma protecao evita conexoes duplicadas no fechamento.
	if overlay.has_signal("menu_closed") and not overlay.menu_closed.is_connected(_on_menu_closed):
		overlay.menu_closed.connect(_on_menu_closed)

func _on_menu_opened() -> void:
	# Cenas podem escolher se o menu congela ou nao o jogo ao fundo.
	if pause_tree_when_open:
		get_tree().paused = true

func _on_menu_closed() -> void:
	# So desfaz a pausa quando esta foi solicitada para o overlay.
	if pause_tree_when_open:
		get_tree().paused = false

func open_menu() -> void:
	# Impede o overlay em telas de transicao ou cenas nao homologadas.
	if not _can_open_in_current_scene():
		return
	# Recria a interface se o overlay global foi liberado.
	if overlay == null or not is_instance_valid(overlay):
		await _spawn_overlay()
	# Se a recriacao falhar, encerra sem acessar uma referencia nula.
	if overlay == null:
		return
	overlay.open()

func close_menu() -> void:
	# Fechar e seguro mesmo quando nenhuma interface foi criada.
	if overlay == null or not is_instance_valid(overlay):
		return
	overlay.close()

func toggle_menu() -> void:
	# Nao alterna estado de uma instancia inexistente.
	if overlay == null or not is_instance_valid(overlay):
		return

	# Escolhe fechar ou abrir com base no estado visual atual.
	if overlay.is_open():
		close_menu()
	else:
		open_menu()

func return_to_access_screen() -> void:
	get_tree().paused = false

	# Limpa a sessao do professor quando o autoload correspondente estiver registrado.
	if has_node("/root/ProfessorSession"):
		var professor_session: Node = get_node("/root/ProfessorSession")
		# Chamada por nome preserva compatibilidade caso a implementacao do autoload mude.
		if professor_session.has_method("clear_session"):
			professor_session.call("clear_session")

	close_menu()
	get_tree().change_scene_to_file(ACCESS_SCENE_PATH)

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

func set_font_scale(value: float) -> void:
	var selected_scale := FONT_SCALE_OPTIONS[0]
	var shortest_distance := absf(value - selected_scale)
	# Percorre as opcoes permitidas para selecionar a mais proxima do valor recebido.
	for option in FONT_SCALE_OPTIONS:
		var distance := absf(value - option)
		# Substitui a selecao somente quando a nova opcao estiver mais perto.
		if distance < shortest_distance:
			selected_scale = option
			shortest_distance = distance

	# Nao salva nem emite sinais quando a escala efetiva permaneceu igual.
	if is_equal_approx(font_scale, selected_scale):
		return

	font_scale = selected_scale
	save_settings()
	font_scale_changed.emit(font_scale)
	settings_changed.emit()

func reset_settings() -> void:
	# Restaura todas as categorias juntas para manter UI e audio sincronizados.
	master_volume = DEFAULT_MASTER_VOLUME
	sfx_volume = DEFAULT_SFX_VOLUME
	music_enabled = DEFAULT_MUSIC_ENABLED
	vfx_enabled = DEFAULT_VFX_ENABLED
	subtitles_enabled = DEFAULT_SUBTITLES_ENABLED
	font_scale = DEFAULT_FONT_SCALE

	apply_settings()
	save_settings()
	font_scale_changed.emit(font_scale)
	settings_changed.emit()

func apply_settings() -> void:
	_apply_bus_volume("Master", master_volume)
	_apply_bus_volume("SFX", sfx_volume)
	_apply_music_enabled()

func save_settings() -> void:
	# user:// funciona em desktop e usa armazenamento persistente do navegador na Web.
	var config := ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "music_enabled", music_enabled)
	config.set_value("graphics", "vfx_enabled", vfx_enabled)
	config.set_value("accessibility", "subtitles_enabled", subtitles_enabled)
	config.set_value("accessibility", "font_scale", font_scale)

	var err := config.save(CONFIG_PATH)
	# Falha de disco nao interrompe o jogo, mas fica registrada para manutencao.
	if err != OK:
		push_warning("Erro ao salvar configuracoes em: %s" % CONFIG_PATH)

func load_settings() -> void:
	var config := ConfigFile.new()
	var err := config.load(CONFIG_PATH)

	# Primeira execucao ou arquivo invalido usa padroes e cria um novo arquivo valido.
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
	font_scale = _validated_font_scale(float(config.get_value("accessibility", "font_scale", DEFAULT_FONT_SCALE)))

	apply_settings()
	settings_loaded.emit()

func _validated_font_scale(value: float) -> float:
	var selected_scale := FONT_SCALE_OPTIONS[0]
	var shortest_distance := absf(value - selected_scale)
	# Normaliza valor antigo/customizado para uma das escalas homologadas.
	for option in FONT_SCALE_OPTIONS:
		var distance := absf(value - option)
		# Mantem a opcao com menor distancia absoluta.
		if distance < shortest_distance:
			selected_scale = option
			shortest_distance = distance
	return selected_scale

func _apply_bus_volume(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	# Um bus ausente indica configuracao incompleta do projeto, mas nao deve fechar o jogo.
	if bus_index == -1:
		push_warning("Bus de audio nao encontrado: %s" % bus_name)
		return

	# Valores proximos de zero usam mute para evitar conversao logaritmica invalida.
	if value <= 0.001:
		AudioServer.set_bus_mute(bus_index, true)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(0.001))
	else:
		AudioServer.set_bus_mute(bus_index, false)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

func _apply_music_enabled() -> void:
	var bus_index := AudioServer.get_bus_index("Music")
	# Preserva execucao mesmo se o layout de buses nao tiver a faixa Music.
	if bus_index == -1:
		push_warning("Bus de audio 'Music' nao encontrado.")
		return

	AudioServer.set_bus_mute(bus_index, not music_enabled)
	# Cada chave possui fallback para aceitar arquivos de versoes anteriores.
