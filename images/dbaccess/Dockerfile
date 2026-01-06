FROM oraclelinux:8

ENV ACCEPT_EULA=Y \
	ORACLE_HOME=/opt/oracle/instantclient_21_5

RUN curl https://packages.microsoft.com/config/rhel/8/prod.repo \
		| tee /etc/yum.repos.d/mssql-release.repo \
	&& yum install \
		unzip \
		unixODBC-devel \
		postgresql-odbc \
		msodbcsql18 \
	&& mkdir -p /opt/oracle \
	&& cd /opt/oracle \
	&& curl -LO https://download.oracle.com/otn_software/linux/instantclient/215000/instantclient-basic-linux.x64-21.5.0.0.0dbru.zip \
	&& unzip instantclient-basic-linux.x64-21.5.0.0.0dbru.zip \
	&& rm -rf *.zip

ENV LD_LIBRARY_PATH=${ORACLE_HOME}:${LD_LIBRARY_PATH} \
	PATH=${ORACLE_HOME}:/opt/mssql-tools18/bin:${PATH} \
	TNS_ADMIN=${ORACLE_HOME}/network/admin
