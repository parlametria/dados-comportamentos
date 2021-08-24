# Módulo de Tweets sobre Proposições monitoradas

Este módulo baixa e salva os dados de tweets sobre proposições e usernames, agregadas por semana para o conjunto de proposições de um painel. Para executá-lo é só executar o script abaixo:

```
Rscript export_tweets.R -u <url_api_painel> -p <painel> -i <data_inicial> -f <data_final> -e <export_filepath>
```

onde:

- **url_api_painel**: URL da API do Painel. O valor default é "https://api.leggo.org.br/";
- **painel**: Nome do painel de interesse. O painel default é "socioambiental";
- **data_inicial**: Data para marcar o início do recorte de tempo, no formato `AAAA-MM-DD`. A data inicial default será "2019-01-01".
- **data_final**: Data para marcar o final do recorte de tempo, no formato `AAAA-MM-DD`. A data final default será a data atual;
- **export_filepath:** Caminho para exportação dos dados de pressão. O caminho default é `data/ready/tweets_proposicoes/tweets_proposicoes_socioambiental.csv`.
