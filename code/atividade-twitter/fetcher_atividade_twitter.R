library(tidyverse)
library(jsonlite)
library(RCurl)
library(lubridate)

#' @title Recupera atividade no twitter dos parlamentares para
#' um painel e intervalo de datas específicos.
#' @description Retorna as atividades parlamentares no twitter
#' por mês e ano.
#' @param url_api  URL da API do Leggo Twitter
#' @param interesse Interesse
#' @param data_inicial Data inicial
#' @param data_final Data final
#' @return Dataframe com dados das atividades parlamentares
fetch_atividade_twitter <-
  function(url_api,
           interesse,
           data_inicial = "2019-02-01",
           data_final = Sys.Date()) {
    print(paste0("Baixando atividade no twitter para o painel ", interesse, "..."))
    
    atividade <- getURL(
      paste0(
        url_api,
        "parlamentares/atividade/diaria?interesse=",
        interesse,
        "&data_inicial=",
        data_inicial,
        "&data_final=",
        data_final
      )
    ) %>%
      fromJSON() %>%
      mutate(
        mes = month(created_at),
        ano = year(created_at),
        painel = interesse,
        atividade_twitter = as.numeric(atividade_twitter)
      ) %>%
      group_by(id_parlamentar_parlametria,
               mes,
               ano,
               painel) %>%
      summarise(total_tweets = sum(atividade_twitter),
                .groups = "drop") 
    
    
    return(atividade)
  }

#' @title Recupera atividade no twitter dos parlamentares para
#' todos os painéis com intervalo de datas específico.
#' @description Retorna as atividades parlamentares no twitter
#' por mês e ano.
#' @param url_api  URL da API do Leggo Twitter
#' @param data_inicial Data inicial
#' @param data_final Data final
#' @return Dataframe com dados das atividades parlamentares
fetch_all_atividade_twitter <-
  function(url_api,
           data_inicial = "2019-02-01",
           data_final = Sys.Date()) {
    source(here::here("code/utils/utils.R"))
    
    interesses <- fetch_interesses()
    
    atividade <- purrr::map_df(
      interesses$interesse,
      ~ fetch_atividade_twitter(url_api,
                                .x,
                                data_inicial,
                                data_final)
    )
    
    return(atividade)
  }
