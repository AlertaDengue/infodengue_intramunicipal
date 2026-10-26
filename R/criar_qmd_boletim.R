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
#' @param limiar_preseason,limiar_epidemico,limiar_posseason Limiares de
#'   incidencia semanal (casos por 100 mil habitantes) do municipio, calculados
#'   pelo InfoDengue a partir da serie historica (MEM).
#' @param nome_unidade_local,nome_unidade_local_plural Nome da unidade local
#'   usado nos textos (ex.: `"bairro"`, `"bairros"`).
#' @param nome_agregacao,nome_agregacao_plural Nome do agrupamento usado nos
#'   textos (ex.: `"distrito"`, `"distritos"`; `"região administrativa"`,
#'   `"regiões administrativas"`).
#' @param limiar_completude Completude minima recomendada (%) das variaveis de
#'   localizacao, mostrada no grafico de completude.
#' @param logo_esquerda,logo_direita Caminhos opcionais para as imagens do
#'   cabecalho. Sao copiadas para a pasta do `.qmd` como `logo1.png` e
#'   `logo2.png`. Sem elas, o cabecalho e gerado sem logos.
#' @param executar_nowcasting Se TRUE, solicita ajuste opcional de nowcasting.
#' @param overwrite Se `TRUE`, sobrescreve `output_qmd` quando ele ja existe.
#' @param render Se `TRUE`, renderiza o QMD apos cria-lo.
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
    limiar_preseason,
    limiar_epidemico,
    limiar_posseason,
    nome_unidade_local = "bairro",
    nome_unidade_local_plural = "bairros",
    nome_agregacao = "distrito",
    nome_agregacao_plural = "distritos",
    limiar_completude = 70,
    logo_esquerda = NULL,
    logo_direita = NULL,
    overwrite = FALSE,
    render = FALSE,
    executar_nowcasting = FALSE) {

  for (nome in c("municipio_nome", "uf", "output_qmd", "notificacoes_path", "referencia_path",
                 "col_bairro_ref", "col_bairro_id_ref", "col_distrito_ref", "col_pop_ref", "col_geometry_ref",
                 "nome_unidade_local", "nome_unidade_local_plural", "nome_agregacao", "nome_agregacao_plural")) {
    validar_escalar_texto(get(nome), nome)
  }
  for (nome in c("municipio_geocodigo", "ano", "populacao", "limiar_preseason", "limiar_epidemico",
                 "limiar_posseason", "limiar_completude")) {
    valor <- get(nome)
    if (!is.numeric(valor) || length(valor) != 1L || !is.finite(valor)) stop(nome, " deve ser numerico escalar finito.", call. = FALSE)
  }
  if (populacao <= 0 || ano != floor(ano) || ano < 1000 || ano > 9999 || municipio_geocodigo <= 0 ||
      municipio_geocodigo != floor(municipio_geocodigo)) stop("Populacao, ano ou geocodigo invalidos.", call. = FALSE)
  if (any(c(limiar_preseason, limiar_epidemico, limiar_posseason) < 0) ||
      limiar_epidemico < max(limiar_preseason, limiar_posseason) ||
      limiar_completude < 0 || limiar_completude > 100) stop("Limiares invalidos: confira incidencia e completude (0 a 100).", call. = FALSE)
  for (nome in c("overwrite", "render", "executar_nowcasting")) {
    x <- get(nome)
    if (!is.logical(x) || length(x) != 1L || is.na(x)) stop(nome, " deve ser TRUE ou FALSE.", call. = FALSE)
  }
  validar_arquivo(notificacoes_path, "notificacoes_path")
  validar_arquivo(referencia_path, "referencia_path")
  for (nome in c("historico_alerta_path", "historico_alerta_dengue_path", "historico_alerta_chikungunya_path")) {
    x <- get(nome)
    if (!is.character(x) || length(x) != 1L || is.na(x)) stop(nome, " deve ser texto escalar.", call. = FALSE)
    if (nzchar(x)) validar_arquivo(x, nome)
  }
  if (!arquivo_informado(historico_alerta_path) && !arquivo_informado(historico_alerta_dengue_path) &&
      !arquivo_informado(historico_alerta_chikungunya_path)) stop("Informe historico_alerta_path ou ao menos um historico por agravo.", call. = FALSE)
  if (!grepl("[.]qmd$", output_qmd, ignore.case = TRUE)) stop("output_qmd deve terminar em .qmd.", call. = FALSE)
  logos <- list(logo1.png = logo_esquerda, logo2.png = logo_direita)
  for (logo in logos) {
    if (!is.null(logo)) {
      validar_arquivo(logo, "logo")
      tryCatch(png::readPNG(logo), error = function(e) stop("Logo deve ser PNG valido: ", logo, call. = FALSE))
    }
  }
  if (file.exists(output_qmd) && !overwrite) stop("output_qmd ja existe. Use overwrite = TRUE.", call. = FALSE)
  template_path <- encontrar_template_boletim()
  template <- paste(readLines(template_path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

  valores <- list(
    municipio_nome = municipio_nome,
    uf = uf,
    municipio_geocodigo = municipio_geocodigo,
    ano = ano,
    populacao = populacao,
    notificacoes_path = normalizar_path_qmd(notificacoes_path),
    historico_alerta_path = normalizar_path_qmd(historico_alerta_path),
    historico_alerta_dengue_path = normalizar_path_qmd(historico_alerta_dengue_path),
    historico_alerta_chikungunya_path = normalizar_path_qmd(historico_alerta_chikungunya_path),
    referencia_path = normalizar_path_qmd(referencia_path),
    col_bairro_ref = col_bairro_ref,
    col_bairro_id_ref = col_bairro_id_ref,
    col_distrito_ref = col_distrito_ref,
    col_pop_ref = col_pop_ref,
    col_geometry_ref = col_geometry_ref,
    limiar_preseason = limiar_preseason,
    limiar_epidemico = limiar_epidemico,
    limiar_posseason = limiar_posseason,
    nome_unidade_local = nome_unidade_local,
    nome_unidade_local_plural = nome_unidade_local_plural,
    nome_agregacao = nome_agregacao,
    nome_agregacao_plural = nome_agregacao_plural,
    limiar_completude = limiar_completude,
    executar_nowcasting = executar_nowcasting,
    logo_esquerda_arquivo = if (is.null(logo_esquerda)) "" else "logo1.png",
    logo_direita_arquivo = if (is.null(logo_direita)) "" else "logo2.png"
  )

  qmd <- substituir_placeholders(template, valores)

  restantes <- unique(regmatches(qmd, gregexpr("\\{\\{[a-z_]+\\}\\}", qmd))[[1]])
  if (length(restantes) > 0) {
    stop("Marcadores sem valor no template: ", paste(restantes, collapse = ", "), call. = FALSE)
  }

  output_dir <- dirname(output_qmd)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  output_dir <- normalizePath(output_dir, mustWork = TRUE)
  output_qmd <- file.path(output_dir, basename(output_qmd))
  stage <- tempfile("boletim-", tmpdir = output_dir)
  dir.create(stage)
  on.exit(unlink(stage, recursive = TRUE), add = TRUE)
  arquivo_qmd <- file.path(stage, basename(output_qmd))
  writeLines(enc2utf8(qmd), arquivo_qmd, useBytes = TRUE)
  arquivos <- stats::setNames(list(arquivo_qmd), output_qmd)
  for (nome in names(logos)) {
    origem <- logos[[nome]]
    if (is.null(origem)) next
    origem <- normalizePath(origem, mustWork = TRUE)
    destino <- file.path(output_dir, nome)
    if (identical(origem, destino)) next
    if (file.exists(destino) && !overwrite) stop("Logo de destino ja existe: ", destino, call. = FALSE)
    if (!file.copy(origem, file.path(stage, nome))) stop("Falha ao preparar logo: ", origem, call. = FALSE)
    arquivos[[destino]] <- file.path(stage, nome)
  }
  backups <- lapply(names(arquivos), function(destino) {
    if (!file.exists(destino)) return(NULL)
    backup <- tempfile(tmpdir = stage)
    if (!file.copy(destino, backup)) stop("Falha ao proteger arquivo existente: ", destino, call. = FALSE)
    backup
  })
  gravados <- integer()
  tryCatch({
    for (i in seq_along(arquivos)) {
      gravados <- c(gravados, i)
      if (!file.copy(arquivos[[i]], names(arquivos)[i], overwrite = TRUE)) stop("Falha ao gravar: ", names(arquivos)[i], call. = FALSE)
    }
  }, error = function(e) {
    for (i in gravados) {
      destino <- names(arquivos)[i]
      if (is.null(backups[[i]])) unlink(destino) else file.copy(backups[[i]], destino, overwrite = TRUE)
    }
    stop(conditionMessage(e), call. = FALSE)
  })
  if (isTRUE(render)) {
    renderizar_qmd(output_qmd)
  }

  invisible(output_qmd)
}

validar_escalar_texto <- function(x, nome) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x)) stop(nome, " deve ser texto escalar nao vazio.", call. = FALSE)
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
  if (is.null(path) || identical(path, "")) return("")
  normalizePath(path, winslash = "/", mustWork = TRUE)
}

substituir_placeholders <- function(template, valores) {
  for (nome in names(valores)) {
    valor <- valores[[nome]]
    substituto <- as.character(jsonlite::toJSON(valor, auto_unbox = TRUE, digits = NA))
    if (is.character(valor)) substituto <- substr(substituto, 2L, nchar(substituto) - 1L)
    template <- paste(strsplit(template, paste0("{{", nome, "}}"), fixed = TRUE)[[1]], collapse = substituto)
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
