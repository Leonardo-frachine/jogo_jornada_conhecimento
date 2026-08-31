extends Node

# Cliente HTTP centralizado: transforma chamadas do jogo no contrato JSON da API.
# Nenhuma tela deve montar respostas de erro brutas por conta propria.
const DEFAULT_BASE_URL := "https://api.nathanmariotto.com.br" # Backend local padrao
const BASE_URL_SETTING := "application/config/api_base_url"
const REQUEST_TIMEOUT_SECONDS := 10.0
const IMPORT_REQUEST_TIMEOUT_SECONDS := 30.0
const AI_REQUEST_TIMEOUT_SECONDS := 45.0
const REPORT_REQUEST_TIMEOUT_SECONDS := 30.0
const SERVER_UNAVAILABLE_MESSAGE := "Servidor temporariamente indisponivel. Tente novamente em alguns minutos."

var base_url: String = DEFAULT_BASE_URL

func _ready() -> void:
	# Permite trocar a API por configuracao de projeto sem editar cada tela.
	base_url = _load_base_url()

func set_base_url(value: String) -> void:
	base_url = _normalize_base_url(value)

func create_player(name: String, sala_id: int = 0, sala_codigo: String = "") -> Dictionary:
	var payload: Dictionary = {
		"nome": name,
	}
	# Envia o ID quando a sala ja foi resolvida internamente.
	if sala_id > 0:
		payload["salaId"] = sala_id
	# O codigo publico e usado no fluxo de entrada digitado pelo aluno.
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

func download_student_report_pdf(room_id: int, player_id: int, professor_id: int) -> Dictionary:
	return await _request_binary(
		"/salas/%d/relatorios/alunos/%d/pdf?professorId=%d" % [room_id, player_id, professor_id],
		"application/pdf"
	)

func download_class_report_pdf(room_id: int, professor_id: int) -> Dictionary:
	return await _request_binary(
		"/salas/%d/relatorios/turma.pdf?professorId=%d" % [room_id, professor_id],
		"application/pdf"
	)

func download_room_report_csv(room_id: int, professor_id: int) -> Dictionary:
	return await _request_binary(
		"/salas/%d/relatorios/respostas.csv?professorId=%d" % [room_id, professor_id],
		"text/csv"
	)

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
	# Tempo zero representa ausencia de limite e nao deve ser enviado como valor invalido.
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
	# O backend possui parser somente para CSV e XLSX.
	if extension != "csv" and extension != "xlsx":
		return _error_response(0, "Selecione um arquivo .csv ou .xlsx.")

	var file := FileAccess.open(file_path, FileAccess.READ)
	# Falha de permissao/caminho e devolvida antes de tentar ler o conteudo.
	if file == null:
		return _error_response(0, "Nao foi possivel abrir o arquivo selecionado.")

	var content: PackedByteArray = file.get_buffer(file.get_length())
	file.close()

	# Upload vazio nao e uma planilha valida e economiza uma requisicao ao backend.
	if content.is_empty():
		return _error_response(0, "O arquivo selecionado esta vazio.")

	return await _request_json(HTTPClient.METHOD_POST, "/perguntas/importar-planilha", {
		"salaId": sala_id,
		"fileName": file_path.get_file(),
		"contentBase64": Marshalls.raw_to_base64(content),
	}, IMPORT_REQUEST_TIMEOUT_SECONDS)

func create_progress(jogador_id: int, pergunta_id: int, acertou: bool, fase: int, sala_id: int = 0, sala_codigo: String = "", casa_atual: int = 0, status_partida: String = "", resposta_escolhida: String = "") -> Dictionary:
	# Campos opcionais viram null para o backend resolver a sala pelo identificador disponivel.
	var payload: Dictionary = {
		"jogadorId": jogador_id,
		"perguntaId": pergunta_id,
		"acertou": acertou,
		"fase": fase,
		"salaId": sala_id if sala_id > 0 else null,
		"salaCodigo": sala_codigo.strip_edges().to_upper() if not sala_codigo.strip_edges().is_empty() else null,
	}
	# Posicao so e enviada quando o jogo ja possui uma casa valida.
	if casa_atual > 0:
		payload["casaAtual"] = casa_atual
	# Status vazio deixa o servidor aplicar a regra oficial de resposta em andamento.
	if not status_partida.strip_edges().is_empty():
		payload["statusPartida"] = status_partida.strip_edges().to_lower()
	# A letra original permite ao backend validar o acerto e compor relatorios auditaveis.
	if resposta_escolhida.strip_edges().to_upper() in ["A", "B", "C", "D"]:
		payload["respostaEscolhida"] = resposta_escolhida.strip_edges().to_upper()
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
	# Cada chamada usa um HTTPRequest isolado e o libera assim que recebe resposta.
	var request: HTTPRequest = HTTPRequest.new()
	request.timeout = timeout_seconds
	add_child(request)

	var headers: PackedStringArray = PackedStringArray([
		"Accept: application/json",
		"Content-Type: application/json",
	])
	var body: String = ""
	# GETs sem payload mantem corpo vazio; demais chamadas serializam JSON.
	if payload != null:
		body = JSON.stringify(payload)

	var error: int = request.request(_build_url(path), headers, method, body)
	# Erro ao iniciar a requisicao ocorre antes de existir um status HTTP.
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

	# Falha de transporte, DNS ou timeout usa mensagem curta para nao quebrar a UI.
	if result != HTTPRequest.RESULT_SUCCESS:
		return _error_response(response_code, SERVER_UNAVAILABLE_MESSAGE)

	# Qualquer status fora de 2xx representa falha do contrato HTTP.
	if response_code < 200 or response_code >= 300:
		# Erros de infraestrutura conhecidos nao exibem o corpo extenso do proxy.
		if _is_server_unavailable_response(response_code, parsed_body):
			return _error_response(response_code, SERVER_UNAVAILABLE_MESSAGE)
		return _error_response(response_code, _extract_error_message(parsed_body))

	return {
		"ok": true,
		"status_code": response_code,
		"data": parsed_body,
		"error": "",
	}

func _request_binary(path: String, accept_type: String) -> Dictionary:
	var request := HTTPRequest.new()
	request.timeout = REPORT_REQUEST_TIMEOUT_SECONDS
	add_child(request)
	var headers := PackedStringArray(["Accept: %s" % accept_type])
	var error := request.request(_build_url(path), headers, HTTPClient.METHOD_GET)
	if error != OK:
		request.queue_free()
		return _error_response(0, "Nao foi possivel iniciar a exportacao (%s)." % error_string(error))

	var result_data: Array = await request.request_completed
	request.queue_free()
	var result := int(result_data[0])
	var response_code := int(result_data[1])
	var response_headers: PackedStringArray = result_data[2]
	var raw_body: PackedByteArray = result_data[3]

	if result != HTTPRequest.RESULT_SUCCESS:
		return _error_response(response_code, SERVER_UNAVAILABLE_MESSAGE)
	if response_code < 200 or response_code >= 300:
		var parsed_body: Variant = _parse_json_body(raw_body.get_string_from_utf8())
		return _error_response(response_code, _extract_error_message(parsed_body))
	if raw_body.is_empty():
		return _error_response(response_code, "O servidor retornou um arquivo vazio.")

	return {
		"ok": true,
		"status_code": response_code,
		"data": raw_body,
		"file_name": _extract_download_filename(response_headers),
		"error": "",
	}

func _extract_download_filename(headers: PackedStringArray) -> String:
	for header in headers:
		var lower_header := header.to_lower()
		if not lower_header.begins_with("content-disposition:"):
			continue
		var marker_index := lower_header.find("filename=")
		if marker_index < 0:
			continue
		var value := header.substr(marker_index + "filename=".length()).strip_edges()
		return value.trim_prefix("\"").trim_suffix("\"")
	return ""

func _build_url(path: String) -> String:
	var normalized_path: String = path if path.begins_with("/") else "/%s" % path
	return "%s%s" % [base_url, normalized_path]

func _load_base_url() -> String:
	var configured_value: Variant = ProjectSettings.get_setting(BASE_URL_SETTING, DEFAULT_BASE_URL)
	return _normalize_base_url(str(configured_value))

func _normalize_base_url(value: String) -> String:
	var trimmed: String = value.strip_edges()
	# Configuracao vazia volta para o dominio oficial em vez de gerar URL relativa.
	if trimmed.is_empty():
		return DEFAULT_BASE_URL
	return trimmed.trim_suffix("/")

func _parse_json_body(body_text: String) -> Variant:
	# Respostas de sucesso sem corpo sao representadas por um dicionario vazio.
	if body_text.strip_edges().is_empty():
		return {}

	var parsed: Variant = JSON.parse_string(body_text)
	return parsed if parsed != null else {"raw": body_text}

func _is_server_unavailable_response(response_code: int, parsed_body: Variant) -> bool:
	# Proxies podem devolver metadados estruturados que identificam falha do tunnel.
	if parsed_body is Dictionary:
		var dictionary: Dictionary = parsed_body as Dictionary
		# Marcador explicito do backend/proxy tem prioridade sobre o codigo HTTP.
		if bool(dictionary.get("cloudflare_error", false)):
			return true
		# Uma mensagem de dominio deve chegar ao usuario, mesmo em status de erro.
		if dictionary.has("message"):
			return false

	return response_code in [502, 503, 504, 520, 521, 522, 523, 524, 525, 526, 527, 530]

func _extract_error_message(parsed_body: Variant) -> String:
	# APIs NestJS normalmente retornam a mensagem em um objeto JSON.
	if parsed_body is Dictionary:
		var dictionary: Dictionary = parsed_body as Dictionary
		var message: Variant = dictionary.get("message", "")
		# Erros de validacao podem trazer varias mensagens; une todas em uma linha legivel.
		if message is Array:
			var parts: Array[String] = []
			# Converte cada detalhe para texto sem assumir o tipo recebido.
			for item in message:
				parts.append(str(item))
			return " | ".join(parts)
		# Uma mensagem unica pode ser exibida diretamente.
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
