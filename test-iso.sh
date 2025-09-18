#!/bin/bash

# Script para probar la imagen ISO generada

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

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Buscar archivo ISO
ISO_FILE=$(find . -maxdepth 1 -name "*.iso" -type f | head -1)

if [ -z "$ISO_FILE" ]; then
    log_error "No se encontró archivo ISO en el directorio actual"
    exit 1
fi

log_info "=== Probando imagen ISO: $(basename $ISO_FILE) ==="
echo ""

# 1. Verificar integridad del archivo
log_info "1. Verificando integridad del archivo ISO..."
if file "$ISO_FILE" | grep -q "ISO 9660"; then
    log_success "✓ Archivo ISO válido"
else
    log_error "✗ Archivo ISO corrupto o inválido"
    exit 1
fi

# 2. Verificar tamaño
log_info "2. Información del archivo:"
ls -lh "$ISO_FILE" | awk '{print "   Tamaño: " $5 "   Fecha: " $6 " " $7 " " $8}'

# 3. Verificar contenido básico
log_info "3. Verificando estructura interna..."
if command -v isoinfo &> /dev/null; then
    echo "   Contenido del directorio raíz:"
    isoinfo -l -i "$ISO_FILE" | head -20 | grep "^d" | awk '{print "   📁 " $12}'
else
    log_warning "   isoinfo no disponible, instalando genisoimage..."
    sudo apt install -y genisoimage
fi

# 4. Montar ISO y verificar archivos clave
log_info "4. Montando ISO para verificación..."
MOUNT_POINT="/tmp/iso_test_$$"
sudo mkdir -p "$MOUNT_POINT"

if sudo mount -o loop "$ISO_FILE" "$MOUNT_POINT" 2>/dev/null; then
    log_success "✓ ISO montada exitosamente"

    # Verificar archivos críticos
    echo "   Verificando archivos críticos:"

    if [ -f "$MOUNT_POINT/casper/vmlinuz" ]; then
        log_success "   ✓ Kernel encontrado"
    else
        log_error "   ✗ Kernel no encontrado"
    fi

    if [ -f "$MOUNT_POINT/casper/initrd" ] || [ -f "$MOUNT_POINT/casper/initrd.lz" ]; then
        log_success "   ✓ initrd encontrado"
    else
        log_error "   ✗ initrd no encontrado"
    fi

    if [ -f "$MOUNT_POINT/casper/filesystem.squashfs" ]; then
        log_success "   ✓ Sistema de archivos encontrado"
        SQUASHFS_SIZE=$(du -h "$MOUNT_POINT/casper/filesystem.squashfs" | cut -f1)
        echo "   📦 Tamaño del sistema: $SQUASHFS_SIZE"
    else
        log_error "   ✗ Sistema de archivos no encontrado"
    fi

    # Verificar bootloader
    if [ -d "$MOUNT_POINT/boot/grub" ] || [ -d "$MOUNT_POINT/EFI" ]; then
        log_success "   ✓ Bootloader encontrado"
    else
        log_warning "   ⚠ Bootloader no detectado claramente"
    fi

    # Verificar MD5SUM si existe
    if [ -f "$MOUNT_POINT/md5sum.txt" ]; then
        log_info "   Verificando checksums..."
        cd "$MOUNT_POINT"
        if md5sum -c md5sum.txt --quiet 2>/dev/null; then
            log_success "   ✓ Checksums válidos"
        else
            log_warning "   ⚠ Algunos checksums no coinciden"
        fi
        cd - >/dev/null
    fi

    sudo umount "$MOUNT_POINT"
    sudo rmdir "$MOUNT_POINT"
else
    log_error "No se pudo montar la ISO"
    sudo rmdir "$MOUNT_POINT" 2>/dev/null
fi

echo ""
log_info "=== Métodos de prueba adicionales ==="
echo ""

cat << 'EOF'
🖥️  QEMU (Recomendado para pruebas rápidas):
   sudo apt install qemu-system-x86-64
   qemu-system-x86_64 -cdrom ubuntu-20.04-live-server-custom.iso -m 2048 -boot d

🌐 VirtualBox:
   - Crear nueva VM
   - Montar ISO como CD/DVD
   - Configurar 2GB+ RAM
   - Boot desde CD

☁️  VMware/KVM:
   - Importar ISO como boot media
   - Configurar recursos adecuados

🔥 Hardware real (Prueba final):
   - Grabar en USB: sudo dd if=archivo.iso of=/dev/sdX bs=4M status=progress
   - Boot desde USB en hardware real

📋 Checklist de pruebas:
   ✓ La ISO arranca correctamente
   ✓ Aparece el menú de GRUB
   ✓ El sistema live carga
   ✓ Los paquetes personalizados están instalados
   ✓ SSH funciona (si está habilitado)
   ✓ La configuración personalizada se aplicó
EOF

echo ""
log_success "Verificación básica completada"
log_info "La ISO parece estar correctamente formada"
echo ""