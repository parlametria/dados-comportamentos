library(tidyverse)
library(jsonlite)
library(RCurl)
library(lubridate)
source(here::here("code/utils/utils.R"))

#' @title Recupera autorias parlamentares do Parlametria por interesse/painel
#' @description Retorna as autorias parlamentares detalhadas por interesse/painel.
#' @param url_api  URL da API do Painel.
#' @param interesse Interesse
#' @return Dataframe com dados das autorias por interesse
fetch_autorias_by_interesse <- function(url_api, interesse) {
  print(paste0("Baixando autorias do painel ", interesse, "..."))
  
  autorias <-
    getURI(paste0(url_api, "autorias?interesse=", interesse),
           .encoding = 'latin-1') %>%
    fromJSON() %>% 
    distinct(id_autor, id_documento, .keep_all=T) %>% 
    filter(tipo_documento == "Prop. Original / Apensada") %>% 
    mutate(casa_enum = if_else(casa_autor == "camara", 1, 2)) %>%
    mutate(
      id_autor_parlametria = paste0(casa_enum, id_autor),
      mes = month(data),
      ano = year(data)
    ) %>%
    group_by(id_autor_parlametria, mes, ano) %>%
    summarise(
      quantidade_autorias = n(),
      .groups = 'drop') %>%
    mutate(painel = interesse)
  
  return(autorias)
}

#' @title Recupera autorias parlamentares do Parlametria de todos os 
#' interesse/painéis ativos.
#' @description Retorna as autorias parlamentares detalhadas.
#' @param url_api  URL da API do Painel
#' @return Dataframe com dados das autorias parlamentares
fetch_all_autorias <- function(url_api) {
  # Remove painel desativado
  interesses <- fetch_interesses(url_api)
  
  autorias <- purrr::map_df(interesses$interesse,
                         ~ fetch_autorias_by_interesse(url_api, .x))
  
  return(autorias)
  
}