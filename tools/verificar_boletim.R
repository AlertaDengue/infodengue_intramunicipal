# Rscript tools/verificar_boletim.R /pasta/de/saida [dengue|misto|chikungunya|vazio|logos|nowcasting|numero-repetido|limiares-chik|clima-temperatura|clima-umidade|clima-combinado|clima-ausente] [gerar|validar|pdf]
args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1L) stop("Informe uma pasta de saida.")
scenario <- if (length(args) > 1L) args[2] else "dengue"
acao <- if (length(args) > 2L) args[3] else "gerar"
library(infodengueintramunicipal)
base <- system.file("extdata", "feira_livre", package = "infodengueintramunicipal")
saida <- args[1]; dir.create(saida, recursive = TRUE, showWarnings = FALSE)
saida <- normalizePath(saida)
ref <- sf::st_read(file.path(base, "shape", "feira_livre_bairros.shp"), options = "ENCODING=UTF-8", quiet = TRUE)
stopifnot(nrow(ref) == 28L, sum(ref$pop) == 249990)
saveRDS(ref, file.path(saida, "referencia.rds"))
notificacoes <- ler_tabela_local(file.path(base, "notificacoes.csv"))
historico <- ler_tabela_local(file.path(base, "historico_alerta.csv"))
if (scenario %in% c("misto", "chikungunya", "chikon-historico", "limiares-chik")) {
  chik <- notificacoes; chik$nu_notific <- paste0("C", chik$nu_notific); chik$cid10_codigo <- "A92.0"
  hc <- historico; hc$arbo <- "chikon"
  if (scenario == "chikon-historico") {
    chik <- chik[chik$ano_notif < 2026, ]; hc <- hc[hc$SE < 202601, ]
    notificacoes <- dplyr::bind_rows(notificacoes, chik)
    historico <- dplyr::bind_rows(historico, hc)
  } else if (scenario %in% c("misto", "limiares-chik")) {
    notificacoes <- dplyr::bind_rows(notificacoes, chik)
    historico <- dplyr::bind_rows(historico, hc)
  } else { notificacoes <- chik; historico <- hc }
}
if (scenario == "vazio") { notificacoes <- notificacoes[FALSE, ]; historico$casos <- 0; historico$p_inc100k <- 0 }
if (scenario == "numero-repetido") {
  # Numero reutilizado em datas diferentes da mesma semana continua sendo dois registros.
  repetido <- notificacoes[1, ]
  repetido$dt_notific <- as.Date(repetido$dt_notific) - 1
  notificacoes <- dplyr::bind_rows(notificacoes, repetido)
}
# Parametros e umidade sinteticos: nao representam municipios reais.
config_climatica <- list(modelo = "Af", colunas = list(temp_min = "tempmin"),
                         limiares = list(temp_min = 18))
if (scenario %in% c("clima-umidade", "clima-combinado", "clima-ausente")) {
  historico$umidmax <- 70 + 10 * sin(seq_len(nrow(historico)) / 3)
  if (scenario == "clima-umidade") {
    historico$tempmin <- NULL
    config_climatica <- list(modelo = "Aw", colunas = list(umid_max = "umidmax"),
                             limiares = list(umid_max = 70))
  } else {
    config_climatica <- list(modelo = "AsAw", colunas = list(temp_min = "tempmin", umid_max = "umidmax"),
                             limiares = list(temp_min = 18, umid_max = 70))
  }
  if (scenario == "clima-ausente") historico$umidmax[historico$SE == 202636] <- NA_real_
}
saveRDS(notificacoes, file.path(saida, "notificacoes.rds"))
saveRDS(historico, file.path(saida, "historico.rds"))
logo <- NULL
if (scenario == "logos") {
  logo <- file.path(saida, "logo-demonstracao.png")
  png::writePNG(array(rep(c(0, 0.3, 0.6), each = 400), c(20, 20, 3)), logo)
}
qmd <- criar_qmd_boletim(
  municipio_nome = "Feira Livre", uf = "XX", municipio_geocodigo = 999999,
  ano = if (scenario == "ano-2025") 2025 else 2026, populacao = 250000, output_qmd = file.path(saida, "boletim.qmd"),
  notificacoes_path = file.path(saida, "notificacoes.rds"),
  historico_alerta_path = file.path(saida, "historico.rds"),
  referencia_path = file.path(saida, "referencia.rds"),
  col_bairro_ref = "nm_bairro", col_bairro_id_ref = "id_bairro",
  col_distrito_ref = "nm_distr", col_pop_ref = "pop", col_geometry_ref = attr(ref, "sf_column"),
  # Valores exclusivamente demonstrativos; nao sao limiares municipais estimados por MEM.
  limiar_preseason = 5, limiar_epidemico = 50, limiar_posseason = 10,
  limiar_preseason_chik = if (scenario == "limiares-chik") 2 else NULL,
  limiar_epidemico_chik = if (scenario == "limiares-chik") 20 else NULL,
  limiar_posseason_chik = if (scenario == "limiares-chik") 4 else NULL,
  logo_direita = logo, overwrite = TRUE, config_climatica = config_climatica,
  executar_nowcasting = identical(scenario, "nowcasting"), render = identical(acao, "pdf")
)
cat(qmd, "\n")

if (identical(acao, "validar")) {
  e <- new.env(parent = globalenv())
  e$params <- yaml::yaml.load(strsplit(paste(readLines(qmd), collapse = "\n"), "---", fixed = TRUE)[[1]][2])$params
  knitr::opts_knit$set(rmarkdown.pandoc.to = "latex")
  if (scenario == "nowcasting") set.seed(20)
  md <- withr::with_dir(saida, knitr::knit(qmd, output = "boletim-verificado.md", envir = e, quiet = TRUE))
  if (scenario == "vazio") {
    stopifnot(any(grepl("Não há notificações", readLines(file.path(saida, md)))))
  } else {
    stopifnot(sum(e$df_bairros$notificações) == nrow(e$df_mun_ok), length(e$nomes_distritos) == 4L,
              identical(as.integer(e$weeks_2_plot), if (scenario == "ano-2025") c(202551L, 202552L, 202553L) else c(202635L, 202636L, 202637L)),
              sum(e$perda_notificação$notificações_bruto) == nrow(e$df_mun),
              sum(e$perda_notificação$perca) + nrow(e$df_mun_ok) == nrow(e$df_mun))
    # Os niveis e o indicador municipais nao sao recalculados.
    original <- historico[order(historico$arbo, historico$SE), ]
    stopifnot(identical(e$dados_api$nivel, original$nivel),
              identical(e$dados_api$receptivo, original$receptivo),
              isTRUE(all.equal(e$config_climatica, config_climatica)))
    climaticas <- names(config_climatica$limiares)
    stopifnot(all(climaticas %in% names(e$df_distritos)))
    if (scenario == "clima-ausente") {
      stopifnot(all(is.na(e$df_distritos$nivel[e$df_distritos$sem_not == 202636])),
                all(is.na(e$dados_api$clima_favoravel[e$dados_api$SE == 202636])))
    }
    if (scenario == "clima-umidade") stopifnot(!"tempmin" %in% names(e$dados_api))
    if (scenario == "nowcasting") {
      stopifnot(e$tem_nowcast, length(e$estados_nowcasting) == 5L,
                all(grepl("^ajustado \\(Dmax = ", unlist(e$estados_nowcasting))),
                all(c("ano_epi", "Median", "LI", "LS") %in% names(e$mun_nowcast)),
                all(e$mun_nowcast$LI <= e$mun_nowcast$Median),
                all(e$mun_nowcast$Median <= e$mun_nowcast$LS),
                all(e$mun_nowcast$ano_epi <= lubridate::epiyear(e$fim_nowcast) * 100 + lubridate::epiweek(e$fim_nowcast)))
    }
    if (scenario == "numero-repetido") {
      stopifnot(nrow(e$df_mun) == 7211L, nrow(e$df_mun_ok) == 6922L,
                !anyDuplicated(e$df_mun_ok$id_registro))
      # A mesma chave completa, ao contrario, deve interromper antes das contagens.
      saveRDS(dplyr::bind_rows(notificacoes, notificacoes[1, ]), file.path(saida, "notificacoes.rds"))
      duplicata <- tryCatch({
        withr::with_dir(saida, knitr::knit(qmd, output = "duplicata.md", envir = new.env(parent = e), quiet = TRUE))
        NULL
      }, error = identity)
      stopifnot(inherits(duplicata, "error"), grepl("Notificacoes duplicadas", conditionMessage(duplicata)))
      saveRDS(notificacoes, file.path(saida, "notificacoes.rds"))
    }
    if (scenario == "limiares-chik") {
      stopifnot(isTRUE(all.equal(unname(e$limiares_mem$dengue), c(5, 50, 10))),
                isTRUE(all.equal(unname(e$limiares_mem$chikon), c(2, 20, 4))),
                e$params_modelo_agravo("chikon")$limiar_epidemico == 20,
                e$params_modelo_agravo("chikon")$cid10 == "A92.0",
                isTRUE(all.equal(e$tab_limiar_dados$Chikungunya, c(2, 20, 4))),
                any(vapply(e$rf_inc_mun_chikon$layers, function(layer) {
                  inherits(layer$geom, "GeomHline") && isTRUE(layer$data$yintercept == 20)
                }, logical(1))))
      for (agravo in c("dengue", "chikon")) {
        rt_plot <- e$grafico_rt_mun(agravo, "Rt", if (agravo == "dengue") 3 else 2,
                                  if (agravo == "dengue") 1 else 2)
        stopifnot(all(c("Rt", "lwr", "upr") %in% names(rt_plot$data)),
                  any(is.finite(rt_plot$data$lwr)), any(is.finite(rt_plot$data$upr)),
                  any(vapply(rt_plot$layers, function(layer) inherits(layer$geom, "GeomRibbon"), logical(1))))
      }
    }
    if (scenario == "chikon-historico") stopifnot(!e$tem_chikon, e$n_divergencias_temporais == 143L)
    if (scenario == "ano-2025") stopifnot(e$ano_atual == 2025, all(as.integer(e$df_mun$ano_notif) <= 2025))
    cat("Bruto:", nrow(e$df_mun), "alocado:", nrow(e$df_mun_ok),
        "grade:", sum(e$df_bairros$notificações), "divergencias temporais:", e$n_divergencias_temporais, "\n")
  }
}
