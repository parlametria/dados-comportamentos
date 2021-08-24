#'@title Instala e carrega bibliotecas necessárias
#'@description Recebe uma lista de pacotes, checa os que precisam ser instalados e 
#'carrega todos no workspace
#'@param packages_list Vetor com a lista de pacotes. Ex: c('tidyvese', 'RCurl')
.install_and_load_libraries <- function(packages_list) {
  new_packages <-
    packages_list[!(packages_list %in% installed.packages()[, "Package"])]
  if (length(new_packages))
    install.packages(new_packages)
  lapply(packages_list, require, character.only = TRUE)
}

.install_and_load_libraries(c("tidyverse", "RCurl", "jsonlite", "here", "optparse"))
source(here::here("code/temperatura/fetch_temperatura.R"))

.HELP <- "
Usage:
Rscript export_temperatura -u <url_api_painel> -p <painel> -i <data_inicial> -f <data_final> -e <export_filepath>
url_api_painel: URL da API do Painel
painel: Nome do painel de interesse
data_inicial: Data para marcar o início do recorte de tempo
data_final: Data para marcar o final do recorte de tempo
export_filepath: Caminho para exportação dos dados de temperatura
"

#' @title Get arguments from command line option parsing
#' @description Get arguments from command line option parsing
get_args <- function() {
  args = commandArgs(trailingOnly=TRUE)
  
  option_list = list(
    optparse::make_option(c("-u", "--url_api_painel"),
                          type="character",
                          default="https://api.leggo.org.br/",
                          help=.HELP,
                          metavar="character"),
    optparse::make_option(c("-p", "--nome_painel"),
                          type="character",
                          default="socioambiental",
                          help=.HELP,
                          metavar="character"),
    optparse::make_option(c("-i", "--data_inicial"),
                          type="character",
                          default=NULL,
                          help=.HELP,
                          metavar="character"),
    optparse::make_option(c("-f", "--data_final"),
                          type="character",
                          default=NULL,
                          help=.HELP,
                          metavar="character"),
    optparse::make_option(c("-e", "--export_filepath"),
                          type="character",
                          default=here::here("data/ready/temperatura/temperatura.csv"),
                          help=.HELP,
                          metavar="character")
  );
  
  opt_parser <- optparse::OptionParser(option_list = option_list)
  opt <- optparse::parse_args(opt_parser)
  return(opt);
}

args <- get_args()

url <- args$url_api_painel
painel <- args$nome_painel
data_inicial <- args$data_inicial
data_final <- args$data_final
saida <- args$export_filepath

if (is.null(data_final)) {
  data_final <- Sys.Date()
}

if (is.null(data_inicial)) {
  data_inicial <- data_final - 90
}

print(data_inicial)
proposicoes <-
  fetch_proposicoes_by_painel(url, painel)

temperaturas <-
  fetch_historico_temperatura_by_painel(url, painel, data_inicial, data_final, proposicoes)

write_csv(temperaturas, here::here(saida))

print("Concluído!")