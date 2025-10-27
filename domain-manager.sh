#!/bin/bash

# ============================================
# Domain & SSL Certificate Management
# Version: 1.0.0
# ============================================

SCRIPT_DIR="/usr/local/vpnpanel/scripts"
source "${SCRIPT_DIR}/utils.sh" 2>/dev/null || source "$(dirname "$0")/utils.sh"

CONFIG_FILE="/usr/local/vpnpanel/config/panel.conf"

domain_management_menu() {
    while true; do
        print_banner
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC}             ${WHITE}${BOLD}DOMAIN & SSL MANAGEMENT${NC}                  ${CYAN}║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${WHITE}[1]${NC} Add/Change Domain"
        echo -e "${WHITE}[2]${NC} Install SSL Certificate"
        echo -e "${WHITE}[3]${NC} Renew SSL Certificate"
        echo -e "${WHITE}[4]${NC} Show Current Domain"
        echo -e "${WHITE}[5]${NC} Remove Domain"
        echo -e "${WHITE}[0]${NC} Back to Main Menu"
        echo ""
        
        read -p "$(echo -e ${GREEN}Select option: ${NC})" domain_choice
        
        case $domain_choice in
            1) add_change_domain ;;
            2) install_ssl ;;
            3) renew_ssl ;;
            4) show_current_domain ;;
            5) remove_domain ;;
            0) return ;;
            *) print_error "Invalid option" ; press_enter ;;
        esac
    done
}

add_change_domain() {
    print_box "Add/Change Domain"
    
    local domain=$(read_input "Enter domain name" "vpn.example.com")
    
    if ! validate_domain "$domain"; then
        print_error "Invalid domain format"
        press_enter
        return
    fi
    
    print_info "Checking DNS resolution..."
    
    # Check if domain resolves to server IP
    local resolved_ip=$(dig +short "$domain" @8.8.8.8 | tail -n1)
    
    if [ -z "$resolved_ip" ]; then
        print_warning "Domain doesn't resolve to any IP"
        if ! confirm_action "Continue anyway?"; then
            press_enter
            return
        fi
    elif [ "$resolved_ip" != "$SERVER_IP" ]; then
        print_warning "Domain resolves to $resolved_ip but server IP is $SERVER_IP"
        if ! confirm_action "Continue anyway?"; then
            press_enter
            return
        fi
    else
        print_success "Domain resolves correctly to $SERVER_IP"
    fi
    
    # Update config file
    sed -i "s/^DOMAIN=.*/DOMAIN=\"$domain\"/" "$CONFIG_FILE"
    
    # Update Nginx configuration
    update_nginx_domain "$domain"
    
    print_success "Domain updated successfully!"
    echo ""
    echo -e "${GREEN}Domain:${NC} $domain"
    echo -e "${GREEN}Server IP:${NC} $SERVER_IP"
    echo ""
    echo -e "${YELLOW}Next step:${NC} Install SSL certificate (Option 2)"
    
    log_action "Domain updated: $domain"
    
    press_enter
}

update_nginx_domain() {
    local domain=$1
    
    cat > /etc/nginx/sites-available/vpnpanel << EOF
server {
    listen 80;
    listen [::]:80;
    server_name $domain;
    
    location / {
        return 301 https://\$server_name\$request_uri;
    }
}

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name $domain;
    
    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
    
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    root /var/www/vpnpanel;
    index index.html;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF
    
    nginx -t >/dev/null 2>&1 && systemctl reload nginx
}

install_ssl() {
    print_box "Install SSL Certificate"
    
    local domain=$(grep "^DOMAIN=" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d '"')
    
    if [ -z "$domain" ] || [ "$domain" == "-" ]; then
        print_error "No domain configured. Please add a domain first (Option 1)"
        press_enter
        return
    fi
    
    print_info "Installing SSL certificate for: $domain"
    echo ""
    
    local email=$(read_input "Email for certificate notifications" "admin@$domain")
    
    if ! validate_email "$email"; then
        print_warning "Invalid email format, using default"
        email="admin@$domain"
    fi
    
    # Stop nginx temporarily
    systemctl stop nginx
    
    print_info "Requesting SSL certificate from Let's Encrypt..."
    
    # Request certificate
    certbot certonly --standalone \
        --preferred-challenges http \
        --agree-tos \
        --no-eff-email \
        --email "$email" \
        -d "$domain" 2>&1 | tee /tmp/certbot.log
    
    if [ $? -eq 0 ] && [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
        print_success "SSL certificate installed successfully!"
        
        # Update config
        sed -i "s/^SSL_ENABLED=.*/SSL_ENABLED=true/" "$CONFIG_FILE"
        
        # Restart nginx
        systemctl start nginx
        
        echo ""
        echo -e "${GREEN}Domain:${NC} $domain"
        echo -e "${GREEN}Status:${NC} SSL Enabled"
        echo -e "${GREEN}Valid Until:${NC} 90 days"
        echo ""
        echo -e "${YELLOW}Access panel at:${NC} https://$domain"
        
        log_action "SSL certificate installed for: $domain"
    else
        print_error "Failed to install SSL certificate"
        print_info "Check /tmp/certbot.log for details"
        
        # Start nginx anyway
        systemctl start nginx
    fi
    
    press_enter
}

renew_ssl() {
    print_box "Renew SSL Certificate"
    
    print_info "Renewing all SSL certificates..."
    echo ""
    
    certbot renew --quiet
    
    if [ $? -eq 0 ]; then
        systemctl restart nginx xray
        print_success "SSL certificates renewed successfully!"
        
        log_action "SSL certificates renewed"
    else
        print_error "Failed to renew SSL certificates"
    fi
    
    press_enter
}

show_current_domain() {
    print_box "Current Domain Configuration"
    
    local domain=$(grep "^DOMAIN=" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2 | tr -d '"')
    local ssl_enabled=$(grep "^SSL_ENABLED=" "$CONFIG_FILE" 2>/dev/null | cut -d'=' -f2)
    
    echo ""
    
    if [ -z "$domain" ] || [ "$domain" == "-" ]; then
        print_warning "No domain configured"
        echo -e "${GREEN}Server IP:${NC} $SERVER_IP"
        echo -e "${GREEN}Access:${NC} http://$SERVER_IP:8080"
    else
        echo -e "${GREEN}Domain:${NC} $domain"
        echo -e "${GREEN}Server IP:${NC} $SERVER_IP"
        
        if [ "$ssl_enabled" == "true" ] && [ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]; then
            local expiry=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/$domain/fullchain.pem" | cut -d'=' -f2)
            echo -e "${GREEN}SSL Status:${NC} Enabled"
            echo -e "${GREEN}Expires:${NC} $expiry"
            echo -e "${GREEN}Access:${NC} https://$domain"
        else
            echo -e "${YELLOW}SSL Status:${NC} Not Configured"
            echo -e "${GREEN}Access:${NC} http://$domain"
        fi
    fi
    
    echo ""
    press_enter
}

remove_domain() {
    print_box "Remove Domain"
    
    if ! confirm_action "Remove domain configuration?"; then
        press_enter
        return
    fi
    
    # Reset config
    sed -i "s/^DOMAIN=.*/DOMAIN=\"\"/" "$CONFIG_FILE"
    sed -i "s/^SSL_ENABLED=.*/SSL_ENABLED=false/" "$CONFIG_FILE"
    
    # Restore default nginx config
    cat > /etc/nginx/sites-available/vpnpanel << 'EOF'
server {
    listen 8080 default_server;
    server_name _;
    root /var/www/vpnpanel;
    index index.html;
    location / { try_files $uri $uri/ =404; }
}
EOF
    
    systemctl reload nginx
    
    print_success "Domain configuration removed"
    log_action "Domain configuration removed"
    
    press_enter
}
