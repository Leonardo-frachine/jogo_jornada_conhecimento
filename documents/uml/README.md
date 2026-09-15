# Fontes dos diagramas UML

Os arquivos `.puml` são as fontes editáveis dos PDFs publicados em `documents/`.
Eles foram revisados em 15/09/2026 a partir do cliente Godot e da API NestJS.
O PDF de casos de uso possui duas páginas, uma por perfil, para manter legíveis
as relações `include`, `extend` e as generalizações.
O PDF de atividades foi dividido em nove páginas para manter a leitura confortável:
seis subfluxos do professor e três do aluno. As páginas usam o tema compartilhado
`tema-atividades.iuml` e tamanho A2 paisagem, adequado à quantidade de raias e
decisões do comportamento implementado.

## Validar e renderizar

Com Java 17 e o JAR do PlantUML disponíveis:

```powershell
$fontesUml = Get-ChildItem documents/uml/*.puml | ForEach-Object FullName
java '-Dfile.encoding=UTF-8' -jar plantuml.jar -checkonly $fontesUml
java '-Dfile.encoding=UTF-8' -jar plantuml.jar -tsvg $fontesUml
python -m pip install reportlab svglib
python documents/uml/render_pdfs.py
```

Para atualizar somente o PDF de atividades sem regravar os demais documentos:

```powershell
python documents/uml/render_pdfs.py --diagram activities
```

O PlantUML gera os SVGs versionados, e o script Python os ajusta em páginas A3
para casos de uso e classes, e em A2 paisagem para atividades, preservando os
nomes públicos:

- `documents/Diagrama de Caso de Uso.pdf`
- `documents/Diagrama de Classes UML.pdf`
- `documents/Diagrama de Atividades UML.pdf`

O diagrama de classes cobre o modelo persistido da API. Classes de cena do
Godot não foram misturadas às entidades TypeORM para evitar relações enganosas;
o estado transitório do cliente continua documentado no código em `scripts/`.
No diagrama de atividades, os subfluxos se conectam pelo contexto da sala: o
professor prepara as perguntas e compartilha o código usado pelo aluno. O conteúdo
descreve o estado atual (AS-IS), incluindo regras observadas como dado ponderado,
fallback de dificuldade, sincronização parcial e pontuação remota acumulada.
