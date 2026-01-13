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
	exec bash /local/bin/tool_image_protheus.sh
fi

# Criar script dmidecode para identificação do sistema
cat > /usr/local/bin/dmidecode <<'DMIDECODE_SCRIPT'
#!/bin/bash
echo UUID: STOTVSID
DMIDECODE_SCRIPT
chmod +x /usr/local/bin/dmidecode

# Aplicar limites de recursos para o AppServer
ulimit -n 65536
ulimit -s 1024
ulimit -c unlimited

# Validação de variáveis críticas
check_env_var "APPSERVER_HOME"
check_env_var "PROTHEUS_HOME"
check_env_var "DBSERVER"
check_env_var "DBPORT"
check_env_var "LICENSE_SERVER"

cd ${APPSERVER_HOME}

while read apo; do
    RPO_PATH=`dirname ${apo}`
    RPO_FILE=`basename ${apo}`
    break
done <<<`find ${PROTHEUS_HOME} -name 'tt*.rpo'`

while read protheus_data; do
    PROTHEUS_DATA_PATH="${protheus_data}"
    break
done <<<`find ${PROTHEUS_HOME} -name 'protheus_data'`

# Habilitar controle de lock e numeração via DBAccess (obrigatório na 12.1.2510+)
export LOCK_NUM_ON_DB=1

(
set -o pipefail

cat <<EOF | tee appserver.ini
[ENVIRONMENT]
RPODB=${RPO_FILE:2:1}
RPOVERSION=${RPO_FILE:4:3}
RPOLANGUAGE=${RPO_FILE:3:1}
SOURCEPATH=${RPO_PATH}
ROOTPATH=${PROTHEUS_DATA_PATH}
STARTPATH=/system
LOCALFILES=CTREE
LOCALDBEXTENSION=.DTC
PICTFORMAT=DEFAULT
DATEFORMAT=DEFAULT
DBSERVER=${DBSERVER}
DBPORT=${DBPORT:=7890}
DBDATABASE=${DBDATABASE}
DBALIAS=${DBALIAS}
REGIONALLANGUAGE=${REGIONALLANGUAGE:-BRAZIL}
SPECIALKEY=meuenv
STARTSYSINDB=1
DARK=1
TOPMEMOMEGA=1

[GENERAL]
BUILDKILLUSERS=1
CONSOLELOG=1
CONSOLEFILE=/tmp/console.log
APP_ENVIRONMENT=ENVIRONMENT
MAXSTRINGSIZE=500000
CONSOLE=1

[DRIVERS]
ACTIVE=TCP
MULTIPROTOCOLPORTSECURE=0
MULTIPROTOCOLPORT=1

[TCP]
TYPE=TCPIP
PORT=1234
SECURECONNECTION=0

[WEBAPP]
ENABLE=1
PORT=8086
WEBSOCKET=0
LASTMAINPROG=SIGAADV

[LICENSECLIENT]
SERVER=${LICENSE_SERVER}
PORT=${LICENSE_PORT:-5555}

[WEBAPP/WEBAPP]
MPP=ENVIRONMENT

[SMARTJOB]
ACTIVATE=ON
MINJOBS=1
MAXJOBS=30

[HTTPV11]
ENABLE=1
PORT=9090

[WEBMONITOR]
ENABLE=0

[APP_MONITOR]
ENABLE=0
PORT=50034
GUI=1
EOF
)

exec ./appsrvlinux
