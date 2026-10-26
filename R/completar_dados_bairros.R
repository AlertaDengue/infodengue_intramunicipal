#' Completa grade bairro × semana epidemiológica
#'
#' @description
#' Gera combinação completa entre bairros, semanas epidemiológicas
#' e grupos (ex: arboviroses), preenchendo notificações ausentes com zero.
#'
#' @details
#' A função:
#' \itemize{
#'   \item Extrai ano e semana da variável epidemiológica (formato YYYYWW)
#'   \item Gera grade completa bairro × semana × grupo
#'   \item Preenche notificações ausentes com 0
#'   \item Ordena resultado final
#' }
#'
#' Permite limitar a semana máxima do ano corrente via
#' `max_semana_epidemiologica`.
#'
#' @param dados_bairros Data frame contendo notificações agregadas.
#' @param bairros_unicos Vetor com todos os bairros esperados.
#' @param se_var Nome da coluna da semana epidemiológica (formato "YYYYWW").
#' @param nm_bairr_var Nome da coluna do bairro.
#' @param group_var Nome da coluna de agrupamento (ex: "arbo").
#' @param max_semana_epidemiologica Valor numérico no formato YYYYWW
#' indicando limite superior da série temporal.
#'
#' @return
#' Data frame contendo todas as combinações possíveis de
#' bairro × semana × grupo, com notificações preenchidas.
#'
#' @examples
#' \dontrun{
#' dados <- tibble::tibble(
#'   arbo = "dengue",
#'   nm_bairro_ref = "CENTRO",
#'   sem_not = c(202401, 202403),
#'   notificações = c(5, 10)
#' )
#'
#' completar_dados_bairros(
#'   dados_bairros = dados,
#'   bairros_unicos = "CENTRO",
#'   se_var = "sem_not",
#'   nm_bairr_var = "nm_bairro_ref",
#'   group_var = "arbo",
#'   max_semana_epidemiologica = 202403
#' )
#' }
#'
#' @export

completar_dados_bairros <- function(dados_bairros, bairros_unicos, se_var, nm_bairr_var,
                                    group_var = "arbo", max_semana_epidemiologica = NULL) {

  completar_dados_bairros_novo(
    dados_bairros, bairros_unicos, se_var, nm_bairr_var,
    group_var, max_semana_epidemiologica, count_var = "notificações"
  )
}
