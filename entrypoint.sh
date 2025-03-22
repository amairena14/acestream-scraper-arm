#!/bin/bash

# Initialize WARP if enabled
if [ "${ENABLE_WARP}" = "true" ]; then
    echo "Initializing Cloudflare WARP..."
    /app/warp-setup.sh
fi

# Set ENABLE_ACESTREAM_ENGINE to match ENABLE_ACEXY if not explicitly set
if [ -z "${ENABLE_ACESTREAM_ENGINE+x}" ]; then
    export ENABLE_ACESTREAM_ENGINE=$ENABLE_ACEXY
    echo "ENABLE_ACESTREAM_ENGINE not set, using ENABLE_ACEXY value: $ENABLE_ACESTREAM_ENGINE"
fi

# Update ACESTREAM_HTTP_HOST to use the actual value of ACEXY_HOST
if [ "$ACESTREAM_HTTP_HOST" = "ACEXY_HOST" ]; then
    export ACESTREAM_HTTP_HOST="$ACEXY_HOST"
    echo "Setting ACESTREAM_HTTP_HOST to $ACEXY_HOST"
fi

# Run database migrations
cd /app
echo "Running database migrations..."
python manage.py upgrade

# Setup ZeroNet config if not exists
ZERONET_CONFIG="/app/config/zeronet.conf"
if [ ! -f "$ZERONET_CONFIG" ]; then
    echo "Creating default ZeroNet config..."
    cat > "$ZERONET_CONFIG" << EOF
[global]
ui_ip = *
ui_host =
 0.0.0.0
 localhost
ui_port = 43110
EOF
fi

# Create symlink to config
ln -sf "$ZERONET_CONFIG" /app/ZeroNet/zeronet.conf

# Start Tor if enabled
if [ "$ENABLE_TOR" = "true" ]; then
    echo "Starting Tor service..."
    service tor start
    sleep 3  # Brief pause to ensure Tor has time to start
fi

# Start Acestream Engine if enabled (ARM version)
if [ "$ENABLE_ACESTREAM_ENGINE" = "true" ]; then
    echo "Starting Acestream engine (ARM version)..."
    if [ "$ALLOW_REMOTE_ACCESS" = "yes" ]; then
        EXTRA_FLAGS="$EXTRA_FLAGS --bind-all"
    fi
    # Invoca el script de inicio de Acestream para ARM.
    /system/bin/acestream.sh $EXTRA_FLAGS &
    sleep 3  # Brief pause to allow Acestream engine to start
fi

# Start Acexy if enabled
if [ "$ENABLE_ACEXY" = "true" ]; then
    if [ "$ENABLE_ACESTREAM_ENGINE" = "false" ] && [ "$ACEXY_HOST" = "localhost" ] && [ "$ACEXY_PORT" = "6878" ]; then
        echo "ERROR: When Acestream Engine is disabled, you must specify ACEXY_HOST and ACEXY_PORT other than localhost to connect to an external Acestream Engine instance"
        exit 1
    fi

    echo "Starting Acexy proxy..."
    export ACEXY_HOST
    export ACEXY_PORT
    /usr/local/bin/acexy &
else
    echo "Acexy is disabled."
fi

# Start ZeroNet in the background
cd /app/ZeroNet
echo "Starting ZeroNet..."
python3 zeronet.py main &
ZERONET_PID=$!

echo "Waiting for ZeroNet to initialize..."
sleep 10

# Start Flask app with Gunicorn
cd /app
echo "Starting Flask application on port $FLASK_PORT..."
exec gunicorn \
    --bind "0.0.0.0:$FLASK_PORT" \
    --workers 3 \
    --timeout 300 \
    --keep-alive 5 \
    --worker-class uvicorn.workers.UvicornWorker \
    --log-level info \
    "wsgi:asgi_app" &
GUNICORN_PID=$!

echo "Services started. Monitoring processes..."
trap "echo 'Shutting down services...'; kill $(jobs -p)" EXIT INT TERM QUIT

# Wait for any process to exit
wait
