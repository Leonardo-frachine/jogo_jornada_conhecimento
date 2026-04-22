# 🎮 Jornada do Conhecimento

**Jornada do Conhecimento** é um jogo educacional digital baseado em um tabuleiro gamificado, onde o jogador evolui respondendo perguntas e enfrentando desafios ao longo de uma jornada de aprendizado.

O projeto tem como objetivo tornar o aprendizado mais dinâmico, interativo e envolvente, permitindo que alunos aprendam enquanto jogam e professores acompanhem o desempenho em tempo real.

---

## 📖 História do Jogo (Narrativa)

Inspirado na **Jornada do Herói**, o jogo acompanha o aluno em uma aventura pelo conhecimento:

- **Mundo Comum**: O aluno começa em seu ambiente escolar.
- **Chamado para Aventura**: Surge o convite para iniciar a jornada.
- **Mentor**: Um guia (mascote ou sistema) auxilia com dicas e feedbacks.
- **Travessia do Limiar**: O jogador entra no tabuleiro.
- **Testes e Aliados**: Responde perguntas e enfrenta desafios.
- **Grande Provação**: Fases com maior dificuldade e tempo limitado.
- **Recompensa**: Ganha XP, avança e recebe feedback positivo.
- **Batalha Final**: Desafio final com perguntas mais complexas.
- **Retorno do Herói**: Finaliza o jogo com relatório de desempenho.

---

## 🎯 Conceito do Jogo

- **Gênero**: Educacional / Tabuleiro Digital  
- **Plataforma**: Desenvolvido com Godot  
- **Objetivo**: Chegar ao final do tabuleiro acumulando conhecimento (XP)

O jogador progride conforme responde corretamente às perguntas, enquanto o professor pode gerenciar conteúdos e acompanhar o progresso dos alunos.

---

## 🔄 Core Loop (Loop Principal)

1. Jogar o dado 🎲  
2. Avançar casas no tabuleiro  
3. Responder uma pergunta  
4. Resultado:
   - ✅ Acertou → ganha XP e avança  
   - ❌ Errou → permanece ou retrocede  
5. Repetir até o final  

---

## 🎮 Mecânicas do Jogo

### Controles
- Mouse / Toque → selecionar respostas  
- Clique → rolar o dado  
- Botão confirmar → enviar resposta  
- Menu → pausar ou sair  

### Regras
- **Vitória**: chegar ao final do tabuleiro  
- **Derrota**: atingir limite de erros ou baixo desempenho  

---

## 🧩 Elementos do Jogo

- 👤 **Jogador**: aluno que evolui com base em acertos  
- ❓ **Desafios**: perguntas com níveis de dificuldade  
- 🎁 **Itens**: bônus, dicas e pontuação  
- 👨‍🏫 **Professor (Admin)**:
  - Inserir perguntas manualmente ou via CSV/Excel  
  - Definir conteúdos por disciplina  
  - Acompanhar desempenho dos alunos  
  - Visualizar relatórios detalhados  

---

## 🗺️ Level Design

O jogo segue uma progressão crescente:

> Fácil → Médio → Difícil → Desafio Final

---

## 🖥️ Interface

O jogo possui:

### Para o jogador:
- Pontuação (XP)
- Progresso no tabuleiro
- Feedback de respostas

### Para o professor:
- Gerenciamento de perguntas  
- Importação de planilhas  
- Relatórios de desempenho  
- Acompanhamento dos alunos  

---

## 📊 Sistema de Perguntas (CSV)

### Importação
Formato esperado:
```
Título, Descrição, A, B, C, D, Correta (A-D), Dificuldade (1-6), Pontuação, Tempo
```

### Exportação
Inclui:
- Respostas dos alunos  
- Pontuação  
- Tempo restante  
- Alternativa selecionada  

---

## 🧱 Estrutura do Projeto

A estrutura do projeto segue a organização do Godot, podendo incluir:

```
📁 jogo_jornada_conhecimento
├── 📁 assets        # Imagens, sons, sprites
├── 📁 scenes        # Cenas do jogo (menu, tabuleiro, perguntas)
├── 📁 scripts       # Lógica do jogo (GDScript)
├── 📁 ui            # Interface do usuário
├── 📁 data          # Perguntas e dados (CSV/JSON)
├── 📁 managers      # Controladores (game manager, question manager)
├── 📄 project.godot # Configuração do projeto
```

*(A estrutura pode variar conforme evolução do projeto)*

---

## 🛠️ Ferramentas Utilizadas

- 🎮 **Godot Engine** → Desenvolvimento do jogo  
- 📋 **Trello** → Planejamento e organização das sprints  
- 💻 **GitHub** → Versionamento do código  
- 📊 **Planilhas (CSV/Excel)** → Gerenciamento de perguntas  

---

## 🚀 Objetivo do Projeto

O projeto busca:

- Tornar o aprendizado mais interativo  
- Ajudar professores a identificar dificuldades dos alunos  
- Utilizar gamificação como ferramenta educacional  
- Integrar tecnologia ao ensino de forma prática  

---

## 📌 Status do Projeto

🚧 Em desenvolvimento  

---

## 🤝 Equipe

Desenvolvido por estudantes como parte de projeto acadêmico.
- Guilherme Poit Vasconcelos
- Gustavo Henrique de Oliveira
- Leonardo Dias Frachine
- Nathan Henrique Mariotto Ritz
