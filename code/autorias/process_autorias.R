library(tidyverse)

source(here::here("code/autorias/fetcher_autorias.R"))

#' @title Recupera autorias parlamentares do Parlametria de todos os 
#' interesse/painéis ativos
#' @description Retorna as autorias parlamentares detalhadas.
#' @param url_api  URL da API do Painel
#' @return Dataframe com dados das autorias parlamentares
process_autorias <- function(url_api) {
  autorias <- fetch_all_autorias(url_api)
  
  autorias_agg <- autorias %>% 
    spread(painel, quantidade_autorias) %>% 
    tidyr::complete(mes, ano, id_autor_parlametria,
                    fill = list(pandemia = 0)) %>% 
    mutate_all(~replace_na(., 0))
  
  return(autorias_agg)
}