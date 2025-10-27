#!/bin/bash

# ============================================
# Protocol Manager - VLESS, VMESS, TROJAN
# Version: 1.0.0
# ============================================

SCRIPT_DIR="/usr/local/vpnpanel/scripts"
source "${SCRIPT_DIR}/utils.sh" 2>/dev/null || source "$(dirname "$0")/utils.sh"

XRAY_CONFIG="/usr/local/etc/xray/config.json"
USER_DB="/usr/local/vpnpanel/data/users.db"

# ============================================
# VLESS Management
# ============================================

vless_management_menu() {
    while true; do
        print_banner
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC}                  ${WHITE}${BOLD}VLESS MANAGEMENT${NC}                     ${CYAN}║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${WHITE}[1]${NC} Create VLESS Account"
        echo -e "${WHITE}[2]${NC} Delete VLESS Account"
        echo -e "${WHITE}[3]${NC} Renew VLESS Account"
        echo -e "${WHITE}[4]${NC} List VLESS Accounts"
        echo -e "${WHITE}[5]${NC} Show VLESS Config"
        echo -e "${WHITE}[0]${NC} Back to Main Menu"
        echo ""
        
        read -p "$(echo -e ${GREEN}Select option: ${NC})" vless_choice
        
        case $vless_choice in
            1) create_vless_account ;;
            2) delete_vless_account ;;
            3) renew_vless_account ;;
            4) list_vless_accounts ;;
            5) show_vless_config ;;
            0) return ;;
            *) print_error "Invalid option" ; press_enter ;;
        esac
    done
}

create_vless_account() {
    print_box "Create VLESS Account"
    
    local username=$(read_input "Username" "user$(date +%s | tail -c 4)")
    local days=$(read_input "Validity (days)" "30")
    local limit=$(read_input "Connection limit" "2")
    
    if ! validate_username "$username"; then
        print_error "Invalid username format"
        press_enter
        return
    fi
    
    # Check if user exists
    if grep -q "^vless:$username:" "$USER_DB" 2>/dev/null; then
        print_error "User already exists"
        press_enter
        return
    fi
    
    local uuid=$(generate_uuid)
    local exp_date=$(calculate_expiry_date $days)
    local created_date=$(get_current_date)
    
    # Add inbound to Xray config
    add_vless_inbound "$username" "$uuid"
    
    # Save to database
    echo "vless:$username:$uuid:$created_date:$exp_date:$limit:0" >> "$USER_DB"
    
    # Restart Xray
    systemctl restart xray
    
    print_success "VLESS Account Created Successfully!"
    echo ""
    display_vless_info "$username" "$uuid" "$exp_date"
    
    press_enter
}

add_vless_inbound() {
    local username=$1
    local uuid=$2
    local port=$(generate_random_port 10000 60000)
    
    # Backup config
    backup_file "$XRAY_CONFIG"
    
    # Add inbound configuration
    local temp_config=$(mktemp)
    jq --arg port "$port" --arg uuid "$uuid" --arg email "$username" \
        '.inbounds += [{
            "port": ($port | tonumber),
            "protocol": "vless",
            "settings": {
                "clients": [{
                    "id": $uuid,
                    "email": $email,
                    "level": 0
                }],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "tcp",
                "security": "none"
            },
            "tag": ("vless-" + $email)
        }]' "$XRAY_CONFIG" > "$temp_config"
    
    mv "$temp_config" "$XRAY_CONFIG"
}

display_vless_info() {
    local username=$1
    local uuid=$2
    local exp_date=$3
    local port=$(get_user_port "vless" "$username")
    
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Protocol    :${NC} VLESS"
    echo -e "${GREEN}Username    :${NC} $username"
    echo -e "${GREEN}UUID        :${NC} $uuid"
    echo -e "${GREEN}Server      :${NC} $SERVER_IP"
    echo -e "${GREEN}Port        :${NC} ${port:-443}"
    echo -e "${GREEN}Expires     :${NC} $exp_date"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Generate connection string
    local vless_link="vless://${uuid}@${SERVER_IP}:${port:-443}?type=tcp&security=none#${username}"
    echo -e "${YELLOW}Connection Link:${NC}"
    echo "$vless_link"
    echo ""
    
    # Generate QR code if qrencode is available
    if command -v qrencode &>/dev/null; then
        echo "$vless_link" | qrencode -t ANSIUTF8
        echo ""
    fi
}

delete_vless_account() {
    print_box "Delete VLESS Account"
    
    list_vless_accounts
    echo ""
    
    local username=$(read_input "Username to delete")
    
    if ! grep -q "^vless:$username:" "$USER_DB" 2>/dev/null; then
        print_error "User not found"
        press_enter
        return
    fi
    
    if confirm_action "Delete user $username?"; then
        # Remove from database
        sed -i "/^vless:$username:/d" "$USER_DB"
        
        # Remove from Xray config
        remove_vless_inbound "$username"
        
        systemctl restart xray
        
        print_success "User deleted successfully"
    else
        print_warning "Deletion cancelled"
    fi
    
    press_enter
}

remove_vless_inbound() {
    local username=$1
    local temp_config=$(mktemp)
    
    backup_file "$XRAY_CONFIG"
    
    jq --arg email "$username" \
        'del(.inbounds[] | select(.tag == ("vless-" + $email)))' \
        "$XRAY_CONFIG" > "$temp_config"
    
    mv "$temp_config" "$XRAY_CONFIG"
}

renew_vless_account() {
    print_box "Renew VLESS Account"
    
    list_vless_accounts
    echo ""
    
    local username=$(read_input "Username to renew")
    local days=$(read_input "Additional days" "30")
    
    if ! grep -q "^vless:$username:" "$USER_DB" 2>/dev/null; then
        print_error "User not found"
        press_enter
        return
    fi
    
    local current_exp=$(grep "^vless:$username:" "$USER_DB" | cut -d: -f5)
    local new_exp=$(date -d "$current_exp +$days days" '+%Y-%m-%d')
    
    sed -i "s/^vless:$username:\([^:]*\):\([^:]*\):[^:]*:/vless:$username:\1:\2:$new_exp:/" "$USER_DB"
    
    print_success "Account renewed until: $new_exp"
    press_enter
}

list_vless_accounts() {
    print_box "VLESS Accounts"
    
    if [ ! -f "$USER_DB" ] || ! grep -q "^vless:" "$USER_DB" 2>/dev/null; then
        print_warning "No VLESS accounts found"
        return
    fi
    
    echo -e "${CYAN}┌─────────────┬──────────────┬──────────────┬────────┐${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Username${NC}    ${CYAN}│${NC} ${WHITE}Created${NC}      ${CYAN}│${NC} ${WHITE}Expires${NC}      ${CYAN}│${NC} ${WHITE}Status${NC} ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────┼──────────────┼──────────────┼────────┤${NC}"
    
    grep "^vless:" "$USER_DB" 2>/dev/null | while IFS=: read -r proto user uuid created expires limit traffic; do
        local status="${GREEN}Active${NC}"
        if ! check_expiry "$expires"; then
            status="${RED}Expired${NC}"
        fi
        
        printf "${CYAN}│${NC} %-11s ${CYAN}│${NC} %-12s ${CYAN}│${NC} %-12s ${CYAN}│${NC} %-6b ${CYAN}│${NC}\n" \
            "$user" "$created" "$expires" "$status"
    done
    
    echo -e "${CYAN}└─────────────┴──────────────┴──────────────┴────────┘${NC}"
}

show_vless_config() {
    print_box "Show VLESS Configuration"
    
    local username=$(read_input "Username")
    
    if ! grep -q "^vless:$username:" "$USER_DB" 2>/dev/null; then
        print_error "User not found"
        press_enter
        return
    fi
    
    local user_data=$(grep "^vless:$username:" "$USER_DB")
    local uuid=$(echo "$user_data" | cut -d: -f3)
    local expires=$(echo "$user_data" | cut -d: -f5)
    
    display_vless_info "$username" "$uuid" "$expires"
    press_enter
}

# ============================================
# VMESS Management
# ============================================

vmess_management_menu() {
    while true; do
        print_banner
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC}                  ${WHITE}${BOLD}VMESS MANAGEMENT${NC}                     ${CYAN}║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${WHITE}[1]${NC} Create VMESS Account"
        echo -e "${WHITE}[2]${NC} Delete VMESS Account"
        echo -e "${WHITE}[3]${NC} Renew VMESS Account"
        echo -e "${WHITE}[4]${NC} List VMESS Accounts"
        echo -e "${WHITE}[5]${NC} Show VMESS Config"
        echo -e "${WHITE}[0]${NC} Back to Main Menu"
        echo ""
        
        read -p "$(echo -e ${GREEN}Select option: ${NC})" vmess_choice
        
        case $vmess_choice in
            1) create_vmess_account ;;
            2) delete_vmess_account ;;
            3) renew_vmess_account ;;
            4) list_vmess_accounts ;;
            5) show_vmess_config ;;
            0) return ;;
            *) print_error "Invalid option" ; press_enter ;;
        esac
    done
}

create_vmess_account() {
    print_box "Create VMESS Account"
    
    local username=$(read_input "Username" "user$(date +%s | tail -c 4)")
    local days=$(read_input "Validity (days)" "30")
    
    if ! validate_username "$username"; then
        print_error "Invalid username format"
        press_enter
        return
    fi
    
    if grep -q "^vmess:$username:" "$USER_DB" 2>/dev/null; then
        print_error "User already exists"
        press_enter
        return
    fi
    
    local uuid=$(generate_uuid)
    local exp_date=$(calculate_expiry_date $days)
    local created_date=$(get_current_date)
    local alterid=0
    
    # Add inbound
    add_vmess_inbound "$username" "$uuid" "$alterid"
    
    # Save to database
    echo "vmess:$username:$uuid:$created_date:$exp_date:$alterid:0" >> "$USER_DB"
    
    systemctl restart xray
    
    print_success "VMESS Account Created!"
    echo ""
    display_vmess_info "$username" "$uuid" "$alterid" "$exp_date"
    
    press_enter
}

add_vmess_inbound() {
    local username=$1
    local uuid=$2
    local alterid=${3:-0}
    local port=$(generate_random_port 10000 60000)
    
    backup_file "$XRAY_CONFIG"
    
    local temp_config=$(mktemp)
    jq --arg port "$port" --arg uuid "$uuid" --arg email "$username" --arg alterid "$alterid" \
        '.inbounds += [{
            "port": ($port | tonumber),
            "protocol": "vmess",
            "settings": {
                "clients": [{
                    "id": $uuid,
                    "email": $email,
                    "alterId": ($alterid | tonumber)
                }]
            },
            "streamSettings": {
                "network": "tcp"
            },
            "tag": ("vmess-" + $email)
        }]' "$XRAY_CONFIG" > "$temp_config"
    
    mv "$temp_config" "$XRAY_CONFIG"
}

display_vmess_info() {
    local username=$1
    local uuid=$2
    local alterid=$3
    local exp_date=$4
    local port=$(get_user_port "vmess" "$username")
    
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Protocol    :${NC} VMESS"
    echo -e "${GREEN}Username    :${NC} $username"
    echo -e "${GREEN}UUID        :${NC} $uuid"
    echo -e "${GREEN}AlterID     :${NC} $alterid"
    echo -e "${GREEN}Server      :${NC} $SERVER_IP"
    echo -e "${GREEN}Port        :${NC} ${port:-443}"
    echo -e "${GREEN}Expires     :${NC} $exp_date"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # Generate vmess link (base64 encoded JSON)
    local vmess_json="{\"v\":\"2\",\"ps\":\"$username\",\"add\":\"$SERVER_IP\",\"port\":\"${port:-443}\",\"id\":\"$uuid\",\"aid\":\"$alterid\",\"net\":\"tcp\",\"type\":\"none\",\"host\":\"\",\"path\":\"\",\"tls\":\"\"}"
    local vmess_link="vmess://$(echo -n "$vmess_json" | base64 -w 0)"
    
    echo -e "${YELLOW}Connection Link:${NC}"
    echo "$vmess_link"
    echo ""
    
    if command -v qrencode &>/dev/null; then
        echo "$vmess_link" | qrencode -t ANSIUTF8
        echo ""
    fi
}

delete_vmess_account() {
    print_box "Delete VMESS Account"
    list_vmess_accounts
    echo ""
    
    local username=$(read_input "Username to delete")
    
    if ! grep -q "^vmess:$username:" "$USER_DB" 2>/dev/null; then
        print_error "User not found"
        press_enter
        return
    fi
    
    if confirm_action "Delete user $username?"; then
        sed -i "/^vmess:$username:/d" "$USER_DB"
        remove_vmess_inbound "$username"
        systemctl restart xray
        print_success "User deleted"
    fi
    
    press_enter
}

remove_vmess_inbound() {
    local username=$1
    local temp_config=$(mktemp)
    
    backup_file "$XRAY_CONFIG"
    
    jq --arg email "$username" \
        'del(.inbounds[] | select(.tag == ("vmess-" + $email)))' \
        "$XRAY_CONFIG" > "$temp_config"
    
    mv "$temp_config" "$XRAY_CONFIG"
}

renew_vmess_account() {
    print_box "Renew VMESS Account"
    list_vmess_accounts
    echo ""
    
    local username=$(read_input "Username to renew")
    local days=$(read_input "Additional days" "30")
    
    if ! grep -q "^vmess:$username:" "$USER_DB" 2>/dev/null; then
        print_error "User not found"
        press_enter
        return
    fi
    
    local current_exp=$(grep "^vmess:$username:" "$USER_DB" | cut -d: -f5)
    local new_exp=$(date -d "$current_exp +$days days" '+%Y-%m-%d')
    
    sed -i "s/^vmess:$username:\([^:]*\):\([^:]*\):[^:]*:/vmess:$username:\1:\2:$new_exp:/" "$USER_DB"
    
    print_success "Account renewed until: $new_exp"
    press_enter
}

list_vmess_accounts() {
    print_box "VMESS Accounts"
    
    if [ ! -f "$USER_DB" ] || ! grep -q "^vmess:" "$USER_DB" 2>/dev/null; then
        print_warning "No VMESS accounts found"
        return
    fi
    
    echo -e "${CYAN}┌─────────────┬──────────────┬──────────────┬────────┐${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Username${NC}    ${CYAN}│${NC} ${WHITE}Created${NC}      ${CYAN}│${NC} ${WHITE}Expires${NC}      ${CYAN}│${NC} ${WHITE}Status${NC} ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────┼──────────────┼──────────────┼────────┤${NC}"
    
    grep "^vmess:" "$USER_DB" 2>/dev/null | while IFS=: read -r proto user uuid created expires alterid traffic; do
        local status="${GREEN}Active${NC}"
        if ! check_expiry "$expires"; then
            status="${RED}Expired${NC}"
        fi
        
        printf "${CYAN}│${NC} %-11s ${CYAN}│${NC} %-12s ${CYAN}│${NC} %-12s ${CYAN}│${NC} %-6b ${CYAN}│${NC}\n" \
            "$user" "$created" "$expires" "$status"
    done
    
    echo -e "${CYAN}└─────────────┴──────────────┴──────────────┴────────┘${NC}"
}

show_vmess_config() {
    print_box "Show VMESS Configuration"
    
    local username=$(read_input "Username")
    
    if ! grep -q "^vmess:$username:" "$USER_DB" 2>/dev/null; then
        print_error "User not found"
        press_enter
        return
    fi
    
    local user_data=$(grep "^vmess:$username:" "$USER_DB")
    local uuid=$(echo "$user_data" | cut -d: -f3)
    local expires=$(echo "$user_data" | cut -d: -f5)
    local alterid=$(echo "$user_data" | cut -d: -f6)
    
    display_vmess_info "$username" "$uuid" "$alterid" "$expires"
    press_enter
}

# ============================================
# TROJAN Management
# ============================================

trojan_management_menu() {
    while true; do
        print_banner
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC}                  ${WHITE}${BOLD}TROJAN MANAGEMENT${NC}                    ${CYAN}║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${WHITE}[1]${NC} Create TROJAN Account"
        echo -e "${WHITE}[2]${NC} Delete TROJAN Account"
        echo -e "${WHITE}[3]${NC} Renew TROJAN Account"
        echo -e "${WHITE}[4]${NC} List TROJAN Accounts"
        echo -e "${WHITE}[5]${NC} Show TROJAN Config"
        echo -e "${WHITE}[0]${NC} Back to Main Menu"
        echo ""
        
        read -p "$(echo -e ${GREEN}Select option: ${NC})" trojan_choice
        
        case $trojan_choice in
            1) create_trojan_account ;;
            2) delete_trojan_account ;;
            3) renew_trojan_account ;;
            4) list_trojan_accounts ;;
            5) show_trojan_config ;;
            0) return ;;
            *) print_error "Invalid option" ; press_enter ;;
        esac
    done
}

create_trojan_account() {
    print_box "Create TROJAN Account"
    
    local username=$(read_input "Username" "user$(date +%s | tail -c 4)")
    local days=$(read_input "Validity (days)" "30")
    
    if ! validate_username "$username"; then
        print_error "Invalid username"
        press_enter
        return
    fi
    
    if grep -q "^trojan:$username:" "$USER_DB" 2>/dev/null; then
        print_error "User already exists"
        press_enter
        return
    fi
    
    local password=$(generate_random_string 16)
    local exp_date=$(calculate_expiry_date $days)
    local created_date=$(get_current_date)
    
    # Add inbound
    add_trojan_inbound "$username" "$password"
    
    # Save to database
    echo "trojan:$username:$password:$created_date:$exp_date:0" >> "$USER_DB"
    
    systemctl restart xray
    
    print_success "TROJAN Account Created!"
    echo ""
    display_trojan_info "$username" "$password" "$exp_date"
    
    press_enter
}

add_trojan_inbound() {
    local username=$1
    local password=$2
    local port=$(generate_random_port 10000 60000)
    
    backup_file "$XRAY_CONFIG"
    
    local temp_config=$(mktemp)
    jq --arg port "$port" --arg password "$password" --arg email "$username" \
        '.inbounds += [{
            "port": ($port | tonumber),
            "protocol": "trojan",
            "settings": {
                "clients": [{
                    "password": $password,
                    "email": $email
                }]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "none"
            },
            "tag": ("trojan-" + $email)
        }]' "$XRAY_CONFIG" > "$temp_config"
    
    mv "$temp_config" "$XRAY_CONFIG"
}

display_trojan_info() {
    local username=$1
    local password=$2
    local exp_date=$3
    local port=$(get_user_port "trojan" "$username")
    
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Protocol    :${NC} TROJAN"
    echo -e "${GREEN}Username    :${NC} $username"
    echo -e "${GREEN}Password    :${NC} $password"
    echo -e "${GREEN}Server      :${NC} $SERVER_IP"
    echo -e "${GREEN}Port        :${NC} ${port:-443}"
    echo -e "${GREEN}Expires     :${NC} $exp_date"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    local trojan_link="trojan://${password}@${SERVER_IP}:${port:-443}?security=none#${username}"
    
    echo -e "${YELLOW}Connection Link:${NC}"
    echo "$trojan_link"
    echo ""
    
    if command -v qrencode &>/dev/null; then
        echo "$trojan_link" | qrencode -t ANSIUTF8
        echo ""
    fi
}

delete_trojan_account() {
    print_box "Delete TROJAN Account"
    list_trojan_accounts
    echo ""
    
    local username=$(read_input "Username to delete")
    
    if ! grep -q "^trojan:$username:" "$USER_DB" 2>/dev/null; then
        print_error "User not found"
        press_enter
        return
    fi
    
    if confirm_action "Delete user $username?"; then
        sed -i "/^trojan:$username:/d" "$USER_DB"
        remove_trojan_inbound "$username"
        systemctl restart xray
        print_success "User deleted"
    fi
    
    press_enter
}

remove_trojan_inbound() {
    local username=$1
    local temp_config=$(mktemp)
    
    backup_file "$XRAY_CONFIG"
    
    jq --arg email "$username" \
        'del(.inbounds[] | select(.tag == ("trojan-" + $email)))' \
        "$XRAY_CONFIG" > "$temp_config"
    
    mv "$temp_config" "$XRAY_CONFIG"
}

renew_trojan_account() {
    print_box "Renew TROJAN Account"
    list_trojan_accounts
    echo ""
    
    local username=$(read_input "Username to renew")
    local days=$(read_input "Additional days" "30")
    
    if ! grep -q "^trojan:$username:" "$USER_DB" 2>/dev/null; then
        print_error "User not found"
        press_enter
        return
    fi
    
    local current_exp=$(grep "^trojan:$username:" "$USER_DB" | cut -d: -f5)
    local new_exp=$(date -d "$current_exp +$days days" '+%Y-%m-%d')
    
    sed -i "s/^trojan:$username:\([^:]*\):\([^:]*\):[^:]*:/trojan:$username:\1:\2:$new_exp:/" "$USER_DB"
    
    print_success "Account renewed until: $new_exp"
    press_enter
}

list_trojan_accounts() {
    print_box "TROJAN Accounts"
    
    if [ ! -f "$USER_DB" ] || ! grep -q "^trojan:" "$USER_DB" 2>/dev/null; then
        print_warning "No TROJAN accounts found"
        return
    fi
    
    echo -e "${CYAN}┌─────────────┬──────────────┬──────────────┬────────┐${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Username${NC}    ${CYAN}│${NC} ${WHITE}Created${NC}      ${CYAN}│${NC} ${WHITE}Expires${NC}      ${CYAN}│${NC} ${WHITE}Status${NC} ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────┼──────────────┼──────────────┼────────┤${NC}"
    
    grep "^trojan:" "$USER_DB" 2>/dev/null | while IFS=: read -r proto user password created expires traffic; do
        local status="${GREEN}Active${NC}"
        if ! check_expiry "$expires"; then
            status="${RED}Expired${NC}"
        fi
        
        printf "${CYAN}│${NC} %-11s ${CYAN}│${NC} %-12s ${CYAN}│${NC} %-12s ${CYAN}│${NC} %-6b ${CYAN}│${NC}\n" \
            "$user" "$created" "$expires" "$status"
    done
    
    echo -e "${CYAN}└─────────────┴──────────────┴──────────────┴────────┘${NC}"
}

show_trojan_config() {
    print_box "Show TROJAN Configuration"
    
    local username=$(read_input "Username")
    
    if ! grep -q "^trojan:$username:" "$USER_DB" 2>/dev/null; then
        print_error "User not found"
        press_enter
        return
    fi
    
    local user_data=$(grep "^trojan:$username:" "$USER_DB")
    local password=$(echo "$user_data" | cut -d: -f3)
    local expires=$(echo "$user_data" | cut -d: -f5)
    
    display_trojan_info "$username" "$password" "$expires"
    press_enter
}

# ============================================
# Helper Functions
# ============================================

get_user_port() {
    local protocol=$1
    local username=$2
    
    local tag="${protocol}-${username}"
    local port=$(jq -r ".inbounds[] | select(.tag == \"$tag\") | .port" "$XRAY_CONFIG" 2>/dev/null)
    
    echo "${port:-443}"
}
