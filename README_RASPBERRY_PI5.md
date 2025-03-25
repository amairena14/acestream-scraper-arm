# Acestream Scraper para Raspberry Pi 5

Esta guía explica cómo instalar y ejecutar Acestream Scraper en una Raspberry Pi 5 utilizando Docker.

## Requisitos

- Raspberry Pi 5 con Raspberry Pi OS (64-bit) o similar
- Al menos 2GB de RAM disponible
- Al menos 4GB de espacio en disco
- Conexión a Internet

## Instalación rápida

1. Clona este repositorio:

```bash
git clone https://github.com/Pipepito/acestream-scraper.git
cd acestream-scraper
```

2. Ejecuta el script de instalación:

```bash
sudo chmod +x install_raspberry_pi5.sh
sudo ./install_raspberry_pi5.sh
```

Esto instalará Docker si es necesario, configurará el entorno y ejecutará el contenedor.

3. Accede a la interfaz web:

Abre un navegador y visita `http://[IP-DE-TU-RASPBERRY]:8000`

## Instalación manual

Si prefieres realizar la instalación manualmente, sigue estos pasos:

1. Instala Docker y Docker Compose:

```bash
sudo apt-get update
sudo apt-get install -y docker.io docker-compose
```

2. Crea los directorios para datos:

```bash
mkdir -p ./data/zeronet
mkdir -p ./data/config
```

3. Ejecuta el contenedor con Docker Compose:

```bash
docker-compose -f docker-compose.arm64.yml up -d
```

## Configuración

La configuración predeterminada debería funcionar en la mayoría de los casos. Si necesitas personalizar la configuración, puedes editar el archivo `docker-compose.arm64.yml` antes de ejecutar el contenedor.

### Variables de entorno importantes

- `ENABLE_TOR`: Habilita o deshabilita el servicio Tor (true/false)
- `ENABLE_ACEXY`: Habilita o deshabilita el proxy Acexy (true/false)
- `ENABLE_ACESTREAM_ENGINE`: Habilita o deshabilita el motor Acestream (true/false)
- `ENABLE_WARP`: Habilita o deshabilita Cloudflare WARP (true/false)
- `ALLOW_REMOTE_ACCESS`: Permite acceso remoto al motor Acestream (yes/no)

## Solución de problemas

### Verificar el estado del contenedor

```bash
docker-compose -f docker-compose.arm64.yml ps
```

### Ver los logs

```bash
docker-compose -f docker-compose.arm64.yml logs -f
```

### Reiniciar el contenedor

```bash
docker-compose -f docker-compose.arm64.yml restart
```

### Problemas con WARP

Si experimentas problemas con WARP, puedes deshabilitarlo cambiando `ENABLE_WARP=true` a `ENABLE_WARP=false` en el archivo `docker-compose.arm64.yml`.

## Consideraciones para Raspberry Pi 5

- El contenedor está optimizado para la arquitectura ARM64 de la Raspberry Pi 5
- Se ha configurado para utilizar la versión ARM del motor Acestream
- Cloudflare WARP está configurado para funcionar correctamente en ARM64

## Limitaciones conocidas

- El rendimiento puede ser inferior al de un PC de escritorio debido a las limitaciones de hardware de la Raspberry Pi
- Algunos streams de alta calidad pueden no reproducirse correctamente si la conexión a Internet o el hardware no son suficientemente potentes

## Recursos adicionales

- [Wiki completa del proyecto](https://github.com/Pipepito/acestream-scraper/wiki)
- [Configuración avanzada](https://github.com/Pipepito/acestream-scraper/wiki/Configuration)
- [Preguntas frecuentes](https://github.com/Pipepito/acestream-scraper/wiki/FAQ)