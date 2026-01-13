#!/bin/bash
set -e

# Garante que o diretório de dumps tenha permissões adequadas
chmod 777 /local/data/totvs/dumps 2>/dev/null || true
chmod 644 /local/data/totvs/dumps/*.dmp 2>/dev/null || true
chmod 644 /local/data/totvs/dumps/*.DMP 2>/dev/null || true

#impdp \
#	system/${ORACLE_PWD}@${ORACLE_PDB} \
#	DIRECTORY=DUMPS \
#	LOGTIME=ALL \
#	LOGFILE=${DATABASE_NAME} \
#	DUMPFILE=${DATABASE_NAME^^}_%U.dmp \
#	SQLFILE=${DATABASE_NAME}

impdp \
	${DATABASE_USER}/${DATABASE_PASS}@${ORACLE_PDB} \
	DIRECTORY=DUMPS \
	LOGTIME=ALL \
	LOGFILE=${DATABASE_NAME} \
	DUMPFILE=${DATABASE_NAME^^}_%U.dmp \
	TRANSFORM=TABLE_COMPRESSION_CLAUSE:"nocompress"
