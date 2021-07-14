#'@title Baixa as proposições de um painel
#'@description Recebe uma url da API do Painel e um painel específico e
#'retorna as proposições pertencentes ao painel.
#'@param url URL da API do Painel. Ex: 'https://api.leggo.org.br/'
#'@param painel String correspondente ao painel de interesse. Ex: 'socioambiental'
#'@return Dataframe no formato: <id_leggo, interesse, sigla_camara, sigla_senado>
fetch_proposicoes_by_painel <- function(url, painel) {
  print(paste0("Baixando as proposições do painel ", painel, "..."))
  data <-
    RCurl::getURL(paste0(url, "proposicoes/?interesse=", painel)) %>%
    jsonlite::fromJSON() %>%
    mutate(interesse = painel) %>% 
    select(id_leggo, interesse, sigla_camara, sigla_senado) 
  print(paste0("Foram retornadas ", nrow(data), " proposições."))
  return(data)
}


#'@title Baixa a pressão para uma proposição em um painel
#'@description Recebe uma url da API do Painel, um painel e proposição específicos,
#'um intervalo de datas e retorna as pressões por semana para a proposição.
#'@param url URL da API do Painel. Ex: 'https://api.leggo.org.br/'
#'@param painel String correspondente ao painel de interesse. Ex: 'socioambiental'
#'@param id_leggo ID da proposição na plataforma do Painel.
#'@param data_inicial Data inicial do intervalo no formato AAAA-MM-DD.
#'@param data_final Data final do intervalo no formato AAAA-MM-DD.
#'@return Dataframe no formato: <id_leggo, interesse, periodo = date, user_count, sum_interactions, popularity>
fetch_pressao_by_id_leggo <-
  function (url,
            painel,
            id_leggo,
            data_inicial,
            data_final) {
    print(
      paste0(
        "Baixando dados de pressão para a proposição ", id_leggo, " entre ", data_inicial, " e ", data_final, "..."
      )
    )
    data <-
      RCurl::getURL(
        paste0(
          url, 
          "pressao/",
          id_leggo,
          "/?interesse=",
          painel,
          "&data_inicio=",
          data_inicial,
          "&data_fim=",
          data_final
        )
      ) %>%
      jsonlite::fromJSON()
    
    if (length(data) == 0) {
      return(tribble())
    }
    
    data <- data %>%
      mutate(id_leggo = id_leggo,
             interesse = painel) %>%
      select(id_leggo,
             interesse,
             periodo = date,
             user_count,
             sum_interactions,
             popularity)
    
    
    return(data)
  }

#'@title Baixa a pressão para todas as proposições de um painel
#'@description Recebe uma url da API do Painel, um painel específico, 
#'um intervalo de datas e retorna a pressão por semana para as proposições do painel.
#'@param url URL da API do Painel. Ex: 'https://api.leggo.org.br/'
#'@param painel String correspondente ao painel de interesse. Ex: 'socioambiental'
#'@param data_inicial Data inicial do intervalo no formato AAAA-MM-DD.
#'@param data_final Data final do intervalo no formato AAAA-MM-DD.
#'@param proposicoes Dataframe de proposições que possuem pelo menos o id_leggo. 
#'Ex: retorno da função fetch_proposicoes_by_painel()
#'@return Dataframe no formato: <id_leggo, interesse, periodo, temperatura_recente>
fetch_pressao_by_painel <-
  function(url,
           painel = 'socioambiental',
           data_inicial = Sys.Date() - 90,
           data_final = Sys.Date(),
           proposicoes) {
    pressao <-
      map_df(
        proposicoes$id_leggo,
        ~ fetch_pressao_by_id_leggo(url, painel, .x, data_inicial, data_final)
      )
    
    return(pressao)
  }

