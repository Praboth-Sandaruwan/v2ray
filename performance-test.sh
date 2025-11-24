#!/bin/bash

# V2Ray Performance Testing and Monitoring Script
# This script tests and monitors the performance of the V2Ray proxy

set -e

# Configuration
PROXY_HOST="127.0.0.1"
PROXY_PORT="${SOCKS_PROXY_PORT:-1080}"
TEST_DURATION=60
LOG_FILE="performance-test-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if proxy is running
check_proxy_status() {
    print_status "Checking V2Ray proxy status..."
    
    if curl -s --socks5 "${PROXY_HOST}:${PROXY_PORT}" --connect-timeout 5 http://www.google.com > /dev/null 2>&1; then
        print_success "V2Ray proxy is running and accessible"
        return 0
    else
        print_error "V2Ray proxy is not accessible"
        return 1
    fi
}

# Function to test connection latency
test_latency() {
    print_status "Testing connection latency..."
    
    local total_time=0
    local iterations=10
    local failed=0
    
    for i in $(seq 1 $iterations); do
        local start_time=$(date +%s%N)
        if curl -s --socks5 "${PROXY_HOST}:${PROXY_PORT}" --connect-timeout 10 --max-time 10 http://www.google.com > /dev/null 2>&1; then
            local end_time=$(date +%s%N)
            local latency=$(( (end_time - start_time) / 1000000 ))
            total_time=$((total_time + latency))
            echo "  Test $i: ${latency}ms"
        else
            failed=$((failed + 1))
            echo "  Test $i: Failed"
        fi
    done
    
    if [ $failed -eq $iterations ]; then
        print_error "All latency tests failed"
        return 1
    fi
    
    local successful_tests=$((iterations - failed))
    local avg_latency=$((total_time / successful_tests))
    
    print_success "Average latency: ${avg_latency}ms (Failed: $failed/$iterations)"
    echo "LATENCY_RESULT=${avg_latency}" >> "${LOG_FILE}"
}

# Function to test download speed
test_download_speed() {
    print_status "Testing download speed..."
    
    local test_file="http://speedtest.tele2.net/10MB.zip"
    local temp_file="/tmp/speedtest_$(date +%s).tmp"
    
    local start_time=$(date +%s)
    
    if curl -s --socks5 "${PROXY_HOST}:${PROXY_PORT}" --connect-timeout 30 --max-time 120 -o "$temp_file" "$test_file"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        local file_size=$(stat -c%s "$temp_file" 2>/dev/null || stat -f%z "$temp_file" 2>/dev/null || echo 0)
        
        if [ $file_size -gt 0 ]; then
            local speed_mbps=$(( file_size * 8 / duration / 1000000 ))
            print_success "Download speed: ${speed_mbps} Mbps (File: $((file_size/1024/1024))MB in ${duration}s)"
            echo "DOWNLOAD_SPEED_RESULT=${speed_mbps}" >> "${LOG_FILE}"
        else
            print_error "Failed to download test file"
        fi
    else
        print_error "Download speed test failed"
    fi
    
    rm -f "$temp_file"
}

# Function to test upload speed
test_upload_speed() {
    print_status "Testing upload speed..."
    
    local temp_file="/tmp/upload_test_$(date +%s).tmp"
    dd if=/dev/zero of="$temp_file" bs=1M count=5 2>/dev/null
    
    local start_time=$(date +%s)
    
    if curl -s --socks5 "${PROXY_HOST}:${PROXY_PORT}" --connect-timeout 30 --max-time 120 -X POST --data-binary @"$temp_file" "http://httpbin.org/post" > /dev/null 2>&1; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        local file_size=$(stat -c%s "$temp_file" 2>/dev/null || stat -f%z "$temp_file" 2>/dev/null || echo 0)
        
        if [ $file_size -gt 0 ]; then
            local speed_mbps=$(( file_size * 8 / duration / 1000000 ))
            print_success "Upload speed: ${speed_mbps} Mbps (File: $((file_size/1024/1024))MB in ${duration}s)"
            echo "UPLOAD_SPEED_RESULT=${speed_mbps}" >> "${LOG_FILE}"
        else
            print_error "Failed to upload test file"
        fi
    else
        print_error "Upload speed test failed"
    fi
    
    rm -f "$temp_file"
}

# Function to test concurrent connections
test_concurrent_connections() {
    print_status "Testing concurrent connections..."
    
    local connections=20
    local success_count=0
    local failed_count=0
    
    for i in $(seq 1 $connections); do
        (
            if curl -s --socks5 "${PROXY_HOST}:${PROXY_PORT}" --connect-timeout 10 --max-time 10 "http://httpbin.org/delay/1" > /dev/null 2>&1; then
                echo "SUCCESS"
            else
                echo "FAILED"
            fi
        ) &
    done
    
    for job in $(jobs -p); do
        wait $job
        if [ $? -eq 0 ]; then
            success_count=$((success_count + 1))
        else
            failed_count=$((failed_count + 1))
        fi
    done
    
    print_success "Concurrent connections test: $success_count/$connections successful"
    echo "CONCURRENT_CONNECTIONS_RESULT=${success_count}/${connections}" >> "${LOG_FILE}"
}

# Function to test DNS resolution speed
test_dns_resolution() {
    print_status "Testing DNS resolution speed..."
    
    local domains=("google.com" "github.com" "cloudflare.com" "amazon.com")
    local total_time=0
    local failed=0
    
    for domain in "${domains[@]}"; do
        local start_time=$(date +%s%N)
        if curl -s --socks5 "${PROXY_HOST}:${PROXY_PORT}" --connect-timeout 5 --max-time 5 "http://$domain" > /dev/null 2>&1; then
            local end_time=$(date +%s%N)
            local resolution_time=$(( (end_time - start_time) / 1000000 ))
            total_time=$((total_time + resolution_time))
            echo "  $domain: ${resolution_time}ms"
        else
            failed=$((failed + 1))
            echo "  $domain: Failed"
        fi
    done
    
    if [ $failed -eq ${#domains[@]} ]; then
        print_error "All DNS resolution tests failed"
        return 1
    fi
    
    local successful_tests=$((${#domains[@]} - failed))
    local avg_resolution_time=$((total_time / successful_tests))
    
    print_success "Average DNS resolution time: ${avg_resolution_time}ms (Failed: $failed/${#domains[@]})"
    echo "DNS_RESOLUTION_RESULT=${avg_resolution_time}" >> "${LOG_FILE}"
}

# Function to monitor system resources
monitor_system_resources() {
    print_status "Monitoring system resources..."
    
    echo "=== System Resources ===" >> "${LOG_FILE}"
    
    # CPU usage
    if command -v top >/dev/null 2>&1; then
        echo "CPU Usage:" >> "${LOG_FILE}"
        top -bn1 | grep "Cpu(s)" >> "${LOG_FILE}"
    fi
    
    # Memory usage
    if command -v free >/dev/null 2>&1; then
        echo "Memory Usage:" >> "${LOG_FILE}"
        free -h >> "${LOG_FILE}"
    fi
    
    # Network connections
    if command -v ss >/dev/null 2>&1; then
        echo "Network Connections:" >> "${LOG_FILE}"
        ss -s >> "${LOG_FILE}"
    fi
    
    # Disk I/O
    if command -v iostat >/dev/null 2>&1; then
        echo "Disk I/O:" >> "${LOG_FILE}"
        iostat -x 1 1 >> "${LOG_FILE}"
    fi
    
    print_success "System resources monitoring completed"
}

# Function to test connection stability
test_connection_stability() {
    print_status "Testing connection stability for ${TEST_DURATION} seconds..."
    
    local success_count=0
    local failed_count=0
    local start_time=$(date +%s)
    local end_time=$((start_time + TEST_DURATION))
    
    while [ $(date +%s) -lt $end_time ]; do
        if curl -s --socks5 "${PROXY_HOST}:${PROXY_PORT}" --connect-timeout 5 --max-time 5 "http://www.google.com" > /dev/null 2>&1; then
            success_count=$((success_count + 1))
        else
            failed_count=$((failed_count + 1))
        fi
        sleep 2
    done
    
    local total_tests=$((success_count + failed_count))
    local success_rate=$((success_count * 100 / total_tests))
    
    print_success "Connection stability: ${success_rate}% success rate (${success_count}/${total_tests})"
    echo "STABILITY_RESULT=${success_rate}" >> "${LOG_FILE}"
}

# Function to generate performance report
generate_report() {
    print_status "Generating performance report..."
    
    echo "=== V2Ray Performance Test Report ===" >> "${LOG_FILE}"
    echo "Test Date: $(date)" >> "${LOG_FILE}"
    echo "Proxy: ${PROXY_HOST}:${PROXY_PORT}" >> "${LOG_FILE}"
    echo "" >> "${LOG_FILE}"
    
    if [ -f "${LOG_FILE}" ]; then
        echo "Performance test completed. Results saved to: ${LOG_FILE}"
        
        # Display summary
        echo ""
        echo "=== Performance Test Summary ==="
        grep "_RESULT=" "${LOG_FILE}" | while read line; do
            key=$(echo "$line" | cut -d'=' -f1)
            value=$(echo "$line" | cut -d'=' -f2)
            case $key in
                "LATENCY_RESULT")
                    echo "Average Latency: ${value}ms"
                    ;;
                "DOWNLOAD_SPEED_RESULT")
                    echo "Download Speed: ${value} Mbps"
                    ;;
                "UPLOAD_SPEED_RESULT")
                    echo "Upload Speed: ${value} Mbps"
                    ;;
                "CONCURRENT_CONNECTIONS_RESULT")
                    echo "Concurrent Connections: ${value} successful"
                    ;;
                "DNS_RESOLUTION_RESULT")
                    echo "DNS Resolution Time: ${value}ms"
                    ;;
                "STABILITY_RESULT")
                    echo "Connection Stability: ${value}% success rate"
                    ;;
            esac
        done
    fi
}

# Main execution
main() {
    echo "=== V2Ray Performance Testing Suite ==="
    echo "Starting performance tests for V2Ray proxy at ${PROXY_HOST}:${PROXY_PORT}"
    echo ""
    
    # Check if proxy is running
    if ! check_proxy_status; then
        print_error "Cannot proceed with performance tests - proxy is not accessible"
        exit 1
    fi
    
    echo ""
    
    # Run performance tests
    test_latency
    echo ""
    
    test_download_speed
    echo ""
    
    test_upload_speed
    echo ""
    
    test_concurrent_connections
    echo ""
    
    test_dns_resolution
    echo ""
    
    test_connection_stability
    echo ""
    
    monitor_system_resources
    echo ""
    
    generate_report
    
    print_success "All performance tests completed!"
}

# Run main function
main "$@"