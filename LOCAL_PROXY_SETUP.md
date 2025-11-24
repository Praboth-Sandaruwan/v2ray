# V2Ray Local Proxy Setup Guide

This guide provides comprehensive instructions for setting up and using the V2Ray local proxy that disguises your outgoing traffic as Zoom traffic.

## Overview

The V2Ray local proxy is a Docker-based application that runs on your local machine and routes all your network traffic through a remote V2Ray server. The proxy is specifically configured to disguise your traffic as legitimate Zoom connections, making it appear as if you're using Zoom's video conferencing service.

### How It Works

1. **Local SOCKS5 Proxy**: The application creates a local SOCKS5 proxy server on port 1080
2. **Traffic Disguising**: All traffic through the proxy is wrapped in WebSocket connections that mimic Zoom traffic patterns
3. **Remote Server**: Traffic is forwarded to a remote V2Ray server at `partner.zoom.mobitel.asia`
4. **TLS Encryption**: All connections are secured with TLS encryption using the Zoom domain

### Key Features

- **Traffic Disguising**: Makes your internet traffic appear as Zoom video calls
- **SOCKS5 Protocol**: Compatible with most applications that support proxy settings
- **Docker-based**: Easy deployment and isolation from your system
- **Automatic DNS**: Uses multiple DNS servers for reliability
- **Traffic Filtering**: Blocks ads and malicious connections

## Prerequisites

Before setting up the local proxy, ensure you have:

### System Requirements

- **Operating System**: Windows 10/11, macOS 10.14+, or Linux (Ubuntu 18.04+)
- **RAM**: Minimum 2GB available
- **Storage**: Minimum 1GB free disk space
- **Network**: Stable internet connection

### Software Requirements

- **Docker Desktop**: Version 4.0 or higher
  - [Download for Windows](https://www.docker.com/products/docker-desktop/)
  - [Download for macOS](https://www.docker.com/products/docker-desktop/)
  - [Installation guide for Linux](https://docs.docker.com/engine/install/)

### Network Requirements

- Outbound connections on port 443 (HTTPS)
- No firewall blocking Docker applications
- Administrator privileges (for Docker installation)

## Quick Start Guide

Follow these steps to get the local proxy running immediately:

### 1. Clone or Download the Project

```bash
# If using Git
git clone <repository-url>
cd Nwk

# Or download and extract the project files to a directory
```

### 2. Start the Proxy Service

```bash
# Start the proxy using Docker Compose
docker-compose -f docker-compose.yml --env-file .env.local up -d

# Check if the service is running
docker-compose ps
```

### 3. Configure Your Browser

For Chrome:
1. Go to Settings → Advanced → System
2. Click "Open your computer's proxy settings"
3. Set SOCKS proxy to `127.0.0.1` and port `1080`

For Firefox:
1. Go to Settings → General → Network Settings
2. Select "Manual proxy configuration"
3. Set SOCKS Host to `127.0.0.1`, Port `1080`
4. Select "SOCKS v5"

### 4. Verify It's Working

1. Open your browser and visit [https://httpbin.org/ip](https://httpbin.org/ip)
2. The IP address should be different from your actual IP
3. Visit [https://browserleaks.com/ip](https://browserleaks.com/ip) to verify your connection details

## Detailed Setup Instructions

### Starting the Proxy Service

1. **Navigate to the Project Directory**:
   ```bash
   cd /path/to/Nwk
   ```

2. **Review Configuration Files**:
   - Check [`.env.local`](.env.local:1) for environment variables
   - Review [`client-config.json`](client-config.json:1) for proxy settings

3. **Start the Service**:
   ```bash
   # Start in detached mode (runs in background)
   docker-compose -f docker-compose.yml --env-file .env.local up -d
   
   # Or start in foreground to see logs
   docker-compose -f docker-compose.yml --env-file .env.local up
   ```

4. **Verify the Service is Running**:
   ```bash
   # Check container status
   docker-compose ps
   
   # View logs
   docker-compose logs -f v2ray
   ```

5. **Stop the Service** (when needed):
   ```bash
   docker-compose down
   ```

### Configuring Applications to Use the Proxy

#### Web Browsers

**Chrome/Edge/Chromium**:
1. Go to Settings → Advanced → System
2. Click "Open your computer's proxy settings"
3. Configure as shown in the Application Configuration section below

**Firefox**:
1. Go to Settings → General → Network Settings
2. Select "Manual proxy configuration"
3. Configure as shown in the Application Configuration section below

#### System-wide Proxy Settings

**Windows 10/11**:
1. Open Settings → Network & Internet → Proxy
2. Under "Manual proxy setup", turn on "Use a proxy server"
3. Set Address to `127.0.0.1` and Port to `1080`
4. Check "Don't use the proxy server for local addresses"
5. Click Save

**macOS**:
1. Open System Preferences → Network
2. Select your active connection and click "Advanced"
3. Go to the "Proxies" tab
4. Check "SOCKS Proxy"
5. Set Server to `127.0.0.1` and Port to `1080`
6. Click OK and then Apply

**Linux (Ubuntu/Debian)**:
1. Open Settings → Network → Network Proxy
2. Select "Manual"
3. Set SOCKS Host to `127.0.0.1` and Port `1080`
4. Click Apply system-wide

## Application Configuration

### Web Browsers

#### Chrome/Edge/Chromium

**Method 1: System Proxy Settings**
1. Go to Settings → Advanced → System
2. Click "Open your computer's proxy settings"
3. Configure system-wide proxy as described above

**Method 2: Command Line Flags**
```bash
# Launch Chrome with proxy settings
google-chrome --proxy-server="socks5://127.0.0.1:1080"

# For Windows
"C:\Program Files\Google\Chrome\Application\chrome.exe" --proxy-server="socks5://127.0.0.1:1080"
```

#### Firefox

1. Go to Settings → General → Network Settings
2. Select "Manual proxy configuration"
3. Set SOCKS Host to `127.0.0.1`, Port `1080`
4. Select "SOCKS v5"
5. Check "Proxy DNS when using SOCKS v5"
6. Click OK

### System-wide Proxy Settings

#### Windows

1. Open Settings → Network & Internet → Proxy
2. Under "Manual proxy setup", turn on "Use a proxy server"
3. Set Address to `127.0.0.1` and Port to `1080`
4. Add the following to the "Exceptions" field:
   ```
   localhost,127.*,10.*,172.16.*,172.17.*,172.18.*,172.19.*,172.20.*,172.21.*,172.22.*,172.23.*,172.24.*,172.25.*,172.26.*,172.27.*,172.28.*,172.29.*,172.30.*,172.31.*,192.168.*
   ```
5. Click Save

#### macOS

1. Open System Preferences → Network
2. Select your active connection and click "Advanced"
3. Go to the "Proxies" tab
4. Check "SOCKS Proxy"
5. Set Server to `127.0.0.1` and Port `1080`
6. Add these domains to "Bypass proxy settings for these Hosts & Domains":
   ```
   localhost, 127.0.0.1, *.local, 10.*, 172.16.*, 172.17.*, 172.18.*, 172.19.*, 172.20.*, 172.21.*, 172.22.*, 172.23.*, 172.24.*, 172.25.*, 172.26.*, 172.27.*, 172.28.*, 172.29.*, 172.30.*, 172.31.*, 192.168.*
   ```
7. Click OK and then Apply

#### Linux (Ubuntu/Debian)

1. Open Settings → Network → Network Proxy
2. Select "Manual"
3. Set SOCKS Host to `127.0.0.1` and Port `1080`
4. Click "Apply system-wide"

Or via command line:
```bash
# Set proxy environment variables
export ALL_PROXY="socks5://127.0.0.1:1080"
export no_proxy="localhost,127.0.0.1,::1"

# Add to ~/.bashrc for persistence
echo 'export ALL_PROXY="socks5://127.0.0.1:1080"' >> ~/.bashrc
echo 'export no_proxy="localhost,127.0.0.1,::1"' >> ~/.bashrc
```

### Specific Applications

#### Telegram Desktop

1. Go to Settings → Advanced → Connection Type
2. Select "Use custom proxy"
3. Select "SOCKS5"
4. Set Server to `127.0.0.1` and Port `1080`
5. Click Save

#### Discord

1. Go to User Settings → Appearance → Advanced
2. Enable "Developer Mode"
3. Close and reopen Discord
4. Press Ctrl+Shift+I to open Developer Tools
5. Go to Console tab and enter:
   ```javascript
   settings.set("proxy", { address: "127.0.0.1", port: 1080, protocol: "socks5" })
   ```
6. Restart Discord

#### Steam

1. Go to Settings → In-Game
2. Set "Proxy Server" to `SOCKS5`
3. Set Address to `127.0.0.1` and Port `1080`
4. Click OK

## Troubleshooting

### Common Issues and Solutions

#### Proxy Not Connecting

**Problem**: Applications can't connect through the proxy

**Solutions**:
1. Check if the Docker container is running:
   ```bash
   docker-compose ps
   ```

2. Check container logs for errors:
   ```bash
   docker-compose logs v2ray
   ```

3. Verify the proxy port is accessible:
   ```bash
   # On Windows/macOS/Linux
   telnet 127.0.0.1 1080
   
   # Or with curl
   curl --socks5 127.0.0.1:1080 http://httpbin.org/ip
   ```

4. Restart the proxy service:
   ```bash
   docker-compose restart v2ray
   ```

#### Slow Connection Speeds

**Problem**: Internet is slow when using the proxy

**Solutions**:
1. Check Docker resource limits in [`docker-compose.yml`](docker-compose.yml:30-35)
2. Increase memory and CPU limits if needed
3. Try different DNS servers in [`.env.local`](.env.local:16)
4. Check if your ISP is throttling WebSocket connections

#### DNS Leaks

**Problem**: DNS requests are bypassing the proxy

**Solutions**:
1. Ensure "Proxy DNS when using SOCKS v5" is enabled in Firefox
2. Use DNS-over-HTTPS in your browser
3. Configure system DNS to use the proxy

#### Docker Issues

**Problem**: Docker container fails to start

**Solutions**:
1. Check Docker Desktop is running
2. Verify Docker has sufficient resources
3. Check for port conflicts:
   ```bash
   # On Windows/macOS/Linux
   netstat -an | grep 1080
   ```
4. Rebuild the container:
   ```bash
   docker-compose down
   docker-compose up --build -d
   ```

### Debugging Commands

```bash
# Check container status
docker-compose ps

# View real-time logs
docker-compose logs -f v2ray

# Check container resource usage
docker stats

# Test proxy connectivity
curl --socks5 127.0.0.1:1080 http://httpbin.org/ip

# Check if port is listening
# On Windows
netstat -an | findstr 1080

# On macOS/Linux
lsof -i :1080
```

## Security Considerations

### Local Security

1. **Local Access Only**: The proxy is configured to accept connections only from localhost (127.0.0.1)
2. **No Authentication**: The proxy doesn't require authentication, so ensure only trusted applications can access it
3. **Container Isolation**: Docker provides isolation between the proxy and your system

### Network Security

1. **TLS Encryption**: All traffic is encrypted with TLS
2. **Traffic Disguising**: Traffic appears as Zoom connections
3. **DNS Protection**: Multiple DNS servers prevent DNS poisoning

### Privacy Considerations

1. **Remote Server**: Your traffic passes through a remote V2Ray server
2. **Logging**: The remote server may log connection metadata
3. **Provider Trust**: You must trust the proxy server provider

### Best Practices

1. **Use HTTPS**: Always prefer HTTPS websites when using the proxy
2. **Selective Routing**: Configure proxy bypass for local and trusted networks
3. **Regular Updates**: Keep Docker and the proxy image updated
4. **Monitor Logs**: Regularly check logs for unusual activity

## Testing and Verification

### Verifying Traffic is Disguised as Zoom

1. **Network Traffic Analysis**:
   ```bash
   # Use tcpdump to analyze traffic (requires admin/root)
   # On Linux/macOS
   sudo tcpdump -i any host partner.zoom.mobitel.asia
   
   # On Windows (using Wireshark)
   # Filter for: ip.addr == partner.zoom.mobitel.asia
   ```

2. **Browser Headers Check**:
   - Open Developer Tools in your browser (F12)
   - Go to Network tab
   - Check request headers for WebSocket connections
   - Verify the Host header shows `partner.zoom.mobitel.asia`

3. **IP Verification**:
   - Visit [https://httpbin.org/ip](https://httpbin.org/ip) to check your external IP
   - Visit [https://browserleaks.com/ip](https://browserleaks.com/ip) for detailed connection info

### Performance Testing

1. **Speed Test**:
   ```bash
   # Test speed through proxy
   curl --socks5 127.0.0.1:1080 -o /dev/null http://speedtest.wdc01.softlayer.com/downloads/test10.zip
   
   # Compare with direct connection
   curl -o /dev/null http://speedtest.wdc01.softlayer.com/downloads/test10.zip
   ```

2. **Latency Test**:
   ```bash
   # Test latency through proxy
   curl --socks5 127.0.0.1:1080 -o /dev/null -w "%{time_total}\n" http://httpbin.org/delay/1
   
   # Compare with direct connection
   curl -o /dev/null -w "%{time_total}\n" http://httpbin.org/delay/1
   ```

### DNS Leak Test

1. **Browser Test**:
   - Visit [https://dnsleaktest.com](https://dnsleaktest.com)
   - Check if your ISP's DNS servers are shown
   - If they are, DNS is leaking

2. **Command Line Test**:
   ```bash
   # Check DNS resolution through proxy
   curl --socks5 127.0.0.1:1080 http://httpbin.org/dns/8.8.8.8/google.com
   ```

## Advanced Configuration

### Customizing Proxy Settings

To modify proxy settings, edit the following files:

1. **Change Proxy Port**:
   - Edit [`client-config.json`](client-config.json:18) and change the port value
   - Edit [`.env.local`](.env.local:7) to update the SOCKS_PROXY_PORT
   - Update [`docker-compose.yml`](docker-compose.yml:11) to expose the new port

2. **Change Remote Server**:
   - Edit [`client-config.json`](client-config.json:40) to change the server address
   - Edit [`.env.local`](.env.local:4) to update the V2RAY_SERVER

3. **Modify DNS Servers**:
   - Edit [`client-config.json`](client-config.json:8-13) to change DNS servers
   - Edit [`.env.local`](.env.local:16) to update the DNS_SERVERS

### Creating Multiple Proxy Instances

To run multiple proxy instances with different configurations:

1. Create new configuration files:
   ```bash
   cp client-config.json client-config-2.json
   cp .env.local .env.local-2
   ```

2. Modify the new configuration files with different ports

3. Create a new docker-compose file:
   ```bash
   cp docker-compose.yml docker-compose-2.yml
   ```

4. Update the new docker-compose file to use the new configuration files

5. Start the second instance:
   ```bash
   docker-compose -f docker-compose-2.yml --env-file .env.local-2 up -d
   ```

## Maintenance

### Regular Tasks

1. **Update Docker Image**:
   ```bash
   docker-compose pull
   docker-compose up -d --force-recreate
   ```

2. **Clean Up Old Containers**:
   ```bash
   docker system prune -f
   ```

3. **Backup Configuration**:
   ```bash
   tar -czf proxy-config-backup.tar.gz client-config.json .env.local docker-compose.yml Dockerfile
   ```

### Monitoring

1. **Check Resource Usage**:
   ```bash
   docker stats v2ray-client
   ```

2. **Monitor Logs**:
   ```bash
   docker-compose logs -f --tail=100 v2ray
   ```

3. **Health Check**:
   ```bash
   docker inspect v2ray-client | grep Health -A 10
   ```

## Support

If you encounter issues with the local proxy:

1. Check the troubleshooting section above
2. Review the container logs for error messages
3. Verify your Docker installation is working correctly
4. Ensure your network allows outbound connections on port 443

For additional support, refer to the main project documentation or open an issue on the project repository.