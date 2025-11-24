# UUID Generation Script for V2Ray (PowerShell Version)
# Generates cryptographically secure UUIDs for each container session

param(
    [string]$FallbackUuid = ""
)

# Logging function
function Log {
    param([string]$Message)
    Write-Host "[V2Ray-UUID] $Message" -ForegroundColor Cyan
}

# Validate UUID format
function Test-UuidFormat {
    param([string]$Uuid)
    $pattern = '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
    return $Uuid -match $pattern
}

# Generate cryptographically secure UUID
function New-SecureUuid {
    $maxAttempts = 5
    $attempt = 1
    
    while ($attempt -le $maxAttempts) {
        Log "Generating UUID (attempt $attempt/$maxAttempts)"
        
        try {
            # Method 1: Use .NET GUID generator
            $uuid = [System.Guid]::NewGuid().ToString("D")
            
            if (Test-UuidFormat -Uuid $uuid) {
                Log "Successfully generated UUID: $uuid"
                return $uuid
            }
        }
        catch {
            Log "WARNING: UUID generation attempt $attempt failed - $($_.Exception.Message)"
        }
        
        $attempt++
        Start-Sleep -Seconds 1
    }
    
    Log "ERROR: Failed to generate valid UUID after $maxAttempts attempts"
    return $null
}

# Get or generate UUID
function Get-OrGenerateUuid {
    param([string]$FallbackUuid = "")
    
    # Generate new UUID
    $newUuid = New-SecureUuid
    
    if ($newUuid -and (Test-UuidFormat -Uuid $newUuid)) {
        Log "Generated new UUID: $newUuid"
        return $newUuid
    }
    
    # Fallback to provided UUID if available
    if ($FallbackUuid -and (Test-UuidFormat -Uuid $FallbackUuid)) {
        Log "WARNING: Using fallback UUID: $FallbackUuid"
        return $FallbackUuid
    }
    
    Log "ERROR: No valid UUID available"
    return $null
}

# Main execution
Log "Starting UUID generation process"

$uuid = Get-OrGenerateUuid -FallbackUuid $FallbackUuid

if ($uuid) {
    Write-Output $uuid
    exit 0
} else {
    Log "CRITICAL ERROR: Failed to generate or retrieve UUID"
    exit 1
}