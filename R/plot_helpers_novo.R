#' Calcular inicio de janela de um ano epidemiologico
#'
#' Helper interno para derivar o limite inferior aproximado de uma janela
#' anual no formato `YYYYWW`.
#'
#' @param weeks_limit Semana epidemiologica final no formato numerico `YYYYWW`.
#'
#' @return Valor numerico `YYYYWW` correspondente ao mesmo numero de semana
#' do ano anterior.
#' @keywords internal
calcular_inicio_janela_1ano <- function(weeks_limit) {
  ano <- as.integer(substr(as.character(weeks_limit), 1, 4))
  semana <- substr(as.character(weeks_limit), 5, 6)

  as.numeric(paste0(ano - 1, semana))
}

#' Ajustar nowcasting para nao ficar abaixo do observado
#'
#' Helper interno que garante coerencia minima entre serie observada e
#' estimativas de nowcasting.
#'
#' @param nowcast_data Data frame com colunas `ano_epi`, `Median`, `LI`, `LS`.
#' @param observed_data Data frame com colunas `ano_epi` e `total_Y`.
#'
#' @return Data frame de nowcasting com colunas ajustadas.
#' @keywords internal
ajustar_nowcasting_legado <- function(nowcast_data, observed_data) {
  if (anyDuplicated(observed_data$ano_epi)) {
    stop("Serie observada deve ter uma linha por semana.", call. = FALSE)
  }
  observado <- observed_data$total_Y[match(nowcast_data$ano_epi, observed_data$ano_epi)]
  limites <- c(Median = 0, LI = -0.5, LS = 0.5)
  for (coluna in names(limites)) {
    trocar <- !is.na(nowcast_data[[coluna]]) & !is.na(observado) &
      nowcast_data[[coluna]] < observado
    nowcast_data[[coluna]][trocar] <- observado[trocar] + limites[[coluna]]
  }
  nowcast_data
}
