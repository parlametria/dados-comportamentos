library(tidyverse)
library(futile.logger)
source(here::here("code/cargos_mesa/process_cargos_mesa.R"))

.HELP <- "
Usage:
Rscript export_cargos_mesa.R -l <legislaturas> -e <export_filepath>
legislaturas: Lista de legislaturas de interesse. Default: 51 a 56.
export_filepath: Caminho para exportação dos dados de disciplina
"

#' @title Get arguments from command line option parsing
#' @description Get arguments from command line option parsing
get_args <- function() {
  args = commandArgs(trailingOnly=TRUE)
  
  option_list = list(
    optparse::make_option(c("-l", "--legs"),
                          type="integer",
                          default=56,
                          help=.HELP),
    optparse::make_option(c("-e", "--export_filepath"),
                          type="character",
                          default=here::here("data/ready/cargos_mesa/cargos_mesa.csv"),
                          help=.HELP,
                          metavar="character")
  );
  
  opt_parser <- optparse::OptionParser(option_list = option_list)
  opt <- optparse::parse_args(opt_parser)
  return(opt);
}

args <- get_args()
print(args)

legislaturas <- args$legs
saida <- args$export_filepath

flog.info("Obtendo dados de cargos de mesa...")
cargos <- process_cargos_mesa(legislaturas)
flog.info("Salvando dados...")
readr::write_csv(cargos, saida)
flog.info("Salvo!")
