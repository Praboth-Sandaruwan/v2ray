#!/bin/bash

# Test Script for UUID Randomization Implementation
# Validates the complete UUID randomization workflow

set -euo pipefail

# Configuration
TEST_DIR="/tmp/v2ray-uuid-test"
LOG_PREFIX="[UUID-Test]"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}${LOG_PREFIX} INFO:${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}${LOG_PREFIX} WARN:${NC} $1"
}

log_error() {
    echo -e "${RED}${LOG_PREFIX} ERROR:${NC} $1"
}

# Test UUID generation script
test_uuid_generation() {
    log_info "Testing UUID generation script..."
    
    # Create test environment
    mkdir -p "$TEST_DIR"
    cp generate-uuid.sh "$TEST_DIR/"
    chmod +x "$TEST_DIR/generate-uuid.sh"
    
    # Test UUID generation
    local uuid1 uuid2
    uuid1=$("$TEST_DIR/generate-uuid.sh" 2>/dev/null || echo "")
    uuid2=$("$TEST_DIR/generate-uuid.sh" 2>/dev/null || echo "")
    
    if [ -z "$uuid1" ]; then
        log_error "Failed to generate first UUID"
        return 1
    fi
    
    if [ -z "$uuid2" ]; then
        log_error "Failed to generate second UUID"
        return 1
    fi
    
    # Validate UUID format
    if [[ ! "$uuid1" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
        log_error "First UUID has invalid format: $uuid1"
        return 1
    fi
    
    if [[ ! "$uuid2" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$ ]]; then
        log_error "Second UUID has invalid format: $uuid2"
        return 1
    fi
    
    # Check UUIDs are different
    if [ "$uuid1" = "$uuid2" ]; then
        log_warn "Generated UUIDs are identical (this might be expected in some cases)"
    else
        log_info "Generated different UUIDs as expected"
    fi
    
    log_info "UUID generation test passed"
    return 0
}

# Test configuration update script
test_config_update() {
    log_info "Testing configuration update script..."
    
    # Create test configuration
    local test_config="$TEST_DIR/test-config.json"
    cat > "$test_config" << 'EOF'
{
  "outbounds": [
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "example.com",
            "port": 443,
            "users": [
              {
                "id": "old-uuid-here-1234-5678-901234567890",
                "level": 0,
                "email": "user@example.com"
              }
            ]
          }
        ]
      }
    }
  ]
}
EOF
    
    # Copy update script
    cp update-config.sh "$TEST_DIR/"
    chmod +x "$TEST_DIR/update-config.sh"
    
    # Test configuration update
    local test_uuid="12345678-1234-1234-1234-123456789012"
    CONFIG_OUTPUT="$test_config" "$TEST_DIR/update-config.sh" "$test_uuid" >/dev/null 2>&1
    
    # Check if UUID was updated
    local updated_uuid
    updated_uuid=$(grep -o '"id": "[^"]*"' "$test_config" | cut -d'"' -f4 || echo "")
    
    if [ "$updated_uuid" = "$test_uuid" ]; then
        log_info "Configuration update test passed"
        return 0
    else
        log_error "Configuration update failed. Expected: $test_uuid, Got: $updated_uuid"
        return 1
    fi
}

# Test environment variable configuration
test_env_config() {
    log_info "Testing environment variable configuration..."
    
    # Check if .env.local has required variables
    if [ ! -f ".env.local" ]; then
        log_error ".env.local file not found"
        return 1
    fi
    
    local required_vars=("V2RAY_UUID" "V2RAY_UUID_FALLBACK" "V2RAY_UUID_RANDOMIZE")
    for var in "${required_vars[@]}"; do
        if ! grep -q "^${var}=" .env.local; then
            log_error "Missing required environment variable: $var"
            return 1
        fi
    done
    
    # Check if UUID randomization is enabled
    if grep -q "^V2RAY_UUID_RANDOMIZE=true" .env.local; then
        log_info "UUID randomization is enabled in configuration"
    else
        log_warn "UUID randomization is not enabled in configuration"
    fi
    
    log_info "Environment configuration test passed"
    return 0
}

# Test Docker configuration
test_docker_config() {
    log_info "Testing Docker configuration..."
    
    # Check if Dockerfile includes UUID scripts
    if ! grep -q "generate-uuid.sh" Dockerfile; then
        log_error "Dockerfile missing generate-uuid.sh copy"
        return 1
    fi
    
    if ! grep -q "update-config.sh" Dockerfile; then
        log_error "Dockerfile missing update-config.sh copy"
        return 1
    fi
    
    # Check if docker-compose.yml has required environment variables
    if ! grep -q "V2RAY_UUID_FALLBACK" docker-compose.yml; then
        log_error "docker-compose.yml missing V2RAY_UUID_FALLBACK"
        return 1
    fi
    
    if ! grep -q "V2RAY_UUID_RANDOMIZE" docker-compose.yml; then
        log_error "docker-compose.yml missing V2RAY_UUID_RANDOMIZE"
        return 1
    fi
    
    # Check if configuration volume is writable
    if grep -q "config.json:ro" docker-compose.yml; then
        log_warn "Configuration file is mounted as read-only, this may prevent UUID updates"
    fi
    
    log_info "Docker configuration test passed"
    return 0
}

# Test complete workflow simulation
test_complete_workflow() {
    log_info "Testing complete workflow simulation..."
    
    # Create test environment
    local test_env_file="$TEST_DIR/.env.test"
    cat > "$test_env_file" << EOF
V2RAY_UUID=eb02f51c-214a-495b-9ebc-ef6e4fba86cd
V2RAY_UUID_FALLBACK=eb02f51c-214a-495b-9ebc-ef6e4fba86cd
V2RAY_UUID_RANDOMIZE=true
EOF
    
    # Simulate startup process
    local test_config="$TEST_DIR/simulated-config.json"
    cp client-config.json "$test_config"
    
    # Generate UUID
    local new_uuid
    new_uuid=$(V2RAY_UUID_FALLBACK="eb02f51c-214a-495b-9ebc-ef6e4fba86cd" "$TEST_DIR/generate-uuid.sh" 2>/dev/null || echo "")
    
    if [ -z "$new_uuid" ]; then
        log_error "Failed to generate UUID in workflow test"
        return 1
    fi
    
    # Update configuration
    CONFIG_OUTPUT="$test_config" "$TEST_DIR/update-config.sh" "$new_uuid" >/dev/null 2>&1
    
    # Verify update
    local final_uuid
    final_uuid=$(grep -o '"id": "[^"]*"' "$test_config" | cut -d'"' -f4 || echo "")
    
    if [ "$final_uuid" = "$new_uuid" ]; then
        log_info "Complete workflow test passed"
        return 0
    else
        log_error "Complete workflow test failed. Expected: $new_uuid, Got: $final_uuid"
        return 1
    fi
}

# Cleanup function
cleanup() {
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
    fi
}

# Main test execution
main() {
    log_info "Starting UUID randomization implementation tests..."
    
    local failed_tests=0
    local total_tests=5
    
    # Run tests
    if ! test_uuid_generation; then
        ((failed_tests++))
    fi
    
    if ! test_config_update; then
        ((failed_tests++))
    fi
    
    if ! test_env_config; then
        ((failed_tests++))
    fi
    
    if ! test_docker_config; then
        ((failed_tests++))
    fi
    
    if ! test_complete_workflow; then
        ((failed_tests++))
    fi
    
    # Cleanup
    cleanup
    
    # Report results
    echo
    log_info "Test Results: $((total_tests - failed_tests))/$total_tests tests passed"
    
    if [ $failed_tests -eq 0 ]; then
        log_info "All tests passed! UUID randomization implementation is ready."
        return 0
    else
        log_error "$failed_tests test(s) failed. Please review the implementation."
        return 1
    fi
}

# Execute main function
main "$@"