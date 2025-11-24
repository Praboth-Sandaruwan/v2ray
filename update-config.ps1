# Dynamic Configuration Update Script for V2Ray (PowerShell Version)
# Updates the client configuration with the generated UUID

param(
    [Parameter(Mandatory = $true)]
    [string]$NewUuid,
    
    [string]$ConfigTemplate = ".\client-config.json",
    [string]$ConfigOutput = ".\client-config.updated.json"
)

# Logging function
function Log {
    param([string]$Message)
    Write-Host "[V2Ray-Config] $Message" -ForegroundColor Cyan
}

# Validate UUID format
function Test-UuidFormat {
    param([string]$Uuid)
    $pattern = '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    return $Uuid -match $pattern
}

# Update UUID in configuration file
function Update-ConfigUuid {
    param([string]$NewUuid)
    
    Log "Updating configuration with UUID: $NewUuid"
    
    # Validate the new UUID
    if (-not (Test-UuidFormat -Uuid $NewUuid)) {
        Log "ERROR: Invalid UUID provided for configuration update"
        return $false
    }
    
    # Check if template exists
    if (-not (Test-Path $ConfigTemplate)) {
        Log "ERROR: Template file not found: $ConfigTemplate"
        return $false
    }
    
    # Create backup of existing config
    if (Test-Path $ConfigOutput) {
        $backupPath = "$ConfigOutput.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
        Copy-Item $ConfigOutput $backupPath
        Log "Created backup: $backupPath"
    }
    
    try {
        # Read configuration file
        $config = Get-Content $ConfigTemplate -Raw | ConvertFrom-Json
        
        # Update UUID in all user objects
        $config.outbounds | ForEach-Object {
            if ($_.settings.vnext) {
                $_.settings.vnext | ForEach-Object {
                    if ($_.users) {
                        $_.users | ForEach-Object {
                            $_.id = $NewUuid
                        }
                    }
                }
            }
        }
        
        # Save updated configuration
        $config | ConvertTo-Json -Depth 10 | Set-Content $ConfigOutput
        
        Log "Configuration updated successfully"
        return $true
    }
    catch {
        Log "ERROR: Failed to update configuration - $($_.Exception.Message)"
        return $false
    }
}

# Verify configuration file
function Test-Config {
    if (-not (Test-Path $ConfigOutput)) {
        Log "ERROR: Configuration file does not exist"
        return $false
    }
    
    try {
        # Basic validation - check if UUID is present and valid
        $config = Get-Content $ConfigOutput -Raw | ConvertFrom-Json
        $foundUuid = $false
        
        foreach ($out in $config.outbounds) {
            if ($out.settings.vnext) {
                foreach ($v in $out.settings.vnext) {
                    if ($v.users) {
                        foreach ($u in $v.users) {
                            if ($u.id -and (Test-UuidFormat -Uuid $u.id)) {
                                $foundUuid = $true
                                Log "Configuration verified with UUID: $($u.id)"
                                break
                            }
                        }
                        if ($foundUuid) { break }
                    }
                }
                if ($foundUuid) { break }
            }
        }
        
        return $foundUuid
    }
    catch {
        Log "ERROR: Configuration validation failed - $($_.Exception.Message)"
        return $false
    }
}

# Main execution
Log "Starting configuration update process"

# Validate input UUID
if (-not (Test-UuidFormat -Uuid $NewUuid)) {
    Log "ERROR: Invalid UUID provided: $NewUuid"
    exit 1
}

# Update configuration
if (Update-ConfigUuid -NewUuid $NewUuid) {
    # Verify the updated configuration
    if (Test-Config) {
        Log "Configuration update completed successfully"
        exit 0
    }
    else {
        Log "ERROR: Configuration verification failed"
        exit 1
    }
}
else {
    Log "ERROR: Configuration update failed"
    exit 1
}