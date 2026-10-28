#' Criar QMD agnostico de municipio para boletim submunicipal
#'
#' Gera um arquivo `.qmd` parametrizado a partir de um template interno do
#' pacote. O QMD gerado nao acessa APIs internas: ele espera dados locais
#' informados pelo usuario nos caminhos de entrada.
#'
#' @param municipio_nome Nome do municipio.
#' @param uf Sigla da unidade federativa.
#' @param municipio_geocodigo Codigo IBGE do municipio.
#' @param ano Ano de referencia do boletim.
#' @param populacao Populacao municipal usada em indicadores municipais.
#' @param output_qmd Caminho do arquivo `.qmd` a ser criado.
#' @param notificacoes_path Caminho para notificacoes locais (`.csv`,
#'   `.parquet`, `.rds`, `.rda` ou `.RData`).
#' @param historico_alerta_path Caminho opcional para historico de alerta em
#'   arquivo unico contendo a coluna `arbo`.
#' @param historico_alerta_dengue_path Caminho para historico de alerta de
#'   dengue, quando `historico_alerta_path` nao for usado.
#' @param historico_alerta_chikungunya_path Caminho para historico de alerta de
#'   chikungunya, quando `historico_alerta_path` nao for usado.
#' @param referencia_path Caminho para referencia espacial/populacional local.
#' @param col_bairro_ref Nome da coluna de bairro/unidade local na referencia.
#' @param col_bairro_id_ref Nome da coluna de identificador local na referencia.
#' @param col_distrito_ref Nome da coluna de agrupamento submunicipal.
#' @param col_pop_ref Nome da coluna de populacao na referencia.
#' @param col_geometry_ref Nome da coluna de geometria na referencia.
#' @param overwrite Se `TRUE`, sobrescreve `output_qmd` quando ele ja existe.
#' @param render Se `TRUE`, renderiza o QMD apos cria-lo usando o pacote
#'   `quarto`, quando disponivel, ou o binario `quarto` no sistema.
#'
#' @return Caminho normalizado do arquivo QMD criado, invisivelmente.
#' @export
criar_qmd_boletim <- function(
    municipio_nome,
    uf,
    municipio_geocodigo,
    ano,
    populacao,
    output_qmd,
    notificacoes_path,
    historico_alerta_path = "",
    historico_alerta_dengue_path = "",
    historico_alerta_chikungunya_path = "",
    referencia_path,
    col_bairro_ref = "nome_bairr",
    col_bairro_id_ref = "id_bairro",
    col_distrito_ref = "distrito",
    col_pop_ref = "pop",
    col_geometry_ref = "geometry",
    overwrite = FALSE,
    render = FALSE) {

  validar_escalar_texto(municipio_nome, "municipio_nome")
  validar_escalar_texto(uf, "uf")
  validar_escalar_texto(output_qmd, "output_qmd")
  validar_escalar_texto(notificacoes_path, "notificacoes_path")
  validar_escalar_texto(referencia_path, "referencia_path")

  if (!is.numeric(municipio_geocodigo) || length(municipio_geocodigo) != 1) {
    stop("municipio_geocodigo deve ser numerico e escalar.", call. = FALSE)
  }

  if (!is.numeric(ano) || length(ano) != 1) {
    stop("ano deve ser numerico e escalar.", call. = FALSE)
  }

  if (!is.numeric(populacao) || length(populacao) != 1) {
    stop("populacao deve ser numerica e escalar.", call. = FALSE)
  }

  if (!nzchar(historico_alerta_path) &&
      (!nzchar(historico_alerta_dengue_path) ||
       !nzchar(historico_alerta_chikungunya_path))) {
    stop(
      paste(
        "Informe historico_alerta_path com arquivo unico contendo arbo,",
        "ou informe historico_alerta_dengue_path e",
        "historico_alerta_chikungunya_path."
      ),
      call. = FALSE
    )
  }

  if (file.exists(output_qmd) && !isTRUE(overwrite)) {
    stop("output_qmd ja existe. Use overwrite = TRUE para sobrescrever.", call. = FALSE)
  }

  template_path <- encontrar_template_boletim()
  template <- paste(readLines(template_path, warn = FALSE), collapse = "\n")

  valores <- list(
    municipio_nome = municipio_nome,
    uf = uf,
    municipio_geocodigo = as.character(municipio_geocodigo),
    ano = as.character(ano),
    populacao = as.character(populacao),
    notificacoes_path = normalizar_path_qmd(notificacoes_path),
    historico_alerta_path = normalizar_path_qmd(historico_alerta_path),
    historico_alerta_dengue_path = normalizar_path_qmd(historico_alerta_dengue_path),
    historico_alerta_chikungunya_path = normalizar_path_qmd(historico_alerta_chikungunya_path),
    referencia_path = normalizar_path_qmd(referencia_path),
    col_bairro_ref = col_bairro_ref,
    col_bairro_id_ref = col_bairro_id_ref,
    col_distrito_ref = col_distrito_ref,
    col_pop_ref = col_pop_ref,
    col_geometry_ref = col_geometry_ref
  )

  qmd <- substituir_placeholders(template, valores)

  output_dir <- dirname(output_qmd)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  writeLines(qmd, output_qmd, useBytes = TRUE)
  output_qmd <- normalizePath(output_qmd, mustWork = TRUE)

  if (isTRUE(render)) {
    renderizar_qmd(output_qmd)
  }

  invisible(output_qmd)
}

validar_escalar_texto <- function(x, nome) {
  if (!is.character(x) || length(x) != 1 || !nzchar(x)) {
    stop(nome, " deve ser texto escalar nao vazio.", call. = FALSE)
  }

  invisible(x)
}

encontrar_template_boletim <- function() {
  template <- system.file(
    "templates",
    "boletim_municipal_completo.qmd",
    package = "infodengesubmunicipal"
  )

  if (nzchar(template) && file.exists(template)) {
    return(template)
  }

  template <- file.path(
    getwd(),
    "inst",
    "templates",
    "boletim_municipal_completo.qmd"
  )

  if (file.exists(template)) {
    return(template)
  }

  stop("Template boletim_municipal_completo.qmd nao encontrado.", call. = FALSE)
}

normalizar_path_qmd <- function(path) {
  if (is.null(path) || length(path) != 1 || !nzchar(path)) {
    return("")
  }

  gsub("\\\\", "/", path)
}

substituir_placeholders <- function(template, valores) {
  for (nome in names(valores)) {
    template <- gsub(
      paste0("{{", nome, "}}"),
      valores[[nome]],
      template,
      fixed = TRUE
    )
  }

  template
}

encontrar_quarto <- function() {
  bin <- Sys.which("quarto")
  if (!nzchar(bin) && requireNamespace("quarto", quietly = TRUE)) {
    bin <- tryCatch(quarto::quarto_path(), error = function(e) "")
  }
  if (is.null(bin) || !length(bin)) return("")
  unname(bin)
}

renderizar_qmd <- function(path, quarto_bin = encontrar_quarto()) {
  path <- normalizePath(path, mustWork = TRUE)
  if (length(quarto_bin) != 1L || is.na(quarto_bin) || !nzchar(quarto_bin)) {
    stop("Quarto nao encontrado. Instale em https://quarto.org/docs/get-started/", call. = FALSE)
  }
  status <- system2(quarto_bin, c("render", shQuote(path)))
  if (status != 0L) {
    log <- sub("[.]qmd$", ".log", path, ignore.case = TRUE)
    if (file.exists(log)) {
      linhas <- readLines(log, warn = FALSE)
      erros <- grep("^!", linhas)
      indices <- unique(unlist(lapply(erros, function(i) seq.int(i, min(i + 3L, length(linhas))))))
      if (length(indices)) message(paste(linhas[indices], collapse = "\n"))
      stop("A renderizacao falhou (status ", status, "). Consulte ", log, call. = FALSE)
    }
    stop("A renderizacao falhou (status ", status, "). Veja a saida do Quarto acima; nenhum log LaTeX foi produzido.", call. = FALSE)
  }
  invisible(path)
}
