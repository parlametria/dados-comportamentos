# Sumário dos Dados

Os dados salvos neste diretório são gerados pelos scripts localizados na pasta `code/`. Inicialmente os dados são divididos em dois diretórios:

- `raw/`: Destino dos dados que ainda sofrerão mais uma camada de processamento;
- `ready/`: Destino dos dados que estão prontos para uso.


### Diretório raw/

Contém os dados intermediários de votos e votações, somente com as informações vindas das APIs da Câmara e do Senado.

- `votacoes/`: Dados com as informações das votações de plenário na Câmara e no Senado, com algumas linhas da Orientação do Meio Ambiente preenchidas (manualmente por André em relatórios passados).

- `votos/`: Dados com as informações dos votos dos parlamentares nas votações acima tanto na Câmara quanto no Senado.

### Diretório ready/

Contém os dados já processados e prontos para serem utilizados.

- `pressao/`: Contém os dados de pressão do Parlametria considerando o n° de usuários que tweetaram sobre uma proposição e o engajamento total por semana desde 01/01/2019 para as proposições do painel Socioambiental.

- `proposicoes_apresentadas_ma/`: Contém dados das proposições sobre Meio Ambiente que foram apresentadas da Câmara e no Senado a partir de 2019.

- `proposicoes_parlametria/`: Contém o mapeamento de id_leggo (id do Parlametria para as proposiçõẽs) com demais informações, como nome formal, ementa, casa de origem, autor, etc.

- `temperatura/`: Possui dados de temperatura por semana para o conjunto de proposições do painel Socioambiental desde 01/01/2019.

- `tweets_proposicoes/`: Contém dados de tweets sobre proposições monitoradas do painel Socioambiental (considerando a citação explícita do nome formal da proposição no tweet). A informação é agregada por proposição, username e semana.

- `votacoes/`: Contém os dados de votações nominais e em plenário sobre Meio Ambiente considerando o voto do Líder da Frente Parlamentar Ambientalista em cada casa e calculando se o voto Obstrução colaborava com o voto do Meio Ambiente.