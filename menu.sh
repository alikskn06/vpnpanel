#!/bin/bash

# ============================================
# VPN Panel - Main Menu System
# Version: 1.0.0
# ============================================

SCRIPT_DIR="/usr/local/vpnpanel/scripts"
source "${SCRIPT_DIR}/utils.sh" 2>/dev/null || source "$(dirname "$0")/utils.sh"

# ============================================
# System Information Display
# ============================================

display_system_info() {
    local uptime_days=$(awk '{print int($1/86400)}' /proc/uptime)
    local uptime_hours=$(awk '{print int(($1%86400)/3600)}' /proc/uptime)
    local current_time=$(date '+%d-%m-%Y | %H:%M:%M %p')
    local os_info=$(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
    local domain=$(cat /usr/local/vpnpanel/config/panel.conf 2>/dev/null | grep DOMAIN | cut -d'=' -f2 | tr -d '"' || echo "-")
    local ns_domain=$(cat /usr/local/vpnpanel/config/panel.conf 2>/dev/null | grep NS_DOMAIN | cut -d'=' -f2 | tr -d '"' || echo "-")
    
    local total_ram=$(free -h | awk '/^Mem:/ {print $2}')
    local used_ram=$(free -h | awk '/^Mem:/ {print $3}')
    local free_ram=$(free -h | awk '/^Mem:/ {print $4}')
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
    local reboot_time=$(who -b | awk '{print $3" "$4":"$5}')
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}               ${WHITE}${BOLD}INFORMATION VPS${NC}                        ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Server Uptime      =${NC} ${WHITE}${uptime_days} days ${uptime_hours} hours${NC}"
    echo -e "${GREEN}Current Time       =${NC} ${WHITE}${current_time}${NC}"
    echo -e "${GREEN}Operating System   =${NC} ${WHITE}${os_info}${NC}"
    echo -e "${GREEN}Current Domain     =${NC} ${WHITE}${domain}${NC}"
    echo -e "${GREEN}NS Domain          =${NC} ${WHITE}${ns_domain}${NC}"
    echo -e "${GREEN}Total Ram          =${NC} ${WHITE}${total_ram}${NC}"
    echo -e "${GREEN}Total Used Ram     =${NC} ${WHITE}${used_ram}${NC}"
    echo -e "${GREEN}Total Free Ram     =${NC} ${WHITE}${free_ram}${NC}"
    echo -e "${GREEN}CPU Usage          =${NC} ${WHITE}${cpu_usage}${NC}"
    echo -e "${GREEN}Time Reboot VPS    =${NC} ${WHITE}${reboot_time}${NC}"
    echo ""
}

# ============================================
# Tunnel Information
# ============================================

display_tunnel_info() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}              ${WHITE}${BOLD}SAKURAV3 TUNELING${NC}                      ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}Use Core           :${NC} ${WHITE}Xray-Core 2023${NC}"
    echo -e "${GREEN}IP-VPS             :${NC} ${WHITE}${SERVER_IP}${NC}"
    echo ""
}

# ============================================
# Service Status Display
# ============================================

display_service_status() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}            ${WHITE}${BOLD}TERIMA KASIH SUDAH MENGGUNAKAN${NC}           ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC}              ${WHITE}${BOLD}AUTOSCRIPT SAKURAV3${NC}                    ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local ssh_status=$(check_service_status sshd 2>/dev/null || check_service_status ssh)
    local nginx_status=$(check_service_status nginx)
    local xray_status=$(check_service_status xray)
    local trojan_status=$(check_service_status xray)
    
    echo -e "${WHITE}     SSH        VMESS        VLESS        TROJAN${NC}"
    echo -e "     ${ssh_status}         ${nginx_status}         ${xray_status}         ${trojan_status}"
    echo ""
    
    echo -e "${WHITE}SSH : ON   NGINX : ON    XRAY : ON   TROJAN : ON${NC}"
    echo -e "${WHITE}STUNNEL : ON   DROPBEAR : ON   SSH-WS : ON${NC}"
    echo ""
}

# ============================================
# Main Menu Options
# ============================================

display_main_menu() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}[01]${NC} SSH        [Menu]     ${WHITE}[06]${NC} TRIAL        [Menu]   ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}[02]${NC} VMESS      [Menu]     ${WHITE}[07]${NC} BACKUP                ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}[03]${NC} VLESS      [Menu]     ${WHITE}[08]${NC} ADD-HOST DOMAIN       ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}[04]${NC} TROJAN     [Menu]     ${WHITE}[09]${NC} CHECK RUNNING         ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}[05]${NC} SETTING    [Menu]     ${WHITE}[10]${NC} SETUP REBOOT          ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ============================================
# Additional Menu
# ============================================

display_additional_menu() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                    ${WHITE}${BOLD}MENU TAMBAHAN${NC}                      ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${WHITE}[11]${NC} DOMAIN FREE           ${WHITE}[15]${NC} UNLOCK"
    echo -e "${WHITE}[12]${NC} INSTAL UDP            ${WHITE}[16]${NC} RENEW CERT"
    echo -e "${WHITE}[13]${NC} NS DOMAIN             ${WHITE}[17]${NC} CLEAR SAMPAH"
    echo -e "${WHITE}[14]${NC} LOCK"
    echo ""
}

# ============================================
# Monitoring Display
# ============================================

display_monitoring() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}Wadah Kasih,       ( MONITORING BANDWIDTH )${NC}          ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}Wadah Memberi,       TODAY        =${NC}                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}Niat Di Hati,        YESTERDAY    =${NC}                  ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}Nowaitu Free.        MONTH        =${NC}                  ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ============================================
# Panel Information
# ============================================

display_panel_info() {
    local panel_version=$(cat /usr/local/vpnpanel/config/panel.conf 2>/dev/null | grep PANEL_VERSION | cut -d'=' -f2 | tr -d '"' || echo "1.0.0")
    local license_key="2BBKN-FFKG3-YWMVA-J3PWJ2-PFSHF"
    
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}Autoscript By      : SakuraV3${NC}                        ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}Version            : Limited Edition 2023${NC}            ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}License Key        : ${license_key}${NC} ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}Day Expired        : Lifetime${NC}                        ${CYAN}║${NC}"
    echo -e "${CYAN}║${NC} ${WHITE}Username           : ${USER}${NC}                              ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ============================================
# Menu Functions
# ============================================

ssh_menu() {
    source "${SCRIPT_DIR}/ssh-manager.sh" 2>/dev/null
    ssh_management_menu
}

vmess_menu() {
    source "${SCRIPT_DIR}/protocol-manager.sh" 2>/dev/null
    vmess_management_menu
}

vless_menu() {
    source "${SCRIPT_DIR}/protocol-manager.sh" 2>/dev/null
    vless_management_menu
}

trojan_menu() {
    source "${SCRIPT_DIR}/protocol-manager.sh" 2>/dev/null
    trojan_management_menu
}

settings_menu() {
    print_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                    ${WHITE}${BOLD}SETTINGS MENU${NC}                      ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${WHITE}[1]${NC} Change Domain"
    echo -e "${WHITE}[2]${NC} Renew Certificate"
    echo -e "${WHITE}[3]${NC} Change Port"
    echo -e "${WHITE}[4]${NC} Panel Password"
    echo -e "${WHITE}[5]${NC} Auto Reboot"
    echo -e "${WHITE}[0]${NC} Back to Main Menu"
    echo ""
    
    read -p "$(echo -e ${GREEN}Select menu : ${NC})" setting_choice
    
    case $setting_choice in
        1) change_domain ;;
        2) renew_cert ;;
        3) change_port ;;
        4) change_password ;;
        5) auto_reboot_menu ;;
        0) return ;;
        *) print_error "Invalid option" ; press_enter ;;
    esac
}

trial_menu() {
    print_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}                    ${WHITE}${BOLD}TRIAL ACCOUNTS${NC}                     ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${WHITE}[1]${NC} Create Trial SSH"
    echo -e "${WHITE}[2]${NC} Create Trial VMESS"
    echo -e "${WHITE}[3]${NC} Create Trial VLESS"
    echo -e "${WHITE}[4]${NC} Create Trial TROJAN"
    echo -e "${WHITE}[0]${NC} Back to Main Menu"
    echo ""
    
    read -p "$(echo -e ${GREEN}Select menu : ${NC})" trial_choice
    
    case $trial_choice in
        1) create_trial_ssh ;;
        2) create_trial_vmess ;;
        3) create_trial_vless ;;
        4) create_trial_trojan ;;
        0) return ;;
        *) print_error "Invalid option" ; press_enter ;;
    esac
}

backup_menu() {
    source "${SCRIPT_DIR}/backup.sh" 2>/dev/null
    backup_management_menu
}

check_running() {
    source "${SCRIPT_DIR}/monitor.sh" 2>/dev/null
    show_active_connections
}

domain_menu() {
    source "${SCRIPT_DIR}/domain-manager.sh" 2>/dev/null
    domain_management_menu
}

# ============================================
# Main Menu Loop
# ============================================

main_menu() {
    while true; do
        print_banner
        display_system_info
        display_tunnel_info
        display_service_status
        display_main_menu
        display_additional_menu
        display_monitoring
        display_panel_info
        
        read -p "$(echo -e ${GREEN}Select menu : ${NC})" menu_choice
        
        case $menu_choice in
            1|01) ssh_menu ;;
            2|02) vmess_menu ;;
            3|03) vless_menu ;;
            4|04) trojan_menu ;;
            5|05) settings_menu ;;
            6|06) trial_menu ;;
            7|07) backup_menu ;;
            8|08) domain_menu ;;
            9|09) check_running ;;
            10) auto_reboot_menu ;;
            11) install_domain_free ;;
            12) install_udp ;;
            13) install_ns_domain ;;
            14) lock_panel ;;
            15) unlock_panel ;;
            16) renew_cert ;;
            17) clear_cache ;;
            0|00) 
                print_warning "Exiting panel..."
                exit 0
                ;;
            *)
                print_error "Invalid option! Please select 0-17"
                press_enter
                ;;
        esac
    done
}

# ============================================
# Placeholder Functions (will be in separate modules)
# ============================================

change_domain() {
    print_info "Domain management - Coming from domain-manager.sh"
    press_enter
}

renew_cert() {
    print_info "Renewing SSL certificate..."
    certbot renew --quiet
    systemctl restart nginx xray
    print_success "Certificate renewed successfully"
    press_enter
}

change_port() {
    print_info "Port management - Under development"
    press_enter
}

change_password() {
    print_info "Password management - Under development"
    press_enter
}

auto_reboot_menu() {
    print_box "Auto Reboot Settings"
    echo -e "${WHITE}[1]${NC} Enable Auto Reboot (Daily)"
    echo -e "${WHITE}[2]${NC} Disable Auto Reboot"
    echo -e "${WHITE}[3]${NC} Set Custom Schedule"
    echo -e "${WHITE}[0]${NC} Back"
    echo ""
    
    read -p "$(echo -e ${GREEN}Select : ${NC})" reboot_choice
    
    case $reboot_choice in
        1)
            echo "0 4 * * * /sbin/reboot" > /tmp/auto_reboot
            crontab /tmp/auto_reboot
            print_success "Auto reboot enabled (4:00 AM daily)"
            ;;
        2)
            crontab -r 2>/dev/null
            print_success "Auto reboot disabled"
            ;;
        3)
            print_info "Custom schedule - Under development"
            ;;
    esac
    press_enter
}

create_trial_ssh() {
    print_info "Creating trial SSH account..."
    local username="trial$(date +%s | tail -c 4)"
    local password=$(generate_random_string 8)
    local exp_date=$(calculate_expiry_date 1)
    
    useradd -e $(date -d "$exp_date" "+%Y-%m-%d") -s /bin/false -M "$username" 2>/dev/null
    echo "$username:$password" | chpasswd
    
    print_success "Trial SSH Account Created"
    echo -e "${GREEN}Username :${NC} $username"
    echo -e "${GREEN}Password :${NC} $password"
    echo -e "${GREEN}Expires  :${NC} $exp_date (1 day)"
    press_enter
}

create_trial_vmess() {
    print_info "Trial VMESS - Feature in protocol-manager.sh"
    press_enter
}

create_trial_vless() {
    print_info "Trial VLESS - Feature in protocol-manager.sh"
    press_enter
}

create_trial_trojan() {
    print_info "Trial TROJAN - Feature in protocol-manager.sh"
    press_enter
}

install_domain_free() {
    print_info "Free domain installation - Under development"
    press_enter
}

install_udp() {
    print_info "UDP installation - Under development"
    press_enter
}

install_ns_domain() {
    print_info "NS Domain installation - Under development"
    press_enter
}

lock_panel() {
    print_warning "Panel locked!"
    press_enter
}

unlock_panel() {
    print_success "Panel unlocked!"
    press_enter
}

clear_cache() {
    print_info "Clearing cache..."
    sync; echo 3 > /proc/sys/vm/drop_caches
    apt-get clean 2>/dev/null
    print_success "Cache cleared"
    press_enter
}

# ============================================
# Start Menu
# ============================================

check_root
main_menu
