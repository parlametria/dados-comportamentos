library(tidyverse)
source(here::here("code/atividade-twitter/fetcher_atividade_twitter.R"))

#' @title Recupera atividade no twitter dos parlamentares para
#' todos os painéis com intervalo de datas específico.
#' @description Retorna as atividades parlamentares no twitter
#' por mês e ano, totalmente completos.
#' @param url_api  URL da API do Leggo Twitter
#' @param data_inicial Data inicial
#' @param data_final Data final
#' @return Dataframe com dados das atividades parlamentares
process_atividade_twitter <-
  function(url_api, data_inicial, data_final) {
    atividade <- fetch_all_atividade_twitter(url_api,
                                             data_inicial,
                                             data_final)
    
    atividade_alt <- atividade %>%
      tidyr::complete(mes,
                      ano,
                      painel,
                      id_parlamentar_parlametria,
                      fill = list(total_tweets = 0)) %>%
      filter(ano != 2019 | (ano == 2019 & mes > 1)) %>% 
      spread(painel, total_tweets)
    
    return(atividade_alt)
  }