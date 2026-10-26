# Calendario epidemiologico: semana inicia no domingo; regra de quatro dias.
n_semanas_epi <- function(ano) {
  dias <- as.Date(paste0(ano, "-12-31")) - 0:6
  max(lubridate::epiweek(dias[lubridate::epiyear(dias) == ano]))
}

validar_semanas_epi <- function(semanas) {
  x <- suppressWarnings(as.numeric(as.character(semanas)))
  if (anyNA(x) || any(!is.finite(x)) || any(x != floor(x)) ||
      any(x < 100001 | x > 999953)) stop("Semana epidemiologica invalida: use YYYYWW.", call. = FALSE)
  maximos <- vapply(x %/% 100L, n_semanas_epi, numeric(1))
  if (any(x %% 100L < 1L | x %% 100L > maximos)) {
    stop("Semana epidemiologica inexistente no calendario (domingo, regra de quatro dias).", call. = FALSE)
  }
  as.integer(x)
}

inicio_semana_epi <- function(semana) {
  semana <- validar_semanas_epi(semana)
  as.Date(lubridate::floor_date(as.Date(paste0(semana %/% 100L, "-01-04")),
                               "week", week_start = 7)) + 7 * (semana %% 100L - 1L)
}

#' Listar semanas epidemiologicas consecutivas
#' @param ultima_semana Semana final no formato YYYYWW.
#' @param n Quantidade positiva de semanas.
#' @return Vetor numerico crescente de semanas, incluindo semanas sem casos.
#' @export
ultimas_semanas_epi <- function(ultima_semana, n = 3L) {
  if (length(ultima_semana) != 1L || length(n) != 1L || !is.numeric(n) ||
      !is.finite(n) || n < 1 || n != floor(n)) stop("Informe semana escalar e n inteiro positivo.", call. = FALSE)
  datas <- inicio_semana_epi(ultima_semana) - 7 * rev(seq_len(n) - 1L)
  as.integer(lubridate::epiyear(datas) * 100L + lubridate::epiweek(datas))
}
