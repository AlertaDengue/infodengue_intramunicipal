test_that("normalizar_bairro remove acentos e caracteres especiais", {

  input <- c("São João", "Bairro-1", "  Vila   Nova  ")
  expected <- c("SAO JOAO", "BAIRRO1", "VILA NOVA")

  result <- normalizar_bairro(input)

  expect_equal(result, expected)

})


test_that("normalizar_bairro lida com NA corretamente", {

  input <- c("Centro", NA)

  result <- normalizar_bairro(input)

  expect_true(is.na(result[2]))
  expect_equal(result[1], "CENTRO")

})

test_that("normalizar_bairro é idempotente", {

  input <- "SAO JOAO"

  result1 <- normalizar_bairro(input)
  result2 <- normalizar_bairro(result1)

  expect_equal(result1, result2)

})


test_that("normalizar_bairro normaliza bairros reais do df_mun", {

  # pegar amostra real
  bairros_raw <- df_mun %>%
    dplyr::filter(!is.na(nm_bairro)) %>%
    dplyr::slice_head(n = 20) %>%
    dplyr::pull(nm_bairro)

  bairros_norm <- normalizar_bairro(bairros_raw)

  # 1. não deve ter acento
  expect_false(any(grepl("[ÁÉÍÓÚÂÊÔÃÕÇ]", bairros_norm)))

  # 2. deve estar em maiúsculo
  expect_true(all(bairros_norm == toupper(bairros_norm)))

  # 3. não deve ter caracteres especiais
  expect_false(any(grepl("[^A-Z0-9 ]", bairros_norm)))

})

 test_that("normalizar_bairro preserva nomes UTF-8 no locale C", {
  entrada <- c("Til\u00e1pia", "S\u00e3o Jo\u00e3o", NA_character_)
  resultado <- withr::with_locale(c(LC_CTYPE = "C"), normalizar_bairro(entrada))
  expect_equal(resultado, c("TILAPIA", "SAO JOAO", NA_character_))
})
