#' Criar gráficos da série temporal do número reprodutivo efetivo (Rt)
#'
#' Gera gráficos da evolução semanal do número reprodutivo efetivo (Rt)
#' a partir de dados epidemiológicos. A função pode produzir um único
#' gráfico agregado ou múltiplos gráficos por grupo (facets), além de
#' retornar gráficos individuais para cada nível do agrupamento.
#'
#' Opcionalmente, a função também pode incluir intervalos de confiança
#' para o Rt utilizando `geom_ribbon`.
#'
#' @param api_data Data frame contendo os dados do Rt. Deve incluir ao
#' menos as colunas `Rt` e a coluna de semana epidemiológica definida
#' em `sem_not`.
#' @param weeks_limit Última semana epidemiológica considerada na
#' visualização. Observações posteriores são removidas.
#' @param title_suffix String com o título do gráfico.
#' @param facet_by String opcional com o nome da coluna utilizada para
#' dividir os gráficos em múltiplos painéis (ex.: distrito ou bairro).
#' Se `NULL`, apenas um gráfico agregado será gerado.
#' @param lwr String opcional com o nome da coluna contendo o limite
#' inferior do intervalo de confiança do Rt.
#' @param upr String opcional com o nome da coluna contendo o limite
#' superior do intervalo de confiança do Rt.
#' @param sem_not String com o nome da coluna que representa a semana
#' epidemiológica. Default é `"sem_not"`.
#'
#' @return
#' Uma lista contendo:
#'
#' * `combined_plot` — gráfico único ou facetado com todos os dados
#' * `individual_plots` — lista de gráficos individuais para cada nível
#'   de `facet_by` (ou apenas um gráfico caso `facet_by = NULL`)
#'
#' @details
#' O gráfico inclui:
#'
#' * Série temporal do Rt
#' * Linha horizontal indicando o limiar epidêmico (`Rt = 1`)
#' * Intervalo de confiança opcional do Rt (quando `lwr` e `upr`
#'   são fornecidos)
#'
#' Quando `facet_by` é especificado, a função gera:
#'
#' * Um gráfico combinado com `facet_wrap`
#' * Gráficos individuais separados para cada nível do agrupamento
#'
#' @examples
#' \dontrun{
#' create_rt_plot(
#'   api_data = dados_rt,
#'   weeks_limit = 202452,
#'   title_suffix = "Número Reprodutivo Efetivo (Rt)"
#' )
#'
#' create_rt_plot(
#'   api_data = dados_rt,
#'   weeks_limit = 202452,
#'   title_suffix = "Rt por distrito",
#'   facet_by = "distrito",
#'   lwr = "Rt_lower",
#'   upr = "Rt_upper"
#' )
#' }
#'
#' @seealso [create_rt_plot_novo()]
#' @export
create_rt_plot <- function(api_data, weeks_limit, title_suffix, facet_by = NULL,
                           lwr = NULL, upr = NULL, sem_not = NULL) {
  .Deprecated("create_rt_plot_novo", package = "infodengesubmunicipal")

  # Set default column names if not provided
  if (is.null(sem_not)) sem_not <- "sem_not"

  # Check if required columns exist (only sem_not and Rt are mandatory)
  required_cols <- c(sem_not, "Rt")
  missing_cols <- required_cols[!required_cols %in% names(api_data)]
  if (length(missing_cols) > 0) {
    stop(paste("Colunas obrigat\u00f3rias n\u00e3o encontradas nos dados:", paste(missing_cols, collapse = ", ")))
  }

  # Check if optional columns exist when provided
  if (!is.null(lwr) && !lwr %in% names(api_data)) {
    warning(paste("Coluna", lwr, "n\u00e3o encontrada nos dados. Ribbon ser\u00e1 ignorado."))
    lwr <- NULL
  }
  if (!is.null(upr) && !upr %in% names(api_data)) {
    warning(paste("Coluna", upr, "n\u00e3o encontrada nos dados. Ribbon ser\u00e1 ignorado."))
    upr <- NULL
  }

  # Criar lista para armazenar os gráficos
  plot_list <- list()

  # Se não há facet_by, criar apenas um gráfico
  if (is.null(facet_by)) {
    p <- api_data %>%
      filter(!!sym(sem_not) <= as.numeric(as.character(weeks_limit))) %>%
      ggplot() +
      geom_line(aes(x = factor(!!sym(sem_not)), y = Rt, group = 1), linetype = 1) +
      geom_hline(yintercept = 1, linetype = 2, col = "red") +
      scale_x_discrete(breaks = breaks_1ano) +
      labs(x = "Semanas Epidemiol\u00f3gicas", y = "Rt", title = title_suffix) +
      theme_minimal(base_size = 12) +
      theme(legend.position = "top", axis.text.x = element_text(angle = 45, hjust = 1))

    # Add ribbon if both lwr and upr are provided and exist
    if (!is.null(lwr) && !is.null(upr)) {
      p <- p + geom_ribbon(
        aes(x = factor(!!sym(sem_not)),
            ymin = !!sym(lwr),
            ymax = !!sym(upr),
            group = 1),
        alpha = 0.7, fill = "grey"
      )
    }

    plot_list[["combined_plot"]] <- p
    plot_list[["individual_plots"]] <- list(p)

  } else {
    # Se há facet_by, criar gráfico combinado e individuais

    # Gráfico combinado com facets
    p_combined <- api_data %>%
      filter(!!sym(sem_not) <= as.numeric(as.character(weeks_limit))) %>%
      ggplot() +
      geom_line(aes(x = factor(!!sym(sem_not)), y = Rt, group = 1), linetype = 1) +
      geom_hline(yintercept = 1, linetype = 2, col = "red") +
      scale_x_discrete(breaks = breaks_1ano) +
      labs(x = "Semanas Epidemiol\u00f3gicas", y = "Rt", title = title_suffix) +
      theme_minimal(base_size = 15) +
      theme(legend.position = "top", axis.text.x = element_text(angle = 45, hjust = 1))

    # Add facets with label letters
    facet_levels <- unique(api_data[[facet_by]])
    facet_labels <- setNames(LETTERS[1:length(facet_levels)], facet_levels)

    p_combined <- p_combined + facet_wrap(vars(!!sym(facet_by)),
                                          labeller = as_labeller(facet_labels),
                                          strip.position = "top")

    # Add ribbon if both lwr and upr are provided and exist
    if (!is.null(lwr) && !is.null(upr)) {
      p_combined <- p_combined + geom_ribbon(
        aes(x = factor(!!sym(sem_not)),
            ymin = !!sym(lwr),
            ymax = !!sym(upr),
            group = !!sym(facet_by)),
        alpha = 0.7, fill = "grey"
      )
    }

    # Criar gráficos individuais para cada nível do facet
    individual_plots <- list()

    for (level in facet_levels) {
      p_individual <- api_data %>%
        filter(!!sym(sem_not) <= as.numeric(as.character(weeks_limit)),
               !!sym(facet_by) == level) %>%
        ggplot() +
        geom_line(aes(x = factor(!!sym(sem_not)), y = Rt, group = 1), linetype = 1) +
        geom_hline(yintercept = 1, linetype = 2, col = "red") +
        scale_x_discrete(breaks = breaks_1ano) +
        labs(x = "Semanas Epidemiol\u00f3gicas", y = "Rt",
             title = paste(title_suffix, "", level)) +
        theme_minimal(base_size = 12) +
        theme(legend.position = "top", axis.text.x = element_text(angle = 45, hjust = 1))

      # Add ribbon if both lwr and upr are provided and exist
      if (!is.null(lwr) && !is.null(upr)) {
        p_individual <- p_individual + geom_ribbon(
          aes(x = factor(!!sym(sem_not)),
              ymin = !!sym(lwr),
              ymax = !!sym(upr),
              group = 1),
          alpha = 0.7, fill = "grey"
        )
      }

      individual_plots[[as.character(level)]] <- p_individual
    }

    plot_list[["combined_plot"]] <- p_combined
    plot_list[["individual_plots"]] <- individual_plots
  }

  return(plot_list)
}
