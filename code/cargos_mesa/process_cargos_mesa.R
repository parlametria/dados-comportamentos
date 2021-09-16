library(tidyverse)
#' @title Captura informações de deputados e senadores integrantes da Mesa na Câmara dos deputados
#' para um conjunto de legislaturas
#' @description Com base na API da Câmara dos Deputados e Senado Federal,
#' captura informações dos parlamentares integrantes da Mesa.
#' O histórico de cargos de mesa está disponível apenas para
#' a Câmara.
#' @param legislaturas Lista com as legislaturas de interesse.
#' @return Dataframe contendo histórico de cargos na Mesa da Câmara
#' e do Senado.
process_cargos_mesa <- function(legislaturas = seq(51, 56)) {
  source(here::here("code/cargos_mesa/fetcher_cargos_mesa.R"))
  
  cargos_camara <-
    fetch_cargos_mesa_camara_all_legislaturas(legislaturas) %>%
    mutate(
      casa = "camara",
      id = as.character(id),
      id_parlamentar_parlametria = paste0(1, id)
    )
  
  cargos_senado <- fetch_cargos_mesa_senado() %>%
    mutate(casa = "senado",
           id_parlamentar_parlametria = paste0(2, id))
  
  cargos_mesa <- bind_rows(cargos_camara,
                           cargos_senado)
  
  cargos_mesa_alt <- cargos_mesa %>%
    select(id_parlamentar_parlametria,
           legislatura,
           casa,
           cargo,
           data_inicio,
           data_fim)
  
  return(cargos_mesa_alt)
}
