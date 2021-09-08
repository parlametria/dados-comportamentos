library(tidyverse)

source(here::here("code/acoes/fetcher_acoes.R"))

#' @title Recupera ações parlamentares do Parlametria de todos os 
#' interesse/painéis ativos
#' @description Retorna as ações parlamentares detalhadas.
#' @param url_api  URL da API do Painel
#' @return Dataframe com dados das ações parlamentares
process_acoes <- function(url_api) {
  acoes <- fetch_all_acoes(url_api)
  
  acoes_agg <- acoes %>% 
    select(-soma_peso_documentos) %>% 
    spread(painel, quantidade_documentos) %>% 
    mutate_all(~replace_na(., 0))
  
  return(acoes_agg)
}