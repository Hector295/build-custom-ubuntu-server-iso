#!/bin/bash

# Ubuntu Live ISO Builder - Versión Automatizada
# Script para generar imágenes ISO sin interacción del usuario

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Directorio base del proyecto
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
TEMPLATES_DIR="${PROJECT_DIR}/templates"
PACKAGES_DIR="${PROJECT_DIR}/packages"

# Función para mostrar mensajes con colores
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [OPCIONES]"
    echo ""
    echo "Opciones:"
    echo "  -v, --version VERSION    Versión de Ubuntu (20.04, 22.04, 24.04)"
    echo "  -a, --automated          Usar preseed para instalación automatizada"
    echo "  -o, --output DIR         Directorio de salida para la ISO"
    echo "  -h, --help               Mostrar esta ayuda"
    echo ""
    echo "Ejemplos:"
    echo "  $0 -v 22.04"
    echo "  $0 --version 24.04 --automated"
    echo "  $0 -v 20.04 -o /tmp/isos"
    echo ""
}

# Valores por defecto
UBUNTU_VERSION=""
USE_PRESEED=false
OUTPUT_DIR="$PROJECT_DIR"

# Procesar argumentos de línea de comandos
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            UBUNTU_VERSION="$2"
            shift 2
            ;;
        -a|--automated)
            USE_PRESEED=true
            shift
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Opción desconocida: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validar versión de Ubuntu
if [ -z "$UBUNTU_VERSION" ]; then
    log_error "Debe especificar una versión de Ubuntu con -v o --version"
    show_help
    exit 1
fi

# Función para cargar configuración de versión
load_version_config() {
    local config_file="${PROJECT_DIR}/config/ubuntu-versions.conf"
    if [ -f "$config_file" ]; then
        source "$config_file"
    else
        log_error "Archivo de configuración no encontrado: $config_file"
        exit 1
    fi
}

# Función para configurar variables de la versión seleccionada
configure_ubuntu_version() {
    case "$UBUNTU_VERSION" in
        "20.04")
            UBUNTU_CODENAME="$UBUNTU_20_CODENAME"
            UBUNTU_SUITE="$UBUNTU_20_SUITE"
            UBUNTU_MIRROR="$UBUNTU_20_MIRROR"
            UBUNTU_SECURITY_MIRROR="$UBUNTU_20_SECURITY_MIRROR"
            ;;
        "22.04")
            UBUNTU_CODENAME="$UBUNTU_22_CODENAME"
            UBUNTU_SUITE="$UBUNTU_22_SUITE"
            UBUNTU_MIRROR="$UBUNTU_22_MIRROR"
            UBUNTU_SECURITY_MIRROR="$UBUNTU_22_SECURITY_MIRROR"
            ;;
        "24.04")
            UBUNTU_CODENAME="$UBUNTU_24_CODENAME"
            UBUNTU_SUITE="$UBUNTU_24_SUITE"
            UBUNTU_MIRROR="$UBUNTU_24_MIRROR"
            UBUNTU_SECURITY_MIRROR="$UBUNTU_24_SECURITY_MIRROR"
            ;;
        *)
            log_error "Versión de Ubuntu no soportada: $UBUNTU_VERSION"
            log_info "Versiones soportadas: 20.04, 22.04, 24.04"
            exit 1
            ;;
    esac

    log_success "Configurado para Ubuntu ${UBUNTU_VERSION} LTS (${UBUNTU_CODENAME})"
}

# Incluir funciones del script principal
source "${PROJECT_DIR}/build-iso.sh"

# Función principal para construcción automatizada
main_automated() {
    echo ""
    log_info "=== Ubuntu Live ISO Builder - Modo Automatizado ==="
    log_info "Versión: Ubuntu ${UBUNTU_VERSION}"
    log_info "Preseed: $([ "$USE_PRESEED" = true ] && echo "Habilitado" || echo "Deshabilitado")"
    log_info "Salida: ${OUTPUT_DIR}"
    echo ""

    # Verificar dependencias
    check_dependencies

    # Cargar configuración
    load_version_config
    configure_ubuntu_version

    # Preparar entorno
    prepare_build_environment

    # Configurar live-build
    configure_live_build

    # Agregar preseed si está habilitado
    if [ "$USE_PRESEED" = true ]; then
        log_info "Agregando configuración preseed..."
        local includes_dir="${BUILD_DIR}/config/includes.installer"
        mkdir -p "$includes_dir"
        cp "${TEMPLATES_DIR}/preseed.cfg" "${includes_dir}/"
        log_success "Preseed agregado"
    fi

    # Crear hooks
    create_installation_hooks

    # Construir ISO
    build_iso

    # Mover ISO al directorio de salida si es diferente
    if [ "$OUTPUT_DIR" != "$PROJECT_DIR" ]; then
        local iso_name="ubuntu-${UBUNTU_VERSION}-live-server-custom.iso"
        if [ -f "${PROJECT_DIR}/${iso_name}" ]; then
            mkdir -p "$OUTPUT_DIR"
            mv "${PROJECT_DIR}/${iso_name}" "${OUTPUT_DIR}/"
            log_success "ISO movida a: ${OUTPUT_DIR}/${iso_name}"
        fi
    fi

    echo ""
    log_success "¡Construcción automatizada completada!"
    echo ""
}

# Verificar si se ejecuta como script principal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_automated "$@"
fi