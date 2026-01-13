#!/bin/bash
set -e

printf "Escolha qual arquivo de dump você deseja usar:\n"
select dump in `find /local/data/totvs/dumps/ -type f -name '*\.dump'`; do
	test "${dump}" && break
	printf "Opção inválida!\n"
done

printf "Escolha qual banco de dados será restaurado:\n"
databases=`psql --csv postgres postgres <<-EOF | awk 'NR!=1 && $0 !~ /postgres|template.*/{print($0)}'
	SELECT datname FROM pg_database;
EOF`

select database in ${databases}; do
	test "${database}" && break
	printf "Opção inválida!\n"
done

pg_restore -Fc \
	-U postgres \
	--role="${DATABASE_USER}" \
	--dbname="${database}" \
	--no-owner \
	"${dump}"

#TODO: descobrir como identificar se o banco de dados possui dados.
#	--clean \
