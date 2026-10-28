#' Criar grafico de incidencia sem depender de globais
#'
#' Refatora `create_incidence_plot()` para explicitar os parametros que antes
#' eram buscados no ambiente global.
#'
#' @param nowcast_data Data frame com estimativas de nowcasting.
#' @param observed_data Data frame com dados observados.
#' @param weeks_limit Ultima semana epidemiologica considerada.
#' @param breaks_1ano Vetor com os breaks do eixo X.
#' @param limiar_epidemico Limiar epidemico usado no grafico.
#' @param title_suffix Titulo opcional.
#' @param distrito_nome Nome opcional da unidade analisada.
#' @param ylim_max Limite maximo do eixo Y.
#' @param include_zoom Se `TRUE`, adiciona painel de zoom.
#' @param pop Populacao usada para conversao de incidencia.
#' @param convert_to_incidence Se `TRUE`, converte casos absolutos.
#'
#' @return Objeto `ggplot`.
#' @export
create_incidence_plot_novo <- function(nowcast_data, observed_data, weeks_limit,
                                       breaks_1ano, limiar_epidemico,
                                       title_suffix = NULL, distrito_nome = NULL,
                                       ylim_max = NULL, include_zoom = FALSE,
                                       pop = NULL, convert_to_incidence = FALSE) {
  weeks_limit <- as.numeric(as.character(weeks_limit))

  if (convert_to_incidence && is.null(pop)) {
    stop("`pop` deve ser informado quando `convert_to_incidence = TRUE`.")
  }

  observed_data <- observed_data %>%
    dplyr::mutate(ano_epi = as.numeric(as.character(.data$ano_epi)))

  nowcast_data <- nowcast_data %>%
    dplyr::mutate(ano_epi = as.numeric(as.character(.data$ano_epi)))

  if (convert_to_incidence) {
    observed_data <- observed_data %>%
      dplyr::mutate(total_Y = .data$total_Y / pop * 1e5)

    nowcast_data <- nowcast_data %>%
      dplyr::mutate(dplyr::across(c("Median", "LI", "LS"), ~ .x / pop * 1e5))
  }

  plot_title <- if (!is.null(title_suffix)) {
    title_suffix
  } else if (!is.null(distrito_nome)) {
    paste0("Curva de incidência - ", distrito_nome, " até SE", weeks_limit)
  } else {
    "Curva de incidência"
  }

  start_week <- calcular_inicio_janela_1ano(weeks_limit)
  nowcast_data <- ajustar_nowcasting_legado(nowcast_data, observed_data)

  observed_window <- observed_data %>%
    dplyr::filter(.data$ano_epi >= start_week, .data$ano_epi <= weeks_limit) %>%
    dplyr::mutate(nivel = factor(.data$nivel))

  nowcast_window <- nowcast_data %>%
    dplyr::filter(.data$ano_epi >= start_week, .data$ano_epi <= weeks_limit)

  p_main <- ggplot2::ggplot() +
    ggplot2::geom_ribbon(
      data = observed_window,
      ggplot2::aes(x = factor(.data$ano_epi), ymin = 0, ymax = .data$total_Y, fill = .data$nivel, group = 1),
      alpha = 0.3
    ) +
    ggplot2::geom_line(
      data = observed_window,
      ggplot2::aes(x = factor(.data$ano_epi), y = .data$total_Y, group = 1),
      color = "steelblue",
      linewidth = 1
    ) +
    ggplot2::geom_line(
      data = nowcast_window %>% dplyr::filter(.data$type == "Nowcasting"),
      ggplot2::aes(x = factor(.data$ano_epi), y = .data$Median, color = "Nowcasting", group = .data$type),
      linewidth = 0.5,
      linetype = 2
    ) +
    ggplot2::geom_ribbon(
      data = nowcast_window %>% dplyr::filter(.data$type == "Nowcasting"),
      ggplot2::aes(x = factor(.data$ano_epi), ymin = .data$LI, ymax = .data$LS, fill = "Nowcasting", group = .data$type),
      alpha = 0.2
    ) +
    (if (length(limiar_epidemico) == 1L && is.finite(limiar_epidemico)) ggplot2::geom_hline(yintercept = limiar_epidemico, col = "red", show.legend = FALSE)) +
    (if (length(limiar_epidemico) == 1L && is.finite(limiar_epidemico)) ggplot2::geom_text(ggplot2::aes(x = 10, y = limiar_epidemico + 1, label = "Limiar Epidêmico"))) +
    (if (nrow(nowcast_window)) ggplot2::scale_color_manual(
      name = NULL,
      values = c("Nowcasting" = "red3"),
      labels = c("Nowcasting" = "Nowcasting")
    )) +
    ggplot2::scale_fill_manual(
      name = NULL,
      values = c("Nowcasting" = "red3", "1" = "green", "2" = "yellow", "3" = "orange", "4" = "red3"),
      labels = c(
        "Nowcasting" = "Nowcasting (IC 95%)",
        "1" = "Baixo Risco",
        "2" = "Receptivo",
        "3" = "Transmissão",
        "4" = "Alta atividade"
      ),
      breaks = c("1", "2", "3", "4", "Nowcasting")
    ) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      legend.position = "top",
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
    ) +
    ggplot2::scale_x_discrete(breaks = breaks_1ano) +
    ggplot2::labs(
      x = "Semanas Epidemiológicas",
      y = "Incidência (casos por 100.000 hab.)",
      title = plot_title
    )

  if (!is.null(ylim_max)) {
    p_main <- p_main + ggplot2::ylim(0, ylim_max)
  }

  if (!include_zoom) {
    return(p_main)
  }

  ultimas_semanas <- tail(sort(unique(observed_window$ano_epi)), 5)
  zoom_data <- observed_window %>%
    dplyr::filter(.data$ano_epi %in% ultimas_semanas)

  p_zoom <- ggplot2::ggplot(zoom_data) +
    ggplot2::geom_segment(
      ggplot2::aes(
        x = factor(.data$ano_epi),
        xend = factor(.data$ano_epi),
        y = 0,
        yend = .data$total_Y,
        color = factor(.data$nivel)
      ),
      linewidth = 0.8
    ) +
    ggplot2::geom_line(
      ggplot2::aes(x = factor(.data$ano_epi), y = .data$total_Y, group = 1),
      color = "steelblue",
      linewidth = 1.2
    ) +
    ggplot2::geom_line(
      data = nowcast_window %>% dplyr::filter(.data$type == "Nowcasting", .data$ano_epi %in% ultimas_semanas),
      ggplot2::aes(x = factor(.data$ano_epi), y = .data$Median, color = "Nowcasting", group = .data$type),
      linewidth = 0.5,
      linetype = 2
    ) +
    ggplot2::geom_ribbon(
      data = nowcast_window %>% dplyr::filter(.data$type == "Nowcasting", .data$ano_epi %in% ultimas_semanas),
      ggplot2::aes(x = factor(.data$ano_epi), ymin = .data$LI, ymax = .data$LS, fill = "Nowcasting", group = .data$type),
      alpha = 0.2
    ) +
    (if (length(limiar_epidemico) == 1L && is.finite(limiar_epidemico)) ggplot2::geom_hline(yintercept = limiar_epidemico, col = "red", show.legend = FALSE)) +
    (if (nrow(nowcast_window)) ggplot2::scale_color_manual(
      name = NULL,
      values = c("Nowcasting" = "red3", "1" = "green", "2" = "yellow", "3" = "orange", "4" = "red"),
      labels = c("Nowcasting" = "Nowcasting", "1" = "Baixo Risco", "2" = "Receptivo", "3" = "Transmissão", "4" = "Alta atividade"),
      breaks = c("Nowcasting", "1", "2", "3", "4")
    )) +
    ggplot2::scale_fill_manual(values = c("Nowcasting" = "red3"), guide = "none") +
    ggplot2::theme_minimal() +
    ggplot2::labs(x = NULL, y = NULL, title = "Últimas 5 semanas") +
    ggplot2::theme(
      legend.position = "none",
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1, size = 8),
      axis.text.y = ggplot2::element_text(size = 7),
      title = ggplot2::element_text(size = 6),
      plot.background = ggplot2::element_rect(fill = "white", color = "gray"),
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank()
    ) +
    ggplot2::scale_x_discrete(breaks = breaks_1ano)

  p_main + patchwork::inset_element(p_zoom, left = 0.6, bottom = 0.3, right = 1, top = 1)
}
