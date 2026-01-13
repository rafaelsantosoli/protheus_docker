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

if test "$(id -u)" != 0; then
	exec bash /local/tools/image_dbaccess.sh
fi

# Aplicar limites de recursos para o DBAccess
ulimit -n 65536
ulimit -c unlimited

# Habilitar controle de lock e numeração via DBAccess (obrigatório na 12.1.2510+)
export LOCK_NUM_ON_DB=1

# Validação de variáveis críticas
check_env_var "DBACCESS_HOME"
check_env_var "DBACCESS_DRIVER"
check_env_var "DBACCESS_ALIAS"
check_env_var "DATABASE_USER"
check_env_var "DATABASE_PASS"
check_env_var "DATABASE_NAME"

cd "${DBACCESS_HOME}"

# Inicializar ADD_DRIVER como vazio
ADD_DRIVER=""

# Configuração específica para Oracle
if test "${DBACCESS_DRIVER,,}" == "oracle"; then
	log_info "Configurando tnsnames.ora para Oracle..."
	cat <<-EOF > /opt/oracle/instantclient_21_5/network/admin/tnsnames.ora
	${DBACCESS_ALIAS}=
	(DESCRIPTION = 
	  (ADDRESS = (PROTOCOL = TCP)(HOST = ${DATABASE_HOST})(PORT = ${DATABASE_PORT:=1521}))
	  (CONNECT_DATA =
	    (SERVER = DEDICATED)
	    (SERVICE_NAME = ${ORACLE_PDB})
	  )
	)
	EOF
fi

# Configuração ODBC para PostgreSQL
if test "${DBACCESS_DRIVER,,}" == "postgres"; then
	ODBC_DRIVER=$(find /usr -name 'psqlodbcw*' | head -n1)
	ADD_DRIVER="-c /usr/lib64/libodbc.so"

	cat <<-EOF > /etc/odbc.ini
	[${DBACCESS_ALIAS}]
	DRIVER=${ODBC_DRIVER}
	SERVERNAME=${DATABASE_HOST}
	PORT=${DATABASE_PORT:=5432}
	DATABASE=${DATABASE_NAME}
	USERNAME=${DATABASE_USER}
	PASSWORD=${DATABASE_PASS}
	EOF
fi

# Configuração ODBC para MSSQL
if test "${DBACCESS_DRIVER,,}" == "mssql"; then
	ODBC_DRIVER=$(find /usr -name 'libmsodbcsql*' | head -n1)
	ADD_DRIVER="-c /usr/lib64/libodbc.so"

	cat <<-EOF > /etc/odbc.ini
	[${DBACCESS_ALIAS}]
	DRIVER=${ODBC_DRIVER}
	SERVER=${DATABASE_HOST}
	PORT=${DATABASE_PORT:=1433}
	DATABASE=${DATABASE_NAME}
	UID=${DATABASE_USER}
	PWD=${DATABASE_PASS}
	TRUSTSERVERCERTIFICATE=YES
	EOF
fi

rm dbaccess.ini 2>/dev/null || true

if [ -n "${ADD_DRIVER}" ]; then
	../tools/dbaccesscfg \
		-u ${DATABASE_USER} \
		-p ${DATABASE_PASS} \
		-a ${DBACCESS_ALIAS} \
		-d ${DBACCESS_DRIVER} \
		${ADD_DRIVER} \
		-o "LICENSESERVER=${LICENSE_SERVER};LICENSEPORT=${LICENSE_PORT:=5555}"
else
	../tools/dbaccesscfg \
		-u ${DATABASE_USER} \
		-p ${DATABASE_PASS} \
		-a ${DBACCESS_ALIAS} \
		-d ${DBACCESS_DRIVER} \
		-o "LICENSESERVER=${LICENSE_SERVER};LICENSEPORT=${LICENSE_PORT:=5555}"
fi

# Adicionar ODBC30=1 para PostgreSQL conforme documentação TDN
if test "${DBACCESS_DRIVER,,}" == "postgres"; then
	log_info "Adicionando ODBC30=1 para PostgreSQL..."
	if grep -q "^\[General\]" dbaccess.ini; then
		sed -i '/^\[General\]/a ODBC30=1' dbaccess.ini
	else
		sed -i '1i[General]\nODBC30=1\n' dbaccess.ini
	fi
	log_success "ODBC30 configurado!"
fi

cat dbaccess.ini
log_success "DBAccess iniciado com sucesso!"
exec ./dbaccess64
