# infodengesubmunicipal

Pacote R para preparar dados locais e gerar boletins municipais de arboviroses
com análises submunicipais, gráficos, mapas e tabelas em PDF.
O boletim admite dengue, chikungunya ou as duas doenças no período analisado.
Seções sem notificações no recorte são omitidas. Um período sem notificações
produz uma saída informativa.

## Instalação e requisitos

```r
install.packages("remotes")
remotes::install_github("AlertaDengue/infodengue_intramunicipal")
library(infodengesubmunicipal)
```

O nome do repositório é `infodengue_intramunicipal`; o nome do pacote R é
`infodengesubmunicipal`. O instalador `remotes` resolve também o remoto
`AlertaDengue/AlertTools` declarado no pacote. Para instalar um arquivo fonte
local, prepare as dependências antes de usar `install.packages(..., repos = NULL)`.

Requisitos: R >= 4.1, ggplot2 >= 4.0.0 e o executável [Quarto](https://quarto.org/docs/get-started/).
O pacote R `quarto` é opcional e não substitui o executável. Para PDF, recomendamos:

```sh
quarto install tinytex
```

Os templates verificam as dependências R e não instalam pacotes durante a
renderização. `arrow` é opcional para arquivos Parquet. `nowcaster` e seu ambiente
INLA são necessários somente para solicitar nowcasting; consulte as instruções
específicas desses pacotes antes de habilitá-lo. `Suggests` não é instalado
obrigatoriamente junto com o pacote.

## Dados de entrada

Os arquivos devem estar preparados localmente. O boletim não consulta APIs
internas nem baixa dados durante sua execução. `ler_tabela_local()` lê CSV,
Parquet, RDS, Rda e RData. Arquivos Rda/RData tabulares devem conter um objeto.
A referência espacial admite também os nomes de objeto `ref_submunicipal`
ou `df_intra_ref` em RData. A leitura de CSV preserva `nu_notific`, `id_bairro`
e `nm_bairro` como texto, incluindo zeros à esquerda e sufixos.

### Notificações

| Coluna | Conteúdo |
| --- | --- |
| `municipio_geocodigo` | Identificador do município |
| `nu_notific` | Identificador da notificação; único por agravo |
| `cid10_codigo` | `A90` para dengue, `A920` ou `A92.0` para chikungunya |
| `ano_notif`, `se_notif` | Ano e semana epidemiológicos informados |
| `dt_notific`, `dt_sin_pri`, `dt_digita` | Datas ISO (`YYYY-MM-DD`); início dos sintomas e digitação podem ser ausentes |
| `id_bairro`, `nm_bairro` | Identificação da unidade local; ausência pode impedir alocação |

Os códigos de semanas usam domingo como início e a regra de quatro dias
(`lubridate::epiyear()`/`epiweek()`). Anos com SE 53 são preservados.
Divergências entre códigos informados e datas são contabilizadas no boletim,
sem recalcular os códigos silenciosamente. Códigos de semanas inexistentes são
rejeitados. As três semanas finais são consecutivas, incluindo semanas sem casos.

O pareamento usa nomes normalizados e distância de Levenshtein até dois
caracteres; escolhe o candidato mais próximo e não aloca empates. A base de
referência deve ter identificadores e nomes normalizados únicos. As perdas
consideram notificações não alocadas e não são substituídas por zeros na entrada.

### Histórico municipal de alerta

Pode ser um arquivo único com `arbo` (`dengue`, `chikon` ou `chikungunya`) ou
arquivos separados somente dos agravos necessários. Em arquivos separados,
a função adiciona o agravo. Não é necessário fabricar um arquivo vazio para a
outra doença. Semanas duplicadas por agravo são rejeitadas.

| Coluna | Obrigatória | Conteúdo e ausência |
| --- | --- | --- |
| `SE` | Sim | Semana `YYYYWW` válida |
| `casos` | Sim | Casos observados, não negativos |
| `p_inc100k` | Sim | Incidência municipal, não negativa |
| `nivel` | Sim | Nível de alerta de 1 a 4; pode conter NA |
| `Rt` | Sim | Número reprodutivo; pode conter NA |
| `tempmin` | Sim | Temperatura mínima; pode conter NA |
| `arbo` | No arquivo único | Identificação do agravo |
| `casos_est` | Não | Estimativa fornecida no histórico; sem ela a tabela indica “Indisponível” |
| `receptivo` | Não | Indicador de receptividade fornecido no histórico; ausente permanece NA |
| `lwr`, `upr` | Não | Limites do intervalo do Rt; ausência não cria bandas artificiais |

Casos observados nunca são rotulados automaticamente como estimativas.
A receptividade climática é desenhada a partir de `tempmin`. O histórico municipal
é uma fonte separada das notificações; totais e semanas podem divergir e devem
ser conciliados pela equipe responsável. As curvas de dengue usam início dos
sintomas; tabelas submunicipais e perdas usam a semana de notificação.

### Referência espacial

Forneça um objeto `sf` em RDS/RData com nome e ID da unidade, agrupamento,
população e geometria. Informe os nomes reais das colunas ao gerador. A população
dos agrupamentos inclui todas as unidades da referência, inclusive sem casos.
IDs, nomes normalizados e agrupamentos devem estar preenchidos, com população
positiva e geometria válida. Shapefiles podem ser preparados com `sf::st_read()`
e salvos com `saveRDS()` antes de chamar o gerador.

Não atribua um EPSG geográfico a coordenadas cartesianas sintéticas. Para CRS
locais sem unidade conhecida, o desenho preserva as coordenadas no plano e usa
uma cópia sem a etiqueta de CRS que o GDAL não consegue transformar. A referência
original mantém seu CRS.

## Exemplo reproduzível: Feira Livre

Os dados incluídos são sintéticos: município fictício `999999`, 7.210 notificações
de dengue, 28 bairros e quatro distritos. UF `XX` e os limiares abaixo são apenas
demonstrativos; não são parâmetros estimados para um município real.

```r
library(infodengesubmunicipal)
base <- system.file("extdata", "feira_livre", package = "infodengesubmunicipal")
saida <- file.path(tempdir(), "feira_livre")
dir.create(saida, recursive = TRUE, showWarnings = FALSE)

ref <- sf::st_read(
  file.path(base, "shape", "feira_livre_bairros.shp"),
  options = "ENCODING=UTF-8", quiet = TRUE
)
referencia <- file.path(saida, "referencia.rds")
saveRDS(ref, referencia)

qmd <- criar_qmd_boletim(
  municipio_nome = "Feira Livre", uf = "XX", municipio_geocodigo = 999999,
  ano = 2026, populacao = 250000,
  output_qmd = file.path(saida, "boletim.qmd"),
  notificacoes_path = file.path(base, "notificacoes.csv"),
  historico_alerta_path = file.path(base, "historico_alerta.csv"),
  referencia_path = referencia,
  col_bairro_ref = "nm_bairro", col_bairro_id_ref = "id_bairro",
  col_distrito_ref = "nm_distr", col_pop_ref = "pop",
  col_geometry_ref = attr(ref, "sf_column"),
  limiar_preseason = 5, limiar_epidemico = 50, limiar_posseason = 10,
  limiar_completude = 70,
  nome_unidade_local = "bairro", nome_unidade_local_plural = "bairros",
  nome_agregacao = "distrito", nome_agregacao_plural = "distritos",
  executar_nowcasting = FALSE, overwrite = TRUE
)
```

Para gerar o PDF, use `render = TRUE` na chamada ou execute `quarto render`
com o caminho retornado. Entradas são validadas e gravadas como caminhos
absolutos; renderizar em outra pasta de trabalho não muda a localização dos dados.
A definição do período usa o ano solicitado e a última semana disponível nesse
ano nas fontes de entrada. Dados de anos posteriores não entram no boletim.

A soma populacional do shapefile é 249.990; o histórico usa denominador implícito
de 250.000. O exemplo mantém cada fonte e seu denominador, sem alterar os
originais para igualá-los. Em `202553`, o histórico contém 24 casos e os códigos
das notificações indicam oito; há também divergências de datas nos registros.
O boletim informa a quantidade dessas divergências e preserva os códigos de entrada.

No checkout do repositório, `data-raw/preparar_feira_livre.R` prepara a referência,
e `tools/verificar_boletim.R` reproduz geração e validação em pasta separada:

```sh
Rscript tools/verificar_boletim.R /tmp/feira-livre dengue validar
Rscript tools/verificar_boletim.R /tmp/feira-livre-pdf dengue pdf
```

Os cenários `misto`, `chikungunya`, `vazio` e `logos` são derivados determinísticos
dos dados sintéticos; `nowcasting` solicita o ajuste opcional. Não são dados
reais de chikungunya. No conjunto original, 6.921 notificações são alocadas e
conservadas na grade; 289 não são alocadas.

## Logos, limiares e métodos

`logo_esquerda` e `logo_direita` são opcionais. Quando informados, devem apontar
para imagens PNG válidas; serão copiadas como `logo1.png` e `logo2.png` ao lado
do QMD. Sem argumentos, o cabeçalho não usa logos antigos que estejam na pasta.
`overwrite = TRUE` permite substituir os arquivos gerados. A função protege os
arquivos existentes antes de gravar; não basta renomear JPG/PDF para PNG.

Os três limiares de incidência são obrigatórios, em casos por 100 mil habitantes,
finitos e não negativos; o epidêmico não pode ser menor que os demais. A equipe
usuária fornece seus limiares municipais. Eles não são automaticamente aplicados
como limiares de cada agrupamento. `limiar_completude` é percentual de 0 a 100,
com padrão 70. Nomes de unidades e agrupamentos têm argumentos para singular e plural.

O nowcasting vem desabilitado por padrão. Se solicitado, o boletim identifica
por unidade os estados desabilitado, indisponível, sem dados, ajustado ou falha.
Falhas não são tratadas como ajustes bem-sucedidos. A curva apresenta o ajuste
quando disponível; a tabela municipal usa `casos_est` do histórico. O pacote
não instala `nowcaster` ou INLA durante a renderização.

## API e migração

As funções de entrada agora pertencem ao pacote: `ler_tabela_local()`,
`validar_colunas()`, `preparar_referencia()` e `preparar_historico_alerta()`.
`ultimas_semanas_epi()` gera uma sequência consecutiva pelo calendário.
`completar_dados_bairros()` e sua versão `_novo` preservam semanas válidas e
avisam quantas linhas/notificações ficam fora da grade configurada.

`create_incidence_plot()`, `create_receptivity_plot()` e `create_rt_plot()`
continuam disponíveis, mas emitem aviso de obsolescência. Use as versões
`_novo`, passando os parâmetros explicitamente, ou seus aliases em português
`criar_grafico_incidencia_novo()`, `criar_grafico_receptividade_novo()` e
`criar_grafico_rt_novo()`. Os aliases antigos também encaminham o aviso.

`create_map_panel()` e `criar_painel_mapas()` exibem todos os mapas recebidos,
em ordem, com layout adaptável e uma legenda. Mapas devem compartilhar escalas
compatíveis. Chamadores que desejam só três mapas devem selecioná-los explicitamente.

O gerador e o boletim recebidos como `_v2.R` e `_att.qmd` foram integrados aos
nomes canônicos do pacote. QMDs gerados anteriormente conservam seu código antigo:
regere-os após atualizar o pacote, fornecendo os novos limiares. Nenhum PDF ou
boletim anterior é atualizado automaticamente.

## Preparação opcional com a API pública

O download abaixo é uma etapa manual de preparação, anterior à renderização.
Ele fornece séries municipais agregadas e não substitui as notificações locais.

### Baixar Dados Da API Pública Do InfoDengue

A API pública do InfoDengue pode ser usada para baixar séries municipais
agregadas, conforme a documentação:

```text
https://info.dengue.mat.br/services/api/doc
```

Exemplo em R para baixar dados semanais de dengue de um município:

```r
base_url <- "https://info.dengue.mat.br/api/alertcity"

consulta <- list(
  geocode = 5300108,
  disease = "dengue",
  format = "csv",
  ew_start = 1,
  ew_end = 53,
  ey_start = 2026,
  ey_end = 2026
)

url <- paste0(
  base_url,
  "?",
  paste(names(consulta), consulta, sep = "=", collapse = "&")
)

dados_infodengue <- read.csv(url)
write.csv(
  dados_infodengue,
  "boletins/brasilia/alertcity_dengue.csv",
  row.names = FALSE
)
```

Troque `geocode` pelo código IBGE do município, `disease` por `"dengue"`,
`"chikungunya"` ou `"zika"`, e ajuste as semanas (`ew_start`, `ew_end`) e os
anos epidemiológicos (`ey_start`, `ey_end`) conforme o período do boletim.

Esse endpoint público retorna dados agregados por município. O arquivo de
notificações usado pelo boletim submunicipal deve continuar contendo as
colunas listadas acima, com identificação da unidade local (`id_bairro` e/ou
`nm_bairro`). Se os dados baixados da API forem usados como parte do fluxo de
preparação, transforme-os antes para o formato esperado pelo template.
