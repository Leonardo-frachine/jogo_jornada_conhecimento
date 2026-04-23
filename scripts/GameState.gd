extends Node

const TOTAL_CASAS := 28

var player_name: String = ""
var room_code: String = ""
var score: int = 0
var xp: int = 0
var level: int = 1
var current_house: int = 1
var questions_answered: int = 0
var correct_answers: int = 0
var wrong_answers: int = 0
var game_finished: bool = false
var victory: bool = false
var last_feedback: String = "Prepare-se para a jornada!"

var question_bank := {
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

func start_session(name: String, code: String) -> void:
	player_name = name.strip_edges()
	room_code = code.strip_edges()
	reset_run_stats()
	last_feedback = "Preparando a partida de %s..." % player_name

func reset_run_stats() -> void:
	score = 0
	xp = 0
	level = 1
	current_house = 1
	questions_answered = 0
	correct_answers = 0
	wrong_answers = 0
	game_finished = false
	victory = false
	last_feedback = "Role o dado para iniciar a jornada."

func register_answer(correct: bool, house_index: int) -> int:
	questions_answered += 1
	var difficulty := get_difficulty_for_house(house_index)
	if correct:
		correct_answers += 1
		var gained_points := difficulty * 100
		score += gained_points
		xp += difficulty * 25
		last_feedback = "Resposta correta! +%d pontos." % gained_points
		return gained_points

	wrong_answers += 1
	last_feedback = "Resposta incorreta. Tente novamente na proxima rodada."
	return 0

func update_progress(house_index: int) -> void:
	current_house = clampi(house_index, 1, TOTAL_CASAS)
	level = get_level_for_house(current_house)
	if current_house >= TOTAL_CASAS:
		finish_session(true)

func finish_session(won: bool) -> void:
	game_finished = true
	victory = won
	if won:
		last_feedback = "Jornada concluida com sucesso!"
	else:
		last_feedback = "Fim de partida."

func get_accuracy() -> float:
	if questions_answered <= 0:
		return 0.0
	return float(correct_answers) / float(questions_answered)

func get_accuracy_percent() -> int:
	return int(round(get_accuracy() * 100.0))

func get_level_for_house(house_index: int) -> int:
	if house_index >= 22:
		return 4
	if house_index >= 15:
		return 3
	if house_index >= 8:
		return 2
	return 1

func get_difficulty_for_house(house_index: int) -> int:
	if house_index >= 22:
		return 4
	if house_index >= 15:
		return 3
	if house_index >= 8:
		return 2
	return 1

func get_question_for_house(house_index: int) -> Dictionary:
	return question_bank.get(clampi(house_index, 1, TOTAL_CASAS), question_bank[1]).duplicate(true)
