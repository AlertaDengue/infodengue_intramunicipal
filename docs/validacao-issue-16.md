# Implementação e validação da issue #16

## Entrega

- `config_climatica` centraliza modelo, mapeamento de colunas e limiares.
- Modelos suportados: Af, Aw, Awi, AsAw e AsAwi.
- Preparação do histórico, gráfico e parâmetros do AlertTools usam a mesma configuração.
- Modelos somente de umidade não exigem temperatura.
- As comparações são estritas (`>`), incluindo os valores exatamente no limiar.
- Indicadores municipais fornecidos no histórico são preservados.
- Em semanas sem qualquer variável climática exigida, condição climática, receptividade e nível submunicipais ficam indisponíveis. A persistência reinicia após essas lacunas ou semanas ausentes, sem repetir o clima anterior. Rt continua calculado na série completa.
- Configuração omitida mantém Af/tempmin/18 com aviso e nota visível no boletim. Os QMDs registram a configuração utilizada.
- O gráfico apresenta 53 semanas consecutivas, painéis por variável, limiares e estado de indisponibilidade.

## Verificações realizadas

- Suíte completa e testes do pacote instalado: 269 verificações aprovadas, nenhuma falha ou skip; 11 avisos das APIs legadas e do cenário de coluna opcional ausente.
- `R CMD INSTALL` e `R CMD build`: concluídos.
- `R CMD check --no-manual --no-vignettes`, com sugestões não obrigatórias: nenhum ERROR ou WARNING; quatro NOTEs descritas abaixo. Os repositórios externos não estavam acessíveis durante a checagem; as dependências necessárias já estavam instaladas.
- Comparação das condições climáticas dos cinco modelos com as expressões reais do AlertTools, carregando assertthat, stringr e dplyr como no template. Esses carregamentos também são necessários por dependências não declaradas pelo AlertTools instalado.
- Execução completa dos cenários sintéticos `clima-temperatura`, `clima-umidade`, `clima-combinado` e `clima-ausente`. Cada um preservou 7.210 notificações brutas, 6.921 alocadas e conservadas na grade e os indicadores municipais de entrada.
- Quatro PDFs de 13 páginas gerados com Quarto/XeLaTeX. As páginas dos gráficos climáticos foram renderizadas e inspecionadas visualmente: variáveis, unidades, limiares, condição conjunta, legendas e indisponibilidade.
- `git diff --check`: sem erros.

As NOTEs da checagem são: tamanho instalado (5,7 MB, dos quais 4,5 MB em dados), Imports utilizados pelos templates, referências globais de código legado e 427 strings UTF-8 dos dados. Não houve erro de documentação, exemplos ou testes.

## Reprodução

```sh
Rscript tools/verificar_boletim.R /tmp/clima-temperatura clima-temperatura validar
Rscript tools/verificar_boletim.R /tmp/clima-umidade clima-umidade validar
Rscript tools/verificar_boletim.R /tmp/clima-combinado clima-combinado validar
Rscript tools/verificar_boletim.R /tmp/clima-ausente clima-ausente validar
```

Trocar `validar` por `pdf` gera os PDFs. A umidade dos cenários é uma série sintética determinística; os limiares 18 °C e 70% são demonstrativos.

## Revisão necessária

Confirmar os parâmetros oficiais antes de usar em municípios reais. Os cenários não demonstram equivalência com boletins de Joinville, Fortaleza ou Distrito Federal. Aplicar parâmetros municipais aos agrupamentos não é uma calibração específica por distrito. A política de indisponibilidade e reinício de persistência pode mudar alertas submunicipais em séries com lacunas; exige revisão da equipe responsável.

A issue #16 deve permanecer aberta para revisão da implementação e das evidências. Não há merge automático.
