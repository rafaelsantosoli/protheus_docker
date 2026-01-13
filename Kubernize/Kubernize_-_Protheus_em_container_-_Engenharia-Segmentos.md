---
titulo: Kubernize - Protheus em container - Engenharia-Segmentos
fonte: https://tdn.totvs.com/display/public/EN/Kubernize+-+Protheus+em+container
data_conversao: 2026-01-13 13:55:25
---

# Kubernize - Protheus em container - Engenharia-Segmentos

# 1. Visão Geral

O projeto **Kubernize Protheus** tem como objetivo configurar os serviços **DBAccess**, **Protheus**, **License Server** e **TSS** para execução em um ambiente de contêineres, utilizando o **Docker** como tecnologia de containerização e o **Kubernetes** como plataforma de orquestração. Essa abordagem permitirá maior escalabilidade, portabilidade, resiliência e gerenciamento simplificado, atendendo às necessidades modernas de infraestrutura e operação em ambientes **on-premises**, **cloud** ou **híbridos**.

# 2. Imagens Docker

As imagens Docker do projeto **Kubernize Protheus** representam os principais serviços que compõem o **Protheus**, organizados de forma padronizada para atender diferentes tipos de build. Essa estrutura facilita sua utilização em diversos ambientes, como desenvolvimento, testes e produção

## 2.1 Distribuição Linux

As imagens são baseadas na distribuição **Oracle Linux 8**, na variante **slim-fips**, otimizada para ambientes de produção, oferecendo compatibilidade binária com o **Red Hat Enterprise Linux (RHEL)** e suporte a padrões de segurança **FIPS 140-2**, além de um tamanho reduzido para maior eficiência.

Além disso, as imagens configuram diretórios e usuários específicos para a aplicação, garantindo maior organização e segurança:

- Diretórios de trabalho:
  - /opt/totvs/protheus
  - /opt/totvs/dbaccess
  - /opt/totvs/license
  - /opt/totvs/tss
- Estrutura padronizada de diretórios para configuração do volume e gerenciamento de atualizações de artefatos.
- Usuário configurado:
  - totvs: Usuário sem login (/sbin/nologin), utilizado para reforçar a segurança do ambiente.

## 2.2 Builds

As builds definem o estado e a finalidade de cada versão da imagem Docker:

- **next**:

  - Versão liberada pela TOTVSTEC para ser testada pelo time de automação da engenharia Protheus.
  - Tag: Possui o sufixo **-next** (exemplo: **12.1.2410-next**).
- **latest**:

  - Última versão estável homologada pelo time de automação da engenharia Protheus.
  - Tag: Possui o sufixo **-latest** (exemplo: **12.1.2410-latest**).
- **published**:

  - Versão oficialmente aprovada, pronta para ampla distribuição
  - Tag: Não possui sufixo adicional (exemplo: **12.1.2410**).

Para os serviços **License Server** e **TSS**, a versão da tag será definida pelo time responsável pelo produto, e a distribuição da imagem sempre ocorrerá de forma oficial, ou seja, na versão **published**.

## 2.3 Versões Disponíveis

As imagens estão inicialmente publicadas no **[docker.totvs.io](http://docker.totvs.io)**, destinadas ao **uso interno** pelos times de desenvolvimento do Protheus, engenharia Protheus e TOTVS Cloud.

| Serviço | Tag Docker | Comando de Pull |
| --- | --- | --- |
| Protheus | 12.1.2210-next | docker pull docker.totvs.io/totvs-images/protheus:12.1.2210-next |
| 12.1.2210-latest | docker pull docker.totvs.io/totvs-images/protheus:12.1.2210-latest |
| 12.1.2210 | docker pull docker.totvs.io/totvs-images/protheus:12.1.2210 |
| 12.1.2310-next | docker pull docker.totvs.io/totvs-images/protheus:12.1.2310-next |
| 12.1.2310-latest | docker pull docker.totvs.io/totvs-images/protheus:12.1.2310-latest |
| 12.1.2310 | docker pull docker.totvs.io/totvs-images/protheus:12.1.2310 |
| 12.1.2410-next | docker pull docker.totvs.io/totvs-images/protheus:12.1.2410-next |
| 12.1.2410-latest | docker pull docker.totvs.io/totvs-images/protheus:12.1.2410-latest |
| 12.1.2410 | docker pull docker.totvs.io/totvs-images/protheus:12.1.2410 |
| DBAccess | 12.1.2210-next | docker pull docker.totvs.io/totvs-images/dbaccess:12.1.2210-next |
| 12.1.2210-latest | docker pull docker.totvs.io/totvs-images/dbaccess:12.1.2210-latest |
| 12.1.2210 | docker pull docker.totvs.io/totvs-images/dbaccess:12.1.2210 |
| 12.1.2310-next | docker pull docker.totvs.io/totvs-images/dbaccess:12.1.2310-next |
| 12.1.2310-latest | docker pull docker.totvs.io/totvs-images/dbaccess:12.1.2310-latest |
| 12.1.2310 | docker pull docker.totvs.io/totvs-images/dbaccess:12.1.2310 |
| 12.1.2410-next | docker pull docker.totvs.io/totvs-images/dbaccess:12.1.2410-next |
| 12.1.2410-latest | docker pull docker.totvs.io/totvs-images/dbaccess:12.1.2410-latest |
| 12.1.2410 | docker pull docker.totvs.io/totvs-images/dbaccess:12.1.2410 |
| TSS | v12.1.2410-3.0 | docker pull docker.totvs.io/totvs-images/tss:v12.1.2410-3.0 |
| v12.1.2310-3.0 | docker pull docker.totvs.io/totvs-images/tss:v12.1.2310-3.0 |
| License Server | v3.6.3_1 | docker pull docker.totvs.io/totvs-images/license:v3.6.3_1 |

## 2.4 Variáveis de ambiente das imagens

As variáveis de ambiente configuram os serviços nos contêineres, garantindo inicialização e operação adequadas. Cada imagem (**DBAccess, Protheus e TSS**) possui parâmetros específicos essenciais para seu funcionamento.

- **DBAccess**
  - LICENSE_SERVER: Define o endereço ou nome do servidor responsável pelas licenças.
  - LICENSE_PORT: Especifica a porta utilizada para comunicação com o servidor de licenças.
  - DBACCESS_DATABASE: Define o tipo de banco de dados a ser utilizado (**POSTGRES**, **MSSQL** ou **ORACLE**).
  - Variáveis específicas por banco de dados:
    - **PostgreSQL**: POSTGRES_SERVER, POSTGRES_PORT, POSTGRES_DATABASE, POSTGRES_USER, POSTGRES_PASS.
    - **MSSQL**: MSSQL_SERVER, MSSQL_PORT, MSSQL_DATABASE, MSSQL_USER, MSSQL_PASS.
    - **Oracle**: ORACLE_SERVER, ORACLE_PORT, ORACLE_USER, ORACLE_PASS, ORACLE_SERVICE (opcional), ORACLE_SID (opcional).
  - COMMAND_PRE: Comando opcional a ser executado antes da inicialização.
- **Protheus**
  - LICENSE_SERVER: Define o endereço ou nome do servidor responsável pelas licenças.
  - LICENSE_PORT: Especifica a porta utilizada para comunicação com o servidor de licenças.
  - DBACCESS_SERVER: Endereço do servidor do **DBAccess.**
  - DBACCESS_PORT: Porta utilizada pelo **DBAccess.**
  - DBACCESS_DATABASE: Tipo de banco de dados utilizado (**POSTGRES**, **MSSQL**, **ORACLE**).
  - DBACCESS_ALIAS: Alias do banco de dados configurado.
  - COMMAND_PRE: Comando que será executado antes da inicialização.
- **TSS**
  - DBACCESS_SERVER: Endereço do servidor do **DBAccess.**
  - DBACCESS_PORT: Porta utilizada pelo **DBAccess.**
  - DBACCESS_DATABASE: Tipo de banco de dados utilizado (**POSTGRES**, **MSSQL**, **ORACLE**).
  - DBACCESS_ALIAS: Alias do banco de dados configurado.
  - COMMAND_PRE: Comando que será executado antes da inicialização.

## 2.5 Utilização de imagens com docker run

A forma mais simples de testar o funcionamento das imagens do **License Server, DBAccess, Protheus e TSS** é utilizando o comando **docker run**. Esse método permite executar os contêineres diretamente, facilitando a validação do ambiente antes de configurar um orquestrador como **Docker Swarm** ou **Kubernetes**.

Os exemplos a seguir demonstram como iniciar cada serviço individualmente.

**docker run license** Expandir origem

```
docker run --rm -it docker.totvs.io/totvs-images/license:v3.6.3_1
```

**docker run dbaccess** Expandir origem

```
docker run --rm -it \
-e LICENSE_SERVER=license \
-e LICENSE_PORT=5555 \
-e DBACCESS_DATABASE=POSTGRES \
-e POSTGRES_SERVER=postgres \
-e POSTGRES_PORT=5432 \
-e POSTGRES_DATABASE=protheus1212410 \
-e POSTGRES_USER=protheus \
-e POSTGRES_PASS=Protheus.123 \
-e DBACCESS_ALIAS=P1212410 \
docker.totvs.io/totvs-images/dbaccess:12.1.2410
```

**docker run protheus** Expandir origem

```
docker run --rm -it \
-e LICENSE_SERVER=license \
-e LICENSE_PORT=5555 \
-e DBACCESS_SERVER=dbaccess \
-e DBACCESS_PORT=7890 \
-e DBACCESS_DATABASE=POSTGRES \
-e DBACCESS_ALIAS=P1212410 \
docker.totvs.io/totvs-images/protheus:12.1.2410
```

**docker run tss** Expandir origem

```
docker run --rm -it \
-e DBACCESS_SERVER=dbaccess \
-e DBACCESS_PORT=7890 \
-e DBACCESS_DATABASE=POSTGRES \
-e DBACCESS_ALIAS=P1212410 \
-e TSS_HOSTNAME=tss \
-e TSS_PORT=8080 \
docker.totvs.io/totvs-images/tss:v12.1.2410-3.0
```

## 2.6 Novo Controle de Lock e Numeração Automática via DBAccess

A partir da **lib 20251006**, disponível na **release 12.1.2510 do Protheus**, o controle de concorrência realizado pelas funções **LockByName** e **GetSXENum** pode ser feito diretamente via serviço **DBAccess**, substituindo o controle anterior via **License Server**.

**Como habilitar?**Via variável de ambiente (recomendado para containers):

```
export LOCK_NUM_ON_DB=1
```

Essa configuração torna-se global para os serviços executados no mesmo **host/container**, sendo ideal em ambientes com **Docker** ou orquestrados com **Kubernetes**.

**Arquivo <nome_do_banco>_dbnumber.val - Confirmação de Controle Ativo pelo DBAccess**

Quando o controle de numeração **(LOCK_NUM_ON_DB=1)** está habilitado e funcionando corretamente via **DBAccess**, um arquivo com **extensão .val** é criado dinamicamente no diretório de execução do serviço.

Esse arquivo serve como evidência de que o controle de numeração está sendo gerenciado diretamente pelo **DBAccess**, substituindo o modelo anterior baseado no **License Server**.

**Saiba Mais**

- [Controle de lock e numeração automática via DBAccess](https://tdn.totvs.com/pages/releaseview.action?pageId=928946197)
- [Manutenção de numeração automática](https://tdn.totvs.com/pages/releaseview.action?pageId=928951733)
- [ImportLSNumber - Importação de numeração do License Server para o DBAccess](https://tdn.totvs.com/pages/releaseview.action?pageId=947322766)

# 3. Utilização das Imagens com Docker Swarm

Este guia descreve o uso das imagens Docker do **Protheus, DBAccess, PostgreSQL 16, License Server** e **TSS** no **Docker Swarm**, proporcionando um ambiente distribuído e escalável para os serviços.

O ambiente será configurado automaticamente utilizando os artefatos do **release 12.1.2410**, disponíveis em **[arte.engpro.totvs.com.br](http://arte.engpro.totvs.com.br)**.

Como o **License Server** será inicializado sem licenças na primeira execução do Protheus, a empresa **99** será utilizada para testes locais.

## 3.1 Instalação do Docker Swarm

O **Docker Swarm** é um modo de orquestração nativo do Docker, permitindo o gerenciamento distribuído e escalável de serviços em múltiplos nós.

Caso o **Docker Swarm** ainda não esteja iniciado no ambiente, execute o seguinte comando para inicializá-lo no nó principal:

```
docker swarm init --advertise-addr $(hostname -I | awk '{print $1}')
```

Para verificar se o **Docker Swarm** foi instalado e iniciado corretamente, execute o seguinte comando no nó manager:

```
docker node ls
```

## 3.2 Configurar Variáveis de Ambiente

Caso esteja fora da rede da TOTVS ou não conectado à VPN, é necessário exportar as variáveis de ambiente para acessar os artefatos hospedados em **[arte.engpro.totvs.com.br](http://arte.engpro.totvs.com.br)**:

```
export ARTE_USER=<seu_usuario>
export ARTE_PASS=<sua_senha>
```

Se estiver na VPN ou dentro da rede interna da TOTVS, este passo não é necessário.

## 3.3 Executar o Script de Inicialização (swarm.sh)

O script **swarm.sh** é responsável por iniciar todos os serviços necessários para o funcionamento do **Protheus** dentro do **Docker Swarm**. Para executá-lo, siga os passos abaixo:

1. Salve arquivo **swarm.sh** no seu ambiente.

   **swarm.sh** Expandir origem

   ```
   #!/bin/sh
   set -e

   DT=$(date +%Y%m%d%H%M%S)

   #############
   ## starter.sh
   #############

   docker config create protheus_starter_${DT} - <<EOF
   set -e

   export IMAGE_VOLUME=/opt/totvs/protheus/volume

   if test ! -f \${IMAGE_VOLUME}/current/control/STARTED; then
   	AUTHORIZATION=\$(printf "%s:%s" "\${ARTE_USER}" "\${ARTE_PASS}" | base64)
   	AUTHORIZATION=\$(printf "Authorization: basic %s" "\${AUTHORIZATION}")

   	wget --header "\${AUTHORIZATION}" \\
   		-O \${IMAGE_VOLUME}/current/apo/tttm120.rpo \\
   		"https://arte.engpro.totvs.com.br/protheus/padrao/builds/12.1.2410/published/repositorio/panthera_onca/tttm120.rpo"

   	wget --header "\${AUTHORIZATION}" \\
   		-O /tmp/dicionario.zip \\
   		"https://arte.engpro.totvs.com.br/protheus/padrao/builds/12.1.2410/published/dicionario/dicionario_de_dados/completo/BRA-DICIONARIOS_COMPL.ZIP"

   	wget --header "\${AUTHORIZATION}" \\
   		-O /tmp/help.zip \\
   		"https://arte.engpro.totvs.com.br/protheus/padrao/builds/12.1.2410/published/dicionario/help_de_campo/completo/BRA-HELPS_COMPL.ZIP"

   	wget --header "\${AUTHORIZATION}" \\
   		-O /tmp/menu.zip \\
   		"https://arte.engpro.totvs.com.br/protheus/padrao/builds/12.1.2410/published/dicionario/menus/BRA-MENUS.ZIP"

   	unzip -o /tmp/dicionario.zip -d \${IMAGE_VOLUME}/current/protheus_data/systemload
   	unzip -o /tmp/help.zip -d \${IMAGE_VOLUME}/current/protheus_data/systemload
   	unzip -o /tmp/menu.zip -d \${IMAGE_VOLUME}/current/protheus_data/system

   	touch \${IMAGE_VOLUME}/current/control/STARTED
   fi
   EOF

   ##############
   ## postgres.sh
   ##############

   docker config create postgres_starter_${DT} - <<EOF
   set -e

   export PGPASSWORD="\${POSTGRES_PASSWORD}"

   until psql -h postgres -U postgres -W -l; do
   	sleep 1
   done

   psql -h postgres -U postgres postgres <<EOSQL
       CREATE USER "\${PROTHEUS_USER}"
           WITH LOGIN
           NOSUPERUSER
           INHERIT CREATEDB
           NOCREATEROLE
           NOREPLICATION
           CONNECTION LIMIT -1
           PASSWORD '\${PROTHEUS_PASS}';
       CREATE DATABASE "\${PROTHEUS_DATABASE}"
           WITH OWNER "\${PROTHEUS_USER}"
           TEMPLATE template0
           ENCODING 'WIN1252'
           LC_COLLATE 'C'
           LC_CTYPE 'C'
           CONNECTION LIMIT=-1;
       GRANT ALL PRIVILEGES \\
           ON DATABASE "\${PROTHEUS_DATABASE}"
   	TO "\${PROTHEUS_USER}";
   EOSQL

   psql -h postgres -U postgres "\${PROTHEUS_DATABASE}" <<EOSQL
       CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
   EOSQL
   EOF

   ##################
   ## docker stack up
   ##################

   LICENSE_SERVER="license"
   LICENSE_PORT="5555"

   DBACCESS_DATABASE="POSTGRES"
   DBACCESS_SERVER="dbaccess"
   DBACCESS_PORT="7890"
   DBACCESS_ALIAS="PROTHEUS1212410"

   POSTGRES_SERVER="postgres"
   POSTGRES_PORT="5432"
   POSTGRES_DATABASE="protheus"
   POSTGRES_USER="protheus"
   POSTGRES_PASS="Protheus.123"

   # senha do usuario postgres
   POSTGRES_PASSWORD=postgres

   docker stack up -c - protheus <<EOF
   version: "3.6"

   services:
     license:
       image: "docker.totvs.io/totvs-images/license:v3.6.3_1"
       volumes:
       - "license_data:/opt/totvs/license/volume"
       environment:
       - "TZ=America/Sao_Paulo"
       - "LC_ALL=pt_BR"
     protheus:
       image: "docker.totvs.io/totvs-images/protheus:12.1.2410"
       volumes:
       - "protheus_data:/opt/totvs/protheus/volume"
       ports:
       - "8080"
       - "1234"
       environment:
       - "TZ=America/Sao_Paulo"
       - "LC_ALL=pt_BR"
       - "LICENSE_SERVER=${LICENSE_SERVER}"
       - "LICENSE_PORT=${LICENSE_PORT}"
       - "DBACCESS_DATABASE=${DBACCESS_DATABASE}"
       - "DBACCESS_SERVER=${DBACCESS_SERVER}"
       - "DBACCESS_PORT=${DBACCESS_PORT}"
       - "DBACCESS_ALIAS=${DBACCESS_ALIAS}"
     dbaccess:
       image: "docker.totvs.io/totvs-images/dbaccess:12.1.2410"
       environment:
       - "TZ=America/Sao_Paulo"
       - "LC_ALL=pt_BR"
       - "LICENSE_SERVER=${LICENSE_SERVER}"
       - "LICENSE_PORT=${LICENSE_PORT}"
       - "DBACCESS_DATABASE=${DBACCESS_DATABASE}" 
       - "DBACCESS_ALIAS=${DBACCESS_ALIAS}"
       - "POSTGRES_SERVER=${POSTGRES_SERVER}"
       - "POSTGRES_PORT=${POSTGRES_PORT}"
       - "POSTGRES_DATABASE=${POSTGRES_DATABASE}"
       - "POSTGRES_USER=${POSTGRES_USER}"
       - "POSTGRES_PASS=${POSTGRES_PASS}"
       - "DBACCESS_1=[POSTGRES]CLIENTLIBRARY=/usr/lib64/libodbc.so.2.0.0"
     tss:
       image: docker.totvs.io/totvs-images/tss:v12.1.2410-3.0
       volumes:
       - "tss_data:/opt/totvs/tss/volume"
       ports:
       - "4321"
       environment:
       - "TZ=America/Sao_Paulo"
       - "LC_ALL=pt_BR"
       - "LICENSE_SERVER=${LICENSE_SERVER}"
       - "LICENSE_PORT=${LICENSE_PORT}"
       - "DBACCESS_DATABASE=${DBACCESS_DATABASE}"
       - "DBACCESS_SERVER=${DBACCESS_SERVER}"
       - "DBACCESS_PORT=${DBACCESS_PORT}"
       - "DBACCESS_ALIAS=${DBACCESS_ALIAS}"
     postgres:
       image: "postgres:16"
       volumes:
       - "postgres_data:/var/lib/postgresql/data"
       environment:
       - "TZ=America/Sao_Paulo"
       - "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}"
     postgres-start-container:
       image: "postgres:16"
       deploy:
         restart_policy:
           condition: "on-failure"
       command:
       - "/bin/sh"
       - "/postgres.sh"
       configs:
       - source: "postgres_starter_${DT}"
         target: "/postgres.sh"
       environment:
       - "PROTHEUS_DATABASE=${POSTGRES_DATABASE}"
       - "PROTHEUS_USER=${POSTGRES_USER}"
       - "PROTHEUS_PASS=${POSTGRES_PASS}"
       - "POSTGRES_PASSWORD=${POSTGRES_PASSWORD}"
     protheus-start-container:
       image: "alpine"
       deploy:
         restart_policy:
           condition: "on-failure"
       user: "1000:1000"
       command:
       - "/bin/sh"
       - "/starter.sh"
       configs:
       - source: "protheus_starter_${DT}"
         target: "/starter.sh"
       volumes:
       - "protheus_data:/opt/totvs/protheus/volume"
       environment:
       - "ARTE_USER=${ARTE_USER}"
       - "ARTE_PASS=${ARTE_PASS}"

   configs:
     postgres_starter_${DT}:
       external: true
     protheus_starter_${DT}:
       external: true

   volumes:
     license_data:
     protheus_data:
     postgres_data:
     tss_data:
   EOF
   ```
2. Execute o script no terminal do Linux usando o comando:

   ```
   bash swarm.sh
   ```

Esse processo iniciará os serviços essenciais, como **Protheus**, **DBAccess**, **License Server** e **PostgreSQL**, garantindo que o ambiente do Protheus seja configurado automaticamente.

## 3.4 Acompanhar a Subida dos Contêineres

Verifique o status dos serviços rodando:

```
watch docker ps
```

Esse comando atualiza a saída periodicamente, permitindo acompanhar a subida dos contêineres.

![](/download/attachments/904051127/image-2025-3-10_17-1-30.png?version=1&modificationDate=1741636892043&api=v2)

## 3.5 Obter a porta do Protheus

Para descobrir a porta onde o **Protheus** está ouvindo:

```
docker service ls
```

# 4. Utilização das Imagens com Kubernetes

Este guia descreve o uso das imagens Docker do **Protheus, DBAccess, PostgreSQL 16, License Server** e **TSS** no **Kubernetes**, proporcionando um ambiente distribuído e escalável para os serviços.

O ambiente deve ser executado em um **Kubernetes** previamente configurado.

Os artefatos do release **12.1.2410**, disponíveis em **[arte.engpro.totvs.com.br](http://arte.engpro.totvs.com.br)**, serão utilizados para configuração automática.  
  
Como o **License Server** será inicializado sem licenças na primeira execução do **Protheus**, a empresa **99** será utilizada para testes locais.

## 4.1 Salvar arquivo kubernetes.yaml

O arquivo kubernetes.yaml contém toda a configuração necessária para a implantação do ambiente **Protheus** no **Kubernetes**, garantindo escalabilidade, segurança e organização. O arquivo está estruturado com os seguintes componentes:

- **PersistentVolumeClaim (PVC):**

  - Define o volume persistente para armazenar dados do **Protheus**, **License Server**, **TSS** e **PostgreSQL**, garantindo a integridade das informações entre reinicializações dos contêineres.
- **Secrets:**

  - Armazena credenciais sensíveis, como **usuários e senhas** do PostgreSQL e acesso ao repositório TOTVS.
- **ConfigMaps:**

  - environment-configure: Contém configurações essenciais, como servidores, portas e credenciais de banco de dados.
  - environment-scripts: Armazena scripts de inicialização dos serviços **Protheus** e **PostgreSQL**, garantindo que as dependências sejam corretamente configuradas antes da execução.
- **Deployments:**

  - License Server
  - PostgreSQL
  - DBAccess
  - Protheus
  - TSS
- **Services:**

  - Define os acessos aos serviços por meio de **ClusterIP** e **NodePort**, possibilitando a comunicação interna e externa entre os componentes.

Crie o arquivo e adicione a configuração abaixo:

**kubernetes.yaml** Expandir origem

```
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-protheus
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi

---
apiVersion: v1
kind: Secret
metadata:
  name: "secret-environment"
type: Opaque
stringData:
  ARTE_USER: "nouser"
  ARTE_PASS: "nopass"
  POSTGRES_USER: "protheus"
  POSTGRES_PASS: "Protheus.123"
  POSTGRES_PASSWORD: "postgres"

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: "config-environment"
data:
  LICENSE_SERVER: "license"
  LICENSE_PORT: "5555"
  DBACCESS_DATABASE: "POSTGRES"
  DBACCESS_SERVER: "dbaccess"
  DBACCESS_PORT: "7890"
  DBACCESS_ALIAS: "PROTHEUS1212410"
  POSTGRES_SERVER: "postgres"
  POSTGRES_PORT: "5432"
  POSTGRES_DATABASE: "protheus"
  TSS_HOSTNAME: "tss"
  TSS_PORT: "8080"

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: "config-scripts"
data:
  start-protheus.sh: |
    set -e
    
    export IMAGE_VOLUME=/opt/totvs/protheus/volume
    
    if test ! -f ${IMAGE_VOLUME}/current/control/STARTED; then
      curl -f -u "${ARTE_USER}:${ARTE_PASS}" \
    		-L "https://arte.engpro.totvs.com.br/protheus/padrao/builds/12.1.2410/published/repositorio/panthera_onca/tttm120.rpo" \
    		-o ${IMAGE_VOLUME}/current/apo/tttm120.rpo
    
    	curl -f -u "${ARTE_USER}:${ARTE_PASS}" \
    		-L "https://arte.engpro.totvs.com.br/protheus/padrao/builds/12.1.2410/published/dicionario/dicionario_de_dados/completo/BRA-DICIONARIOS_COMPL.ZIP" \
    		-o /tmp/dicionario.zip
    
    	curl -f -u "${ARTE_USER}:${ARTE_PASS}" \
    		-L "https://arte.engpro.totvs.com.br/protheus/padrao/builds/12.1.2410/published/dicionario/help_de_campo/completo/BRA-HELPS_COMPL.ZIP" \
    		-o /tmp/help.zip
    
    	curl -f -u "${ARTE_USER}:${ARTE_PASS}" \
    		-L "https://arte.engpro.totvs.com.br/protheus/padrao/builds/12.1.2410/published/dicionario/menus/BRA-MENUS.ZIP" \
    		-o /tmp/menu.zip
    
    	unzip -o /tmp/dicionario.zip -d ${IMAGE_VOLUME}/current/protheus_data/systemload
    	unzip -o /tmp/help.zip -d ${IMAGE_VOLUME}/current/protheus_data/systemload
    	unzip -o /tmp/menu.zip -d ${IMAGE_VOLUME}/current/protheus_data/system

      rm -f /tmp/dicionario.zip
      rm -f /tmp/help.zip
      rm -f /tmp/menu.zip
      
    	touch ${IMAGE_VOLUME}/current/control/STARTED
    fi

  start-postgres.sh: |
    set -e

    PROTHEUS_DB_SETUP_DONE="/var/lib/postgresql/data/.PROTHEUS_DB_SETUP_DONE"

    if [ -f "$PROTHEUS_DB_SETUP_DONE" ]; then
      echo "Postgres já configurado para o Protheus." 
      sleep infinity
    fi
    
    export PGPASSWORD="${POSTGRES_PASSWORD}"
    
    export PROTHEUS_DATABASE=${POSTGRES_DATABASE}
    export PROTHEUS_USER=${POSTGRES_USER}
    export PROTHEUS_PASS=${POSTGRES_PASS}
    
    until psql -h localhost -U postgres -W -l; do
    	sleep 1
    done
    
    psql -h localhost -U postgres postgres <<EOSQL
        CREATE USER "${PROTHEUS_USER}"
            WITH LOGIN
            NOSUPERUSER
            INHERIT CREATEDB
            NOCREATEROLE
            NOREPLICATION
            CONNECTION LIMIT -1
            PASSWORD '${PROTHEUS_PASS}';
        CREATE DATABASE "${PROTHEUS_DATABASE}"
            WITH OWNER "${PROTHEUS_USER}"
            TEMPLATE template0
            ENCODING 'WIN1252'
            LC_COLLATE 'C'
            LC_CTYPE 'C'
            CONNECTION LIMIT=-1;
        GRANT ALL PRIVILEGES \
            ON DATABASE "${PROTHEUS_DATABASE}"
    	TO "${PROTHEUS_USER}";
    EOSQL
    
    psql -h localhost -U postgres "${PROTHEUS_DATABASE}" <<EOSQL
        CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
    EOSQL

    touch "$PROTHEUS_DB_SETUP_DONE"
    
    sleep infinity

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: license
spec:
  selector:
    matchLabels:
      app: license
  template:
    metadata:
      labels:
        app: license
    spec:
      volumes:
      - name: kubernize-storage
        persistentVolumeClaim:
          claimName: pvc-protheus
      containers:
      - name: license
        image: docker.totvs.io/totvs-images/license:v3.6.3_1
        imagePullPolicy: "Always"
        volumeMounts:
        - name: kubernize-storage
          mountPath: /opt/totvs/license/volume
          subPath: license

---
apiVersion: v1
kind: Service
metadata:
  name: license
spec:
  type: ClusterIP
  selector:
    app: license
  ports:
    - name: tcp
      protocol: TCP
      port: 5555
      targetPort: 5555

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      volumes:
      - name: kubernize-storage
        persistentVolumeClaim:
          claimName: pvc-protheus
      - name: "config-scripts"
        configMap:
          name: "config-scripts"
          items:
          - key: "start-postgres.sh"
            path: "start-postgres.sh"
      containers:
      - name: start-postgres
        image: postgres:16
        envFrom:
        - secretRef:
            name: "secret-environment"
        - configMapRef:
            name: "config-environment"
        args: [ "/bin/bash", "/scripts/start-postgres.sh" ]
        volumeMounts:
        - name: "config-scripts"
          mountPath: "/scripts"
        - name: kubernize-storage
          mountPath: /var/lib/postgresql/data
          subPath: postgres
      - name: postgres
        image: postgres:16
        env:
        - name: "POSTGRES_PASSWORD"
          valueFrom:
            secretKeyRef:
              name: "secret-environment"
              key: "POSTGRES_PASSWORD"
        volumeMounts:
        - name: kubernize-storage
          mountPath: /var/lib/postgresql/data
          subPath: postgres
        readinessProbe:
          exec:
            command: [ "test", "-f", "/var/lib/postgresql/data/.PROTHEUS_DB_SETUP_DONE" ]
          initialDelaySeconds: 10
          periodSeconds: 5
          failureThreshold: 60

---
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  type: ClusterIP 
  selector:
    app: postgres
  ports:
    - name: tcp
      protocol: TCP
      port: 5432
      targetPort: 5432

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dbaccess
  labels:
    app: dbaccess
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dbaccess
  template:
    metadata:
      labels:
        app: dbaccess
    spec:
      initContainers:
      - name: wait-license
        image: alpine
        envFrom:
          - configMapRef:
              name: config-environment
        command:
          - sh
          - -c
          - |
            until nc -z "$LICENSE_SERVER" "$LICENSE_PORT"; do
              echo "Aguardando license server iniciar..."
              sleep 2
            done
      - name: wait-postgres
        image: alpine
        envFrom:
          - configMapRef:
              name: config-environment
        command:
          - sh
          - -c
          - |
            until nc -z "$POSTGRES_SERVER" "$POSTGRES_PORT"; do
              echo "Aguardando o servidor Postgres iniciar..."
              sleep 2
            done
      containers:
        - name: dbaccess
          image: docker.totvs.io/totvs-images/dbaccess:12.1.2410
          imagePullPolicy: "Always"
          envFrom:
          - secretRef:
              name: "secret-environment"
          - configMapRef:
              name: "config-environment"
          env:
          - name: "DBACCESS_1"
            value: "[POSTGRES]CLIENTLIBRARY=/usr/lib64/libodbc.so.2.0.0"

---
apiVersion: v1
kind: Service
metadata:
  name: dbaccess
spec:
  type: ClusterIP
  selector:
    app: dbaccess
  ports:
    - name: tcp
      protocol: TCP
      port: 7890
      targetPort: 7890

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: "protheus"
spec:
  selector:
    matchLabels:
      app: protheus
  template:
    metadata:
      labels:
        app: protheus
    spec:
      volumes:
      - name: kubernize-storage
        persistentVolumeClaim:
          claimName: pvc-protheus
      - name: "config-scripts"
        configMap:
          name: "config-scripts"
          items:
          - key: "start-protheus.sh"
            path: "start-protheus.sh"
      initContainers:
      - name: wait-dbaccess
        image: alpine
        envFrom:
          - configMapRef:
              name: config-environment
        command:
          - sh
          - -c
          - |
            until nc -z "$DBACCESS_SERVER" "$DBACCESS_PORT"; do
              echo "Aguardando o servidor DBACCESS iniciar..."
              sleep 2
            done
      containers:
      - name: protheus
        image: docker.totvs.io/totvs-images/protheus:12.1.2410
        imagePullPolicy: "Always"
        envFrom:
        - configMapRef:
            name: "config-environment"
        env:
        - name: "ARTE_USER"
          valueFrom:
            secretKeyRef:
              name: "secret-environment"
              key: "ARTE_USER"
        - name: "ARTE_PASS"
          valueFrom:
            secretKeyRef:
              name: "secret-environment"
              key: "ARTE_PASS"
        - name: "COMMAND_PRE"
          value: "bash /scripts/start-protheus.sh"
        volumeMounts:
        - name: kubernize-storage
          mountPath: /opt/totvs/protheus/volume
          subPath: protheus
        - name: "config-scripts"
          mountPath: "/scripts"
        readinessProbe:
            exec:
              command: [ "test", "-f", "/opt/totvs/protheus/volume/current/control/STARTED" ]
            initialDelaySeconds: 5
            periodSeconds: 5
            failureThreshold: 60

---
apiVersion: v1
kind: Service
metadata:
  name: protheus
spec:
  type: NodePort 
  selector:
    app: protheus
  ports:
    - name: http
      protocol: TCP
      port: 8080
      targetPort: 8080

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: "tss"
spec:
  selector:
    matchLabels:
      app: tss
  template:
    metadata:
      labels:
        app: tss
    spec:
      volumes:
      - name: kubernize-storage
        persistentVolumeClaim:
          claimName: pvc-protheus
      initContainers:
      - name: wait-dbaccess
        image: alpine
        envFrom:
          - configMapRef:
              name: config-environment
        command:
          - sh
          - -c
          - |
            until nc -z "$DBACCESS_SERVER" "$DBACCESS_PORT"; do
              echo "Aguardando o servidor DBACCESS iniciar..."
              sleep 2
            done
      containers:
      - name: tss
        image: docker.totvs.io/totvs-images/tss:v12.1.2410-3.0
        imagePullPolicy: "Always"
        envFrom:
        - configMapRef:
            name: "config-environment"
        volumeMounts:
        - name: kubernize-storage
          mountPath: /opt/totvs/protheus/volume
          subPath: tss

---
apiVersion: v1
kind: Service
metadata:
  name: tss
spec:
  type: NodePort
  selector:
    app: tss
  ports:
    - name: http
      protocol: TCP
      port: 4321
      targetPort: 4321
```

## 4.2  Definir Credenciais ARTE_USER e ARTE_PASS

O Secret no Kubernetes é utilizado para armazenar informações sensíveis, como credenciais de acesso. Para garantir que os serviços acessem os artefatos corretamente, é necessário definir os valores de **ARTE_USER** e **ARTE_PASS**.

Abra o arquivo **kubernetes.yaml** e localize a configuração do **Secret environment-secret.**

**kubernetes.yaml** Expandir origem

```
---
apiVersion: v1
kind: Secret
metadata:
  name: "environment-secret"
type: Opaque
stringData:
  ARTE_USER: "nouser"
  ARTE_PASS: "nopass"
  POSTGRES_USER: "protheus"
  POSTGRES_PASS: "Protheus.123"
  POSTGRES_PASSWORD: "postgres"
```

## 4.3 Criar um Namespace para Isolar os Serviços

Criar um **namespace** permite organizar e isolar os serviços dentro do cluster **Kubernetes**, garantindo melhor gerenciamento e controle.

Para criar o namespace, execute o seguinte comando:

```
kubectl create namespace kubernize
```

## 4.4 Aplicar a Configuração no Kubernetes

O arquivo **kubernetes.yaml** precisa ser aplicado ao cluster **Kubernetes** para provisionar corretamente os recursos necessários ao ambiente **Protheus**.

```
kubectl apply -f kubernetes.yaml -n kubernize
```

![](/download/attachments/904051127/image-2025-3-10_18-14-27.png?version=1&modificationDate=1741641269603&api=v2)

## 4.5 Verificar a criação dos recursos

Após aplicar o arquivo **kubernetes.yaml**, utilize o comando abaixo para verificar se os **pods**, **serviços** e demais recursos foram criados corretamente:

```
kubectl get all -n kubernize
```

![](/download/attachments/904051127/image-2025-3-10_18-17-34.png?version=1&modificationDate=1741641456003&api=v2)

# 5. Inicialização do Protheus Empresa de Testes

Para iniciar o Protheus na empresa de testes, siga os passos abaixo:

1. Abra seu navegador e acesse o endereço:  
   **[http://localhost:porta](http://localhostporta)** (substitua "porta" pela porta configurada no ambiente para ambiente).
2. Na tela do **TOTVS SmartClient HTML**, selecione o programa inicial **SIGACFG**.
3. Escolha o ambiente do servidor correspondente à empresa de testes.
4. Clique em **OK** para iniciar o configurador.

# 

## 5.1 Criação da Empresa de Testes 99

Após iniciar o configurador **SIGACFG**, siga as etapas para criar a empresa de testes:

1. Na tela **Criação de Empresa**, selecione a opção **Criar empresa TESTE**.
2. Clique em **Selecionar** para continuar com a configuração.

![](/download/attachments/904051127/image-2025-2-7_10-16-54.png?version=1&modificationDate=1738934215567&api=v2)

## 5.2 Criação da Empresa de Testes 99

Após criar a empresa de testes, siga os passos abaixo para definir a localização:

1. Na tela **Selecione a Localização**, escolha o país **Brasil** para a configuração da empresa de testes.
2. Clique em **OK** para confirmar e continuar com a configuração.

![](/download/attachments/904051127/image-2025-2-7_10-20-42.png?version=1&modificationDate=1738934443253&api=v2)

## 5.3 Configuração Inicial do Protheus

Após definir a localização, o sistema redirecionará para a tela de login do **TOTVS Protheus**. Siga os passos abaixo para o primeiro acesso:

1. No campo **Usuário**, informe: **Admin**.
2. No campo **Senha**, deixe em branco (campo vazio).
3. Clique em **Entrar** para acessar o sistema.
4. No primeiro login, o sistema solicitará a criação de uma nova senha. Defina e confirme a alteração.
5. Após o login, acesse o módulo do **Configurador** para prosseguir com a configuração do ambiente.
6. Na tela de **Definição de Tipo de Ambiente**, selecione **3 - Desenvolvimento** e clique em **Confirmar**.
7. Confirme que o módulo **Configurador** abriu corretamente e, para testar o ambiente, acesse o módulo de Faturamento (ou outro desejado) para utilização.

![](/download/attachments/904051127/image-2025-2-7_10-43-59.png?version=1&modificationDate=1738935840360&api=v2)

![](/download/attachments/904051127/image-2025-2-7_10-45-10.png?version=1&modificationDate=1738935911990&api=v2)

# 6. Inicialização do TSS

Para iniciar o TSS, siga os passos abaixo:

1. Abra o navegador e acesse o endereço:  
   **[http://localhost:porta](http://localhostporta)** (substitua "porta" pela porta configurada no ambiente para ambiente).
2. Na tela do **TOTVS SmartClient HTML**, selecione o programa inicial **TSSMONITOR**.
3. Escolha o ambiente do servidor **SPED**.
4. Clique em **OK** para iniciar o configurador.
5. Na tela de login, digite:

   - **Usuário:** ADMIN
   - **Senha:** ADMIN
6. Altere a senha no primeiro login.
7. Configure o TSS conforme a documentação oficial do time de produto.

![](/download/attachments/904051127/image-2025-3-10_17-22-13.png?version=1&modificationDate=1741638134897&api=v2)

![](/download/attachments/904051127/image-2025-3-10_17-26-42.png?version=1&modificationDate=1741638404180&api=v2)

![](/download/attachments/904051127/image-2025-3-10_17-28-26.png?version=1&modificationDate=1741638508493&api=v2)

![](/download/attachments/904051127/image-2025-3-10_17-30-46.png?version=1&modificationDate=1741638648560&api=v2)