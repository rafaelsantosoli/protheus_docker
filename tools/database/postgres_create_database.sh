#!/bin/bash
set -euo pipefail

# Funções de log estruturado
log_info() {
    echo "ℹ️  $*"
}

log_success() {
    echo "✅ $*"
}

log_error() {
    echo "❌ ERRO: $*" >&2
}

log_warning() {
    echo "⚠️  AVISO: $*"
}

# Função para validar variáveis de ambiente
check_env_var() {
    local var_name=$1
    if [[ -z "${!var_name:-}" ]]; then
        log_error "Variável de ambiente '${var_name}' não está definida."
        exit 1
    fi
}

# Validação de variáveis críticas
check_env_var "DATABASE_USER"
check_env_var "DATABASE_PASS"
check_env_var "DATABASE_NAME"

echo "ℹ️  Criando usuário e banco de dados PostgreSQL..."

psql -U postgres postgres <<EOSQL
    DO
    \$do\$
    BEGIN
       IF NOT EXISTS (
          SELECT FROM pg_catalog.pg_roles
          WHERE  rolname = '${DATABASE_USER}') THEN

          CREATE USER "${DATABASE_USER}"
            WITH LOGIN
            NOSUPERUSER
            INHERIT CREATEDB
            NOCREATEROLE
            NOREPLICATION
            CONNECTION LIMIT -1
            PASSWORD '${DATABASE_PASS}';
       END IF;
    END
    \$do\$;

    DO
    \$do\$
    BEGIN
       IF NOT EXISTS (
          SELECT FROM pg_database
          WHERE  datname = '${DATABASE_NAME}') THEN

            PERFORM dblink_exec('dbname=' || current_database(), 'CREATE DATABASE "${DATABASE_NAME}" WITH OWNER "${DATABASE_USER}" ENCODING ''WIN1252'' LC_COLLATE ''C'' LC_CTYPE ''C'' CONNECTION LIMIT=-1');
       END IF;
    END
    \$do\$;

    GRANT ALL PRIVILEGES ON DATABASE "${DATABASE_NAME}" TO "${DATABASE_USER}";
EOSQL

echo "ℹ️  Criando TableSpaces para organização de dados..."

# Create directory outside of PGDATA to avoid permissions/recommendation issues
mkdir -p /var/lib/postgresql/tablespaces/data
mkdir -p /var/lib/postgresql/tablespaces/index
chown -R postgres:postgres /var/lib/postgresql/tablespaces

psql -U postgres "${DATABASE_NAME}" <<EOSQL
    -- Criar extensões
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    CREATE EXTENSION IF NOT EXISTS "dblink";
EOSQL

# Tablespace creation (Must be outside transaction block/function)
TS_DATA_EXISTS=$(psql -U postgres -tAc "SELECT 1 FROM pg_tablespace WHERE spcname = '${DATABASE_NAME}_data'")
if [ "$TS_DATA_EXISTS" != "1" ]; then
    psql -U postgres -c "CREATE TABLESPACE ${DATABASE_NAME}_data LOCATION '/var/lib/postgresql/tablespaces/data';"
fi

TS_INDEX_EXISTS=$(psql -U postgres -tAc "SELECT 1 FROM pg_tablespace WHERE spcname = '${DATABASE_NAME}_index'")
if [ "$TS_INDEX_EXISTS" != "1" ]; then
    psql -U postgres -c "CREATE TABLESPACE ${DATABASE_NAME}_index LOCATION '/var/lib/postgresql/tablespaces/index';"
fi

# Re-grant permissions just in case
psql -U postgres "${DATABASE_NAME}" <<EOSQL
    GRANT CREATE ON TABLESPACE ${DATABASE_NAME}_data TO "${DATABASE_USER}";
    GRANT CREATE ON TABLESPACE ${DATABASE_NAME}_index TO "${DATABASE_USER}";
EOSQL

echo "✅ Banco de dados PostgreSQL criado com sucesso!"
