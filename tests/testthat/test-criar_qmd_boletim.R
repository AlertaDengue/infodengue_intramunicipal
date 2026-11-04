argumentos_boletim <- function() {
  base <- system.file("extdata", "feira_livre", package = "infodengueintramunicipal")
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
test_that("logo oficial e fixo e somente o logo direito e opcional", {
  a <- argumentos_boletim(); pasta <- tempfile(); dir.create(pasta)
  a$output_qmd <- file.path(pasta, "boletim.qmd")
  do.call(criar_qmd_boletim, a)
  oficial <- system.file("logos", "infodengue.png", package = "infodengueintramunicipal")
  expect_true(any(png::readPNG(oficial)[, , 4] > 0))
  expect_equal(unname(tools::md5sum(file.path(pasta, "logo1.png"))), unname(tools::md5sum(oficial)))
  expect_true(any(grepl("logoboletim.*logo1.png", readLines(a$output_qmd))))
  expect_false(any(grepl("logoboletim.*logo2.png", readLines(a$output_qmd))))
  expect_false("logo_esquerda" %in% names(formals(criar_qmd_boletim)))

  logo <- tempfile(fileext = ".png"); png::writePNG(array(1, c(2, 2, 3)), logo)
  a$output_qmd <- file.path(pasta, "direita.qmd"); a$logo_direita <- logo
  do.call(criar_qmd_boletim, a)
  expect_equal(unname(tools::md5sum(file.path(pasta, "logo2.png"))), unname(tools::md5sum(logo)))
  expect_true(any(grepl("logoboletim.*logo2.png", readLines(a$output_qmd))))
  a$output_qmd <- file.path(pasta, "protegido.qmd")
  expect_error(do.call(criar_qmd_boletim, a), "Logo de destino ja existe")
  expect_false(file.exists(a$output_qmd))

  a$logo_direita <- NULL; do.call(criar_qmd_boletim, a)
  expect_false(any(grepl("logoboletim.*logo2.png", readLines(a$output_qmd))))
  # Um arquivo alterado nao pode substituir o logo oficial silenciosamente.
  png::writePNG(array(0, c(2, 2, 3)), file.path(pasta, "logo1.png"))
  a$output_qmd <- file.path(pasta, "restaurado.qmd")
  expect_error(do.call(criar_qmd_boletim, a), "Logo de destino ja existe")
  expect_false(file.exists(a$output_qmd))
  a$overwrite <- TRUE; do.call(criar_qmd_boletim, a)
  expect_equal(unname(tools::md5sum(file.path(pasta, "logo1.png"))), unname(tools::md5sum(oficial)))

  a$output_qmd <- file.path(pasta, "invalido.qmd"); writeLines("nao png", logo); a$logo_direita <- logo
  expect_error(do.call(criar_qmd_boletim, a), "PNG valido")
  expect_false(file.exists(a$output_qmd))
})
