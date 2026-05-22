# Relatorio de Cenas Local x Runtime

## 1. Main Scene do projeto
- `Project Settings > Application > Run > Main Scene`: `res://scene/selecao_perfil.tscn`

## 2. Cenas `.tscn` encontradas no projeto
- `res://scene/selecao_perfil.tscn`
- `res://scene/tela_inicial.tscn`
- `res://scene/acesso_professor.tscn`
- `res://scene/painel_professor.tscn`
- `res://scene/loading_screen.tscn`
- `res://scene/game.tscn`
- `res://scene/end_game_screen.tscn`
- `res://ui/settings/SettingsOverlay.tscn`
- `res://ui/settings/root.tscn`
- `res://entitis/player.tscn`

## 3. Fluxo real de runtime (F5)
### Fluxo principal
1. `res://scene/selecao_perfil.tscn`
2. Se aluno: `res://scene/tela_inicial.tscn`
3. Depois: `res://scene/loading_screen.tscn`
4. Depois: `res://scene/game.tscn`
5. Ao finalizar: `res://scene/end_game_screen.tscn`

### Fluxo professor
1. `res://scene/selecao_perfil.tscn`
2. `res://scene/acesso_professor.tscn`
3. `res://scene/painel_professor.tscn`

### Configuracoes
- `res://scripts/SettingsManager.gd` instancia `res://ui/settings/SettingsOverlay.tscn`
- `res://ui/settings/SettingsOverlay.tscn` instancia `res://ui/settings/root.tscn`

## 4. Telas principais e cena oficial definida
| Tela | Cena oficial | Observacoes |
|---|---|---|
| Selecao de perfil / inicio do F5 | `res://scene/selecao_perfil.tscn` | Main Scene oficial |
| Entrada do aluno | `res://scene/tela_inicial.tscn` | Fluxo aluno |
| Login/cadastro do professor | `res://scene/acesso_professor.tscn` | Fluxo professor |
| Lobby/preparacao da partida | `res://scene/loading_screen.tscn` | Tela de carregamento antes do tabuleiro |
| Tabuleiro | `res://scene/game.tscn` | Cena principal de jogo |
| Tela de pergunta | `res://scene/game.tscn` -> `CanvasLayer/JanelaPergunta` | Overlay oficial embutido na cena do tabuleiro |
| Painel do professor | `res://scene/painel_professor.tscn` | Cena oficial unica |
| Dashboard do professor | `res://scene/painel_professor.tscn` -> `PaginaDashboard` | Aba oficial dentro do painel |
| Acompanhamento dos alunos | `res://scene/painel_professor.tscn` -> `PaginaAlunos` | Aba oficial dentro do painel |
| Banco de perguntas | `res://scene/painel_professor.tscn` -> `PaginaPerguntas` | Aba oficial dentro do painel |
| Geracao por IA | `res://scene/painel_professor.tscn` -> `PainelIa/IaArea` | Estrutura fixa agora oficial no `.tscn` |
| Resultado final | `res://scene/end_game_screen.tscn` | Cena oficial |
| Configuracoes | `res://ui/settings/SettingsOverlay.tscn` + `res://ui/settings/root.tscn` | Overlay oficial editavel |

## 5. Scripts ligados a cada tela
- `res://scene/selecao_perfil.tscn` -> `res://scripts/selecao_perfil.gd`
- `res://scene/tela_inicial.tscn` -> `res://scripts/tela_inicial.gd`
- `res://scene/acesso_professor.tscn` -> `res://scripts/acesso_professor.gd`
- `res://scene/painel_professor.tscn` -> `res://scripts/painel_professor.gd`
- `res://scene/loading_screen.tscn` -> `res://scripts/loading_screen.gd`
- `res://scene/game.tscn` -> `res://scripts/game.gd`
- `res://scene/end_game_screen.tscn` -> `res://scripts/end_game_screen.gd`
- `res://ui/settings/SettingsOverlay.tscn` -> `res://ui/settings/SettingsOverlay.gd`
- `res://ui/settings/root.tscn` -> sem script proprio; usado por `SettingsOverlay.tscn`
- `res://entitis/player.tscn` -> `res://scripts/player.gd`

## 6. Referencias de navegacao e carregamento de cenas
### `change_scene_to_file(...)`
- `res://scripts/selecao_perfil.gd`
  - `res://scene/tela_inicial.tscn`
  - `res://scene/acesso_professor.tscn`
- `res://scripts/tela_inicial.gd`
  - `res://scene/selecao_perfil.tscn`
  - `res://scene/loading_screen.tscn`
- `res://scripts/acesso_professor.gd`
  - `res://scene/selecao_perfil.tscn`
  - `res://scene/painel_professor.tscn`
- `res://scripts/loading_screen.gd`
  - `res://scene/game.tscn`
  - `res://scene/selecao_perfil.tscn`
- `res://scripts/game.gd`
  - `res://scene/end_game_screen.tscn`
- `res://scripts/end_game_screen.gd`
  - `res://scene/loading_screen.tscn`
  - `res://scene/selecao_perfil.tscn`
- `res://scripts/painel_professor.gd`
  - `res://scene/acesso_professor.tscn`
- `res://scripts/SettingsManager.gd`
  - `res://scene/selecao_perfil.tscn`

### `preload/load/PackedScene.instantiate(...)`
- `res://scripts/SettingsManager.gd`
  - `preload("res://ui/settings/SettingsOverlay.tscn")`
  - `OVERLAY_SCENE.instantiate()`
- `res://ui/settings/SettingsOverlay.tscn`
  - instancia `res://ui/settings/root.tscn`
- `res://scene/game.tscn`
  - instancia `res://entitis/player.tscn`

## 7. Cenas realmente usadas em runtime
- `res://scene/selecao_perfil.tscn`
- `res://scene/tela_inicial.tscn`
- `res://scene/acesso_professor.tscn`
- `res://scene/painel_professor.tscn`
- `res://scene/loading_screen.tscn`
- `res://scene/game.tscn`
- `res://scene/end_game_screen.tscn`
- `res://ui/settings/SettingsOverlay.tscn`
- `res://ui/settings/root.tscn`
- `res://entitis/player.tscn`

## 8. Cenas antigas, duplicadas ou aparentemente nao usadas
### Arquivos temporarios/antigos sem referencia ativa
- `res://scene/game.tscn1039820304.tmp`
- `res://entitis/player.tscn1214927691.tmp`
- `res://entitis/player.tscn1288935679.tmp`

### Observacao
- Nao foram encontradas referencias ativas para os arquivos `.tmp`.
- Nenhuma cena `.tscn` permanente encontrada parece estar duplicada em uso paralelo.
- `res://ui/settings/root.tscn` nao e cena final de navegacao, mas e usada oficialmente como subcena do overlay de configuracoes.

## 9. Diferenca Local x Remote identificada
### Antes da correcao
- `res://scene/game.tscn` tinha o tabuleiro na cena, mas o HUD e a janela de pergunta eram montados por `scripts/game.gd` em runtime.
- `res://scene/painel_professor.tscn` tinha a estrutura geral do painel, mas a area fixa de IA era montada por `scripts/painel_professor.gd` em runtime.
- `res://ui/settings/root.tscn` nao tinha todos os controles fixos visiveis; `ui/settings/SettingsOverlay.gd` criava elementos faltantes em runtime.

### Depois da correcao
- `res://scene/game.tscn` agora contem oficialmente:
  - `HUD`
  - `HUD/Root/TopPanel`
  - `HUD/Root/FeedbackLabel`
  - `HUD/Root/RollButton`
  - `CanvasLayer/DialogBackdrop`
  - `CanvasLayer/JanelaPergunta`
- `res://scene/painel_professor.tscn` agora contem oficialmente a estrutura fixa da area de IA:
  - descricao
  - formulario
  - botoes principais
  - feedback
  - resumo
  - acoes em lote
  - container da lista
- `res://ui/settings/root.tscn` agora contem oficialmente:
  - `MasterValue`
  - `SfxValue`
  - `VfxText`
  - `VfxToggle`

## 10. Telas montadas por codigo em vez de `.tscn`
### Estrutura fixa que foi movida para `.tscn`
- HUD do tabuleiro
- Overlay fixo da pergunta
- Area fixa de geracao com IA no painel do professor
- Controles faltantes da tela de configuracoes

### Estrutura ainda dinamica por dados e mantida assim de proposito
- Cards do dashboard do professor
- Lista/ranking de alunos
- Cards do banco de perguntas
- Cards de perguntas geradas por IA
- Dialogos utilitarios (`AcceptDialog`, `FileDialog`)
- Overlay de configuracoes ainda animado por script

## 11. Scripts que criam UI por codigo
### Ativos e esperados
- `res://scripts/painel_professor.gd`
  - cria cards dinamicos do dashboard, ranking, banco de perguntas e perguntas geradas
- `res://ui/settings/SettingsOverlay.gd`
  - ainda contem fallback para criar controles ausentes, embora a cena oficial agora ja tenha esses controles
- `res://scripts/loading_screen.gd`
  - cria `AcceptDialog` de erro
- `res://scripts/tela_inicial.gd`
  - cria `AcceptDialog` de validacao
- `res://scripts/painel_professor.gd`
  - cria `FileDialog` para importacao

### Removido do fluxo principal
- `res://scripts/game.gd`
  - nao monta mais HUD nem tela de pergunta por codigo no fluxo principal
- `res://scripts/painel_professor.gd`
  - nao monta mais a estrutura fixa da secao IA por codigo no fluxo principal

## 12. Scripts que alteram layout/aparencia em runtime
- `res://scripts/game.gd`
  - posicionamento responsivo do HUD e da janela de pergunta
  - ajustes visuais via `add_theme_*`
- `res://scripts/painel_professor.gd`
  - responsividade do painel
  - alternancia de abas (`visible`)
  - estilos e cards dinamicos
- `res://scripts/loading_screen.gd`
  - animacoes de `scale`, `self_modulate` e progresso
- `res://scripts/end_game_screen.gd`
  - animacoes de `modulate` e `scale`
- `res://scripts/acesso_professor.gd`
  - alternancia de `GrupoNome.visible`
- `res://ui/settings/SettingsOverlay.gd`
  - animacoes de abertura/fechamento e ajuste de tamanho do painel
- `res://scripts/UITheme.gd`
  - centraliza parte das sobrescritas visuais em runtime

## 13. Caminhos corrigidos / alinhados com cenas oficiais
- O fluxo de navegacao principal ja apontava para as cenas corretas e foi mantido:
  - `selecao_perfil -> tela_inicial`
  - `selecao_perfil -> acesso_professor`
  - `tela_inicial -> loading_screen`
  - `loading_screen -> game`
  - `game -> end_game_screen`
  - `acesso_professor -> painel_professor`
- A correcao principal foi estrutural:
  - o runtime passou a usar a estrutura oficial existente dentro de `game.tscn`
  - o runtime passou a usar a estrutura oficial existente dentro de `painel_professor.tscn`
  - o overlay de configuracoes passou a ter seus controles fixos no `.tscn`

## 14. O que foi movido para cenas editaveis
- `res://scene/game.tscn`
  - HUD
  - labels de status
  - botao de rolar dado
  - fundo do dialogo de pergunta
  - painel de pergunta
  - quatro botoes de resposta
- `res://scene/painel_professor.tscn`
  - descricao da area IA
  - formulario fixo de tema/materia/dificuldade/quantidade/pontuacao/tempo
  - botoes fixos da area IA
  - resumo e feedback da area IA
- `res://ui/settings/root.tscn`
  - labels de valor de volume
  - controles de VFX

## 15. Validacao realizada
### Validacao estatica feita
- leitura do `project.godot` para confirmar `Main Scene`
- mapeamento completo de `.tscn`
- rastreamento de `change_scene_to_file`, `preload`, `instantiate` e `PackedScene`
- rastreamento de criacao de UI por codigo
- rastreamento de scripts que alteram layout/aparencia em runtime
- confirmacao de que os arquivos `.tmp` nao possuem referencia ativa

### Limitacao de execucao
- Nao foi possivel executar testes reais com F5/F6 neste ambiente porque o binario do Godot nao esta disponivel no PATH:
  - `where.exe godot4` -> nao encontrado
  - `where.exe godot` -> nao encontrado

## 16. Estado final esperado apos abrir no editor
- `res://scene/game.tscn` deve mostrar no `Local` o HUD e a janela de pergunta como parte oficial da cena.
- `res://scene/painel_professor.tscn` deve mostrar no `Local` a area fixa de IA como parte oficial da cena.
- `res://ui/settings/root.tscn` deve mostrar no `Local` todos os controles base do overlay de configuracoes.
- O `Remote` continua podendo atualizar dados dinamicos, mas nao deve mais ser necessario para entender a estrutura fixa dessas telas.

## 17. Pendencias / dependencia ainda dinamica
- Ainda existe dependencia de UI dinamica para listas e cards orientados por dados no `painel_professor.gd`.
- Ainda existe aplicacao de tema em runtime via `UITheme.gd` em varias telas.
- Essas partes nao foram removidas porque:
  - fazem parte do comportamento dinamico esperado
  - nao representam troca de cena errada
  - nao alteram endpoint nem regra de negocio

## 18. Conclusao
- O F5 continua partindo de `res://scene/selecao_perfil.tscn`.
- Cada tela principal do fluxo agora tem uma cena oficial unica e editavel no `Local`.
- A maior divergencia estrutural entre `Local` e `Remote` estava em `game.tscn`, `painel_professor.tscn` e `ui/settings/root.tscn`, e essa parte foi trazida para dentro dos `.tscn` oficiais.
