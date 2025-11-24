> Replace `partner.zoom.mobitel.asia`, `/danuwa`, and the UUID with the values you set in `.env`.

1. **Download Shadowrocket** from the App Store
2. **Add Server Configuration**:
   - Open Shadowrocket
   - Tap the "+" button
   - Select "VLESS"
   - Configure:
     ```
     Server: partner.zoom.mobitel.asia
     Port: 443
     ID: 2e50bce3-2c41-4d46-9a25-7b4d478c855a
     Security: TLS
     Network: WebSocket
     Path: /danuwa
     Host: partner.zoom.mobitel.asia
     ```
3. **Import from URL**:
   - Tap "Add from URL"
   - Paste the VLESS URL
   - Tap "Add"

### Quantumult X (iOS)

#### Configuration

1. **Download Quantumult X** from the App Store
2. **Add Server**:
   - Open Quantumult X
   - Go to "Settings" → "Server"
   - Tap "Add Server"
   - Select "VLESS"
   - Configure:
     ```
     Server: partner.zoom.mobitel.asia
     Port: 443
     ID: 2e50bce3-2c41-4d46-9a25-7b4d478c855a
     Security: TLS
     Transport: WebSocket
     Path: /danuwa
     Host: partner.zoom.mobitel.asia
     ```

### V2RayNG (Android)

#### Configuration

1. **Download V2RayNG** from [GitHub](https://github.com/2dust/v2rayNG/releases) or F-Droid
2. **Add Server**:
   - Open V2RayNG
   - Tap the "+" button
   - Select "VLESS"
   - Configure:
     ```
     Address: partner.zoom.mobitel.asia
     Port: 443
     User ID: 2e50bce3-2c41-4d46-9a25-7b4d478c855a
     Security: TLS
     Network: WebSocket
     Path: /danuwa
     Host: partner.zoom.mobitel.asia
     ```
3. **Import from URL**:
   - Tap the menu → "Import from clipboard"
   - Paste the VLESS URL
   - Tap "Import"

## Platform-Specific Instructions

### Windows

#### Using v2rayN

1. **System Proxy Configuration**:
   - Right-click v2rayN → "System Proxy" → "PAC"
   - Or select "Global" for all traffic
   - Configure browser to use system proxy

2. **Browser Configuration**:
   - Chrome: Uses system proxy automatically
   - Firefox: Settings → Network Settings → "Use system proxy settings"
   - Edge: Uses system proxy automatically

#### Using Command Line

```bash
# Set system proxy (PowerShell)
netsh winhttp set proxy 127.0.0.1:1080

# Reset proxy
netsh winhttp reset proxy
```

### macOS

#### Using V2RayX

1. **Download and Install** V2RayX
2. **Import Configuration**:
   - Open V2RayX
   - Click "Import" → "From URL"
   - Paste the VLESS URL
   - Click "Import"

3. **System Proxy**:
   - Enable "System Proxy" in V2RayX
   - Or configure manually in System Preferences

#### Using Command Line

```bash
# Set proxy environment variables
export http_proxy=socks5://127.0.0.1:1080
export https_proxy=socks5://127.0.0.1:1080

# Reset proxy
unset http_proxy
unset https_proxy
```

### Linux

#### Using Qv2ray

1. **Install Qv2ray**:
   ```bash
   # Ubuntu/Debian
   sudo apt install qv2ray
   
   # Or download from GitHub
   wget https://github.com/Qv2ray/Qv2ray/releases/latest/download/Qv2ray-v2.7.0-linux-x64.AppImage
   chmod +x Qv2ray-v2.7.0-linux-x64.AppImage
   ./Qv2ray-v2.7.0-linux-x64.AppImage
   ```

2. **Configure Proxy**:
   - Import the VLESS configuration
   - Set system proxy in network settings

#### Using Command Line

```bash
# Set proxy environment variables
export http_proxy=socks5://127.0.0.1:1080
export https_proxy=socks5://127.0.0.1:1080
export all_proxy=socks5://127.0.0.1:1080

# Configure git to use proxy
git config --global http.proxy socks5://127.0.0.1:1080
git config --global https.proxy socks5://127.0.0.1:1080

# Reset proxy
unset http_proxy https_proxy all_proxy
git config --global --unset http.proxy
git config --global --unset https.proxy
```

### Android

#### Using V2RayNG

1. **Install V2RayNG** from F-Droid or GitHub
2. **Import Configuration**:
   - Copy the VLESS URL
   - Open V2RayNG
   - Tap the menu → "Import from clipboard"
   - Select the imported configuration
   - Tap the connect button

3. **VPN Mode**:
   - Enable "VPN Mode" for system-wide proxy
   - Or use "Proxy Mode" for app-specific proxy

### iOS

#### Using Shadowrocket

1. **Install

Shadowrocket** from the App Store
2. **Add Configuration
