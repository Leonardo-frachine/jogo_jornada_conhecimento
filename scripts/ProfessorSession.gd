extends Node

var professor_id: int = 0
var professor_name: String = ""
var professor_email: String = ""
var current_room_id: int = 0
var current_room_name: String = ""
var current_room_code: String = ""

func clear_session() -> void:
	professor_id = 0
	professor_name = ""
	professor_email = ""
	current_room_id = 0
	current_room_name = ""
	current_room_code = ""

func start_session(professor_payload: Dictionary) -> void:
	professor_id = int(professor_payload.get("id", 0))
	professor_name = str(professor_payload.get("nome", "")).strip_edges()
	professor_email = str(professor_payload.get("email", "")).strip_edges()
	current_room_id = 0
	current_room_name = ""
	current_room_code = ""

func has_session() -> bool:
	return professor_id > 0

func set_current_room(room_payload: Dictionary) -> void:
	current_room_id = int(room_payload.get("id", 0))
	current_room_name = str(room_payload.get("nome", "")).strip_edges()
	current_room_code = str(room_payload.get("codigo", "")).strip_edges()

func has_current_room() -> bool:
	return current_room_id > 0
