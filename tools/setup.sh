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

# Tenta carregar variáveis do arquivo .env na raiz do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
fi

if [ -f "$PROJECT_ROOT/.env" ]; then
    set -a
    source "$PROJECT_ROOT/.env"
    set +a
fi

# Verifica credenciais do ARTE
if [ -z "$ARTE_USER" ] || [ -z "$ARTE_PASS" ]; then
    log_error "As variáveis de ambiente ARTE_USER e ARTE_PASS precisam estar definidas."
    exit 1
fi

MODE="create"
if [ "$1" == "update" ]; then
    MODE="update"
    if [ -z "$2" ]; then
        echo "Uso para atualização: $0 update <nome_do_ambiente>"
        exit 1
    fi
    env_name="$2"
    echo ">>> Modo de Atualização: Ambiente '$env_name'"
fi

if [ "$MODE" == "create" ]; then
    # 1. Solicitar Nome do Ambiente
    printf "Digite o nome do ambiente (ex: pg_dev, oracle_test):\n"
    read env_name

    if [ -z "$env_name" ]; then
        echo "Nome do ambiente não pode ser vazio."
        exit 1
    fi

    ENV_DIR="${PROJECT_ROOT}/environments/${env_name}"
    mkdir -p "$ENV_DIR"
    echo "Configurando ambiente em: $ENV_DIR"

    # 2. Seleção de Opções
    printf "Qual release do Protheus deseja utilizar?\n"
    select release in 12.1.2210 12.1.2310 12.1.2410 12.1.2510; do
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

    # 3. Definição de Variáveis Derivadas
    case "${release}" in
        12.1.2210) animal=harpia; rpo_file=tttm120.rpo ;;
        12.1.2310) animal=harpia; rpo_file=tttm120.rpo ;;
        12.1.2410) animal=panthera_onca; rpo_file=tttm120.rpo ;;
        12.1.2510) animal=panthera_onca; rpo_file=tttm120.rpo ;;
    esac

    case "${banco_de_dados}" in
        postgres15|postgres16) database="postgresql.zip" ;;
        mssql2019|mssql2022)   database="mssql_bak.zip" ;;
        oracle19)              database="oracle.zip" ;;
    esac

    case "${idioma}" in
        bra) tipo_congelada="exp_com_dic"; tipo_protheus="padrao" ;;
        *)   tipo_congelada="mnt_com_dic"; tipo_protheus="mi" ;;
    esac

    # 4. Salvar Configuração do Ambiente
    CONFIG_FILE="${ENV_DIR}/config.env"
    echo "Salvando configuração em ${CONFIG_FILE}..."

    cat <<EOF > "${CONFIG_FILE}"
RELEASE=${release}
BANCO_DE_DADOS=${banco_de_dados}
EXPEDICAO=${expedicao}
IDIOMA=${idioma}
ANIMAL=${animal}
RPO_FILE=${rpo_file}
DATABASE_FILE=${database}
TIPO_CONGELADA=${tipo_congelada}
TIPO_PROTHEUS=${tipo_protheus}
COMPOSE_PROJECT_NAME=${env_name}
EOF

else
    # MODO UPDATE
    ENV_DIR="${PROJECT_ROOT}/environments/${env_name}"
    CONFIG_FILE="${ENV_DIR}/config.env"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "Erro: Configuração não encontrada em $CONFIG_FILE"
        exit 1
    fi
    
    echo "Carregando configurações existentes..."
    source "$CONFIG_FILE"
    
    # Mapeia variáveis do config (Maiúsculas) para variáveis locais (Minúsculas) usadas no download
    release="$RELEASE"
    banco_de_dados="$BANCO_DE_DADOS"
    expedicao="$EXPEDICAO"
    idioma="$IDIOMA"
    animal="$ANIMAL"
    rpo_file="$RPO_FILE"
    database="$DATABASE_FILE"
    tipo_congelada="$TIPO_CONGELADA"
    tipo_protheus="$TIPO_PROTHEUS"
fi

# 5. Download e Extração de Artefatos (Centralizado em data/)
APPSERVER_URL="https://arte.engpro.totvs.io/tec/appserver/${animal}/linux/64/${expedicao}/appserver.tar.gz"
WEBAPP_URL="https://arte.engpro.totvs.io/tec/smartclientwebapp/${animal}/linux/64/${expedicao}/smartclientwebapp.tar.gz"
PDFPRINTER_URL="https://arte.engpro.totvs.io/tec/pdfprinter/linux/64/${expedicao}/pdfprinter.tar.gz"
DBACCESS_URL="https://arte.engpro.totvs.io/tec/dbaccess/linux/64/${expedicao}/dbaccess.tar.gz"
PROTHEUS_URL="https://arte.engpro.totvs.io/protheus/${tipo_protheus}/builds/${release}/${expedicao}/repositorio/${animal}/${rpo_file}"
DICIONARIO_URL="https://arte.engpro.totvs.io/protheus/${tipo_protheus}/builds/${release}/published/dicionario/dicionario_de_dados/completo/${idioma}-DICIONARIOS_COMPL.ZIP"
HELP_URL="https://arte.engpro.totvs.io/protheus/${tipo_protheus}/builds/${release}/published/dicionario/help_de_campo/completo/${idioma}-HELPS_COMPL.ZIP"
MENU_URL="https://arte.engpro.totvs.io/protheus/${tipo_protheus}/builds/${release}/published/dicionario/menus/${idioma}-MENUS.ZIP"
CONGELADA_URL="https://arte.engpro.totvs.io/engenharia/base_congelada/protheus/${idioma}/${release}/${tipo_congelada}/latest/${database}"
PROTHEUSDATA_URL="https://arte.engpro.totvs.io/engenharia/base_congelada/protheus/${idioma}/${release}/${tipo_congelada}/latest/protheus_data.zip"

mkdir -p \
	"${PROJECT_ROOT}/data/downloads/" \
	"${PROJECT_ROOT}/data/totvs/dumps/" \
	"${PROJECT_ROOT}/data/totvs/appserver/" \
	"${PROJECT_ROOT}/data/totvs/dbaccess/configures/" \
	"${PROJECT_ROOT}/data/totvs/protheus/apo/" \
	"${PROJECT_ROOT}/data/totvs/protheus/protheus_data/" \
	"${PROJECT_ROOT}/data/totvs/protheus/protheus_data/system" \
	"${PROJECT_ROOT}/data/totvs/protheus/protheus_data/systemload"

touch "${PROJECT_ROOT}/data/totvs/dbaccess/configures/odbc.ini" \
	"${PROJECT_ROOT}/data/totvs/dbaccess/configures/tnsnames.ora"

chmod 0666 "${PROJECT_ROOT}/data/totvs/dbaccess/configures/odbc.ini" \
	"${PROJECT_ROOT}/data/totvs/dbaccess/configures/tnsnames.ora"

# Função inteligente de Download e Extração
download_and_extract() {
    url="$1"
    dest_file="$2"
    extract_dest="$3"
    type="$4" # tar, zip, cp, custom_dump

    filename=$(basename "$dest_file")
    echo "--------------------------------------------------"
    echo "Processando: $filename"

    current_hash=""
    if [ -f "$dest_file" ]; then
        # Calcula hash apenas se arquivo existir
        current_hash=$(sha256sum "$dest_file" | awk '{print $1}')
    fi

    # Download condicional (-z)
    echo "Downloading ${url}"
    if ! curl -u "${ARTE_USER}:${ARTE_PASS}" -L "${url}" -o "${dest_file}" -z "${dest_file}" --fail; then
        echo "Erro no download de $url"
        return 1
    fi

    if [ ! -f "$dest_file" ]; then
        echo "Erro: Arquivo não encontrado após download: $dest_file"
        return 1
    fi

    new_hash=$(sha256sum "$dest_file" | awk '{print $1}')

    if [ "$current_hash" == "$new_hash" ] && [ -n "$current_hash" ]; then
        echo " >> Arquivo inalterado (Hash Match: ${new_hash:0:8}...). Pulando extração."
        return 0
    fi

    echo " >> Arquivo novo ou modificado. Iniciando extração..."

    case "$type" in
        "tar")
            tar xzvf "$dest_file" -C "$extract_dest"
            ;;
        "zip")
            unzip -o "$dest_file" -d "$extract_dest"
            ;;
        "cp")
             cp "$dest_file" "$extract_dest"
             ;;
        "custom_dump")
            (
                cd "$extract_dest"
                # Usa caminho absoluto ou relativo ajustado
                unzip -o "$dest_file" || 7z x "$dest_file"
            )
            ;;
    esac
}

echo "Verificando e baixando artefatos..."

# AppServer
download_and_extract "${APPSERVER_URL}" \
    "${PROJECT_ROOT}/data/downloads/appserver.tar.gz" \
    "${PROJECT_ROOT}/data/totvs/appserver/" \
    "tar"

# WebApp
download_and_extract "${WEBAPP_URL}" \
    "${PROJECT_ROOT}/data/downloads/webapp.tar.gz" \
    "${PROJECT_ROOT}/data/totvs/appserver/" \
    "tar"

# PDF Printer
download_and_extract "${PDFPRINTER_URL}" \
    "${PROJECT_ROOT}/data/downloads/pdfprinter.tar.gz" \
    "${PROJECT_ROOT}/data/totvs/appserver/" \
    "tar"

# DBAccess
download_and_extract "${DBACCESS_URL}" \
    "${PROJECT_ROOT}/data/downloads/dbaccess.tar.gz" \
    "${PROJECT_ROOT}/data/totvs/dbaccess/" \
    "tar"

# Copia dbapi.so (sempre necessário se dbaccess mudar)
cp "${PROJECT_ROOT}/data/totvs/dbaccess/client/dbapi.so" "${PROJECT_ROOT}/data/totvs/appserver/"

# RPO
rpo_file_local=`basename ${PROTHEUS_URL}`
download_and_extract "${PROTHEUS_URL}" \
    "${PROJECT_ROOT}/data/downloads/${rpo_file_local}" \
    "${PROJECT_ROOT}/data/totvs/protheus/apo/" \
    "cp"

# Dicionários
dicionario_file=`basename ${DICIONARIO_URL}`
download_and_extract "${DICIONARIO_URL}" \
    "${PROJECT_ROOT}/data/downloads/${dicionario_file}" \
    "${PROJECT_ROOT}/data/totvs/protheus/protheus_data/systemload/" \
    "zip"

# Help
help_file=`basename ${HELP_URL}`
download_and_extract "${HELP_URL}" \
    "${PROJECT_ROOT}/data/downloads/${help_file}" \
    "${PROJECT_ROOT}/data/totvs/protheus/protheus_data/systemload/" \
    "zip"

# Menu
menu_file=`basename ${MENU_URL}`
download_and_extract "${MENU_URL}" \
    "${PROJECT_ROOT}/data/downloads/${menu_file}" \
    "${PROJECT_ROOT}/data/totvs/protheus/protheus_data/system/" \
    "zip"

# Base Congelada (Dump)
congelada_file=`basename ${CONGELADA_URL}`
download_and_extract "${CONGELADA_URL}" \
    "${PROJECT_ROOT}/data/downloads/${congelada_file}" \
    "${PROJECT_ROOT}/data/totvs/dumps" \
    "custom_dump"

# Ajusta permissões do diretório dumps para que o Oracle consiga ler/escrever
chmod 777 "${PROJECT_ROOT}/data/totvs/dumps"
chmod 644 "${PROJECT_ROOT}/data/totvs/dumps/"*.dmp 2>/dev/null || true
chmod 644 "${PROJECT_ROOT}/data/totvs/dumps/"*.DMP 2>/dev/null || true

# Protheus Data
# A url foi definida anteriormente mas não estava sendo baixada.
protheus_data_file=`basename ${PROTHEUSDATA_URL}`
download_and_extract "${PROTHEUSDATA_URL}" \
    "${PROJECT_ROOT}/data/downloads/${protheus_data_file}" \
    "${PROJECT_ROOT}/data/totvs/protheus/" \
    "zip"

echo "Setup concluído para o ambiente: $env_name"
echo "Próximo passo: Executar o generate.sh $env_name"
