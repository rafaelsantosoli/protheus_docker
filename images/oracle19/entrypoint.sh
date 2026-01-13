#!/bin/bash
set -euo pipefail

echo "ℹ️  Aguardando Oracle inicializar completamente..."

# Aguardar o Oracle ficar pronto
until echo "SELECT 1 FROM DUAL;" | sqlplus -S sys/${ORACLE_PWD}@localhost:1521/${ORACLE_PDB} as sysdba > /dev/null 2>&1; do
    echo "   Oracle ainda não está pronto, aguardando..."
    sleep 5
done

echo "✅ Oracle está pronto!"

# Executar script de criação do banco Protheus
if [ -f "/local/tools/oracle_create_database.sh" ]; then
    echo "ℹ️  Executando script de criação do banco Protheus..."
    bash /local/tools/oracle_create_database.sh
    echo "✅ Banco Protheus criado com sucesso!"
else
    echo "⚠️  Script oracle_create_database.sh não encontrado em /local/tools/"
fi
