test_that("grade conserva SE53 e contagens nas duas APIs", {
  d <- tibble::tibble(arbo = "dengue", bairro = "TILAPIA", se = c(202553, 202601), notificações = c(8, 2))
  for (fn in list(completar_dados_bairros, completar_dados_bairros_novo)) {
    r <- fn(d, "TILAPIA", "se", "bairro", max_semana_epidemiologica = 202601)
    expect_equal(sum(r$notificações), 10)
    expect_equal(r$notificações[r$se == 202553], 8)
    expect_warning(fn(d, "OUTRO", "se", "bairro"), "2 linhas")
  }
})
test_that("calendario inclui semana vazia e virada de ano", {
  expect_equal(ultimas_semanas_epi(202637), c(202635L, 202636L, 202637L))
  expect_equal(ultimas_semanas_epi(202601), c(202552L, 202553L, 202601L))
  expect_error(ultimas_semanas_epi(202453), "inexistente")
})
