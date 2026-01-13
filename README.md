# Protheus-dev

Ambiente de desenvolvimento totalmente integrado, usando Docker.

## Como usar

Fazer o backup desse repositorio com um nome qualquer

```sh
# fazer o download dos artefatos
bash tools/setup.sh

# gerar o docker-compose para os artefatos
bash tools/generate.sh

# informar qual license server sera utilizado
export LICENSE_SERVER=licensedev.engpro.totvs.com.br
export LICENSE_PORT=8850

# iniciar o ambiente
docker-compose up -d --build

# entrar no container do banco para criar banco inicial
#Se caso esteja usando o postgres:
docker-compose exec postgres16 bash /local/tools/postgres_create_database.sh
#Se caso esteja usando o mssql (verifique o nome do servico no docker-compose.yml, ex: mssql2022):
docker-compose exec mssql2022 bash /local/tools/mssql_create_database.sh
#Se caso esteja usando o oracle:
docker-compose exec oracle19 bash /local/tools/oracle_create_database.sh

# caso queira restaurar o banco de dados da base congelada
#Se caso esteja usando o postgres:
docker-compose exec postgres16 bash /local/tools/postgres_pgrestore.sh
#Se caso esteja usando o mssql (verifique o nome do servico no docker-compose.yml):
docker-compose exec mssql2022 bash /local/tools/mssql_restore_database.sh
#Se caso esteja usando o oracle:
docker-compose exec oracle19 bash /local/tools/oracle_impdp.sh

# para consultar as portas do ambiente:
docker ps

# parabens! seu ambiente esta (ou pelo menos deveria) funcionando!
```

Caso você precise verificar algum problema no ambiente:

```sh
docker-compose logs protheus
docker-compose logs dbaccess
```

## Roadmap

- [x] script para criar banco inicial do postgres
- [x] script para restaurar base congelada do postgres
- [x] script para fazer backup do postgres
- [x] script para criar banco inicial do mssql
- [x] script para restaurar base congelada do mssql
- [ ] script para fazer backup do mssql
- [x] script para criar banco inicial do oracle
- [x] script para restaurar base congelada do oracle
- [ ] script para fazer backup do oracle
- [ ] incluir imagem do tir com rdp ou vnc
- [ ] incluir imagem do robo de teste
- [ ] incluir imagem do sonar
- [ ] incluir imagem do cloudbeaver
- [ ] incluir imagem do servidor cgi
- [ ] incluir configuracao automatica do vscode
