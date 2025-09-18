#!/bin/bash

# Script para instalar dependencias necesarias para live-build

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar si se ejecuta como root
if [[ $EUID -ne 0 ]]; then
   log_error "Este script debe ejecutarse como root (usar sudo)"
   exit 1
fi

log_info "Instalando dependencias para Ubuntu Live ISO Builder..."

# Actualizar lista de paquetes
log_info "Actualizando lista de paquetes..."
apt update

# Instalar dependencias principales
log_info "Instalando live-build y dependencias..."
apt install -y \
    live-build \
    debootstrap \
    xorriso \
    isolinux \
    syslinux \
    memtest86+ \
    dosfstools \
    squashfs-tools \
    genisoimage \
    rsync

# Verificar instalación
log_info "Verificando instalación..."

DEPS=("live-build" "debootstrap" "xorriso")
ALL_INSTALLED=true

for dep in "${DEPS[@]}"; do
    if command -v "$dep" &> /dev/null; then
        log_success "✓ $dep instalado correctamente"
    else
        log_error "✗ $dep no se instaló correctamente"
        ALL_INSTALLED=false
    fi
done

if [ "$ALL_INSTALLED" = true ]; then
    log_success "¡Todas las dependencias se instalaron exitosamente!"
    log_info "Ahora puedes ejecutar: ./build-iso.sh"
else
    log_error "Algunas dependencias no se instalaron correctamente"
    exit 1
fi