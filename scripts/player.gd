extends CharacterBody2D

# Peao local: conhece a sequencia de casas e anima cada passo ate o destino.
signal step_reached(house_index: int)
signal movement_finished

var board_positions: Array[Vector2] = []
var current_house: int = 1
var moving := false
var idle_sprite_scale := Vector2(0.085, 0.1)
var walk_sprite_scale := Vector2(0.095, 0.115)

@onready var sprite: AnimatedSprite2D = $CollisionShape2D/AnimatedSprite2D

func setup(positions: Array[Vector2]) -> void:
	# Uma nova sessao comeca na primeira casa e aplica o personagem escolhido.
	_apply_selected_character()
	board_positions = positions
	current_house = 1
	# Posiciona somente quando o tabuleiro forneceu ao menos uma casa.
	if board_positions.size() > 0:
		global_position = board_positions[0]
	_play_idle()

func update_board_positions(positions: Array[Vector2]) -> void:
	board_positions = positions
	# Durante movimento nao reposiciona, evitando salto causado por resize da janela.
	if moving or board_positions.is_empty():
		return
	current_house = clampi(current_house, 1, board_positions.size())
	global_position = board_positions[current_house - 1]

func move_to_house(target_house: int) -> void:
	# Bloqueia um segundo deslocamento enquanto o primeiro ainda executa.
	if moving:
		return
	# Sem casas, encerra o fluxo para a tela nao ficar esperando o sinal.
	if board_positions.is_empty():
		movement_finished.emit()
		return

	target_house = clampi(target_house, 1, board_positions.size())
	moving = true
	# Define se avanca ou recua e visita cada casa intermediaria.
	var direction := 1 if target_house > current_house else -1
	# Cada iteracao corresponde a um passo real do peao no tabuleiro.
	while current_house != target_house:
		current_house += direction
		await _move_to_position(board_positions[current_house - 1])
		step_reached.emit(current_house)
	moving = false
	_play_idle()
	movement_finished.emit()

func _move_to_position(target_position: Vector2) -> void:
	# Movimento suave e leve pulso de escala comunicam visualmente cada passo.
	_play_walk()
	var tween := create_tween()
	tween.tween_property(self, "global_position", target_position, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(sprite, "scale", walk_sprite_scale, 0.14)
	tween.tween_property(sprite, "scale", idle_sprite_scale, 0.14)
	await tween.finished

func _apply_selected_character() -> void:
	# A cena pode ser inicializada antes do AnimatedSprite estar disponivel.
	if sprite == null:
		return

	var texture_path := GameState.get_selected_character_texture_path()
	var texture := load(texture_path) as Texture2D
	# Mantem o personagem atual se o recurso selecionado nao puder ser carregado.
	if texture == null:
		return

	var frames := SpriteFrames.new()
	# Cria a animacao base quando o SpriteFrames novo ainda nao possui idle.
	if not frames.has_animation("idle"):
		frames.add_animation("idle")
	frames.add_frame("idle", texture)
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", 5.0)
	sprite.sprite_frames = frames
	sprite.animation = &"idle"

	var token_scale := 104.0 / maxf(float(texture.get_height()), 1.0)
	idle_sprite_scale = Vector2.ONE * token_scale
	walk_sprite_scale = Vector2.ONE * token_scale * 1.12
	sprite.scale = idle_sprite_scale

func _play_walk() -> void:
	# Guarda defensiva para chamadas durante liberacao da cena.
	if sprite == null:
		return
	sprite.speed_scale = 10.0
	sprite.play("idle")

func _play_idle() -> void:
	# Guarda defensiva para chamadas durante liberacao da cena.
	if sprite == null:
		return
	sprite.speed_scale = 5.0
	sprite.play("idle")
