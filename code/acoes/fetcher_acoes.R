library(tidyverse)
library(jsonlite)
library(RCurl)
library(lubridate)
source(here::here("code/utils/utils.R"))

#' @title Recupera ações parlamentares do Parlametria por interesse/painel
#' @description Retorna as ações parlamentares detalhadas por interesse/painel.
#' @param url_api  URL da API do Painel.
#' @param interesse Interesse
#' @return Dataframe com dados das ações por interesse
fetch_acoes_by_interesse <- function(url_api, interesse) {
  print(paste0("Baixando ações do painel ", interesse, "..."))
  
  acoes <-
    getURI(paste0(url_api, "autorias?interesse=", interesse),
           .encoding = 'latin-1') %>%
    fromJSON() %>%
    distinct(id_autor, id_documento, .keep_all=T) %>% 
    filter(tipo_acao == "Proposição") %>% 
    mutate(casa_enum = if_else(casa_autor == "camara", 1, 2)) %>%
    mutate(
      id_autor_parlametria = paste0(casa_enum, id_autor),
      mes = month(data),
      ano = year(data)
    ) %>%
    group_by(id_autor_parlametria, mes, ano) %>%
    summarise(
      quantidade_documentos = n(),
      soma_peso_documentos = sum(peso_autor_documento),
      .groups = 'drop') %>%
    mutate(painel = interesse)
  
  return(acoes)
}

#' @title Recupera ações parlamentares do Parlametria de todos os 
#' interesse/painéis ativos.
#' @description Retorna as ações parlamentares detalhadas.
#' @param url_api  URL da API do Painel
#' @return Dataframe com dados das ações parlamentares
fetch_all_acoes <- function(url_api) {
  # Remove painel desativado
  interesses <- fetch_interesses(url_api)
  
  acoes <- purrr::map_df(interesses$interesse,
                         ~ fetch_acoes_by_interesse(url_api, .x))
  
  return(acoes)
  
}