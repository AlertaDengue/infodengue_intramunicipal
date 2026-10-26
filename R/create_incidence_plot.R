#' Criar gráfico de incidência epidemiológica com nowcasting
#'
#' Gera um gráfico de incidência epidemiológica combinando dados observados
#' e estimativas de nowcasting. O gráfico inclui a curva observada, o intervalo
#' de confiança do nowcasting, níveis de risco epidemiológico e um limiar
#' epidêmico. Opcionalmente, pode incluir um painel de zoom para as semanas
#' mais recentes.
#'
#' A função também permite converter os valores para incidência por 100.000
#' habitantes caso os dados estejam em contagem absoluta.
#'
#' @param nowcast_data Data frame contendo estimativas de nowcasting. Deve
#' incluir as colunas `ano_epi`, `Median`, `LI`, `LS` e `type`.
#' @param observed_data Data frame contendo os dados observados. Deve incluir
#' ao menos as colunas `ano_epi`, `total_Y` e `nivel`.
#' @param title_suffix String opcional para o título do gráfico.
#' @param distrito_nome String opcional com o nome do distrito ou região
#' analisada. Usado na construção automática do título.
#' @param SE Número da semana epidemiológica final da série.
#' @param ylim_max Valor máximo do eixo Y. Se `NULL`, o limite é determinado
#' automaticamente.
#' @param include_zoom Lógico. Se `TRUE`, adiciona um painel de zoom com as
#' últimas semanas epidemiológicas.
#' @param pop População utilizada para converter contagens em incidência por
#' 100.000 habitantes.
#' @param convert_to_incidence Lógico. Se `TRUE`, converte os valores de casos
#' absolutos para incidência por 100.000 habitantes.
#'
#' @return
#' Um objeto `ggplot` contendo o gráfico de incidência epidemiológica. Se
#' `include_zoom = TRUE`, o gráfico final inclui um painel adicional com zoom
#' nas semanas mais recentes utilizando `patchwork`.
#'
#' @details
#' O gráfico inclui:
#'
#' * Curva de incidência observada
#' * Intervalo de confiança do nowcasting
#' * Níveis de risco epidemiológico representados por cores
#' * Linha horizontal indicando o limiar epidêmico
#'
#' Quando `include_zoom = TRUE`, um painel com as últimas semanas
#' epidemiológicas é inserido no canto superior do gráfico principal.
#'
#' @examples
#' \dontrun{
#' create_incidence_plot(
#'   nowcast_data = rf_mun_nowscat$mun_nowcast,
#'   observed_data = rf_mun_nowscat$mun_observados,
#'   title_suffix = "Curva de incidência de dengue",
#'   convert_to_incidence = TRUE,
#'   pop = 616317
#' )
#' }
#'
#' @seealso [create_incidence_plot_novo()]
#' @export
create_incidence_plot <- function(nowcast_data, observed_data, title_suffix = NULL,
                                  distrito_nome = NULL, SE = NULL,
                                  ylim_max = NULL, include_zoom = FALSE, pop = pop,
                                  convert_to_incidence = F) {
  .Deprecated("create_incidence_plot_novo", package = "infodengesubmunicipal")

  # Transformar em incidência se solicitado
  if (convert_to_incidence) {
    observed_data <- observed_data %>%
      mutate(total_Y = total_Y / pop * 1e5)

    nowcast_data <- nowcast_data %>%
      mutate(across(c(Median, LI, LS), ~ .x / pop * 1e5))

    y_label <- "Incid\u00eancia (casos por 100.000 hab.)"
  } else {
    y_label <- "Incid\u00eancia (casos por 100.000 hab.)"
  }

  # Determinar o título baseado nos parâmetros fornecidos
  if (!is.null(title_suffix)) {
    plot_title <- title_suffix
  } else if (!is.null(distrito_nome) && !is.null(SE)) {
    plot_title <- paste0("Curva de incid\u00eancia - ", distrito_nome, " at\u00e9 SE", SE)
  } else if (!is.null(distrito_nome)) {
    plot_title <- paste0("Curva de incid\u00eancia - ", distrito_nome)
  } else {
    plot_title <- "Curva de incid\u00eancia"
  }

  # Ensure we're comparing the same weeks
  common_weeks <- intersect(nowcast_data$ano_epi, observed_data$ano_epi)

  # Filter data to common weeks only
  nowcast_filtered <- nowcast_data %>% filter(ano_epi %in% common_weeks)
  observed_filtered <- observed_data %>% filter(ano_epi %in% common_weeks)

  # Apply the condition row-wise
  for (i in seq_along(common_weeks)) {

    if (nowcast_filtered$Median[i] < observed_filtered$total_Y[i]) {
      nowcast_filtered$Median[i] <- observed_filtered$total_Y[i]
    }


    if (nowcast_filtered$LI[i] < observed_filtered$total_Y[i]) {
      nowcast_filtered$LI[i] <- observed_filtered$total_Y[i] - 0.5
    }


    if (nowcast_filtered$LS[i] < observed_filtered$total_Y[i]) {
      nowcast_filtered$LS[i] <- observed_filtered$total_Y[i] + 0.5
    }
  }

  # Replace the original nowcast_data with the modified version
  nowcast_data <- nowcast_data %>%
    left_join(nowcast_filtered %>% select(ano_epi, Median, LI, LS), by = "ano_epi", suffix = c(".x", ".y")) %>%
    mutate(
      Median = coalesce(Median.y, Median.x),
      LI = coalesce(LI.y, LI.x),
      LS = coalesce(LS.y, LS.x)
    ) %>%
    select(-Median.x, -Median.y, -LI.x, -LI.y, -LS.x, -LS.y)

  # max_val <- max(observed_data %>%
  #                  filter(ano_epi >= paste0(ano_atual-1,substr(weeks_2_plot[3],5,6))) %>%
  #                  pull(total_Y), na.rm = T)
  #
  # min_val <- min(observed_data %>%
  #                  filter(ano_epi >= paste0(ano_atual-1,substr(weeks_2_plot[3],5,6))) %>%
  #                  pull(total_Y), na.rm = T)
  #


  # Criar o gráfico principal
  p_main <- ggplot() +
    # Ribbon para os níveis de risco (substitui geom_segment)
    geom_ribbon(
      data = observed_data %>%
        filter(ano_epi >= paste0(ano_atual-1, substr(weeks_2_plot[3], 5, 6))) %>%
        mutate(nivel = factor(nivel)),
      aes(x = factor(ano_epi), ymin = 0, ymax = total_Y,
          fill = nivel, group = 1),
      alpha = 0.3
    ) +
    # Linha observada
    geom_line(
      data = observed_data %>%
        filter(ano_epi >= paste0(ano_atual-1, substr(weeks_2_plot[3], 5, 6))),
      aes(x = factor(ano_epi), y = total_Y, group = 1),
      color = "steelblue", linewidth = 1
    ) +
    # Nowcasting
    geom_line(
      data = nowcast_data %>% dplyr::filter(type == "Nowcasting"),
      aes(x = factor(ano_epi), y = Median, color = "Nowcasting", group = type),
      linewidth = 0.5, linetype = 2
    ) +
    # Ribbon nowcasting
    geom_ribbon(
      data = nowcast_data %>% dplyr::filter(type == "Nowcasting"),
      aes(x = factor(ano_epi), ymin = LI, ymax = LS, fill = "Nowcasting", group = type),
      alpha = 0.2
    ) +
    geom_hline(yintercept = limiar_epidemico, col = "red", show.legend = F) +
    geom_text(aes(x = 10, y = limiar_epidemico + 1, label = "Limiar Epid\u00eamico")) +

    # Escalas
    scale_color_manual(
      name = NULL,
      values = c("Nowcasting" = "red3"),
      labels = c("Nowcasting" = "Nowcasting")
    ) +
    scale_fill_manual(
      name = NULL,
      values = c(
        "Nowcasting" = "red3",
        "1" = "green",
        "2" = "yellow",
        "3" = "orange",
        "4" = "red3"
      ),
      labels = c(
        "Nowcasting" = "Nowcasting (IC 95%)",
        "1" = "Baixo Risco",
        "2" = "Receptivo",
        "3" = "Transmiss\u00e3o",
        "4" = "Alta atividade"
      ),
      breaks = c("1", "2", "3", "4", "Nowcasting")
    ) +
    theme_minimal() +
    theme(
      legend.position = "top",
      axis.text.x = element_text(angle = 45, hjust = 1)
    ) +
    scale_x_discrete(breaks = breaks_1ano) +
    # scale_y_continuous(
    #   limits= c(min_val,max_val)
    # ) +
    labs(
      x = "Semanas Epidemiol\u00f3gicas",
      y = "Incid\u00eancia (casos por 100.000 hab.)",
      title = title_suffix
    )

  # Adicionar ylim se especificado
  if (!is.null(ylim_max)) {
    p_main <- p_main + ylim(0, ylim_max)
  }

  # Se não for incluir o zoom, retorne apenas o gráfico principal
  if (!include_zoom) {
    return(p_main)
  }

  # Preparar dados para o zoom (últimas 10 semanas)
  ultimas_semanas <- tail(sort(unique(observed_data$ano_epi)), 5)
  zoom_data <- observed_data %>%
    filter(ano_epi %in% ultimas_semanas)

  # Criar gráfico de zoom
  p_zoom <- ggplot(zoom_data) +
    geom_segment(
      aes(x = factor(ano_epi), xend = factor(ano_epi),
          y = 0, yend = total_Y, color = factor(nivel)),
      linewidth = 0.8
    ) +
    geom_line(
      aes(x = factor(ano_epi), y = total_Y, group = 1),
      color = "steelblue", linewidth = 1.2
    ) +
    # Nowcasting
    geom_line(
      data = nowcast_data %>% dplyr::filter(type == "Nowcasting"  & ano_epi %in% ultimas_semanas),
      aes(x = factor(ano_epi), y = Median, color = "Nowcasting", group = type),
      linewidth = 0.5, linetype = 2
    ) +
    # Ribbon nowcasting
    geom_ribbon(
      data = nowcast_data %>% dplyr::filter(type == "Nowcasting"  & ano_epi %in% ultimas_semanas),
      aes(x = factor(ano_epi), ymin = LI, ymax = LS, fill = "Nowcasting", group = type),
      alpha = 0.2
    )+
    geom_hline(yintercept = 72, col = "red", show.legend = F) +
    # Escalas
    scale_color_manual(
      name = NULL,
      values = c("Nowcasting" = "red3", "1" = "green", "2" = "yellow",
                 "3" = "orange", "4" = "red"),
      labels = c("Nowcasting" = "Nowcasting", "1" = "Baixo Risco",
                 "2" = "Receptivo", "3" = "Transmiss\u00e3o", "4" = "Alta atividade"),
      breaks = c("Nowcasting", "1", "2", "3", "4")
    ) +
    scale_fill_manual(values = c("Nowcasting" = "red3"), guide = "none") +
    theme_minimal() +
    labs(x = NULL, y = NULL, title = "\u00daltimas 5 semanas")+
    theme(
      legend.position = "none",
      axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
      axis.text.y = element_text(size = 7),
      title = element_text(size = 6),
      plot.background = element_rect(fill = "white", color = "gray"),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank()
    ) +
    scale_x_discrete(breaks = breaks_1ano)

  # Combinar os gráficos usando patchwork
  final_plot <- p_main +
    inset_element(p_zoom, left = 0.6, bottom = 0.3, right = 1, top = 1)

  return(final_plot)
}
