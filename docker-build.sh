#!/bin/bash

# Script para construir ISO usando Docker
# Ejecutar desde el directorio del proyecto

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

# Verificar que Docker está instalado
if ! command -v docker &> /dev/null; then
    log_error "Docker no está instalado. Instala Docker primero:"
    echo "sudo apt update && sudo apt install docker.io"
    echo "sudo usermod -aG docker \$USER"
    echo "Luego reinicia la sesión"
    exit 1
fi

# Verificar que el usuario está en el grupo docker
if ! groups | grep -q docker; then
    log_error "Tu usuario no está en el grupo docker."
    echo "Ejecuta: sudo usermod -aG docker \$USER"
    echo "Luego reinicia la sesión"
    exit 1
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="ubuntu-live-builder"

log_info "=== Ubuntu Live ISO Builder con Docker ==="
echo ""

# Construir imagen Docker
log_info "Construyendo imagen Docker..."
docker build -t "$IMAGE_NAME" "$PROJECT_DIR"

if [ $? -eq 0 ]; then
    log_success "Imagen Docker construida exitosamente"
else
    log_error "Error construyendo imagen Docker"
    exit 1
fi

# Ejecutar contenedor con privilegios y volumen montado
log_info "Ejecutando contenedor para construir ISO..."
echo ""
log_info "Comandos disponibles dentro del contenedor:"
echo "  ./build-iso.sh                    # Modo interactivo"
echo "  ./build-iso-automated.sh -v 20.04 # Modo automatizado"
echo "  exit                              # Salir del contenedor"
echo ""

docker run -it --privileged \
    --volume "$PROJECT_DIR:/workspace" \
    --workdir /workspace \
    "$IMAGE_NAME" \
    /bin/bash

log_info "Contenedor finalizado"

# Verificar si se generó ISO
ISO_FILES=$(find "$PROJECT_DIR" -maxdepth 1 -name "*.iso" -type f)
if [ ! -z "$ISO_FILES" ]; then
    echo ""
    log_success "¡ISO(s) generada(s) exitosamente!"
    echo "$ISO_FILES" | while read -r iso_file; do
        log_success "📁 $(basename "$iso_file")"
        log_info "   Tamaño: $(du -h "$iso_file" | cut -f1)"
    done
else
    echo ""
    log_info "No se encontraron archivos ISO generados"
fi

echo ""
log_info "Para limpiar la imagen Docker:"
echo "docker rmi $IMAGE_NAME"