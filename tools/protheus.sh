#!/bin/bash
set -e

if test "$(id -u)" != 0; then
	exec bash /local/bin/tool_image_protheus.sh
fi

cd ${APPSERVER_HOME}

while read apo; do
    RPO_PATH=`dirname ${apo}`
    RPO_FILE=`basename ${apo}`
    break
done <<<`find ${PROTHEUS_HOME} -name 'tt*.rpo'`

while read protheus_data; do
    PROTHEUS_DATA_PATH="${protheus_data}"
    break
done <<<`find ${PROTHEUS_HOME} -name 'protheus_data'`

(
set -o pipefail

cat <<EOF | tee appserver.ini
[ENVIRONMENT]
RPODB=${RPO_FILE:2:1}
RPOVERSION=${RPO_FILE:4:3}
RPOLANGUAGE=${RPO_FILE:3:1}
SOURCEPATH=${RPO_PATH}
ROOTPATH=${PROTHEUS_DATA_PATH}
STARTPATH=/system
DBSERVER=${DBSERVER}
DBPORT=${DBPORT:=7890}
DBDATABASE=${DBDATABASE}
DBALIAS=${DBALIAS}
REGIONALLANGUAGE=${REGIONALLANGUAGE}
TOPMEMOMEGA=10
SPECIALKEY=meuenv
STARTSYSINDB=1
DARK=1

[GENERAL]
BUILDKILLUSERS=1
CONSOLELOG=1
CONSOLEFILE=/tmp/console.log
MAXSTRINGSIZE=10

[DRIVERS]
ACTIVE=TCP

[TCP]
TYPE=TCPIP
PORT=1234

[WEBAPP]
ENABLE=1
PORT=8080

[LOCKSERVER]
ENABLE=1
SERVER=$(ip route get 8.8.8.8 | awk '/src/{print($7)}')
PORT=1234

[LICENSECLIENT]
SERVER=${LICENSE_SERVER}
PORT=${LICENSE_PORT:-5555}

[WEBAPP/WEBAPP]
MPP=

[WEBMONITOR]
ENABLE=0

[APP_MONITOR]
ENABLE=0
PORT=50034
GUI=1
EOF
)

exec ./appsrvlinux
