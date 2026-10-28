test_that("ajuste legado alinha semanas por chave e preserva ordem", {
  estimado <- tibble::tibble(ano_epi = c(202602, 202601, 202603), Median = c(1, 1, NA_real_),
                            LI = c(0, 0, NA_real_), LS = c(2, 2, NA_real_), type = "Nowcasting")
  observado <- tibble::tibble(ano_epi = c(202601, 202602), total_Y = c(10, 20))
  r <- ajustar_nowcasting_legado(estimado, observado)
  expect_equal(r$ano_epi, estimado$ano_epi)
  expect_equal(r$Median, c(20, 10, NA_real_))
  expect_equal(r$LI, c(19.5, 9.5, NA_real_))
  expect_equal(r$LS, c(20.5, 10.5, NA_real_))
  expect_error(ajustar_nowcasting_legado(estimado, dplyr::bind_rows(observado, observado[1, ])), "uma linha")
})
