argumentos_boletim <- function() {
  base <- system.file("extdata", "feira_livre", package = "infodengesubmunicipal")
  list(municipio_nome = 'Feira "Livre"', uf = "XX", municipio_geocodigo = 999999,
       ano = 2026, populacao = 250000, output_qmd = tempfile(fileext = ".qmd"),
       notificacoes_path = file.path(base, "notificacoes.csv"),
       historico_alerta_path = file.path(base, "historico_alerta.csv"),
       referencia_path = file.path(base, "historico_alerta.csv"),
       limiar_preseason = 5, limiar_epidemico = 50, limiar_posseason = 10)
}
test_that("gerador valida parametros e entrega caminhos absolutos sem marcadores", {
  a <- argumentos_boletim()
  res <- do.call(criar_qmd_boletim, a)
  qmd <- paste(readLines(res), collapse = "\n")
  yaml <- yaml::yaml.load(strsplit(qmd, "---", fixed = TRUE)[[1]][2])
  expect_equal(yaml$params$municipio_nome, a$municipio_nome)
  expect_equal(yaml$params$notificacoes_path, normalizePath(a$notificacoes_path))
  expect_false(grepl("{{", qmd, fixed = TRUE))
  expect_error(do.call(criar_qmd_boletim, a), "ja existe")
  a$overwrite <- TRUE; a$limiar_completude <- 101
  expect_error(do.call(criar_qmd_boletim, a), "Limiares invalidos")
  a$limiar_completude <- 70; a$populacao <- Inf
  expect_error(do.call(criar_qmd_boletim, a), "finito")
})
test_that("logos sao opcionais, copiados e protegidos contra sobrescrita", {
  a <- argumentos_boletim(); pasta <- tempfile(); dir.create(pasta)
  a$output_qmd <- file.path(pasta, "boletim.qmd")
  logo <- tempfile(fileext = ".png"); png::writePNG(array(1, c(2, 2, 3)), logo)
  a$logo_esquerda <- logo; do.call(criar_qmd_boletim, a)
  expect_true(file.exists(file.path(pasta, "logo1.png")))
  a$output_qmd <- file.path(pasta, "outro.qmd")
  expect_error(do.call(criar_qmd_boletim, a), "Logo de destino ja existe")
  expect_false(file.exists(a$output_qmd))
  a$logo_esquerda <- NULL; do.call(criar_qmd_boletim, a)
  expect_false(any(grepl("logoboletim.*logo1.png", readLines(a$output_qmd))))
  a$output_qmd <- file.path(pasta, "invalido.qmd"); writeLines("nao png", logo); a$logo_direita <- logo
  expect_error(do.call(criar_qmd_boletim, a), "PNG valido")
  expect_false(file.exists(a$output_qmd))
})
