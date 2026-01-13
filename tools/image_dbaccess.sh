#!/bin/bash
set -e

cd /opt/totvs/dbaccess/multi

(
	set -o pipefail

	cat <<-EOF | tee ${TNS_ADMIN}/tnsnames.ora
	PROTHEUS= 
	(DESCRIPTION = 
	  (ADDRESS = (PROTOCOL = TCP)(HOST = ${DATABASE_HOST})(PORT = ${DATABASE_PORT:=1521}))
	  (CONNECT_DATA =
	    (SERVER = DEDICATED)
	    (SERVICE_NAME = ${DATABASE_NAME})
	  )
	)
	EOF
)

(
	set -o pipefail

	if test "${DBACCESS_DRIVER,,}" == "postgres"; then
		cat <<-EOF | tee /etc/odbc.ini
		[${DBACCESS_ALIAS}]
		DRIVER=/usr/lib64/psqlodbcw.so
		SERVERNAME=${DATABASE_HOST}
		PORT=${DATABASE_PORT:=5432}
		DATABASE=${DATABASE_NAME}
		USERNAME=${DATABASE_USER}
		PASSWORD=${DATABASE_PASS}
		EOF
	fi
)

(
	set -o pipefail

	if test "${DBACCESS_DRIVER,,}" == "mssql"; then
		cat <<-EOF | tee /etc/odbc.ini
		[${DBACCESS_ALIAS}]
		DRIVER=/usr/lib64/libmsodbcsql-18.so
		SERVER=${DATABASE_HOST}
		PORT=${DATABASE_PORT:=1433}
		DATABASE=${DATABASE_NAME}
		UID=${DATABASE_USER}
		PWD=${DATABASE_PASS}
		TRUSTSERVERCERTIFICATE=YES
		EOF
	fi
)

../tools/dbaccesscfg \
	-u ${DATABASE_USER} \
	-p ${DATABASE_PASS} \
	-a ${DBACCESS_ALIAS} \
	-d ${DBACCESS_DRIVER} \
	-c '/usr/lib64/libodbc.so' \
	-o "LICENSESERVER=${LICENSE_SERVER};LICENSEPORT=${LICENSE_PORT:=5555}"

cat dbaccess.ini
exec ./dbaccess64
