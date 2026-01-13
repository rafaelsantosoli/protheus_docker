#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Uso: $0 <nome_do_ambiente>"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

ENV_NAME="$1"
ENV_DIR="${PROJECT_ROOT}/environments/${ENV_NAME}"
CONFIG_FILE="${ENV_DIR}/config.env"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Erro: Configuração não encontrada em ${CONFIG_FILE}."
    exit 1
fi

source "${CONFIG_FILE}"

case "${BANCO_DE_DADOS}" in
    postgres15|postgres16)
        dbdatabase="postgres" 
        database_port="5432"
        ;;
    mssql2019|mssql2022)   
        dbdatabase="mssql" 
        database_port="1433"
        ;;
    oracle19)              
        dbdatabase="oracle"
        database_port="1521"
        ;;
esac

case "${IDIOMA}" in
    bra) congelada_idioma="exp" ;;
    *)   congelada_idioma="${IDIOMA}" ;;
esac

congelada_nome="p${RELEASE//./}mntdb${congelada_idioma}"
dbalias="${RELEASE//./}_${IDIOMA}"
database_user="protheus"

exec 9<&1
exec 1>"${ENV_DIR}/docker-compose.yml"

cat <<-EOF
	version: "3.6"
	services:
EOF

case "${BANCO_DE_DADOS}" in
	mssql2022)
		cat <<-EOF
		  mssql2022:
		    build: ../../images/mssql2022
		    hostname: ${ENV_NAME}_mssql
		    environment:
		      - ACCEPT_EULA=Y
		      - MSSQL_SA_PASSWORD=Mssql.123
		      - DATABASE_USER=${database_user}
		      - DATABASE_PASS=Protheus.123
		      - DATABASE_NAME=${congelada_nome}
		      - MSSQL_PID=Developer
		      - MSSQL_MEMORY_LIMIT_MB=8192
		    volumes:
		      - "../../:/local"
		      - "../../config/mssql.conf:/var/opt/mssql/mssql.conf"
		      - "mssql_data:/var/opt/mssql/data"
		      - "mssql_log:/var/opt/mssql/log"
		    ports:
		      - "1433"
		    ulimits:
		      memlock: -1
		      nofile:
		        soft: 65536
		        hard: 65536
		    sysctls:
		      - net.ipv4.ip_local_port_range=1024 65535
		    deploy:
		      resources:
		        limits:
		          cpus: 8
		          memory: 10G
		        reservations:
		          cpus: 2
		          memory: 4G
		    healthcheck:
		      test: ["CMD-SHELL", "/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P Mssql.123 -C -Q 'SELECT 1' || exit 1"]
		      interval: 30s
		      retries: 3
		      start_period: 30s
		EOF
		;;
	mssql2019)
		cat <<-EOF
		  mssql2019:
		    build: ../../images/mssql2019
		    hostname: ${ENV_NAME}_mssql
		    environment:
		      - ACCEPT_EULA=Y
		      - MSSQL_SA_PASSWORD=Mssql.123
		      - DATABASE_USER=${database_user}
		      - DATABASE_PASS=Protheus.123
		      - DATABASE_NAME=${congelada_nome}
		      - MSSQL_PID=Developer
		    volumes:
		      - "../../:/local"
		      - "mssql2019:/var/opt/mssql"
		    ports:
		      - "1433"
		    deploy:
		      resources:
		        limits:
		          cpus: 2
		          memory: 4G
		EOF
		;;
	postgres15)
		cat <<-EOF
		  postgres15:
		    build: ../../images/postgres15
		    environment:
		      - POSTGRES_PASSWORD=Postgres.123
		      - DATABASE_USER=${database_user}
		      - DATABASE_PASS=Protheus.123
		      - DATABASE_NAME=${congelada_nome}
		    volumes:
		      - "../../:/local"
		      - "postgres15:/var/lib/postgresql/data"
		    ports:
		      - "5432"
		    deploy:
		      resources:
		        limits:
		          cpus: 2
		          memory: 2GB
		EOF
		;;
	postgres16)
		cat <<-EOF
		  postgres16:
		    build: ../../images/postgres16
		    environment:
		      - POSTGRES_PASSWORD=Postgres.123
		      - DATABASE_USER=${database_user}
		      - DATABASE_PASS=Protheus.123
		      - DATABASE_NAME=${congelada_nome}
		    volumes:
		      - "../../:/local"
		      - "postgres16:/var/lib/postgresql/data"
		    ports:
		      - "5432"
		    deploy:
		      resources:
		        limits:
		          cpus: 2
		          memory: 2GB
		EOF
		;;
	oracle19)
		# oracle o usuario tem "o nome do banco"
		# Ajuste: se necessario, corrigir logica do usuario para oracle no context de environment
		database_user=${congelada_nome}
		ORACLE_PDB=ORACLEPDB1

		cat <<-EOF
		  oracle19:
		    build: ../../images/oracle19
		    environment:
		    - ORACLE_SID=ORACLE
		    - ORACLE_PDB=${ORACLE_PDB}
		    - ORACLE_PWD=Oracle.123
		    - DATABASE_USER=${database_user}
		    - DATABASE_PASS=Protheus.123
		    - DATABASE_NAME=${congelada_nome}
		    volumes:
		    - "../../:/local"
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
    build: ../../images/dbaccess
    command: ["bash", "/local/tools/dbaccess.sh"]
    environment:
      - TOTVS_HOME=/local/data/totvs/
      - DBACCESS_HOME=/local/data/totvs/dbaccess/multi/
      - LICENSE_SERVER=${LICENSE_SERVER:-localhost}
      - LICENSE_PORT=${LICENSE_PORT:-5555}
      - DBACCESS_DRIVER=${dbdatabase}
      - DBACCESS_ALIAS=${dbalias}
      - DATABASE_HOST=${BANCO_DE_DADOS}
      - DATABASE_PORT=${database_port}
      - DATABASE_USER=${database_user}
      - DATABASE_PASS=Protheus.123
      - DATABASE_NAME=${congelada_nome}
      - ORACLE_PDB=${ORACLE_PDB}
    volumes:
      - "../../:/local"
      - "../../data/totvs/dbaccess/configures/odbc.ini:/etc/odbc.ini"
      - "../../data/totvs/dbaccess/configures/tnsnames.ora:/opt/oracle/instantclient_21_5/network/admin/tnsnames.ora"
    ports:
      - "7890"
    depends_on:
      - ${BANCO_DE_DADOS}

  protheus:
    build: ../../images/protheus
    command: ["bash", "/local/tools/protheus.sh"]
    environment:
      - TOTVS_HOME=/local/data/totvs/
      - PROTHEUS_HOME=/local/data/totvs/protheus/
      - APPSERVER_HOME=/local/data/totvs/appserver/
      - DBSERVER=dbaccess
      - DBPORT=7890
      - DBDATABASE=${dbdatabase}
      - DBALIAS=${dbalias}
      - LICENSE_SERVER=${LICENSE_SERVER:-localhost}
      - LICENSE_PORT=${LICENSE_PORT:-5555}
    volumes:
      - "../../:/local"
    ports:
      - "8080"
    depends_on:
      - dbaccess

volumes:
EOF

case "${BANCO_DE_DADOS}" in
    mssql2022) echo "  mssql_data: {}"; echo "  mssql_log: {}" ;;
    mssql2019) echo "  mssql2019: {}" ;;
    postgres15) echo "  postgres15: {}" ;;
    postgres16) echo "  postgres16: {}" ;;
    oracle19) echo "  oracle19: {}" ;;
esac
