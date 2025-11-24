#!/bin/sh
set -e

log() {
    echo "[nginx-entrypoint] $1"
}

TEMPLATE="/etc/nginx/nginx.conf.template"
CONFIG="/etc/nginx/nginx.conf"

: "${DOMAIN:?DOMAIN must be set}"
V2RAY_PORT="${V2RAY_PORT:-10000}"
V2RAY_PATH="${V2RAY_PATH:-/danuwa}"

log "Rendering nginx config for ${DOMAIN} (path: ${V2RAY_PATH}, v2ray port: ${V2RAY_PORT})"
envsubst '$DOMAIN $V2RAY_PORT $V2RAY_PATH' < "$TEMPLATE" > "$CONFIG"

CERT_DIR="/etc/ssl"
CERT_FILE="${CERT_DIR}/certs/${DOMAIN}.crt"
KEY_FILE="${CERT_DIR}/private/${DOMAIN}.key"
LE_CERT="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
LE_KEY="/etc/letsencrypt/live/${DOMAIN}/privkey.pem"

mkdir -p "${CERT_DIR}/certs" "${CERT_DIR}/private"

if [ -f "$LE_CERT" ] && [ -f "$LE_KEY" ]; then
    log "Found Let's Encrypt certificate, syncing to nginx paths"
    cp "$LE_CERT" "$CERT_FILE"
    cp "$LE_KEY" "$KEY_FILE"
    chmod 644 "$CERT_FILE"
    chmod 600 "$KEY_FILE"
else
    if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
        log "No TLS certificate present, generating self-signed placeholder"
        openssl req -x509 -nodes -days 365 \
            -subj "/CN=${DOMAIN}" \
            -newkey rsa:2048 \
            -keyout "$KEY_FILE" \
            -out "$CERT_FILE"
        chmod 644 "$CERT_FILE"
        chmod 600 "$KEY_FILE"
    else
        log "Using existing self-signed certificate"
    fi
fi

exec nginx -g 'daemon off;'
