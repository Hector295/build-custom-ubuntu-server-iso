# Dockerfile para Ubuntu Live ISO Builder
FROM ubuntu:20.04

# Evitar prompts interactivos durante la instalación
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Instalar dependencias necesarias
RUN apt-get update && apt-get install -y \
    live-build \
    debootstrap \
    xorriso \
    isolinux \
    syslinux \
    syslinux-utils \
    memtest86+ \
    dosfstools \
    squashfs-tools \
    genisoimage \
    rsync \
    wget \
    curl \
    sudo \
    xz-utils \
    gzip \
    bzip2 \
    cpio \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Crear directorio de trabajo
WORKDIR /workspace

# Configurar permisos para live-build
RUN chmod 755 /workspace

# El punto de entrada será bash para ejecutar scripts
CMD ["/bin/bash"]