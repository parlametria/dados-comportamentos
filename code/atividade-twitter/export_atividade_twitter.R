library(tidyverse)
library(futile.logger)
library(here)
source(here::here("code/atividade-twitter/process_atividade_twitter.R"))

.HELP <- "
Usage:
Rscript export_atividade_twitter.R -u <url_api> -i <initial_date> -e <end_date> -o <output_filepath>
url_api: URL da API do Painel
initial_date: Data inicial no formato AAAA-MM-DD
end_date: Data final no formato AAAA-MM-DD
output_filepath: Caminho para exportação dos dados de atividade no twitter
"

#' @title Get arguments from command line option parsing
#' @description Get arguments from command line option parsing
get_args <- function() {
  args = commandArgs(trailingOnly=TRUE)
  
  option_list = list(
    optparse::make_option(c("-u", "--url"),
                          type="character",
                          default="https://leggo-twitter-validacao.herokuapp.com/api/",
                          help=.HELP,
                          metavar="character"),
    optparse::make_option(c("-i", "--initial_date"),
                          type="character",
                          default="2019-02-01",
                          help=.HELP,
                          metavar="character"),
    optparse::make_option(c("-e", "--end_date"),
                          type="character",
                          default=as.character(Sys.Date()),
                          help=.HELP,
                          metavar="character"),
    optparse::make_option(c("-o", "--output_filepath"),
                          type="character",
                          default=here::here("data/ready/atividade_twitter/atividade_twitter.csv"),
                          help=.HELP,
                          metavar="character")
  );
  
  opt_parser <- optparse::OptionParser(option_list = option_list)
  opt <- optparse::parse_args(opt_parser)
  return(opt);
}

args <- get_args()
print(args)

url_api <- args$url
initial_date <- args$initial_date
end_date <- args$end_date
saida <- args$output_filepath

flog.info("Recuperando dados de atividade no twitter dos parlamentares...")
atividade <- process_atividade_twitter(url_api,
                                   initial_date,
                                   end_date)

flog.info("Salvando resultado...")
readr::write_csv(atividade, saida)
flog.info("Salvo!")
