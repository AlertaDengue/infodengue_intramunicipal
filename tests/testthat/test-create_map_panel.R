testthat::test_that("create_map_panel combina os tres ultimos mapas e retorna ggplot", {
  plots_list <- list(
    ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, color = factor(cyl))) + ggplot2::geom_point(),
    ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, color = factor(cyl))) + ggplot2::geom_point(),
    ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, fill = factor(cyl))) + ggplot2::geom_point(shape = 21),
    ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, fill = factor(cyl))) + ggplot2::geom_point(shape = 21)
  )

  resultado <- create_map_panel(
    plots_list = plots_list,
    legend_title = "Legenda teste"
  )

  testthat::expect_s3_class(resultado, "ggplot")
})

 test_that("painel aceita quantidades diversas e rejeita escalas incompatíveis", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, fill = factor(cyl))) + ggplot2::geom_point(shape = 21)
  for (n in 1:4) expect_s3_class(create_map_panel(rep(list(p), n)), "ggplot")
  expect_s3_class(create_map_panel(list(ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point())), "ggplot")
  expect_error(create_map_panel(list()), "ao menos")
  q <- p + ggplot2::scale_fill_manual(values = c("red", "green", "blue"))
  expect_error(create_map_panel(list(p, q)), "incompativeis")
})
