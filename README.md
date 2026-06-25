# infodengesubmunicipal

Pacote em R para gerar boletins municipais de arboviroses em escala
submunicipal, a partir de arquivos locais preparados pela equipe usuária.

O objetivo principal é apoiar equipes de vigilância e secretarias estaduais ou
municipais que precisam produzir PDFs localmente, sem depender de acesso a APIs
internas do InfoDengue.

## O Que O Pacote Faz

O pacote ajuda a:

- validar dados locais de notificações;
- padronizar nomes de bairros ou unidades locais;
- combinar notificações com uma referência espacial e populacional;
- calcular perdas de geolocalização por bairro/unidade;
- gerar um arquivo `.qmd` pronto para renderizar um boletim em PDF;
- produzir tabelas, gráficos e mapas básicos para acompanhamento municipal.

A forma recomendada de uso é pela função:

```r
criar_qmd_boletim()
```

Essa função cria um arquivo Quarto (`.qmd`) configurado para um município. O
usuário depois renderiza esse `.qmd` para gerar o PDF.

## Instalação

Se você recebeu um arquivo `.tar.gz` do pacote, instale assim:

```r
install.packages(
  "infodengesubmunicipal_0.0.0.9000.tar.gz",
  repos = NULL,
  type = "source"
)
```

Se estiver instalando a partir de uma pasta local do pacote:

```r
install.packages("devtools")
devtools::install("caminho/para/infodengesubmunicipal")
```

Depois carregue:

```r
library(infodengesubmunicipal)
```

Também é necessário ter o Quarto instalado para transformar o `.qmd` em PDF.
No RStudio recente, o Quarto geralmente já vem incluído.

Se o comando `quarto --version` não funcionar no terminal, instale o Quarto
pelo site oficial:

```text
https://quarto.org/docs/get-started/
```

Depois de instalar, feche e abra novamente o terminal ou o RStudio e confira:

```sh
quarto --version
```

## Organização Recomendada Dos Arquivos

Crie uma pasta para cada município. Por exemplo:

```text
boletins/
└── brasilia/
    ├── notificacoes.parquet
    ├── historico_alerta.csv
    ├── referencia_submunicipal.rds
    └── boletim_brasilia.qmd
```

O pacote não baixa dados automaticamente. Os arquivos devem ser preparados e
salvos localmente pela equipe usuária.

## Arquivo De Notificações

O arquivo de notificações pode ser `.csv`, `.parquet`, `.rds`, `.rda` ou
`.RData`.

Ele deve conter, no mínimo, estas colunas:

| Coluna | Descrição |
| --- | --- |
| `municipio_geocodigo` | Código IBGE do município |
| `dt_notific` | Data da notificação |
| `dt_sin_pri` | Data dos primeiros sintomas |
| `dt_digita` | Data de digitação |
| `se_notif` | Semana epidemiológica da notificação |
| `ano_notif` | Ano epidemiológico da notificação |
| `cid10_codigo` | CID-10 do agravo |
| `id_bairro` | Identificador do bairro ou unidade local |
| `nm_bairro` | Nome do bairro ou unidade local |
| `nu_notific` | Número da notificação |

Os CIDs usados pelo template são:

| CID | Arbovirose |
| --- | --- |
| `A90` | dengue |
| `A92.0` | chikungunya |
| `A928` | zika |

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

## Arquivo De Histórico De Alerta

O histórico de alerta pode ser informado de duas formas.

Opção 1: um único arquivo com dengue e chikungunya, contendo uma coluna `arbo`:

```text
historico_alerta.csv
```

Opção 2: dois arquivos separados:

```text
historico_alerta_dengue.csv
historico_alerta_chikungunya.csv
```

O histórico deve conter, no mínimo:

| Coluna | Descrição |
| --- | --- |
| `SE` | Semana epidemiológica no formato ano + semana, por exemplo `202620` |
| `casos` | Casos observados |
| `p_inc100k` | Incidência por 100 mil habitantes |
| `nivel` | Nível de alerta |
| `Rt` | Número reprodutivo |
| `tempmin` | Temperatura mínima usada na receptividade |
| `arbo` | Arbovirose, apenas se for arquivo único |

Quando forem usados dois arquivos separados, o pacote adiciona `arbo`
automaticamente.

## Arquivo De Referência Submunicipal

Esse arquivo informa a divisão territorial usada no boletim: bairros, regiões
administrativas, distritos, regionais de saúde ou outra unidade local.

Pode ser `.rds`, `.rda` ou `.RData`. O objeto deve ser uma tabela espacial
`sf`, ou uma tabela com uma coluna de geometria compatível com `sf`.

O template espera uma referência com estas informações:

| Informação | Exemplo de coluna |
| --- | --- |
| Nome da unidade local | `nome_bairr`, `RA`, `bairro` |
| Identificador da unidade local | `id_bairro`, `ID_DISTRITO` |
| Agrupamento submunicipal | `distrito`, `RS`, `regional` |
| População | `pop` |
| Geometria | `geometry`, `geom` |

Você informa os nomes reais das colunas ao chamar `criar_qmd_boletim()`. Em
especial, `col_bairro_ref` e `col_bairro_id_ref` indicam quais colunas da
referência serão comparadas com as colunas de unidade local do arquivo de
notificações.

Na prática, o valor informado em `col_bairro_ref` é comparado com a coluna
nominal das notificações (`nm_bairro`), e o valor informado em
`col_bairro_id_ref` é comparado com a coluna de identificador das notificações
(`id_bairro`). Por isso, essas colunas precisam representar a mesma unidade
territorial nos dois arquivos, mesmo que tenham nomes diferentes em cada base.

## Gerar Um QMD Para Um Município

Exemplo para Brasília:

```r
library(infodengesubmunicipal)

criar_qmd_boletim(
  municipio_nome = "Brasília",
  uf = "DF",
  municipio_geocodigo = 5300108,
  ano = 2026,
  populacao = 2817068,
  output_qmd = "boletins/brasilia/boletim_brasilia.qmd",
  notificacoes_path = "boletins/brasilia/notificacoes.parquet",
  historico_alerta_path = "boletins/brasilia/historico_alerta.csv",
  referencia_path = "boletins/brasilia/referencia_submunicipal.rds",
  col_bairro_ref = "RA",
  col_bairro_id_ref = "ID_DISTRITO",
  col_distrito_ref = "RS",
  col_pop_ref = "pop",
  col_geometry_ref = "geom"
)
```

Esse comando cria o arquivo:

```text
boletins/brasilia/boletim_brasilia.qmd
```

O arquivo gerado já contém os caminhos dos dados e a configuração do município.

## Renderizar O PDF

No R:

```r
quarto::quarto_render("boletins/brasilia/boletim_brasilia.qmd")
```

Ou pelo terminal:

```sh
quarto render boletins/brasilia/boletim_brasilia.qmd
```

Também é possível pedir para a função criar e renderizar em seguida:

```r
criar_qmd_boletim(
  municipio_nome = "Brasília",
  uf = "DF",
  municipio_geocodigo = 5300108,
  ano = 2026,
  populacao = 2817068,
  output_qmd = "boletins/brasilia/boletim_brasilia.qmd",
  notificacoes_path = "boletins/brasilia/notificacoes.parquet",
  historico_alerta_path = "boletins/brasilia/historico_alerta.csv",
  referencia_path = "boletins/brasilia/referencia_submunicipal.rds",
  col_bairro_ref = "RA",
  col_bairro_id_ref = "ID_DISTRITO",
  col_distrito_ref = "RS",
  col_pop_ref = "pop",
  col_geometry_ref = "geom",
  render = TRUE
)
```

## Usando Histórico Em Dois Arquivos

Se dengue e chikungunya estiverem separados:

```r
criar_qmd_boletim(
  municipio_nome = "Município Exemplo",
  uf = "UF",
  municipio_geocodigo = 1234567,
  ano = 2026,
  populacao = 100000,
  output_qmd = "boletim_exemplo.qmd",
  notificacoes_path = "dados/notificacoes.parquet",
  historico_alerta_dengue_path = "dados/historico_dengue.csv",
  historico_alerta_chikungunya_path = "dados/historico_chikungunya.csv",
  referencia_path = "dados/referencia_submunicipal.rds"
)
```

## Atualizar Um QMD Existente

Por segurança, a função não sobrescreve um `.qmd` que já existe. Para substituir
um arquivo existente:

```r
criar_qmd_boletim(
  municipio_nome = "Brasília",
  uf = "DF",
  municipio_geocodigo = 5300108,
  ano = 2026,
  populacao = 2817068,
  output_qmd = "boletins/brasilia/boletim_brasilia.qmd",
  notificacoes_path = "boletins/brasilia/notificacoes.parquet",
  historico_alerta_path = "boletins/brasilia/historico_alerta.csv",
  referencia_path = "boletins/brasilia/referencia_submunicipal.rds",
  overwrite = TRUE
)
```

## Erros Comuns

### "arquivo nao encontrado"

Verifique se o caminho informado existe a partir da pasta onde o R está sendo
executado.

Use:

```r
getwd()
file.exists("caminho/do/arquivo.csv")
```

### "nao contem as colunas obrigatorias"

O arquivo foi encontrado, mas alguma coluna esperada está ausente ou com outro
nome. Confira os nomes com:

```r
names(read.csv("arquivo.csv"))
```

Para arquivos `.parquet`:

```r
arrow::read_parquet("arquivo.parquet") |> names()
```

### "Quarto nao encontrado"

Instale o Quarto ou use uma versão recente do RStudio.

Site do Quarto:

```text
https://quarto.org/
```

### Nomes De Bairro Não Casam Com A Referência

O template normaliza nomes removendo acentos e padronizando caixa, mas grafias
muito diferentes ainda podem impedir a alocação. Revise:

- `nm_bairro` nas notificações;
- a coluna de nome da unidade local na referência;
- abreviações, espaços extras e nomes antigos.

## O Que O QMD Gerado Produz

O QMD gerado espelha a estrutura visual do boletim consolidado usado como
referência no projeto. Ele inclui:

- cabeçalho e rodapé do boletim;
- contextualização territorial;
- mapa da divisão local;
- mapa dos agrupamentos submunicipais;
- gráfico de completude dos dados;
- tabela e gráfico de perdas de notificação;
- tabela municipal de situação recente;
- curva de incidência municipal;
- gráfico de receptividade climática;
- comparação da incidência com anos anteriores;
- Rt municipal;
- tabelas por unidade submunicipal;
- curvas de incidência por unidade submunicipal;
- mapas submunicipais para dengue e chikungunya;
- Rt por unidade submunicipal;
- descrição dos indicadores e anexo.

A equipe pode editar textos, títulos e seções do boletim gerado sem alterar o
pacote.

## Observação Sobre Privacidade E Acesso A Dados

O pacote não exige token e não consulta API interna. Todos os dados usados no
boletim são arquivos locais indicados pelo usuário. A responsabilidade por
armazenamento, sigilo e compartilhamento dos dados segue as normas da secretaria
ou instituição responsável.

## Suporte Operacional

Ao pedir ajuda sobre um erro, envie:

- a mensagem completa do erro;
- o trecho do `.qmd` onde o erro ocorreu;
- os nomes das colunas dos arquivos de entrada;
- a versão do R e do Quarto.

Com isso, normalmente é possível identificar rapidamente se o problema está no
caminho do arquivo, no contrato de colunas ou na referência espacial.
