#!/bin/bash

# ============================================
# SSH User Management
# Version: 1.0.0
# ============================================

SCRIPT_DIR="/usr/local/vpnpanel/scripts"
source "${SCRIPT_DIR}/utils.sh" 2>/dev/null || source "$(dirname "$0")/utils.sh"

USER_DB="/usr/local/vpnpanel/data/users.db"

ssh_management_menu() {
    while true; do
        print_banner
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC}                   ${WHITE}${BOLD}SSH MANAGEMENT${NC}                      ${CYAN}║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${WHITE}[1]${NC} Create SSH Account"
        echo -e "${WHITE}[2]${NC} Delete SSH Account"
        echo -e "${WHITE}[3]${NC} Renew SSH Account"
        echo -e "${WHITE}[4]${NC} List SSH Accounts"
        echo -e "${WHITE}[5]${NC} Change Password"
        echo -e "${WHITE}[6]${NC} Show SSH Info"
        echo -e "${WHITE}[7]${NC} Lock User"
        echo -e "${WHITE}[8]${NC} Unlock User"
        echo -e "${WHITE}[0]${NC} Back to Main Menu"
        echo ""
        
        read -p "$(echo -e ${GREEN}Select option: ${NC})" ssh_choice
        
        case $ssh_choice in
            1) create_ssh_account ;;
            2) delete_ssh_account ;;
            3) renew_ssh_account ;;
            4) list_ssh_accounts ;;
            5) change_ssh_password ;;
            6) show_ssh_info ;;
            7) lock_ssh_user ;;
            8) unlock_ssh_user ;;
            0) return ;;
            *) print_error "Invalid option" ; press_enter ;;
        esac
    done
}

create_ssh_account() {
    print_box "Create SSH Account"
    
    local username=$(read_input "Username" "user$(date +%s | tail -c 4)")
    local password=$(read_input "Password" "$(generate_random_string 12)")
    local days=$(read_input "Validity (days)" "30")
    
    if ! validate_username "$username"; then
        print_error "Invalid username"
        press_enter
        return
    fi
    
    if id "$username" &>/dev/null; then
        print_error "User already exists"
        press_enter
        return
    fi
    
    local exp_date=$(calculate_expiry_date $days)
    local created_date=$(get_current_date)
    
    # Create user
    useradd -e $(date -d "$exp_date" "+%Y-%m-%d") -s /bin/false -M "$username" 2>/dev/null
    echo "$username:$password" | chpasswd
    
    # Save to database
    echo "ssh:$username:$password:$created_date:$exp_date:0" >> "$USER_DB"
    
    print_success "SSH Account Created!"
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Username    :${NC} $username"
    echo -e "${GREEN}Password    :${NC} $password"
    echo -e "${GREEN}Server      :${NC} $SERVER_IP"
    echo -e "${GREEN}Port        :${NC} 22"
    echo -e "${GREEN}Expires     :${NC} $exp_date"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}SSH Command:${NC}"
    echo "ssh $username@$SERVER_IP"
    echo ""
    
    press_enter
}

delete_ssh_account() {
    print_box "Delete SSH Account"
    list_ssh_accounts
    echo ""
    
    local username=$(read_input "Username to delete")
    
    if ! id "$username" &>/dev/null; then
        print_error "User not found"
        press_enter
        return
    fi
    
    if confirm_action "Delete user $username?"; then
        userdel -f "$username" 2>/dev/null
        sed -i "/^ssh:$username:/d" "$USER_DB"
        print_success "User deleted"
    fi
    
    press_enter
}

renew_ssh_account() {
    print_box "Renew SSH Account"
    list_ssh_accounts
    echo ""
    
    local username=$(read_input "Username to renew")
    local days=$(read_input "Additional days" "30")
    
    if ! id "$username" &>/dev/null; then
        print_error "User not found"
        press_enter
        return
    fi
    
    local current_exp=$(grep "^ssh:$username:" "$USER_DB" | cut -d: -f5)
    local new_exp=$(date -d "$current_exp +$days days" '+%Y-%m-%d')
    
    # Update system expiry
    chage -E $(date -d "$new_exp" "+%Y-%m-%d") "$username"
    
    # Update database
    sed -i "s/^ssh:$username:\([^:]*\):\([^:]*\):[^:]*:/ssh:$username:\1:\2:$new_exp:/" "$USER_DB"
    
    print_success "Account renewed until: $new_exp"
    press_enter
}

list_ssh_accounts() {
    print_box "SSH Accounts"
    
    if [ ! -f "$USER_DB" ] || ! grep -q "^ssh:" "$USER_DB" 2>/dev/null; then
        print_warning "No SSH accounts found"
        return
    fi
    
    echo -e "${CYAN}┌──────────────┬──────────────┬──────────────┬─────────┐${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Username${NC}     ${CYAN}│${NC} ${WHITE}Created${NC}      ${CYAN}│${NC} ${WHITE}Expires${NC}      ${CYAN}│${NC} ${WHITE}Status${NC}  ${CYAN}│${NC}"
    echo -e "${CYAN}├──────────────┼──────────────┼──────────────┼─────────┤${NC}"
    
    grep "^ssh:" "$USER_DB" 2>/dev/null | while IFS=: read -r proto user pass created expires traffic; do
        local status="${GREEN}Active${NC}"
        if ! check_expiry "$expires"; then
            status="${RED}Expired${NC}"
        fi
        
        if passwd -S "$user" 2>/dev/null | grep -q "L"; then
            status="${YELLOW}Locked${NC}"
        fi
        
        printf "${CYAN}│${NC} %-12s ${CYAN}│${NC} %-12s ${CYAN}│${NC} %-12s ${CYAN}│${NC} %-7b ${CYAN}│${NC}\n" \
            "$user" "$created" "$expires" "$status"
    done
    
    echo -e "${CYAN}└──────────────┴──────────────┴──────────────┴─────────┘${NC}"
}

change_ssh_password() {
    print_box "Change SSH Password"
    list_ssh_accounts
    echo ""
    
    local username=$(read_input "Username")
    local new_password=$(read_input "New Password" "$(generate_random_string 12)")
    
    if ! id "$username" &>/dev/null; then
        print_error "User not found"
        press_enter
        return
    fi
    
    echo "$username:$new_password" | chpasswd
    
    # Update database
    sed -i "s/^ssh:$username:[^:]*:/ssh:$username:$new_password:/" "$USER_DB"
    
    print_success "Password changed successfully"
    echo -e "${GREEN}New Password:${NC} $new_password"
    
    press_enter
}

show_ssh_info() {
    print_box "Show SSH Information"
    
    local username=$(read_input "Username")
    
    if ! grep -q "^ssh:$username:" "$USER_DB" 2>/dev/null; then
        print_error "User not found"
        press_enter
        return
    fi
    
    local user_data=$(grep "^ssh:$username:" "$USER_DB")
    local password=$(echo "$user_data" | cut -d: -f3)
    local created=$(echo "$user_data" | cut -d: -f4)
    local expires=$(echo "$user_data" | cut -d: -f5)
    
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Username    :${NC} $username"
    echo -e "${GREEN}Password    :${NC} $password"
    echo -e "${GREEN}Server      :${NC} $SERVER_IP"
    echo -e "${GREEN}Port        :${NC} 22"
    echo -e "${GREEN}Created     :${NC} $created"
    echo -e "${GREEN}Expires     :${NC} $expires"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${YELLOW}SSH Command:${NC}"
    echo "ssh $username@$SERVER_IP"
    echo ""
    
    press_enter
}

lock_ssh_user() {
    print_box "Lock SSH User"
    list_ssh_accounts
    echo ""
    
    local username=$(read_input "Username to lock")
    
    if ! id "$username" &>/dev/null; then
        print_error "User not found"
        press_enter
        return
    fi
    
    passwd -l "$username" >/dev/null 2>&1
    print_success "User $username locked"
    
    press_enter
}

unlock_ssh_user() {
    print_box "Unlock SSH User"
    list_ssh_accounts
    echo ""
    
    local username=$(read_input "Username to unlock")
    
    if ! id "$username" &>/dev/null; then
        print_error "User not found"
        press_enter
        return
    fi
    
    passwd -u "$username" >/dev/null 2>&1
    print_success "User $username unlocked"
    
    press_enter
}
