#' Criar breaks do eixo X para janela móvel de 1 ano
#'
#' Gera pontos de quebra (breaks) para o eixo X de gráficos baseados em
#' semanas epidemiológicas, considerando uma janela móvel de 1 ano
#' (52 semanas). Os breaks são calculados em intervalos definidos
#' pelo argumento `passo` e retornados no formato `YYYYWW`.
#'
#' A função usa o calendario epidemiologico de domingo e seleciona
#' semanas consecutivas dentro da janela de 52 semanas
#' anteriores e depois reconverte para o formato `ano-semana`.
#'
#' @param ano_fim Inteiro. Ano da última semana da série.
#' @param semana_fim Inteiro. Semana epidemiológica final (1–53, conforme o ano).
#' @param passo Inteiro. Intervalo entre os breaks em semanas.
#' Default é `10`.
#'
#' @return
#' Um vetor numérico contendo os breaks do eixo X no formato `YYYYWW`.
#'
#' @examples
#' \dontrun{
#' # Gerar breaks para uma série que termina na semana 35 de 2024
#' criar_breaks_1ano(
#'   ano_fim = 2024,
#'   semana_fim = 35
#' )
#'
#' # Usando passo menor
#' criar_breaks_1ano(
#'   ano_fim = 2024,
#'   semana_fim = 35,
#'   passo = 5
#' )
#' }
#'
#' @export
criar_breaks_1ano <- function(ano_fim, semana_fim, passo = 10) {
  if (length(passo) != 1L || !is.numeric(passo) || !is.finite(passo) || passo < 1 || passo != floor(passo)) stop("passo deve ser inteiro positivo.", call. = FALSE)
  semanas <- ultimas_semanas_epi(as.numeric(ano_fim) * 100 + as.numeric(semana_fim), 53L)
  indices <- unique(c(seq.int(1L, length(semanas), by = passo), length(semanas)))
  as.numeric(semanas[indices])
}
