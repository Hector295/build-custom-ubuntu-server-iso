#!/bin/bash

# Ubuntu Live ISO Builder
# Script principal para generar imágenes ISO personalizadas

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

# Función para verificar dependencias
check_dependencies() {
    log_info "Verificando dependencias..."

    local deps=("live-build" "debootstrap" "xorriso")
    local missing_deps=()

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Faltan las siguientes dependencias: ${missing_deps[*]}"
        log_info "Instala las dependencias con:"
        log_info "sudo apt update && sudo apt install -y live-build debootstrap xorriso"
        exit 1
    fi

    log_success "Todas las dependencias están instaladas"
}

# Función para mostrar el menú de selección de Ubuntu
# Función para cargar configuración de versión
load_version_config() {
    local config_file="${PROJECT_DIR}/config/ubuntu-versions.conf"
    if [ -f "$config_file" ]; then
        source "$config_file"
    else
        log_warning "Archivo de configuración no encontrado: $config_file"
    fi
}

select_ubuntu_version() {
    echo ""
    log_info "Selecciona la versión de Ubuntu Live Server:"
    echo "1) Ubuntu 20.04 LTS (Focal Fossa)"
    echo "2) Ubuntu 22.04 LTS (Jammy Jellyfish)"
    echo "3) Ubuntu 24.04 LTS (Noble Numbat)"
    echo ""

    while true; do
        read -p "Ingresa tu opción (1-3): " choice
        case $choice in
            1)
                UBUNTU_VERSION="$UBUNTU_20_VERSION"
                UBUNTU_CODENAME="$UBUNTU_20_CODENAME"
                UBUNTU_SUITE="$UBUNTU_20_SUITE"
                UBUNTU_MIRROR="$UBUNTU_20_MIRROR"
                UBUNTU_SECURITY_MIRROR="$UBUNTU_20_SECURITY_MIRROR"
                break
                ;;
            2)
                UBUNTU_VERSION="$UBUNTU_22_VERSION"
                UBUNTU_CODENAME="$UBUNTU_22_CODENAME"
                UBUNTU_SUITE="$UBUNTU_22_SUITE"
                UBUNTU_MIRROR="$UBUNTU_22_MIRROR"
                UBUNTU_SECURITY_MIRROR="$UBUNTU_22_SECURITY_MIRROR"
                break
                ;;
            3)
                UBUNTU_VERSION="$UBUNTU_24_VERSION"
                UBUNTU_CODENAME="$UBUNTU_24_CODENAME"
                UBUNTU_SUITE="$UBUNTU_24_SUITE"
                UBUNTU_MIRROR="$UBUNTU_24_MIRROR"
                UBUNTU_SECURITY_MIRROR="$UBUNTU_24_SECURITY_MIRROR"
                break
                ;;
            *)
                log_error "Opción inválida. Por favor selecciona 1, 2 o 3."
                ;;
        esac
    done

    log_success "Seleccionada: Ubuntu ${UBUNTU_VERSION} LTS (${UBUNTU_CODENAME})"
    log_info "Mirror principal: ${UBUNTU_MIRROR}"
    log_info "Mirror de seguridad: ${UBUNTU_SECURITY_MIRROR}"
}

# Función para leer paquetes APT
read_apt_packages() {
    local apt_file_generic="${PACKAGES_DIR}/apt-packages.txt"
    local apt_file_specific="${PACKAGES_DIR}/apt-packages-${UBUNTU_CODENAME}.txt"
    local packages=""

    # Leer paquetes genéricos (sin logs para evitar contaminar la salida)
    if [ -f "$apt_file_generic" ]; then
        while IFS= read -r line; do
            # Ignorar líneas vacías y comentarios
            if [[ ! -z "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
                packages="${packages} ${line}"
            fi
        done < "$apt_file_generic"
    fi

    # Leer paquetes específicos de la versión (sin logs para evitar contaminar la salida)
    if [ -f "$apt_file_specific" ]; then
        while IFS= read -r line; do
            # Ignorar líneas vacías y comentarios
            if [[ ! -z "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
                packages="${packages} ${line}"
            fi
        done < "$apt_file_specific"
    fi

    # Filtrar solo nombres de paquetes válidos (sin .txt, espacios, caracteres especiales problemáticos)
    packages=$(echo "$packages" | tr ' ' '\n' | grep -v '\.txt$' | grep -v '^$' | grep -E '^[a-zA-Z0-9][a-zA-Z0-9\.\-\+]*$' | tr '\n' ' ')

    # Solo devolver los nombres de paquetes limpios
    echo "$packages"
}

# Función para leer paquetes PIP
read_pip_packages() {
    local pip_file="${PACKAGES_DIR}/pip-packages.txt"
    local packages=""

    if [ -f "$pip_file" ]; then
        log_info "Leyendo paquetes PIP desde ${pip_file}..."
        while IFS= read -r line; do
            # Ignorar líneas vacías y comentarios
            if [[ ! -z "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
                packages="${packages} ${line}"
            fi
        done < "$pip_file"
        echo "$packages"
    else
        log_warning "Archivo de paquetes PIP no encontrado: ${pip_file}"
        echo ""
    fi
}

# Función para preparar el entorno de construcción
prepare_build_environment() {
    log_info "Preparando entorno de construcción..."

    # Limpiar directorio de construcción anterior y cache
    if [ -d "$BUILD_DIR" ]; then
        log_info "Limpiando construcción anterior y cache..."
        sudo rm -rf "$BUILD_DIR"
    fi

    # Limpiar cache global de live-build que puede estar corrupto
    if [ -d "/var/cache/live" ]; then
        log_info "Limpiando cache global de live-build..."
        sudo rm -rf /var/cache/live
    fi

    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"

    log_success "Entorno de construcción preparado"
}

# Función para configurar live-build
configure_live_build() {
    log_info "Configurando live-build para Ubuntu ${UBUNTU_VERSION}..."

    cd "$BUILD_DIR"

    # Configuración simple para Live Server
    lb config --system live \
        --distribution "$UBUNTU_SUITE" \
        --archive-areas "main restricted universe multiverse" \
        --mode ubuntu \
        --architectures amd64 \
        --binary-images iso-hybrid \
        --bootloader grub-efi \
        --zsync false \
        --debug --verbose


    log_success "Configuración de live-build completada"
}

# Función para crear hooks de instalación
create_installation_hooks() {
    log_info "Creando hooks de instalación..."

    local hooks_dir="${BUILD_DIR}/config/hooks/live"
    mkdir -p "$hooks_dir"

    # Hook simple para paquetes APT
    local apt_packages=$(read_apt_packages)
    if [ ! -z "$apt_packages" ]; then
        log_info "Paquetes APT a instalar: $(echo $apt_packages | wc -w) paquetes"
        cat > "${hooks_dir}/0010-install-apt.hook.chroot" << EOF
#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

echo "=== Instalando paquetes APT ==="
apt-get update
apt-get install -y $apt_packages
apt-get clean
echo "=== Paquetes APT instalados ==="
EOF
        chmod +x "${hooks_dir}/0010-install-apt.hook.chroot"
        log_success "Hook APT creado"
    fi

    # Hook simple para paquetes PIP
    local pip_packages=$(read_pip_packages)
    if [ ! -z "$pip_packages" ]; then
        log_info "Paquetes PIP a instalar: $pip_packages"
        cat > "${hooks_dir}/0020-install-pip.hook.chroot" << EOF
#!/bin/bash
set -e

echo "=== Instalando paquetes PIP ==="
pip3 install $pip_packages
echo "=== Paquetes PIP instalados ==="
EOF
        chmod +x "${hooks_dir}/0020-install-pip.hook.chroot"
        log_success "Hook PIP creado"
    fi
}

# Función principal de construcción
build_iso() {
    log_info "Iniciando construcción de la imagen ISO..."

    cd "$BUILD_DIR"

    # Ejecutar la construcción
    log_info "Ejecutando lb build..."
    sudo lb build

    # Verificar si la ISO fue creada
    local iso_file=$(find . -name "*.iso" -type f | head -1)
    if [ ! -z "$iso_file" ]; then
        local final_name="ubuntu-${UBUNTU_VERSION}-live-server-custom.iso"
        mv "$iso_file" "${PROJECT_DIR}/${final_name}"

        # Hacer la ISO híbrida/booteable si no lo es
        log_info "Verificando si la ISO es booteable..."
        if command -v isohybrid &> /dev/null; then
            log_info "Convirtiendo a ISO híbrida booteable..."
            isohybrid "${PROJECT_DIR}/${final_name}" 2>/dev/null || log_warning "No se pudo convertir a híbrida"
        fi

        log_success "¡ISO creada exitosamente!"
        log_success "Ubicación: ${PROJECT_DIR}/${final_name}"

        # Mostrar información del archivo
        local file_size=$(du -h "${PROJECT_DIR}/${final_name}" | cut -f1)
        log_info "Tamaño del archivo: ${file_size}"
    else
        log_error "Error: No se pudo encontrar la imagen ISO generada"
        exit 1
    fi
}

# Función principal
main() {
    echo ""
    log_info "=== Ubuntu Live ISO Builder ==="
    echo ""

    check_dependencies
    load_version_config
    select_ubuntu_version
    prepare_build_environment
    configure_live_build
    create_installation_hooks
    build_iso

    echo ""
    log_success "¡Proceso completado exitosamente!"
    echo ""
}

# Verificar si se ejecuta como script principal
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi