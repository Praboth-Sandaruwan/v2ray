# V2Ray Docker — Local WS (No TLS)

Single-container V2Ray (VLESS over WebSocket) for local/LAN use without TLS. TLS, nginx, and certbot have been removed in this branch.

## Prerequisites
- Docker Engine + Docker Compose v2

## Configuration
Edit `.env` (defaults are already local):
```
V2RAY_UUID=2e50bce3-2c41-4d46-9a25-7b4d478c855a
V2RAY_PATH=/beelzebub
V2RAY_PORT=11000
V2RAY_SERVER=127.0.0.1
```

## Run
```bash
docker compose up -d
docker compose ps
```

## Test WebSocket handshake
```bash
curl -v \
  -H "Connection: Upgrade" -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Key: test" -H "Sec-WebSocket-Version: 13" \
  http://127.0.0.1:11000/beelzebub
```

## Client settings (WS, no TLS)
- Host: `127.0.0.1` (or your LAN IP)
- Port: `11000`
- UUID: `2e50bce3-2c41-4d46-9a25-7b4d478c855a`
- Security: `none`
- Network: `ws`
- Path: `/beelzebub`
- Host header: same as Host
- v2rayN import URL:
```
vless://2e50bce3-2c41-4d46-9a25-7b4d478c855a@127.0.0.1:11000?encryption=none&security=none&type=ws&host=127.0.0.1&path=%2Fbeelzebub#local-ws
```

## Troubleshooting
- Check container logs: `docker compose logs v2ray`
- Check status: `docker compose ps`
- Rebuild if needed (after config/template changes): `docker compose build v2ray && docker compose up -d`
