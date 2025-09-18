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

    # Limpiar directorio de construcción anterior
    if [ -d "$BUILD_DIR" ]; then
        log_info "Limpiando construcción anterior..."
        sudo rm -rf "$BUILD_DIR"
    fi

    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"

    log_success "Entorno de construcción preparado"
}

# Función para configurar live-build
configure_live_build() {
    log_info "Configurando live-build para Ubuntu ${UBUNTU_VERSION}..."

    cd "$BUILD_DIR"

    # Configuración optimizada para Live Server
    lb config \
        --distribution "$UBUNTU_SUITE" \
        --parent-distribution "$UBUNTU_SUITE" \
        --archive-areas "main restricted universe multiverse" \
        --parent-archive-areas "main restricted universe multiverse" \
        --mirror-bootstrap "$UBUNTU_MIRROR" \
        --mirror-chroot "$UBUNTU_MIRROR" \
        --mirror-binary "$UBUNTU_MIRROR" \
        --mirror-debian-installer "$UBUNTU_MIRROR" \
        --parent-mirror-bootstrap "$UBUNTU_MIRROR" \
        --parent-mirror-chroot "$UBUNTU_MIRROR" \
        --parent-mirror-binary "$UBUNTU_MIRROR" \
        --mirror-chroot-security "$UBUNTU_SECURITY_MIRROR" \
        --mirror-binary-security "$UBUNTU_SECURITY_MIRROR" \
        --parent-mirror-chroot-security "$UBUNTU_SECURITY_MIRROR" \
        --parent-mirror-binary-security "$UBUNTU_SECURITY_MIRROR" \
        --mode ubuntu \
        --architectures amd64 \
        --linux-flavours generic \
        --linux-packages linux-image \
        --binary-images iso-live \
        --memtest none \
        --bootappend-live "boot=live components quiet splash console=tty0 console=ttyS0,115200n8" \
        --bootappend-install "console=tty0 console=ttyS0,115200n8" \
        --debian-installer live \
        --debian-installer-gui false \
        --debian-installer-distribution "$UBUNTU_SUITE" \
        --iso-application "Ubuntu ${UBUNTU_VERSION} Live Server Custom" \
        --iso-publisher "Ubuntu Live ISO Builder" \
        --iso-volume "Ubuntu_${UBUNTU_VERSION}_Live_Server" \
        --bootloader grub-efi \
        --firmware-chroot true \
        --firmware-binary true \
        --apt-recommends false \
        --apt-secure true \
        --cache true \
        --cache-indices true \
        --cache-packages true \
        --compression gzip \
        --zsync false

    log_success "Configuración de live-build completada"
}

# Función para crear hooks de instalación
create_installation_hooks() {
    log_info "Creando hooks de instalación..."

    local hooks_dir="${BUILD_DIR}/config/hooks/live"
    mkdir -p "$hooks_dir"

    # Hook para paquetes APT con validaciones
    local apt_packages=$(read_apt_packages)
    log_info "DEBUG: Paquetes leídos: '$apt_packages'"
    if [ ! -z "$apt_packages" ]; then
        log_info "Paquetes APT a instalar: $(echo $apt_packages | wc -w) paquetes"
        cat > "${hooks_dir}/0010-install-apt-packages.hook.chroot" << 'EOF'
#!/bin/bash
set -e

echo "=== Instalando paquetes APT personalizados ==="

# Función para manejar errores
handle_error() {
    echo "ERROR: $1" >&2
    exit 1
}

# Configurar APT para autoinstall
echo "Configurando APT para autoinstall..."
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none

# Configurar APT para evitar interacción
cat > /etc/apt/apt.conf.d/99autoinstall << 'APT_EOF'
APT::Get::Assume-Yes "true";
APT::Get::force-yes "true";
APT::Install-Recommends "false";
APT::Install-Suggests "false";
Dpkg::Options {
   "--force-confdef";
   "--force-confold";
}
APT_EOF

# Actualizar cache de paquetes con reintentos
echo "Actualizando cache de paquetes..."
for attempt in 1 2 3; do
    if apt-get update -qq; then
        break
    elif [ $attempt -eq 3 ]; then
        handle_error "No se pudo actualizar el cache de paquetes después de 3 intentos"
    else
        echo "Intento $attempt fallido, reintentando en 10 segundos..."
        sleep 10
    fi
done

# Instalar paquetes optimizado para autoinstall
PACKAGES="PACKAGES_PLACEHOLDER"
if [ ! -z "$PACKAGES" ]; then
    echo "Instalando paquetes para autoinstall: $PACKAGES"

    # Limpiar duplicados y espacios extra
    PACKAGES=$(echo $PACKAGES | tr ' ' '\n' | sort -u | tr '\n' ' ')

    # Verificar disponibilidad de paquetes en lotes
    echo "Verificando disponibilidad de paquetes..."
    available_packages=""
    missing_packages=""

    for package in $PACKAGES; do
        if apt-cache policy "$package" 2>/dev/null | grep -q "Candidate:"; then
            available_packages="$available_packages $package"
        else
            missing_packages="$missing_packages $package"
        fi
    done

    if [ ! -z "$missing_packages" ]; then
        echo "ADVERTENCIA: Paquetes no disponibles:$missing_packages"
    fi

    # Instalar paquetes disponibles en una sola operación
    if [ ! -z "$available_packages" ]; then
        echo "Instalando paquetes disponibles..."
        apt-get install -y --no-install-recommends --no-install-suggests $available_packages || {
            echo "Error en instalación masiva, intentando paquete por paquete..."
            for package in $available_packages; do
                echo "Instalando $package..."
                apt-get install -y --no-install-recommends --no-install-suggests "$package" || echo "ADVERTENCIA: No se pudo instalar $package"
            done
        }
    fi
fi

# Limpiar cache y configuración temporal
echo "Limpiando configuración temporal..."
rm -f /etc/apt/apt.conf.d/99autoinstall
apt-get autoremove -y -qq
apt-get autoclean -qq
apt-get clean -qq

echo "=== Instalación de paquetes APT completada ==="
EOF
        # Reemplazar placeholder con paquetes reales usando archivo temporal
        temp_file=$(mktemp)
        while IFS= read -r line; do
            if [[ "$line" == *"PACKAGES_PLACEHOLDER"* ]]; then
                echo "${line/PACKAGES_PLACEHOLDER/$apt_packages}"
            else
                echo "$line"
            fi
        done < "${hooks_dir}/0010-install-apt-packages.hook.chroot" > "$temp_file"
        mv "$temp_file" "${hooks_dir}/0010-install-apt-packages.hook.chroot"
        chmod +x "${hooks_dir}/0010-install-apt-packages.hook.chroot"
        log_success "Hook de paquetes APT creado con validaciones"
    fi

    # Hook para paquetes PIP con validaciones
    local pip_packages=$(read_pip_packages)
    if [ ! -z "$pip_packages" ]; then
        cat > "${hooks_dir}/0020-install-pip-packages.hook.chroot" << 'EOF'
#!/bin/bash
set -e

echo "=== Instalando paquetes PIP personalizados ==="

# Función para manejar errores
handle_error() {
    echo "ERROR: $1" >&2
    exit 1
}

# Configurar PIP para autoinstall
echo "Configurando PIP para autoinstall..."
export PIP_DISABLE_PIP_VERSION_CHECK=1
export PIP_NO_INPUT=1
export PIP_QUIET=2

# Verificar que pip3 esté disponible
if ! command -v pip3 &> /dev/null; then
    echo "pip3 no está disponible, instalando..."
    DEBIAN_FRONTEND=noninteractive apt-get update -qq
    DEBIAN_FRONTEND=noninteractive apt-get install -y python3-pip python3-venv || handle_error "No se pudo instalar python3-pip"
fi

# Configurar pip para instalación no interactiva
mkdir -p /root/.config/pip
cat > /root/.config/pip/pip.conf << 'PIP_EOF'
[global]
disable-pip-version-check = true
no-input = true
quiet = 2
timeout = 60
retries = 3
trusted-host = pypi.org
               pypi.python.org
               files.pythonhosted.org
PIP_EOF

# Actualizar pip silenciosamente
echo "Actualizando pip..."
pip3 install --upgrade pip --quiet --no-warn-script-location || echo "ADVERTENCIA: No se pudo actualizar pip"

# Instalar paquetes PIP optimizado para autoinstall
PACKAGES="PIP_PACKAGES_PLACEHOLDER"
if [ ! -z "$PACKAGES" ]; then
    echo "Instalando paquetes PIP para autoinstall: $PACKAGES"

    # Limpiar duplicados y espacios extra
    PACKAGES=$(echo $PACKAGES | tr ' ' '\n' | sort -u | tr '\n' ' ')

    # Instalar paquetes con configuración optimizada
    for package in $PACKAGES; do
        echo "Instalando $package..."
        pip3 install "$package" --quiet --no-warn-script-location --disable-pip-version-check || {
            echo "Error instalando $package, intentando con --user..."
            pip3 install "$package" --user --quiet --no-warn-script-location --disable-pip-version-check || echo "ADVERTENCIA: No se pudo instalar $package"
        }
    done

    # Verificar instalaciones
    echo "Verificando instalaciones PIP..."
    for package in $PACKAGES; do
        if pip3 show "$package" >/dev/null 2>&1; then
            echo "✓ $package instalado correctamente"
        else
            echo "✗ $package no se instaló correctamente"
        fi
    done
fi

# Limpiar configuración temporal
echo "Limpiando configuración temporal PIP..."
rm -f /root/.config/pip/pip.conf

echo "=== Instalación de paquetes PIP completada ==="
EOF
        # Reemplazar placeholder con paquetes reales usando archivo temporal
        temp_file=$(mktemp)
        while IFS= read -r line; do
            if [[ "$line" == *"PIP_PACKAGES_PLACEHOLDER"* ]]; then
                echo "${line/PIP_PACKAGES_PLACEHOLDER/$pip_packages}"
            else
                echo "$line"
            fi
        done < "${hooks_dir}/0020-install-pip-packages.hook.chroot" > "$temp_file"
        mv "$temp_file" "${hooks_dir}/0020-install-pip-packages.hook.chroot"
        chmod +x "${hooks_dir}/0020-install-pip-packages.hook.chroot"
        log_success "Hook de paquetes PIP creado con validaciones"
    fi

    # Hook para configuraciones adicionales específicas por versión
    cat > "${hooks_dir}/0030-custom-config.hook.chroot" << 'EOF'
#!/bin/bash
set -e

echo "=== Aplicando configuraciones personalizadas ==="

# Función para manejar errores
handle_error() {
    echo "ERROR: $1" >&2
    exit 1
}

# Habilitar SSH por defecto
echo "Habilitando SSH..."
if systemctl list-unit-files ssh.service >/dev/null 2>&1; then
    systemctl enable ssh || echo "ADVERTENCIA: No se pudo habilitar SSH"
elif systemctl list-unit-files sshd.service >/dev/null 2>&1; then
    systemctl enable sshd || echo "ADVERTENCIA: No se pudo habilitar SSHD"
fi

# Configurar timezone a UTC
echo "Configurando timezone a UTC..."
echo "UTC" > /etc/timezone
if command -v dpkg-reconfigure &> /dev/null; then
    dpkg-reconfigure -f noninteractive tzdata || echo "ADVERTENCIA: No se pudo configurar timezone"
fi

# Configurar teclado español latino
echo "Configurando teclado español latino..."
cat > /etc/default/keyboard << 'KEYBOARD_EOF'
XKBMODEL="pc105"
XKBLAYOUT="latam"
XKBVARIANT=""
XKBOPTIONS=""
KEYBOARD_EOF

# Configurar locale
echo "Configurando locale..."
if command -v locale-gen &> /dev/null; then
    locale-gen en_US.UTF-8 || echo "ADVERTENCIA: No se pudo generar locale en_US.UTF-8"
    locale-gen es_ES.UTF-8 || echo "ADVERTENCIA: No se pudo generar locale es_ES.UTF-8"
fi

# Configurar usuario ubuntu por defecto para Live Server
echo "Configurando usuario ubuntu..."
if ! id ubuntu >/dev/null 2>&1; then
    useradd -m -s /bin/bash -G sudo ubuntu || echo "ADVERTENCIA: No se pudo crear usuario ubuntu"
    echo "ubuntu:ubuntu" | chpasswd || echo "ADVERTENCIA: No se pudo establecer password para ubuntu"
fi

# Configurar sudoers para usuario ubuntu
echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu || echo "ADVERTENCIA: No se pudo configurar sudoers"

echo "=== Configuraciones personalizadas aplicadas ==="
EOF
    chmod +x "${hooks_dir}/0030-custom-config.hook.chroot"
    log_success "Hook de configuraciones personalizadas creado"
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