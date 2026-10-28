arquivo_informado <- function(path) {
  is.character(path) && length(path) == 1L && !is.na(path) && nzchar(path)
}

validar_arquivo <- function(path, nome) {
  if (!arquivo_informado(path)) {
    stop(nome, " nao foi informado.", call. = FALSE)
  }
  if (!file.exists(path)) {
    stop(nome, " nao encontrado: ", path, call. = FALSE)
  }
  invisible(path)
}

#' Validar colunas obrigatorias
#' @param data Tabela a verificar.
#' @param colunas Nomes das colunas obrigatorias.
#' @param nome Nome da entrada nas mensagens.
#' @return A tabela, invisivelmente.
#' @export
validar_colunas <- function(data, colunas, nome) {
  faltantes <- setdiff(colunas, names(data))
  if (length(faltantes) > 0) {
    stop(nome, " nao contem as colunas obrigatorias: ",
         paste(faltantes, collapse = ", "), call. = FALSE)
  }
  invisible(data)
}

#' Ler tabela local preservando identificadores
#' @param path Caminho CSV, Parquet, RDS, Rda ou RData.
#' @param nome Nome da entrada nas mensagens.
#' @return Objeto lido; CSV preserva nu_notific, id_bairro e nm_bairro como texto.
#' @export
ler_tabela_local <- function(path, nome = "arquivo") {
  validar_arquivo(path, nome)
  ext <- tolower(tools::file_ext(path))
  ler_rdata <- function() {
    env <- new.env(parent = emptyenv())
    objs <- load(path, envir = env)
    if (length(objs) != 1) {
      stop(nome, " deve conter exatamente um objeto quando usado como RData/Rda.", call. = FALSE)
    }
    env[[objs]]
  }
  switch(
    ext,
    # identificadores lidos como texto: preserva zeros a esquerda e sufixos de renotificacao
    csv = {
      cabecalho <- names(readr::read_csv(path, n_max = 0, show_col_types = FALSE))
      texto <- intersect(c("nu_notific", "id_bairro", "nm_bairro"), cabecalho)
      tipos <- do.call(readr::cols, stats::setNames(rep(list(readr::col_character()), length(texto)), texto))
      readr::read_csv(path, show_col_types = FALSE, col_types = tipos)
    },
    parquet = {
      if (!requireNamespace("arrow", quietly = TRUE)) {
        stop("Instale o pacote arrow para ler arquivos .parquet.", call. = FALSE)
      }
      arrow::read_parquet(path)
    },
    rds = readRDS(path),
    rda = ler_rdata(),
    rdata = ler_rdata(),
    stop("Extensao nao suportada para ", nome, ": ", ext, call. = FALSE)
  )
}

ler_referencia_local <- function(path) {
  validar_arquivo(path, "referencia_path")
  ext <- tolower(tools::file_ext(path))
  if (ext == "rds") {
    return(readRDS(path))
  }
  if (ext %in% c("rda", "rdata")) {
    env <- new.env(parent = emptyenv())
    objs <- load(path, envir = env)
    if ("ref_submunicipal" %in% objs) return(env$ref_submunicipal)
    if ("df_intra_ref" %in% objs) return(env$df_intra_ref)
    if (length(objs) == 1) return(env[[objs]])
    stop("referencia_path em RData deve conter ref_submunicipal, df_intra_ref, ou apenas um objeto.",
         call. = FALSE)
  }
  ler_tabela_local(path, "referencia_path")
}

#' Preparar referencia espacial e populacional
#' @param path Caminho da referencia local.
#' @param col_bairro,col_bairro_id,col_distrito,col_pop,col_geometry Colunas da referencia.
#' @return Objeto sf com nomes canonicos, populacao e identificadores validados.
#' @export
preparar_referencia <- function(path, col_bairro, col_bairro_id, col_distrito,
                                col_pop, col_geometry) {
  ref <- ler_referencia_local(path)
  validar_colunas(ref, c(col_bairro, col_bairro_id, col_distrito, col_pop, col_geometry),
                  "referencia_submunicipal")
  if (!inherits(ref, "sf")) {
    ref <- sf::st_as_sf(ref, sf_column_name = col_geometry)
  } else if (attr(ref, "sf_column") != col_geometry) {
    ref <- sf::st_set_geometry(ref, col_geometry)
  }
  ref <- ref %>%
    rename(
      nome_bairr = all_of(col_bairro),
      id_bairro = all_of(col_bairro_id),
      distrito = all_of(col_distrito),
      pop = all_of(col_pop),
      geometry = all_of(col_geometry)
    ) %>%
    sf::st_set_geometry("geometry") %>%
    mutate(
      nome_bairr = normalizar_bairro(nome_bairr),
      id_bairro = as.character(id_bairro),
      distrito = as.character(distrito),
      pop = as.numeric(pop)
    )
  if (anyNA(ref$id_bairro) || any(!nzchar(ref$id_bairro)) || anyDuplicated(ref$id_bairro) ||
      anyNA(ref$nome_bairr) || any(!nzchar(ref$nome_bairr)) || anyDuplicated(ref$nome_bairr)) {
    stop("Referencia deve ter IDs e nomes normalizados unicos e preenchidos.", call. = FALSE)
  }
  if (anyNA(ref$distrito) || any(!nzchar(ref$distrito)) ||
      any(!is.finite(ref$pop) | ref$pop <= 0)) stop("Distrito e populacao invalidos na referencia.", call. = FALSE)
  if (any(sf::st_is_empty(ref)) || !all(sf::st_is_valid(ref))) stop("Geometrias invalidas na referencia.", call. = FALSE)
  ref
}

#' Preparar historico municipal de alerta
#' @param path_unico Arquivo unico com coluna arbo.
#' @param path_dengue,path_chikungunya Arquivos separados opcionais por agravo.
#' @return Tabela ordenada. casos_est e receptivo ausentes recebem NA, nunca casos observados.
#' @export
preparar_historico_alerta <- function(path_unico = "", path_dengue = "", path_chikungunya = "") {
  obrigatorias <- c("SE", "casos", "p_inc100k", "nivel", "Rt", "tempmin")
  if (arquivo_informado(path_unico)) {
    historico <- ler_tabela_local(path_unico, "historico_alerta")
    validar_colunas(historico, c(obrigatorias, "arbo"), "historico_alerta")
  } else {
    entradas <- list(dengue = path_dengue, chikon = path_chikungunya)
    entradas <- entradas[vapply(entradas, arquivo_informado, logical(1))]
    if (!length(entradas)) stop("Informe ao menos um historico de alerta.", call. = FALSE)
    historico <- dplyr::bind_rows(lapply(names(entradas), function(arbo) {
      x <- ler_tabela_local(entradas[[arbo]], paste0("historico_", arbo))
      validar_colunas(x, obrigatorias, paste0("historico_", arbo))
      x$arbo <- arbo
      x
    }))
  }
  historico$arbo <- normalizar_arbo(historico$arbo)
  for (col in intersect(c(obrigatorias, "casos_est", "receptivo", "lwr", "upr"), names(historico))) {
    original <- historico[[col]]
    valor <- suppressWarnings(as.numeric(as.character(original)))
    if (any(!is.na(original) & is.na(valor)) || any(!is.na(valor) & !is.finite(valor))) {
      stop("Valores numericos invalidos em ", col, call. = FALSE)
    }
    historico[[col]] <- valor
  }
  historico$SE <- validar_semanas_epi(historico$SE)
  if (anyNA(historico$casos) || any(historico$casos < 0) ||
      anyNA(historico$p_inc100k) || any(historico$p_inc100k < 0) ||
      any(!is.na(historico$nivel) & !historico$nivel %in% 1:4)) {
    stop("Casos, incidencia ou nivel invalidos no historico.", call. = FALSE)
  }
  if (anyDuplicated(historico[c("arbo", "SE")])) stop("Historico possui semanas duplicadas por agravo.", call. = FALSE)
  for (col in c("casos_est", "receptivo")) if (!col %in% names(historico)) historico[[col]] <- NA_real_
  dplyr::arrange(historico, .data$arbo, .data$SE)
}

normalizar_arbo <- function(x) {
  x <- tolower(trimws(as.character(x)))
  x[x == "chikungunya"] <- "chikon"
  if (anyNA(x) || any(!x %in% c("dengue", "chikon"))) stop("Agravo invalido: use dengue ou chikon/chikungunya.", call. = FALSE)
  x
}
