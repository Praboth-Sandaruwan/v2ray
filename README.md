# V2Ray Docker Project

A production-ready Docker-based V2Ray server implementation with VLESS protocol, WebSocket transport, and automatic SSL certificate management through Let's Encrypt.

## Overview

This project provides a secure, scalable, and easy-to-deploy V2Ray server solution using Docker containers. It implements a multi-container architecture with Nginx as a reverse proxy, V2Ray core for the proxy functionality, and Certbot for automated SSL certificate management.

### Key Features

- **VLESS Protocol**: Modern, lightweight protocol with improved performance
- **WebSocket Transport**: Traffic disguised as standard WebSocket connections
- **Automatic SSL**: Let's Encrypt certificates with auto-renewal
- **Security Hardened**: Multiple layers of security including rate limiting and security headers
- **Production Ready**: Health checks, resource limits, and logging
- **Easy Deployment**: Single command deployment with Docker Compose

## Architecture

The project uses a multi-container architecture:

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │    │                 │
│   Nginx Proxy   │────│   V2Ray Core    │────│   Certbot       │
│   (Port 80/443) │    │   (Port 10000)  │    │   (SSL Mgmt)    │
│                 │    │                 │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                       │                       │
        └───────────────────────┼───────────────────────┘
                                │
                    ┌─────────────────┐
                    │                 │
                    │   Shared        │
                    │   Network       │
                    │   (172.20.0.0/16)│
                    │                 │
                    └─────────────────┘
```

### Components

1. **Nginx Container** ([`Dockerfile.nginx`](Dockerfile.nginx))
   - Handles HTTPS termination
   - WebSocket proxying to V2Ray
   - Rate limiting and security headers
   - Serves ACME challenges for Let's Encrypt

2. **V2Ray Container** ([`Dockerfile`](Dockerfile))
   - Core proxy functionality
   - VLESS protocol implementation
   - WebSocket transport
   - Traffic routing and filtering

3. **Certbot Container**
   - Automated SSL certificate issuance
   - Certificate renewal (every 12 hours)
   - Integration with Nginx for certificate deployment

## Prerequisites

Before deploying this project, ensure you have:

- **Docker**: Version 20.10 or higher
- **Docker Compose**: Version 2.0 or higher
- **Domain Name**: A registered domain pointing to your server's IP
- **Server Requirements**:
  - Minimum 2GB RAM
  - Minimum 10GB storage
  - Ports 80 and 443 open to the internet
  - Linux server (Ubuntu 20.04+ recommended)

## Quick Start (TLS via domain)

1. **Configure environment variables** in `.env` (DOMAIN, SSL_EMAIL, V2RAY_UUID, V2RAY_PATH, V2RAY_PORT).
2. **Build and start** the stack (V2Ray core, nginx reverse proxy, certbot):
   ```bash
   docker compose up -d
   ```
3. **Verify**:
   ```bash
   docker compose ps
   docker compose logs v2ray
   docker compose logs nginx
   ```
   Certbot will attempt to issue a real certificate automatically; the nginx entrypoint falls back to self-signed until issuance succeeds.

## Local WS (no TLS, higher throughput)

For a local WebSocket-only proxy (no nginx/certbot, no TLS):

1. Copy `.env.local` and keep defaults (Host/Server = 127.0.0.1, port 11000, path `/beelzebub`).
2. Start just V2Ray with the local override:
   ```bash
   docker compose -f docker-compose.local.yml --env-file .env.local up -d
   docker compose -f docker-compose.local.yml --env-file .env.local ps
   ```
3. Client settings:
   - Host: `127.0.0.1` (or your LAN IP if another device connects)
   - Port: `11000`
   - UUID: your `V2RAY_UUID`
   - Security: none
   - Network: ws
   - Path: `/beelzebub`
   - Host header: same as Host
4. Test WebSocket handshake (no TLS):
   ```bash
   curl -v \
     -H "Connection: Upgrade" -H "Upgrade: websocket" \
     -H "Sec-WebSocket-Key: test" -H "Sec-WebSocket-Version: 13" \
      http://127.0.0.1:11000/beelzebub
   ```

## Detailed Setup Instructions

### 1. Environment Configuration

Edit the [`.env`](.env) file with your specific settings:

```bash
# Domain Configuration
DOMAIN=your-domain.com

# SSL/TLS Configuration
SSL_EMAIL=admin@your-domain.com

# V2Ray Configuration
V2RAY_UUID=your-uuid-here  # Generate with: uuidgen
V2RAY_PATH=/your-custom-path
V2RAY_PORT=10000
```

### 2. V2Ray Configuration

The V2Ray configuration is defined in [`config.json`](config.json):

- **Protocol**: VLESS with no encryption (TLS handled by Nginx)
- **Transport**: WebSocket with custom path
- **Routing**: Blocks private IPs, Chinese IPs, and ads
- **DNS**: Uses multiple DNS servers for reliability

### 3. Nginx Configuration

The Nginx configuration in [`nginx.conf`](nginx.conf) includes:

- **SSL Settings**: Modern TLS 1.2/1.3 with strong ciphers
- **Security Headers**: HSTS, XSS protection, content security policy
- **Rate Limiting**: Prevents abuse and DoS attacks
- **WebSocket Proxy**: Forwards WebSocket connections to V2Ray

### 4. SSL Certificate Setup

The project uses Let's Encrypt for SSL certificates:

1. Initial deployment uses a self-signed certificate
2. Certbot automatically obtains a Let's Encrypt certificate
3. Certificates are renewed automatically every 12 hours
4. Nginx is reloaded when certificates are renewed

## Configuration Explanation

### V2Ray Configuration ([`config.json`](config.json))

```json
{
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": 10000,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "your-uuid-here",
            "level": 0,
            "email": "user@example.com"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/your-custom-path",
          "headers": {
            "Host": "your-domain.com"
          }
        }
      }
    }
  ]
}
```

### Docker Compose Configuration ([`docker-compose.yml`](docker-compose.yml))

The Docker Compose file defines:

- **Three services**: nginx, v2ray, and certbot
- **Shared network**: For inter-container communication
- **Persistent volumes**: For logs and certificates
- **Resource limits**: To prevent resource exhaustion
- **Health checks**: To ensure service availability

## Security Considerations

This implementation includes multiple security layers:

1. **Transport Security**: TLS 1.2/1.3 with strong ciphers
2. **Application Security**: Non-root containers, read-only filesystems
3. **Network Security**: Rate limiting, connection limits
4. **Access Control**: UUID-based authentication
5. **Traffic Filtering**: Blocks malicious IPs and domains

For detailed security information, see [SECURITY.md](SECURITY.md).

## Troubleshooting

### Common Issues

1. **Certificate Issues**:
   ```bash
   # Check certificate status
   docker-compose exec certbot certbot certificates
   
   # Force certificate renewal
   docker-compose exec certbot certbot renew --force-renewal
   ```

2. **Connection Issues**:
   ```bash
   # Check V2Ray logs
   docker-compose logs v2ray
   
   # Check Nginx logs
   docker-compose logs nginx
   
   # Test WebSocket connection
   curl -i -N -H "Connection: Upgrade" \
        -H "Upgrade: websocket" \
        -H "Sec-WebSocket-Key: test" \
        -H "Sec-WebSocket-Version: 13" \
        https://your-domain.com/your-custom-path
   ```

3. **Performance Issues**:
   ```bash
   # Check resource usage
   docker stats
   
   # Check connection limits
   docker-compose exec nginx nginx -T | grep limit
   ```

### Health Checks

All containers include health checks:

```bash
# Check health status
docker-compose ps

# View health check logs
docker inspect <container-name> | grep Health -A 10
```

## Maintenance Guide

### Regular Maintenance Tasks

1. **Update Containers**:
   ```bash
   # Pull latest images
   docker-compose pull
   
   # Recreate containers with new images
   docker-compose up -d --force-recreate
   ```

2. **Log Management**:
   ```bash
   # Rotate logs
   docker-compose exec nginx logrotate /etc/logrotate.d/nginx
   
   # Clean old logs
   docker system prune -f
   ```

3. **Backup Configuration**:
   ```bash
   # Backup certificates
   tar -czf certbot-backup.tar.gz certbot/
   
   # Backup configuration
   tar -czf config-backup.tar.gz .env config.json nginx.conf
   ```

### Monitoring

Monitor the following metrics:

- Container resource usage
- SSL certificate expiration
- Connection rates and errors
- System resource utilization

For detailed deployment instructions, see [DEPLOYMENT.md](DEPLOYMENT.md).

For client configuration instructions, see [CLIENT_CONFIG.md](CLIENT_CONFIG.md).

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For support and questions:

1. Check the troubleshooting section above
2. Review the documentation files
3. Open an issue on the project repository
