#' Criar gráfico de receptividade climática e temperatura mínima
#'
#' Gera um gráfico de séries temporais da temperatura mínima semanal e
#' da receptividade climática para transmissão de arboviroses. O gráfico
#' destaca visualmente as semanas em que a temperatura mínima está acima
#' do limiar favorável à transmissão (18°C), utilizando faixas coloridas
#' no fundo do gráfico.
#'
#' O gráfico também inclui uma linha horizontal indicando o limiar de
#' temperatura favorável à transmissão e apresenta a evolução semanal
#' da temperatura mínima.
#'
#' @param api_data Data frame contendo os dados climáticos. Deve incluir
#' ao menos as colunas `SE` (semana epidemiológica) e `tempmin`
#' (temperatura mínima).
#' @param weeks_limit Valor da última semana epidemiológica considerada
#' na análise.
#'
#' @return
#' Um objeto `ggplot` contendo o gráfico de receptividade climática
#' baseado na temperatura mínima semanal.
#'
#' @details
#' O gráfico inclui:
#'
#' * Faixas coloridas indicando semanas com temperatura mínima
#'   favorável (`tempmin >= 18°C`) ou desfavorável.
#' * Linha temporal da temperatura mínima semanal.
#' * Linha horizontal indicando o limiar climático favorável à
#'   transmissão de arboviroses (18°C).
#'
#' As semanas epidemiológicas exibidas são limitadas à janela
#' de um ano anterior até a semana atual.
#'
#' @examples
#' \dontrun{
#' create_receptivity_plot(
#'   api_data = dados_api,
#'   weeks_limit = 202452
#' )
#' }
#'
#' @seealso [create_receptivity_plot_novo()]
#' @export
create_receptivity_plot <- function(api_data, weeks_limit) {
  .Deprecated("create_receptivity_plot_novo", package = "infodengesubmunicipal")
  # Calcular fator de escala
  # scale_factor <- max(api_data$receptivo, na.rm = TRUE) / max(api_data$tempmin, na.rm = TRUE)

  api_data %>%
    filter(SE >= paste0(ano_atual-1,substr(weeks_2_plot[3],5,6))) %>%
    ggplot() +
    geom_rect(aes(xmin = as.numeric(factor(SE)) - 0.5,
                  xmax = as.numeric(factor(SE)) + 0.5,
                  ymin = -Inf,
                  ymax = Inf,
                  fill = tempmin >= 18), alpha = 0.7) +
    geom_line(aes(x = factor(SE), y = tempmin, group = 1),
              color = "orange2", linewidth = 1) +
    scale_fill_manual(values = c("TRUE" = "steelblue", "FALSE" = "grey70"), guide = "none") +

    geom_hline(aes(yintercept = 18, color = "Limiar Favor\u00e1vel (18\u00b0C)"),
               linewidth = 1, linetype = "dashed") +
    scale_color_manual(values = c("red")) +
    scale_x_discrete(breaks = breaks_1ano) +
    scale_y_continuous(
      name = "Temperatura M\u00ednima (\u00b0C)") +
    labs(x = "Semanas Epidemiol\u00f3gicas",
         title = "Receptividade clim\u00e1tica e Temperatura M\u00ednima por Semana",
         color = "") +
    theme_minimal() +
    theme(
      axis.title.y.right = element_blank(),  # Remove right axis title
      axis.text.y.right = element_blank(),   # Remove right axis text
      axis.title.y.left = element_text(color = "black"),
      legend.position = "top",
      axis.text.x = element_text(angle = 45, hjust = 1)
    )
}
