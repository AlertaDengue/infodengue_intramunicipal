#' infodengesubmunicipal: ferramentas para analise epidemiologica submunicipal
#'
#' Infraestrutura de namespace do pacote. Os imports centralizados aqui
#' refletem o uso atual do codigo e reduzem erros de carregamento enquanto
#' a refatoracao das funcoes segue em andamento.
#'
#' @keywords internal
#' @importFrom AlertTools setCriteria
#' @importFrom stats setNames
#' @importFrom utils tail
#' @importFrom magrittr %>%
#' @import cowplot
#' @import dplyr
#' @import ggplot2
#' @import sf
#' @import tidyr
#' @importFrom ggpubr theme_pubclean
#' @importFrom grid unit
#' @importFrom gtable gtable_filter
#' @importFrom patchwork inset_element
#' @importFrom purrr map map_dfr
#' @importFrom rlang .data sym :=
"_PACKAGE"
