#!/bin/bash

# Script de instalación para Acestream Scraper en Raspberry Pi 5
# Este script configura el entorno y ejecuta el contenedor Docker

echo "=== Instalación de Acestream Scraper para Raspberry Pi 5 ==="

# Verificar si se ejecuta como root
if [ "$(id -u)" -ne 0 ]; then
    echo "Este script debe ejecutarse como root o con sudo"
    exit 1
fi

# Verificar si Docker está instalado
if ! command -v docker &> /dev/null; then
    echo "Docker no está instalado. Instalando Docker..."
    
    # Actualizar repositorios
    apt-get update
    
    # Instalar dependencias
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Añadir clave GPG oficial de Docker
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Configurar repositorio
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Actualizar e instalar Docker
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Instalar Docker Compose
    apt-get install -y docker-compose
    
    echo "Docker instalado correctamente"
fi

# Crear dispositivo TUN si no existe
if [ ! -e /dev/net/tun ]; then
    echo "Creando dispositivo TUN..."
    mkdir -p /dev/net
    mknod /dev/net/tun c 10 200
    chmod 600 /dev/net/tun
fi

# Crear directorios para datos
echo "Creando directorios para datos..."
mkdir -p ./data/zeronet
mkdir -p ./data/config

# Verificar permisos
chmod -R 755 ./data

# Ejecutar con Docker Compose
echo "Iniciando contenedor con Docker Compose..."
docker-compose -f docker-compose.arm64.yml up -d

echo ""
echo "=== Instalación completada ==="
echo "Acestream Scraper está ejecutándose en segundo plano"
echo "Accede a la interfaz web en: http://localhost:8000"
echo ""
echo "Para ver los logs: docker-compose -f docker-compose.arm64.yml logs -f"
echo "Para detener: docker-compose -f docker-compose.arm64.yml down"