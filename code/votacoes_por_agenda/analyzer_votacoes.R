library(tidyverse)
library(here)
source(here("code/utils/check_packages.R"))
source(here("code/proposicoes/fetcher_proposicoes_camara.R"))
.check_and_load_perfilparlamentar_package()

#' @title Adiciona votações da planilha que não estão no dataframe de votações
#' @description Adiciona as votações faltantes no csv de votações, considerando a planilha
#' de votações relacionadas ao Meio Ambiente em 2019 e 2020.
#' @param votacoes_df Dataframe das votações retornadas pelo pacote perfilparlamentar
#' @param planilha_votacoes_path Caminho do csv contendo as votações preenchidas na planilha
#' @return Dataframe com o merge das votações
merge_votacoes_com_planilha_externa <- function(
  votacoes_df,
  planilha_votacoes_path = NULL) {
  
  if (is.null(planilha_votacoes_path)) {
    source(here::here("code/constants.R"))
    planilha_votacoes_path <- .URL_PLANILHA_VOTACAO_CAMARA
  }
  votacoes_planilha <- read_csv(planilha_votacoes_path, col_types = cols(.default = "c")) %>% 
    anti_join(votacoes_df, by = "id_votacao") %>% 
    select(-c(autor, tema, uri_tramitacao))
  
  if (nrow(votacoes_planilha) > 0) {
    votacoes_planilha_info <- votacoes_planilha %>% 
      mutate(data_prop = map(id_proposicao,
                             perfilparlamentar::fetch_info_proposicao_camara)) %>%
      select(-id_proposicao) %>% 
      unnest(data_prop) %>% 
      select(
        nome_proposicao = nome,
        ementa_proposicao,
        obj_votacao,
        resumo,
        data,
        data_apresentacao_proposicao,
        autor,
        indexacao_proposicao,
        tema,
        uri_tramitacao,
        id_proposicao = id,
        id_votacao,
        descricao_efeitos
      )
  } else {
    votacoes_planilha_info <- tibble(descricao_efeitos = character())
  }
  
  votacoes <- votacoes_df %>% 
    bind_rows(votacoes_planilha_info)
  
  return(votacoes)
}

#' @title Adiciona rótulos já preenchidos previamente na planilha da Câmara
#' @description Adiciona rótulos de orientação preenchidas na planilha para as votações
#' já rotuladas previamente.
#' @param votacoes_df Dataframe de votações a receber rótulos já preenchidos.
#' @return Votações com 'Ambientalismo orienta SIM/NÃO/LIBERADO' adicionado
adiciona_rotulos_existentes_camara <- function(votacoes_df) {
  source(here("code/constants.R"))
  
  votacoes_rotuladas <-
    read_csv(.URL_PLANILHA_VOTACAO_CAMARA, col_types = cols(.default = "c")) 
  
  if (!"descricao_efeitos" %in% names(votacoes_rotuladas)) {
    votacoes_rotuladas$descricao_efeitos <- NA
  }
  
  votacoes_rotuladas <- votacoes_rotuladas %>%
    distinct(id_votacao,
             `Ambientalismo orienta SIM/NÃO/LIBERADO`,
             `Obstrução colabora com a orientação?`,
             descricao_efeitos)
  
  votacoes <- votacoes_rotuladas %>% right_join(votacoes_df, by = c("id_votacao")) %>%
    mutate(descricao_efeitos = if_else(
      is.na(descricao_efeitos.x),
      descricao_efeitos.y,
      descricao_efeitos.x
    )) %>%
    select(c(
      `Ambientalismo orienta SIM/NÃO/LIBERADO`, 
      `Obstrução colabora com a orientação?`,
      names(votacoes_df))) %>% 
    distinct(id_votacao, .keep_all = T)
  
  return(votacoes)
}

#' @title Votações nominais em plenário de Meio Ambiente e Agricultura
#' @description Processa informações de votações em plenário relacionadas a proposições dos temas de Meio Ambiente e Agricultura
#' @return Informações sobre as votações
#' @examples
#' votacoes <- processa_votacoes_camara()
processa_votacoes_camara <- function() {
  ## Marcando quais as proposições tiveram votações nominais em plenário em 2019 e 2020
  proposicoes_votadas <- fetch_proposicoes_votadas_plenario_camara()
  
  proposicoes <- proposicoes_votadas %>% 
    distinct(id)
  
  proposicoes_info <-
    purrr::pmap_dfr(list(proposicoes$id), ~ fetch_info_proposicao_camara(..1)) %>%
    select(
      id_proposicao = id,
      nome_proposicao = nome,
      data_apresentacao_proposicao = data_apresentacao,
      ementa_proposicao = ementa,
      autor,
      indexacao_proposicao = indexacao,
      tema,
      uri_tramitacao
    )
  
  proposicoes_ma <- proposicoes_info %>% 
    filter(str_detect(tolower(tema), "meio ambiente|agricultura|estrutura fundiária")) %>% 
    group_by(id_proposicao) %>% 
    mutate(tema = paste0(tema, collapse = ";"),
              autor = paste0(autor, collapse = ";")) %>% 
    ungroup() %>% 
    distinct() 
  
  votacoes_proposicoes <- tibble(id_proposicao = proposicoes_ma$id_proposicao) %>%
    mutate(data = map(id_proposicao,
                      perfilparlamentar::fetch_votacoes_por_proposicao_camara)) %>%
    select(-id_proposicao) %>% 
    unnest(data) %>% 
    mutate(id_proposicao = as.character(id_proposicao))
  
  votacoes <- votacoes_proposicoes %>%
    left_join(proposicoes_info, by = c("id_proposicao")) %>%
    select(
      nome_proposicao,
      ementa_proposicao,
      obj_votacao,
      resumo,
      data,
      data_apresentacao_proposicao,
      autor,
      indexacao_proposicao,
      tema,
      uri_tramitacao,
      id_proposicao,
      id_votacao
    )
  
  votacoes_alt <- votacoes %>% 
    merge_votacoes_com_planilha_externa() %>% 
    adiciona_rotulos_existentes_camara() 
  
  votos <- purrr::map_df(
    votacoes_alt %>%
      distinct(id_votacao) %>%
      pull(id_votacao),
    ~ fetch_votos_por_votacao_camara(.x)
  ) %>%
    group_by(id_votacao) %>%
    summarise(num_votos = n()) %>%
    filter(num_votos >= 20)
  
  votacoes_alt <- votacoes_alt %>%
    mutate(total_votos = str_extract(tolower(resumo), "total.*") %>%
             str_extract("(\\d)+")) %>%
    mutate(is_nominal = if_else(total_votos > 20 |
                                  id_votacao %in% votos$id_votacao, 1, 0)) %>%
    select(-total_votos)
  
  return(votacoes_alt)
}

#' @title Adiciona rótulos já preenchidos previamente na planilha do Senado
#' @description Adiciona rótulos de orientação preenchidas na planilha para as votações
#' já rotuladas previamente.
#' @param votacoes_df Dataframe de votações a receber rótulos já preenchidos.
#' @return Votações com 'Ambientalismo orienta SIM/NÃO/LIBERADO' adicionado
adiciona_rotulos_existentes_senado <- function(votacoes_df) {
  source(here("code/constants.R"))
  
  votacoes_rotuladas <-
    read_csv(.URL_PLANILHA_VOTACAO_SENADO, col_types = cols(.default = "c")) 
  
  votacoes_rotuladas <- votacoes_rotuladas %>%
    distinct(id_votacao,
             `Ambientalismo orienta SIM/NÃO/LIBERADO`)
  
  votacoes <- votacoes_rotuladas %>% right_join(votacoes_df, by = c("id_votacao")) %>%
    select(c(`Ambientalismo orienta SIM/NÃO/LIBERADO`, names(votacoes_df))) %>% 
    distinct(id_votacao, .keep_all = T)
  
  return(votacoes)
}


#' @title Votações nominais em plenário de Meio Ambiente e Agricultura
#' @description Processa informações de votações em plenário relacionadas a proposições dos temas de Meio Ambiente e Agricultura
#' @return Informações sobre as votações
#' @examples
#' votacoes <- processa_votacoes_senado()
processa_votacoes_senado <- function() {
  
  votacoes_senado <- fetch_proposicoes_votadas_senado(initial_date = "01/02/2019",
                                                      end_date = format(Sys.Date(), "%d/%m/%Y"))
  
  proposicoes <-
    purrr::map_df(
      votacoes_senado %>% 
        distinct(id_proposicao) %>%
        pull(id_proposicao), ~ fetch_info_proposicao_senado(.x)
    )
  
  # Remove proposições do tipo MSF e OFS
  proposicoes_filtradas <- proposicoes %>% 
    filter(!str_detect(tolower(nome), "msf|ofs"))
  
  proposicoes_ma <- proposicoes_filtradas %>% 
    filter(
      str_detect(
        tema,
        "Nao especificado|Meio ambiente|Agricultura, pecuária e abastecimento|Recursos hídricos"
      )
    ) 
  
  votacoes_filtradas <- votacoes_senado %>% 
    inner_join(proposicoes_ma,
               by = c("id_proposicao" = "id")) %>% 
    mutate(cod_sessao = "",
           hora = "") %>% 
    select(id_proposicao,
           id_votacao,
           nome_proposicao = nome,
           ementa_proposicao = ementa,
           obj_votacao = objeto_votacao,
           votacao_secreta,
           resumo = link_votacao,
           tema,
           cod_sessao,
           hora,
           data = datetime,
           data_apresentacao_proposicao = data_apresentacao,
           autor,
           uri_tramitacao)
  
  votos <- purrr::map2_df(
    votacoes_filtradas$id_proposicao,
    votacoes_filtradas$id_votacao,
    ~ fetch_votos_por_proposicao_votacao_senado(.x, .y)
  ) %>%
    group_by(id_votacao) %>%
    summarise(num_votos = n()) %>%
    filter(num_votos >= 20)
  
  votacoes_filtradas <- votacoes_filtradas %>%
    adiciona_rotulos_existentes_senado() %>%
    mutate(is_nominal = if_else(id_votacao %in% votos$id_votacao, 1, 0))
  
  return(votacoes_filtradas)
}
