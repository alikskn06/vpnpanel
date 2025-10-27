#!/bin/bash

# ============================================
# Monitoring & Bandwidth Tracking
# Version: 1.0.0
# ============================================

SCRIPT_DIR="/usr/local/vpnpanel/scripts"
source "${SCRIPT_DIR}/utils.sh" 2>/dev/null || source "$(dirname "$0")/utils.sh"

show_active_connections() {
    print_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}              ${WHITE}${BOLD}ACTIVE CONNECTIONS${NC}                       ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # SSH Connections
    local ssh_count=$(who | wc -l)
    echo -e "${GREEN}SSH Connections:${NC} $ssh_count"
    
    if [ $ssh_count -gt 0 ]; then
        echo ""
        echo -e "${CYAN}┌────────────────┬──────────────────┬─────────────────┐${NC}"
        echo -e "${CYAN}│${NC} ${WHITE}Username${NC}       ${CYAN}│${NC} ${WHITE}IP Address${NC}       ${CYAN}│${NC} ${WHITE}Login Time${NC}      ${CYAN}│${NC}"
        echo -e "${CYAN}├────────────────┼──────────────────┼─────────────────┤${NC}"
        
        who | while read user term date time ip; do
            printf "${CYAN}│${NC} %-14s ${CYAN}│${NC} %-16s ${CYAN}│${NC} %-15s ${CYAN}│${NC}\n" \
                "$user" "${ip//[()]/}" "$date $time"
        done
        
        echo -e "${CYAN}└────────────────┴──────────────────┴─────────────────┘${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}Xray Connections:${NC}"
    
    if systemctl is-active --quiet xray; then
        local xray_connections=$(ss -tunlp | grep xray | wc -l)
        echo -e "  Active: ${WHITE}$xray_connections${NC}"
    else
        echo -e "  Status: ${RED}Not Running${NC}"
    fi
    
    echo ""
    press_enter
}

show_bandwidth_usage() {
    print_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}               ${WHITE}${BOLD}BANDWIDTH USAGE${NC}                        ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    if command -v vnstat &>/dev/null; then
        # Today's usage
        local today=$(vnstat --oneline | cut -d';' -f4)
        echo -e "${GREEN}Today:${NC}     $today"
        
        # Yesterday's usage
        local yesterday=$(vnstat --oneline | cut -d';' -f5)
        echo -e "${GREEN}Yesterday:${NC} $yesterday"
        
        # Monthly usage
        local month=$(vnstat --oneline | cut -d';' -f11)
        echo -e "${GREEN}This Month:${NC} $month"
        
        echo ""
        echo -e "${CYAN}Detailed Statistics:${NC}"
        vnstat -d | tail -n 15
    else
        print_warning "vnstat not installed"
    fi
    
    echo ""
    press_enter
}

show_system_resources() {
    print_banner
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${NC}              ${WHITE}${BOLD}SYSTEM RESOURCES${NC}                        ${CYAN}║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # CPU Usage
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')
    echo -e "${GREEN}CPU Usage:${NC}    $cpu_usage"
    
    # Memory Usage
    local mem_total=$(free -h | awk '/^Mem:/ {print $2}')
    local mem_used=$(free -h | awk '/^Mem:/ {print $3}')
    local mem_free=$(free -h | awk '/^Mem:/ {print $4}')
    local mem_percent=$(free | awk '/^Mem:/ {printf "%.1f%%", $3/$2 * 100}')
    
    echo -e "${GREEN}Memory:${NC}       $mem_used / $mem_total ($mem_percent)"
    
    # Disk Usage
    local disk_used=$(df -h / | awk 'NR==2 {print $3}')
    local disk_total=$(df -h / | awk 'NR==2 {print $2}')
    local disk_percent=$(df -h / | awk 'NR==2 {print $5}')
    
    echo -e "${GREEN}Disk:${NC}         $disk_used / $disk_total ($disk_percent)"
    
    # Load Average
    local load=$(uptime | awk -F'load average:' '{print $2}')
    echo -e "${GREEN}Load Avg:${NC}    $load"
    
    # Uptime
    local uptime=$(uptime -p)
    echo -e "${GREEN}Uptime:${NC}       $uptime"
    
    echo ""
    press_enter
}
