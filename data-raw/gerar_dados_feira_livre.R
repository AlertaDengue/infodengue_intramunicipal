# Execute na raiz do repositorio: Rscript data-raw/gerar_dados_feira_livre.R
# Usa apenas os arquivos sinteticos versionados; nao consulta servicos externos.
base <- file.path("inst", "extdata", "feira_livre")
leitor <- new.env(parent = globalenv())
sys.source(file.path("R", "entradas_boletim.R"), envir = leitor)
historico_alerta <- as.data.frame(leitor$ler_tabela_local(file.path(base, "historico_alerta.csv")))
notificacoes_alerta <- as.data.frame(leitor$ler_tabela_local(file.path(base, "notificacoes.csv")))
referencia_intramunicipal <- sf::st_read(
  file.path(base, "shape", "feira_livre_bairros.shp"),
  options = "ENCODING=UTF-8", quiet = TRUE
)
stopifnot(nrow(historico_alerta) == 90L, nrow(notificacoes_alerta) == 7210L,
          is.character(notificacoes_alerta$nu_notific),
          is.character(notificacoes_alerta$id_bairro),
          nrow(referencia_intramunicipal) == 28L)
dados <- list(historico_alerta = historico_alerta,
              notificacoes_alerta = notificacoes_alerta,
              referencia_intramunicipal = referencia_intramunicipal)
dir.create("data", showWarnings = FALSE)
for (nome in c(names(dados), "dados")) {
  save(list = nome, file = file.path("data", paste0(nome, ".rda")),
       compress = "xz", version = 2)
}
