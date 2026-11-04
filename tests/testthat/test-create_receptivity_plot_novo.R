test_that("grafico legado preserva parametros e avisa sobre configuracao", {
  dados <- data.frame(SE = 202401:202403, tempmin = c(17, 18, 20))
  expect_warning(p <- create_receptivity_plot_novo(dados, 202403, 202401:202403), "legado Af")
  d <- p$data[match(as.character(dados$SE), as.character(p$data$semana)), ]
  expect_equal(d$valor, dados$tempmin)
  expect_equal(as.character(d$condicao), c("Desfavoravel", "Desfavoravel", "Favoravel"))
  expect_warning(p <- create_receptivity_plot_novo(dados, 202403, 202401:202403, limiar_temp = 20), "20 graus")
  expect_match(p$labels$subtitle, "20")
})

test_that("grafico respeita variaveis, limite, fatores e lacunas", {
  cfg <- list(modelo = "AsAw", colunas = list(temp_min = "temperatura", umid_max = "umidade"),
              limiares = list(temp_min = 18, umid_max = 70))
  dados <- data.frame(SE = factor(c(202401, 202402, 202404, 202405)),
                      temperatura = c(19, 19, 19, 19), umidade = c(71, 70, NA, 80))
  p <- create_receptivity_plot_novo(dados, factor("202404"), 202401:202404, config_climatica = cfg)
  expect_s3_class(p, "ggplot")
  expect_equal(nrow(p$data), 106)
  expect_equal(length(unique(p$data$variavel)), 2)
  d <- p$data[as.character(p$data$semana) %in% as.character(202401:202404), ]
  expect_equal(as.character(d$condicao), rep(c("Favoravel", "Desfavoravel", "Indisponivel", "Indisponivel"), 2))
  expect_false(any(as.character(p$data$semana) == "202405"))
  expect_silent(ggplot2::ggplot_build(p))
  alias <- criar_grafico_receptividade_novo(dados, 202404, 202401:202404, config_climatica = cfg)
  expect_equal(alias$data, p$data)
  expect_error(create_receptivity_plot_novo(dados, 202404, 202401:202404,
                                           limiar_temp = 18, config_climatica = cfg), "Nao combine")
  expect_error(create_receptivity_plot_novo(dados[c(1, 1), ], 202404, 202401:202404,
                                           config_climatica = cfg), "uma linha por semana")
})

test_that("umidade isolada usa limiar e unidade proprios", {
  cfg <- list(modelo = "Aw", colunas = list(umid_max = "umidade"), limiares = list(umid_max = 70))
  p <- create_receptivity_plot_novo(data.frame(SE = 202601:202603, umidade = c(69, 70, 71)),
                                   202603, 202601:202603, config_climatica = cfg)
  expect_match(p$labels$subtitle, "Umidade maxima.*70")
  expect_false(any(grepl("Temperatura", p$data$variavel)))
  expect_equal(unique(p$data$limiar), 70)
})
