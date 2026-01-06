#!/bin/bash
set -e

printf "Qual release do Protheus deseja utilizar?\n"
select release in 12.1.2210 12.1.2310 12.1.2410; do
	test "${release}" && break
	printf "opção invalida!\n"
done


printf "Qual banco de dados deseja utilizar?\n"
select banco_de_dados in postgres15 postgres16 mssql2019 mssql2022 oracle19; do
	test "${banco_de_dados}" && break
	printf "opção invalida!\n"
done


printf "Qual a expedição deseja utilizar?\n"
select expedicao in next latest published; do
	test "${expedicao}" && break
	printf "opção invalida!\n"
done


printf "Qual idioma deseja utilizar?\n"
select idioma in arg bra col mex per; do
	test "${idioma}" && break
	printf "opção invalida!\n"
done

case "${release}" in
	12.1.2210)
		animal=harpia
		rpo_file=tttm120.rpo
		;;
	12.1.2310)
		animal=harpia
		rpo_file=tttm120.rpo
		;;
	12.1.2410)
		animal=panthera_onca
		rpo_file=tttm120.rpo
		;;
esac

case "${banco_de_dados}" in
	postgres15)
		database="postgresql.zip"
		;;
	postgres16)
		database="postgresql.zip"
		;;
	mssql2019)
		database="mssql_bak.zip"
		;;
	mssql2022)
		database="mssql_bak.zip"
		;;
	oracle19)
		database="oracle.zip"
		;;
esac

case "${idioma}" in
	bra)
		tipo_congelada="exp_com_dic"
		tipo_protheus="padrao"
		;;
	*)
		tipo_congelada="mnt_com_dic"
		tipo_protheus="mi"
		;;
esac

APPSERVER_URL="https://arte.engpro.totvs.com.br/tec/appserver/${animal}/linux/64/${expedicao}/appserver.tar.gz"
WEBAPP_URL="https://arte.engpro.totvs.com.br/tec/smartclientwebapp/${animal}/linux/64/${expedicao}/smartclientwebapp.tar.gz"
PDFPRINTER_URL="https://arte.engpro.totvs.com.br/tec/pdfprinter/linux/64/${expedicao}/pdfprinter.tar.gz"
DBACCESS_URL="https://arte.engpro.totvs.com.br/tec/dbaccess/linux/64/${expedicao}/dbaccess.tar.gz"
PROTHEUS_URL="https://arte.engpro.totvs.com.br/protheus/${tipo_protheus}/builds/${release}/${expedicao}/repositorio/${animal}/${rpo_file}"
DICIONARIO_URL="https://arte.engpro.totvs.com.br/protheus/${tipo_protheus}/builds/${release}/published/dicionario/dicionario_de_dados/completo/${idioma}-DICIONARIOS_COMPL.ZIP"
HELP_URL="https://arte.engpro.totvs.com.br/protheus/${tipo_protheus}/builds/${release}/published/dicionario/help_de_campo/completo/${idioma}-HELPS_COMPL.ZIP"
MENU_URL="https://arte.engpro.totvs.com.br/protheus/${tipo_protheus}/builds/${release}/published/dicionario/menus/${idioma}-MENUS.ZIP"
CONGELADA_URL="https://arte.engpro.totvs.com.br/engenharia/base_congelada/protheus/${idioma}/${release}/${tipo_congelada}/latest/${database}"
PROTHEUSDATA_URL="https://arte.engpro.totvs.com.br/engenharia/base_congelada/protheus/${idioma}/${release}/${tipo_congelada}/latest/protheus_data.zip"

mkdir -p \
	data/downloads/ \
	data/totvs/dumps/ \
	data/totvs/appserver/ \
	data/totvs/dbaccess/configures/ \
	data/totvs/protheus/apo/ \
	data/totvs/protheus/protheus_data/ \
	data/totvs/protheus/protheus_data/system \
	data/totvs/protheus/protheus_data/systemload

touch data/totvs/dbaccess/configures/odbc.ini \
	data/totvs/dbaccess/configures/tnsnames.ora

chmod 0666 data/totvs/dbaccess/configures/odbc.ini \
	data/totvs/dbaccess/configures/tnsnames.ora

echo "Downloading ${APPSERVER_URL}"
curl -u "${ARTE_USER}:${ARTE_PASS}" -L "${APPSERVER_URL}" -o data/downloads/appserver.tar.gz -z data/downloads/appserver.tar.gz
tar xzvf data/downloads/appserver.tar.gz -C data/totvs/appserver/

echo "Donwloading ${WEBAPP_URL}"
curl -u "${ARTE_USER}:${ARTE_PASS}" -L "${WEBAPP_URL}" -o data/downloads/webapp.tar.gz -z data/downloads/webapp.tar.gz
tar xzvf data/downloads/webapp.tar.gz -C data/totvs/appserver/

echo "Downloading ${PDFPRINTER_URL}"
curl -u "${ARTE_USER}:${ARTE_PASS}" -L "${PDFPRINTER_URL}" -o data/downloads/pdfprinter.tar.gz -z data/downloads/pdfprinter.tar.gz
tar xzvf data/downloads/pdfprinter.tar.gz -C data/totvs/appserver/

echo "Downloading ${DBACCESS_URL}"
curl -u "${ARTE_USER}:${ARTE_PASS}" -L "${DBACCESS_URL}" -o data/downloads/dbaccess.tar.gz -z data/downloads/dbaccess.tar.gz
tar xzvf data/downloads/dbaccess.tar.gz -C data/totvs/dbaccess/
cp data/totvs/dbaccess/client/dbapi.so data/totvs/appserver/

rpo_file=`basename ${PROTHEUS_URL}`
echo "Downloading ${PROTHEUS_URL}"
curl -u "${ARTE_USER}:${ARTE_PASS}" -L "${PROTHEUS_URL}" -o data/downloads/${rpo_file} -z data/downloads/${rpo_file}
cp data/downloads/${rpo_file} data/totvs/protheus/apo/

dicionario_file=`basename ${DICIONARIO_URL}`
echo "Downloading ${DICIONARIO_URL}"
curl -u "${ARTE_USER}:${ARTE_PASS}" -L "${DICIONARIO_URL}" -o data/downloads/${dicionario_file} -z data/downloads/${dicionario_file}
unzip -o data/downloads/${dicionario_file} -d data/totvs/protheus/protheus_data/systemload/

help_file=`basename ${HELP_URL}`
echo "Downloading ${HELP_URL}"
curl -u "${ARTE_USER}:${ARTE_PASS}" -L "${HELP_URL}" -o data/downloads/${help_file} -z data/downloads/${help_file}
unzip -o data/downloads/${help_file} -d data/totvs/protheus/protheus_data/systemload/

menu_file=`basename ${MENU_URL}`
echo "Downloading ${MENU_URL}"
curl -u "${ARTE_USER}:${ARTE_PASS}" -L "${MENU_URL}" -o data/downloads/${menu_file} -z data/downloads/${menu_file}
unzip -o data/downloads/${menu_file} -d data/totvs/protheus/protheus_data/system/

congelada_file=`basename ${CONGELADA_URL}`
echo "Downloading ${CONGELADA_URL}"
curl -u "${ARTE_USER}:${ARTE_PASS}" -L "${CONGELADA_URL}" -o data/downloads/${congelada_file} -z data/downloads/${congelada_file}
(
	cd data/totvs/dumps
	unzip -o ../../downloads/${congelada_file} || 7z x ../../downloads/${congelada_file}
)
