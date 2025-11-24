#!/bin/bash

# UUID Generation Script for V2Ray
# Generates cryptographically secure UUIDs for each container session

set -euo pipefail

# Configuration
UUID_FILE="/tmp/v2ray_current_uuid"
LOG_PREFIX="[V2Ray-UUID]"

# Logging function
log() {
    echo "${LOG_PREFIX} $1" >&2
}

# Validate UUID format
validate_uuid() {
    local uuid="$1"
    if [[ ! "$uuid" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
        log "ERROR: Invalid UUID format: $uuid"
        return 1
    fi
    return 0
}

# Generate cryptographically secure UUID
generate_secure_uuid() {
    local uuid
    local max_attempts=5
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log "Generating UUID (attempt $attempt/$max_attempts)"
        
        # Try multiple methods for UUID generation in order of preference
        if command -v uuidgen >/dev/null 2>&1; then
            # Method 1: Use uuidgen with random option
            uuid=$(uuidgen --random 2>/dev/null || uuidgen)
        elif [ -f /proc/sys/kernel/random/uuid ]; then
            # Method 2: Use kernel random UUID generator
            uuid=$(cat /proc/sys/kernel/random/uuid 2>/dev/null)
        elif command -v python3 >/dev/null 2>&1; then
            # Method 3: Use Python uuid module
            uuid=$(python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null)
        elif command -v openssl >/dev/null 2>&1; then
            # Method 4: Use OpenSSL to generate random bytes and format as UUID
            local random_bytes
            random_bytes=$(openssl rand -hex 16 2>/dev/null)
            if [ -n "$random_bytes" ]; then
                # Format as UUID version 4 (random)
                uuid="${random_bytes:0:8}-${random_bytes:8:4}-4${random_bytes:12:3}-${random_bytes:15:1}${random_bytes:16:3}-${random_bytes:20:12}"
            fi
        else
            # Method 5: Fallback using /dev/urandom
            local random_bytes
            random_bytes=$(od -N16 -tx1 -An /dev/urandom | tr -d ' \n' 2>/dev/null)
            if [ -n "$random_bytes" ]; then
                # Format as UUID version 4 (random)
                uuid="${random_bytes:0:2}${random_bytes:2:2}${random_bytes:4:2}${random_bytes:6:2}-${random_bytes:8:2}${random_bytes:10:2}-4${random_bytes:12:1}${random_bytes:13:2}-${random_bytes:15:1}${random_bytes:16:1}${random_bytes:17:2}-${random_bytes:19:2}${random_bytes:21:2}${random_bytes:23:2}${random_bytes:25:2}${random_bytes:27:2}${random_bytes:29:2}"
            fi
        fi
        
        if [ -n "$uuid" ] && validate_uuid "$uuid"; then
            log "Successfully generated UUID: $uuid"
            echo "$uuid"
            return 0
        fi
        
        log "WARNING: UUID generation attempt $attempt failed"
        attempt=$((attempt + 1))
        sleep 1
    done
    
    log "ERROR: Failed to generate valid UUID after $max_attempts attempts"
    return 1
}

# Get or generate UUID
get_or_generate_uuid() {
    local fallback_uuid="${1:-}"
    
    # Check if UUID file exists and is valid
    if [ -f "$UUID_FILE" ]; then
        local existing_uuid
        existing_uuid=$(cat "$UUID_FILE" 2>/dev/null || echo "")
        if [ -n "$existing_uuid" ] && validate_uuid "$existing_uuid"; then
            log "Using existing UUID: $existing_uuid"
            echo "$existing_uuid"
            return 0
        else
            log "WARNING: Invalid existing UUID, regenerating"
            rm -f "$UUID_FILE"
        fi
    fi
    
    # Generate new UUID
    local new_uuid
    new_uuid=$(generate_secure_uuid)
    if [ $? -eq 0 ] && [ -n "$new_uuid" ]; then
        # Save UUID to file
        echo "$new_uuid" > "$UUID_FILE"
        chmod 600 "$UUID_FILE" 2>/dev/null || true
        log "Generated and saved new UUID: $new_uuid"
        echo "$new_uuid"
        return 0
    fi
    
    # Fallback to provided UUID if available
    if [ -n "$fallback_uuid" ] && validate_uuid "$fallback_uuid"; then
        log "WARNING: Using fallback UUID: $fallback_uuid"
        echo "$fallback_uuid"
        return 0
    fi
    
    log "ERROR: No valid UUID available"
    return 1
}

# Main execution
main() {
    local fallback_uuid="${1:-}"
    local uuid
    
    log "Starting UUID generation process"
    
    uuid=$(get_or_generate_uuid "$fallback_uuid")
    if [ $? -eq 0 ]; then
        echo "$uuid"
        exit 0
    else
        log "CRITICAL ERROR: Failed to generate or retrieve UUID"
        exit 1
    fi
}

# Execute main function with all arguments
main "$@"