#!/bin/bash
set -e

if test "$(id -u)" != 0; then
	exec bash /local/tools/image_dbaccess.sh
fi

cd "${DBACCESS_HOME}"

(
	set -o pipefail

	cat <<-EOF | tee ${TNS_ADMIN}/tnsnames.ora
	${DBACCESS_ALIAS}=
	(DESCRIPTION = 
	  (ADDRESS = (PROTOCOL = TCP)(HOST = ${DATABASE_HOST})(PORT = ${DATABASE_PORT:=1521}))
	  (CONNECT_DATA =
	    (SERVER = DEDICATED)
	    (SERVICE_NAME = ${ORACLE_PDB})
	  )
	)
	EOF
)

(
	while read driver; do
		ODBC_DRIVER="${driver}"
		break
	done <<<`find /usr -name 'psqlodbcw*'`

	set -o pipefail

	if test "${DBACCESS_DRIVER,,}" == "postgres"; then
		ADD_DRIVER="-c /usr/lib64/libodbc.so"

		cat <<-EOF | tee /etc/odbc.ini
		[${DBACCESS_ALIAS}]
		DRIVER=${ODBC_DRIVER}
		SERVERNAME=${DATABASE_HOST}
		PORT=${DATABASE_PORT:=5432}
		DATABASE=${DATABASE_NAME}
		USERNAME=${DATABASE_USER}
		PASSWORD=${DATABASE_PASS}
		EOF
	fi
)

(
	while read driver; do
		ODBC_DRIVER="${driver}"
		break
	done <<<`find /usr -name 'libmsodbcsql*'`

	set -o pipefail

	if test "${DBACCESS_DRIVER,,}" == "mssql"; then
		ADD_DRIVER="-c /usr/lib64/libodbc.so"

		cat <<-EOF | tee /etc/odbc.ini
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
)

rm dbaccess.ini || true
../tools/dbaccesscfg \
	-u ${DATABASE_USER} \
	-p ${DATABASE_PASS} \
	-a ${DBACCESS_ALIAS} \
	-d ${DBACCESS_DRIVER} \
	${ADD_DRIVER} \
	-o "LICENSESERVER=${LICENSE_SERVER};LICENSEPORT=${LICENSE_PORT:=5555}"

cat dbaccess.ini
exec ./dbaccess64
