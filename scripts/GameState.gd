extends Node

# Estado global da tentativa do aluno e ponte entre telas, tabuleiro e backend.
signal session_preparation_updated(message: String)

const TOTAL_CASAS := 28
const STATUS_INICIADO := "iniciado"
const STATUS_JOGANDO := "jogando"
const STATUS_FINALIZADO := "finalizado"
const CHARACTER_TEXTURE_PATHS := {
	1: "res://imagens/personagens_animais/cachorro.png",
	2: "res://imagens/personagens_animais/leao.png",
	3: "res://imagens/personagens_animais/tartaruga.png",
	4: "res://imagens/personagens_animais/aguia.png",
	5: "res://imagens/personagens_animais/gato.png",
}
const CHARACTER_NAMES := {
	1: "Cachorro",
	2: "Leão",
	3: "Tartaruga",
	4: "Águia",
	5: "Gato",
}

var player_name: String = ""
var room_code: String = ""
var selected_character_index: int = 1
var selected_character_texture_path: String = str(CHARACTER_TEXTURE_PATHS[1])
var score: int = 0
var persisted_score: int = 0
var xp: int = 0
var level: int = 1
var current_house: int = 1
var questions_answered: int = 0
var correct_answers: int = 0
var wrong_answers: int = 0
var game_finished: bool = false
var victory: bool = false
var last_feedback: String = "Prepare-se para a jornada!"
var player_id: int = 0
var resolved_room_id: int = 0
var backend_ready: bool = false
var session_prepared: bool = false
var backend_error: String = ""
var sync_warning: String = ""
var loaded_questions: Array[Dictionary] = []
var used_question_ids: Array[int] = []
var current_question: Dictionary = {}

var fallback_question_bank: Dictionary = {
	1: {"text": "Quanto e 2 + 2?", "options": ["3", "4", "5"], "correct": 1},
	2: {"text": "Qual e a capital do Brasil?", "options": ["Rio de Janeiro", "Brasilia", "Salvador"], "correct": 1},
	3: {"text": "3 x 3 e igual a?", "options": ["6", "9", "12"], "correct": 1},
	4: {"text": "Qual numero e maior?", "options": ["2", "8", "5"], "correct": 1},
	5: {"text": "A agua em temperatura ambiente fica em qual estado?", "options": ["Solido", "Gasoso", "Liquido"], "correct": 2},
	6: {"text": "5 x 2 e igual a?", "options": ["10", "12", "8"], "correct": 0},
	7: {"text": "O Sol e normalmente percebido como?", "options": ["Frio", "Quente", "Molhado"], "correct": 1},
	8: {"text": "Qual destes numeros e par?", "options": ["3", "7", "8"], "correct": 2},
	9: {"text": "Qual animal costuma voar?", "options": ["Cachorro", "Passaro", "Peixe"], "correct": 1},
	10: {"text": "O formato do planeta Terra e melhor descrito como?", "options": ["Plano", "Redondo", "Quadrado"], "correct": 1},
	11: {"text": "6 + 4 e igual a?", "options": ["9", "10", "11"], "correct": 1},
	12: {"text": "Como o gelo normalmente se apresenta?", "options": ["Quente", "Frio", "Seco"], "correct": 1},
	13: {"text": "2 x 5 e igual a?", "options": ["10", "8", "12"], "correct": 0},
	14: {"text": "Onde o peixe vive?", "options": ["Agua", "Ceu", "Terra"], "correct": 0},
	15: {"text": "Qual destes numeros e impar?", "options": ["4", "7", "10"], "correct": 1},
	16: {"text": "9 + 1 e igual a?", "options": ["10", "11", "9"], "correct": 0},
	17: {"text": "Qual som o gato faz?", "options": ["Late", "Mia", "Voa"], "correct": 1},
	18: {"text": "O cachorro normalmente...", "options": ["Nada no deserto", "Late", "Vive no espaco"], "correct": 1},
	19: {"text": "4 x 2 e igual a?", "options": ["6", "8", "10"], "correct": 1},
	20: {"text": "O fogo e associado a qual sensacao?", "options": ["Frio", "Quente", "Molhado"], "correct": 1},
	21: {"text": "3 + 3 e igual a?", "options": ["5", "6", "7"], "correct": 1},
	22: {"text": "Em qual continente esta o Brasil?", "options": ["Europa", "Africa", "America"], "correct": 2},
	23: {"text": "Qual numero e maior?", "options": ["2", "10", "1"], "correct": 1},
	24: {"text": "A Lua e melhor definida como...", "options": ["Planeta", "Satelite natural", "Estrela"], "correct": 1},
	25: {"text": "5 x 5 e igual a?", "options": ["20", "25", "30"], "correct": 1},
	26: {"text": "A agua pode ser encontrada em qual estado?", "options": ["Somente solido", "Liquido", "Nenhum"], "correct": 1},
	27: {"text": "Um ser humano normalmente precisa de que para viver?", "options": ["Respirar", "Voar", "Hibernar sempre"], "correct": 0},
	28: {"text": "Voce chegou a ultima casa. Pronto para concluir a jornada?", "options": ["Sim", "Nao", "Talvez"], "correct": 0}
}

func start_session(name: String, code: String, character_index: int = 0) -> void:
	# Normaliza a identidade de entrada antes de limpar qualquer tentativa anterior.
	player_name = name.strip_edges()
	room_code = code.strip_edges().to_upper()
	# Indice opcional atualiza o personagem; valor desconhecido volta ao primeiro.
	if character_index > 0:
		selected_character_index = character_index if CHARACTER_TEXTURE_PATHS.has(character_index) else 1
		selected_character_texture_path = str(CHARACTER_TEXTURE_PATHS[selected_character_index])
	player_id = 0
	resolved_room_id = 0
	backend_ready = false
	session_prepared = false
	backend_error = ""
	sync_warning = ""
	loaded_questions.clear()
	used_question_ids.clear()
	current_question.clear()
	reset_run_stats()
	last_feedback = "Preparando a partida de %s..." % player_name

func get_selected_character_texture_path() -> String:
	return selected_character_texture_path

func get_selected_character_name() -> String:
	return str(CHARACTER_NAMES.get(selected_character_index, "Cachorro"))

func prepare_session() -> Dictionary:
	# Reconstroi todo o contexto remoto na ordem sala -> jogador -> perguntas.
	session_prepared = false
	backend_ready = false
	backend_error = ""
	sync_warning = ""
	player_id = 0
	resolved_room_id = 0
	loaded_questions.clear()
	used_question_ids.clear()
	current_question.clear()

	# Codigo e obrigatorio para garantir isolamento do banco de perguntas.
	if room_code.is_empty():
		return _session_failure("Informe o codigo da sala para carregar as perguntas corretas.")

	_emit_session_status("Validando sala informada...")
	var room_response: Dictionary = await ApiClient.fetch_room_by_code(room_code)
	# Falha ao resolver codigo impede criar jogador em turma incorreta.
	if not room_response.get("ok", false):
		return _session_failure("Codigo de sala invalido ou sala nao cadastrada. Confira o codigo informado e tente novamente.")

	var room_data: Dictionary = room_response.get("data", {})
	resolved_room_id = int(room_data.get("id", 0))
	room_code = str(room_data.get("codigo", room_code)).strip_edges().to_upper()
	# Payload sem ID nao e uma sala utilizavel, mesmo que a resposta HTTP tenha sucesso.
	if resolved_room_id <= 0:
		return _session_failure("A sala informada nao possui um identificador valido no servidor.")

	_emit_session_status("Conectando ao backend...")
	var player_response: Dictionary = await ApiClient.create_player(player_name, resolved_room_id, room_code)
	# Jogador precisa existir no backend antes de qualquer progresso ser salvo.
	if not player_response.get("ok", false):
		return _session_failure("Nao foi possivel criar o jogador na API. %s" % player_response.get("error", ""))

	var created_player: Dictionary = player_response.get("data", {})
	player_id = int(created_player.get("id", 0))
	# ID invalido impediria relacionar respostas posteriores.
	if player_id <= 0:
		return _session_failure("A API nao retornou um identificador valido para o jogador.")
	persisted_score = int(created_player.get("pontuacao", 0))
	score = persisted_score

	_emit_session_status("Carregando perguntas da API...")
	var questions_response: Dictionary = await ApiClient.fetch_questions(resolved_room_id)
	# Perguntas da sala precisam carregar antes de abrir o tabuleiro.
	if not questions_response.get("ok", false):
		return _session_failure("Nao foi possivel carregar as perguntas. %s" % questions_response.get("error", ""))

	var normalized_questions: Array[Dictionary] = _normalize_questions(questions_response.get("data", []))
	# Sala sem pergunta valida nao inicia com o fallback, preservando o isolamento por turma.
	if normalized_questions.is_empty():
		return _session_failure("Esta sala ainda nao possui perguntas validas para iniciar a partida.")

	loaded_questions = normalized_questions
	backend_ready = true
	session_prepared = true
	last_feedback = "Sessao iniciada. Role o dado para comecar."
	_emit_session_status("Tudo pronto. Entrando no tabuleiro...")

	return {
		"ok": true,
		"error": "",
	}

func reset_run_stats() -> void:
	# Zera somente os dados da tentativa local e mantem nome, sala e personagem.
	score = 0
	persisted_score = 0
	xp = 0
	level = 1
	current_house = 1
	questions_answered = 0
	correct_answers = 0
	wrong_answers = 0
	game_finished = false
	victory = false
	last_feedback = "Role o dado para iniciar a jornada."
	sync_warning = ""
	current_question.clear()

func register_answer(correct: bool, house_index: int) -> int:
	# Calcula feedback local imediatamente; sincronizacao remota ocorre em seguida.
	questions_answered += 1
	var question: Dictionary = current_question if not current_question.is_empty() else get_question_for_house(house_index)
	var question_points: int = _get_points_for_question(question, house_index)
	var score_delta: int = _get_score_delta(correct, question_points)
	score += score_delta

	# Acerto incrementa estatisticas, XP e pontuacao integral da pergunta.
	if correct:
		correct_answers += 1
		xp += max(25, int(round(float(question_points) / 4.0)))
		last_feedback = "Resposta correta! +%d pontos." % score_delta
		return score_delta

	wrong_answers += 1
	last_feedback = "Resposta incorreta! %d pontos." % score_delta
	return score_delta

func submit_answer_result(correct: bool, house_index: int) -> Dictionary:
	sync_warning = ""

	# Sem sessao remota pronta nao existe jogador para receber o progresso.
	if not backend_ready or player_id <= 0:
		return _sync_failure("Sessao da API nao esta pronta.")

	var question_id := int(current_question.get("id", 0))
	# Perguntas fallback/invalidas sem ID nao podem ser persistidas no historico.
	if question_id <= 0:
		return _sync_failure("Pergunta atual sem identificador valido.")

	var casa_atual := current_house
	# Acerto confirma a casa de destino; erro permanece na casa atual/retorno do jogo.
	if correct:
		casa_atual = clampi(house_index, 1, TOTAL_CASAS)
	var fase: int = get_level_for_house(casa_atual) if correct else level
	var response: Dictionary = await ApiClient.create_progress(
		player_id,
		question_id,
		correct,
		fase,
		resolved_room_id,
		room_code,
		casa_atual,
		STATUS_JOGANDO
	)
	# Falha de sincronizacao restaura a ultima pontuacao confirmada pelo servidor.
	if not response.get("ok", false):
		score = persisted_score
		return _sync_failure("Nao foi possivel registrar o progresso. %s" % response.get("error", ""))

	var progress_data: Dictionary = response.get("data", {})
	persisted_score = int(progress_data.get("pontuacaoTotal", score))
	score = persisted_score

	return response

func sync_finished_session(won: bool) -> Dictionary:
	sync_warning = ""

	# Finalizacao oficial exige jogador persistido e backend disponivel.
	if not backend_ready or player_id <= 0:
		return _sync_failure("Sessao da API nao esta pronta.")

	var response: Dictionary = await ApiClient.finish_player_session(
		player_id,
		current_house,
		won
	)
	# Mantem aviso local se o servidor nao confirmar o encerramento.
	if not response.get("ok", false):
		return _sync_failure("Nao foi possivel registrar o encerramento da partida. %s" % response.get("error", ""))

	return response

func update_progress(house_index: int) -> void:
	# Casa e fase locais acompanham cada passo efetivamente alcancado.
	current_house = clampi(house_index, 1, TOTAL_CASAS)
	level = get_level_for_house(current_house)
	# A ultima casa encerra a tentativa local como vitoria.
	if current_house >= TOTAL_CASAS:
		finish_session(true)

func finish_session(won: bool) -> void:
	game_finished = true
	victory = won
	# Feedback final diferencia conclusao da jornada de encerramento sem vitoria.
	if won:
		last_feedback = "Jornada concluida com sucesso!"
	# Sem vitoria usa mensagem neutra de fim.
	else:
		last_feedback = "Fim de partida."

func get_accuracy() -> float:
	# Sem respostas, retorna zero para evitar divisao por zero.
	if questions_answered <= 0:
		return 0.0
	return float(correct_answers) / float(questions_answered)

func get_accuracy_percent() -> int:
	return int(round(get_accuracy() * 100.0))

func get_level_for_house(house_index: int) -> int:
	# Casas 22 a 28 formam o quarto e ultimo nivel.
	if house_index >= 22:
		return 4
	# Casas 15 a 21 formam o terceiro nivel.
	if house_index >= 15:
		return 3
	# Casas 8 a 14 formam o segundo nivel; anteriores ficam no primeiro.
	if house_index >= 8:
		return 2
	return 1

func get_difficulty_for_house(house_index: int) -> int:
	return get_level_for_house(house_index)

func get_question_for_house(house_index: int) -> Dictionary:
	# Guarda a pergunta sorteada para validar resposta e sincronizar seu ID.
	current_question = _select_question_for_house(house_index)
	return current_question.duplicate(true)

func get_challenge_question_for_house(house_index: int) -> Dictionary:
	# Casa-desafio pede uma dificuldade acima, limitada ao nivel maximo.
	var challenge_level := mini(get_level_for_house(house_index) + 1, 4)
	current_question = _select_question_for_level(house_index, challenge_level)
	current_question["is_challenge"] = true
	return current_question.duplicate(true)

func register_imported_questions(payload: Variant) -> int:
	var normalized_questions: Array[Dictionary] = _normalize_questions(payload)
	var imported_count := 0

	# Percorre o lote normalizado para atualizar perguntas existentes ou inserir novas.
	for question in normalized_questions:
		var question_id := int(question.get("id", 0))
		var replaced := false

		# IDs positivos permitem localizar a mesma pergunta ja carregada.
		if question_id > 0:
			# Procura o ID no cache local da sala.
			for index in range(loaded_questions.size()):
				# Ao encontrar, substitui o conteudo e interrompe a busca.
				if int(loaded_questions[index].get("id", 0)) == question_id:
					loaded_questions[index] = question
					replaced = true
					break

		# Perguntas sem correspondencia sao acrescentadas e contam como novas.
		if not replaced:
			loaded_questions.append(question)
			imported_count += 1

	return imported_count

func _select_question_for_house(house_index: int) -> Dictionary:
	return _select_question_for_level(house_index, get_level_for_house(house_index))

func _select_question_for_level(house_index: int, desired_level: int) -> Dictionary:
	# Cache vazio usa somente o banco fallback local como ultima protecao.
	if loaded_questions.is_empty():
		var fallback := _build_fallback_question(house_index)
		fallback["difficulty"] = desired_level
		fallback["points"] = desired_level * 100
		return fallback

	var candidates: Array[Dictionary] = _collect_candidates(desired_level, false)
	# Sem pergunta exata nao usada, aceita outra dificuldade ainda nao usada.
	if candidates.is_empty():
		candidates = _collect_candidates(desired_level, true)

	# Quando todas foram usadas, limpa o historico para iniciar um novo ciclo.
	if candidates.is_empty():
		used_question_ids.clear()
		candidates = _collect_candidates(desired_level, false)

	# Se nenhum item remoto for valido, retorna uma pergunta local segura.
	if candidates.is_empty():
		return _build_fallback_question(house_index)

	var selected: Dictionary = candidates[randi_range(0, candidates.size() - 1)]
	var selected_id := int(selected.get("id", 0))
	# IDs validos entram na lista para evitar repeticao ate esgotar o banco.
	if selected_id > 0 and not used_question_ids.has(selected_id):
		used_question_ids.append(selected_id)

	return selected.duplicate(true)

func _collect_candidates(level_value: int, include_used: bool) -> Array[Dictionary]:
	var exact_matches: Array[Dictionary] = []
	var fallback_matches: Array[Dictionary] = []

	# Classifica cada pergunta como correspondencia exata ou fallback de dificuldade.
	for question in loaded_questions:
		var question_id := int(question.get("id", 0))
		# No primeiro passe ignora perguntas ja apresentadas ao aluno.
		if not include_used and question_id > 0 and used_question_ids.has(question_id):
			continue

		# Prioriza perguntas do nivel atual da casa.
		if int(question.get("difficulty", 1)) == level_value:
			exact_matches.append(question)
		# Outras dificuldades ficam disponiveis somente como fallback.
		else:
			fallback_matches.append(question)

	# Qualquer correspondencia exata vence o conjunto de fallback.
	if not exact_matches.is_empty():
		return exact_matches

	return fallback_matches

func _normalize_questions(payload: Variant) -> Array[Dictionary]:
	var normalized: Array[Dictionary] = []
	# A API deve enviar lista; outro formato nao produz perguntas utilizaveis.
	if payload is not Array:
		return normalized

	# Valida cada item individualmente para descartar apenas registros ruins.
	for item in payload:
		# Valores que nao sao objetos nao possuem campos de pergunta.
		if item is not Dictionary:
			continue

		var normalized_question: Dictionary = _normalize_question(item)
		# Somente perguntas com alternativas e gabarito coerentes entram no cache.
		if not normalized_question.is_empty():
			normalized.append(normalized_question)

	return normalized

func _normalize_question(raw_question: Dictionary) -> Dictionary:
	var options: Array[String] = []
	# Le as quatro alternativas na ordem fixa esperada pelo gabarito A-D.
	for key in ["alternativaA", "alternativaB", "alternativaC", "alternativaD"]:
		var option_text: String = str(raw_question.get(key, "")).strip_edges()
		# Alternativa vazia nao e adicionada ao conjunto jogavel.
		if not option_text.is_empty():
			options.append(option_text)

	var correct_letter: String = str(raw_question.get("respostaCorreta", "A")).strip_edges().to_upper()
	var correct_index: int = ["A", "B", "C", "D"].find(correct_letter)
	# Exige ao menos duas opcoes e uma letra correta dentro do conjunto realmente carregado.
	if options.size() < 2 or correct_index < 0 or correct_index >= options.size():
		return {}

	var difficulty: int = _parse_difficulty(raw_question.get("dificuldade", 1))
	var points: int = _parse_non_negative_int(raw_question.get("pontuacao", difficulty * 100), difficulty * 100)

	return {
		"id": int(raw_question.get("id", 0)),
		"text": str(raw_question.get("enunciado", "")).strip_edges(),
		"title": str(raw_question.get("titulo", "")).strip_edges(),
		"options": options,
		"correct_index": correct_index,
		"difficulty": difficulty,
		"points": points,
		"subject": str(raw_question.get("materia", "")).strip_edges(),
		"time_limit": _parse_non_negative_int(raw_question.get("tempoLimite", 0), 0),
	}

func _build_fallback_question(house_index: int) -> Dictionary:
	# Clampa a casa e duplica dados para nao alterar o banco fallback compartilhado.
	var fallback: Dictionary = fallback_question_bank.get(
		clampi(house_index, 1, TOTAL_CASAS),
		fallback_question_bank[1],
	)

	return {
		"id": 0,
		"text": str(fallback.get("text", "")),
		"title": "",
		"options": fallback.get("options", []).duplicate(),
		"correct_index": int(fallback.get("correct", 0)),
		"difficulty": get_difficulty_for_house(house_index),
		"points": get_difficulty_for_house(house_index) * 100,
		"subject": "",
		"time_limit": 0,
	}

func _get_points_for_question(question: Dictionary, house_index: int) -> int:
	var default_points: int = get_difficulty_for_house(house_index) * 100
	return _parse_non_negative_int(question.get("points", default_points), default_points)

func _get_score_delta(correct: bool, question_points: int) -> int:
	return question_points if correct else -int(round(float(question_points) / 2.0))

func _parse_difficulty(value: Variant) -> int:
	var numeric_value: int = _parse_non_negative_int(value, -1)
	# Dificuldade numerica valida e limitada aos quatro niveis do tabuleiro.
	if numeric_value > 0:
		return clampi(numeric_value, 1, 4)

	var text_value: String = str(value).strip_edges().to_lower()
	# Textos facil/basico/iniciante mapeiam para o primeiro nivel.
	if text_value.begins_with("f") or text_value.contains("basic") or text_value.contains("inic"):
		return 1
	# Medio/intermediario mapeiam para o segundo nivel.
	if text_value.begins_with("m") or text_value.contains("inter"):
		return 2
	# Dificil/avancado mapeiam para o terceiro nivel.
	if text_value.begins_with("d") or text_value.contains("avanc"):
		return 3
	# Especial/final mapeiam para o quarto nivel.
	if text_value.begins_with("e") or text_value.contains("espec") or text_value.contains("final"):
		return 4

	return 1

func _parse_non_negative_int(value: Variant, default_value: int) -> int:
	# Inteiro pode ser usado diretamente quando nao negativo.
	if value is int:
		return value if value >= 0 else default_value
	# Float e arredondado antes da mesma validacao de faixa.
	if value is float:
		var float_value: int = int(round(value))
		return float_value if float_value >= 0 else default_value

	var text_value: String = str(value).strip_edges()
	# Texto vazio ou nao inteiro usa o fallback informado pelo chamador.
	if text_value.is_empty() or not text_value.is_valid_int():
		return default_value

	var parsed_value: int = text_value.to_int()
	return parsed_value if parsed_value >= 0 else default_value

func _emit_session_status(message: String) -> void:
	last_feedback = message
	session_preparation_updated.emit(message)

func _session_failure(message: String) -> Dictionary:
	# Falha de preparacao bloqueia entrada no tabuleiro e atualiza a tela de loading.
	backend_error = message
	_emit_session_status(message)
	return {
		"ok": false,
		"error": message,
	}

func _sync_failure(message: String) -> Dictionary:
	# Falha posterior mantem o jogo local, mas registra aviso de sincronizacao.
	sync_warning = message
	return {
		"ok": false,
		"error": message,
	}
	# Uma nova preparacao perde IDs e perguntas da sessao anterior, mas preserva a escolha visual.
	# Erro incrementa contador separado e aplica a penalidade calculada.
