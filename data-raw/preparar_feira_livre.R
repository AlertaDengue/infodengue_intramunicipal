# Rscript data-raw/preparar_feira_livre.R /pasta/de/saida
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 1L) stop("Informe uma pasta de saida.")
base <- system.file("extdata", "feira_livre", package = "infodengesubmunicipal")
if (!nzchar(base)) base <- file.path("inst", "extdata", "feira_livre")
dir.create(args[1], recursive = TRUE, showWarnings = FALSE)
ref <- sf::st_read(file.path(base, "shape", "feira_livre_bairros.shp"),
                   options = "ENCODING=UTF-8", quiet = TRUE)
stopifnot(nrow(ref) == 28L, length(unique(ref$nm_distr)) == 4L,
          sum(ref$pop) == 249990, !any(sf::st_is_empty(ref)), all(sf::st_is_valid(ref)))
# O CRS cartesiano local e preservado: nao atribuir EPSG geograficamente ficticio.
saveRDS(ref, file.path(args[1], "referencia.rds"))
cat("Referencia preparada em", normalizePath(file.path(args[1], "referencia.rds")), "\n")
