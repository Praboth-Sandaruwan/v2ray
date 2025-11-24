#!/bin/sh

# Exit on error
set -e

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Function to check if certificate exists and is valid
is_certificate_valid() {
    local domain="$1"
    local cert_path="/etc/letsencrypt/live/$domain/fullchain.pem"
    
    if [ ! -f "$cert_path" ]; then
        log "Certificate not found for $domain"
        return 1
    fi
    
    # Check if certificate expires in less than 30 days
    local expiry_date
    expiry_date=$(openssl x509 -in "$cert_path" -noout -enddate | cut -d= -f2)
    local expiry_timestamp
    expiry_timestamp=$(date -d "$expiry_date" +%s)
    local current_timestamp
    current_timestamp=$(date +%s)
    local days_until_expiry
    days_until_expiry=$(( (expiry_timestamp - current_timestamp) / 86400 ))
    
    if [ "$days_until_expiry" -lt 30 ]; then
        log "Certificate for $domain expires in $days_until_expiry days, renewing..."
        return 1
    fi
    
    log "Certificate for $domain is valid for $days_until_expiry more days"
    return 0
}

# Function to obtain certificate
obtain_certificate() {
    local domain="$1"
    local email="$2"
    
    log "Obtaining certificate for $domain"
    
    certbot certonly \
        --webroot \
        -w /var/www/certbot \
        --email "$email" \
        -d "$domain" \
        --rsa-key-size 4096 \
        --agree-tos \
        --force-renewal \
        --non-interactive \
        --verbose
    
    if [ $? -eq 0 ]; then
        log "Successfully obtained certificate for $domain"
        return 0
    else
        log "Failed to obtain certificate for $domain"
        return 1
    fi
}

# Function to setup initial certificates
setup_initial_certificates() {
    local domain="$DOMAIN"
    local email="$SSL_EMAIL"
    
    if [ -z "$domain" ] || [ -z "$email" ]; then
        log "Error: DOMAIN and SSL_EMAIL environment variables must be set"
        exit 1
    fi
    
    # Create directories if they don't exist
    mkdir -p /etc/letsencrypt/live/"$domain"
    mkdir -p /etc/letsencrypt/archive/"$domain"
    mkdir -p /etc/letsencrypt/renewal
    mkdir -p /var/www/certbot/.well-known/acme-challenge
    
    # Set proper permissions
    chmod 755 /var/www/certbot
    chmod 755 /var/www/certbot/.well-known
    chmod 755 /var/www/certbot/.well-known/acme-challenge
    
    # Generate self-signed certificate for initial setup
    if [ ! -f "/etc/ssl/certs/$domain.crt" ]; then
        log "Generating self-signed certificate for initial setup"
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout "/etc/ssl/private/$domain.key" \
            -out "/etc/ssl/certs/$domain.crt" \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=$domain"
        
        chmod 600 "/etc/ssl/private/$domain.key"
        chmod 644 "/etc/ssl/certs/$domain.crt"
    fi
    
    # Try to obtain Let's Encrypt certificate
    if ! is_certificate_valid "$domain"; then
        obtain_certificate "$domain" "$email"
        
        # If successful, copy certificates to nginx SSL directory
        if [ $? -eq 0 ] && [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
            log "Copying Let's Encrypt certificates to nginx SSL directory"
            cp "/etc/letsencrypt/live/$domain/fullchain.pem" "/etc/ssl/certs/$domain.crt"
            cp "/etc/letsencrypt/live/$domain/privkey.pem" "/etc/ssl/private/$domain.key"
            chmod 644 "/etc/ssl/certs/$domain.crt"
            chmod 600 "/etc/ssl/private/$domain.key"
        fi
    fi
}

# Function to renew certificates
renew_certificates() {
    log "Checking certificate renewal"
    
    certbot renew --webroot -w /var/www/certbot --non-interactive --verbose
    
    if [ $? -eq 0 ]; then
        log "Certificate renewal process completed"
        
        # Reload nginx if certificates were renewed
        local domain="$DOMAIN"
        if [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
            log "Copying renewed certificates to nginx SSL directory"
            cp "/etc/letsencrypt/live/$domain/fullchain.pem" "/etc/ssl/certs/$domain.crt"
            cp "/etc/letsencrypt/live/$domain/privkey.pem" "/etc/ssl/private/$domain.key"
            chmod 644 "/etc/ssl/certs/$domain.crt"
            chmod 600 "/etc/ssl/private/$domain.key"
            
            # Send reload signal to nginx
            if command -v nginx >/dev/null 2>&1 && [ -f /var/run/nginx.pid ]; then
                log "Reloading nginx configuration"
                nginx -s reload
            else
                log "nginx reload skipped (not running in this container)"
            fi
        fi
    else
        log "Certificate renewal failed"
    fi
}

# Main function
main() {
    log "Starting Certbot entrypoint script"
    
    # Setup initial certificates
    setup_initial_certificates
    
    # Start cron for automatic renewal
    log "Setting up cron job for certificate renewal"
    
    # Create cron job for renewal (check twice daily)
    echo "0 0,12 * * * /certbot-entrypoint.sh renew >> /var/log/certbot.log 2>&1" > /etc/crontabs/root
    
    # Start cron daemon
    crond -f -l 2 &
    
    # Handle command line arguments
    case "${1:-}" in
        "renew")
            renew_certificates
            ;;
        "setup")
            setup_initial_certificates
            ;;
        *)
            # Default behavior: setup and then run renewal loop
            while true; do
                sleep 12h
                renew_certificates
            done
            ;;
    esac
}

# Execute main function
main "$@"
