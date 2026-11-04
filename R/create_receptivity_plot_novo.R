#' Criar grafico de condicoes climaticas municipais
#'
#' Usa a configuracao municipal e comparacoes estritas (>) como o AlertTools.
#' A condicao climatica nao inclui casos nem persistencia do nivel de alerta.
#'
#' @param api_data Data frame com uma linha por semana e variaveis climaticas.
#' @param weeks_limit Ultima semana epidemiologica considerada.
#' @param breaks_1ano Vetor com os breaks do eixo X.
#' @param limiar_temp Limiar legado de temperatura; nao combinar com config_climatica.
#' @param se_col Nome da coluna da semana epidemiologica.
#' @param temp_col Coluna legada de temperatura; nao combinar com config_climatica.
#' @param config_climatica Configuracao com modelo, colunas e limiares; consulte
#'   [criar_qmd_boletim()]. NULL usa temperatura com aviso de compatibilidade.
#'
#' @return Objeto `ggplot`, com paineis separados por variavel. Semanas sem
#'   informacao ficam indisponiveis. Mostra as ultimas 53 semanas consecutivas.
#' @export
create_receptivity_plot_novo <- function(api_data, weeks_limit, breaks_1ano,
                                         limiar_temp = 18, se_col = "SE",
                                         temp_col = "tempmin", config_climatica = NULL) {
  if (!is.null(config_climatica) && (!missing(limiar_temp) || !missing(temp_col))) {
    stop("Nao combine config_climatica com limiar_temp ou temp_col.", call. = FALSE)
  }
  if (is.null(config_climatica)) {
    cfg <- normalizar_config_climatica(list(modelo = "Af", colunas = list(temp_min = temp_col),
                                             limiares = list(temp_min = limiar_temp)))
    avisar_clima_legado(temp_col, limiar_temp)
  } else {
    cfg <- normalizar_config_climatica(config_climatica)
  }
  validar_colunas(api_data, se_col, "dados climaticos")
  dados <- preparar_colunas_climaticas(api_data, cfg)
  dados[[se_col]] <- validar_semanas_epi(dados[[se_col]])
  if (anyDuplicated(dados[[se_col]])) stop("Serie climatica deve ter uma linha por semana.", call. = FALSE)
  semanas <- ultimas_semanas_epi(as.numeric(as.character(weeks_limit)), n = 53L)
  dados <- dados[match(semanas, dados[[se_col]]), , drop = FALSE]
  dados$semana <- factor(semanas, levels = semanas)
  dados$condicao <- factor(ifelse(is.na(dados$clima_favoravel), "Indisponivel",
                                  ifelse(dados$clima_favoravel, "Favoravel", "Desfavoravel")),
                          levels = c("Favoravel", "Desfavoravel", "Indisponivel"))
  paineis <- lapply(names(cfg$colunas), function(v) {
    data.frame(semana = dados$semana, valor = dados[[v]], condicao = dados$condicao,
               variavel = rotulos_climaticos()[[v]], limiar = cfg$limiares[[v]])
  })
  longo <- dplyr::bind_rows(paineis)
  longo$variavel <- factor(longo$variavel, levels = unname(rotulos_climaticos()[names(cfg$colunas)]))
  limites <- unique(longo[c("variavel", "limiar")])
  ggplot2::ggplot(longo) +
    ggplot2::geom_rect(ggplot2::aes(xmin = as.numeric(.data$semana) - 0.5,
                                    xmax = as.numeric(.data$semana) + 0.5,
                                    ymin = -Inf, ymax = Inf, fill = .data$condicao), alpha = 0.45, show.legend = TRUE) +
    ggplot2::geom_line(ggplot2::aes(x = .data$semana, y = .data$valor, group = 1),
                       color = "orange3", linewidth = 0.8, na.rm = TRUE) +
    ggplot2::geom_point(ggplot2::aes(x = .data$semana, y = .data$valor), size = 0.8, na.rm = TRUE) +
    ggplot2::geom_hline(data = limites, ggplot2::aes(yintercept = .data$limiar),
                        color = "red3", linetype = "dashed") +
    ggplot2::facet_wrap(~variavel, ncol = 1, scales = "free_y") +
    ggplot2::scale_fill_manual(values = c(Favoravel = "steelblue", Desfavoravel = "grey70",
                                          Indisponivel = "#F6D99A"), drop = FALSE) +
    ggplot2::scale_x_discrete(breaks = breaks_1ano, drop = FALSE) +
    ggplot2::labs(x = "Semanas epidemiologicas", y = NULL,
                  title = "Condicoes climaticas para transmissao",
                  subtitle = paste(strwrap(descrever_config_climatica(cfg), width = 70), collapse = "\n"),
                  fill = "Condicao conjunta", caption = "Linha tracejada: limiar. Sem dados: indisponivel.") +
    ggplot2::theme_minimal() +
    ggplot2::theme(legend.position = "bottom", axis.text.x = ggplot2::element_text(angle = 45, hjust = 1))
}
