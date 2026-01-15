# Protheus-dev

Ambiente de desenvolvimento totalmente integrado para TOTVS Protheus, usando Docker.

## 📋 Índice

- [Como usar](#como-usar)
- [Modo Kubernize (Imagens Oficiais)](#modo-kubernize-imagens-oficiais)
- [Variáveis de Ambiente](#variáveis-de-ambiente)
- [Estrutura do Projeto](#estrutura-do-projeto)
- [Troubleshooting](#troubleshooting)
- [Roadmap](#roadmap)

## Como usar

### 1. Configuração Inicial

```sh
# fazer o download dos artefatos (modo interativo)
bash tools/setup.sh create meu_ambiente

# OU modo atualização (para ambientes existentes)
bash tools/setup.sh update meu_ambiente

# gerar o docker-compose para o ambiente
bash tools/generate.sh meu_ambiente
```

### 2. Configurar variáveis de ambiente

Edite o arquivo `environments/meu_ambiente/config.env` para ajustar:
- `LICENSE_SERVER`: Servidor de licenças
- `LICENSE_PORT`: Porta do servidor de licenças

### 3. Iniciar o ambiente

```sh
cd environments/meu_ambiente

# iniciar todos os serviços
docker compose up -d --build

# verificar status
docker compose ps
```

### 4. Criar/Restaurar Banco de Dados

#### PostgreSQL
```sh
# criar banco inicial
docker compose exec postgres16 bash /local/tools/postgres_create_database.sh

# restaurar base congelada
docker compose exec postgres16 bash /local/tools/postgres_pgrestore.sh
```

#### MSSQL (verifique o nome do serviço no docker-compose.yml)
```sh
# criar banco inicial
docker compose exec mssql2022 bash /local/tools/mssql_create_database.sh

# restaurar base congelada
docker compose exec mssql2022 bash /local/tools/mssql_restore_database.sh
```

#### Oracle
```sh
# criar banco inicial
docker compose exec oracle19 bash /local/tools/oracle_create_database.sh

# restaurar base congelada (dump)
docker compose exec oracle19 bash /local/tools/oracle_impdp.sh
```

### 5. Verificar logs

```sh
docker compose logs -f protheus
docker compose logs -f dbaccess
docker compose logs -f oracle19  # ou postgres16, mssql2022
```

### Exec e acesso ao container

Para abrir um shell ou rodar comandos dentro do container use o nome do serviço com `docker compose exec` ou o nome do container com `docker exec`.

Exemplos:

```sh
# com docker compose (serviço):
docker compose exec protheus bash

# com docker (container):
docker exec -it oracle_dev-protheus-1 bash
```

Observação: `docker compose exec <container-name>` não funciona — o primeiro argumento é o NOME DO SERVIÇO definido no compose (ex.: `protheus`, `dbaccess`).

## Modo Kubernize (Imagens Oficiais)

Este projeto suporta o uso de **imagens Docker oficiais da TOTVS** (Kubernize), que simplificam a implantação e seguem as melhores práticas recomendadas pela engenharia Protheus.

### Vantagens das Imagens Kubernize

- ✅ **Homologadas pela TOTVS**: Testadas e aprovadas pela engenharia.
- ✅ **Atualizações simplificadas**: Basta trocar a tag da imagem.
- ✅ **Menos manutenção**: Não requer scripts customizados de inicialização.
- ✅ **Configuração via variáveis de ambiente**: Padrão 12-factor app.
- ✅ **Suporte a `LOCK_NUM_ON_DB`**: Controle de lock e numeração via DBAccess (obrigatório na 12.1.2510+).

### Credenciais para Acesso ao Registry

As imagens oficiais estão hospedadas em `docker.totvs.io` (uso interno TOTVS). Para fazer pull das imagens, configure suas credenciais:

```sh
docker login docker.totvs.io
# Username: seu_usuario
# Password: sua_senha
```

### Ambiente de Exemplo

Um ambiente pré-configurado está disponível em `environments/oracle_kubernize/`:

```sh
cd environments/oracle_kubernize

# Fazer login no registry TOTVS
docker login docker.totvs.io

# Iniciar o ambiente
docker compose up -d

# Verificar status
docker compose ps

# Acompanhar logs
docker compose logs -f protheus
```

### Imagens Disponíveis

| Serviço | Imagem | Versão |
| --- | --- | --- |
| Protheus | `docker.totvs.io/totvs-images/protheus` | 12.1.2510 |
| DBAccess | `docker.totvs.io/totvs-images/dbaccess` | 12.1.2510 |
| License Server | `docker.totvs.io/totvs-images/license` | v3.6.3_1 |
| TSS | `docker.totvs.io/totvs-images/tss` | v12.1.2510-3.0 |

### Variáveis de Ambiente (Modo Kubernize)

**DBAccess:**
- `DBACCESS_DATABASE`: Tipo de banco (`POSTGRES`, `MSSQL`, `ORACLE`)
- `ORACLE_SERVER`, `ORACLE_PORT`, `ORACLE_USER`, `ORACLE_PASS`, `ORACLE_SERVICE`
- `LICENSE_SERVER`, `LICENSE_PORT`
- `LOCK_NUM_ON_DB=1`: Controle de lock via DBAccess

**Protheus:**
- `DBACCESS_SERVER`, `DBACCESS_PORT`, `DBACCESS_DATABASE`, `DBACCESS_ALIAS`
- `LICENSE_SERVER`, `LICENSE_PORT`
- `LOCK_NUM_ON_DB=1`: Controle de lock via DBAccess

Consulte a [documentação oficial do Kubernize](Kubernize/Kubernize_-_Protheus_em_container_-_Engenharia-Segmentos.md) para mais detalhes.


## Variáveis de Ambiente

### Config.env (por ambiente)

| Variável | Descrição | Exemplo |
|---|---|---|
| `RELEASE` | Versão do Protheus | `12.1.2510` |
| `BANCO_DE_DADOS` | Tipo do banco (postgres15, postgres16, mssql2019, mssql2022, oracle19) | `oracle19` |
| `IDIOMA` | Idioma da base (bra, esp, eng) | `bra` |
| `LICENSE_SERVER` | Endereço do servidor de licenças | `licensedev.engpro.totvs.com.br` |
| `LICENSE_PORT` | Porta do servidor de licenças | `8850` |

### Docker Compose (gerado automaticamente)

As variáveis são injetadas nos containers via `docker-compose.yml`:
- `DATABASE_HOST`, `DATABASE_PORT`, `DATABASE_USER`, `DATABASE_PASS`
- `LICENSE_SERVER`, `LICENSE_PORT`
- `DBSERVER`, `DBPORT`, `DBDATABASE`, `DBALIAS`

## Estrutura do Projeto

```
protheus_docker/
├── environments/          # Ambientes isolados
│   └── <nome_ambiente>/
│       ├── config.env
│       └── docker-compose.yml
├── images/                # Dockerfiles
│   ├── dbaccess/
│   ├── mssql2019/
│   ├── mssql2022/
│   ├── oracle19/
│   ├── postgres15/
│   ├── postgres16/
│   └── protheus/
├── tools/                 # Scripts de automação
│   ├── setup.sh          # Download e extração de artefatos
│   ├── generate.sh       # Geração de docker-compose
│   ├── dbaccess.sh       # Inicialização DBAccess
│   ├── protheus.sh       # Inicialização AppServer
│   └── *_database.sh     # Scripts de banco
└── data/                  # Dados compartilhados (binários, dumps)
    └── totvs/
```

## Troubleshooting

### Erro: "Password is empty" no DBAccess
**Causa:** Variáveis de ambiente não carregadas no container.
**Solução:** Regenere o docker-compose e recrie o container:
```sh
bash tools/generate.sh <ambiente>
cd environments/<ambiente>
docker-compose up -d --force-recreate dbaccess
```

### Erro: "string index out of bounds" no AppServer
**Causa:** Parâmetros legados `MAXSTRINGSIZE` e `TOPMEMOMEGA`.
**Solução:** Já corrigido automaticamente. Reinicie o container:
```sh
docker-compose restart protheus
```

### Erro: "Unable to open log file" no Oracle
**Causa:** Permissões do diretório dumps.
**Solução:** Já corrigido automaticamente no setup.sh. Para ambientes antigos:
```sh
chmod 777 data/totvs/dumps/
chmod 644 data/totvs/dumps/*.dmp
```

### License Server vazio no appserver.ini
**Causa:** Variável não propagada para o container.
**Solução:** Já corrigido. Regenere o ambiente:
```sh
bash tools/generate.sh <ambiente>
docker-compose up -d --force-recreate protheus
```

## Roadmap

- [x] script para criar banco inicial do postgres
- [x] script para restaurar base congelada do postgres
- [x] script para fazer backup do postgres
- [x] script para criar banco inicial do mssql
- [x] script para restaurar base congelada do mssql
- [ ] script para fazer backup do mssql
- [x] script para criar banco inicial do oracle
- [x] script para restaurar base congelada do oracle
- [ ] script para fazer backup do oracle
- [ ] incluir imagem do tir com rdp ou vnc
- [ ] incluir imagem do robo de teste
- [ ] incluir imagem do sonar
- [ ] incluir imagem do cloudbeaver
- [ ] incluir imagem do servidor cgi
- [ ] incluir configuracao automatica do vscode
