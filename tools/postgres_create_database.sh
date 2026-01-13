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
    CREATE USER "${DATABASE_USER}"
        WITH LOGIN
        NOSUPERUSER
        INHERIT CREATEDB
        NOCREATEROLE
        NOREPLICATION
        CONNECTION LIMIT -1
        PASSWORD '${DATABASE_PASS}';

    CREATE DATABASE "${DATABASE_NAME}"
        WITH OWNER "${DATABASE_USER}"
        TEMPLATE template0
        ENCODING 'WIN1252'
        LC_COLLATE 'C'
        LC_CTYPE 'C'
        CONNECTION LIMIT=-1;

    GRANT ALL PRIVILEGES \
        ON DATABASE "${DATABASE_NAME}"
	TO "${DATABASE_USER}";
EOSQL

echo "ℹ️  Criando TableSpaces para organização de dados..."

psql -U postgres "${DATABASE_NAME}" <<EOSQL
    -- Criar diretórios para tablespaces
    \! mkdir -p /var/lib/postgresql/data/tablespaces/data
    \! mkdir -p /var/lib/postgresql/data/tablespaces/index

    -- Criar tablespaces
    CREATE TABLESPACE ${DATABASE_NAME}_data
        LOCATION '/var/lib/postgresql/data/tablespaces/data';
    
    CREATE TABLESPACE ${DATABASE_NAME}_index
        LOCATION '/var/lib/postgresql/data/tablespaces/index';

    -- Conceder permissões
    GRANT CREATE ON TABLESPACE ${DATABASE_NAME}_data TO "${DATABASE_USER}";
    GRANT CREATE ON TABLESPACE ${DATABASE_NAME}_index TO "${DATABASE_USER}";

    -- Criar extensões
    CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
EOSQL

echo "✅ Banco de dados PostgreSQL criado com sucesso!"
