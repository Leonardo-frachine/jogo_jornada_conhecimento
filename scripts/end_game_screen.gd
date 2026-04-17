extends Control


@onready var logo = find_child("Logo", true, false)
@onready var character = find_child("Character", true, false)

func _ready():

	if logo:
		animate_logo()
	if character:
		animate_character()


func animate_logo() -> void:
	var base_y = logo.position.y
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(logo, "position:y", base_y - 6.0, 0.95).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(logo, "position:y", base_y, 0.95).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func animate_character() -> void:
	var base_y = character.position.y
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(character, "position:y", base_y - 8.0, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(character, "position:y", base_y, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/tela_inicial.tscn")
