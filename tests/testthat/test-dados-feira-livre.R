test_that("dados nativos preservam as bases sinteticas de origem", {
  base <- system.file("extdata", "feira_livre", package = "infodengueintramunicipal")
  expect_identical(infodengueintramunicipal::historico_alerta,
                   as.data.frame(ler_tabela_local(file.path(base, "historico_alerta.csv"))))
  expect_identical(infodengueintramunicipal::notificacoes_alerta,
                   as.data.frame(ler_tabela_local(file.path(base, "notificacoes.csv"))))
  ref <- sf::st_read(file.path(base, "shape", "feira_livre_bairros.shp"),
                     options = "ENCODING=UTF-8", quiet = TRUE)
  expect_identical(infodengueintramunicipal::referencia_intramunicipal, ref)
})

test_that("data carrega cada base e a lista com as mesmas informacoes", {
  nomes <- c("historico_alerta", "notificacoes_alerta", "referencia_intramunicipal")
  env <- new.env(parent = emptyenv())
  for (nome in c(nomes, "dados")) {
    utils::data(list = nome, package = "infodengueintramunicipal", envir = env)
    expect_true(exists(nome, envir = env, inherits = FALSE))
    expect_identical(env[[nome]], getExportedValue("infodengueintramunicipal", nome))
  }
  expect_named(env$dados, nomes)
  for (nome in nomes) expect_identical(env$dados[[nome]], env[[nome]])
})
