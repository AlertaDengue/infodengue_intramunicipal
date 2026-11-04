# infodengueintramunicipal

Pacote R para preparar dados locais e gerar boletins municipais de arboviroses
com análises submunicipais, gráficos, mapas e tabelas em PDF.
O boletim admite dengue, chikungunya ou as duas doenças no período analisado.
Seções sem notificações no recorte são omitidas. Um período sem notificações
produz uma saída informativa.

## Instalação e requisitos

```r
install.packages("remotes")
remotes::install_github("AlertaDengue/infodengue_intramunicipal")
library(infodengueintramunicipal)
```

O pacote usa a grafia `infodengueintramunicipal`, pois nomes de pacotes R
não permitem sublinhados. O instalador `remotes` resolve também o remoto
`AlertaDengue/AlertTools` declarado no pacote. Para instalar um arquivo fonte
local, prepare as dependências antes de usar `install.packages(..., repos = NULL)`.

Requisitos: R >= 4.1, ggplot2 >= 4.0.0 e o executável [Quarto](https://quarto.org/docs/get-started/).
O pacote R `quarto` é opcional e não substitui o executável. Para PDF, recomendamos:

```sh
quarto install tinytex
```

Os templates verificam as dependências R e não instalam pacotes durante a
renderização. `arrow` é opcional para arquivos Parquet. Para habilitar
`executar_nowcasting = TRUE`, instale a versão mais recente do `nowcaster`
diretamente do GitHub, que inclui o modelo `nowcasting_mgcv()` (sem INLA):

```r
remotes::install_github("covid19br/nowcaster", dependencies = NA, upgrade = "never")
```

`Suggests` não é instalado obrigatoriamente junto com o pacote. O comando acima
instala as dependências obrigatórias do nowcaster, sem solicitar o INLA opcional.

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
| Colunas climáticas | Conforme o modelo | Temperatura mínima e/ou umidade mínima/máxima, configuradas em `config_climatica`; podem conter NA |
| `arbo` | No arquivo único | Identificação do agravo |
| `casos_est` | Não | Estimativa fornecida no histórico; sem ela a tabela indica “Indisponível” |
| `receptivo` | Não | Indicador de receptividade fornecido no histórico; ausente permanece NA |
| `lwr`, `upr` | Não | Limites do intervalo do Rt; ausência não cria bandas artificiais |

Casos observados nunca são rotulados automaticamente como estimativas.
O gráfico climático usa as variáveis e os limiares de `config_climatica`.
Ele não substitui o indicador municipal `receptivo`. O histórico municipal
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

As tres bases tambem sao dados nativos do pacote, acessiveis diretamente:

```r
library(infodengueintramunicipal)
infodengueintramunicipal::historico_alerta
infodengueintramunicipal::notificacoes_alerta
infodengueintramunicipal::referencia_intramunicipal

# Carregamento individual com data()
data("historico_alerta", package = "infodengueintramunicipal")
data("notificacoes_alerta", package = "infodengueintramunicipal")
data("referencia_intramunicipal", package = "infodengueintramunicipal")

# Ou as tres bases reunidas em uma lista
data(dados, package = "infodengueintramunicipal")
names(dados)
notificacoes <- dados$notificacoes_alerta
```

A grafia do objeto de notificacoes e `notificacoes_alerta`.
As tabelas preservam identificadores textuais e datas; a referencia e um objeto
`sf` com o CRS local original. Os arquivos em `extdata` continuam disponiveis
para o gerador de boletins, que recebe caminhos:

```r
library(infodengueintramunicipal)
base <- system.file("extdata", "feira_livre", package = "infodengueintramunicipal")
saida <- file.path(tempdir(), "feira_livre")
dir.create(saida, recursive = TRUE, showWarnings = FALSE)

ref <- sf::st_read(
  file.path(base, "shape", "feira_livre_bairros.shp"),
  options = "ENCODING=UTF-8", quiet = TRUE
)
referencia <- file.path(saida, "referencia.rds")
saveRDS(ref, referencia)

criar_qmd_boletim(
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
  config_climatica = list(
    modelo = "Af", colunas = list(temp_min = "tempmin"),
    limiares = list(temp_min = 18) # Demonstrativo; confirme os parâmetros municipais.
  ),
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

## Configuração climática municipal

Informe `config_climatica` em `criar_qmd_boletim()` com os parâmetros oficiais
do município. O pacote não escolhe o modelo pela localização nem estima limiares.
Os exemplos abaixo são **sintéticos**, não são parâmetros confirmados de Joinville,
Fortaleza ou Distrito Federal.

```r
# Temperatura mínima apenas
clima_temperatura <- list(
  modelo = "Af", colunas = list(temp_min = "tempmin"),
  limiares = list(temp_min = 18)
)

# Umidade máxima apenas: não exige coluna de temperatura
clima_umidade <- list(
  modelo = "Aw", colunas = list(umid_max = "umidmax"),
  limiares = list(umid_max = 70)
)

# Temperatura mínima E umidade máxima
clima_combinado <- list(
  modelo = "AsAw", colunas = list(temp_min = "tempmin", umid_max = "umidmax"),
  limiares = list(temp_min = 18, umid_max = 70)
)
# Passe, por exemplo, config_climatica = clima_combinado ao gerador.
```

| Modelo AlertTools | Chaves exigidas em `colunas` e `limiares` |
| --- | --- |
| `Af` | `temp_min` |
| `Aw` | `umid_max` |
| `Awi` | `umid_min` |
| `AsAw` | `temp_min` e `umid_max` |
| `AsAwi` | `temp_min` e `umid_min` |

Os valores de `colunas` são os nomes reais no histórico de entrada. Temperatura
é expressa em °C e umidade em percentual (0 a 100). A preparação preserva as
colunas originais e adiciona nomes canônicos e `clima_favoravel`; rejeita colisões
com dados diferentes. O QMD registra a configuração para reprodução do boletim.
`preparar_historico_alerta()` e `create_receptivity_plot_novo()` também recebem
`config_climatica`, assim como o alias `criar_grafico_receptividade_novo()`.

Todas as variáveis selecionadas devem ser **estritamente maiores** que seus
limiares na mesma semana, como nas regras do AlertTools. A igualdade não é
favorável. O gráfico apresenta as últimas 53 semanas consecutivas, com painéis
separados e escalas próprias para temperatura e umidade. Azul indica condição
conjunta favorável, cinza desfavorável e amarelo-claro indisponibilidade.

Uma coluna exigida ausente ou com valores inválidos interrompe a execução.
Se faltar o valor de qualquer variável climática em uma semana, a condição
climática, a receptividade e o nível de alerta **submunicipais** ficam
indisponíveis. Nos alertas, a persistência temporal reinicia após a lacuna,
sem repetir o clima da semana anterior. Rt continua calculado na série completa.

A condição do gráfico considera somente clima. O `receptivo` calculado pelo
AlertTools também considera presença de casos; o nível inclui critérios de
transmissão, incidência e persistência próprios do modelo. Os níveis e o
`receptivo` municipais recebidos no histórico são preservados. Aplicar parâmetros
municipais aos agrupamentos não significa que foram calibrados por distrito.

Para compatibilidade, omitir `config_climatica` ainda seleciona `Af`, `tempmin`
e 18 °C, com aviso e nota visível no boletim para confirmar esses parâmetros.
Os argumentos antigos `limiar_temp`/`temp_col` do gráfico (e os equivalentes em
português) continuam aceitos com aviso, mas não podem ser combinados com a nova
configuração. O comparador do gráfico foi corrigido de `>=` para `>`; resultados
no limite podem mudar. A função antiga `create_receptivity_plot()` permanece
obsoleta. Regere os QMDs antigos: atualizar o pacote não atualiza seu conteúdo.

Para reproduzir os cenários sintéticos:

```sh
Rscript tools/verificar_boletim.R /tmp/clima-temperatura clima-temperatura validar
Rscript tools/verificar_boletim.R /tmp/clima-umidade clima-umidade validar
Rscript tools/verificar_boletim.R /tmp/clima-combinado clima-combinado validar
Rscript tools/verificar_boletim.R /tmp/clima-ausente clima-ausente validar
# Troque validar por pdf para gerar o PDF.
```

## Logos, limiares e métodos

O logo oficial do InfoDengue vem incluído no pacote e aparece sempre à esquerda
do cabeçalho, copiado como `logo1.png` ao lado do QMD. Somente `logo_direita`
é configurável: informe uma imagem PNG válida, copiada como `logo2.png`.
Sem esse argumento, o lado direito fica vazio, mesmo que haja um logo antigo na pasta.
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
usa `nowcaster::nowcasting_mgcv()` e não precisa do INLA. Dependências não são
instaladas durante a renderização. A janela máxima de atraso é de 15 semanas,
conforme o padrão do nowcaster para esse modelo.

## API e migração

O pacote foi renomeado de `infodengesubmunicipal` para `infodengueintramunicipal`.
Após reinstalar, atualize `library()`, chamadas `::` e `package =` nos seus
scripts e gere novamente os boletins. O argumento `logo_esquerda` foi removido:
o logo do InfoDengue agora é fixo e somente `logo_direita` deve ser informado.

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
