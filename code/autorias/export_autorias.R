library(tidyverse)
library(futile.logger)
library(here)
source(here::here("code/autorias/process_autorias.R"))

.HELP <- "
Usage:
Rscript export_autorias.R -u <url_api> -o <output_filepath>
url_api: URL da API do Painel
output_filepath: Caminho para exportação dos dados de autorias parlamentares
"

#' @title Get arguments from command line option parsing
#' @description Get arguments from command line option parsing
get_args <- function() {
  args = commandArgs(trailingOnly=TRUE)
  
  option_list = list(
    optparse::make_option(c("-u", "--url"),
                          type="character",
                          default="https://api.leggo.org.br/",
                          help=.HELP,
                          metavar="character"),
    optparse::make_option(c("-o", "--output_filepath"),
                          type="character",
                          default=here::here("data/ready/autorias/autorias.csv"),
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
saida <- args$output_filepath

flog.info("Recuperando dados de autorias parlamentares...")
autorias <- process_autorias(url_api)

flog.info("Salvando resultado...")
readr::write_csv(autorias, saida)
flog.info("Salvo!")
