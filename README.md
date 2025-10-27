# VPN Management Panel

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)
![Shell](https://img.shields.io/badge/shell-bash-green.svg)

A comprehensive, open-source VPN management panel supporting **VLESS**, **VMESS**, **Trojan**, and **SSH** protocols with full monitoring and backup capabilities.

---

## ✨ Features

### 🔐 Protocol Support
- **VLESS** (TCP, WebSocket, gRPC, HTTPUpgrade)
- **VMESS** (TCP, WebSocket, gRPC, HTTPUpgrade)
- **Trojan** (TCP, WebSocket, gRPC)
- **SSH** User Management

### 🎯 Management Features
- ✅ User creation, deletion, and renewal
- ✅ Real-time traffic monitoring (vnstat)
- ✅ Domain and SSL certificate management (Let's Encrypt)
- ✅ Automated backups with retention policies
- ✅ System resource monitoring (CPU, RAM, Disk)
- ✅ QR code generation for mobile clients
- ✅ Connection string generation
- ✅ Active connection monitoring

### 🔒 Security Features
- ✅ SSL/TLS support with automatic renewal
- ✅ UUID-based authentication
- ✅ AES-128-GCM traffic encryption
- ✅ User account locking/unlocking
- ✅ Automatic firewall configuration (UFW)
- ✅ Secure password generation

---

## 📦 System Requirements

| Component | Requirement |
|-----------|------------|
| **OS** | Ubuntu 20.04+ / Debian 10+ |
| **RAM** | Minimum 1GB (2GB recommended) |
| **Storage** | 10GB free space |
| **Network** | Public IP address |
| **Ports** | 80, 443, 22 (open) |
| **Access** | Root privileges |

---

## 🚀 Quick Installation

### One-Line Installation

```bash
wget https://raw.githubusercontent.com/alikskn06/vpnpanel/main/setup.sh && chmod +x setup.sh && sudo ./setup.sh
```

### Manual Installation

```bash
# Clone the repository
git clone https://github.com/alikskn06/vpnpanel.git
cd vpnpanel

# Make scripts executable
chmod +x *.sh

# Run setup
sudo ./setup.sh
```

### Installation Time
⏱️ Approximately **5-10 minutes**

---

## 🎯 Quick Start

After installation:

```bash
# Start the panel
vpnpanel

# Or directly
/usr/local/vpnpanel/scripts/menu.sh
```

### First Steps

1. **Configure Domain** (optional but recommended)
   - Menu: `[4] Domain & SSL Management`
   - Add your domain and install SSL certificate

2. **Create First User**
   - Menu: `[1] Protocol Management`
   - Choose protocol (VLESS recommended)
   - Enter username and duration

3. **Share Connection**
   - Copy connection string or scan QR code
   - Import to client app (v2rayNG, Shadowrocket, etc.)

---

## 📖 Main Menu

```
╔══════════════════════════════════════════════════════════╗
║              VPN MANAGEMENT PANEL v1.0                   ║
║              Server IP: xxx.xxx.xxx.xxx                  ║
╚══════════════════════════════════════════════════════════╝

[1] Protocol Management (VLESS/VMESS/Trojan)
[2] SSH Management
[3] Monitoring & Statistics
[4] Domain & SSL Management
[5] Backup & Restore
[6] System Settings
[0] Exit
```

---

## 📱 Client Applications

### Android
- [v2rayNG](https://github.com/2dust/v2rayNG/releases) (Recommended)
- [Hiddify Next](https://github.com/hiddify/hiddify-next)

### iOS
- Shadowrocket (App Store - $2.99)
- Streisand (Free)

### Windows
- [v2rayN](https://github.com/2dust/v2rayN/releases)
- [Hiddify](https://github.com/hiddify/hiddify-next)

### macOS
- V2Box (App Store)
- Qv2ray

### Linux
- [Nekoray](https://github.com/MatsuriDayo/nekoray)
- v2rayA

---

## 📁 Project Structure

```
vpnpanel/
├── setup.sh                 # Main installation script
├── menu.sh                  # Main menu interface
├── utils.sh                 # Utility functions
├── protocol-manager.sh      # VLESS/VMESS/Trojan management
├── ssh-manager.sh           # SSH user management
├── monitor.sh               # System monitoring
├── backup.sh                # Backup/restore module
├── domain-manager.sh        # Domain/SSL management
├── USAGE_GUIDE.md          # Detailed usage guide
└── README.md               # This file
```

---

## 🔧 Usage Examples

### Creating a VLESS User

```bash
# Start panel
vpnpanel

# Select: [1] Protocol Management
# Select: [1] VLESS Protocol
# Select: [1] Create VLESS User
# Enter username: john
# Enter duration: 30 (days)
# Choose transport: [1] TCP

# QR code and connection string generated automatically
```

### Domain & SSL Setup

```bash
# 1. Point your domain A record to server IP
# 2. In panel: [4] Domain & SSL Management
# 3. [1] Add/Change Domain
# 4. Enter domain: vpn.yourdomain.com
# 5. [2] Install SSL Certificate
# 6. Enter email for notifications

# SSL auto-renews every 60 days
```

### Monitoring

```bash
# Real-time stats
# [3] Monitoring & Statistics

# View:
# - Active SSH/Xray connections
# - Bandwidth usage (daily/monthly)
# - System resources (CPU, RAM, Disk)
```

---

## 🔒 Security Best Practices

1. **Change Default SSH Port**
   ```bash
   nano /etc/ssh/sshd_config
   # Port 2222
   systemctl restart sshd
   ```

2. **Enable Fail2Ban**
   ```bash
   apt install fail2ban -y
   systemctl enable fail2ban
   ```

3. **Regular Backups**
   - Automated daily backups at 2 AM
   - Keep backups on external storage
   - Test restore procedures monthly

4. **Monitor Logs**
   ```bash
   tail -f /usr/local/vpnpanel/logs/panel.log
   ```

5. **Update Regularly**
   ```bash
   apt update && apt upgrade -y
   ```

---

## 🐛 Troubleshooting

### Panel Not Starting

```bash
# Check installation
ls -la /usr/local/vpnpanel/scripts/

# Re-run setup
sudo ./setup.sh
```

### Connection Issues

```bash
# Check services
systemctl status xray nginx

# Check firewall
ufw status

# View logs
tail -f /usr/local/vpnpanel/logs/xray_error.log
```

### SSL Certificate Problems

```bash
# Check DNS
dig +short yourdomain.com

# Manual renewal
certbot renew --force-renewal
systemctl restart nginx xray
```

**📖 For detailed troubleshooting, see [USAGE_GUIDE.md](USAGE_GUIDE.md)**

---

## 📊 Configuration Files

| File | Location |
|------|----------|
| Panel Config | `/usr/local/vpnpanel/config/panel.conf` |
| Xray Config | `/usr/local/vpnpanel/config/xray_config.json` |
| User Database | `/usr/local/vpnpanel/data/users.db` |
| SSH Users | `/usr/local/vpnpanel/data/ssh_users.db` |
| Logs | `/usr/local/vpnpanel/logs/` |
| Backups | `/usr/local/vpnpanel/backups/` |

---

## 🗑️ Uninstallation

```bash
# Stop services
systemctl stop xray nginx

# Remove panel
rm -rf /usr/local/vpnpanel

# Remove Xray
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh) remove --purge

# Remove alias
sed -i '/vpnpanel/d' ~/.bashrc
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## ⚠️ Disclaimer

This software is provided for **educational and legitimate use only**. Users are responsible for complying with local laws and regulations regarding VPN usage. The developers assume no liability for misuse.

---

## 🌟 Credits

Built with:
- [Xray-core](https://github.com/XTLS/Xray-core) - Core proxy engine
- [Nginx](https://nginx.org/) - Web server
- [Certbot](https://certbot.eff.org/) - SSL certificates
- [vnstat](https://humdi.net/vnstat/) - Bandwidth monitoring

---

## 📊 Version

- **Version**: 1.0.0
- **Last Updated**: December 2024
- **Compatibility**: Ubuntu 20.04+, Debian 10+
- **Xray Version**: Latest stable

---

## 📞 Support

- **Documentation**: [USAGE_GUIDE.md](USAGE_GUIDE.md)
- **Issues**: [GitHub Issues](https://github.com/alikskn06/vpnpanel/issues)
- **Repository**: [GitHub](https://github.com/alikskn06/vpnpanel)

---

## ⭐ Star History

If you find this project useful, please consider giving it a star! ⭐

---

**Made with ❤️ for a free and open internet**

