test_that("criar_qmd_boletim gera QMD parametrizado", {
  output <- tempfile(fileext = ".qmd")

  res <- criar_qmd_boletim(
    municipio_nome = "Brasilia",
    uf = "DF",
    municipio_geocodigo = 5300108,
    ano = 2026,
    populacao = 2817068,
    output_qmd = output,
    notificacoes_path = "dados/notificacoes.parquet",
    historico_alerta_path = "dados/historico_alerta.csv",
    referencia_path = "dados/ref_submunicipal.rds"
  )

  expect_equal(res, normalizePath(output))
  expect_true(file.exists(output))

  qmd <- paste(readLines(output, warn = FALSE), collapse = "\n")

  expect_match(qmd, "Boletim Municipal - Brasilia", fixed = TRUE)
  expect_match(qmd, "municipio_geocodigo: 5300108", fixed = TRUE)
  expect_match(qmd, "ano: 2026", fixed = TRUE)
  expect_match(qmd, 'notificacoes_path: "dados/notificacoes.parquet"', fixed = TRUE)
  expect_match(qmd, 'historico_alerta_path: "dados/historico_alerta.csv"', fixed = TRUE)
  expect_match(qmd, 'referencia_path: "dados/ref_submunicipal.rds"', fixed = TRUE)
  expect_match(qmd, "```{r nowcasting, include=FALSE, cache=FALSE}", fixed = TRUE)
  expect_match(qmd, "```{r bairros_ultima_semana, include=FALSE}", fixed = TRUE)
  expect_match(qmd, "```{r fig13", fixed = TRUE)
  expect_match(qmd, "tabela_indicadores", fixed = TRUE)
  expect_false(grepl("{{municipio_nome}}", qmd, fixed = TRUE))
})

test_that("criar_qmd_boletim exige historico unico ou historicos por agravo", {
  output <- tempfile(fileext = ".qmd")

  expect_error(
    criar_qmd_boletim(
      municipio_nome = "Brasilia",
      uf = "DF",
      municipio_geocodigo = 5300108,
      ano = 2026,
      populacao = 2817068,
      output_qmd = output,
      notificacoes_path = "dados/notificacoes.parquet",
      referencia_path = "dados/ref_submunicipal.rds"
    ),
    "Informe historico_alerta_path"
  )
})

test_that("criar_qmd_boletim nao sobrescreve sem overwrite", {
  output <- tempfile(fileext = ".qmd")
  writeLines("existente", output)

  expect_error(
    criar_qmd_boletim(
      municipio_nome = "Brasilia",
      uf = "DF",
      municipio_geocodigo = 5300108,
      ano = 2026,
      populacao = 2817068,
      output_qmd = output,
      notificacoes_path = "dados/notificacoes.parquet",
      historico_alerta_path = "dados/historico_alerta.csv",
      referencia_path = "dados/ref_submunicipal.rds"
    ),
    "output_qmd ja existe"
  )
})
