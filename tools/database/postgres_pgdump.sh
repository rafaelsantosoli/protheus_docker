#!/bin/bash
set -e

printf "Escolha qual banco de dados será backupeado:\n"
databases=`psql --csv postgres postgres <<-EOF | awk 'NR!=1 && $0 !~ /postgres|template.*/{print($0)}'
	SELECT datname FROM pg_database;
EOF`

select database in ${databases}; do
	test "${database}" && break
	printf "Opção inválida!\n"
done

pg_dump -Fc \
	-U postgres \
	--no-owner \
	--file="/local/data/totvs/dumps/${database}_$(date "+%s").dump" \
	"${database}"
