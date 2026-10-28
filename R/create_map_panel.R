#' Criar painel adaptavel de mapas com legenda compartilhada
#' @param plots_list Lista nao vazia de ggplots, exibidos na ordem recebida.
#' @param legend_title Titulo da legenda de preenchimento.
#' @param ncol Numero opcional de colunas; por padrao usa uma grade aproximadamente quadrada.
#' @return Um ggplot composto, com todos os mapas e legenda compartilhada.
#' @details Os mapas com preenchimento devem usar escalas e limites compativeis.
#' @export
create_map_panel <- function(plots_list, legend_title = "Incidência (100.000 pessoas)", ncol = NULL) {
  if (!is.list(plots_list) || !length(plots_list) ||
      !all(vapply(plots_list, inherits, logical(1), "ggplot"))) {
    stop("plots_list deve conter ao menos um ggplot.", call. = FALSE)
  }
  if (is.null(ncol)) ncol <- ceiling(sqrt(length(plots_list)))
  if (length(ncol) != 1L || !is.numeric(ncol) || !is.finite(ncol) || ncol < 1 || ncol != floor(ncol)) {
    stop("ncol deve ser inteiro positivo.", call. = FALSE)
  }
  assinaturas <- lapply(plots_list, function(p) {
    escala <- ggplot2::ggplot_build(p)$plot$scales$get_scales("fill")
    if (is.null(escala)) return(NULL)
    list(limites = escala$get_limits(), quebras = escala$get_breaks(),
         cores = escala$map(escala$get_breaks()))
  })
  usadas <- assinaturas[!vapply(assinaturas, is.null, logical(1))]
  if (length(usadas) > 1L && !all(vapply(usadas, identical, logical(1), usadas[[1]]))) {
    stop("Mapas com escalas de preenchimento incompativeis: informe limites comuns.", call. = FALSE)
  }
  legendas <- lapply(plots_list, function(p) {
    cowplot::get_legend(p + ggplot2::labs(fill = legend_title) + ggplot2::theme(legend.position = "bottom"))
  })
  legendas <- Filter(Negate(is.null), legendas)
  mapas <- lapply(plots_list, function(p) p + ggplot2::theme(legend.position = "none"))
  painel <- cowplot::plot_grid(plotlist = mapas, ncol = ncol, align = "hv")
  if (!length(legendas)) return(painel)
  cowplot::plot_grid(painel, legendas[[1]], ncol = 1, rel_heights = c(1, 0.15))
}
