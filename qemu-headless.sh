#!/bin/bash

# Script para probar la ISO con QEMU en modo headless/texto

set -e

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Buscar archivo ISO
ISO_FILE=$(find . -maxdepth 1 -name "*.iso" -type f | head -1)

if [ -z "$ISO_FILE" ]; then
    echo "Error: No se encontró archivo ISO en el directorio actual"
    exit 1
fi

# Verificar si QEMU está instalado
if ! command -v qemu-system-x86_64 &> /dev/null; then
    log_info "QEMU no está instalado. Instalando..."
    sudo apt update
    sudo apt install -y qemu-system-x86-64 qemu-utils
fi

log_info "Iniciando VM en modo headless/texto..."
log_info "ISO: $(basename $ISO_FILE)"
log_warning "Modo texto - verás la consola directamente"
log_success "Presiona Ctrl+A, luego X para salir de QEMU"

# VM en modo texto para servidores
qemu-system-x86_64 \
    -cdrom "$ISO_FILE" \
    -m 2048 \
    -cpu qemu64 \
    -smp 2 \
    -boot d \
    -netdev user,id=net0 \
    -device virtio-net,netdev=net0 \
    -nographic \
    -serial stdio \
    -monitor none \
    -name "Ubuntu Live Test Headless"