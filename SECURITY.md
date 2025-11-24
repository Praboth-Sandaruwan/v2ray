# V2Ray Docker Security Guide

This document provides comprehensive security guidance for the V2Ray Docker project, including security architecture, threat analysis, and hardening recommendations.

## Table of Contents

1. [Security Architecture Overview](#security-architecture-overview)
2. [Threat Model and Mitigations](#threat-model-and-mitigations)
3. [Security Hardening Guidelines](#security-hardening-guidelines)
4. [Monitoring and Logging](#monitoring-and-logging)
5. [Incident Response Procedures](#incident-response-procedures)
6. [Regular Security Maintenance](#regular-security-maintenance)
7. [Security Audit Checklist](#security-audit-checklist)

## Security Architecture Overview

### Defense in Depth

The V2Ray Docker project implements a multi-layered security approach:

```
┌─────────────────────────────────────────────────────────────┐
│                    External Network                         │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                Network Security Layer                       │
│  • Firewall Rules (iptables/ufw)                           │
│  • DDoS Protection                                         │
│  • Network Segmentation                                    │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                Application Security Layer                   │
│  • Nginx Reverse Proxy                                     │
│  • TLS Termination                                         │
│  • Rate Limiting                                           │
│  • Security Headers                                        │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                Container Security Layer                     │
│  • Non-root Containers                                     │
│  • Read-only Filesystems                                   │
│  • Resource Limits                                         │
│  • Seccomp/AppArmor Profiles                               │
└─────────────────────┬───────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────┐
│                Host Security Layer                          │
│  • OS Hardening                                            │
│  • Access Control                                          │
│  • System Monitoring                                       │
└─────────────────────────────────────────────────────────────┘
```

### Security Components

1. **Network Security**:
   - Firewall rules limiting access to ports 80/443
   - DDoS protection through rate limiting
   - Network isolation using Docker networks

2. **Transport Security**:
   - TLS 1.2/1.3 with strong cipher suites
   - HSTS for HTTPS enforcement
   - Certificate pinning (client-side)

3. **Application Security**:
   - VLESS protocol with UUID authentication
   - WebSocket transport for traffic obfuscation
   - Request filtering and validation

4. **Container Security**:
   - Non-root user execution
   - Read-only filesystems where possible
   - Resource constraints and limits
   - Security options (`no-new-privileges`)

5. **Data Security**:
   - Encrypted traffic between client and server
   - Secure storage of configuration files
   - Regular certificate rotation

## Threat Model and Mitigations

### Threat Categories

#### 1. Network-Level Threats

**Threat**: DDoS Attacks
- **Description**: Overwhelming the server with traffic
- **Impact**: Service unavailability
- **Mitigations**:
  - Rate limiting in Nginx configuration
  - Connection limits per IP
  - Cloud-based DDoS protection services
  - Anycast network distribution

**Threat**: Man-in-the-Middle (MITM) Attacks
- **Description**: Intercepting or modifying traffic
- **Impact**: Data exposure, traffic manipulation
- **Mitigations**:
  - TLS with certificate validation
  - HSTS headers
  - Certificate pinning on clients
  - DNSSEC for domain resolution

#### 2. Application-Level Threats

**Threat**: Authentication Bypass
- **Description**: Unauthorized access to the proxy
- **Impact**: Unauthorized traffic routing
- **Mitigations**:
  - UUID-based authentication
  - Regular UUID rotation
  - Strong entropy in UUID generation
  - Client certificate validation (optional)

**Threat**: Protocol Fingerprinting
- **Description**: Identifying V2Ray traffic patterns
- **Impact**: Traffic blocking or filtering
- **Mitigations**:
  - WebSocket transport for obfuscation
  - Custom path configuration
  - TLS fingerprint masking
  - Plausible deniability through domain fronting

#### 3. Infrastructure Threats

**Threat**: Container Escape
- **Description**: Breaking out of container isolation
- **Impact**: Host system compromise
- **Mitigations**:
  - Non-root container execution
  - Seccomp/AppArmor profiles
  - Regular container image updates
  - Minimal container surface area

**Threat**: Resource Exhaustion
- **Description**: Consuming excessive system resources
- **Impact**: Service degradation or denial
- **Mitigations**:
  - Container resource limits
  - System monitoring and alerts
  - Auto-scaling capabilities
  - Resource quotas

#### 4. Data Threats

**Threat**: Traffic Analysis
- **Description**: Analyzing traffic patterns and metadata
- **Impact**: User activity identification
- **Mitigations**:
  - Padding and traffic shaping
  - Multiple routing paths
  - Regular path changes
  - Noise traffic generation

**Threat**: Log Exposure
- **Description**: Unauthorized access to logs
- **Impact**: User activity disclosure
- **Mitigations**:
  - Encrypted log storage
  - Log rotation and cleanup
  - Access-controlled log viewing
  - Minimal logging of sensitive data

### Risk Assessment Matrix

| Threat | Likelihood | Impact | Risk Level | Mitigation Priority |
|--------|------------|--------|------------|---------------------|
| DDoS Attacks | High | Medium | High | Critical |
| MITM Attacks | Medium | High | High | Critical |
| Authentication Bypass | Low | High | Medium | High |
| Protocol Fingerprinting | Medium | Medium | Medium | Medium |
| Container Escape | Low | Critical | Medium | Medium |
| Resource Exhaustion | Medium | Medium | Medium | Medium |
| Traffic Analysis | High | Low | Low | Low |
| Log Exposure | Low | Medium | Low | Low |

## Security Hardening Guidelines

### System-Level Hardening

1. **Operating System Security**:
   ```bash
   # Disable unnecessary services
   sudo systemctl disable bluetooth
   sudo systemctl disable cups
   sudo systemctl disable avahi-daemon
   
   # Configure kernel parameters
   echo "net.ipv4.ip_forward = 0" | sudo tee -a /etc/sysctl.conf
   echo "net.ipv4.conf.all.send_redirects = 0" | sudo tee -a /etc/sysctl.conf
   echo "net.ipv4.conf.all.accept_redirects = 0" | sudo tee -a /etc/sysctl.conf
   echo "net.ipv4.conf.all.accept_source_route = 0" | sudo tee -a /etc/sysctl.conf
   sudo sysctl -p
   
   # Enable automatic security updates
   sudo apt install unattended-upgrades
   sudo dpkg-reconfigure -plow unattended-upgrades
   ```

2. **Access Control**:
   ```bash
   # Create dedicated user for management
   sudo useradd -m -s /bin/bash v2rayadmin
   sudo usermod -aG sudo v2rayadmin
   
   # Configure SSH security
   sudo nano /etc/ssh/sshd_config
   # Add/modify these lines:
   # PermitRootLogin no
   # PasswordAuthentication no
   # PubkeyAuthentication yes
   # MaxAuthTries 3
   # ClientAliveInterval 300
   # ClientAliveCountMax 2
   
   sudo systemctl restart ssh
   ```

3. **File System Security**:
   ```bash
   # Set appropriate permissions
   chmod 600 .env
   chmod 644 config.json
   chmod 644 nginx.conf
   chmod 755 certbot-entrypoint.sh
   
   # Configure file attributes
   chattr +i .env  # Make immutable (remove with chattr -i)
   ```

### Docker Security Hardening

1. **Container Runtime Security**:
   ```bash
   # Configure Docker daemon security
   sudo tee /etc/docker/daemon.json > /dev/null <<EOF
   {
     "live-restore": true,
     "userland-proxy": false,
     "no-new-privileges": true,
     "seccomp-profile": "/etc/docker/seccomp.json",
     "default-ulimits": {
       "nofile": {
         "Name": "nofile",
         "Hard": 64000,
         "Soft": 64000
       }
     },
     "log-driver": "json-file",
     "log-opts": {
       "max-size": "10m",
       "max-file": "3"
     }
   }
   EOF
   
   sudo systemctl restart docker
   ```

2. **Container Image Security**:
   ```bash
   # Use minimal base images
   # Already implemented: Alpine Linux for V2Ray, Nginx Alpine for proxy
   
   # Scan images for vulnerabilities
   docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
     aquasec/trivy image v2ray-nginx:latest
   docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
     aquasec/trivy image v2ray-core:latest
   ```

3. **Network Security**:
   ```bash
   # Create isolated network
   docker network create --driver bridge --subnet=172.20.0.0/16 v2ray-network
   
   # Configure network policies
   # Already implemented in docker-compose.yml
   ```

### Application Security Hardening

1. **Nginx Configuration**:
   ```nginx
   # Additional security headers (already implemented)
   add_header X-Frame-Options DENY always;
   add_header X-Content-Type-Options nosniff always;
   add_header X-XSS-Protection "1; mode=block" always;
   add_header Referrer-Policy "strict-origin-when-cross-origin" always;
   add_header Content-Security-Policy "default-src 'self';" always;
   
   # Hide server information
   server_tokens off;
   
   # Limit request methods
   if ($request_method !~ ^(GET|HEAD|POST)$ ) {
       return 405;
   }
   
   # Additional rate limiting
   limit_req_zone $binary_remote_addr zone=api:10m rate=5r/s;
   limit_req zone=api burst=10 nodelay;
   ```

2. **V2Ray Configuration**:
   ```json
   {
     "log": {
       "loglevel": "warning",
       "access": "/var/log/v2ray/access.log",
       "error": "/var/log/v2ray/error.log"
     },
     "dns": {
       "servers": [
         "1.1.1.1",
         "1.0.0.1",
         "8.8.8.8",
         "8.8.4.4"
       ]
     },
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
           },
           "security": "none"
         },
         "sniffing": {
           "enabled": true,
           "destOverride": [
             "http",
             "tls"
           ]
         }
       }
     ]
   }
   ```

### SSL/TLS Security

1. **Certificate Management**:
   ```bash
   # Use strong certificates
   # Already implemented: 4096-bit RSA keys
   
   # Configure OCSP stapling
   # Already implemented in nginx.conf
   
   # Enable certificate transparency
   # Add to nginx.conf:
   # ssl_ct on;
   # ssl_ct_static_scts /var/www/ct/;
   ```

2. **Protocol Configuration**:
   ```nginx
   # Use only secure protocols
   ssl_protocols TLSv1.2 TLSv1.3;
   
   # Use strong cipher suites
   ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-CHACHA20-POLY1305;
   
   # Enable perfect forward secrecy
   ssl_prefer_server_ciphers off;
   
   # Configure session tickets
   ssl_session_timeout 1d;
   ssl_session_cache shared:SSL:50m;
   ssl_session_tickets off;
   ```

## Monitoring and Logging

### Security Monitoring

1. **Real-time Monitoring**:
   ```bash
   # Monitor connection attempts
   tail -f /var/log/nginx/access.log | grep -v "GET /health"
   
   # Monitor failed authentication
   tail -f /var/log/v2ray/error.log | grep -i "failed\|error\|rejected"
   
   # Monitor SSL certificate issues
   tail -f /var/log/certbot.log
   ```

2. **Intrusion Detection**:
   ```bash
   # Install and configure fail2ban
   sudo apt install fail2ban
   
   # Create V2Ray jail configuration
   sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
   [DEFAULT]
   bantime = 3600
   findtime = 600
   maxretry = 5
   
   [v2ray-auth]
   enabled = true
   filter = v2ray-auth
   logpath = /var/log/v2ray/error.log
   maxretry = 3
   bantime = 86400
   
   [nginx-req-limit]
   enabled = true
   filter = nginx-req-limit
   logpath = /var/log/nginx/error.log
   maxretry = 10
   bantime = 600
   EOF
   
   # Create filter for V2Ray authentication failures
   sudo tee /etc/fail2ban/filter.d/v2ray-auth.conf > /dev/null <<EOF
   [Definition]
   failregex = .*rejected.*client: <HOST>
   ignoreregex =
   EOF
   
   sudo systemctl restart fail2ban
   ```

3. **Log Analysis**:
   ```bash
   # Analyze access patterns
   awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -nr | head -20
   
   # Detect suspicious activity
   grep -i "attack\|exploit\|malicious" /var/log/nginx/access.log
   
   # Monitor certificate renewal
   grep -i "certificate\|renew\|expire" /var/log/certbot.log
   ```

### Security Metrics

Monitor these key security metrics:

1. **Authentication Metrics**:
   - Failed login attempts per hour
   - Unique IPs attempting authentication
   - Authentication success rate

2. **Traffic Metrics**:
   - Requests per second by IP
   - Unusual traffic patterns
   - Geographic distribution of connections

3. **System Metrics**:
   - Container resource usage
   - File system integrity
   - Process execution monitoring

## Incident Response Procedures

### Incident Classification

1. **Critical Incidents**:
   - Service compromise
   - Data breach
   - Complete service outage

2. **High Incidents**:
   - Partial service degradation
   - Successful authentication bypass
   - DDoS attacks

3. **Medium Incidents**:
   - Suspicious activity detected
   - Configuration errors
   - Certificate issues

4. **Low Incidents**:
   - Failed authentication attempts
   - Minor performance issues
   - Log anomalies

### Response Procedures

#### 1. Immediate Response (First Hour)

```bash
# Isolate affected systems
docker-compose stop

# Preserve evidence
mkdir -p /tmp/incident-$(date +%Y%m%d_%H%M%S)
cp -r /var/log/nginx /tmp/incident-$(date +%Y%m%d_%H%M%S)/
cp -r /var/log/v2ray /tmp/incident-$(date +%Y%m%d_%H%M%S)/
docker inspect v2ray-nginx > /tmp/incident-$(date +%Y%m%d_%H%M%S)/nginx-inspect.log
docker inspect v2ray-core > /tmp/incident-$(date +%Y%m%d_%H%M%S)/v2ray-inspect.log

# Change credentials
# Generate new UUID
NEW_UUID=$(uuidgen)
sed -i "s/V2RAY_UUID=.*/V2RAY_UUID=$NEW_UUID/" .env

# Rotate certificates
docker-compose exec certbot certbot renew --force-renewal
```

#### 2. Investigation (First 24 Hours)

```bash
# Analyze logs
grep -i "error\|failed\|rejected" /var/log/nginx/error.log
grep -i "error\|failed\|rejected" /var/log/v2ray/error.log

# Check for unauthorized access
docker exec -it v2ray-nginx cat /var/log/nginx/access.log | awk '{print $1}' | sort | uniq -c | sort -nr

# Verify configuration integrity
md5sum config.json nginx.conf .env

# Check container integrity
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image v2ray-nginx:latest
```

#### 3. Recovery (24-72 Hours)

```bash
# Restore from backup if necessary
tar -xzf /backup/v2ray_backup_YYYYMMDD_HHMMSS.tar.gz

# Update configurations
# Apply security patches
docker-compose pull
docker-compose up -d

# Verify service recovery
curl -I https://your-domain.com/health
docker-compose ps
```

### Communication Plan

1. **Internal Notification**:
   - Security team
   - System administrators
   - Management

2. **External Notification** (if required):
   - Users (if data breach)
   - Regulatory authorities (if required)
   - Law enforcement (if criminal activity)

## Regular Security Maintenance

### Daily Tasks

1. **Log Review**:
   ```bash
   # Check for anomalies
   tail -100 /var/log/nginx/error.log | grep -i "error\|warn"
   tail -100 /var/log/v2ray/error.log | grep -i "error\|warn"
   ```

2. **Health Checks**:
   ```bash
   # Verify service status
   docker-compose ps
   
   # Check SSL certificates
   docker-compose exec certbot certbot certificates
   ```

### Weekly Tasks

1. **Security Updates**:
   ```bash
   # Update system packages
   sudo apt update && sudo apt upgrade -y
   
   # Update Docker images
   docker-compose pull
   docker-compose up -d
   ```

2. **Security Scans**:
   ```bash
   # Scan for vulnerabilities
   docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
     aquasec/trivy image v2ray-nginx:latest
   docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
     aquasec/trivy image v2ray-core:latest
   ```

### Monthly Tasks

1. **Security Audit**:
   - Review access logs
   - Analyze authentication patterns
   - Verify configuration security
   - Update security policies

2. **Certificate Review**:
   - Check certificate expiration
   - Verify certificate strength
   - Review certificate authorities

### Quarterly Tasks

1. **Penetration Testing**:
   - External security assessment
   - Vulnerability scanning
   - Configuration review

2. **Security Training**:
   - Team security awareness
   - Incident response drills
   - Policy updates

## Security Audit Checklist

### Network Security

- [ ] Firewall rules configured correctly
- [ ] Only necessary ports open (80, 443)
- [ ] DDoS protection in place
- [ ] Network segmentation implemented
- [ ] DNSSEC configured (optional)

### Application Security

- [ ] TLS 1.2/1.3 enabled
- [ ] Strong cipher suites configured
- [ ] Security headers implemented
- [ ] Rate limiting configured
- [ ] Authentication mechanisms secure

### Container Security

- [ ] Non-root containers
- [ ] Read-only filesystems where possible
- [ ] Resource limits configured
- [ ] Security options enabled
- [ ] Images regularly updated

### Data Security

- [ ] Encrypted traffic
- [ ] Secure certificate storage
- [ ] Log access controlled
- [ ] Backup encryption
- [ ] Data retention policies

### Monitoring and Logging

- [ ] Security monitoring enabled
- [ ] Log collection configured
- [ ] Alert systems active
- [ ] Incident response plan
- [ ] Regular security reviews

### Access Control

- [ ] Strong authentication
- [ ] Principle of least privilege
- [ ] Regular access reviews
- [ ] Multi-factor authentication (optional)
- [ ] Account lockout policies

This security guide provides comprehensive security measures for the V2Ray Docker project. Regular security assessments and updates are essential to maintain a secure deployment.