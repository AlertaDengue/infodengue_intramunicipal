#' Gerar mapas semanais de incidencia epidemiologica
#'
#' Versao em portugues de `generate_maps_novo()`.
#'
#' @param dados Objeto `sf` com dados epidemiologicos.
#' @param semanas_para_plotar Vetor de semanas epidemiologicas a plotar.
#' @param intervalo_limites Limites da escala de cores.
#' @param coluna_valor Nome da coluna com o valor mapeado.
#' @param arbovirus Arbovirus filtrado.
#' @param coluna_geometria Nome da coluna de geometria.
#' @param limites Objeto `sf` opcional com limites adicionais.
#' @param area Coluna opcional de agrupamento de linhas em `limites`.
#' @param dados_alocados Data frame opcional com casos alocados.
#' @param dados_totais Data frame opcional com casos totais.
#'
#' @return Lista de objetos `ggplot`.
#' @export
gerar_mapas <- function(dados, semanas_para_plotar, intervalo_limites = NULL,
                        coluna_valor = "p_inc100k", arbovirus,
                        coluna_geometria = "geometry", limites = NULL,
                        area = NULL, dados_alocados = NULL,
                        dados_totais = NULL) {
  generate_maps_novo(
    data = dados,
    weeks_2_plot = semanas_para_plotar,
    lim_range = intervalo_limites,
    value_col = coluna_valor,
    arbo = arbovirus,
    geom_col = coluna_geometria,
    shape = limites,
    area = area,
    allocated_data = dados_alocados,
    total_data = dados_totais
  )
}

#' Gerar mapas semanais sem depender de globais
#'
#' Versao em portugues de `generate_maps_novo()`.
#'
#' @inheritParams gerar_mapas
#'
#' @return Lista de objetos `ggplot`.
#' @export
gerar_mapas_novo <- function(dados, semanas_para_plotar, intervalo_limites = NULL,
                             coluna_valor = "p_inc100k", arbovirus,
                             coluna_geometria = "geometry", limites = NULL,
                             area = NULL, dados_alocados = NULL,
                             dados_totais = NULL) {
  gerar_mapas(
    dados = dados,
    semanas_para_plotar = semanas_para_plotar,
    intervalo_limites = intervalo_limites,
    coluna_valor = coluna_valor,
    arbovirus = arbovirus,
    coluna_geometria = coluna_geometria,
    limites = limites,
    area = area,
    dados_alocados = dados_alocados,
    dados_totais = dados_totais
  )
}

#' Criar painel de mapas semanais com legenda compartilhada
#'
#' Versao em portugues de `create_map_panel()`.
#'
#' @param lista_graficos Lista de objetos `ggplot`.
#' @param titulo_legenda Titulo da legenda de cores do mapa.
#' @param numero_colunas Numero opcional de colunas.
#'
#' @return Objeto `ggplot` combinado.
#' @export
criar_painel_mapas <- function(lista_graficos,
                               titulo_legenda = "Incidencia (100.000 pessoas)",
                               numero_colunas = NULL) {
  create_map_panel(
    plots_list = lista_graficos,
    legend_title = titulo_legenda,
    ncol = numero_colunas
  )
}

#' Criar grafico de incidencia epidemiologica com nowcasting
#'
#' Versao em portugues de `create_incidence_plot()`.
#'
#' @param dados_nowcasting Data frame contendo estimativas de nowcasting.
#' @param dados_observados Data frame contendo os dados observados.
#' @param titulo Titulo opcional do grafico.
#' @param nome_distrito Nome opcional do distrito ou regiao analisada.
#' @param semana_epidemiologica Semana epidemiologica final da serie.
#' @param limite_y Valor maximo do eixo Y.
#' @param incluir_zoom Se `TRUE`, adiciona painel de zoom.
#' @param populacao Populacao usada para conversao de incidencia.
#' @param converter_para_incidencia Se `TRUE`, converte casos absolutos.
#'
#' @return Objeto `ggplot`.
#' @export
criar_grafico_incidencia <- function(dados_nowcasting, dados_observados,
                                     titulo = NULL, nome_distrito = NULL,
                                     semana_epidemiologica = NULL,
                                     limite_y = NULL, incluir_zoom = FALSE,
                                     populacao = NULL,
                                     converter_para_incidencia = FALSE) {
  create_incidence_plot(
    nowcast_data = dados_nowcasting,
    observed_data = dados_observados,
    title_suffix = titulo,
    distrito_nome = nome_distrito,
    SE = semana_epidemiologica,
    ylim_max = limite_y,
    include_zoom = incluir_zoom,
    pop = populacao,
    convert_to_incidence = converter_para_incidencia
  )
}

#' Criar grafico de incidencia sem depender de globais
#'
#' Versao em portugues de `create_incidence_plot_novo()`.
#'
#' @param dados_nowcasting Data frame contendo estimativas de nowcasting.
#' @param dados_observados Data frame contendo os dados observados.
#' @param semana_limite Ultima semana epidemiologica considerada.
#' @param quebras_1ano Vetor com as quebras do eixo X.
#' @param limiar_epidemico Limiar epidemico usado no grafico.
#' @param titulo Titulo opcional do grafico.
#' @param nome_distrito Nome opcional do distrito ou regiao analisada.
#' @param limite_y Valor maximo do eixo Y.
#' @param incluir_zoom Se `TRUE`, adiciona painel de zoom.
#' @param populacao Populacao usada para conversao de incidencia.
#' @param converter_para_incidencia Se `TRUE`, converte casos absolutos.
#'
#' @return Objeto `ggplot`.
#' @export
criar_grafico_incidencia_novo <- function(dados_nowcasting, dados_observados,
                                          semana_limite, quebras_1ano,
                                          limiar_epidemico, titulo = NULL,
                                          nome_distrito = NULL,
                                          limite_y = NULL,
                                          incluir_zoom = FALSE,
                                          populacao = NULL,
                                          converter_para_incidencia = FALSE) {
  create_incidence_plot_novo(
    nowcast_data = dados_nowcasting,
    observed_data = dados_observados,
    weeks_limit = semana_limite,
    breaks_1ano = quebras_1ano,
    limiar_epidemico = limiar_epidemico,
    title_suffix = titulo,
    distrito_nome = nome_distrito,
    ylim_max = limite_y,
    include_zoom = incluir_zoom,
    pop = populacao,
    convert_to_incidence = converter_para_incidencia
  )
}

#' Criar graficos da serie temporal do Rt
#'
#' Versao em portugues de `create_rt_plot()`.
#'
#' @param dados_api Data frame contendo os dados do Rt.
#' @param semana_limite Ultima semana epidemiologica considerada.
#' @param titulo Titulo do grafico.
#' @param facetar_por Coluna opcional para facetar os graficos.
#' @param limite_inferior Coluna opcional com limite inferior do intervalo.
#' @param limite_superior Coluna opcional com limite superior do intervalo.
#' @param coluna_semana Nome da coluna de semana epidemiologica.
#'
#' @return Lista com grafico combinado e graficos individuais.
#' @export
criar_grafico_rt <- function(dados_api, semana_limite, titulo,
                             facetar_por = NULL, limite_inferior = NULL,
                             limite_superior = NULL, coluna_semana = NULL) {
  create_rt_plot(
    api_data = dados_api,
    weeks_limit = semana_limite,
    title_suffix = titulo,
    facet_by = facetar_por,
    lwr = limite_inferior,
    upr = limite_superior,
    sem_not = coluna_semana
  )
}

#' Criar graficos de Rt sem depender de globais
#'
#' Versao em portugues de `create_rt_plot_novo()`.
#'
#' @param dados_api Data frame contendo os dados do Rt.
#' @param semana_limite Ultima semana epidemiologica considerada.
#' @param titulo Titulo do grafico.
#' @param quebras_1ano Vetor com as quebras do eixo X.
#' @param facetar_por Coluna opcional para facetar os graficos.
#' @param limite_inferior Coluna opcional com limite inferior do intervalo.
#' @param limite_superior Coluna opcional com limite superior do intervalo.
#' @param coluna_semana Nome da coluna de semana epidemiologica.
#'
#' @return Lista com grafico combinado e graficos individuais.
#' @export
criar_grafico_rt_novo <- function(dados_api, semana_limite, titulo,
                                  quebras_1ano, facetar_por = NULL,
                                  limite_inferior = NULL,
                                  limite_superior = NULL,
                                  coluna_semana = "sem_not") {
  create_rt_plot_novo(
    api_data = dados_api,
    weeks_limit = semana_limite,
    title_suffix = titulo,
    breaks_1ano = quebras_1ano,
    facet_by = facetar_por,
    lwr = limite_inferior,
    upr = limite_superior,
    sem_not = coluna_semana
  )
}

#' Criar grafico de receptividade climatica e temperatura minima
#'
#' Versao em portugues de `create_receptivity_plot()`.
#'
#' @param dados_api Data frame contendo os dados climaticos.
#' @param semana_limite Ultima semana epidemiologica considerada.
#'
#' @return Objeto `ggplot`.
#' @export
criar_grafico_receptividade <- function(dados_api, semana_limite) {
  create_receptivity_plot(
    api_data = dados_api,
    weeks_limit = semana_limite
  )
}

#' Criar grafico de receptividade sem depender de globais
#'
#' Versao em portugues de `create_receptivity_plot_novo()`.
#'
#' @param dados_api Data frame contendo os dados climaticos.
#' @param semana_limite Ultima semana epidemiologica considerada.
#' @param quebras_1ano Vetor com as quebras do eixo X.
#' @param limiar_temperatura Limiar de temperatura favoravel.
#' @param coluna_semana Nome da coluna de semana epidemiologica.
#' @param coluna_temperatura Nome da coluna de temperatura minima.
#'
#' @return Objeto `ggplot`.
#' @export
criar_grafico_receptividade_novo <- function(dados_api, semana_limite,
                                             quebras_1ano,
                                             limiar_temperatura = 18,
                                             coluna_semana = "SE",
                                             coluna_temperatura = "tempmin") {
  create_receptivity_plot_novo(
    api_data = dados_api,
    weeks_limit = semana_limite,
    breaks_1ano = quebras_1ano,
    limiar_temp = limiar_temperatura,
    se_col = coluna_semana,
    temp_col = coluna_temperatura
  )
}
