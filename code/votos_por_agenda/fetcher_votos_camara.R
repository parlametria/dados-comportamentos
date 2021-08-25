source(here::here("code/utils/check_packages.R"))
.check_and_load_perfilparlamentar_package()

#' @title Recupera dados dos votos para um conjunto de votações.
#' @description Recebe um caminho para o dataframe de votações e retorna todos os
#' votos relacionados.
#' @param votacoes_datapath Caminho para o csv de votações da Camara
#' @return Dataframe com os votos.
fetch_votos_camara <- function(
  votacoes_datapath = here::here("data/raw/votacoes/votacoes_camara.csv")) {
  library(tidyverse)  
  
  votacoes <- read_csv(votacoes_datapath, col_types=cols(.default = "c")) %>% 
    rename(orientacao_ma = `Ambientalismo orienta SIM/NÃO/LIBERADO`) %>% 
    filter(is.na(orientacao_ma) | !str_detect(tolower(orientacao_ma), 'fora do tema')) %>% 
    distinct(id_votacao)
  
  
  votos <- purrr::map_df(votacoes$id_votacao, 
                         ~ fetch_votos_por_votacao_camara(.x))
  
  return(votos)
}