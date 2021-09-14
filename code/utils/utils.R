#' @title Padroniza siglas de partidos
#' @description Recebe uma sigla de partido como input e retorna seu valor padronizado
#' @param sigla Sigla do partido
#' @return Dataframe com sigla do partido padronizada
padroniza_sigla <- function(sigla) {
  sigla = toupper(sigla)
  
  sigla_padronizada <- case_when(
    str_detect(tolower(sigla), "ptdob") ~ "AVANTE",
    str_detect(tolower(sigla), "pcdob") ~ "PCdoB",
    str_detect(tolower(sigla), "ptn") ~ "PODEMOS",
    str_detect(tolower(sigla), "pps") ~ "CIDADANIA",
    str_detect(tolower(sigla), "pmdb") ~ "MDB",
    str_detect(tolower(sigla), "patri") ~ "PATRIOTA",
    str_detect(tolower(sigla), "pc do b") ~ "PCdoB",
    str_detect(tolower(sigla), "prb") ~ "REPUBLICANOS",
    tolower(sigla) == "pr" ~ "PL",
    str_detect(sigla, "SOLID.*") ~ "SOLIDARIEDADE",
    str_detect(sigla, "PODE.*") ~ "PODEMOS",
    str_detect(sigla, "GOV.") ~ "GOVERNO",
    str_detect(sigla, "PHS.*") ~ "PHS",
    TRUE ~ sigla
  ) %>%
    stringr::str_replace("REPR.", "") %>% 
    stringr::str_replace_all("[[:punct:]]", "") %>% 
    trimws(which = c("both"))
  
  return(sigla_padronizada)
}

#' @title Recupera interesses do Parlametria
#' @description Retorna os interesses cadastrados no Parlametria
#' @param url_api  URL da API do Painel.
#' @return Dataframe com dados dos interesses
fetch_interesses <- function(url_api = "https://api.leggo.org.br/") {
  interesses <- RCurl::getURI(paste0(url_api, "interesses")) %>%
    jsonlite::fromJSON() %>%
    select(interesse) %>% 
    filter(interesse != "leggo")
  
  return(interesses)
}