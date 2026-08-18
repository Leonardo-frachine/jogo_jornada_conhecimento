extends Node

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
	process_mode = Node.PROCESS_MODE_ALWAYS

	_music_player = AudioStreamPlayer.new()
	_music_player.name = "PersistentMusic"
	_music_player.bus = &"Music"
	add_child(_music_player)

	for index in range(SFX_POOL_SIZE):
		var player := AudioStreamPlayer.new()
		player.name = "Sfx%d" % (index + 1)
		player.bus = &"SFX"
		add_child(player)
		_sfx_players.append(player)

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
	if _music_player.stream != stream:
		_music_player.stop()
		_music_player.stream = stream
		_set_music_loop(stream)
	_sync_music_state()

func _set_music_loop(stream: AudioStream) -> void:
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD

func _sync_music_state() -> void:
	if _music_player == null or _music_player.stream == null:
		return

	if SettingsManager.music_enabled:
		_music_player.stream_paused = false
		if not _music_player.playing:
			_music_player.play()
	elif _music_player.playing:
		_music_player.stream_paused = true

func _play_sfx(stream: AudioStream) -> void:
	if stream == null or _sfx_players.is_empty():
		return

	var selected_player := _sfx_players[_next_sfx_player]
	for player in _sfx_players:
		if not player.playing:
			selected_player = player
			break

	_next_sfx_player = (_sfx_players.find(selected_player) + 1) % _sfx_players.size()
	selected_player.stop()
	selected_player.stream = stream
	selected_player.play()
