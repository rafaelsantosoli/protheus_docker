#!/bin/bash

# run.sh - Wrapper para executar comandos docker-compose em ambientes isolados

if [ $# -lt 2 ]; then
    echo "Uso: $0 <nome_do_ambiente> <comando_docker_compose> [argumentos...]"
    echo "Exemplo: $0 pg_dev up -d"
    echo "Exemplo: $0 pg_dev logs -f protheus"
    echo "Exemplo: $0 pg_dev down"
    exit 1
fi

ENV_NAME="$1"
shift
COMMAND="$@"

ENV_DIR="environments/${ENV_NAME}"
COMPOSE_FILE="${ENV_DIR}/docker-compose.yml"

if [ ! -d "$ENV_DIR" ]; then
    echo "Erro: Ambiente '${ENV_NAME}' não encontrado em ${ENV_DIR}."
    echo "Execute 'tools/setup.sh' primeiro para criar o ambiente."
    exit 1
fi

if [ ! -f "$COMPOSE_FILE" ]; then
    echo "Erro: Arquivo docker-compose.yml não encontrado em ${ENV_DIR}."
    echo "Execute 'tools/generate.sh' (ou equivalente) para gerar a configuração do Docker."
    exit 1
fi

echo ">> Executando docker-compose para o ambiente: ${ENV_NAME}"
echo ">> Arquivo: ${COMPOSE_FILE}"
echo ">> Comando: ${COMMAND}"

# Executa o docker-compose apontando para o arquivo específico e definindo o nome do projeto
# Isso permite que os containers tenham nomes prefixados com o nome do ambiente, se desejado,
# mas aqui estamos usando o nome do diretório como padrão se não definido.
# O parâmetro -p define o nome do projeto.

docker-compose -f "${COMPOSE_FILE}" -p "${ENV_NAME}" ${COMMAND}
