extends CharacterBody2D

# --- CONTROLE ---
var posicoes_das_casas: Array = []
var casa_atual: int = 0
var andando: bool = false
var valor_sorteado: int = 0

var casas_pendentes: Array = []
var casa_pergunta_atual: int = 0
var resposta_correta_atual: int = 0

# --- INTERFACE ---
@onready var sprite_dado = $"../CanvasLayer/SpriteDado"
@onready var janela = $"../CanvasLayer/JanelaPergunta"

@onready var label_pergunta = janela.get_node("PerguntaLabel")
@onready var btn_a = janela.get_node("BotaoA")
@onready var btn_b = janela.get_node("BotaoB")
@onready var btn_c = janela.get_node("BotaoC")

# --- PERGUNTAS ---
var perguntas = {
	1: {"texto": "Quanto é 2+2?", "opcoes": ["3","4","5"], "correta": 1},
	2: {"texto": "Capital do Brasil?", "opcoes": ["SP","Brasília","RJ"], "correta": 1},
	3: {"texto": "3x3?", "opcoes": ["6","9","12"], "correta": 1},
	4: {"texto": "Maior número?", "opcoes": ["2","8","5"], "correta": 1},
	5: {"texto": "Água é?", "opcoes": ["Sólida","Gasosa","Líquida"], "correta": 2},
	6: {"texto": "5x2?", "opcoes": ["10","12","8"], "correta": 0},
	7: {"texto": "Sol é?", "opcoes": ["Frio","Quente","Molhado"], "correta": 1},
	8: {"texto": "Par?", "opcoes": ["3","7","8"], "correta": 2},
	9: {"texto": "Animal que voa?", "opcoes": ["Cachorro","Pássaro","Peixe"], "correta": 1},
	10: {"texto": "Terra é?", "opcoes": ["Plana","Redonda","Quadrada"], "correta": 1},
	11: {"texto": "6+4?", "opcoes": ["9","10","11"], "correta": 1},
	12: {"texto": "Gelo é?", "opcoes": ["Quente","Frio","Seco"], "correta": 1},
	13: {"texto": "2x5?", "opcoes": ["10","8","12"], "correta": 0},
	14: {"texto": "Peixe vive?", "opcoes": ["Água","Céu","Terra"], "correta": 0},
	15: {"texto": "Ímpar?", "opcoes": ["4","7","10"], "correta": 1},
	16: {"texto": "9+1?", "opcoes": ["10","11","9"], "correta": 0},
	17: {"texto": "Gato faz?", "opcoes": ["Late","Mia","Voa"], "correta": 1},
	18: {"texto": "Cachorro?", "opcoes": ["Nada","Late","Nada"], "correta": 1},
	19: {"texto": "4x2?", "opcoes": ["6","8","10"], "correta": 1},
	20: {"texto": "Fogo?", "opcoes": ["Frio","Quente","Molhado"], "correta": 1},
	21: {"texto": "3+3?", "opcoes": ["5","6","7"], "correta": 1},
	22: {"texto": "Brasil?", "opcoes": ["Europa","África","América"], "correta": 2},
	23: {"texto": "Maior?", "opcoes": ["2","10","1"], "correta": 1},
	24: {"texto": "Lua é?", "opcoes": ["Planeta","Satélite","Sol"], "correta": 1},
	25: {"texto": "5x5?", "opcoes": ["20","25","30"], "correta": 1},
	26: {"texto": "Água?", "opcoes": ["Sempre sólida","Líquida","Gasosa"], "correta": 1},
	27: {"texto": "Humano?", "opcoes": ["Respira","Voa","Nada"], "correta": 0},
	28: {"texto": "Final?", "opcoes": ["Sim","Não","Talvez"], "correta": 0}
}

# --- DADO ---
var dados = [
	preload("res://imagens/Dado/Dado/dieWhite_border1.png"),
	preload("res://imagens/Dado/Dado/dieWhite_border2.png"),
	preload("res://imagens/Dado/Dado/dieWhite_border3.png"),
	preload("res://imagens/Dado/Dado/dieWhite_border4.png"),
	preload("res://imagens/Dado/Dado/dieWhite_border5.png"),
	preload("res://imagens/Dado/Dado/dieWhite_border6.png")
]

func _ready():
	await get_tree().process_frame
	
	var grupo_casas = get_parent().get_node_or_null("Casas")
	if grupo_casas:
		for i in range(1, 29):
			var node = grupo_casas.get_node_or_null("StaticBody2D_P" + str(i))
			if node:
				posicoes_das_casas.append(node.global_position)
	
	if posicoes_das_casas.size() > 0:
		global_position = posicoes_das_casas[0]
	
	janela.hide()

func _input(event):
	if event.is_action_pressed("ui_accept") and not andando and not janela.visible:
		valor_sorteado = randi_range(1, 6)
		
		if sprite_dado:
			sprite_dado.texture = dados[valor_sorteado - 1]
		
		preparar_pergunta()

func preparar_pergunta():
	var casa_escolhida: int
	
	# 🔥 PRIORIDADE: usar pendentes se existir
	if casas_pendentes.size() > 0:
		casa_escolhida = casas_pendentes.pick_random()
	else:
		var destino = casa_atual + valor_sorteado
		
		if destino >= posicoes_das_casas.size():
			destino = posicoes_das_casas.size() - 1
		
		casa_escolhida = destino + 1
	
	casa_pergunta_atual = casa_escolhida
	
	var info = perguntas.get(casa_escolhida)
	
	if info:
		label_pergunta.text = info["texto"]
		
		var indices = [0,1,2]
		indices.shuffle()
		
		btn_a.text = info["opcoes"][indices[0]]
		btn_b.text = info["opcoes"][indices[1]]
		btn_c.text = info["opcoes"][indices[2]]
		
		btn_a.set_meta("indice", indices[0])
		btn_b.set_meta("indice", indices[1])
		btn_c.set_meta("indice", indices[2])
		
		resposta_correta_atual = info["correta"]
	
	janela.show()

# --- BOTÕES ---

func _on_botao_a_pressed():
	_verificar(btn_a)

func _on_botao_b_pressed():
	_verificar(btn_b)

func _on_botao_c_pressed():
	_verificar(btn_c)

# --- VERIFICAÇÃO ---

func _verificar(botao: Button):
	var indice = botao.get_meta("indice")
	
	if indice == resposta_correta_atual:
		print("✔ Correto")
		
		# remove se for pendente
		if casa_pergunta_atual in casas_pendentes:
			casas_pendentes.erase(casa_pergunta_atual)
		
		janela.hide()
		andar_casas(valor_sorteado)
		valor_sorteado = 0
	
	else:
		print("❌ Errado")
		
		# 🔥 GUARDA SOMENTE CASAS ANTERIORES (SEM ERRO)
		casas_pendentes.clear()
		
		if casa_atual > 1:
			for i in range(1, casa_atual):
				casas_pendentes.append(i)
		
		print("Pendentes:", casas_pendentes) # debug
		
		janela.hide()
		valor_sorteado = 0

func andar_casas(qtd):
	if qtd == 0 or posicoes_das_casas.is_empty():
		return
	
	andando = true
	
	var destino = casa_atual + qtd
	if destino >= posicoes_das_casas.size():
		destino = posicoes_das_casas.size() - 1
	
	while casa_atual < destino:
		casa_atual += 1
		
		var tween = create_tween()
		tween.tween_property(self, "global_position", posicoes_das_casas[casa_atual], 0.3)
		await tween.finished
	
	andando = false
