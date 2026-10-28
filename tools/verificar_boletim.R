# Rscript tools/verificar_boletim.R /pasta/de/saida [dengue|misto|chikungunya|vazio|logos|nowcasting] [gerar|validar|pdf]
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1L) stop("Informe uma pasta de saida.")
scenario <- if (length(args) > 1L) args[2] else "dengue"
acao <- if (length(args) > 2L) args[3] else "gerar"
library(infodengesubmunicipal)
base <- system.file("extdata", "feira_livre", package = "infodengesubmunicipal")
saida <- args[1]; dir.create(saida, recursive = TRUE, showWarnings = FALSE)
saida <- normalizePath(saida)
ref <- sf::st_read(file.path(base, "shape", "feira_livre_bairros.shp"), options = "ENCODING=UTF-8", quiet = TRUE)
stopifnot(nrow(ref) == 28L, sum(ref$pop) == 249990)
saveRDS(ref, file.path(saida, "referencia.rds"))
notificacoes <- ler_tabela_local(file.path(base, "notificacoes.csv"))
historico <- ler_tabela_local(file.path(base, "historico_alerta.csv"))
if (scenario %in% c("misto", "chikungunya")) {
  chik <- notificacoes; chik$nu_notific <- paste0("C", chik$nu_notific); chik$cid10_codigo <- "A92.0"
  hc <- historico; hc$arbo <- "chikon"
  if (scenario == "misto") {
    notificacoes <- dplyr::bind_rows(notificacoes, chik)
    historico <- dplyr::bind_rows(historico, hc)
  } else { notificacoes <- chik; historico <- hc }
}
if (scenario == "vazio") { notificacoes <- notificacoes[FALSE, ]; historico$casos <- 0; historico$p_inc100k <- 0 }
saveRDS(notificacoes, file.path(saida, "notificacoes.rds"))
saveRDS(historico, file.path(saida, "historico.rds"))
logo <- NULL
if (scenario == "logos") {
  logo <- file.path(saida, "logo-demonstracao.png")
  png::writePNG(array(rep(c(0, 0.3, 0.6), each = 400), c(20, 20, 3)), logo)
}
qmd <- criar_qmd_boletim(
  municipio_nome = "Feira Livre", uf = "XX", municipio_geocodigo = 999999,
  ano = 2026, populacao = 250000, output_qmd = file.path(saida, "boletim.qmd"),
  notificacoes_path = file.path(saida, "notificacoes.rds"),
  historico_alerta_path = file.path(saida, "historico.rds"),
  referencia_path = file.path(saida, "referencia.rds"),
  col_bairro_ref = "nm_bairro", col_bairro_id_ref = "id_bairro",
  col_distrito_ref = "nm_distr", col_pop_ref = "pop", col_geometry_ref = attr(ref, "sf_column"),
  # Valores exclusivamente demonstrativos; nao sao limiares municipais estimados por MEM.
  limiar_preseason = 5, limiar_epidemico = 50, limiar_posseason = 10,
  logo_esquerda = logo, logo_direita = logo, overwrite = TRUE,
  executar_nowcasting = identical(scenario, "nowcasting"), render = identical(acao, "pdf")
)
cat(qmd, "\n")

if (identical(acao, "validar")) {
  e <- new.env(parent = globalenv())
  e$params <- yaml::yaml.load(strsplit(paste(readLines(qmd), collapse = "\n"), "---", fixed = TRUE)[[1]][2])$params
  knitr::opts_knit$set(rmarkdown.pandoc.to = "latex")
  md <- withr::with_dir(saida, knitr::knit(qmd, output = "boletim-verificado.md", envir = e, quiet = TRUE))
  if (scenario == "vazio") {
    stopifnot(any(grepl("Não há notificações", readLines(file.path(saida, md)))))
  } else {
    stopifnot(sum(e$df_bairros$notificações) == nrow(e$df_mun_ok), length(e$nomes_distritos) == 4L,
              identical(as.integer(e$weeks_2_plot), c(202635L, 202636L, 202637L)),
              sum(e$perda_notificação$notificações_bruto) == nrow(e$df_mun),
              sum(e$perda_notificação$perca) + nrow(e$df_mun_ok) == nrow(e$df_mun))
    cat("Bruto:", nrow(e$df_mun), "alocado:", nrow(e$df_mun_ok),
        "grade:", sum(e$df_bairros$notificações), "divergencias temporais:", e$n_divergencias_temporais, "\n")
  }
}
