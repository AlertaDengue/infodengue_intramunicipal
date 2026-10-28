#' Historico de alerta distribuido com o pacote
#' @description Dados de exemplo legados do repositorio. Para um exemplo explicitamente
#' sintetico e reproduzivel, use os dados de Feira Livre em \code{dados}.
#' @format Objeto tabular de historico de alerta.
"dados_api"

#' Notificacoes distribuidas com o pacote
#' @description Dados de exemplo legados do repositorio. Para um exemplo explicitamente
#' sintetico e reproduzivel, use os dados de Feira Livre em \code{dados}.
#' @format Objeto tabular de notificacoes municipais.
"df_mun"

#' Historico sintetico de alerta de Feira Livre
#'
#' Historico semanal do municipio ficticio 999999, para exemplos e testes.
#' Os valores originais sao preservados; nao ha estimativas `casos_est`.
#' @format Um data.frame com 90 linhas e 10 colunas:
#' \describe{
#'   \item{SE}{Semana epidemiologica no formato YYYYWW.}
#'   \item{casos}{Numero de casos no historico.}
#'   \item{p_inc100k}{Incidencia por 100 mil habitantes.}
#'   \item{Rt, lwr, upr}{Rt e limites de incerteza, ausentes nesta base.}
#'   \item{tempmin}{Temperatura minima em graus Celsius.}
#'   \item{receptivo}{Indicador de receptividade climatica.}
#'   \item{nivel}{Nivel de alerta.}
#'   \item{arbo}{Agravo, dengue nesta base.}
#' }
#' @source Arquivo sintetico `extdata/feira_livre/historico_alerta.csv`.
#' @seealso [dados], [notificacoes_alerta], [referencia_intramunicipal]
#' @examples
#' data("historico_alerta", package = "infodengesubmunicipal")
#' head(historico_alerta)
"historico_alerta"

#' Notificacoes sinteticas de Feira Livre
#'
#' Notificacoes de dengue do municipio ficticio 999999 em 2025 e 2026.
#' Identificadores textuais, datas, valores ausentes e divergencias dos arquivos
#' originais sao preservados; os dados nao representam um municipio real.
#' @format Um data.frame com 7210 linhas e 10 colunas:
#' \describe{
#'   \item{nu_notific}{Identificador textual da notificacao.}
#'   \item{municipio_geocodigo}{Codigo do municipio ficticio, 999999.}
#'   \item{cid10_codigo}{Codigo do agravo, A90 nesta base.}
#'   \item{ano_notif, se_notif}{Ano e semana epidemiologica informados.}
#'   \item{dt_notific, dt_sin_pri, dt_digita}{Datas de notificacao, inicio dos
#'     sintomas e digitacao, em classe Date.}
#'   \item{id_bairro, nm_bairro}{Identificador textual e nome do bairro informado.}
#' }
#' @source Arquivo sintetico `extdata/feira_livre/notificacoes.csv`.
#' @seealso [dados], [historico_alerta], [referencia_intramunicipal]
#' @examples
#' data("notificacoes_alerta", package = "infodengesubmunicipal")
#' head(notificacoes_alerta)
"notificacoes_alerta"

#' Referencia espacial sintetica de Feira Livre
#'
#' Bairros e distritos do municipio ficticio 999999. Preserva o CRS cartesiano
#' local do shapefile; nao atribua um EPSG geografico ficticio.
#' A populacao espacial soma 249990, enquanto o historico usa denominador 250000.
#' @format Um objeto sf com 28 linhas e 6 colunas:
#' \describe{
#'   \item{id_bairro, nm_bairro}{Identificador e nome do bairro.}
#'   \item{id_distr, nm_distr}{Identificador e nome do distrito; quatro distritos.}
#'   \item{pop}{Populacao sintetica do bairro.}
#'   \item{geometry}{Geometria poligonal no sistema local original.}
#' }
#' @source Shapefile sintetico `extdata/feira_livre/shape/feira_livre_bairros.shp`.
#' @seealso [dados], [historico_alerta], [notificacoes_alerta]
#' @examples
#' data("referencia_intramunicipal", package = "infodengesubmunicipal")
#' sf::st_drop_geometry(referencia_intramunicipal)
"referencia_intramunicipal"

#' Conjunto de dados sinteticos de Feira Livre
#'
#' Reune as tres bases de exemplo do municipio ficticio 999999. Cada base
#' tambem pode ser carregada individualmente com data() ou acessada por `::`.
#' Os arquivos originais continuam disponiveis em extdata/feira_livre.
#' @format Lista nomeada com tres elementos:
#' \describe{
#'   \item{historico_alerta}{Historico semanal: 90 linhas.}
#'   \item{notificacoes_alerta}{Notificacoes de dengue: 7210 linhas.}
#'   \item{referencia_intramunicipal}{Objeto sf: 28 bairros e quatro distritos.}
#' }
#' @source Dados sinteticos fornecidos pelo mantenedor, em `extdata/feira_livre`.
#' @seealso [historico_alerta], [notificacoes_alerta], [referencia_intramunicipal]
#' @examples
#' data(dados, package = "infodengesubmunicipal")
#' names(dados)
#' nrow(dados$notificacoes_alerta)
"dados"
