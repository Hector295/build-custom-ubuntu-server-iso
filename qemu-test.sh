#!/bin/bash

# Script para probar la ISO con QEMU fácilmente

set -e

# Colores para output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
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

log_info "Iniciando VM con QEMU..."
log_info "ISO: $(basename $ISO_FILE)"
log_success "Presiona Ctrl+Alt+G para liberar el mouse"
log_success "Presiona Ctrl+Alt+Q para cerrar QEMU"

# Detectar si estamos en un entorno gráfico
if [ -z "$DISPLAY" ]; then
    log_info "Sin entorno gráfico detectado, usando modo texto..."
    DISPLAY_MODE="-nographic"
    CONSOLE_OPTION="-append console=ttyS0"
else
    log_info "Entorno gráfico detectado..."
    DISPLAY_MODE="-display gtk,grab-on-hover=on"
    CONSOLE_OPTION=""
fi

# Detectar si KVM está disponible
if [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    log_info "KVM disponible, usando aceleración..."
    KVM_OPTIONS="-enable-kvm -cpu host"
else
    log_info "KVM no disponible, usando emulación..."
    KVM_OPTIONS="-cpu qemu64"
fi

# Configurar VM optimizada para testing
log_info "Iniciando QEMU..."
qemu-system-x86_64 \
    -cdrom "$ISO_FILE" \
    -m 2048 \
    $KVM_OPTIONS \
    -smp 2 \
    -boot d \
    -netdev user,id=net0 \
    -device virtio-net,netdev=net0 \
    -vga std \
    $DISPLAY_MODE \
    $CONSOLE_OPTION \
    -name "Ubuntu Live Test"