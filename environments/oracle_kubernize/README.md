# Ambiente Oracle com Imagens Oficiais Kubernize

Este ambiente utiliza as **imagens Docker oficiais da TOTVS** (projeto Kubernize), seguindo as melhores práticas recomendadas pela engenharia Protheus.

## Pré-requisitos

1. **Acesso ao registry docker.totvs.io** (uso interno TOTVS)
2. Credenciais válidas para pull das imagens
3. Docker e Docker Compose instalados

## Configuração

### 1. Criar arquivo .env

O Docker Compose lê automaticamente as variáveis do arquivo `.env`. Copie o template:

```bash
cd environments/oracle_kubernize
cp config.env .env

# Edite o .env conforme necessário
nano .env  # ou vim, code, etc.
```

### 2. Login no Registry TOTVS

```bash
docker login docker.totvs.io
# Username: seu_usuario_totvs
# Password: sua_senha
```

### 3. Iniciar o ambiente

```bash
cd environments/oracle_kubernize

# Iniciar todos os serviços
docker compose up -d

# Verificar status
docker compose ps

# Acompanhar logs
docker compose logs -f protheus
```

## Imagens Utilizadas

- **Protheus**: `docker.totvs.io/totvs-images/protheus:12.1.2510` (oficial TOTVS)
- **DBAccess**: `docker.totvs.io/totvs-images/dbaccess:12.1.2510` (oficial TOTVS)
- **Oracle**: Build local (`../../images/oracle19`) - baseado em Oracle Database 19c Enterprise Edition

## Variáveis de Ambiente

As variáveis são definidas no arquivo `.env` (cópia de `config.env`).

Edite conforme necessário:

### Oracle
- `ORACLE_SID`: Nome da instância Oracle
- `ORACLE_SERVICE`: Nome do serviço PDB
- `ORACLE_PORT`: Porta do Oracle (padrão: 1521)
- `DATABASE_USER`: Usuário do banco
- `DATABASE_PASS`: Senha do usuário

### DBAccess
- `DBACCESS_ALIAS`: Alias do ambiente (ex: 1212510_bra)
- `DBACCESS_PORT`: Porta do DBAccess (padrão: 7890)
- `LICENSE_SERVER`: Servidor de licenças
- `LICENSE_PORT`: Porta do servidor de licenças

### Protheus
- `PROTHEUS_PORT`: Porta TCP do SmartClient (padrão: 1234)
- `WEBAPP_PORT`: Porta HTTP do WebApp (padrão: 8086)

## Recursos Habilitados

### Controle de Lock e Numeração via DBAccess

A variável `LOCK_NUM_ON_DB=1` está habilitada, ativando o controle de concorrência diretamente no DBAccess (obrigatório na release 12.1.2510+).

**Arquivo de confirmação:**
Quando ativo, o arquivo `<banco>_dbnumber.val` é criado automaticamente no diretório do DBAccess.

### Healthchecks

Todos os serviços possuem healthchecks configurados:
- Oracle: Valida conexão via sqlplus
- DBAccess: Verifica processo `dbaccess64`
- Protheus: Verifica processo `appsrvlinux`

### Ulimits

Configurado `nofile: 65536` para DBAccess e Protheus, atendendo aos requisitos de alta concorrência.

## Volumes Persistentes

- `oracle_data`: Dados do Oracle (`/opt/oracle/oradata`)
- `dbaccess_data`: Configurações e dados do DBAccess (`/opt/totvs/dbaccess/volume`)
- `protheus_data`: RPO, dicionários e dados do Protheus (`/opt/totvs/protheus/volume`)

## Portas Expostas

| Serviço | Porta Host | Porta Container | Protocolo |
| --- | --- | --- | --- |
| Oracle | 1521 | 1521 | TCP |
| DBAccess | 7890 | 7890 | TCP |
| Protheus SmartClient | 1234 | 1234 | TCP (SSL) |
| Protheus WebApp | 8086 | 8080 | HTTP |

## Comandos Úteis

### Logs em tempo real

```bash
docker compose logs -f protheus
docker compose logs -f dbaccess
docker compose logs -f oracle19
```

### Acessar shell do container

```bash
# Protheus
docker compose exec protheus bash

# DBAccess
docker compose exec dbaccess bash

# Oracle
docker compose exec oracle19 bash
```

### Verificar arquivo de controle de numeração

```bash
docker compose exec dbaccess ls -lah /opt/totvs/dbaccess/volume/current/ | grep _dbnumber.val
```

### Parar e remover o ambiente

```bash
docker compose down

# Remover também os volumes (CUIDADO: apaga os dados!)
docker compose down -v
```

## Troubleshooting

### Erro: "unauthorized: authentication required"

Certifique-se de ter feito login no registry:
```bash
docker login docker.totvs.io
```

### Erro: Oracle não sobe (healthcheck failing)

Aguarde até 2 minutos na primeira inicialização. O Oracle 19c demora para criar o PDB.

Verifique os logs:
```bash
docker compose logs oracle19
```

### DBAccess não conecta no Oracle

1. Confirme que o Oracle está healthy:
   ```bash
   docker compose ps
   ```

2. Verifique as credenciais em `config.env`:
   - `DATABASE_USER`
   - `DATABASE_PASS`
   - `ORACLE_SERVICE`

3. Teste a conexão manualmente:
   ```bash
   docker compose exec oracle19 sqlplus ${DATABASE_USER}/${DATABASE_PASS}@${ORACLE_SERVICE}
   ```

### Protheus não acessa o WebApp

1. Verifique se a porta 8086 está mapeada:
   ```bash
   docker compose ps protheus
   ```

2. Teste a conexão HTTP:
   ```bash
   curl -v http://localhost:8086
   ```

3. Se aparecer erro SSL, lembre-se: a porta 8086 é **HTTP**, não HTTPS.

## Referências

- [Documentação oficial Kubernize](../Kubernize/Kubernize_-_Protheus_em_container_-_Engenharia-Segmentos.md)
- [TDN - Controle de lock via DBAccess](https://tdn.totvs.com/pages/releaseview.action?pageId=928946197)
- [TDN - Protheus em Container](https://tdn.totvs.com/display/public/EN/Kubernize+-+Protheus+em+container)
