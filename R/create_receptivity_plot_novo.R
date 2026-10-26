#' Criar grafico de receptividade sem depender de globais
#'
#' Refatora `create_receptivity_plot()` para usar explicitamente a semana limite
#' e os breaks do eixo X.
#'
#' @param api_data Data frame com colunas de semana e temperatura minima.
#' @param weeks_limit Ultima semana epidemiologica considerada.
#' @param breaks_1ano Vetor com os breaks do eixo X.
#' @param limiar_temp Limiar de temperatura favoravel.
#' @param se_col Nome da coluna da semana epidemiologica.
#' @param temp_col Nome da coluna de temperatura minima.
#'
#' @return Objeto `ggplot`.
#' @export
create_receptivity_plot_novo <- function(api_data, weeks_limit, breaks_1ano,
                                         limiar_temp = 18, se_col = "SE",
                                         temp_col = "tempmin") {
  weeks_limit <- as.numeric(as.character(weeks_limit))
  start_week <- calcular_inicio_janela_1ano(weeks_limit)

  api_data <- api_data %>%
    dplyr::mutate(
      !!rlang::sym(se_col) := as.numeric(as.character(.data[[se_col]]))
    )

  dados_plot <- api_data %>%
    dplyr::filter(
      !!rlang::sym(se_col) >= start_week,
      !!rlang::sym(se_col) <= weeks_limit
    )

  ggplot2::ggplot(dados_plot) +
    ggplot2::geom_rect(
      ggplot2::aes(
        xmin = as.numeric(factor(!!rlang::sym(se_col))) - 0.5,
        xmax = as.numeric(factor(!!rlang::sym(se_col))) + 0.5,
        ymin = -Inf,
        ymax = Inf,
        fill = !!rlang::sym(temp_col) >= limiar_temp
      ),
      alpha = 0.7
    ) +
    ggplot2::geom_line(
      ggplot2::aes(x = factor(!!rlang::sym(se_col)), y = !!rlang::sym(temp_col), group = 1),
      color = "orange2",
      linewidth = 1
    ) +
    ggplot2::scale_fill_manual(values = c("TRUE" = "steelblue", "FALSE" = "grey70"), guide = "none") +
    ggplot2::geom_hline(
      ggplot2::aes(yintercept = limiar_temp, color = "Limiar Favor\u00e1vel (18\u00b0C)"),
      linewidth = 1,
      linetype = "dashed"
    ) +
    ggplot2::scale_color_manual(values = c("red")) +
    ggplot2::scale_x_discrete(breaks = breaks_1ano) +
    ggplot2::scale_y_continuous(name = "Temperatura M\u00ednima (\u00b0C)") +
    ggplot2::labs(
      x = "Semanas Epidemiol\u00f3gicas",
      title = "Receptividade clim\u00e1tica e Temperatura M\u00ednima por Semana",
      color = ""
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      axis.title.y.right = ggplot2::element_blank(),
      axis.text.y.right = ggplot2::element_blank(),
      axis.title.y.left = ggplot2::element_text(color = "black"),
      legend.position = "top",
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
    )
}
