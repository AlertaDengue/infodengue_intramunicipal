#' Normaliza nomes de bairros
#'
#' @description
#' Função utilitária para padronização de nomes de bairros.
#' Remove acentuação, converte para letras maiúsculas,
#' remove caracteres especiais e normaliza espaços.
#'
#' @details
#' A função aplica:
#' \itemize{
#'   \item Conversão para ASCII (remoção de acentos)
#'   \item Conversão para maiúsculas
#'   \item Remoção de caracteres não alfanuméricos
#'   \item Remoção de espaços duplicados
#' }
#'
#' É uma função pura e vetorizada.
#'
#' @param nome Vetor de caracteres contendo nomes de bairros.
#'
#' @return
#' Vetor de caracteres com nomes padronizados.
#'
#' @examples
#' \dontrun{
#' normalizar_bairro("São João")
#' normalizar_bairro(c("Bairro-1", "  Vila   Nova  "))
#' }
#'
#' @export
#' @importFrom stringr str_replace_all str_squish
normalizar_bairro <- function(nome) {
  enc2utf8(as.character(nome)) %>%
    iconv(from = "UTF-8", to = "ASCII//TRANSLIT") %>%
    toupper() %>%
    stringr::str_replace_all("[^A-Z0-9 ]", "") %>%
    stringr::str_squish()
}
