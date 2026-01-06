#!/bin/bash
set -e

SQLCMD=$(find /opt -name sqlcmd)

if ! $SQLCMD -U sa -P "${MSSQL_SA_PASSWORD}" -q quit 2>/dev/null; then
	echo ignorando certificados
	SQLCMD="${SQLCMD} -C"
fi

printf "Escolha qual arquivo de dump você deseja usar:\n"
select dump in `find /local/data/totvs/dumps/ -type f -name '*\.bak'`; do
	test "${dump}" && break
	printf "Opção inválida!\n"
done

databases=`$SQLCMD -U sa -P "${MSSQL_SA_PASSWORD}" <<-EOF | awk 'NF==0{exit} NR>2 && $0!~/master|tempdb|model|msdb/{gsub("[^A-Za-z0-9_]", ""); print($0)}'
	SELECT name FROM SYS.DATABASES;
	GO
EOF`

printf "Escolha qual banco de dados será restaurado:\n"
select database in ${databases}; do
	test "${database}" && break
	printf "Opção inválida!\n"
done

data_file=`basename ${dump}`
data_file="${data_file/.bak/}"
log_file="${data_file}_log"

$SQLCMD -U sa -P "${MSSQL_SA_PASSWORD}" <<-EOSQL
	RESTORE DATABASE ${database} FROM DISK='${dump}' WITH 
	  MOVE '${data_file}' 
	    TO '/var/opt/mssql/data/${database}.mdf', 
	  MOVE '${log_file}' 
	    TO '/var/opt/mssql/data/${database}_log.ldf',
	  REPLACE;
	GO
	ALTER DATABASE ${database} SET RECOVERY SIMPLE WITH NO_WAIT;
	GO
	USE ${database};
	GO
	CREATE USER ${DATABASE_USER} FOR LOGIN ${DATABASE_USER} WITH DEFAULT_SCHEMA=[dbo];
	GO
	GRANT ALL ON database::${database} TO ${DATABASE_USER} WITH GRANT OPTION;
	GO
	GRANT CONTROL, ALTER ON database::${database} TO ${DATABASE_USER} WITH GRANT OPTION;
	GO
EOSQL
