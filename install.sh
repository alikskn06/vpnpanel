#!/bin/bash

# ============================================
# VPN Panel - One-Line Installer
# Version: 1.0.0
# ============================================

set -e

REPO_URL="https://raw.githubusercontent.com/alikskn06/vpnpanel/main"
INSTALL_DIR="/tmp/vpnpanel-install"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}           VPN Management Panel Installer             ${GREEN}║${NC}"
echo -e "${GREEN}║${NC}              Version 1.0.0                            ${GREEN}║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Error: Please run as root (use sudo)${NC}"
    exit 1
fi

# Check OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo -e "${RED}Error: Cannot detect OS${NC}"
    exit 1
fi

if [[ "$OS" != "ubuntu" && "$OS" != "debian" ]]; then
    echo -e "${RED}Error: Only Ubuntu/Debian supported${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/4]${NC} Creating temporary directory..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

echo -e "${YELLOW}[2/4]${NC} Downloading panel files..."

# Required files
FILES=(
    "utils.sh"
    "setup.sh"
    "menu.sh"
    "protocol-manager.sh"
    "ssh-manager.sh"
    "monitor.sh"
    "backup.sh"
    "domain-manager.sh"
)

for file in "${FILES[@]}"; do
    echo -e "  - Downloading $file..."
    if ! wget -q "$REPO_URL/$file" -O "$file"; then
        echo -e "${RED}Error: Failed to download $file${NC}"
        exit 1
    fi
    chmod +x "$file"
done

echo -e "${GREEN}✓${NC} All files downloaded"
echo ""

echo -e "${YELLOW}[3/4]${NC} Running setup script..."
echo ""

# Run setup
bash setup.sh

echo ""
echo -e "${YELLOW}[4/4]${NC} Cleaning up..."
cd /
rm -rf "$INSTALL_DIR"

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}            Installation Complete! ✓                   ${GREEN}║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}Start the panel:${NC}"
echo -e "  ${YELLOW}vpnpanel${NC}"
echo ""
echo -e "${GREEN}Or:${NC}"
echo -e "  ${YELLOW}/usr/local/vpnpanel/scripts/menu.sh${NC}"
echo ""
