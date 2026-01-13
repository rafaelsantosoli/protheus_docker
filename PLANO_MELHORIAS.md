# 📋 Plano de Melhorias - Protheus Docker Multi-Ambiente

## 🎯 Objetivos Gerais
1. **Manter escalabilidade**: Arquitetura multi-ambiente isolado
2. **Incorporar robustez**: Validações e padrões do repositório juliansantosinfo
3. **Corrigir inconsistências**: Baseado em documentação oficial TOTVS
4. **Melhorar UX**: Documentação, automação e troubleshooting

---

## 📊 FASE 1: Correções Críticas (Alta Prioridade)

### ✅ 1.1. DBAccess - Configuração ODBC30 para PostgreSQL
**Problema**: Documentação TDN requer `ODBC30=1` no dbaccess.ini para PostgreSQL  
**Arquivo**: `tools/dbaccess.sh`  
**Mudança**:
```bash
# Após gerar dbaccess.ini, adicionar seção [General] com ODBC30=1
```
**Referência**: https://tdn-homolog.totvs.com/display/PROT/04.+Conectando+sua+base+ao+DBAccess

---

### ✅ 1.2. PostgreSQL - TableSpaces e IndexSpaces
**Problema**: DBAccess PostgreSQL usa TableSpace/IndexSpace para organização  
**Arquivo**: `tools/postgres_create_database.sh`  
**Mudança**:
```sql
CREATE TABLESPACE ${DATABASE_NAME}_data LOCATION '/var/lib/postgresql/data/tablespaces/data';
CREATE TABLESPACE ${DATABASE_NAME}_index LOCATION '/var/lib/postgresql/data/tablespaces/index';
```

---

### ✅ 1.3. Validação de Variáveis Críticas
**Status**: Parcialmente implementado  
**Ação**: Expandir `check_env_var()` para:
- `tools/oracle_create_database.sh`
- `tools/mssql_create_database.sh`
- `tools/postgres_create_database.sh`

---

### ✅ 1.4. Healthchecks para Todos os Serviços
**Arquivo**: `tools/generate.sh`  
**Adicionar**:
```yaml
# PostgreSQL
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U postgres"]
  interval: 10s
  timeout: 5s
  retries: 5

# MSSQL
healthcheck:
  test: ["CMD-SHELL", "/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P $$MSSQL_SA_PASSWORD -C -Q 'SELECT 1'"]
  interval: 30s
  timeout: 10s
  retries: 3
  start_period: 30s

# Oracle
healthcheck:
  test: ["CMD-SHELL", "echo 'SELECT 1 FROM DUAL;' | sqlplus -S system/$$ORACLE_PWD@$$ORACLE_PDB"]
  interval: 30s
  timeout: 10s
  retries: 5
  start_period: 120s

# DBAccess
healthcheck:
  test: ["CMD-SHELL", "pgrep -x dbaccess64 || exit 1"]
  interval: 30s
  timeout: 5s
  retries: 3

# Protheus
healthcheck:
  test: ["CMD-SHELL", "pgrep -x appsrvlinux || exit 1"]
  interval: 30s
  timeout: 5s
  retries: 3
```

---

## 📊 FASE 2: Melhorias de Arquitetura (Média Prioridade)

### 🔄 2.1. Padrão Entrypoint (Inspirado em juliansantosinfo)
**Benefício**: Separação de responsabilidades  
**Estrutura proposta**:
```
tools/
├── entrypoints/
│   ├── dbaccess-entrypoint.sh      # Orquestração geral
│   ├── setup-database.sh           # Configuração de banco
│   └── setup-dbaccess.sh           # Configuração DBAccess
```

**Decisão**: **OPCIONAL** - Manter estrutura atual é mais simples para multi-ambiente

---

### 🔄 2.2. Template .env.example
**Criar**: `.env.example` na raiz
```env
# Credenciais ARTE (Repositório TOTVS)
ARTE_USER=seu_usuario_totvs
ARTE_PASS=sua_senha

# License Server
LICENSE_SERVER=seu_servidor_licencas
LICENSE_PORT=5555
```

---

### 🔄 2.3. Script de Validação de Ambiente
**Criar**: `tools/validate.sh <env_name>`
```bash
#!/bin/bash
# Valida se ambiente está pronto para uso
# - Verifica arquivos necessários
# - Testa conectividade com bancos
# - Valida configurações do docker-compose
```

---

### 🔄 2.4. Logs Estruturados
**Padrão**: Adicionar timestamps e níveis de log
```bash
log_info()  { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ℹ️  $*"; }
log_error() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ❌ $*" >&2; }
log_success() { echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✅ $*"; }
```

---

## 📊 FASE 3: Funcionalidades Avançadas (Baixa Prioridade)

### 🚀 3.1. Backup Automatizado
**Status Atual**:
- ✅ Postgres: `postgres_pgdump.sh`
- ❌ MSSQL: Falta implementar
- ❌ Oracle: Falta implementar

**Ação**: Criar `mssql_backup.sh` e `oracle_expdp.sh`

---

### 🚀 3.2. Docker Compose Profiles
**Benefício**: Subir apenas serviços necessários
```yaml
services:
  cloudbeaver:
    profiles: ["tools"]
  sonarqube:
    profiles: ["tools"]
```

**Uso**:
```bash
docker-compose --profile tools up -d
```

---

### 🚀 3.3. CI/CD com GitHub Actions
**Arquivo**: `.github/workflows/build.yml`
- Build automático de imagens
- Testes de integração
- Publicação no Docker Hub (opcional)

---

## 📊 FASE 4: Documentação (Alta Prioridade)

### 📚 4.1. README.md Aprimorado
**Status**: ✅ Já implementado na sessão anterior  
**Próximos passos**:
- Adicionar diagrama de arquitetura (Mermaid)
- Badges (Docker, License, Build Status)
- Comparação com instalação tradicional

---

### 📚 4.2. Documentação por Componente
**Criar**:
- `docs/ARCHITECTURE.md`: Diagrama e explicação da arquitetura
- `docs/TROUBLESHOOTING.md`: Problemas comuns expandidos
- `docs/DEVELOPMENT.md`: Guia para contribuidores

---

### 📚 4.3. Exemplos de Uso
**Criar**: `examples/` com cenários reais
```
examples/
├── ambiente-dev-postgres.md
├── ambiente-prod-oracle.md
└── multi-release.md
```

---

## 🎯 Priorização e Timeline

### Sprint 1 (1-2 dias) - **CRÍTICO**
- [ ] 1.1. ODBC30 para PostgreSQL
- [ ] 1.2. TableSpaces PostgreSQL  
- [ ] 1.3. Validações expandidas
- [ ] 1.4. Healthchecks

### Sprint 2 (2-3 dias) - **IMPORTANTE**
- [ ] 2.2. .env.example
- [ ] 2.3. Script de validação
- [ ] 2.4. Logs estruturados
- [ ] 4.1. Badges e diagramas

### Sprint 3 (1 semana) - **DESEJÁVEL**
- [ ] 3.1. Backups MSSQL/Oracle
- [ ] 3.2. Docker Compose Profiles
- [ ] 4.2. Documentação expandida

### Backlog - **FUTURO**
- [ ] 3.3. CI/CD
- [ ] 2.1. Entrypoint pattern
- [ ] Monitoramento (Prometheus/Grafana)

---

## ✅ Checklist de Validação

Após cada fase, validar:
- [ ] Todos os bancos (Postgres15/16, MSSQL2019/2022, Oracle19) funcionando
- [ ] Scripts de criação e restore funcionais
- [ ] Logs claros e informativos
- [ ] Documentação atualizada
- [ ] Nenhuma regressão em ambientes existentes

---

## 📝 Notas de Implementação

### Decisões Arquiteturais

1. **Manter estrutura multi-ambiente**: Diferencial competitivo vs repositório de referência
2. **Não adotar entrypoint complexo**: Manter simplicidade
3. **Priorizar robustez sobre features**: Garantir que o básico funcione 100%

### Comparação com Repositório de Referência

| Aspecto | Nosso Repo | juliansantosinfo | Decisão |
|---------|------------|------------------|---------|
| Multi-ambiente | ✅ Sim | ❌ Não | **Manter** |
| Validações | ⚠️ Parcial | ✅ Completo | **Melhorar** |
| Healthchecks | ❌ Não | ✅ Sim | **Adicionar** |
| Documentação | ✅ Boa | ✅ Excelente | **Equiparar** |
| Entrypoints | ❌ Simples | ✅ Modular | **Opcional** |
| Download | ✅ ARTE | ✅ GitHub Releases | **Manter** |

---

## 🔗 Referências

- [TDN - Protheus com PostgreSQL](https://tdn.totvs.com/display/PROT/Protheus+com+PostgreSQL)
- [TDN - DBAccess Configuration](https://tdn-homolog.totvs.com/display/PROT/04.+Conectando+sua+base+ao+DBAccess)
- [Repositório juliansantosinfo](https://github.com/juliansantosinfo/TOTVS-Protheus-in-Docker)
- [Oracle ODBC Best Practices](https://docs.oracle.com/en/database/oracle/oracle-database/26/odbcd/performance-and-tuning.html)
