library(tidyverse)
library(perfilparlamentar)

#' @title Processa votações sem consenso
#' @description Processa as votações para filtrar quais não há consenso
#' @param votos Dataframe de votos. Devem ter pelo menos 2 colunas: id_votacao e voto.
#' @return Dataframe com votações e as proporções de consenso
#' @examples
#' processa_votacoes_sem_consenso(votos)
processa_votacoes_sem_consenso <-
  function(votos, limite_consenso = 0.9) {
    votacoes_proporcao <- votos %>%
      filter(voto != 0) %>%
      group_by(id_votacao, casa) %>%
      mutate(votos_validos = n()) %>%
      ungroup() %>%
      group_by(id_votacao, casa, voto, votos_validos) %>%
      summarise(contagem = n()) %>%
      ungroup() %>%
      mutate(proporcao = contagem / votos_validos)
    
    votacoes_id <- votacoes_proporcao %>%
      group_by(id_votacao, casa) %>%
      summarise(proporcao_max = max(proporcao)) %>%
      filter(proporcao_max < limite_consenso)
    
    return(votacoes_id)
  }

#' @title Conta votações sem consenso
#' @description Conta quantas votações ocorerram em quais não há consenso
#' @param votos Dataframe de votos. Devem ter pelo menos 3 colunas: id_votacao, casa e voto.
#' @return Dataframe indicando a quantidade de votações sem consenso por casa
#' @examples
#' conta_votacoes_sem_consenso(votos)
#' @export
conta_votacoes_sem_consenso <- function(votos) {
  votacoes_sem_consenso <- processa_votacoes_sem_consenso(votos) %>%
    group_by(casa) %>%
    summarise(num_votacoes = n())
}

#' @title Participou votações
#' @description Analisa se o parlamentar participou em mais de 10 votações
#' @param parlamentares Dataframe de entidades
#' @param votos Dataframe de votos.
#' @param orientacoes Dataframe de orientações
#' @param enumera_orientacao Flag indicando se as orientações
#' precisam ser transformadas em enum.
#' @return Dataframe com id e casa do parlamentar e quantas votações ele participou
#' @examples
#' participou_votacoes(votos, orientacoes, enumera_orientacao)
participou_votacoes <-
  function(parlamentares,
           votos,
           orientacoes,
           enumera_orientacao) {
    parlamentares_info <- get_parlamentares_info(parlamentares)
    votos_orientados <-
      processa_votos_orientados(votos, orientacoes, enumera_orientacao)
    lista_votos_validos <- c(-1, 1, 2, 3)
    
    quantidade_votacoes <- parlamentares_info %>%
      left_join(
        votos_orientados,
        by = c("id_entidade_parlametria" = "id_parlamentar_parlametria", "casa")
      ) %>%
      filter(!is.na(voto)) %>%
      mutate(votou = if_else(voto %in% lista_votos_validos, 1, 0)) %>%
      mutate(num_votacoes = sum(votou)) %>%
      distinct(id_entidade, id_entidade_parlametria, num_votacoes, casa)
    
    return(quantidade_votacoes)
  }

#' @title Processa bancada suficiente
#' @description Processa os parlamentares e filtra aqueles que não bancada
#' suficiente na camara/senado.
#' @return Dataframe com partidos e se sua bancada é suficiente
#' @examples
#' processa_bancada_suficiente()
processa_bancada_suficiente <-
  function(parlamentares,
           minimo_deputados = 5,
           minimo_senadores = 3) {
    partido_atual <- parlamentares %>%
      filter(is_parlamentar == 1, legislatura == 56, em_exercicio == 1) %>%
      group_by(partido, casa) %>%
      summarise(num_parlamentares = n_distinct(id_entidade)) %>%
      ungroup() %>%
      mutate(bancada_suficiente = if_else((casa == "camara" &
                                             num_parlamentares >= minimo_deputados) |
                                            (casa == "senado" &
                                               num_parlamentares >= minimo_senadores),
                                          TRUE,
                                          FALSE
      )) %>%
      select(partido, casa, bancada_suficiente) %>%
      filter(!is.na(partido))
    
    return(partido_atual)
  }

#' @title Get parlamentares info
#' @description Processa os parlamentares e filtra seus dados
#' em sua ultima legislatura
#' @return Dataframe com dados dos parlamentares
#' @examples
#' get_parlamentares_info()
get_parlamentares_info <- function(parlamentares) {
  parlamentares_info <- parlamentares %>%
    mutate(
      id_entidade_parlametria = as.numeric(id_entidade_parlametria),
      id_entidade = as.numeric(id_entidade)
    ) %>%
    group_by(id_entidade) %>%
    mutate(ultima_legislatura = max(legislatura)) %>%
    filter(is_parlamentar == 1, legislatura == ultima_legislatura) %>%
    select(id_entidade,
           id_entidade_parlametria,
           casa,
           nome,
           uf,
           partido_atual = partido)
  
  return(parlamentares_info)
}

#' @title Processa votos orientados
#' @description Processa os votos e suas orientações
#' @param votos Dataframe de votos
#' Os votos devem ter pelo menos 2 colunas: id_votacao e voto.
#' @param orientacoes Dataframe de orientações
#' @param enumera_orientacao Flag indicando se as orientações
#' precisam ser transformadas em enum.
#' @return Dataframe com o que cada parlamentar votou e qual era a orientação do partido
#' @examples
#' processa_votos_orientados(votos, orientacoes, enumera_orientacao)
processa_votos_orientados <-
  function(votos, orientacoes, enumera_orientacao = TRUE) {
    consenso_votacoes <- processa_votacoes_sem_consenso(votos)
    lista_votos_validos <- c(-1, 1, 2, 3)
    
    if (enumera_orientacao) {
      orientacoes <- orientacoes %>%
        enumera_voto()
    }
    
    votos_filtrados <- votos %>%
      filter(id_votacao %in% (consenso_votacoes %>% pull(id_votacao))) %>%
      distinct(id_votacao, id_parlamentar, .keep_all = TRUE) %>%
      mutate(partido = padroniza_sigla(partido))
    
    orientacoes_filtradas <- orientacoes %>%
      filter(id_votacao %in% (consenso_votacoes %>% pull(id_votacao))) %>%
      distinct(id_votacao, partido_bloco, .keep_all = TRUE) %>%
      select(id_votacao, voto = orientacao, partido_bloco) %>%
      select(id_votacao, orientacao = voto, partido_bloco) %>%
      mutate_sigla_bloco() %>%
      mutate(partido = padroniza_sigla(partido))
    
    votos_orientados <- votos_filtrados %>%
      left_join(orientacoes_filtradas,
                by = c("id_votacao" = "id_votacao", "partido")) %>%
      distinct() %>%
      mutate(seguiu = if_else(voto == orientacao &
                                (orientacao %in% lista_votos_validos), 1, 0)) %>%
      mutate(seguiu = if_else(is.na(seguiu), 0, seguiu))
    
    return(votos_orientados)
  }

#' @title Processa num votações parlamantares
#' @description Processa o número total de votações para cada parlamentar
#' @param votos Dataframe de votos
#' Os votos devem ter pelo menos 2 colunas: id_votacao e voto.
#' @param orientacoes Dataframe de orientações
#' @param enumera_orientacao Flag indicando se as orientações
#' precisam ser transformadas em enum.
#' @return Dataframe com o id do parlamentar e quantas vezes ele votou
#' @examples
#' processa_num_votacoes_parlamentares(votos, orientacoes)
processa_num_votacoes_parlamentares <-
  function(votos, orientacoes, enumera_orientacao) {
    votos_orientados <-
      processa_votos_orientados(votos, orientacoes, enumera_orientacao)
    lista_votos_validos <- c(-1, 1, 2, 3)
    
    num_votacoes_parlamentares <- votos_orientados %>%
      mutate(voto_valido = if_else(voto %in% lista_votos_validos, 1, 0)) %>%
      group_by(id_parlamentar, casa) %>%
      summarise(votos_validos = sum(voto_valido)) %>%
      filter(!is.na(id_parlamentar))
  }

#' @title Processa disciplina partidária
#' @description Processa as votações para filtrar quais não há consenso
#' @param parlamentares Dataframe de entidades
#' @param votos Dataframe de votos
#' Os votos devem ter pelo menos 2 colunas: id_votacao e voto.
#' @param orientacoes Dataframe de orientações
#' @param enumera_orientacao Flag indicando se as orientações
#' precisam ser transformadas em enum.
#' @return Dataframe de parlamentares e sua disciplina partidária
#' @examples
#' processa_disciplina_partidaria(parlamentares, votos, orientacoes, enumera_orientacao)
processa_disciplina_partidaria <-
  function(parlamentares,
           votos,
           orientacoes,
           enumera_orientacao = FALSE) {
    bancada_suficiente <- processa_bancada_suficiente(parlamentares)
    parlamentares_info <- get_parlamentares_info(parlamentares)
    lista_votos_validos <- c(-1, 1, 2, 3)
    votos_orientados <-
      processa_votos_orientados(votos, orientacoes, enumera_orientacao)
    .QUANTIDADE_MINIMA_DE_VOTOS_VALIDOS <- 10
    
    disciplina <- votos_orientados %>%
      mutate(ano = lubridate::year(data),
             mes = lubridate::month(data)) %>% 
      mutate(voto_valido = if_else(voto %in% lista_votos_validos, 1, 0)) %>%
      mutate(voto_valido_com_orientacao = if_else(voto_valido == 1 &
                                                    (orientacao %in% lista_votos_validos), 1, 0)) %>%
      mutate(seguiu = if_else(voto_valido_com_orientacao == 1, seguiu, 0)) %>%
      group_by(id_parlamentar, casa, partido, mes, ano) %>%
      summarise(
        votos_validos = sum(voto_valido_com_orientacao),
        num_seguiu = sum(seguiu)
      ) %>%
      ungroup() %>%
      mutate(disciplina = num_seguiu / votos_validos) %>% ## considera apenas os votos válidos com orientação
      mutate(partido = padroniza_sigla(partido)) %>%
      mutate(
        disciplina = if_else(
          votos_validos < .QUANTIDADE_MINIMA_DE_VOTOS_VALIDOS,
          NA_real_,
          disciplina
        )
      )
    
    df <- disciplina %>%
      left_join(
        parlamentares_info %>% select(
          uf,
          nome,
          id_entidade,
          id_entidade_parlametria,
          partido_atual,
          casa
        ),
        by = c("id_parlamentar" = "id_entidade", "casa")
      ) %>%
      left_join(bancada_suficiente, by = c("partido_atual" = "partido", "casa")) %>%
      mutate(partido_atual = padroniza_sigla(partido_atual)) %>%
      filter(!is.na(id_parlamentar)) %>%
      select(
        id_parlamentar,
        id_parlamentar_parlametria = id_entidade_parlametria,
        partido_disciplina = partido,
        partido_atual,
        casa,
        mes,
        ano,
        votos_validos,
        num_seguiu,
        disciplina,
        bancada_suficiente
      ) %>%
      mutate(
        bancada_suficiente = if_else(
          partido_disciplina == partido_atual,
          bancada_suficiente,
          as.logical(NA)
        )
      )
    
    return(df)
  }

#' @title Processa o Disciplina para o Parlametria
#' @description Recupera informações de disciplina partidária
#' para o parlametria usando o pacote perfilparlamentar
#' @param parlamentares_datapath Caminho para o csv de entidades
#' @param votos_datapath Caminho para o csv de votos.
#' @param orientacoes_datapath Caminho para o csv de orientações.
#' @param votacoes_datapath Caminho para o csv de votações.
#' @param data_inicio Data inicial do recorte de tempo.
#' @param data_final Data final do recorte de tempo.
#' @return Dataframe de parlamentares e a disciplina calculada.
#' @example
#' disciplina <- processa_disciplina(parlamentares_datapath, votos_datapath, orientacoes_datapath, votacoes_datapath, data_inicio, data_final)
processa_disciplina <-
  function(parlamentares_datapath,
           votos_datapath,
           orientacoes_datapath,
           votacoes_datapath,
           data_inicio = "2019-02-01",
           data_final = "2022-12-31") {
    votacoes <- read_csv(votacoes_datapath) %>%
      filter(data >= data_inicio, data <= data_final)
    
    votos <- read_csv(votos_datapath) %>%
      filter(id_votacao %in% (votacoes %>% pull(id_votacao))) %>%
      left_join(votacoes %>% select(id_votacao, data), by = 'id_votacao')
    
    orientacoes <- read_csv(orientacoes_datapath) %>%
      filter(id_votacao %in% (votacoes %>% pull(id_votacao)))
    
    parlamentares <- read_csv(parlamentares_datapath)
    
    if (nrow(votos) > 0 && nrow(orientacoes) > 0) {
      disciplina <-
        processa_disciplina_partidaria(parlamentares, votos, orientacoes, FALSE)
      
    } else {
      disciplina <- tibble(
        id_parlamentar = integer(),
        id_parlamentar_parlametria = integer(),
        partido_disciplina = character(),
        partido_atual = character(),
        casa = character(),
        votos_validos = integer(),
        num_seguiu = integer(),
        disciplina = double(),
        bancada_suficiente = logical()
      )
    }
    
    
    return(disciplina)
  }
