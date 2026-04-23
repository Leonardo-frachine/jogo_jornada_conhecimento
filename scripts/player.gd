extends CharacterBody2D

signal step_reached(house_index: int)
signal movement_finished

var board_positions: Array[Vector2] = []
var current_house: int = 1
var moving := false

@onready var sprite: AnimatedSprite2D = $CollisionShape2D/AnimatedSprite2D

func setup(positions: Array[Vector2]) -> void:
	board_positions = positions
	current_house = 1
	if board_positions.size() > 0:
		global_position = board_positions[0]
	_play_idle()

func move_to_house(target_house: int) -> void:
	if moving:
		return
	if board_positions.is_empty():
		movement_finished.emit()
		return

	moving = true
	while current_house < target_house:
		current_house += 1
		await _move_to_position(board_positions[current_house - 1])
		step_reached.emit(current_house)
	moving = false
	_play_idle()
	movement_finished.emit()

func _move_to_position(target_position: Vector2) -> void:
	_play_walk()
	var tween := create_tween()
	tween.tween_property(self, "global_position", target_position, 0.28).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(sprite, "scale", Vector2(0.095, 0.115), 0.14)
	tween.tween_property(sprite, "scale", Vector2(0.085, 0.1), 0.14)
	await tween.finished

func _play_walk() -> void:
	if sprite == null:
		return
	sprite.speed_scale = 10.0
	sprite.play("idle")

func _play_idle() -> void:
	if sprite == null:
		return
	sprite.speed_scale = 5.0
	sprite.play("idle")
