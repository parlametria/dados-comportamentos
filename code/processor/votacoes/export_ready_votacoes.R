library(tidyverse)
library(here)
library(stringr)
source(here::here("code/processor/votacoes/processor_votacoes.R"))

if (!require(optparse)) {
  install.packages("optparse")
  suppressWarnings(suppressMessages(library(optparse)))
}

args = commandArgs(trailingOnly = TRUE)

message("LEIA O README deste diretório")
message("Use --help para mais informações\n")

option_list = list(
  make_option(
    c("-v", "--vot"),
    type = "character",
    default = here::here("data/raw/votacoes/votacoes_camara.csv"),
    help = "caminho de votações raw [default= %default]",
    metavar = "character"
  ),
  make_option(
    c("-u", "--votos"),
    type = "character",
    default = here::here("data/raw/votos/votos_camara.csv"),
    help = "caminho de votos raw [default= %default]",
    metavar = "character"
  ),
  make_option(
    c("-o", "--out"),
    type = "character",
    default = here::here("data/ready/votacoes/votacoes_camara.csv"),
    help = "nome do arquivo de saída [default= %default]",
    metavar = "character"
  )
)

opt_parser = OptionParser(option_list = option_list)
opt = parse_args(opt_parser)

save_votacoes <- function(votacoes_raw, votos_raw, saida) {
  message("Preenchendo automaticamente a planilha de votações em Plenário das proposições de Meio Ambiente")
  votacoes <- transform_votacoes(votacoes_raw, votos_raw)
  
  message(paste0("Salvando o resultado em ", saida))
  write_csv(votacoes, saida)
  
  message("Concluído")
}

votacoes_raw <- opt$vot
votos_raw <- opt$votos
saida <- opt$out

if (!interactive()) {
  save_votacoes(votacoes_raw, votos_raw, saida)
}