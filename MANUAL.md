# Manual de Utilização - Protheus Docker Manager

Este manual descreve detalhadamente como utilizar as ferramentas de automação para criar e gerenciar ambientes Protheus utilizando Docker e Kubernetes no WSL2.

## 📋 Pré-requisitos

1. **WSL2 Instalado** (Ubuntu recomendado).
2. **Docker Desktop** ou **Docker Engine** rodando no WSL2.
3. **Credenciais TOTVS**:
   - Para modo **Custom** (Legado): Credenciais do `arte.engpro.totvs.io`.
   - Para modo **Kubernize** (Oficial): Credenciais do `docker.totvs.io`.

## ⚙️ Instalação

Para facilitar o uso, adicione o diretório `tools/cli` ao seu PATH. Execute o comando abaixo para configurar automaticamente no seu `.bashrc` e `.zshrc`:

```bash
# Executar na raiz do repositório
echo "export PATH=\$PATH:\$HOME/repositorios/protheus_docker/tools/cli" >> ~/.bashrc
echo "export PATH=\$PATH:\$HOME/repositorios/protheus_docker/tools/cli" >> ~/.zshrc
source ~/.bashrc 2>/dev/null || source ~/.zshrc
```

Agora você pode usar o comando `protheus` de qualquer lugar.

---

## 🚀 Fluxo de Trabalho Básico

### 1. Criar um Novo Ambiente (`init`)

O comando `init` inicia um assistente interativo para configurar um novo ambiente.

```bash
protheus init nome_do_ambiente
```

**Opções do Assistente:**
1. **Modo do Ambiente**:
   - **Kubernize (Recomendado)**: Utiliza as imagens oficiais da TOTVS (`docker.totvs.io`). Mais rápido e padrão de mercado. Requer apenas download de artefatos de dados (RPO, Dicionários).
   - **Custom (Legado)**: Baixa os binários do AppServer/DBAccess e constrói imagens locais. Permite maior customização do Dockerfile se necessário.
2. **Release**: Versão do Protheus (ex: 12.1.2410).
3. **Banco de Dados**: PostgreSQL, Oracle, MSSQL.
4. **Expedição**: Latest, Published, Next.
5. **Idioma**: Brasileiro (bra), Espanhol, Inglês, etc.

Isso criará a pasta `environments/nome_do_ambiente` com o arquivo `config.env`.

### 2. Gerar Configuração (`generate`)

Após criar o ambiente, você precisa gerar os arquivos de orquestração (Docker Compose ou Kubernetes).

**Para Docker (Desenvolvimento Local):**
```bash
protheus generate nome_do_ambiente
# Ou explicitamente:
protheus generate nome_do_ambiente --target docker
```
Isso cria o arquivo `docker-compose.yml` na pasta do ambiente.

**Para Kubernetes (K8s):**
```bash
protheus generate nome_do_ambiente --target k8s
```
Isso cria o arquivo `kubernetes.yaml` na pasta do ambiente.

### 3. Iniciar o Ambiente (`up`)

Para subir o ambiente usando Docker Compose:

```bash
protheus up nome_do_ambiente
```

Este comando entra na pasta do ambiente e executa `docker compose up -d`.

### 4. Gerenciar o Ambiente

- **Ver Status**:
  ```bash
  protheus ps nome_do_ambiente
  ```
- **Ver Logs**:
  ```bash
  protheus logs nome_do_ambiente [nome_servico]
  # Exemplo: protheus logs meu_env protheus
  ```
- **Parar Ambiente**:
  ```bash
  protheus down nome_do_ambiente
  ```
- **Acessar Shell do Container**:
  ```bash
  protheus shell nome_do_ambiente nome_servico
  # Exemplo: Acessar o banco de dados
  protheus shell meu_env postgres16
  ```

---

## 💾 Gerenciamento de Banco de Dados

## 💾 Gerenciamento de Banco de Dados

O CLI possui comandos dedicados para facilitar a criação e restauração de bancos de dados, detectando automaticamente o tipo de banco (Postgres, Oracle, MSSQL) configurado no ambiente.

### Comandos Gerais

1. **Criar Banco Vazio (Inicial)**:
   Executa o script de criação de usuários e tablespaces apropriado para o banco.
   ```bash
   protheus db create nome_do_ambiente
   ```

2. **Restaurar Base Congelada (Oficial TOTVS)**:
   Executa o script de restauração (impdp, pg_restore) utilizando os dumps baixados em `data/totvs/dumps`.
   ```bash
   protheus db restore nome_do_ambiente
   ```

### Detalhes por Banco

- **PostgreSQL**:
  - `create`: Cria role e database.
  - `restore`: Restaura via `pg_restore`.
- **Oracle**:
  - `create`: Cria tablespaces e usuários.
  - `restore`: Importa via `impdp`.
- **MSSQL**:
  - `create`: Cria banco.
  - `restore`: Restaura `.bak`.

---

## ☸️ Utilizando com Kubernetes

O gerador K8s cria um manifesto padrão (`kubernetes.yaml`) que inclui:
- **PersistentVolumeClaim (PVC)**: Para persistência de dados (10Gi).
- **ConfigMap**: Variáveis de ambiente e configuração.
- **Deployments**:
  - `license`: License Server.
  - `dbaccess`: Gateway de banco.
  - `protheus`: O ERP em si.
  - `postgres` (opcional/exemplo): Um banco Postgres simples.
- **Services**: Exposição de portas (NodePort para Protheus).

**Como aplicar:**

1. Certifique-se de que seu cluster K8s está acessível (`kubectl get nodes`).
2. Gere o manifesto:
   ```bash
   protheus generate nome_do_ambiente --target k8s
   ```
3. Aplique no cluster:
   ```bash
   kubectl apply -f environments/nome_do_ambiente/kubernetes.yaml
   ```

**Nota sobre Imagens no K8s:**
O modo **Kubernize** é ideal para Kubernetes pois usa imagens oficiais publicadas. O modo **Custom** requer que você faça o build das imagens localmente e as envie (push) para um registry que seu cluster Kubernetes consiga acessar, ou use um carregador de imagens local (como `kind load` ou `minikube image load`).

---

## 🛠️ Estrutura de Diretórios

- `environments/`: Onde ficam as configurações de cada ambiente.
- `tools/cli/`: Onde fica o comando `protheus` e o assistente `setup_wizard.sh`.
- `tools/generators/`: Scripts que criam os Yamls (`docker` e `k8s`).
- `tools/database/`: Scripts SQL/Shell para manutenção de banco.
- `data/`: Diretório compartilhado onde ficam os artefatos baixados (RPO, Dicionários, Dumps).
