# Ubuntu Live ISO Builder

**Generador profesional de imágenes ISO personalizadas de Ubuntu Live Server**

Herramienta completa para crear imágenes ISO personalizadas de Ubuntu Live Server con soporte para múltiples versiones LTS y configuración automatizada.

## 🚀 Características

- ✅ **Soporte completo** para Ubuntu 20.04, 22.04 y 24.04 LTS
- ✅ **Configuración específica por versión** con paquetes optimizados
- ✅ **Modo interactivo y automatizado** para diferentes casos de uso
- ✅ **Hooks robustos** con validación y manejo de errores
- ✅ **Templates preseed** para instalación desatendida
- ✅ **Gestión de mirrors** optimizada por región
- ✅ **Logs detallados** y manejo de errores

## 📁 Estructura del proyecto

```
proyecto-live-build-iso/
├── config/
│   └── ubuntu-versions.conf      # Configuración de versiones y mirrors
├── scripts/
│   ├── install-dependencies.sh   # Instalación de dependencias
│   └── clean-build.sh           # Limpieza de archivos temporales
├── packages/
│   ├── apt-packages.txt          # Paquetes APT genéricos
│   ├── apt-packages-focal.txt    # Paquetes específicos Ubuntu 20.04
│   ├── apt-packages-jammy.txt    # Paquetes específicos Ubuntu 22.04
│   ├── apt-packages-noble.txt    # Paquetes específicos Ubuntu 24.04
│   └── pip-packages.txt          # Paquetes Python
├── templates/
│   └── preseed.cfg              # Template para instalación automatizada
├── build-iso.sh                 # Script principal interactivo
├── build-iso-automated.sh       # Script para construcción automatizada
└── build/                       # Directorio temporal de construcción
```

## 🔧 Instalación de dependencias

```bash
# Instalar dependencias necesarias
sudo ./scripts/install-dependencies.sh
```

## 📖 Uso

### 🐳 Con Docker (Recomendado para Ubuntu 24.04)

Si estás en Ubuntu 24.04 y quieres generar Ubuntu 20.04/22.04:

```bash
# Instalar Docker si no lo tienes
sudo apt update && sudo apt install docker.io
sudo usermod -aG docker $USER
# Reiniciar sesión después de agregar al grupo

# Ejecutar con Docker
./docker-build.sh
```

Dentro del contenedor Docker:
```bash
# Modo interactivo
./build-iso.sh

# Modo automatizado
./build-iso-automated.sh -v 20.04
```

### 💻 Modo nativo (Ubuntu 20.04 host)

#### Modo interactivo

```bash
./build-iso.sh
```

#### Modo automatizado

```bash
# Generar Ubuntu 22.04 básico
./build-iso-automated.sh --version 22.04

# Generar Ubuntu 24.04 con preseed para instalación automatizada
./build-iso-automated.sh --version 24.04 --automated

# Generar con directorio de salida personalizado
./build-iso-automated.sh -v 20.04 -o /tmp/isos

# Ver todas las opciones
./build-iso-automated.sh --help
```

## 🌍 Versiones soportadas

| Versión | Codename | Estado | Características especiales |
|---------|----------|---------|---------------------------|
| 20.04 LTS | Focal Fossa | ✅ Soportado | Cloud-init, SSH habilitado |
| 22.04 LTS | Jammy Jellyfish | ✅ Soportado | btop, snapd, cloud-init |
| 24.04 LTS | Noble Numbat | ✅ Soportado | netplan.io, últimas mejoras |

## ⚙️ Configuración

### Paquetes personalizados

- **Genéricos**: `packages/apt-packages.txt` - Aplicados a todas las versiones
- **Específicos**: `packages/apt-packages-{codename}.txt` - Solo para esa versión
- **Python**: `packages/pip-packages.txt` - Paquetes pip3

### Configuración por versión

El archivo `config/ubuntu-versions.conf` contiene:
- URLs de mirrors principales y de seguridad
- Configuraciones específicas por versión
- Parámetros de distribución

### Templates preseed

El archivo `templates/preseed.cfg` permite:
- Instalación completamente automatizada
- Usuario predeterminado: `ubuntu/ubuntu`
- SSH habilitado por defecto
- Configuraciones de red y particionado

## 🔧 Hooks de instalación

El sistema incluye hooks robustos con:

1. **Hook APT** (`0010-install-apt-packages.hook.chroot`):
   - Validación de disponibilidad de paquetes
   - Reintentos automáticos
   - Manejo de errores graceful

2. **Hook PIP** (`0020-install-pip-packages.hook.chroot`):
   - Verificación de dependencias Python
   - Instalación individual con fallback

3. **Hook configuración** (`0030-custom-config.hook.chroot`):
   - Usuario ubuntu con sudo sin password
   - SSH habilitado automáticamente
   - Timezone y locale configurados

## 🧹 Limpieza

```bash
# Limpiar archivos temporales
./scripts/clean-build.sh

# También permite eliminar ISOs anteriores interactivamente
```

## 📋 Requisitos del sistema

- Ubuntu 18.04+ o Debian 10+
- Mínimo 4GB RAM
- Mínimo 20GB espacio libre
- Permisos sudo

### Dependencias

- `live-build` - Framework principal
- `debootstrap` - Bootstrap de sistema base
- `xorriso` - Creación de imágenes ISO
- `isolinux`, `syslinux` - Bootloaders
- `squashfs-tools` - Compresión del filesystem

## 🎯 Características avanzadas

### Optimizaciones para Live Server

- Configuración `--mode ubuntu` para mejor compatibilidad
- Soporte consola serie (`console=ttyS0,115200n8`)
- Firmware incluido para mejor compatibilidad hardware
- Cache habilitado para construcciones más rápidas
- Compresión gzip optimizada

### Gestión de mirrors

- Mirrors específicos por versión de Ubuntu
- Separación entre mirrors principales y de seguridad
- Configuración centralizada en `ubuntu-versions.conf`

### Validaciones robustas

- Verificación de dependencias al inicio
- Validación de disponibilidad de paquetes
- Manejo de errores con reintentos automáticos
- Logs detallados para troubleshooting

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature: `git checkout -b feature/nueva-caracteristica`
3. Commit tus cambios: `git commit -am 'Agregar nueva característica'`
4. Push a la rama: `git push origin feature/nueva-caracteristica`
5. Crea un Pull Request

## 📝 Notas

- Las imágenes ISO se generan en el directorio raíz del proyecto
- Los archivos temporales se almacenan en `build/`
- Se recomienda usar el modo automatizado para CI/CD
- Las configuraciones preseed son opcionales pero recomendadas para despliegues