# Configuracao unica para entrada, grafico e criterios do AlertTools.
variaveis_modelo_climatico <- function() {
  list(Af = "temp_min", Aw = "umid_max", Awi = "umid_min",
       AsAw = c("temp_min", "umid_max"), AsAwi = c("temp_min", "umid_min"))
}

avisar_clima_legado <- function(coluna = "tempmin", limiar = 18) {
  warning("Configuracao climatica ausente: usando o legado Af, ", coluna, " e ",
          limiar, " graus Celsius. Confirme os parametros oficiais do municipio.", call. = FALSE)
}

normalizar_config_climatica <- function(config_climatica = NULL) {
  if (is.null(config_climatica)) {
    avisar_clima_legado()
    config_climatica <- list(modelo = "Af", colunas = list(temp_min = "tempmin"),
                             limiares = list(temp_min = 18))
  }
  cfg <- config_climatica
  campos <- c("modelo", "colunas", "limiares")
  if (!is.list(cfg) || is.null(names(cfg)) || anyDuplicated(names(cfg)) ||
      !setequal(names(cfg), campos)) {
    stop("config_climatica deve conter somente modelo, colunas e limiares.", call. = FALSE)
  }
  if (!is.character(cfg$modelo) || length(cfg$modelo) != 1L || is.na(cfg$modelo) ||
      !cfg$modelo %in% names(variaveis_modelo_climatico())) {
    stop("Modelo climatico invalido: use Af, Aw, Awi, AsAw ou AsAwi.", call. = FALSE)
  }
  variaveis <- variaveis_modelo_climatico()[[cfg$modelo]]
  for (campo in c("colunas", "limiares")) {
    x <- cfg[[campo]]
    if ((!is.list(x) && !is.atomic(x)) || is.null(names(x)) || anyDuplicated(names(x)) ||
        !setequal(names(x), variaveis)) {
      stop(campo, " deve nomear exatamente as variaveis do modelo ", cfg$modelo,
           ": ", paste(variaveis, collapse = ", "), call. = FALSE)
    }
    cfg[[campo]] <- as.list(x[variaveis])
  }
  reservadas <- c("SE", "arbo", "casos", "p_inc100k", "nivel", "Rt", "casos_est",
                  "receptivo", "lwr", "upr", "clima_favoravel")
  for (v in variaveis) {
    validar_escalar_texto(cfg$colunas[[v]], paste0("colunas$", v))
    if (cfg$colunas[[v]] %in% reservadas) stop("Coluna climatica reservada: ", cfg$colunas[[v]], call. = FALSE)
    limiar <- cfg$limiares[[v]]
    if (!is.numeric(limiar) || length(limiar) != 1L || !is.finite(limiar)) {
      stop("Limiar climatico deve ser numerico escalar finito: ", v, call. = FALSE)
    }
    if (startsWith(v, "umid") && (limiar < 0 || limiar > 100)) {
      stop("Limiar de umidade deve estar entre 0 e 100: ", v, call. = FALSE)
    }
  }
  if (anyDuplicated(unlist(cfg$colunas))) stop("Variaveis climaticas devem usar colunas distintas.", call. = FALSE)
  cfg
}

preparar_colunas_climaticas <- function(dados, cfg) {
  validar_colunas(dados, unlist(cfg$colunas, use.names = FALSE), "historico climatico")
  # Le todas as origens antes de criar os nomes canonicos, sem sobrescrever fontes.
  valores <- lapply(names(cfg$colunas), function(v) {
    original <- dados[[cfg$colunas[[v]]]]
    x <- suppressWarnings(as.numeric(as.character(original)))
    if (any(!is.na(original) & is.na(x)) || any(!is.na(x) & !is.finite(x))) {
      stop("Valores climaticos invalidos em ", cfg$colunas[[v]], call. = FALSE)
    }
    if (startsWith(v, "umid") && any(x < 0 | x > 100, na.rm = TRUE)) {
      stop("Umidade deve estar entre 0 e 100 em ", cfg$colunas[[v]], call. = FALSE)
    }
    if (v %in% names(dados) && cfg$colunas[[v]] != v &&
        !isTRUE(all.equal(dados[[v]], x, check.attributes = FALSE))) {
      stop("Coluna climatica canonica conflitante: ", v, call. = FALSE)
    }
    x
  })
  names(valores) <- names(cfg$colunas)
  for (v in names(valores)) dados[[v]] <- valores[[v]]
  condicoes <- lapply(names(valores), function(v) valores[[v]] > cfg$limiares[[v]])
  favoravel <- Reduce(`&`, condicoes)
  # Mesmo com outra condicao falsa, uma variavel ausente significa indisponibilidade.
  faltantes <- Reduce(`|`, lapply(valores, is.na))
  favoravel[faltantes] <- NA
  dados$clima_favoravel <- favoravel
  dados
}

rotulos_climaticos <- function() {
  c(temp_min = "Temperatura minima (\u00b0C)", umid_max = "Umidade maxima (%)",
    umid_min = "Umidade minima (%)")
}

descrever_config_climatica <- function(cfg) {
  paste(vapply(names(cfg$limiares), function(v) {
    paste(rotulos_climaticos()[[v]], ">", format(cfg$limiares[[v]], trim = TRUE))
  }, character(1)), collapse = " e ")
}

parametros_climaticos_alerta <- function(cfg) {
  vars <- names(cfg$limiares)
  list(codmodelo = cfg$modelo, varcli = vars[1], clicrit = cfg$limiares[[1]],
       varcli2 = if (length(vars) == 2L) vars[2] else NA_character_,
       clicrit2 = if (length(vars) == 2L) cfg$limiares[[2]] else NA_real_)
}
