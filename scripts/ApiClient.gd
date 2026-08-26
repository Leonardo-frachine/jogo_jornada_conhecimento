extends Node

const DEFAULT_BASE_URL := "https://api.nathanmariotto.com.br" # Backend local padrao
const BASE_URL_SETTING := "application/config/api_base_url"
const REQUEST_TIMEOUT_SECONDS := 10.0
const IMPORT_REQUEST_TIMEOUT_SECONDS := 30.0
const AI_REQUEST_TIMEOUT_SECONDS := 45.0
const SERVER_UNAVAILABLE_MESSAGE := "Servidor temporariamente indisponivel. Tente novamente em alguns minutos."

var base_url: String = DEFAULT_BASE_URL

func _ready() -> void:
	base_url = _load_base_url()

func set_base_url(value: String) -> void:
	base_url = _normalize_base_url(value)

func create_player(name: String, sala_id: int = 0, sala_codigo: String = "") -> Dictionary:
	var payload: Dictionary = {
		"nome": name,
	}
	if sala_id > 0:
		payload["salaId"] = sala_id
	if not sala_codigo.strip_edges().is_empty():
		payload["salaCodigo"] = sala_codigo.strip_edges().to_upper()
	return await _request_json(HTTPClient.METHOD_POST, "/jogadores", payload)

func register_teacher(name: String, email: String, password: String) -> Dictionary:
	return await _request_json(HTTPClient.METHOD_POST, "/professores/cadastro", {
		"nome": name,
		"email": email,
		"senha": password,
	})

func login_teacher(email: String, password: String) -> Dictionary:
	return await _request_json(HTTPClient.METHOD_POST, "/professores/login", {
		"email": email,
		"senha": password,
	})

func create_room(professor_id: int, room_name: String) -> Dictionary:
	return await _request_json(HTTPClient.METHOD_POST, "/salas", {
		"professorId": professor_id,
		"nome": room_name,
	})

func fetch_rooms_by_teacher(professor_id: int) -> Dictionary:
	return await _request_json(HTTPClient.METHOD_GET, "/salas/professor/%d" % professor_id)

func fetch_room_by_code(room_code: String) -> Dictionary:
	return await _request_json(HTTPClient.METHOD_GET, "/salas/codigo/%s" % room_code.strip_edges())

func fetch_room_dashboard(room_id: int) -> Dictionary:
	return await _request_json(HTTPClient.METHOD_GET, "/salas/%d/dashboard" % room_id)

func fetch_room_answers(room_id: int) -> Dictionary:
	return await _request_json(HTTPClient.METHOD_GET, "/salas/%d/respostas" % room_id)

func fetch_room_players(room_id: int) -> Dictionary:
	return await _request_json(HTTPClient.METHOD_GET, "/salas/%d/alunos" % room_id)

func fetch_room_ranking(room_id: int) -> Dictionary:
	return await _request_json(HTTPClient.METHOD_GET, "/salas/%d/ranking" % room_id)

func delete_room(room_id: int) -> Dictionary:
	return await _request_json(HTTPClient.METHOD_DELETE, "/salas/%d" % room_id)

func fetch_questions(sala_id: int) -> Dictionary:
	return await _request_json(HTTPClient.METHOD_GET, "/perguntas?salaId=%d" % sala_id)

func update_question(question_id: int, sala_id: int, payload: Dictionary) -> Dictionary:
	return await _request_json(HTTPClient.METHOD_PATCH, "/perguntas/%d?salaId=%d" % [question_id, sala_id], payload)

func delete_question(question_id: int, sala_id: int) -> Dictionary:
	return await _request_json(HTTPClient.METHOD_DELETE, "/perguntas/%d?salaId=%d" % [question_id, sala_id])

func delete_all_questions(sala_id: int) -> Dictionary:
	return await _request_json(HTTPClient.METHOD_DELETE, "/perguntas?salaId=%d" % sala_id)

func generate_questions_ai(sala_id: int, tema: String, materia: String, dificuldade: String, quantidade: int, pontuacao: int, tempo_limite: int) -> Dictionary:
	var payload: Dictionary = {
		"salaId": sala_id,
		"tema": tema,
		"materia": materia,
		"dificuldade": dificuldade,
		"quantidade": quantidade,
		"pontuacao": pontuacao,
	}
	if tempo_limite > 0:
		payload["tempoLimite"] = tempo_limite

	return await _request_json(
		HTTPClient.METHOD_POST,
		"/perguntas/gerar-ia",
		payload,
		AI_REQUEST_TIMEOUT_SECONDS
	)

func save_generated_questions(sala_id: int, perguntas_aprovadas: Array) -> Dictionary:
	return await _request_json(
		HTTPClient.METHOD_POST,
		"/perguntas/salvar-geradas?salaId=%d" % sala_id,
		perguntas_aprovadas,
		AI_REQUEST_TIMEOUT_SECONDS
	)

func import_questions_spreadsheet(file_path: String, sala_id: int) -> Dictionary:
	var extension: String = file_path.get_extension().to_lower()
	if extension != "csv" and extension != "xlsx":
		return _error_response(0, "Selecione um arquivo .csv ou .xlsx.")

	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return _error_response(0, "Nao foi possivel abrir o arquivo selecionado.")

	var content: PackedByteArray = file.get_buffer(file.get_length())
	file.close()

	if content.is_empty():
		return _error_response(0, "O arquivo selecionado esta vazio.")

	return await _request_json(HTTPClient.METHOD_POST, "/perguntas/importar-planilha", {
		"salaId": sala_id,
		"fileName": file_path.get_file(),
		"contentBase64": Marshalls.raw_to_base64(content),
	}, IMPORT_REQUEST_TIMEOUT_SECONDS)

func create_progress(jogador_id: int, pergunta_id: int, acertou: bool, fase: int, sala_id: int = 0, sala_codigo: String = "", casa_atual: int = 0, status_partida: String = "") -> Dictionary:
	var payload: Dictionary = {
		"jogadorId": jogador_id,
		"perguntaId": pergunta_id,
		"acertou": acertou,
		"fase": fase,
		"salaId": sala_id if sala_id > 0 else null,
		"salaCodigo": sala_codigo.strip_edges().to_upper() if not sala_codigo.strip_edges().is_empty() else null,
	}
	if casa_atual > 0:
		payload["casaAtual"] = casa_atual
	if not status_partida.strip_edges().is_empty():
		payload["statusPartida"] = status_partida.strip_edges().to_lower()
	return await _request_json(HTTPClient.METHOD_POST, "/progresso", payload)

func finish_player_session(jogador_id: int, casa_atual: int, won: bool) -> Dictionary:
	return await _request_json(HTTPClient.METHOD_PATCH, "/jogadores/%d/finalizar-partida" % jogador_id, {
		"casaAtual": casa_atual,
		"venceu": won,
	})

func update_player_phase(jogador_id: int, fase_atual: int) -> Dictionary:
	return await _request_json(HTTPClient.METHOD_PATCH, "/jogadores/%d/fase" % jogador_id, {
		"faseAtual": fase_atual,
	})

func _request_json(method: HTTPClient.Method, path: String, payload: Variant = null, timeout_seconds: float = REQUEST_TIMEOUT_SECONDS) -> Dictionary:
	var request: HTTPRequest = HTTPRequest.new()
	request.timeout = timeout_seconds
	add_child(request)

	var headers: PackedStringArray = PackedStringArray([
		"Accept: application/json",
		"Content-Type: application/json",
	])
	var body: String = ""
	if payload != null:
		body = JSON.stringify(payload)

	var error: int = request.request(_build_url(path), headers, method, body)
	if error != OK:
		request.queue_free()
		return _error_response(0, "Nao foi possivel iniciar a requisicao (%s)." % error_string(error))

	var result_data: Array = await request.request_completed
	request.queue_free()

	var result: int = int(result_data[0])
	var response_code: int = int(result_data[1])
	var raw_body: PackedByteArray = result_data[3]
	var body_text: String = raw_body.get_string_from_utf8()
	var parsed_body: Variant = _parse_json_body(body_text)

	if result != HTTPRequest.RESULT_SUCCESS:
		return _error_response(response_code, SERVER_UNAVAILABLE_MESSAGE)

	if response_code < 200 or response_code >= 300:
		if _is_server_unavailable_response(response_code, parsed_body):
			return _error_response(response_code, SERVER_UNAVAILABLE_MESSAGE)
		return _error_response(response_code, _extract_error_message(parsed_body))

	return {
		"ok": true,
		"status_code": response_code,
		"data": parsed_body,
		"error": "",
	}

func _build_url(path: String) -> String:
	var normalized_path: String = path if path.begins_with("/") else "/%s" % path
	return "%s%s" % [base_url, normalized_path]

func _load_base_url() -> String:
	var configured_value: Variant = ProjectSettings.get_setting(BASE_URL_SETTING, DEFAULT_BASE_URL)
	return _normalize_base_url(str(configured_value))

func _normalize_base_url(value: String) -> String:
	var trimmed: String = value.strip_edges()
	if trimmed.is_empty():
		return DEFAULT_BASE_URL
	return trimmed.trim_suffix("/")

func _parse_json_body(body_text: String) -> Variant:
	if body_text.strip_edges().is_empty():
		return {}

	var parsed: Variant = JSON.parse_string(body_text)
	return parsed if parsed != null else {"raw": body_text}

func _is_server_unavailable_response(response_code: int, parsed_body: Variant) -> bool:
	if parsed_body is Dictionary:
		var dictionary: Dictionary = parsed_body as Dictionary
		if bool(dictionary.get("cloudflare_error", false)):
			return true
		if dictionary.has("message"):
			return false

	return response_code in [502, 503, 504, 520, 521, 522, 523, 524, 525, 526, 527, 530]

func _extract_error_message(parsed_body: Variant) -> String:
	if parsed_body is Dictionary:
		var dictionary: Dictionary = parsed_body as Dictionary
		var message: Variant = dictionary.get("message", "")
		if message is Array:
			var parts: Array[String] = []
			for item in message:
				parts.append(str(item))
			return " | ".join(parts)
		if message is String and not String(message).is_empty():
			return String(message)

	return "Nao foi possivel concluir a solicitacao. Tente novamente."

func _error_response(status_code: int, message: String) -> Dictionary:
	return {
		"ok": false,
		"status_code": status_code,
		"data": {},
		"error": message,
	}
