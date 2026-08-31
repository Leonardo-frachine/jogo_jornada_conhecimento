# Backlog do produto

## Exportacao de relatorios de desempenho

Status da iniciativa: **Concluida no MVP em 31/08/2026**
Publico-alvo: **Professor**
Contexto: **Painel do professor, sempre dentro da sala selecionada**

### Objetivo da iniciativa

Permitir que o professor retire do sistema os dados de desempenho dos alunos em dois formatos complementares:

- um PDF individual, visual e pronto para leitura, compartilhamento ou impressao;
- um CSV da sala, estruturado para conferencia, analises proprias e importacao em ferramentas como Power BI, Excel ou Google Sheets.

### Decisoes de escopo para a primeira entrega

- O PDF representa um aluno da sala selecionada.
- O PDF considera todo o historico disponivel desse aluno na sala e informa o periodo efetivamente analisado.
- O CSV representa todos os alunos e todas as respostas da sala selecionada.
- Cada linha do CSV representa uma resposta a uma pergunta. Esse formato evita colunas repetidas por pergunta e e o mais apropriado para BI.
- Os numeros apresentados no PDF e no CSV devem ser produzidos pela mesma camada de relatorio, evitando divergencias entre os formatos.
- Filtros por periodo, exportacao de uma tentativa especifica e exportacao de PDFs em lote ficam fora do MVP.

---

## REL-001 — Exportar relatorio detalhado de um aluno em PDF

Status: **Concluida**
Tipo: **Feature**
Prioridade sugerida: **Alta**

### Historia de usuario

Como professor, quero exportar um relatorio profissional e detalhado de um aluno da sala selecionada, para compreender seu desempenho, reconhecer seus pontos fortes, identificar dificuldades e compartilhar uma devolutiva de facil leitura.

### Resultado esperado

Ao selecionar um aluno na pagina de acompanhamento, o professor podera acionar **Exportar PDF** e receber um documento A4, paginado e identificado, com resumo executivo, analise de desempenho e detalhamento das respostas incorretas.

### Conteudo obrigatorio do PDF

#### 1. Identificacao

- nome e identidade visual do projeto;
- titulo `Relatorio individual de desempenho`;
- nome do aluno;
- nome e codigo da sala;
- nome do professor;
- periodo analisado, da primeira a ultima resposta considerada;
- data e hora de geracao do documento;
- situacao atual da jornada: nao iniciada, em andamento ou finalizada.

#### 2. Resumo executivo

- pontuacao acumulada;
- fase e casa atuais;
- total de perguntas respondidas;
- total de acertos;
- total de erros;
- percentual de aproveitamento;
- data da ultima atividade.

Os totais devem sempre respeitar as seguintes regras:

- `respondidas = acertos + erros`;
- `aproveitamento = acertos / respondidas * 100`;
- quando nao houver respostas, o aproveitamento deve ser apresentado como `0%`, sem divisao por zero ou informacao enganosa.

#### 3. Desempenho pedagogico

- desempenho por materia, contendo quantidade respondida, acertos, erros e percentual de acerto;
- desempenho por nivel de dificuldade, com os mesmos indicadores;
- representacao visual legivel, como barras de desempenho e indicadores resumidos;
- identificacao objetiva de pontos fortes e pontos a desenvolver.

Classificacao recomendada para o MVP:

- **Ponto forte:** aproveitamento maior ou igual a 75%;
- **Em desenvolvimento:** aproveitamento entre 50% e 74%;
- **Ponto a desenvolver:** aproveitamento menor que 50%;
- grupos com menos de 3 respostas devem ser marcados como **Amostra insuficiente** e nao devem gerar uma conclusao forte ou fraca.

Se nenhuma materia possuir amostra suficiente, o documento deve informar isso claramente, em vez de inventar uma conclusao.

#### 4. Detalhamento dos erros

Para cada resposta incorreta, exibir:

- data e hora da resposta;
- materia;
- dificuldade;
- fase;
- titulo e/ou enunciado da pergunta;
- alternativa escolhida pelo aluno, com letra e texto;
- alternativa correta, com letra e texto;
- pontos descontados ou nao obtidos, conforme a regra do jogo.

As respostas incorretas devem ser ordenadas da mais recente para a mais antiga. Caso o aluno nao possua erros, o relatorio deve apresentar uma mensagem positiva e nao renderizar uma tabela vazia.

#### 5. Encerramento

- sintese curta e deterministica, baseada nos indicadores do relatorio;
- recomendacoes objetivas de revisao das materias com menor aproveitamento;
- rodape com data de geracao, numero da pagina e identificacao da sala.

O MVP nao deve usar IA generativa para produzir conclusoes pedagogicas. Os textos devem seguir regras previsiveis, auditaveis e coerentes com os dados.

### Requisitos de apresentacao

- layout A4, preferencialmente em orientacao retrato;
- identidade visual coerente com o painel do professor;
- tipografia legivel e contraste adequado;
- informacoes importantes nao podem depender somente de cores;
- tabelas longas devem continuar em novas paginas sem cortar linhas;
- cabecalhos de tabelas devem se repetir nas paginas seguintes;
- graficos, textos e tabelas nao podem ficar sobrepostos;
- caracteres do portugues devem ser renderizados corretamente;
- nome sugerido do arquivo: `relatorio_<aluno>_<sala>_<AAAA-MM-DD>.pdf`, com caracteres invalidos removidos.

### Fluxo de interface

1. O professor acessa **Acompanhamento dos alunos**.
2. O professor seleciona ou localiza um aluno da sala atual.
3. O professor aciona **Exportar PDF**.
4. A interface apresenta estado de processamento e impede cliques duplicados.
5. Em caso de sucesso, o arquivo e salvo ou disponibilizado para download.
6. Em caso de falha, o professor recebe uma mensagem clara e pode tentar novamente.

O botao deve ficar desabilitado quando nenhuma sala ou nenhum aluno estiver selecionado.

### Contrato tecnico sugerido

- Endpoint: `GET /salas/:salaId/relatorios/alunos/:jogadorId/pdf`.
- Resposta de sucesso: `application/pdf`.
- A resposta deve definir `Content-Disposition` com um nome de arquivo seguro.
- A geracao deve ocorrer no backend para manter o documento consistente em todos os clientes.
- O servico deve validar que o aluno pertence a sala informada.
- O acesso deve validar que a sala pertence ao professor autenticado.

### Subtarefas tecnicas

- [x] Criar um modelo unico de dados para o relatorio individual.
- [x] Implementar os agregados por materia e dificuldade.
- [x] Implementar as regras de pontos fortes, desenvolvimento e amostra insuficiente.
- [x] Criar e estilizar o template do PDF.
- [x] Implementar o endpoint binario de exportacao.
- [x] Integrar o download ao painel do professor.
- [x] Tratar estado sem respostas e dados historicos incompletos.
- [x] Cobrir o servico, endpoint e template com testes.
- [x] Renderizar PDFs de teste e realizar verificacao visual de uma e varias paginas.

### Criterios de aceite

- [x] O professor consegue exportar o PDF a partir do aluno e da sala selecionados.
- [x] O PDF identifica corretamente professor, sala e aluno.
- [x] Acertos, erros, respondidas, aproveitamento e pontuacao coincidem com os registros da API.
- [x] O PDF apresenta desempenho por materia e dificuldade.
- [x] Pontos fortes e pontos a desenvolver obedecem aos limites definidos e nao classificam amostras insuficientes.
- [x] Cada erro mostra a pergunta, a resposta escolhida e a resposta correta.
- [x] Um aluno sem respostas gera um relatorio valido com estado vazio, sem erro tecnico.
- [x] Um aluno sem erros gera um relatorio valido e sem tabela vazia.
- [x] Um relatorio longo quebra paginas corretamente e permanece legivel.
- [x] A exportacao preserva acentos e caracteres especiais.
- [x] Nao e possivel gerar o relatorio de um aluno pertencente a outra sala.
- [x] Nao e possivel acessar o relatorio de uma sala pertencente a outro professor.

### Fora do escopo do MVP

- envio do PDF por e-mail ou mensageria;
- edicao manual do texto do relatorio;
- relatorio comparativo entre alunos;
- exportacao em lote de todos os PDFs da sala;
- analise ou recomendacoes geradas por IA;
- filtro por uma tentativa especifica.

---

## REL-002 — Exportar dados de desempenho da sala em CSV

Status: **Concluida**
Tipo: **Feature**
Prioridade sugerida: **Alta**

### Historia de usuario

Como professor, quero exportar os dados detalhados de respostas da sala em CSV, para conferir os dados usados nos relatorios e criar analises proprias em ferramentas de planilha ou BI.

### Resultado esperado

No contexto da sala selecionada, o professor podera acionar **Exportar CSV** e receber uma base tabular com uma linha por resposta registrada, pronta para importacao no Power BI, Excel, Google Sheets e ferramentas equivalentes.

### Granularidade do arquivo

- uma linha representa uma resposta de um aluno a uma pergunta;
- o arquivo inclui somente dados da sala selecionada;
- todos os alunos que responderam ao menos uma pergunta aparecem no arquivo;
- alunos sem respostas nao geram linhas, pois o arquivo representa eventos de resposta;
- as linhas sao ordenadas por data de resposta e, em caso de empate, pelo identificador do progresso.

### Colunas obrigatorias

| Coluna | Descricao |
| --- | --- |
| `progresso_id` | Identificador unico do evento de resposta. |
| `sala_id` | Identificador interno da sala. |
| `sala_nome` | Nome da sala. |
| `sala_codigo` | Codigo publico da sala. |
| `professor_id` | Identificador do professor proprietario. |
| `professor_nome` | Nome do professor. |
| `aluno_id` | Identificador do aluno na sala. |
| `aluno_nome` | Nome de exibicao do aluno. |
| `pergunta_id` | Identificador da pergunta. |
| `pergunta_titulo` | Titulo da pergunta, quando houver. |
| `pergunta_enunciado` | Enunciado apresentado ao aluno. |
| `materia` | Materia da pergunta. |
| `dificuldade` | Dificuldade da pergunta. |
| `fase` | Fase informada no momento da resposta. |
| `casa_atual` | Casa alcancada apos a resposta. |
| `resposta_escolhida_letra` | Alternativa marcada pelo aluno. |
| `resposta_escolhida_texto` | Texto da alternativa marcada. |
| `resposta_correta_letra` | Alternativa correta. |
| `resposta_correta_texto` | Texto da alternativa correta. |
| `acertou` | Valor booleano `true` ou `false`. |
| `pontuacao_base` | Pontuacao prevista para a pergunta no momento da resposta. |
| `pontuacao_ganha` | Pontos ganhos ou descontados no evento. |
| `respondido_em` | Data e hora da resposta em ISO 8601, incluindo fuso horario. |

Os nomes das colunas nao devem conter espacos ou acentos, facilitando seu uso como campos em ferramentas de BI.

### Regras do formato

- codificacao UTF-8 com BOM, para preservar caracteres do portugues e melhorar a abertura direta em planilhas;
- cabecalho presente na primeira linha;
- virgula (`,`) como separador padrao em todo o arquivo;
- campos que contenham separador, aspas ou quebra de linha devem ser escapados corretamente conforme RFC 4180;
- valores ausentes devem ser representados por campo vazio, sem textos como `null` ou `undefined`;
- datas devem usar ISO 8601;
- numeros devem ser exportados sem separador de milhar;
- booleanos devem usar sempre `true` ou `false`;
- nome sugerido do arquivo: `desempenho_<sala>_<AAAA-MM-DD>.csv`, com caracteres invalidos removidos.

### Fluxo de interface

1. O professor seleciona uma sala.
2. O professor aciona **Exportar CSV** no dashboard ou na pagina de acompanhamento.
3. A interface apresenta estado de processamento e impede cliques duplicados.
4. Em caso de sucesso, o arquivo e salvo ou disponibilizado para download.
5. Em caso de sala sem respostas, o sistema gera um CSV contendo apenas o cabecalho e informa que nao havia registros.
6. Em caso de falha, o professor recebe uma mensagem clara e pode tentar novamente.

O botao deve ficar desabilitado quando nenhuma sala estiver selecionada.

### Contrato tecnico sugerido

- Endpoint: `GET /salas/:salaId/relatorios/respostas.csv`.
- Resposta de sucesso: `text/csv; charset=utf-8`.
- A resposta deve definir `Content-Disposition` com um nome de arquivo seguro.
- A exportacao deve reutilizar o mesmo modelo de dados que alimenta o PDF.
- O acesso deve validar que a sala pertence ao professor autenticado.
- Para volumes grandes, a implementacao deve evitar carregar copias desnecessarias de todo o arquivo em memoria.

### Subtarefas tecnicas

- [x] Definir e versionar o contrato das colunas do CSV.
- [x] Criar o serializador com escape correto de campos.
- [x] Implementar o endpoint de exportacao da sala.
- [x] Integrar o download ao painel do professor.
- [x] Tratar sala sem respostas.
- [x] Criar testes com acentos, virgulas, aspas e quebras de linha nos textos.
- [x] Validar o contrato tabular, a codificacao e o escape para importacao em ferramentas de planilha e BI.

### Criterios de aceite

- [x] O professor consegue exportar o CSV da sala selecionada.
- [x] O arquivo possui exatamente uma linha por resposta, alem do cabecalho.
- [x] O arquivo nunca inclui respostas de outra sala.
- [x] Todas as colunas obrigatorias estao presentes e na ordem documentada.
- [x] Pergunta, resposta escolhida, resposta correta, resultado e pontuacao correspondem ao historico do sistema.
- [x] A soma de `acertou = true` e `acertou = false` por aluno reproduz os totais usados no PDF.
- [x] Textos com acentos, separadores, aspas e quebras de linha podem ser importados sem corromper colunas.
- [x] O arquivo segue UTF-8 com BOM e CSV RFC 4180, contrato aceito por Power BI e ferramentas de planilha.
- [x] Uma sala sem respostas gera um CSV valido contendo somente o cabecalho.
- [x] Nao e possivel exportar dados de uma sala pertencente a outro professor.

### Fora do escopo do MVP

- produzir o dashboard de BI;
- arquivos XLSX ou Google Sheets;
- escolher manualmente quais colunas exportar;
- combinar varias salas em um unico arquivo;
- agendar exportacoes automaticas;
- filtro por uma tentativa especifica.

---

## Fundacao compartilhada e dependencias

As duas features dependem da mesma qualidade de dados. Esta fundacao deve ser concluida antes da geracao dos arquivos.

### Lacunas identificadas no estado atual

- O progresso registra se o aluno acertou, mas nao registra qual alternativa ele escolheu.
- O relatorio atual consulta a pergunta relacionada. Se o conteudo da pergunta for editado depois da resposta, o historico pode deixar de representar exatamente o que o aluno viu.
- O mesmo cadastro de aluno pode acumular respostas de mais de uma jornada. O MVP sera, por decisao de escopo, um relatorio acumulado por aluno e sala.
- Dados antigos nao terao a alternativa escolhida disponivel e nao devem receber um valor inventado.

### Ajustes necessarios no registro de respostas

- persistir a letra da alternativa escolhida pelo aluno;
- validar no backend se a alternativa pertence a `A`, `B`, `C` ou `D`;
- calcular o campo `acertou` no backend comparando a escolha com a resposta correta, em vez de confiar apenas no booleano enviado pelo cliente;
- persistir um snapshot minimo da pergunta no momento da resposta: titulo, enunciado, materia, dificuldade, resposta escolhida, resposta correta, textos das duas alternativas e pontuacao-base;
- manter `pontuacaoGanha` como valor imutavel do evento;
- para dados legados, usar os dados atuais da pergunta somente como fallback e exibir `Nao registrada` quando a escolha do aluno for desconhecida;
- garantir que PDF e CSV leiam de um unico servico de consulta, agregacao e normalizacao.

### Seguranca e privacidade

- Os endpoints de exportacao devem estar vinculados a uma sessao de professor validada no backend.
- O identificador da sala recebido na URL nao e suficiente como autorizacao.
- O backend deve confirmar que a sala pertence ao professor antes de consultar ou gerar dados.
- Os arquivos nao devem incluir senha, hash de senha, e-mail do professor ou outros campos que nao sejam necessarios ao objetivo pedagogico.
- Erros e logs nao devem expor o conteudo integral do relatorio.

### Compatibilidade com dados historicos

- O sistema deve continuar exportando respostas existentes antes da mudanca do modelo.
- Campos historicos que nao possam ser reconstruidos devem ficar vazios no CSV e aparecer como `Nao registrada` no PDF.
- O relatorio deve evitar classificar como erro de dados uma resposta antiga apenas porque a alternativa escolhida nao foi armazenada.

### Testes compartilhados

- [x] isolamento por professor e sala;
- [x] aluno inexistente ou pertencente a outra sala;
- [x] sala e aluno sem respostas;
- [x] totais e percentuais com zero, uma e varias respostas;
- [x] perguntas inativas ou editadas depois da resposta;
- [x] compatibilidade com registros antigos;
- [x] nomes e enunciados com caracteres especiais;
- [x] consistencia dos mesmos eventos entre PDF, CSV e API;
- [x] relatorio multipagina com quantidade elevada de erros, sem cortes ou paginas vazias.

## Registro da implementacao

Entrega concluida em **31/08/2026** com os seguintes componentes:

- modulo `relatorios` no backend, compartilhando normalizacao e agregacao entre PDF e CSV;
- snapshot imutavel da pergunta e das alternativas no evento de progresso;
- resultado da resposta calculado no backend quando a alternativa escolhida e informada;
- PDF A4 paginado com resumo executivo, analise por materia e dificuldade, pontos fortes, pontos a desenvolver, erros e recomendacoes deterministicas;
- CSV UTF-8 com BOM, uma linha por resposta, escape RFC 4180 e protecao contra interpretacao de formula em planilhas;
- download binario e salvamento por seletor de arquivo no painel do professor;
- testes unitarios e de ponta a ponta, build de producao, validacao estatica dos scripts Godot e verificacao visual de todas as paginas de uma amostra longa.

Nota de seguranca: a entrega respeita o modelo de sessao atualmente existente no projeto e confirma no backend que o `professorId` informado e proprietario da sala. A adocao futura de token assinado ou sessao HTTP centralizada deve proteger de forma uniforme todos os endpoints administrativos, nao apenas os de relatorio.

## Definicao de pronto da iniciativa

A iniciativa sera considerada concluida quando:

- as duas exportacoes estiverem acessiveis no painel do professor;
- PDF e CSV usarem a mesma fonte normalizada de dados;
- todos os criterios de aceite estiverem automatizados quando aplicavel;
- o PDF tiver sido renderizado e revisado visualmente em cenarios curtos e longos;
- o CSV tiver sido importado e conferido em Power BI e planilha;
- a documentacao da API e o README do projeto indicarem os novos endpoints e o fluxo de uso;
- nao houver acesso cruzado entre professores, salas ou alunos.

## Evolucoes futuras sugeridas

- filtro por intervalo de datas;
- identificador de partida/tentativa para relatorios por jornada;
- exportacao de todos os PDFs da sala em arquivo ZIP;
- relatorio comparativo da turma;
- XLSX com abas de resumo, alunos e respostas;
- compartilhamento direto do relatorio;
- agendamento de exportacoes recorrentes.
