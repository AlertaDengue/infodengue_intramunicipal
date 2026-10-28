#' Construir criterios de alerta
#'
#' Helper interno para montar o objeto de criterio usado por
#' `AlertTools::fouralert()`.
#'
#' @param params Lista de parametros do modelo.
#' @param criteria_fn Funcao responsavel por construir o criterio.
#'
#' @return Objeto de criterio.
#' @keywords internal
construir_criteria_alerta <- function(params, criteria_fn = AlertTools::setCriteria) {
  crit_vector <- stats::setNames(
    as.character(params),
    names(params)
  )

  criteria_fn(
    rule = params$codmodelo,
    values = crit_vector
  )
}
