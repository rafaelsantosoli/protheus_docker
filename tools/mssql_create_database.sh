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
check_env_var "MSSQL_SA_PASSWORD"
check_env_var "DATABASE_USER"
check_env_var "DATABASE_PASS"
check_env_var "DATABASE_NAME"

echo "ℹ️  Configurando banco de dados MSSQL..."

SQLCMD=$(find /opt -name sqlcmd)

if ! $SQLCMD -U sa -P "${MSSQL_SA_PASSWORD}" -q quit 2>/dev/null; then
	echo "⚠️  Ignorando certificados SSL"
	SQLCMD="${SQLCMD} -C"
fi

$SQLCMD -U sa -P "${MSSQL_SA_PASSWORD}" <<-EOSQL
	CREATE DATABASE ${DATABASE_NAME} COLLATE Latin1_General_BIN;
	GO
	ALTER DATABASE ${DATABASE_NAME} SET RECOVERY SIMPLE WITH NO_WAIT;
	GO
	CREATE LOGIN ${DATABASE_USER} WITH PASSWORD='${DATABASE_PASS}', DEFAULT_DATABASE=${DATABASE_NAME}, CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF;
	GO
	USE ${DATABASE_NAME};
	GO
	CREATE USER ${DATABASE_USER} FOR LOGIN ${DATABASE_USER} WITH DEFAULT_SCHEMA=[dbo];
	GO
	GRANT ALL ON database::${DATABASE_NAME} TO ${DATABASE_USER} WITH GRANT OPTION;
	GO
	GRANT CONTROL, ALTER ON database::${DATABASE_NAME} TO ${DATABASE_USER} WITH GRANT OPTION;
	GO
EOSQL
