# V2Ray Docker Deployment Guide

This guide provides step-by-step instructions for deploying the V2Ray Docker project in production environments.

## Table of Contents

1. [Environment Preparation](#environment-preparation)
2. [Domain Configuration](#domain-configuration)
3. [SSL Certificate Setup](#ssl-certificate-setup)
4. [Deployment Steps](#deployment-steps)
5. [Production Best Practices](#production-best-practices)
6. [Scaling Considerations](#scaling-considerations)
7. [Backup and Recovery](#backup-and-recovery)
8. [Monitoring and Maintenance](#monitoring-and-maintenance)

## Environment Preparation

### System Requirements

**Minimum Requirements:**
- CPU: 2 cores
- RAM: 2GB
- Storage: 10GB SSD
- Network: 100Mbps
- OS: Ubuntu 20.04+ / Debian 11+ / CentOS 8+

**Recommended Requirements:**
- CPU: 4 cores
- RAM: 4GB
- Storage: 20GB SSD
- Network: 1Gbps
- OS: Ubuntu 22.04 LTS

### Prerequisites Installation

1. **Update System Packages**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Install Docker**:
   ```bash
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   
   # Add user to docker group
   sudo usermod -aG docker $USER
   
   # Enable Docker service
   sudo systemctl enable docker
   sudo systemctl start docker
   ```

3. **Install Docker Compose**:
   ```bash
   # Install Docker Compose
   sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
   sudo chmod +x /usr/local/bin/docker-compose
   
   # Verify installation
   docker-compose --version
   ```

4. **Install Additional Tools**:
   ```bash
   sudo apt install -y git curl wget htop unzip
   ```

### Firewall Configuration

Configure firewall to allow necessary ports:

```bash
# Configure UFW (Ubuntu)
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable

# Or configure iptables directly
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -A INPUT -j DROP
sudo iptables-save > /etc/iptables/rules.v4
```

## Domain Configuration

### DNS Setup

1. **Configure A Record**:
   - Point your domain (e.g., `v2ray.example.com`) to your server's public IP
   - Use a TTL of 300 seconds (5 minutes) for easier changes

2. **Verify DNS Propagation**:
   ```bash
   # Check DNS resolution
   dig +short v2ray.example.com
   
   # Check from multiple locations
   ping v2ray.example.com
   ```

3. **Optional: Configure Subdomains**:
   - Consider using a subdomain specifically for V2Ray
   - Example: `v2ray.example.com` instead of the main domain

### Domain Validation

Ensure your domain meets these requirements:

- ✅ Resolves to the correct server IP
- ✅ Not blacklisted by major email providers
- ✅ Has valid WHOIS information
- ✅ DNSSEC is configured (optional but recommended)

## SSL Certificate Setup

### Let's Encrypt Prerequisites

1. **Domain Ownership**:
   - Ensure you control the domain
   - Domain must resolve to the deployment server

2. **Email Requirements**:
   - Use a professional email address
   - Must be able to receive renewal notifications

3. **Port Requirements**:
   - Port 80 must be open for ACME challenges
   - Port 443 must be open for SSL termination

### Certificate Configuration

The project handles SSL certificates automatically through Certbot:

1. **Initial Setup**:
   - Self-signed certificate is generated for initial deployment
   - Certbot obtains Let's Encrypt certificate automatically
   - Certificates are stored in `./certbot/conf/` directory

2. **Automatic Renewal**:
   - Certificates are checked every 12 hours
   - Renewal happens 30 days before expiration
   - Nginx is automatically reloaded after renewal

3. **Manual Certificate Management**:
   ```bash
   # Check certificate status
   docker-compose exec certbot certbot certificates
   
   # Force renewal
   docker-compose exec certbot certbot renew --force-renewal
   
   # Test renewal process
   docker-compose exec certbot certbot renew --dry-run
   ```

## Deployment Steps

### 1. Clone the Repository

```bash
# Clone the project
git clone <repository-url> v2ray-docker
cd v2ray-docker

# Verify files
ls -la
```

### 2. Configure Environment Variables

```bash
# Copy environment template
cp .env.example .env

# Edit configuration
nano .env
```

**Required Configuration:**
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

**Optional Configuration:**
```bash
# Performance Settings
NGINX_WORKER_CONNECTIONS=2048
RATE_LIMIT_REQUESTS_PER_SECOND=20

# Security Settings
CONNECTION_LIMIT_PER_IP=30
```

### 3. Generate UUID

Generate a unique UUID for V2Ray authentication:

```bash
# Generate UUID
uuidgen

# Or use online generator
# https://www.uuidgenerator.net/
```

### 4. Initial Deployment

```bash
# Build and start containers
docker-compose up -d

# Check container status
docker-compose ps

# View logs
docker-compose logs -f
```

### 5. Verify Deployment

1. **Check Container Health**:
   ```bash
   # Check all containers
   docker-compose ps
   
   # Check health status
   docker inspect v2ray-nginx | grep Health -A 10
   docker inspect v2ray-core | grep Health -A 10
   ```

2. **Test SSL Certificate**:
   ```bash
   # Check certificate
   openssl s_client -connect your-domain.com:443 -servername your-domain.com
   
   # Or use online tool
   # https://www.ssllabs.com/ssltest/
   ```

3. **Test WebSocket Connection**:
   ```bash
   # Test WebSocket endpoint
   curl -i -N -H "Connection: Upgrade" \
        -H "Upgrade: websocket" \
        -H "Sec-WebSocket-Key: test" \
        -H "Sec-WebSocket-Version: 13" \
        https://your-domain.com/your-custom-path
   ```

### 6. Configure Client

Follow the client configuration instructions in [CLIENT_CONFIG.md](CLIENT_CONFIG.md).

## Production Best Practices

### Security Hardening

1. **System Security**:
   ```bash
   # Disable root login
   sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
   
   # Configure fail2ban
   sudo apt install fail2ban
   sudo systemctl enable fail2ban
   sudo systemctl start fail2ban
   ```

2. **Docker Security**:
   ```bash
   # Use non-root containers (already configured)
   # Enable Docker content trust
   export DOCKER_CONTENT_TRUST=1
   
   # Regular security updates
   docker-compose pull
   docker-compose up -d
   ```

3. **Network Security**:
   ```bash
   # Configure iptables rules
   sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
   sudo iptables -A INPUT -i lo -j ACCEPT
   sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
   sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
   sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
   sudo iptables -A INPUT -j DROP
   ```

### Performance Optimization

1. **System Tuning**:
   ```bash
   # Increase file descriptor limits
   echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
   echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf
   
   # Optimize network stack
   echo "net.core.rmem_max = 16777216" | sudo tee -a /etc/sysctl.conf
   echo "net.core.wmem_max = 16777216" | sudo tee -a /etc/sysctl.conf
   sudo sysctl -p
   ```

2. **Docker Optimization**:
   ```bash
   # Configure Docker daemon
   sudo tee /etc/docker/daemon.json > /dev/null <<EOF
   {
     "log-driver": "json-file",
     "log-opts": {
       "max-size": "10m",
       "max-file": "3"
     }
   }
   EOF
   
   sudo systemctl restart docker
   ```

3. **Application Tuning**:
   - Adjust worker connections in [`.env`](.env)
   - Configure appropriate rate limits
   - Monitor resource usage and adjust limits

### Logging and Monitoring

1. **Configure Log Rotation**:
   ```bash
   # Create logrotate configuration
   sudo tee /etc/logrotate.d/v2ray-docker > /dev/null <<EOF
   /path/to/v2ray-docker/logs/*.log {
       daily
       missingok
       rotate 30
       compress
       delaycompress
       notifempty
       create 644 root root
   }
   EOF
   ```

2. **Set Up Monitoring**:
   ```bash
   # Install monitoring tools
   sudo apt install -y prometheus grafana
   
   # Configure Docker metrics
   # Add to /etc/docker/daemon.json:
   # "metrics-addr": "127.0.0.1:9323"
   # "experimental": true
   ```

## Scaling Considerations

### Horizontal Scaling

For high-traffic deployments, consider these scaling strategies:

1. **Load Balancing**:
   ```bash
   # Deploy multiple instances behind a load balancer
   # Use HAProxy, Nginx, or cloud load balancer
   
   # Example HAProxy configuration
   frontend v2ray_frontend
       bind *:443 ssl crt /etc/ssl/certs/your-domain.com.pem
       default_backend v2ray_backend
   
   backend v2ray_backend
       balance roundrobin
       server v2ray1 10.0.1.10:10000 check
       server v2ray2 10.0.1.11:10000 check
       server v2ray3 10.0.1.12:10000 check
   ```

2. **Container Orchestration**:
   - Consider Kubernetes for large deployments
   - Use Docker Swarm for simpler scaling
   - Implement auto-scaling based on metrics

### Vertical Scaling

1. **Resource Allocation**:
   ```yaml
   # Update docker-compose.yml with higher limits
   deploy:
     resources:
       limits:
         cpus: '2.0'
         memory: 2G
       reservations:
         cpus: '1.0'
         memory: 1G
   ```

2. **Performance Tuning**:
   - Increase worker connections
   - Optimize buffer sizes
   - Tune kernel parameters

## Backup and Recovery

### Automated Backup Script

Create a backup script (`backup.sh`):

```bash
#!/bin/bash

# Configuration
BACKUP_DIR="/backup/v2ray"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="v2ray_backup_${DATE}.tar.gz"

# Create backup directory
mkdir -p $BACKUP_DIR

# Backup configuration and certificates
tar -czf $BACKUP_DIR/$BACKUP_FILE \
    .env \
    config.json \
    nginx.conf \
    certbot/ \
    docker-compose.yml

# Keep only last 7 days of backups
find $BACKUP_DIR -name "v2ray_backup_*.tar.gz" -mtime +7 -delete

echo "Backup completed: $BACKUP_DIR/$BACKUP_FILE"
```

### Recovery Procedure

1. **Restore from Backup**:
   ```bash
   # Extract backup
   tar -xzf v2ray_backup_YYYYMMDD_HHMMSS.tar.gz
   
   # Restart services
   docker-compose down
   docker-compose up -d
   ```

2. **Disaster Recovery**:
   ```bash
   # On new server:
   # 1. Install prerequisites
   # 2. Restore backup
   # 3. Update DNS if IP changed
   # 4. Verify SSL certificates
   # 5. Test connectivity
   ```

### Backup Schedule

Set up automated backups with cron:

```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * /path/to/backup.sh >> /var/log/v2ray_backup.log 2>&1
```

## Monitoring and Maintenance

### Health Monitoring

1. **Container Health Checks**:
   ```bash
   # Check all container health
   docker-compose ps
   
   # Detailed health information
   for container in $(docker-compose ps -q); do
       docker inspect $container | grep Health -A 10
   done
   ```

2. **Service Monitoring**:
   ```bash
   # Monitor service status
   watch -n 30 'docker-compose ps'
   
   # Monitor resource usage
   docker stats --no-stream
   ```

### Regular Maintenance Tasks

1. **Weekly Tasks**:
   ```bash
   # Update containers
   docker-compose pull
   docker-compose up -d
   
   # Clean up unused images
   docker image prune -f
   
   # Check disk space
   df -h
   ```

2. **Monthly Tasks**:
   ```bash
   # Review logs for issues
   docker-compose logs --tail=1000
   
   # Check SSL certificate expiration
   docker-compose exec certbot certbot certificates
   
   # Update system packages
   sudo apt update && sudo apt upgrade -y
   ```

3. **Quarterly Tasks**:
   - Review and update security configurations
   - Performance tuning based on metrics
   - Backup strategy review
   - Disaster recovery testing

### Alerting Setup

Configure alerts for critical issues:

```bash
# Example alert script
#!/bin/bash

# Check if containers are running
if ! docker-compose ps | grep -q "Up"; then
    echo "V2Ray containers are down!" | mail -s "V2Ray Alert" admin@example.com
fi

# Check SSL certificate expiration
if openssl x509 -checkend 2592000 -noout -in certbot/conf/live/your-domain.com/cert.pem; then
    echo "SSL certificate expires within 30 days!" | mail -s "SSL Certificate Alert" admin@example.com
fi
```

This deployment guide provides comprehensive instructions for deploying and maintaining the V2Ray Docker project in production environments. For security-specific guidance, see [SECURITY.md](SECURITY.md). For client configuration, see [CLIENT_CONFIG.md](CLIENT_CONFIG.md).