library(tidyverse)
library(here)

.add_coluna_orientacao_ma_camara <- function(votacoes_df, votos_df, casa = "camara") {
  source(here::here("code/proposicoes/fetcher_proposicoes_camara.R"))
  if (casa == "camara") {
    coordenador_ma <- 204530 #ID Rodrigo Agostinho
    # fetch_coordenador_frente_parlamentar_camara() %>%
    # pull(id)
  } else {
    coordenador_ma <- 5953 #ID Fabiano Contarato
  }

  votos_coordenador_ma <- votos_df %>%
    filter(id_parlamentar == coordenador_ma) %>%
    select(id_votacao, voto_coordenador_frente_ambientalista = voto)
  
  votacoes_com_orientacao <- votacoes_df %>%
    left_join(votos_coordenador_ma, by = "id_votacao")
  
  return(votacoes_com_orientacao)
}

#' Transforma votações rotuladas em arquivo sobre as votações (e não votos).
#' @param rotuladas_file Votações rotuladas raw.
#' @return Df ready com as votações
#'
transform_votacoes <-
  function(votacoes_datapath = here::here("data/raw/votacoes/votacoes_camara.csv"),
           votos_datapath = here::here("data/raw/votos/votos_camara.csv"),
           casa = "camara") {
    votos <- read_csv(votos_datapath, col_types = cols(.default = "c"))
    
    votacoes = read_csv(
      here::here(votacoes_datapath),
      col_types = cols(.default = col_character(),
                       data = col_datetime(format = "")))
    
    if (!"Obstrução colabora com a orientação?" %in% names(votacoes)) {
      votacoes$`Obstrução colabora com a orientação?` <- NA
    }
    
    votacoes <- votacoes %>%
      rename(orientacao_ma = `Ambientalismo orienta SIM/NÃO/LIBERADO`,
             obstrucao_colabora = `Obstrução colabora com a orientação?`) %>%
      mutate(orientacao_ma = str_to_title(orientacao_ma)) %>% 
      .add_coluna_orientacao_ma_camara(votos, casa)
    
    votacoes_preenchidas <- votacoes %>%
      filter(
        !is.na(orientacao_ma) &
          !is.na(obstrucao_colabora) |
          is.na(obstrucao_colabora) &
          str_detect(tolower(orientacao_ma), "fora do tema")
      )
    
    votacoes_a_preencher <- votacoes %>%
      filter(is.na(orientacao_ma) |
               (
                 is.na(obstrucao_colabora) &
                   !str_detect(tolower(orientacao_ma), "fora do tema")
               )) %>%
      mutate(orientacao_ma = if_else(
        is.na(orientacao_ma),
        voto_coordenador_frente_ambientalista,
        orientacao_ma
      ))
    
    if (nrow(votacoes_a_preencher) > 0) {
      votos <- votos %>%
        group_by(id_votacao) %>%
        summarise(
          significado_obstrucao = if_else(
            sum(voto == "Sim") > sum(voto == "Não"),
            "Não",
            "Sim")
        )
      
      votacoes_a_preencher = votacoes_a_preencher %>%
        left_join(votos, by = "id_votacao") %>%
        mutate(
          obstrucao_colabora = case_when(
            significado_obstrucao == orientacao_ma ~ "Sim",
            str_detect(tolower(orientacao_ma), "obstrução") ~ "Sim",
            significado_obstrucao != orientacao_ma &
              str_detect(tolower(orientacao_ma), "liberado") ~ NA_character_,
            is.na(significado_obstrucao) | is.na(orientacao_ma) ~ NA_character_,
            TRUE ~ "Não")
        )
    } else {
      votacoes <- votacoes_preenchidas
    }

    
    if (nrow(votacoes_preenchidas) > 0 && nrow(votacoes_a_preencher) > 0) {
      votacoes <- bind_rows(votacoes_preenchidas,
                            votacoes_a_preencher)
    } else if (nrow(votacoes_a_preencher) > 0) {
      votacoes <- votacoes_a_preencher
    } else {
      votacoes <- votacoes_preenchidas
    }
    
    votacoes <- votacoes %>% 
      rename(
        `Ambientalismo orienta SIM/NÃO/LIBERADO` = orientacao_ma,
        `Obstrução colabora com a orientação?` = obstrucao_colabora
      )
    
    return(votacoes)
  }
