library(tidyverse)

#'@title Processa a pressão para uma proposição em um painel
#'@description Recebe um caminho de csv com todos os dados de pressão,
#'um intervalo de datas e retorna as pressões por semana para a proposição.
#'@param pressao_datapath Caminho para o csv de pressão com todos os paineis.
#'@param painel String correspondente ao painel de interesse. Ex: 'socioambiental'
#'@param data_inicial Data inicial do intervalo no formato AAAA-MM-DD.
#'@param data_final Data final do intervalo no formato AAAA-MM-DD.
#'@return Dataframe no formato: <id_leggo, interesse, periodo = date, user_count, sum_interactions, popularity>
fetch_pressao_by_id_leggo <-
  function (pressao_datapath,
            painel,
            id_leggo,
            data_inicial,
            data_final) {
    data <- read_csv(pressao_datapath) %>%
      filter(interesse == painel,
             date >= data_inicial,
             date <= data_final)
    
    if (length(data) == 0) {
      return(tribble())
    }
    
    data <- data %>%
      select(id_leggo,
             interesse,
             periodo = date,
             user_count,
             sum_interactions,
             popularity)
    
    
    return(data)
  }
