#!/bin/bash
set -e

#TODO: Gravar as variaveis usadas no docker-compose.yml gerado
#      assim é possível reler os valores anteriores

printf "Qual release do Protheus deseja utilizar?\n"
select release in 12.1.2210 12.1.2310 12.1.2410; do
	test "${release}" && break
	printf "opção invalida!\n"
done


printf "Qual banco de dados deseja utilizar?\n"
select banco_de_dados in postgres15 postgres16 mssql2019 mssql2022 oracle19; do
	test "${banco_de_dados}" && break
	printf "opção invalida!\n"
done


printf "Qual a expedição deseja utilizar?\n"
select expedicao in next latest published; do
	test "${expedicao}" && break
	printf "opção invalida!\n"
done


printf "Qual idioma deseja utilizar?\n"
select idioma in arg bra col mex per; do
	test "${idioma}" && break
	printf "opção invalida!\n"
done

case "${banco_de_dados}" in
	postgres15)
		dbdatabase="postgres"
		;;
	postgres16)
		dbdatabase="postgres"
		;;
	mssql2019)
		dbdatabase="mssql"
		;;
	mssql2022)
		dbdatabase="mssql"
		;;
	oracle19)
		dbdatabase="oracle"
		;;
esac

case "${idioma}" in
	bra)
		congelada_idioma="exp"
		;;
	*)
		congelada_idioma="${idioma}"
		;;
esac

congelada_nome="p${release//./}mntdb${congelada_idioma}"
dbalias="${release//./}_${idioma}"
database_user="protheus"

exec 9<&1
exec 1>docker-compose.yml

cat <<-EOF
	version: "3.6"
	services:
EOF

case "${banco_de_dados}" in
	postgres15)
		cat <<-EOF
		  postgres15:
		    build: images/postgres15
		    environment:
		    - POSTGRES_PASSWORD=Postgres.123
		    - DATABASE_USER=${database_user}
		    - DATABASE_PASS=Protheus.123
		    - DATABASE_NAME=${congelada_nome}
		    volumes:
		    - "\${PWD}:/local"
		    - "postgres15:/var/lib/postgresql/data"
		    ports:
		    - "5432"
		    deploy:
		      resources:
		        limits:
		          cpus: 1
		          memory: 1GB
		EOF
		;;
	postgres16)
		cat <<-EOF
		  postgres16:
		    build: images/postgres16
		    environment:
		    - POSTGRES_PASSWORD=Postgres.123
		    - DATABASE_USER=${database_user}
		    - DATABASE_PASS=Protheus.123
		    - DATABASE_NAME=${congelada_nome}
		    volumes:
		    - "\${PWD}:/local"
		    - "postgres16:/var/lib/postgresql/data"
		    ports:
		    - "5432"
		    deploy:
		      resources:
		        limits:
		          cpus: 1
		          memory: 1GB
		EOF
		;;
	mssql2019)
		cat <<-EOF
		  mssql2019:
		    build: images/mssql2019
		    environment:
		    - ACCEPT_EULA=yes
		    - MSSQL_SA_PASSWORD=Mssql.123
		    - DATABASE_USER=${database_user}
		    - DATABASE_PASS=Protheus.123
		    - DATABASE_NAME=${congelada_nome}
		    volumes:
		    - "\${PWD}:/local"
		    - "mssql2019:/var/opt/mssql"
		    ports:
		    - "1433"
		    deploy:
		      resources:
		        limits:
		          cpus: 1
		          memory: 2GB
		EOF
		;;
	mssql2022)
		cat <<-EOF
		  mssql2022:
		    build: images/mssql2022
		    environment:
		    - ACCEPT_EULA=yes
		    - MSSQL_SA_PASSWORD=Mssql.123
		    - DATABASE_USER=${database_user}
		    - DATABASE_PASS=Protheus.123
		    - DATABASE_NAME=${congelada_nome}
		    volumes:
		    - "\${PWD}:/local"
		    - "mssql2022:/var/opt/mssql"
		    ports:
		    - "1433"
		    deploy:
		      resources:
		        limits:
		          cpus: 1
		          memory: 2GB
		EOF
		;;
	oracle19)
		# oracle o usuario tem "o nome do banco"
		database_user=${congelada_nome}
		ORACLE_PDB=ORACLEPDB1

		cat <<-EOF
		  oracle19:
		    build: images/oracle19
		    environment:
		    - ORACLE_SID=ORACLE
		    - ORACLE_PDB=${ORACLE_PDB}
		    - ORACLE_PWD=Oracle.123
		    - DATABASE_USER=${database_user}
		    - DATABASE_PASS=Protheus.123
		    - DATABASE_NAME=${congelada_nome}
		    volumes:
		    - "\${PWD}:/local"
		    - "oracle19:/opt/oracle/oradata"
		    ports:
		    - "1521"
		    deploy:
		      resources:
		        limits:
		          cpus: 2
		          memory: 6GB
		EOF
		;;
esac

cat <<-EOF
  dbaccess:
    build: images/dbaccess
    command:
    - "bash"
    - "/local/tools/dbaccess.sh"
    environment:
    - TOTVS_HOME=/local/data/totvs/
    - DBACCESS_HOME=/local/data/totvs/dbaccess/multi/
    - LICENSE_SERVER=\${LICENSE_SERVER:-localhost}
    - LICENSE_PORT=\${LICENSE_PORT:-5555}
    - DBACCESS_DRIVER=${dbdatabase}
    - DBACCESS_ALIAS=${dbalias}
    - DATABASE_HOST=${banco_de_dados}
    - DATABASE_NAME=${congelada_nome}
    - DATABASE_USER=${database_user}
    - DATABASE_PASS=Protheus.123
    - ORACLE_PDB=${ORACLE_PDB}
    volumes:
    - "\${PWD}:/local"
    - "\${PWD}/data/totvs/dbaccess/configures/odbc.ini:/etc/odbc.ini"
    - "\${PWD}/data/totvs/dbaccess/configures/tnsnames.ora:/opt/oracle/instantclient_21_5/network/admin/tnsnames.ora"
    ports:
    - "7890"
    deploy:
      resources:
        limits:
          cpus: 1
          memory: 1GB
  protheus:
    build: images/protheus
    command:
    - "bash"
    - "/local/tools/protheus.sh"
    environment:
    - TOTVS_HOME=/local/data/totvs/
    - PROTHEUS_HOME=/local/data/totvs/protheus/
    - APPSERVER_HOME=/local/data/totvs/appserver/
    - LICENSE_SERVER=\${LICENSE_SERVER:-localhost}
    - LICENSE_PORT=\${LICENSE_PORT:-5555}
    - DBSERVER=dbaccess
    - DBPORT=7890
    - DBDATABASE=${dbdatabase}
    - DBALIAS=${dbalias}
    - REGIONALLANGUAGE=${idioma}
    volumes:
    - "\${PWD}:/local"
    ports:
    - "8080"
    deploy:
      resources:
        limits:
          cpus: 1
          memory: 1GB
volumes:
EOF

case "${banco_de_dados}" in
	postgres15)
		cat <<-EOF
		  postgres15:
		EOF
		;;
	postgres16)
		cat <<-EOF
		  postgres16:
		EOF
		;;
	mssql2019)
		cat <<-EOF
		  mssql2019:
		EOF
		;;
	mssql2022)
		cat <<-EOF
		  mssql2022:
		EOF
		;;
	oracle19)
		cat <<-EOF
		  oracle19:
		EOF
		;;
esac
