#!/bin/bash

# update.sh - Wrapper para atualizar artefatos de um ambiente existente
# Uso: ./update.sh <nome_do_ambiente>

if [ -z "$1" ]; then
    echo "Uso: $0 <nome_do_ambiente>"
    echo "Exemplo: $0 pg_dev"
    exit 1
fi

./tools/setup.sh update "$1"
