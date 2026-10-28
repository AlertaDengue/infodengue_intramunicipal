#' Criar graficos de Rt sem depender de globais
#'
#' Refatora `create_rt_plot()` para receber explicitamente os breaks do eixo X,
#' removendo a dependencia do objeto global `breaks_1ano`.
#'
#' @param api_data Data frame com a serie temporal do Rt.
#' @param weeks_limit Ultima semana epidemiologica exibida.
#' @param title_suffix Titulo do grafico.
#' @param breaks_1ano Vetor com os breaks do eixo X.
#' @param facet_by Coluna opcional para facetar os graficos.
#' @param lwr Coluna opcional com limite inferior do intervalo.
#' @param upr Coluna opcional com limite superior do intervalo.
#' @param sem_not Nome da coluna da semana epidemiologica.
#'
#' @return Lista com `combined_plot` e `individual_plots`.
#' @export
create_rt_plot_novo <- function(api_data, weeks_limit, title_suffix, breaks_1ano,
                                facet_by = NULL, lwr = NULL, upr = NULL,
                                sem_not = "sem_not") {
  weeks_limit <- as.numeric(as.character(weeks_limit))

  required_cols <- c(sem_not, "Rt")
  missing_cols <- required_cols[!required_cols %in% names(api_data)]
  if (length(missing_cols) > 0) {
    stop(
      paste(
        "Colunas obrigat\u00f3rias n\u00e3o encontradas nos dados:",
        paste(missing_cols, collapse = ", ")
      )
    )
  }

  if (!is.null(lwr) && !lwr %in% names(api_data)) {
    warning(paste("Coluna", lwr, "n\u00e3o encontrada nos dados. Ribbon ser\u00e1 ignorado."))
    lwr <- NULL
  }
  if (!is.null(upr) && !upr %in% names(api_data)) {
    warning(paste("Coluna", upr, "n\u00e3o encontrada nos dados. Ribbon ser\u00e1 ignorado."))
    upr <- NULL
  }

  dados_filtrados <- api_data %>%
    dplyr::mutate(
      !!rlang::sym(sem_not) := as.numeric(as.character(.data[[sem_not]]))
    ) %>%
    dplyr::filter(!!rlang::sym(sem_not) <= weeks_limit)

  plot_list <- list()

  if (is.null(facet_by)) {
    p <- ggplot2::ggplot(dados_filtrados) +
      ggplot2::geom_line(
        ggplot2::aes(x = factor(!!rlang::sym(sem_not)), y = .data$Rt, group = 1),
        linetype = 1
      ) +
      ggplot2::geom_hline(yintercept = 1, linetype = 2, col = "red") +
      ggplot2::scale_x_discrete(breaks = breaks_1ano) +
      ggplot2::labs(x = "Semanas Epidemiol\u00f3gicas", y = "Rt", title = title_suffix) +
      ggplot2::theme_minimal(base_size = 12) +
      ggplot2::theme(legend.position = "top", axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

    if (!is.null(lwr) && !is.null(upr)) {
      p <- p + ggplot2::geom_ribbon(
        ggplot2::aes(
          x = factor(!!rlang::sym(sem_not)),
          ymin = !!rlang::sym(lwr),
          ymax = !!rlang::sym(upr),
          group = 1
        ),
        alpha = 0.7,
        fill = "grey"
      )
    }

    plot_list[["combined_plot"]] <- p
    plot_list[["individual_plots"]] <- list(p)

    return(plot_list)
  }

  p_combined <- ggplot2::ggplot(dados_filtrados) +
    ggplot2::geom_line(
      ggplot2::aes(x = factor(!!rlang::sym(sem_not)), y = .data$Rt, group = 1),
      linetype = 1
    ) +
    ggplot2::geom_hline(yintercept = 1, linetype = 2, col = "red") +
    ggplot2::scale_x_discrete(breaks = breaks_1ano) +
    ggplot2::labs(x = "Semanas Epidemiol\u00f3gicas", y = "Rt", title = title_suffix) +
    ggplot2::theme_minimal(base_size = 15) +
    ggplot2::theme(legend.position = "top", axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

  facet_levels <- unique(dados_filtrados[[facet_by]])
  facet_labels <- stats::setNames(LETTERS[seq_along(facet_levels)], facet_levels)

  p_combined <- p_combined +
    ggplot2::facet_wrap(
      ggplot2::vars(!!rlang::sym(facet_by)),
      labeller = ggplot2::as_labeller(facet_labels),
      strip.position = "top"
    )

  if (!is.null(lwr) && !is.null(upr)) {
    p_combined <- p_combined + ggplot2::geom_ribbon(
      ggplot2::aes(
        x = factor(!!rlang::sym(sem_not)),
        ymin = !!rlang::sym(lwr),
        ymax = !!rlang::sym(upr),
        group = !!rlang::sym(facet_by)
      ),
      alpha = 0.7,
      fill = "grey"
    )
  }

  individual_plots <- list()

  for (level in facet_levels) {
    p_individual <- dados_filtrados %>%
      dplyr::filter(!!rlang::sym(facet_by) == level) %>%
      ggplot2::ggplot() +
      ggplot2::geom_line(
        ggplot2::aes(x = factor(!!rlang::sym(sem_not)), y = .data$Rt, group = 1),
        linetype = 1
      ) +
      ggplot2::geom_hline(yintercept = 1, linetype = 2, col = "red") +
      ggplot2::scale_x_discrete(breaks = breaks_1ano) +
      ggplot2::labs(
        x = "Semanas Epidemiol\u00f3gicas",
        y = "Rt",
        title = paste(title_suffix, "", level)
      ) +
      ggplot2::theme_minimal(base_size = 12) +
      ggplot2::theme(legend.position = "top", axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))

    if (!is.null(lwr) && !is.null(upr)) {
      p_individual <- p_individual + ggplot2::geom_ribbon(
        ggplot2::aes(
          x = factor(!!rlang::sym(sem_not)),
          ymin = !!rlang::sym(lwr),
          ymax = !!rlang::sym(upr),
          group = 1
        ),
        alpha = 0.7,
        fill = "grey"
      )
    }

    individual_plots[[as.character(level)]] <- p_individual
  }

  plot_list[["combined_plot"]] <- p_combined
  plot_list[["individual_plots"]] <- individual_plots

  plot_list
}
