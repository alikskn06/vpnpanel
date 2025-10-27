#!/bin/bash

# ============================================
# VPN Panel - Utility Functions
# Version: 1.0.0
# ============================================

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Background colors
BG_RED='\033[41m'
BG_GREEN='\033[42m'
BG_YELLOW='\033[43m'
BG_BLUE='\033[44m'

# Text styles
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'
BLINK='\033[5m'

# System paths
SCRIPT_DIR="/usr/local/vpnpanel"
CONFIG_DIR="${SCRIPT_DIR}/config"
BACKUP_DIR="${SCRIPT_DIR}/backup"
LOG_DIR="${SCRIPT_DIR}/logs"
DATA_DIR="${SCRIPT_DIR}/data"
XRAY_DIR="/usr/local/etc/xray"
XRAY_CONFIG="${XRAY_DIR}/config.json"

# Database files
USER_DB="${DATA_DIR}/users.db"
TRAFFIC_DB="${DATA_DIR}/traffic.db"
CONFIG_FILE="${CONFIG_DIR}/panel.conf"

# System info
SERVER_IP=$(curl -s4 ifconfig.me 2>/dev/null || wget -qO- ifconfig.me 2>/dev/null || echo "Unknown")
KERNEL_VERSION=$(uname -r)
OS_VERSION=$(lsb_release -ds 2>/dev/null || cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)

# ============================================
# Display Functions
# ============================================

print_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║           █▀▀ █░█ █▀█ █▀▀ █▀█   █▀█ ▄▀█ █▄░█ █▀▀ █░░   ║
║           ▄▄█ █▄█ █▀▀ ██▄ █▀▄   █▀▀ █▀█ █░▀█ ██▄ █▄▄   ║
║                                                          ║
║              Professional VPN Management Panel          ║
║                     Version 1.0.0                       ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_separator() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_box() {
    local text="$1"
    local length=${#text}
    local border=$(printf '═%.0s' $(seq 1 $((length + 4))))
    
    echo -e "${CYAN}╔${border}╗"
    echo -e "║  ${WHITE}${text}${CYAN}  ║"
    echo -e "╚${border}╝${NC}"
}

# ============================================
# System Functions
# ============================================

check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root!"
        exit 1
    fi
}

check_os() {
    if [[ -f /etc/debian_version ]]; then
        OS="debian"
        print_success "Detected: Debian/Ubuntu"
    elif [[ -f /etc/redhat-release ]]; then
        OS="centos"
        print_success "Detected: CentOS/RHEL"
    else
        print_error "Unsupported operating system!"
        exit 1
    fi
}

check_internet() {
    print_info "Checking internet connection..."
    if ping -c 1 google.com &>/dev/null || ping -c 1 8.8.8.8 &>/dev/null; then
        print_success "Internet connection: OK"
        return 0
    else
        print_error "No internet connection detected!"
        return 1
    fi
}

get_system_info() {
    echo -e "${CYAN}═══════════════════ SYSTEM INFORMATION ═══════════════════${NC}"
    echo -e "${GREEN}Server IP      :${NC} ${SERVER_IP}"
    echo -e "${GREEN}OS Version     :${NC} ${OS_VERSION}"
    echo -e "${GREEN}Kernel         :${NC} ${KERNEL_VERSION}"
    echo -e "${GREEN}CPU Cores      :${NC} $(nproc)"
    echo -e "${GREEN}Total RAM      :${NC} $(free -h | awk '/^Mem:/ {print $2}')"
    echo -e "${GREEN}Free RAM       :${NC} $(free -h | awk '/^Mem:/ {print $4}')"
    echo -e "${GREEN}Disk Usage     :${NC} $(df -h / | awk 'NR==2 {print $5}')"
    echo -e "${GREEN}Uptime         :${NC} $(uptime -p)"
    print_separator
}

# ============================================
# Validation Functions
# ============================================

validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_domain() {
    local domain=$1
    if [[ $domain =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_port() {
    local port=$1
    if [[ $port =~ ^[0-9]+$ ]] && [ $port -ge 1 ] && [ $port -le 65535 ]; then
        return 0
    else
        return 1
    fi
}

validate_email() {
    local email=$1
    if [[ $email =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 0
    else
        return 1
    fi
}

validate_username() {
    local username=$1
    if [[ $username =~ ^[a-zA-Z0-9_-]{3,32}$ ]]; then
        return 0
    else
        return 1
    fi
}

# ============================================
# User Input Functions
# ============================================

read_input() {
    local prompt="$1"
    local default="$2"
    local input
    
    if [ -n "$default" ]; then
        read -p "$(echo -e ${GREEN}${prompt}${NC} [${YELLOW}${default}${NC}]: )" input
        echo "${input:-$default}"
    else
        read -p "$(echo -e ${GREEN}${prompt}${NC}: )" input
        echo "$input"
    fi
}

read_password() {
    local prompt="$1"
    local password
    read -sp "$(echo -e ${GREEN}${prompt}${NC}: )" password
    echo ""
    echo "$password"
}

confirm_action() {
    local prompt="$1"
    local response
    read -p "$(echo -e ${YELLOW}${prompt}${NC} [y/N]: )" response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# ============================================
# File Operations
# ============================================

create_directories() {
    print_info "Creating necessary directories..."
    mkdir -p "$SCRIPT_DIR" "$CONFIG_DIR" "$BACKUP_DIR" "$LOG_DIR" "$DATA_DIR" "$XRAY_DIR"
    print_success "Directories created successfully"
}

backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        local backup="${BACKUP_DIR}/$(basename $file).$(date +%Y%m%d_%H%M%S).bak"
        cp "$file" "$backup"
        print_success "Backup created: $backup"
    fi
}

# ============================================
# UUID Generation
# ============================================

generate_uuid() {
    cat /proc/sys/kernel/random/uuid
}

# ============================================
# Date/Time Functions
# ============================================

get_current_date() {
    date '+%Y-%m-%d'
}

get_current_time() {
    date '+%H:%M:%S'
}

get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

get_unix_timestamp() {
    date +%s
}

calculate_expiry_date() {
    local days=$1
    date -d "+${days} days" '+%Y-%m-%d'
}

check_expiry() {
    local expiry_date=$1
    local current_date=$(get_current_date)
    
    if [[ "$current_date" > "$expiry_date" ]]; then
        return 1  # Expired
    else
        return 0  # Valid
    fi
}

days_until_expiry() {
    local expiry_date=$1
    local current_timestamp=$(date +%s)
    local expiry_timestamp=$(date -d "$expiry_date" +%s)
    local diff=$((expiry_timestamp - current_timestamp))
    echo $((diff / 86400))
}

# ============================================
# Traffic Functions
# ============================================

bytes_to_human() {
    local bytes=$1
    if [ $bytes -lt 1024 ]; then
        echo "${bytes} B"
    elif [ $bytes -lt 1048576 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", ${bytes}/1024}") KB"
    elif [ $bytes -lt 1073741824 ]; then
        echo "$(awk "BEGIN {printf \"%.2f\", ${bytes}/1048576}") MB"
    else
        echo "$(awk "BEGIN {printf \"%.2f\", ${bytes}/1073741824}") GB"
    fi
}

# ============================================
# Loading Animation
# ============================================

show_loading() {
    local pid=$1
    local delay=0.1
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [${CYAN}%c${NC}]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# ============================================
# Progress Bar
# ============================================

progress_bar() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\r${GREEN}Progress: ["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] ${percentage}%%${NC}"
    
    if [ $current -eq $total ]; then
        echo ""
    fi
}

# ============================================
# Menu Functions
# ============================================

press_enter() {
    echo ""
    read -p "$(echo -e ${CYAN}Press Enter to continue...${NC})"
}

countdown() {
    local seconds=$1
    local message=${2:-"Continuing in"}
    
    for ((i=seconds; i>0; i--)); do
        echo -ne "\r${YELLOW}${message} ${i} seconds...${NC}"
        sleep 1
    done
    echo ""
}

# ============================================
# Log Functions
# ============================================

log_action() {
    local message="$1"
    local log_file="${LOG_DIR}/panel.log"
    echo "[$(get_timestamp)] $message" >> "$log_file"
}

log_error() {
    local message="$1"
    local log_file="${LOG_DIR}/error.log"
    echo "[$(get_timestamp)] ERROR: $message" >> "$log_file"
}

# ============================================
# Service Management
# ============================================

restart_service() {
    local service=$1
    print_info "Restarting $service..."
    systemctl restart "$service"
    if [ $? -eq 0 ]; then
        print_success "$service restarted successfully"
    else
        print_error "Failed to restart $service"
    fi
}

check_service_status() {
    local service=$1
    if systemctl is-active --quiet "$service"; then
        echo -e "${GREEN}●${NC} Running"
    else
        echo -e "${RED}●${NC} Stopped"
    fi
}

# ============================================
# Random Generation
# ============================================

generate_random_string() {
    local length=${1:-16}
    cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w $length | head -n 1
}

generate_random_port() {
    local min=${1:-10000}
    local max=${2:-60000}
    shuf -i $min-$max -n 1
}

# ============================================
# Network Functions
# ============================================

check_port_available() {
    local port=$1
    if netstat -tuln | grep -q ":$port "; then
        return 1  # Port in use
    else
        return 0  # Port available
    fi
}

get_public_ip() {
    curl -s4 ifconfig.me 2>/dev/null || wget -qO- ifconfig.me 2>/dev/null || echo "Unknown"
}

# ============================================
# Initialization
# ============================================

init_utils() {
    check_root
    create_directories
    log_action "Utilities initialized"
}

# Export all functions
export -f print_banner print_info print_success print_error print_warning
export -f print_separator print_box check_root check_os check_internet
export -f get_system_info validate_ip validate_domain validate_port
export -f validate_email validate_username read_input read_password
export -f confirm_action create_directories backup_file generate_uuid
export -f get_current_date get_current_time get_timestamp
export -f bytes_to_human show_loading progress_bar press_enter
export -f log_action log_error restart_service check_service_status
export -f generate_random_string generate_random_port check_port_available
