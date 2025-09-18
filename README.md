# Ubuntu Live ISO Builder

Aplicación para generar imágenes ISO personalizadas de Ubuntu Live Server.

## Estructura del proyecto

```
├── config/           # Archivos de configuración
├── scripts/          # Scripts de construcción
├── packages/         # Listas de paquetes
├── templates/        # Templates de configuración live-build
└── build/           # Directorio de construcción temporal
```

## Uso

```bash
./build-iso.sh
```

## Versiones soportadas

- Ubuntu 20.04 LTS (Focal Fossa)
- Ubuntu 22.04 LTS (Jammy Jellyfish)
- Ubuntu 24.04 LTS (Noble Numbat)

## Archivos de configuración

- `packages/apt-packages.txt`: Lista de paquetes APT a instalar
- `packages/pip-packages.txt`: Lista de paquetes Python a instalar