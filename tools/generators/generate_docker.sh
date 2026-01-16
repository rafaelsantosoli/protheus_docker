#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Uso: $0 <nome_do_ambiente>"
    exit 1
fi

# Updated paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$TOOLS_DIR")"

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
		    healthcheck:
		      test: ["CMD-SHELL", "pg_isready -U postgres || exit 1"]
		      interval: 30s
		      retries: 3
		      start_period: 20s
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
		    healthcheck:
		      test: ["CMD-SHELL", "pg_isready -U postgres || exit 1"]
		      interval: 30s
		      retries: 3
		      start_period: 20s
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
		    healthcheck:
	      test: ["CMD-SHELL", "echo 'SELECT 1 FROM DUAL;' | sqlplus -S sys/Oracle.123@localhost:1521/ORACLEPDB1 as sysdba | awk 'NR==2 {exit ($1==1)?0:1}'"]
		      interval: 30s
		      retries: 5
		      start_period: 120s
		EOF
		;;
esac

# Determine Image Source and Mode
env_type="${ENV_TYPE:-custom}"

if [ "$env_type" == "kubernize" ]; then
    # KUBERNIZE MODE (Official Images)
    # Tag logic: Use release (e.g. 12.1.2410) + suffix if needed.
    # Setup wizard saves full RELEASE, e.g. 12.1.2410.
    # We will assume "published" tag (release number only) or add -latest if requested?
    # Setup said "expedicao" (next, latest, published).
    # If expedicao is published, tag is 12.1.2410.
    # If latest, 12.1.2410-latest.

    IMG_TAG="${RELEASE}"
    if [ "${EXPEDICAO}" != "published" ]; then
        IMG_TAG="${RELEASE}-${EXPEDICAO}"
    fi

    # DBAccess Image
    DBACCESS_IMAGE="docker.totvs.io/totvs-images/dbaccess:${IMG_TAG}"
    # Protheus Image
    PROTHEUS_IMAGE="docker.totvs.io/totvs-images/protheus:${IMG_TAG}"
    # License Server (Fixed version usually, or variable?)
    LICENSE_IMAGE="docker.totvs.io/totvs-images/license:v3.6.3_1"

    cat <<-EOF
  dbaccess:
    image: ${DBACCESS_IMAGE}
    environment:
      - LICENSE_SERVER=${LICENSE_SERVER:-localhost}
      - LICENSE_PORT=${LICENSE_PORT:-5555}
      - DBACCESS_DATABASE=${DBACCESS_DATABASE:-POSTGRES}
      - DBACCESS_ALIAS=${dbalias}
      - POSTGRES_SERVER=${BANCO_DE_DADOS}
      - POSTGRES_PORT=${database_port}
      - POSTGRES_DATABASE=${database_user}
      - POSTGRES_USER=${database_user}
      - POSTGRES_PASS=Protheus.123
      - MSSQL_SERVER=${BANCO_DE_DADOS}
      - MSSQL_PORT=${database_port}
      - MSSQL_DATABASE=${database_user}
      - MSSQL_USER=${database_user}
      - MSSQL_PASS=Protheus.123
      - ORACLE_SERVER=${BANCO_DE_DADOS}
      - ORACLE_PORT=${database_port}
      - ORACLE_USER=${database_user}
      - ORACLE_PASS=Protheus.123
      - LOCK_NUM_ON_DB=1
    ports:
      - "7890"
    depends_on:
      ${BANCO_DE_DADOS}:
        condition: service_healthy

  protheus:
    image: ${PROTHEUS_IMAGE}
    environment:
      - LICENSE_SERVER=${LICENSE_SERVER:-localhost}
      - LICENSE_PORT=${LICENSE_PORT:-5555}
      - DBACCESS_SERVER=dbaccess
      - DBACCESS_PORT=7890
      - DBACCESS_DATABASE=${DBACCESS_DATABASE:-POSTGRES}
      - DBACCESS_ALIAS=${dbalias}
      - LOCK_NUM_ON_DB=1
    volumes:
      # Map local data structure to Kubernize volume structure
      # Local: data/totvs/protheus/apo -> Container: /opt/totvs/protheus/volume/current/apo
      - "../../data/totvs/protheus:/opt/totvs/protheus/volume/current"
    ports:
      - "8086:8080" # Kubernize works on 8080 internal
      - "1234"
    depends_on:
      dbaccess:
        condition: service_healthy
EOF

else
    # CUSTOM MODE (Legacy)
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
    ulimits:
      nofile:
        soft: 65536
        hard: 65536
    depends_on:
      ${BANCO_DE_DADOS}:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "pgrep -x dbaccess64 > /dev/null || exit 1"]
      interval: 20s
      retries: 5
      start_period: 30s

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
      - "8086"
      - "1234"
    ulimits:
      nofile:
        soft: 65536
        hard: 65536
    depends_on:
      dbaccess:
        condition: service_healthy
    extra_hosts:
      - "licensedba.engpro.totvs.com.br:host-gateway"
    healthcheck:
      test: ["CMD-SHELL", "pgrep -f appsrvlinux > /dev/null || exit 1"]
      interval: 20s
      retries: 5
      start_period: 60s
EOF
fi
cat <<-EOF
volumes:
EOF

case "${BANCO_DE_DADOS}" in
    mssql2022) echo "  mssql_data: {}"; echo "  mssql_log: {}" ;;
    mssql2019) echo "  mssql2019: {}" ;;
    postgres15) echo "  postgres15: {}" ;;
    postgres16) echo "  postgres16: {}" ;;
    oracle19) echo "  oracle19: {}" ;;
esac
