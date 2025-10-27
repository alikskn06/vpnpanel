#!/bin/bash

# ============================================
# VPN Panel - Main Setup Script
# Version: 1.0.0
# Author: Professional VPN Panel
# ============================================

SCRIPT_PATH=$(dirname "$(readlink -f "$0")")

# Source utilities if available
if [ -f "${SCRIPT_PATH}/utils.sh" ]; then
    source "${SCRIPT_PATH}/utils.sh"
else
    echo "Error: utils.sh not found!"
    exit 1
fi

# System Requirements
REQUIRED_RAM=512
REQUIRED_DISK=2

check_system_requirements() {
    print_box "Checking System Requirements"
    
    local total_ram=$(free -m | awk '/^Mem:/ {print $2}')
    if [ $total_ram -lt $REQUIRED_RAM ]; then
        print_error "Insufficient RAM! Required: ${REQUIRED_RAM}MB"
        exit 1
    else
        print_success "RAM: ${total_ram}MB ✓"
    fi
    
    local free_disk=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ $free_disk -lt $REQUIRED_DISK ]; then
        print_error "Insufficient disk space!"
        exit 1
    else
        print_success "Disk: ${free_disk}GB ✓"
    fi
    
    echo ""
}

install_dependencies() {
    print_box "Installing Packages"
    
    if [ "$OS" == "debian" ]; then
        apt-get update -qq >/dev/null 2>&1
        
        local packages=(curl wget unzip tar gzip bzip2 openssl ca-certificates gnupg lsb-release software-properties-common apt-transport-https cron net-tools jq qrencode socat nginx certbot python3-certbot-nginx ufw fail2ban htop iftop vnstat)
        
        local total=${#packages[@]}
        local current=0
        
        for pkg in "${packages[@]}"; do
            current=$((current + 1))
            progress_bar $current $total
            
            if ! dpkg -l | grep -q "^ii  $pkg "; then
                DEBIAN_FRONTEND=noninteractive apt-get install -y $pkg >/dev/null 2>&1
            fi
        done
        
        print_success "All packages installed ✓"
    fi
    echo ""
}

configure_firewall() {
    print_box "Firewall Configuration"
    
    if command -v ufw &>/dev/null; then
        ufw --force reset >/dev/null 2>&1
        ufw default deny incoming >/dev/null 2>&1
        ufw default allow outgoing >/dev/null 2>&1
        ufw allow 22/tcp >/dev/null 2>&1
        ufw allow 80/tcp >/dev/null 2>&1
        ufw allow 443/tcp >/dev/null 2>&1
        ufw allow 8080/tcp >/dev/null 2>&1
        echo "y" | ufw enable >/dev/null 2>&1
        
        print_success "Firewall configured ✓"
    fi
    echo ""
}

install_xray() {
    print_box "Installing Xray-core"
    
    local xray_version=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | jq -r '.tag_name')
    local download_url="https://github.com/XTLS/Xray-core/releases/download/${xray_version}/Xray-linux-64.zip"
    
    cd /tmp
    wget -q "$download_url" -O xray.zip
    unzip -q xray.zip
    
    mkdir -p /usr/local/bin /usr/local/etc/xray /var/log/xray
    
    mv xray /usr/local/bin/
    chmod +x /usr/local/bin/xray
    
    cat > /etc/systemd/system/xray.service << 'EOF'
[Unit]
Description=Xray Service
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
EOF
    
    cat > /usr/local/etc/xray/config.json << 'EOF'
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  }]
}
EOF
    
    systemctl daemon-reload
    systemctl enable xray >/dev/null 2>&1
    systemctl start xray
    
    print_success "Xray installed ✓"
    echo ""
}

configure_nginx() {
    print_box "Configuring Nginx"
    
    mkdir -p /var/www/vpnpanel
    
    cat > /var/www/vpnpanel/index.html << 'EOF'
<!DOCTYPE html>
<html><head><title>VPN Panel</title>
<style>
body{font-family:Arial;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);display:flex;justify-content:center;align-items:center;height:100vh;margin:0}
.container{background:#fff;padding:40px;border-radius:10px;box-shadow:0 10px 40px rgba(0,0,0,.2);text-align:center}
h1{color:#667eea;margin-bottom:20px}
.status{color:#4CAF50;font-weight:bold}
</style></head><body>
<div class="container">
<h1>🚀 VPN Panel</h1>
<p class="status">✓ System Running</p>
<p>Access via SSH: <code>vpnpanel</code></p>
</div></body></html>
EOF
    
    cat > /etc/nginx/sites-available/vpnpanel << 'EOF'
server {
    listen 8080 default_server;
    server_name _;
    root /var/www/vpnpanel;
    index index.html;
    location / { try_files $uri $uri/ =404; }
}
EOF
    
    ln -sf /etc/nginx/sites-available/vpnpanel /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    systemctl restart nginx
    print_success "Nginx configured ✓"
    echo ""
}

install_panel() {
    print_box "Installing Panel"
    
    mkdir -p /usr/local/vpnpanel/{config,backup,logs,data,scripts}
    
    cp "${SCRIPT_PATH}"/*.sh /usr/local/vpnpanel/scripts/ 2>/dev/null || true
    
    cat > /usr/local/bin/vpnpanel << 'EOF'
#!/bin/bash
cd /usr/local/vpnpanel/scripts
bash menu.sh
EOF
    
    chmod +x /usr/local/bin/vpnpanel
    
    touch /usr/local/vpnpanel/data/{users,traffic}.db
    
    cat > /usr/local/vpnpanel/config/panel.conf << EOF
PANEL_VERSION="1.0.0"
INSTALL_DATE="$(date '+%Y-%m-%d %H:%M:%S')"
SERVER_IP="${SERVER_IP}"
EOF
    
    print_success "Panel installed ✓"
    echo ""
}

finalize_setup() {
    print_box "Finalizing"
    
    chmod -R 755 /usr/local/vpnpanel
    chmod 600 /usr/local/vpnpanel/config/*.conf 2>/dev/null
    
    systemctl enable xray nginx fail2ban vnstat >/dev/null 2>&1
    systemctl start fail2ban vnstat >/dev/null 2>&1
    
    print_success "Setup complete ✓"
    echo ""
}

display_final_info() {
    print_banner
    
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          🎉 INSTALLATION COMPLETED! 🎉                   ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${CYAN}ACCESS INFORMATION:${NC}"
    echo -e "${WHITE}Server IP    :${NC} ${GREEN}${SERVER_IP}${NC}"
    echo -e "${WHITE}Web Panel    :${NC} ${GREEN}http://${SERVER_IP}:8080${NC}"
    echo -e "${WHITE}Start Panel  :${NC} ${YELLOW}vpnpanel${NC}"
    echo ""
    
    print_separator
    
    echo -e "${GREEN}Press Enter to start panel...${NC}"
    read
    vpnpanel
}

main() {
    check_root
    print_banner
    
    echo -e "${CYAN}Starting installation...${NC}\n"
    sleep 2
    
    check_os
    check_internet
    check_system_requirements
    
    if confirm_action "Continue with installation?"; then
        echo ""
        install_dependencies
        configure_firewall
        install_xray
        configure_nginx
        install_panel
        finalize_setup
        display_final_info
    else
        print_warning "Installation cancelled"
        exit 0
    fi
}

main
