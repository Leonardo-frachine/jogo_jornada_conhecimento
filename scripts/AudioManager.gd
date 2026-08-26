extends Node

# Gerenciador persistente de musica e efeitos; respeita os volumes globais salvos.
const MENU_MUSIC := preload("res://assets/audio/fundo2.MP3")
const GAME_MUSIC := preload("res://assets/audio/fundo.MP3")
const DICE_SFX := preload("res://assets/audio/dice.wav")
const CORRECT_SFX := preload("res://assets/audio/correct.mp3")
const WRONG_SFX := preload("res://assets/audio/wrong.wav")
const MOVE_SFX := preload("res://assets/audio/move.wav")
const SFX_POOL_SIZE := 6

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx_player := 0

func _ready() -> void:
	# O autoload continua processando audio mesmo quando o menu de configuracoes pausa a cena.
	process_mode = Node.PROCESS_MODE_ALWAYS

	_music_player = AudioStreamPlayer.new()
	_music_player.name = "PersistentMusic"
	_music_player.bus = &"Music"
	add_child(_music_player)

	# Cria um pequeno pool para que efeitos rapidos possam se sobrepor sem cortar uns aos outros.
	for index in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "Sfx%d" % (index + 1)
		player.bus = &"SFX"
		add_child(player)
		_sfx_players.append(player)

	# Evita conectar o mesmo callback mais de uma vez ao recarregar cenas.
	if not SettingsManager.settings_changed.is_connected(_sync_music_state):
		SettingsManager.settings_changed.connect(_sync_music_state)

func play_menu_music() -> void:
	_play_music(MENU_MUSIC)

func play_game_music() -> void:
	_play_music(GAME_MUSIC)

func play_dice_sfx() -> void:
	_play_sfx(DICE_SFX)

func play_correct_sfx() -> void:
	_play_sfx(CORRECT_SFX)

func play_wrong_sfx() -> void:
	_play_sfx(WRONG_SFX)

func play_move_sfx() -> void:
	_play_sfx(MOVE_SFX)

func _play_music(stream: AudioStream) -> void:
	# Troca o arquivo somente quando necessario para nao reiniciar a mesma musica.
	if _music_player.stream != stream:
		_music_player.stop()
		_music_player.stream = stream
		_set_music_loop(stream)
	_sync_music_state()

func _set_music_loop(stream: AudioStream) -> void:
	# MP3 e WAV possuem APIs diferentes para repeticao continua.
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	# WAV usa um modo de loop enumerado em vez de uma propriedade booleana.
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD

func _sync_music_state() -> void:
	# Sem player ou faixa carregada nao existe estado musical para sincronizar.
	if _music_player == null or _music_player.stream == null:
		return

	# Musica habilitada retoma a faixa e inicia caso ainda nao esteja tocando.
	if SettingsManager.music_enabled:
		_music_player.stream_paused = false
		# play so e necessario na primeira execucao; faixas pausadas apenas retomam.
		if not _music_player.playing:
			_music_player.play()
	# Ao desabilitar, pausa a faixa atual para preservar sua posicao.
	elif _music_player.playing:
		_music_player.stream_paused = true

func _play_sfx(stream: AudioStream) -> void:
	# Ignora recurso ausente ou pool ainda nao inicializado.
	if stream == null or _sfx_players.is_empty():
		return

	var selected_player := _sfx_players[_next_sfx_player]
	# Procura primeiro um canal livre para permitir efeitos simultaneos.
	for player in _sfx_players:
		# O primeiro player parado pode reproduzir sem interromper outro som.
		if not player.playing:
			selected_player = player
			break

	_next_sfx_player = (_sfx_players.find(selected_player) + 1) % _sfx_players.size()
	selected_player.stop()
	selected_player.stream = stream
	selected_player.play()
