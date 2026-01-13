#!/bin/bash

# Script para configurar proxy de porta para servidor de licenças TOTVS
# Permite que containers Docker acessem o servidor de licenças através do host

set -euo pipefail

LICENSE_SERVER="licensedba.engpro.totvs.com.br"
LICENSE_PORT="5555"
DOCKER_BRIDGE_IP="172.17.0.1"

log_info() {
    echo "[INFO] $1"
}

log_success() {
    echo "[SUCCESS] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

log_warning() {
    echo "[WARNING] $1"
}

# Verifica se está rodando como root
if [[ $EUID -ne 0 ]]; then
   log_error "Este script precisa ser executado como root (use sudo)"
   exit 1
fi

log_info "Configurando proxy de porta para servidor de licenças TOTVS..."

# Resolve o IP do servidor de licenças
LICENSE_IP=$(getent hosts "${LICENSE_SERVER}" | awk '{ print $1 }' | head -n1)

if [ -z "${LICENSE_IP}" ]; then
    log_error "Não foi possível resolver o IP de ${LICENSE_SERVER}"
    log_warning "Verifique se você está conectado à VPN da TOTVS"
    exit 1
fi

log_info "Servidor de licenças: ${LICENSE_SERVER} -> ${LICENSE_IP}:${LICENSE_PORT}"

# Habilita IP forwarding
log_info "Habilitando IP forwarding..."
sysctl -w net.ipv4.ip_forward=1 > /dev/null

# Configura iptables para fazer DNAT (redirecionamento de porta)
log_info "Configurando regras de iptables..."

# Remove regras antigas se existirem
iptables -t nat -D PREROUTING -d "${DOCKER_BRIDGE_IP}" -p tcp --dport "${LICENSE_PORT}" -j DNAT --to-destination "${LICENSE_IP}:${LICENSE_PORT}" 2>/dev/null || true
iptables -t nat -D POSTROUTING -j MASQUERADE 2>/dev/null || true

# Adiciona novas regras
iptables -t nat -A PREROUTING -d "${DOCKER_BRIDGE_IP}" -p tcp --dport "${LICENSE_PORT}" -j DNAT --to-destination "${LICENSE_IP}:${LICENSE_PORT}"
iptables -t nat -A POSTROUTING -j MASQUERADE

log_success "Proxy de porta configurado com sucesso!"
log_info "Containers Docker agora podem acessar ${LICENSE_SERVER}:${LICENSE_PORT}"
log_info ""
log_info "Para remover a configuração, execute:"
log_info "  sudo iptables -t nat -D PREROUTING -d ${DOCKER_BRIDGE_IP} -p tcp --dport ${LICENSE_PORT} -j DNAT --to-destination ${LICENSE_IP}:${LICENSE_PORT}"
log_info "  sudo iptables -t nat -D POSTROUTING -j MASQUERADE"
