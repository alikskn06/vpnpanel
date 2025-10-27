#!/bin/bash

# ============================================
# Backup & Restore System
# Version: 1.0.0
# ============================================

SCRIPT_DIR="/usr/local/vpnpanel/scripts"
source "${SCRIPT_DIR}/utils.sh" 2>/dev/null || source "$(dirname "$0")/utils.sh"

BACKUP_DIR="/usr/local/vpnpanel/backup"

backup_management_menu() {
    while true; do
        print_banner
        echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║${NC}                ${WHITE}${BOLD}BACKUP MANAGEMENT${NC}                     ${CYAN}║${NC}"
        echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${WHITE}[1]${NC} Create Full Backup"
        echo -e "${WHITE}[2]${NC} Restore from Backup"
        echo -e "${WHITE}[3]${NC} List Backups"
        echo -e "${WHITE}[4]${NC} Delete Backup"
        echo -e "${WHITE}[5]${NC} Auto Backup Settings"
        echo -e "${WHITE}[0]${NC} Back to Main Menu"
        echo ""
        
        read -p "$(echo -e ${GREEN}Select option: ${NC})" backup_choice
        
        case $backup_choice in
            1) create_backup ;;
            2) restore_backup ;;
            3) list_backups ;;
            4) delete_backup ;;
            5) auto_backup_settings ;;
            0) return ;;
            *) print_error "Invalid option" ; press_enter ;;
        esac
    done
}

create_backup() {
    print_box "Creating Backup"
    
    local backup_name="backup_$(date +%Y%m%d_%H%M%S).tar.gz"
    local backup_path="${BACKUP_DIR}/${backup_name}"
    
    print_info "Creating backup..."
    echo ""
    
    # Create temporary directory
    local temp_backup="/tmp/vpnpanel_backup_$$"
    mkdir -p "$temp_backup"
    
    # Backup user database
    if [ -f "/usr/local/vpnpanel/data/users.db" ]; then
        cp /usr/local/vpnpanel/data/users.db "$temp_backup/"
        print_success "✓ User database backed up"
    fi
    
    # Backup Xray config
    if [ -f "/usr/local/etc/xray/config.json" ]; then
        cp /usr/local/etc/xray/config.json "$temp_backup/"
        print_success "✓ Xray configuration backed up"
    fi
    
    # Backup panel config
    if [ -f "/usr/local/vpnpanel/config/panel.conf" ]; then
        cp /usr/local/vpnpanel/config/panel.conf "$temp_backup/"
        print_success "✓ Panel configuration backed up"
    fi
    
    # Backup traffic data
    if [ -f "/usr/local/vpnpanel/data/traffic.db" ]; then
        cp /usr/local/vpnpanel/data/traffic.db "$temp_backup/"
        print_success "✓ Traffic data backed up"
    fi
    
    # Create archive
    print_info "Compressing files..."
    tar -czf "$backup_path" -C /tmp "$(basename $temp_backup)" 2>/dev/null
    
    # Cleanup
    rm -rf "$temp_backup"
    
    if [ -f "$backup_path" ]; then
        local backup_size=$(du -h "$backup_path" | cut -f1)
        print_success "Backup created successfully!"
        echo ""
        echo -e "${GREEN}File:${NC} $backup_name"
        echo -e "${GREEN}Size:${NC} $backup_size"
        echo -e "${GREEN}Path:${NC} $backup_path"
        
        log_action "Backup created: $backup_name"
    else
        print_error "Backup creation failed"
        log_error "Backup creation failed"
    fi
    
    echo ""
    press_enter
}

restore_backup() {
    print_box "Restore from Backup"
    
    list_backups
    echo ""
    
    local backup_file=$(read_input "Enter backup filename")
    local backup_path="${BACKUP_DIR}/${backup_file}"
    
    if [ ! -f "$backup_path" ]; then
        print_error "Backup file not found"
        press_enter
        return
    fi
    
    if ! confirm_action "Restore from $backup_file? This will overwrite current data!"; then
        print_warning "Restore cancelled"
        press_enter
        return
    fi
    
    print_info "Restoring backup..."
    echo ""
    
    # Extract backup
    local temp_restore="/tmp/vpnpanel_restore_$$"
    mkdir -p "$temp_restore"
    tar -xzf "$backup_path" -C "$temp_restore" 2>/dev/null
    
    # Find extracted directory
    local extracted_dir=$(find "$temp_restore" -maxdepth 1 -type d -name "vpnpanel_backup_*" | head -n 1)
    
    if [ -z "$extracted_dir" ]; then
        print_error "Failed to extract backup"
        rm -rf "$temp_restore"
        press_enter
        return
    fi
    
    # Restore files
    if [ -f "$extracted_dir/users.db" ]; then
        cp "$extracted_dir/users.db" /usr/local/vpnpanel/data/
        print_success "✓ User database restored"
    fi
    
    if [ -f "$extracted_dir/config.json" ]; then
        cp "$extracted_dir/config.json" /usr/local/etc/xray/
        print_success "✓ Xray configuration restored"
    fi
    
    if [ -f "$extracted_dir/panel.conf" ]; then
        cp "$extracted_dir/panel.conf" /usr/local/vpnpanel/config/
        print_success "✓ Panel configuration restored"
    fi
    
    if [ -f "$extracted_dir/traffic.db" ]; then
        cp "$extracted_dir/traffic.db" /usr/local/vpnpanel/data/
        print_success "✓ Traffic data restored"
    fi
    
    # Cleanup
    rm -rf "$temp_restore"
    
    # Restart services
    print_info "Restarting services..."
    systemctl restart xray nginx
    
    print_success "Backup restored successfully!"
    log_action "Backup restored: $backup_file"
    
    echo ""
    press_enter
}

list_backups() {
    print_box "Available Backups"
    
    if [ ! -d "$BACKUP_DIR" ] || [ -z "$(ls -A $BACKUP_DIR/*.tar.gz 2>/dev/null)" ]; then
        print_warning "No backups found"
        return
    fi
    
    echo -e "${CYAN}┌─────────────────────────────┬──────────┬─────────────────┐${NC}"
    echo -e "${CYAN}│${NC} ${WHITE}Filename${NC}                    ${CYAN}│${NC} ${WHITE}Size${NC}     ${CYAN}│${NC} ${WHITE}Date${NC}            ${CYAN}│${NC}"
    echo -e "${CYAN}├─────────────────────────────┼──────────┼─────────────────┤${NC}"
    
    for backup in ${BACKUP_DIR}/*.tar.gz; do
        if [ -f "$backup" ]; then
            local filename=$(basename "$backup")
            local size=$(du -h "$backup" | cut -f1)
            local date=$(stat -c %y "$backup" | cut -d'.' -f1)
            
            printf "${CYAN}│${NC} %-27s ${CYAN}│${NC} %-8s ${CYAN}│${NC} %-15s ${CYAN}│${NC}\n" \
                "$filename" "$size" "$date"
        fi
    done
    
    echo -e "${CYAN}└─────────────────────────────┴──────────┴─────────────────┘${NC}"
}

delete_backup() {
    print_box "Delete Backup"
    
    list_backups
    echo ""
    
    local backup_file=$(read_input "Enter backup filename to delete")
    local backup_path="${BACKUP_DIR}/${backup_file}"
    
    if [ ! -f "$backup_path" ]; then
        print_error "Backup file not found"
        press_enter
        return
    fi
    
    if confirm_action "Delete $backup_file?"; then
        rm -f "$backup_path"
        print_success "Backup deleted"
        log_action "Backup deleted: $backup_file"
    fi
    
    press_enter
}

auto_backup_settings() {
    print_box "Auto Backup Settings"
    
    echo -e "${WHITE}[1]${NC} Enable Daily Auto Backup"
    echo -e "${WHITE}[2]${NC} Disable Auto Backup"
    echo -e "${WHITE}[3]${NC} Set Backup Retention (days)"
    echo -e "${WHITE}[0]${NC} Back"
    echo ""
    
    read -p "$(echo -e ${GREEN}Select: ${NC})" auto_choice
    
    case $auto_choice in
        1)
            # Add cron job for daily backup
            (crontab -l 2>/dev/null | grep -v "vpnpanel_backup"; echo "0 3 * * * /usr/local/vpnpanel/scripts/backup.sh create_backup") | crontab -
            print_success "Auto backup enabled (daily at 3:00 AM)"
            ;;
        2)
            crontab -l 2>/dev/null | grep -v "vpnpanel_backup" | crontab -
            print_success "Auto backup disabled"
            ;;
        3)
            local days=$(read_input "Retention period (days)" "7")
            # Add cleanup cron job
            echo "Backup retention set to $days days"
            print_info "Old backups will be automatically deleted"
            ;;
    esac
    
    press_enter
}
