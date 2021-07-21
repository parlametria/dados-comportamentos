.add_coluna_orientacao_ma_camara <- function(votacoes_df, votos_df) {
  source(here::here("code/proposicoes/fetcher_proposicoes_camara.R"))
  coordenador_ma <-
    fetch_coordenador_frente_parlamentar_camara() %>%
    pull(id)
  
  votos_coordenador_ma <- votos_df %>%
    filter(id_parlamentar == coordenador_ma) %>%
    select(id_votacao, voto_coordenador_frente_ambientalista = voto)
  
  votacoes_com_orientacao <- votacoes_df %>%
    left_join(votos_coordenador_ma, by = "id_votacao")
  
  return(votacoes_com_orientacao)
}

.resume_votos <- function(votos) {
  votos %>%
    mutate(
      orientacao_ma = stringr::str_to_title(orientacao_ma),
      voto = stringr::str_to_title(voto),
      apoiou = .apoiou(voto, orientacao_ma, significado_obstrucao)
    )  %>%
    summarise(
      votos_capturados = sum(!is.na(id_parlamentar)),
      votos_favoraveis = sum(apoiou == "apoio"),
      votos_contra = sum(apoiou == "contra"),
      votos_indef = sum(apoiou == "indefinido"),
      apoio = votos_favoraveis / (votos_favoraveis + votos_contra),
      votos_sim = sum(voto == "Sim"),
      votos_nao = sum(voto == "Não"),
      votos_obstrucao = sum(voto == "Obstrução"),
      votos_sim_nao = votos_sim + votos_nao,
      votos_outros = sum(!is.na(voto) &
                           !(voto %in% c(
                             "Sim", "Não", "Obstrução"
                           ))),
      .groups = "drop"
    )
}

.apoiou = function(voto,
                   orientacao_ma,
                   significado_obstrucao) {
  case_when(
    !(voto %in% c("Sim", "Não", "Obstrução")) ~ "indefinido",
    voto %in% c("Sim", "Não") &
      voto == orientacao_ma ~ "apoio",
    voto == "Obstrução" &
      significado_obstrucao == orientacao_ma ~ "apoio",
    TRUE ~ "contra"
  )
}


#' Transforma votações rotuladas em arquivo sobre as votações (e não votos).
#' @param rotuladas_file Votações rotuladas raw.
#' @return Df ready com as votações
#'
transform_votacoes <-
  function(votacoes_datapath = here::here("data/raw/votacoes/votacoes_camara.csv"),
           votos_datapath = here::here("data/raw/votos/votos_camara.csv")) {
    votos <- read_csv(votos_datapath, col_types = cols(.default = "c"))
    
    votacoes = read_csv(
      here::here(votacoes_datapath),
      col_types = cols(.default = col_character(),
                       data = col_datetime(format = ""))
    ) %>%
      rename(orientacao_ma = `Ambientalismo orienta SIM/NÃO/LIBERADO`,
             obstrucao_colabora = `Obstrução colabora com a orientação?`) %>%
      mutate(orientacao_ma = str_to_title(orientacao_ma))
    
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
      .add_coluna_orientacao_ma_camara(votos) %>%
      mutate(orientacao_ma = if_else(
        is.na(orientacao_ma),
        voto_coordenador_frente_ambientalista,
        orientacao_ma
      ))
    
    votos <- votos %>%
      group_by(id_votacao) %>%
      summarise(significado_obstrucao = if_else(sum(voto == "Sim") > sum(voto == "Não"),
                                                "Não",
                                                "Sim"))
    
    votacoes_a_preencher_alt = votacoes_a_preencher %>%
      left_join(votos, by = "id_votacao") %>%
      mutate(
        obstrucao_colabora = case_when(
          significado_obstrucao == orientacao_ma ~ TRUE,
          str_detect(tolower(orientacao_ma), "obstrução") ~ TRUE,
          significado_obstrucao != orientacao_ma &
          str_detect(tolower(orientacao_ma), "liberado") ~ NA,
          TRUE ~ FALSE)
      ) %>%
      rename(
        `Ambientalismo orienta SIM/NÃO/LIBERADO` = orientacao_ma,
        `Obstrução colabora com a orientação?` = obstrucao_colabora
      )
    
    votacoes <- bind_rows(votacoes_preenchidas,
                          votacoes_a_preencher_alt)
    
    return(votacoes)
  }
