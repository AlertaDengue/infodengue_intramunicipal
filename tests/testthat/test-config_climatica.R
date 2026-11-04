config_teste_clima <- function(modelo = "Af") {
  vars <- variaveis_modelo_climatico()[[modelo]]
  list(modelo = modelo, colunas = as.list(setNames(vars, vars)),
       limiares = as.list(c(temp_min = 18, umid_max = 70, umid_min = 40)[vars]))
}

test_that("configuracao valida os cinco modelos e rejeita ambiguidades", {
  for (modelo in names(variaveis_modelo_climatico())) {
    cfg <- config_teste_clima(modelo)
    expect_identical(normalizar_config_climatica(cfg), cfg)
  }
  expect_warning(legado <- normalizar_config_climatica(), "Confirme os parametros oficiais")
  expect_equal(legado$limiares$temp_min, 18)
  expect_equal(legado$colunas$temp_min, "tempmin")
  ruins <- list(list(), list(modelo = "outro", colunas = list(), limiares = list()))
  for (cfg in ruins) expect_error(normalizar_config_climatica(cfg))
  cfg <- config_teste_clima("AsAw"); cfg$colunas <- list(temp_min = "temp_min")
  expect_error(normalizar_config_climatica(cfg), "variaveis do modelo")
  cfg <- config_teste_clima("Aw"); cfg$limiares$umid_max <- 101
  expect_error(normalizar_config_climatica(cfg), "entre 0 e 100")
  for (valor in list(NA_real_, Inf, "18", c(18, 19))) {
    cfg <- config_teste_clima(); cfg$limiares$temp_min <- valor
    expect_error(normalizar_config_climatica(cfg), "escalar finito")
  }
  cfg <- config_teste_clima(); cfg$colunas$temp_min <- "nivel"
  expect_error(normalizar_config_climatica(cfg), "reservada")
  cfg <- config_teste_clima("AsAw"); cfg$colunas$umid_max <- "temp_min"
  expect_error(normalizar_config_climatica(cfg), "distintas")
  cfg <- config_teste_clima(); cfg$extra <- TRUE
  expect_error(normalizar_config_climatica(cfg), "somente")
})

test_that("condicao conjunta concorda com as regras reais do AlertTools", {
  # Mesmo ambiente de dependencias carregadas pelo template.
  withr::local_package("assertthat")
  withr::local_package("stringr")
  withr::local_package("dplyr")
  dados <- data.frame(temp_min = c(17, 18, 19, 19, 19, 19),
                      umid_max = c(80, 80, 70, 69, 71, NA),
                      umid_min = c(50, 50, 40, 39, 41, NA), inc = 1)
  esperado <- list(Af = c(FALSE, FALSE, TRUE, TRUE, TRUE, TRUE),
                   Aw = c(TRUE, TRUE, FALSE, FALSE, TRUE, NA),
                   Awi = c(TRUE, TRUE, FALSE, FALSE, TRUE, NA),
                   AsAw = c(FALSE, FALSE, FALSE, FALSE, TRUE, NA),
                   AsAwi = c(FALSE, FALSE, FALSE, FALSE, TRUE, NA))
  for (modelo in names(esperado)) {
    cfg <- config_teste_clima(modelo)
    d <- preparar_colunas_climaticas(dados, cfg)
    expect_identical(d$clima_favoravel, esperado[[modelo]])
    params <- c(parametros_climaticos_alerta(cfg), list(limiar_preseason = 100, limiar_epidemico = 200))
    crit <- construir_criteria_alerta(params)
    regra <- with(d, eval(parse(text = crit$crity[1])))
    expect_equal(d$clima_favoravel, regra)
  }
  cfg <- config_teste_clima("AsAw"); dados$temp_min[6] <- 10
  expect_true(is.na(preparar_colunas_climaticas(dados, cfg)$clima_favoravel[6]))
  expect_error(preparar_colunas_climaticas(dados["temp_min"], cfg), "umid_max")
  dados$umid_max[1] <- 110
  expect_error(preparar_colunas_climaticas(dados, cfg), "entre 0 e 100")
  dados$umid_max[1] <- "erro"
  expect_error(preparar_colunas_climaticas(dados, cfg), "invalidos")
})

test_that("historico de umidade dispensa temperatura e preserva indicadores municipais", {
  h <- data.frame(SE = 202601:202604, arbo = "dengue", casos = 5, p_inc100k = 2,
                  nivel = c(4, 3, NA, 1), Rt = 1, receptivo = c(1, 0, NA, 1),
                  umidade = c(69, 70, 71, NA))
  path <- tempfile(fileext = ".rds"); saveRDS(h, path)
  cfg <- config_teste_clima("Aw"); cfg$colunas$umid_max <- "umidade"
  r <- preparar_historico_alerta(path, config_climatica = cfg)
  expect_false("tempmin" %in% names(r))
  expect_equal(r$nivel, h$nivel)
  expect_equal(r$receptivo, h$receptivo)
  expect_equal(r$clima_favoravel, c(FALSE, FALSE, TRUE, NA))
  expect_equal(attr(r, "config_climatica"), cfg)
  expect_equal(attr(r, "parametros_climaticos")$codmodelo, "Aw")
  expect_match(attr(r, "criterio_climatico"), "Umidade maxima.*70")
  h$arbo <- NULL; saveRDS(h, path)
  expect_equal(nrow(preparar_historico_alerta(path_dengue = path, config_climatica = cfg)), 4)
  cfg$colunas$umid_max <- "inexistente"
  expect_error(preparar_historico_alerta(path_dengue = path, config_climatica = cfg), "inexistente")
  cfg <- config_teste_clima(); h$tempmin <- 19; saveRDS(h, path)
  expect_warning(preparar_historico_alerta(path_dengue = path), "legado Af")
})

test_that("lacunas climaticas interrompem persistencia sem imputacao", {
  # Mesmo ambiente de dependencias carregadas pelo template.
  withr::local_package("assertthat")
  withr::local_package("stringr")
  withr::local_package("dplyr")
  cfg <- config_teste_clima("AsAw")
  d <- data.frame(sem_not = 202601:202608, temp_min = 19, umid_max = 80,
                  casos = 5, inc = 1, p1 = 0)
  d$umid_max[4] <- NA
  d <- preparar_colunas_climaticas(d, cfg)
  params <- c(parametros_climaticos_alerta(cfg), list(limiar_preseason = 100, limiar_epidemico = 200))
  r <- classificar_alerta(d, params)
  expect_equal(r$nivel, c(1, 1, 2, NA, 1, 1, 2, 2))
  expect_true(is.na(r$receptivo[4]))
  expect_equal(r$receptivo[-4], rep(1, 7))
  # Bloco final de uma semana e serie de uma semana devem ser validos.
  curto <- classificar_alerta(d[1, ], params)
  expect_equal(curto$nivel, 1)
  expect_equal(curto$receptivo, 1)
  # Um nivel preexistente nao pode mascarar o indice interno do AlertTools.
  expect_equal(classificar_alerta(transform(d, nivel = 4), params)$nivel, r$nivel)
  # Ausencia de uma semana tambem reinicia a sequencia.
  d <- d[-4, ]; r <- classificar_alerta(d, params)
  expect_equal(r$nivel, c(1, 1, 2, 1, 1, 2, 2))
  d$clima_favoravel <- NA; r <- classificar_alerta(d, params)
  expect_true(all(is.na(r$nivel)))
  # Clima favoravel nao implica receptividade do alerta sem casos.
  d <- preparar_colunas_climaticas(transform(d, inc = 0, casos = 0), cfg)
  expect_true(all(d$clima_favoravel))
  expect_true(all(classificar_alerta(d, params)$receptivo == 0))
})
