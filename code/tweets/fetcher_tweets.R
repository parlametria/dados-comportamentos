library(tidyverse)
library(stringr)

#'@title Baixa a informação de tweets proposições em um painel
#'@description Recebe uma url da API do Painel, um painel e proposição específicos,
#'um intervalo de datas e retorna os tweets por semana para a proposição.
#'@param url URL da API do Painel. Ex: 'https://api.leggo.org.br/'
#'@param painel String correspondente ao painel de interesse. Ex: 'socioambiental'
#'@param data_inicial Data inicial do intervalo no formato AAAA-MM-DD.
#'@param data_final Data final do intervalo no formato AAAA-MM-DD.
fetch_tweets <-
  function(url,
           painel,
           data_inicial = "2019-01-01",
           data_final = Sys.Date()) {
    
    source(here::here("code/pressao/fetch_pressao.R"))
    tweets <- RCurl::getURL(
      str_glue(
        "https://leggo-twitter.herokuapp.com/api/proposicoes?data_inicial={data_inicial}&data_final={data_final}"
      )
    ) %>%
      jsonlite::fromJSON()
    
    proposicoes <- fetch_proposicoes_by_painel(url, painel)
    
    tweeets_proposicoes <- tweets %>% 
      inner_join(proposicoes, by = c("id_proposicao_leggo"="id_leggo"))
    
    return(tweeets_proposicoes)
  }
