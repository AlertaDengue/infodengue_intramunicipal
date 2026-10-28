#' Completar grade bairro x semana epidemiologica com regras explicitas
#'
#' Refatora `completar_dados_bairros()` para lidar melhor com base vazia,
#' usar namespace explicito e permitir configurar o nome da coluna de contagem.
#'
#' @param dados_bairros Data frame contendo notificacoes agregadas.
#' @param bairros_unicos Vetor com todos os bairros esperados.
#' @param se_var Nome da coluna da semana epidemiologica.
#' @param nm_bairr_var Nome da coluna do bairro.
#' @param group_var Nome da coluna de agrupamento.
#' @param max_semana_epidemiologica Limite superior da serie temporal.
#' @param count_var Nome da coluna de contagem.
#'
#' @return Data frame com a grade completa e contagens preenchidas.
#' @export
completar_dados_bairros_novo <- function(dados_bairros, bairros_unicos, se_var,
                                         nm_bairr_var, group_var = "arbo",
                                         max_semana_epidemiologica = NULL,
                                         count_var = "notifica\u00e7\u00f5es") {
  required_cols <- c(se_var, nm_bairr_var, group_var, count_var)
  missing_cols <- setdiff(required_cols, names(dados_bairros))

  if (length(missing_cols) > 0) {
    stop("Missing columns: ", paste(missing_cols, collapse = ", "))
  }

  if (length(bairros_unicos) == 0) {
    bairros_unicos <- unique(dados_bairros[[nm_bairr_var]])
  }

  if (nrow(dados_bairros) == 0) {
    empty_result <- dados_bairros
    empty_result[[se_var]] <- numeric(0)
    empty_result[[count_var]] <- numeric(0)
    return(empty_result)
  }

  dados_bairros[[se_var]] <- validar_semanas_epi(dados_bairros[[se_var]])
  if (is.null(max_semana_epidemiologica)) {
    max_semana_epidemiologica <- max(dados_bairros[[se_var]])
  }
  limite <- validar_semanas_epi(max_semana_epidemiologica)
  if (length(limite) != 1L) stop("Informe apenas uma semana limite.", call. = FALSE)
  ano_atual <- limite %/% 100L
  max_week_atual <- limite %% 100L
  dados_bairros$ano <- dados_bairros[[se_var]] %/% 100L
  dados_bairros$semana <- dados_bairros[[se_var]] %% 100L
  anos <- sort(unique(dados_bairros$ano[dados_bairros$ano <= ano_atual]))
  grade <- lapply(anos, function(ano) {
    max_week <- if (ano == ano_atual) max_week_atual else n_semanas_epi(ano)
    tidyr::expand_grid(
      !!nm_bairr_var := unique(bairros_unicos),
      !!se_var := ano * 100L + seq_len(max_week),
      !!group_var := unique(dados_bairros[[group_var]])
    )
  })
  if (!length(grade)) {
    complete_data <- dados_bairros[FALSE, c(nm_bairr_var, se_var, group_var)]
  } else complete_data <- dplyr::bind_rows(grade)
  chaves <- c(nm_bairr_var, se_var, group_var)
  excluidos <- dplyr::anti_join(dados_bairros, complete_data, by = chaves)
  if (nrow(excluidos)) {
    warning(nrow(excluidos), " linhas (", sum(excluidos[[count_var]], na.rm = TRUE),
            " notificacoes) fora da grade: confira bairros e limite temporal.", call. = FALSE)
  }
  dplyr::left_join(complete_data, dplyr::select(dados_bairros, -"ano", -"semana"), by = chaves) %>%
    dplyr::mutate(!!count_var := dplyr::coalesce(.data[[count_var]], 0)) %>%
    dplyr::arrange(.data[[group_var]], .data[[nm_bairr_var]], .data[[se_var]])
}
