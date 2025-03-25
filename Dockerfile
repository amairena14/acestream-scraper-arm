# Primera etapa: Compilación de Acexy
FROM golang:1.22 AS acexy-builder
WORKDIR /app
RUN git clone https://github.com/Javinator9889/acexy.git . && \
    cd acexy && \
    CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -o /acexy

# Segunda etapa: Imagen principal para ARM64
FROM python:3.10-slim-bullseye

# Metadatos
LABEL maintainer="pipepito" \
      description="Acestream channel scraper with ZeroNet support (ARM64 compatible)" \
      version="1.2.14-arm64"

# Directorio de trabajo y configuración
WORKDIR /app
RUN mkdir -p /app/config

# Instalar dependencias del sistema
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    gnupg \
    gcc \
    python3-dev \
    build-essential \
    tor \
    sudo \
    ca-certificates \
    lsb-release \
    dirmngr \
    apt-transport-https \
    --no-install-recommends

# Configuración de TOR
RUN echo "ControlPort 9051" >> /etc/tor/torrc && \
    echo "CookieAuthentication 1" >> /etc/tor/torrc

# Copiar archivos de la aplicación
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod 0755 /app/entrypoint.sh
COPY requirements.txt requirements-prod.txt ./
COPY migrations/ ./migrations/
COPY migrations_app.py manage.py ./
COPY wsgi.py ./
COPY app/ ./app/

# Instalar dependencias Python
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir -r requirements-prod.txt

# Instalar dependencias de ZeroNet
RUN pip install --no-cache-dir \
    "msgpack-python" \
    "gevent==22.10.2" \
    "PySocks" \
    "gevent-websocket" \
    "python-bitcoinlib" \
    "bencode.py" \
    "merkletools" \
    "pysha3" \
    "cgi-tools" \
    "urllib3<2.0.0" \
    "rich" \
    "requests" \
    "pyaes" \
    "coincurve" \
    "base58" \
    "defusedxml" \
    "rsa"

# Descargar e instalar ZeroNet
RUN mkdir -p ZeroNet && \
    wget https://github.com/zeronet-conservancy/zeronet-conservancy/archive/refs/heads/master.tar.gz -O ZeroNet.tar.gz && \
    tar xvf ZeroNet.tar.gz && \
    mv zeronet-conservancy-master/* ZeroNet/ && \
    rm -rf ZeroNet.tar.gz zeronet-conservancy-master

# Configurar shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Instalación de Acestream para ARM
ADD engine_3.1.80_armv7.tar.gz /tmp
RUN cd /tmp/acestream.engine && \
    mv androidfs/system / && \
    mv androidfs/acestream.engine / && \
    mkdir -p /storage && \
    mkdir -p /system/etc && \
    ln -s /etc/resolv.conf /system/etc/resolv.conf && \
    ln -s /etc/hosts /system/etc/hosts && \
    chown -R root:root /system && \
    find /system -type d -exec chmod 755 {} \; && \
    find /system -type f -exec chmod 644 {} \;

# Copiar el binario Acexy desde la primera etapa
COPY --from=acexy-builder /acexy /usr/local/bin/acexy
RUN chmod +x /usr/local/bin/acexy

# Instalación de Cloudflare WARP para ARM64
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    gnupg \
    curl \
    lsb-release \
    dirmngr \
    ca-certificates \
    --no-install-recommends

# Añadir clave GPG y repositorio de Cloudflare (modificado para ARM64)
RUN curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg \
    && echo "deb [arch=arm64 signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list

# Instalar Cloudflare WARP
RUN apt-get update && apt-get install -y cloudflare-warp \
    && rm -rf /var/lib/apt/lists/*

# Copiar el script de configuración de WARP
COPY warp-setup.sh /app/warp-setup.sh
RUN chmod +x /app/warp-setup.sh

# Copiar scripts adicionales
COPY healthcheck.sh /app/healthcheck.sh
RUN chmod +x /app/healthcheck.sh

# Variables de entorno
ENV DOCKER_ENV=true
ENV TZ='Europe/Madrid'
ENV ENABLE_TOR=false
ENV ENABLE_ACEXY=false
ENV ENABLE_ACESTREAM_ENGINE=false
ENV ENABLE_WARP=false
ENV WARP_ENABLE_NAT=true
ENV WARP_ENABLE_IPV6=false
ENV ACESTREAM_HTTP_PORT=6878
ENV IPV6_DISABLED=true

ENV FLASK_PORT=8000
ENV ACEXY_LISTEN_ADDR=":8080"
ENV ACEXY_HOST="localhost"
ENV ACEXY_PORT=6878
ENV ALLOW_REMOTE_ACCESS="no"
ENV ACEXY_NO_RESPONSE_TIMEOUT=15s
ENV ACEXY_BUFFER_SIZE=5MiB
ENV ACESTREAM_HTTP_HOST=ACEXY_HOST

# Flags adicionales para Acestream
ENV EXTRA_FLAGS="--cache-dir /tmp --cache-limit 2 --cache-auto 1 --log-stderr --log-stderr-level error"

# Exponer puertos
EXPOSE 8000
EXPOSE 43110
EXPOSE 43111
EXPOSE 26552
EXPOSE 8080
EXPOSE 8621
EXPOSE 6878

# Volumen para ZeroNet
VOLUME ["/app/ZeroNet/data"]

# Limpiar APT
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Asegurar que el directorio de trabajo es correcto
WORKDIR /app

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s \
    CMD /app/healthcheck.sh

# IMPORTANTE: Es necesario añadir las siguientes capacidades cuando se ejecuta el contenedor con WARP habilitado:
# --cap-add NET_ADMIN
# --cap-add SYS_ADMIN
# Ejemplo: docker run --cap-add NET_ADMIN --cap-add SYS_ADMIN -e ENABLE_WARP=true ...

ENTRYPOINT ["/app/entrypoint.sh"]
