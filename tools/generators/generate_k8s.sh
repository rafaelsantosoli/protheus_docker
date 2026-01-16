#!/bin/bash
set -e

if [ -z "$1" ]; then
    echo "Uso: $0 <nome_do_ambiente>"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(dirname "$TOOLS_DIR")"

ENV_NAME="$1"
ENV_DIR="${PROJECT_ROOT}/environments/${ENV_NAME}"
CONFIG_FILE="${ENV_DIR}/config.env"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Erro: Configuração não encontrada em ${CONFIG_FILE}."
    exit 1
fi

source "${CONFIG_FILE}"

# Default logic from generate_docker.sh
case "${BANCO_DE_DADOS}" in
    postgres15|postgres16)
        dbdatabase="postgres"
        database_port="5432"
        ;;
    mssql2019|mssql2022)
        dbdatabase="mssql"
        database_port="1433"
        ;;
    oracle19)
        dbdatabase="oracle"
        database_port="1521"
        ;;
esac

case "${IDIOMA}" in
    bra) congelada_idioma="exp" ;;
    *)   congelada_idioma="${IDIOMA}" ;;
esac

congelada_nome="p${RELEASE//./}mntdb${congelada_idioma}"
dbalias="${RELEASE//./}_${IDIOMA}"
# For Kubernetes, simple user names are often better
database_user="protheus"

# Determine Images
env_type="${ENV_TYPE:-custom}"

if [ "$env_type" == "kubernize" ]; then
    IMG_TAG="${RELEASE}"
    if [ "${EXPEDICAO}" != "published" ]; then
        IMG_TAG="${RELEASE}-${EXPEDICAO}"
    fi
    DBACCESS_IMAGE="docker.totvs.io/totvs-images/dbaccess:${IMG_TAG}"
    PROTHEUS_IMAGE="docker.totvs.io/totvs-images/protheus:${IMG_TAG}"
    LICENSE_IMAGE="docker.totvs.io/totvs-images/license:v3.6.3_1"
else
    # Legacy/Custom mode for K8s is tricky because we built local images in Docker Compose.
    # Kubernetes can't easily access local docker daemon images unless using Minikube/Kind with image load.
    # For now, we will warn about this or assume the user pushed them.
    # Or simplified: use placeholders.
    echo "Warning: Custom mode in K8s requires images to be pushed to a registry."
    DBACCESS_IMAGE="my-registry/dbaccess:${RELEASE}"
    PROTHEUS_IMAGE="my-registry/protheus:${RELEASE}"
    LICENSE_IMAGE="docker.totvs.io/totvs-images/license:v3.6.3_1"
fi

exec 1>"${ENV_DIR}/kubernetes.yaml"

cat <<-EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-protheus-${ENV_NAME}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: config-environment-${ENV_NAME}
data:
  LICENSE_SERVER: "license-${ENV_NAME}"
  LICENSE_PORT: "5555"
  DBACCESS_DATABASE: "POSTGRES"
  DBACCESS_SERVER: "dbaccess-${ENV_NAME}"
  DBACCESS_PORT: "7890"
  DBACCESS_ALIAS: "${dbalias}"
  POSTGRES_SERVER: "postgres-${ENV_NAME}"
  POSTGRES_PORT: "5432"
  POSTGRES_DATABASE: "${database_user}"
  LOCK_NUM_ON_DB: "1"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: license-${ENV_NAME}
spec:
  selector:
    matchLabels:
      app: license-${ENV_NAME}
  template:
    metadata:
      labels:
        app: license-${ENV_NAME}
    spec:
      containers:
      - name: license
        image: ${LICENSE_IMAGE}
        ports:
        - containerPort: 5555
      volumes:
      - name: storage
        persistentVolumeClaim:
          claimName: pvc-protheus-${ENV_NAME}
---
apiVersion: v1
kind: Service
metadata:
  name: license-${ENV_NAME}
spec:
  selector:
    app: license-${ENV_NAME}
  ports:
  - port: 5555
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dbaccess-${ENV_NAME}
spec:
  selector:
    matchLabels:
      app: dbaccess-${ENV_NAME}
  template:
    metadata:
      labels:
        app: dbaccess-${ENV_NAME}
    spec:
      containers:
      - name: dbaccess
        image: ${DBACCESS_IMAGE}
        envFrom:
        - configMapRef:
            name: config-environment-${ENV_NAME}
        ports:
        - containerPort: 7890
---
apiVersion: v1
kind: Service
metadata:
  name: dbaccess-${ENV_NAME}
spec:
  selector:
    app: dbaccess-${ENV_NAME}
  ports:
  - port: 7890
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: protheus-${ENV_NAME}
spec:
  selector:
    matchLabels:
      app: protheus-${ENV_NAME}
  template:
    metadata:
      labels:
        app: protheus-${ENV_NAME}
    spec:
      containers:
      - name: protheus
        image: ${PROTHEUS_IMAGE}
        envFrom:
        - configMapRef:
            name: config-environment-${ENV_NAME}
        ports:
        - containerPort: 8080 # Kubernize default
        - containerPort: 1234
      volumes:
      - name: storage
        persistentVolumeClaim:
          claimName: pvc-protheus-${ENV_NAME}
---
apiVersion: v1
kind: Service
metadata:
  name: protheus-${ENV_NAME}
spec:
  type: NodePort
  selector:
    app: protheus-${ENV_NAME}
  ports:
  - port: 8080
    targetPort: 8080
    nodePort: 30080
  - port: 1234
    nodePort: 30234
EOF

# Database Deployment (Postgres only for now as example)
if [[ "${BANCO_DE_DADOS}" == "postgres"* ]]; then
cat <<-EOF
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-${ENV_NAME}
spec:
  selector:
    matchLabels:
      app: postgres-${ENV_NAME}
  template:
    metadata:
      labels:
        app: postgres-${ENV_NAME}
    spec:
      containers:
      - name: postgres
        image: postgres:16
        env:
        - name: POSTGRES_PASSWORD
          value: "Protheus.123"
        ports:
        - containerPort: 5432
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-${ENV_NAME}
spec:
  selector:
    app: postgres-${ENV_NAME}
  ports:
  - port: 5432
EOF
fi
