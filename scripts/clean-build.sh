#!/bin/bash

# Script para limpiar archivos de construcción

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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Directorio base del proyecto
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"

log_info "Limpiando archivos de construcción..."

if [ -d "$BUILD_DIR" ]; then
    log_info "Eliminando directorio de construcción: $BUILD_DIR"
    sudo rm -rf "$BUILD_DIR"
    log_success "Directorio de construcción eliminado"
else
    log_warning "No existe directorio de construcción que limpiar"
fi

# Limpiar archivos ISO anteriores (opcional)
read -p "¿Deseas eliminar archivos ISO anteriores? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log_info "Buscando archivos ISO..."
    ISO_FILES=$(find "$PROJECT_DIR" -maxdepth 1 -name "*.iso" -type f)

    if [ ! -z "$ISO_FILES" ]; then
        echo "$ISO_FILES" | while read -r iso_file; do
            log_info "Eliminando: $(basename "$iso_file")"
            rm -f "$iso_file"
        done
        log_success "Archivos ISO eliminados"
    else
        log_warning "No se encontraron archivos ISO"
    fi
fi

log_success "Limpieza completada"