#!/bin/bash

# Dynamic Configuration Update Script for V2Ray
# Updates the client configuration with the generated UUID

set -euo pipefail

# Configuration
CONFIG_TEMPLATE="/etc/v2ray/config.json.template"
CONFIG_OUTPUT="/etc/v2ray/config.json"
LOG_PREFIX="[V2Ray-Config]"

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

# Update UUID in configuration file
update_config_uuid() {
    local new_uuid="$1"
    local temp_file="${CONFIG_OUTPUT}.tmp"
    
    log "Updating configuration with UUID: $new_uuid"
    
    # Validate the new UUID
    if ! validate_uuid "$new_uuid"; then
        log "ERROR: Invalid UUID provided for configuration update"
        return 1
    fi
    
    # Decide which file to update (prefer rendered config to preserve substitutions)
    local source_file="$CONFIG_OUTPUT"
    if [ ! -f "$source_file" ]; then
        if [ -f "$CONFIG_TEMPLATE" ]; then
            log "Rendered config missing, falling back to template"
            source_file="$CONFIG_TEMPLATE"
        else
            log "ERROR: No configuration file available for update"
            return 1
        fi
    fi
    
    # Create backup of existing config
    if [ -f "$CONFIG_OUTPUT" ]; then
        cp "$CONFIG_OUTPUT" "${CONFIG_OUTPUT}.backup.$(date +%s)" 2>/dev/null || true
    fi
    
    # Update UUID using sed (more reliable than JSON parsing in shell)
    if sed "s/\"id\": \"[^\"]*\"/\"id\": \"$new_uuid\"/g" "$source_file" > "$temp_file"; then
        # Validate the generated JSON
        if command -v python3 >/dev/null 2>&1; then
            if python3 -c "import json; json.load(open('$temp_file'))" 2>/dev/null; then
                mv "$temp_file" "$CONFIG_OUTPUT"
                log "Configuration updated successfully"
                return 0
            else
                log "ERROR: Generated configuration is not valid JSON"
                rm -f "$temp_file"
                return 1
            fi
        else
            # Fallback: move file without JSON validation
            mv "$temp_file" "$CONFIG_OUTPUT"
            log "Configuration updated (JSON validation skipped)"
            return 0
        fi
    else
        log "ERROR: Failed to update configuration file"
        rm -f "$temp_file"
        return 1
    fi
}

# Create configuration template if it doesn't exist
create_template_if_needed() {
    if [ ! -f "$CONFIG_TEMPLATE" ]; then
        log "Creating configuration template"
        if [ -f "$CONFIG_OUTPUT" ]; then
            cp "$CONFIG_OUTPUT" "$CONFIG_TEMPLATE"
        else
            log "ERROR: No configuration file available for template creation"
            return 1
        fi
    fi
}

# Verify configuration file
verify_config() {
    if [ ! -f "$CONFIG_OUTPUT" ]; then
        log "ERROR: Configuration file does not exist"
        return 1
    fi
    
    # Basic validation - check if UUID is present
    if grep -q '"id":' "$CONFIG_OUTPUT"; then
        local current_uuid
        current_uuid=$(grep -o '"id": "[^"]*"' "$CONFIG_OUTPUT" | cut -d'"' -f4)
        if validate_uuid "$current_uuid"; then
            log "Configuration verified with UUID: $current_uuid"
            return 0
        else
            log "ERROR: Configuration contains invalid UUID"
            return 1
        fi
    else
        log "ERROR: Configuration does not contain UUID field"
        return 1
    fi
}

# Main execution
main() {
    local new_uuid="$1"
    
    log "Starting configuration update process"
    
    # Validate input UUID
    if ! validate_uuid "$new_uuid"; then
        log "ERROR: Invalid UUID provided: $new_uuid"
        exit 1
    fi
    
    # Create template if needed
    create_template_if_needed
    
    # Update configuration
    if update_config_uuid "$new_uuid"; then
        # Verify the updated configuration
        if verify_config; then
            log "Configuration update completed successfully"
            exit 0
        else
            log "ERROR: Configuration verification failed"
            exit 1
        fi
    else
        log "ERROR: Configuration update failed"
        exit 1
    fi
}

# Execute main function with UUID argument
if [ $# -ne 1 ]; then
    log "ERROR: Usage: $0 <uuid>"
    exit 1
fi

main "$1"
