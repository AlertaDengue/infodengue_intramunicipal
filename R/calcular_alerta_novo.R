#' Filtrar dados de uma unidade geográfica
#'
#' Filtra o conjunto de dados epidemiológicos para uma unidade geográfica
#' específica e ordena as observações pela semana epidemiológica.
#'
#' @param data Data frame contendo os dados epidemiológicos.
#' @param coluna_id String com o nome da coluna que identifica a unidade
#' geográfica.
#' @param id Valor do identificador da unidade geográfica.
#'
#' @return Data frame filtrado para a unidade geográfica e ordenado por
#' `sem_not`.
#'
#' @examples
#' \dontrun{
#' filtrar_unidade(dados, "id_bairro", 101)
#' }
#'
#' @export
filtrar_unidade <- function(data, coluna_id, id) {

  data |>
    dplyr::filter(.data[[coluna_id]] == id) |>
    dplyr::arrange(.data$sem_not)

}


#' Calcular número reprodutivo efetivo (Rt)
#'
#' Aplica o modelo de estimativa do número reprodutivo efetivo (Rt)
#' utilizando a função `AlertTools::Rt()`.
#'
#' @param data Data frame contendo os dados epidemiológicos.
#' @param gtdist Distribuição do tempo de geração.
#' @param meangt Média do tempo de geração.
#' @param sdgt Desvio padrão do tempo de geração.
#'
#' @return Data frame com estimativas de Rt adicionadas.
#'
#' @examples
#' \dontrun{
#' calcular_rt(dados_bairro)
#' }
#'
#' @export
calcular_rt <- function(data, gtdist = "normal", meangt = 3, sdgt = 1) {

  AlertTools::Rt(
    data,
    count = "casos",
    gtdist = gtdist,
    meangt = meangt,
    sdgt = sdgt
  )

}


#' Classificar níveis de alerta epidemiológico
#'
#' Classifica os níveis de alerta epidemiológico utilizando o modelo
#' definido no objeto `params` e a função `AlertTools::fouralert()`.
#'
#' @param data Data frame contendo os dados epidemiológicos com Rt
#' previamente calculado.
#' @param params Lista de parâmetros utilizados no modelo de alerta.
#' @param criteria_fn Funcao que constroi os criterios; padrao AlertTools::setCriteria.
#'
#' @return Data frame com duas novas colunas:
#' \itemize{
#'   \item `nivel` — nível de alerta epidemiológico
#'   \item `receptivo` — indicador de receptividade do sistema
#' }
#'
#' @examples
#' \dontrun{
#' classificar_alerta(dados_rt, params)
#' }
#'
#' @export
classificar_alerta <- function(data, params, criteria_fn = AlertTools::setCriteria) {
  criteria <- construir_criteria_alerta(
    params = params,
    criteria_fn = criteria_fn
  )

  resultado <- AlertTools::fouralert(
    data,
    crit = criteria
  )

  data |>
    dplyr::mutate(
      nivel = resultado$indices$level,
      receptivo = resultado$indices$cytrue
    )

}


#' Calcular alerta epidemiológico para uma unidade geográfica
#'
#' Executa o pipeline completo de cálculo de alerta epidemiológico
#' para uma unidade geográfica específica.
#'
#' O fluxo inclui:
#' \enumerate{
#'   \item Filtragem da unidade geográfica
#'   \item Estimativa do número reprodutivo efetivo (Rt)
#'   \item Classificação do nível de alerta
#' }
#'
#' @param id Identificador da unidade geográfica.
#' @param data Data frame contendo os dados epidemiológicos.
#' @param coluna_id Nome da coluna de identificação geográfica.
#' @param params Lista de parâmetros do modelo de alerta.
#' @param gtdist Distribuição do tempo de geração.
#' @param meangt Média do tempo de geração.
#' @param sdgt Desvio padrão do tempo de geração.
#' @param criteria_fn Funcao que constroi os criterios; padrao AlertTools::setCriteria.
#'
#' @return Data frame com níveis de alerta para a unidade geográfica.
#'
#' @examples
#' \dontrun{
#' calcular_alerta_novo(
#'   id = 101,
#'   data = dados,
#'   coluna_id = "id_bairro",
#'   params = params_modelo
#' )
#' }
#'
#' @export
calcular_alerta_novo <- function(
    id,
    data,
    coluna_id,
    params,
    gtdist = "normal",
    meangt = 3,
    sdgt = 1,
    criteria_fn = AlertTools::setCriteria
) {

  data |>
    filtrar_unidade(coluna_id, id) |>
    calcular_rt(gtdist, meangt, sdgt) |>
    classificar_alerta(params, criteria_fn = criteria_fn)

}


#' Calcular alertas epidemiológicos para todas as unidades de uma cidade
#'
#' Executa o cálculo de alerta epidemiológico para todas as unidades
#' geográficas presentes em um dataset (por exemplo, bairros ou distritos).
#'
#' @param data Data frame contendo os dados epidemiológicos.
#' @param coluna_id Nome da coluna de identificação geográfica.
#' @param params Lista de parâmetros do modelo de alerta.
#' @param gtdist Distribuição do tempo de geração.
#' @param meangt Média do tempo de geração.
#' @param sdgt Desvio padrão do tempo de geração.
#' @param criteria_fn Funcao que constroi os criterios; padrao AlertTools::setCriteria.
#'
#' @return Data frame contendo os níveis de alerta para todas as unidades
#' geográficas.
#'
#' @examples
#' \dontrun{
#' calcular_alerta_cidade(
#'   data = dados_bairros,
#'   coluna_id = "id_bairro",
#'   params = params_modelo
#' )
#' }
#'
#' @export
calcular_alerta_cidade <- function(
    data,
    coluna_id,
    params,
    gtdist = "normal",
    meangt = 3,
    sdgt = 1,
    criteria_fn = AlertTools::setCriteria
) {

  data |>
    dplyr::distinct(.data[[coluna_id]]) |>
    dplyr::pull() |>
    purrr::map_dfr(
      calcular_alerta_novo,
      data = data,
      coluna_id = coluna_id,
      params = params,
      gtdist = gtdist,
      meangt = meangt,
      sdgt = sdgt,
      criteria_fn = criteria_fn
    )

}
