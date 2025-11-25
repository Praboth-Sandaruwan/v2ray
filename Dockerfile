# Use Ubuntu 22.04 for better performance and kernel optimization
FROM ubuntu:22.04

# Set environment variables for performance
ENV V2RAY_VERSION=5.7.0
ENV V2RAY_URL="https://github.com/v2fly/v2ray-core/releases/download/v${V2RAY_VERSION}/v2ray-linux-64.zip"
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV V2RAY_PORT=10000
ENV V2RAY_PATH=/danuwa

# Note: Kernel parameters will be set at runtime in the startup script
# since they cannot be modified during container build

# Install required packages with performance optimizations
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    gettext-base \
    ca-certificates \
    tzdata \
    wget \
    unzip \
    curl \
    iproute2 \
    iputils-ping \
    net-tools \
    procps \
    htop \
    openssl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && update-ca-certificates

# Create non-root user with optimized settings
RUN groupadd -r v2ray && \
    useradd -r -g v2ray -d /etc/v2ray -s /sbin/nologin -u 1000 v2ray

# Create directories with optimized permissions
RUN mkdir -p /etc/v2ray /var/log/v2ray /tmp/v2ray /var/run/v2ray && \
    chown -R v2ray:v2ray /etc/v2ray /var/log/v2ray /tmp/v2ray /var/run/v2ray && \
    chmod 755 /etc/v2ray /var/log/v2ray /tmp/v2ray /var/run/v2ray

# Download and install V2Ray with performance optimizations
# Try multiple approaches to download V2Ray
RUN echo "Attempting to download V2Ray..." && \
    (curl -k -L --connect-timeout 10 --max-time 60 -o /tmp/v2ray.zip "${V2RAY_URL}" || \
     wget --no-check-certificate --timeout=30 --tries=3 -O /tmp/v2ray.zip "${V2RAY_URL}" || \
     curl -k --ssl-no-revoke -L -o /tmp/v2ray.zip "${V2RAY_URL}") && \
    unzip -p /tmp/v2ray.zip v2ray > /usr/local/bin/v2ray && \
    unzip -p /tmp/v2ray.zip geoip.dat > /usr/local/bin/geoip.dat && \
    unzip -p /tmp/v2ray.zip geosite.dat > /usr/local/bin/geosite.dat && \
    chmod +x /usr/local/bin/v2ray && \
    rm /tmp/v2ray.zip

# Copy server configuration template
COPY config.json /etc/v2ray/config.json.template

# Set ownership and permissions
RUN chown -R v2ray:v2ray /etc/v2ray /usr/local/bin/geoip.dat /usr/local/bin/geosite.dat && \
    chmod 644 /etc/v2ray/config.json.template && \
    chmod 644 /usr/local/bin/geoip.dat /usr/local/bin/geosite.dat

# Create optimized health check script for VLESS inbound
RUN echo '#!/bin/bash' > /usr/local/bin/healthcheck.sh && \
    echo '# Check if V2Ray process is running and inbound port is listening' >> /usr/local/bin/healthcheck.sh && \
    echo 'PORT="${V2RAY_PORT:-10000}"' >> /usr/local/bin/healthcheck.sh && \
    echo 'if pgrep -f "v2ray run" > /dev/null && netstat -tlnp 2>/dev/null | grep -q ":${PORT}.*LISTEN"; then' >> /usr/local/bin/healthcheck.sh && \
    echo '    exit 0' >> /usr/local/bin/healthcheck.sh && \
    echo 'else' >> /usr/local/bin/healthcheck.sh && \
    echo '    exit 1' >> /usr/local/bin/healthcheck.sh && \
    echo 'fi' >> /usr/local/bin/healthcheck.sh && \
    chmod +x /usr/local/bin/healthcheck.sh

# Create performance monitoring script
RUN echo '#!/bin/bash' > /usr/local/bin/perf-monitor.sh && \
    echo 'echo "=== V2Ray Performance Monitor ==="' >> /usr/local/bin/perf-monitor.sh && \
    echo 'echo "Memory Usage:"' >> /usr/local/bin/perf-monitor.sh && \
    echo 'free -h' >> /usr/local/bin/perf-monitor.sh && \
    echo 'echo "Network Connections:"' >> /usr/local/bin/perf-monitor.sh && \
    echo 'ss -s' >> /usr/local/bin/perf-monitor.sh && \
    echo 'echo "TCP Stats:"' >> /usr/local/bin/perf-monitor.sh && \
    echo 'cat /proc/net/netstat | grep TcpExt' >> /usr/local/bin/perf-monitor.sh && \
    echo 'echo "Process Info:"' >> /usr/local/bin/perf-monitor.sh && \
    echo 'ps aux | grep v2ray' >> /usr/local/bin/perf-monitor.sh && \
    chmod +x /usr/local/bin/perf-monitor.sh

# Copy UUID generation and configuration update scripts
COPY generate-uuid.sh /usr/local/bin/generate-uuid.sh
COPY update-config.sh /usr/local/bin/update-config.sh

# Create startup script with kernel optimizations and UUID randomization
RUN echo '#!/bin/bash' > /usr/local/bin/start-v2ray.sh && \
    echo 'set -euo pipefail' >> /usr/local/bin/start-v2ray.sh && \
    echo '' >> /usr/local/bin/start-v2ray.sh && \
    echo '# Logging function' >> /usr/local/bin/start-v2ray.sh && \
    echo 'log() {' >> /usr/local/bin/start-v2ray.sh && \
    echo '    echo "[V2Ray-Startup] $1"' >> /usr/local/bin/start-v2ray.sh && \
    echo '}' >> /usr/local/bin/start-v2ray.sh && \
    echo '' >> /usr/local/bin/start-v2ray.sh && \
    echo '# Normalize defaults for templating' >> /usr/local/bin/start-v2ray.sh && \
    echo 'export V2RAY_PORT="${V2RAY_PORT:-10000}"' >> /usr/local/bin/start-v2ray.sh && \
    echo 'export V2RAY_PATH="${V2RAY_PATH:-/danuwa}"' >> /usr/local/bin/start-v2ray.sh && \
    echo 'export V2RAY_SERVER="${V2RAY_SERVER:-127.0.0.1}"' >> /usr/local/bin/start-v2ray.sh && \
    echo 'export V2RAY_LOG_LEVEL="${V2RAY_LOG_LEVEL:-warning}"' >> /usr/local/bin/start-v2ray.sh && \
    echo 'export DNS_QUERY_STRATEGY="${DNS_QUERY_STRATEGY:-UseIPv4}"' >> /usr/local/bin/start-v2ray.sh && \
    echo 'export DNS_DISABLE_CACHE="${DNS_DISABLE_CACHE:-false}"' >> /usr/local/bin/start-v2ray.sh && \
    echo 'export V2RAY_BUFFER_SIZE="${V2RAY_BUFFER_SIZE:-262144}"' >> /usr/local/bin/start-v2ray.sh && \
    echo 'export V2RAY_UUID="${V2RAY_UUID:-${V2RAY_UUID_FALLBACK:-}}"' >> /usr/local/bin/start-v2ray.sh && \
    echo 'if [ -z "${V2RAY_UUID:-}" ]; then' >> /usr/local/bin/start-v2ray.sh && \
    echo '    log "ERROR: V2RAY_UUID must be set"' >> /usr/local/bin/start-v2ray.sh && \
    echo '    exit 1' >> /usr/local/bin/start-v2ray.sh && \
    echo 'fi' >> /usr/local/bin/start-v2ray.sh && \
    echo '' >> /usr/local/bin/start-v2ray.sh && \
    echo '# Render config from template with current environment' >> /usr/local/bin/start-v2ray.sh && \
    echo 'CONFIG_TEMPLATE="/etc/v2ray/config.json.template"' >> /usr/local/bin/start-v2ray.sh && \
    echo 'CONFIG_OUTPUT="/etc/v2ray/config.json"' >> /usr/local/bin/start-v2ray.sh && \
    echo 'if [ -f "$CONFIG_TEMPLATE" ]; then' >> /usr/local/bin/start-v2ray.sh && \
    echo '    log "Rendering V2Ray config from template"' >> /usr/local/bin/start-v2ray.sh && \
    echo '    envsubst '\''$V2RAY_UUID $V2RAY_PORT $V2RAY_PATH $V2RAY_SERVER $V2RAY_LOG_LEVEL $DNS_QUERY_STRATEGY $DNS_DISABLE_CACHE $V2RAY_BUFFER_SIZE'\'' < "$CONFIG_TEMPLATE" > "$CONFIG_OUTPUT"' >> /usr/local/bin/start-v2ray.sh && \
    echo '    chown v2ray:v2ray "$CONFIG_OUTPUT" 2>/dev/null || true' >> /usr/local/bin/start-v2ray.sh && \
    echo 'fi' >> /usr/local/bin/start-v2ray.sh && \
    echo '' >> /usr/local/bin/start-v2ray.sh && \
    echo '# UUID Randomization' >> /usr/local/bin/start-v2ray.sh && \
    echo 'log "Starting V2Ray with UUID randomization..."' >> /usr/local/bin/start-v2ray.sh && \
    echo '' >> /usr/local/bin/start-v2ray.sh && \
    echo '# Check if UUID randomization is enabled' >> /usr/local/bin/start-v2ray.sh && \
    echo 'if [ "${V2RAY_UUID_RANDOMIZE:-false}" = "true" ]; then' >> /usr/local/bin/start-v2ray.sh && \
    echo '    log "UUID randomization is enabled"' >> /usr/local/bin/start-v2ray.sh && \
    echo '    ' >> /usr/local/bin/start-v2ray.sh && \
    echo '    # Generate new UUID' >> /usr/local/bin/start-v2ray.sh && \
    echo '    NEW_UUID=$(/usr/local/bin/generate-uuid.sh "${V2RAY_UUID_FALLBACK:-$V2RAY_UUID}")' >> /usr/local/bin/start-v2ray.sh && \
    echo '    if [ $? -eq 0 ] && [ -n "$NEW_UUID" ]; then' >> /usr/local/bin/start-v2ray.sh && \
    echo '        log "Generated new UUID: $NEW_UUID"' >> /usr/local/bin/start-v2ray.sh && \
    echo '        ' >> /usr/local/bin/start-v2ray.sh && \
    echo '        # Update configuration with new UUID' >> /usr/local/bin/start-v2ray.sh && \
    echo '        /usr/local/bin/update-config.sh "$NEW_UUID"' >> /usr/local/bin/start-v2ray.sh && \
    echo '        if [ $? -eq 0 ]; then' >> /usr/local/bin/start-v2ray.sh && \
    echo '            log "Configuration updated successfully with new UUID"' >> /usr/local/bin/start-v2ray.sh && \
    echo '        else' >> /usr/local/bin/start-v2ray.sh && \
    echo '            log "WARNING: Failed to update configuration, using original"' >> /usr/local/bin/start-v2ray.sh && \
    echo '        fi' >> /usr/local/bin/start-v2ray.sh && \
    echo '    else' >> /usr/local/bin/start-v2ray.sh && \
    echo '        log "WARNING: Failed to generate UUID, using fallback"' >> /usr/local/bin/start-v2ray.sh && \
    echo '    fi' >> /usr/local/bin/start-v2ray.sh && \
    echo 'else' >> /usr/local/bin/start-v2ray.sh && \
    echo '    log "UUID randomization is disabled, using static UUID"' >> /usr/local/bin/start-v2ray.sh && \
    echo 'fi' >> /usr/local/bin/start-v2ray.sh && \
    echo '' >> /usr/local/bin/start-v2ray.sh && \
    echo '# Apply kernel optimizations with error handling' >> /usr/local/bin/start-v2ray.sh && \
    echo 'log "Applying kernel optimizations..."' >> /usr/local/bin/start-v2ray.sh && \
    echo '# Network buffer settings' >> /usr/local/bin/start-v2ray.sh && \
    echo 'echo 134217728 > /proc/sys/net/core/rmem_max 2>/dev/null || log "Warning: Cannot set rmem_max"' >> /usr/local/bin/start-v2ray.sh && \
    echo 'echo 134217728 > /proc/sys/net/core/wmem_max 2>/dev/null || log "Warning: Cannot set wmem_max"' >> /usr/local/bin/start-v2ray.sh && \
    echo 'echo "4096 65536 134217728" > /proc/sys/net/ipv4/tcp_rmem 2>/dev/null || log "Warning: Cannot set tcp_rmem"' >> /usr/local/bin/start-v2ray.sh && \
    echo 'echo "4096 65536 134217728" > /proc/sys/net/ipv4/tcp_wmem 2>/dev/null || log "Warning: Cannot set tcp_wmem"' >> /usr/local/bin/start-v2ray.sh && \
    echo '# TCP settings' >> /usr/local/bin/start-v2ray.sh && \
    echo 'echo bbr > /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null || log "Warning: Cannot set congestion_control"' >> /usr/local/bin/start-v2ray.sh && \
    echo 'echo 3 > /proc/sys/net/ipv4/tcp_fast_open 2>/dev/null || log "Warning: Cannot set tcp_fast_open"' >> /usr/local/bin/start-v2ray.sh && \
    echo 'echo 5000 > /proc/sys/net/core/netdev_max_backlog 2>/dev/null || log "Warning: Cannot set netdev_max_backlog"' >> /usr/local/bin/start-v2ray.sh && \
    echo 'echo 1 > /proc/sys/net/ipv4/tcp_tw_reuse 2>/dev/null || log "Warning: Cannot set tcp_tw_reuse"' >> /usr/local/bin/start-v2ray.sh && \
    echo 'echo 15 > /proc/sys/net/ipv4/tcp_fin_timeout 2>/dev/null || log "Warning: Cannot set tcp_fin_timeout"' >> /usr/local/bin/start-v2ray.sh && \
    echo 'echo 600 > /proc/sys/net/ipv4/tcp_keepalive_time 2>/dev/null || log "Warning: Cannot set tcp_keepalive_time"' >> /usr/local/bin/start-v2ray.sh && \
    echo 'echo 60 > /proc/sys/net/ipv4/tcp_keepalive_intvl 2>/dev/null || log "Warning: Cannot set tcp_keepalive_intvl"' >> /usr/local/bin/start-v2ray.sh && \
    echo 'echo 3 > /proc/sys/net/ipv4/tcp_keepalive_probes 2>/dev/null || log "Warning: Cannot set tcp_keepalive_probes"' >> /usr/local/bin/start-v2ray.sh && \
    echo 'echo 65536 > /proc/sys/net/ipv4/tcp_max_syn_backlog 2>/dev/null || log "Warning: Cannot set tcp_max_syn_backlog"' >> /usr/local/bin/start-v2ray.sh && \
    echo 'echo 65536 > /proc/sys/net/core/somaxconn 2>/dev/null || log "Warning: Cannot set somaxconn"' >> /usr/local/bin/start-v2ray.sh && \
    echo '# Set CPU governor to performance' >> /usr/local/bin/start-v2ray.sh && \
    echo 'echo performance > /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true' >> /usr/local/bin/start-v2ray.sh && \
    echo 'log "Kernel optimizations applied successfully"' >> /usr/local/bin/start-v2ray.sh && \
    echo '' >> /usr/local/bin/start-v2ray.sh && \
    echo '# Display current UUID being used' >> /usr/local/bin/start-v2ray.sh && \
    echo 'if [ -f /etc/v2ray/config.json ]; then' >> /usr/local/bin/start-v2ray.sh && \
    echo '    CURRENT_UUID=$(grep -o '"id": "[^"]*"' /etc/v2ray/config.json | cut -d'"' -f4 || echo "unknown")' >> /usr/local/bin/start-v2ray.sh && \
    echo '    log "Starting V2Ray with UUID: $CURRENT_UUID"' >> /usr/local/bin/start-v2ray.sh && \
    echo 'fi' >> /usr/local/bin/start-v2ray.sh && \
    echo '' >> /usr/local/bin/start-v2ray.sh && \
    echo '# Start V2Ray' >> /usr/local/bin/start-v2ray.sh && \
    echo 'log "Starting V2Ray service..."' >> /usr/local/bin/start-v2ray.sh && \
    echo 'exec /usr/local/bin/v2ray run -c /etc/v2ray/config.json' >> /usr/local/bin/start-v2ray.sh && \
    chmod +x /usr/local/bin/start-v2ray.sh && \
    chmod +x /usr/local/bin/generate-uuid.sh && \
    chmod +x /usr/local/bin/update-config.sh

# Switch to non-root user
USER v2ray

# Expose VLESS inbound port (proxied by nginx)
EXPOSE 10000

# Set working directory
WORKDIR /etc/v2ray

# Health check with optimized timing
HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=2 \
    CMD /usr/local/bin/healthcheck.sh

# Start V2Ray with performance optimizations
CMD ["/usr/local/bin/start-v2ray.sh"]
