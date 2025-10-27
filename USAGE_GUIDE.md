# VPN Management Panel - Complete Usage Guide

A comprehensive, open-source VPN management panel supporting VLESS, VMESS, Trojan, and SSH protocols with full monitoring and backup capabilities.

## 📋 Table of Contents

- [Features](#features)
- [System Requirements](#system-requirements)
- [Installation](#installation)
- [First-Time Setup](#first-time-setup)
- [Usage Guide](#usage-guide)
- [Configuration Files](#configuration-files)
- [Client Setup](#client-setup)
- [Troubleshooting](#troubleshooting)
- [Security Best Practices](#security-best-practices)
- [Advanced Configuration](#advanced-configuration)

---

## ✨ Features

### Protocol Support
- ✅ **VLESS** (TCP, WebSocket, gRPC, HTTPUpgrade)
- ✅ **VMESS** (TCP, WebSocket, gRPC, HTTPUpgrade)
- ✅ **Trojan** (TCP, WebSocket, gRPC)
- ✅ **SSH** User Management

### Management Features
- ✅ User creation, deletion, renewal
- ✅ Traffic monitoring and bandwidth tracking
- ✅ Domain and SSL certificate management (Let's Encrypt)
- ✅ Automated backups with retention policies
- ✅ System resource monitoring
- ✅ QR code generation for mobile clients
- ✅ Connection string generation
- ✅ Real-time connection monitoring

### Security Features
- ✅ SSL/TLS support with automatic renewal
- ✅ UUID-based authentication
- ✅ Traffic encryption (AES-128-GCM)
- ✅ User account locking/unlocking
- ✅ Firewall auto-configuration
- ✅ Secure password generation

---

## 📦 System Requirements

| Component | Requirement |
|-----------|------------|
| **OS** | Ubuntu 20.04+ / Debian 10+ |
| **RAM** | Minimum 1GB (2GB recommended) |
| **Storage** | 10GB free space |
| **Network** | Public IP address |
| **Ports** | 80, 443, 22 open |
| **Access** | Root privileges required |

---

## 🚀 Installation

### Method 1: Quick Installation (Recommended)

```bash
# Download and run setup script
wget https://raw.githubusercontent.com/yourusername/vlessxtls-script/main/setup.sh
chmod +x setup.sh
sudo ./setup.sh
```

### Method 2: Manual Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/vlessxtls-script.git
cd vlessxtls-script

# Make scripts executable
chmod +x *.sh

# Run setup
sudo ./setup.sh
```

### What Setup Does

The installation script automatically:

1. ✅ Updates system packages
2. ✅ Installs dependencies (Xray, Nginx, Certbot, vnstat, qrencode, etc.)
3. ✅ Creates directory structure at `/usr/local/vpnpanel/`
4. ✅ Initializes databases (users.db, ssh_users.db, traffic.db)
5. ✅ Configures Xray with default settings
6. ✅ Sets up Nginx web server
7. ✅ Configures firewall (UFW)
8. ✅ Creates systemd service
9. ✅ Sets up automatic backup cron job

**Installation Time**: Approximately 5-10 minutes

---

## 🎯 First-Time Setup

After installation completes, start the panel:

```bash
# Method 1: Using alias
vpnpanel

# Method 2: Direct script execution
/usr/local/vpnpanel/scripts/menu.sh
```

### Initial Configuration Steps

1. **Configure Domain** (Optional but recommended)
   - Go to `[4] Domain & SSL Management`
   - Add your domain name
   - Point domain A record to your server IP

2. **Install SSL Certificate**
   - After adding domain, install SSL from same menu
   - Enter email for certificate notifications
   - Certificate automatically renews every 60 days

3. **Create First User**
   - Go to `[1] Protocol Management`
   - Choose protocol (VLESS recommended)
   - Create user account
   - Note down connection details

---

## 📖 Usage Guide

### Main Menu Structure

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

## 1️⃣ Protocol Management

### Creating a VLESS User

1. Select `[1] Protocol Management` from main menu
2. Choose `[1] VLESS Protocol`
3. Select `[1] Create VLESS User`
4. Enter:
   - **Username**: User identifier (alphanumeric)
   - **Duration**: Days of validity (e.g., 30)
5. Choose transport protocol:
   - `[1] TCP` - Fastest, recommended
   - `[2] WebSocket` - Better for CDN/proxy
   - `[3] gRPC` - Good performance
   - `[4] HTTPUpgrade` - Modern alternative
6. Panel generates:
   - ✅ UUID automatically
   - ✅ Connection string
   - ✅ QR code

**Example Connection String:**
```
vless://550e8400-e29b-41d4-a716-446655440000@yourdomain.com:443?type=tcp&security=tls&sni=yourdomain.com&fp=chrome#username
```

### Creating a VMESS User

Similar to VLESS, but uses:
- Different encryption (AES-128-GCM)
- Compatible with older clients
- Slightly slower than VLESS

### Creating a Trojan User

1. Select `[3] Trojan Protocol`
2. Choose `[1] Create Trojan User`
3. Enter username and duration
4. Select transport protocol
5. Password is auto-generated

**Trojan Connection String Example:**
```
trojan://password123@yourdomain.com:443?type=tcp&security=tls&sni=yourdomain.com#username
```

### Managing Users

#### List All Users
- View comprehensive list with:
  - Creation date
  - Expiry date
  - Status (Active/Expired)
  - Transport type
  - Traffic usage (if enabled)

#### Delete User
1. Select protocol type
2. Choose `[2] Delete User`
3. Enter username
4. Confirm deletion
5. User immediately loses access

#### Renew User
1. Select `[3] Renew User`
2. Enter username
3. Enter additional days (e.g., 30)
4. New expiry date calculated automatically

#### Show User Config
- Displays full connection details
- Shows QR code for mobile scanning
- Provides import links for various clients

---

## 2️⃣ SSH Management

### Creating SSH Users

1. Select `[2] SSH Management`
2. Choose `[1] Create SSH User`
3. Enter:
   - **Username**: Linux username (lowercase, no spaces)
   - **Password**: Secure password (min 8 characters)
   - **Duration**: Days of validity

**Default SSH Port**: 22 (changeable in settings)

### SSH User Operations

#### Change Password
1. Select `[2] Change SSH Password`
2. Enter username
3. Enter new password
4. Password updated immediately

#### Lock/Unlock User
- **Lock**: Temporarily disable SSH access without deleting
- **Unlock**: Re-enable SSH access
- Useful for suspected abuse

#### List SSH Users
Shows all SSH accounts with:
- Username
- Creation date
- Expiry date
- Status (Active/Locked/Expired)

#### Show SSH Account Info
Displays:
```
Username: testuser
Password: ********
Server: yourdomain.com
Port: 22
Status: Active
Expires: 2024-12-31
```

### SSH Connection Example

```bash
ssh username@yourdomain.com
# Enter password when prompted
```

---

## 3️⃣ Monitoring & Statistics

### Active Connections

**SSH Connections:**
- Shows currently connected SSH users
- Display username, IP address, login time

**Xray Connections:**
- Active VLESS/VMESS/Trojan connections
- User identification
- Connection duration

### Bandwidth Usage

Powered by **vnstat**:

- **Daily Traffic**: Today's upload/download
- **Monthly Traffic**: Current month statistics
- **Total Traffic**: All-time bandwidth usage

**Example Output:**
```
Daily:    2.5 GB upload / 5.2 GB download
Monthly:  45 GB upload / 120 GB download
```

### System Resources

Real-time monitoring:

| Metric | Description |
|--------|-------------|
| **CPU Usage** | Current processor utilization |
| **Memory** | RAM usage (used/total) |
| **Disk** | Storage usage on root partition |
| **Load Average** | 1/5/15 minute system load |
| **Uptime** | Server uptime |

### User Traffic (Per-User)

If enabled in config:
- Traffic consumption per user
- Top bandwidth consumers
- Usage graphs (if gnuplot installed)

---

## 4️⃣ Domain & SSL Management

### Setting Up Domain

#### Prerequisites
1. Own a domain name
2. Access to DNS management

#### Steps

1. **Point Domain to Server**
   - Log into your domain registrar
   - Add A record:
     ```
     Type: A
     Name: @ (or vpn)
     Value: YOUR_SERVER_IP
     TTL: 3600
     ```
   - Wait for DNS propagation (5-30 minutes)

2. **Add Domain to Panel**
   - Select `[4] Domain & SSL Management`
   - Choose `[1] Add/Change Domain`
   - Enter domain: `vpn.yourdomain.com`
   - Panel checks DNS resolution
   - Confirms server IP matches

3. **Install SSL Certificate**
   - Choose `[2] Install SSL Certificate`
   - Enter email for notifications
   - Panel requests certificate from Let's Encrypt
   - Certificate installed automatically
   - Nginx reloaded with HTTPS config

**Certificate Validity**: 90 days (auto-renews at 60 days)

### Show Current Domain

Displays:
- Configured domain name
- Server IP address
- SSL status (Enabled/Not Configured)
- Certificate expiry date
- Access URL

### Renew SSL Certificate

Manually renew certificate:
1. Select `[3] Renew SSL Certificate`
2. Panel runs `certbot renew`
3. Services restarted automatically

**Automatic Renewal**: Set up via cron (installed by default)

### Remove Domain

- Removes domain configuration
- Disables SSL
- Reverts to IP-based access
- Does NOT delete Let's Encrypt certificate

---

## 5️⃣ Backup & Restore

### What Gets Backed Up

Backup includes:
- ✅ User database (`users.db`)
- ✅ SSH user database (`ssh_users.db`)
- ✅ Xray configuration (`xray_config.json`)
- ✅ Panel configuration (`panel.conf`)
- ✅ Traffic statistics (`traffic.db`)

### Creating Manual Backup

1. Select `[5] Backup & Restore`
2. Choose `[1] Create Backup`
3. Backup created at: `/usr/local/vpnpanel/backups/`
4. Filename format: `backup_YYYYMMDD_HHMMSS.tar.gz`

**Example:**
```
backup_20241215_143022.tar.gz
```

### Automatic Backups

Configured during installation:
- **Frequency**: Daily at 2:00 AM
- **Retention**: Last 7 backups (configurable)
- **Location**: `/usr/local/vpnpanel/backups/`

**View Cron Job:**
```bash
crontab -l | grep backup
```

**Edit Schedule:**
```bash
crontab -e
# Modify: 0 2 * * * /usr/local/vpnpanel/scripts/backup.sh auto
```

### Restoring from Backup

⚠️ **WARNING**: Restore overwrites current data

1. Select `[2] Restore from Backup`
2. Panel lists available backups
3. Choose backup by number
4. Confirm restoration
5. Services restart automatically

**After Restore:**
- All users from backup time restored
- Current users not in backup are lost
- Xray and Nginx restarted

### Download Backup

To download backup to local machine:

```bash
# From your local terminal
scp root@your-server-ip:/usr/local/vpnpanel/backups/backup_*.tar.gz ~/Downloads/
```

---

## 📁 Configuration Files

### Directory Structure

```
/usr/local/vpnpanel/
├── config/
│   ├── panel.conf              # Panel configuration
│   └── xray_config.json        # Xray core config
├── data/
│   ├── users.db                # Protocol users database
│   ├── ssh_users.db            # SSH users database
│   └── traffic.db              # Traffic statistics
├── logs/
│   ├── panel.log               # Panel operations log
│   ├── xray_access.log         # Xray access log
│   └── xray_error.log          # Xray error log
├── backups/                    # Backup files
└── scripts/
    ├── menu.sh                 # Main menu
    ├── utils.sh                # Utility functions
    ├── protocol-manager.sh     # Protocol management
    ├── ssh-manager.sh          # SSH management
    ├── monitor.sh              # Monitoring
    ├── domain-manager.sh       # Domain/SSL management
    └── backup.sh               # Backup/restore
```

### Key Configuration Files

#### `/usr/local/vpnpanel/config/panel.conf`

```bash
# Server Configuration
SERVER_IP="xxx.xxx.xxx.xxx"
DOMAIN="vpn.yourdomain.com"
SSL_ENABLED=true

# Xray Configuration
XRAY_PORT=443
XRAY_WS_PATH="/ws"
XRAY_GRPC_PATH="/grpc"

# Panel Settings
MAX_USERS=100
DEFAULT_DURATION=30
TRAFFIC_LIMIT_GB=0  # 0 = unlimited

# Backup Settings
BACKUP_RETENTION=7
AUTO_BACKUP=true
```

#### `/usr/local/vpnpanel/config/xray_config.json`

Xray-core configuration (auto-generated):
- Inbound/outbound rules
- Protocol settings
- Routing rules
- DNS configuration

**⚠️ Note**: Editing manually may break functionality. Use panel instead.

---

## 📱 Client Setup

### Recommended Client Applications

#### Android
- **v2rayNG** (Recommended)
  - [Download from GitHub](https://github.com/2dust/v2rayNG/releases)
  - Free and open-source
  - Full protocol support

- **Hiddify Next**
  - Modern UI
  - Easy setup
  - [GitHub](https://github.com/hiddify/hiddify-next)

#### iOS
- **Shadowrocket**
  - App Store ($2.99)
  - Best for iOS
  - Full feature support

- **Streisand**
  - Free alternative
  - Basic features

#### Windows
- **v2rayN** (Recommended)
  - [GitHub Releases](https://github.com/2dust/v2rayN/releases)
  - Tray icon
  - PAC/Global modes

- **Hiddify**
  - Cross-platform
  - Modern UI

#### macOS
- **V2Box**
  - App Store
  - Native macOS app

- **Qv2ray**
  - Open-source
  - Advanced features

#### Linux
- **Nekoray**
  - Qt-based GUI
  - [GitHub](https://github.com/MatsuriDayo/nekoray)

- **v2rayA**
  - Web-based GUI
  - Lightweight

### Import Configuration

#### Method 1: Scan QR Code (Mobile)
1. Open client app
2. Tap "+" or "Add"
3. Select "Scan QR Code"
4. Scan from panel display
5. Save and connect

#### Method 2: Import Link
1. Copy connection string from panel
2. Open client app
3. Select "Import from Clipboard"
4. Configuration added automatically

#### Method 3: Manual Configuration

**VLESS Example (v2rayNG):**

```
Address: vpn.yourdomain.com
Port: 443
User ID: 550e8400-e29b-41d4-a716-446655440000
Encryption: none
Flow: xtls-rprx-vision
Network: tcp
Security: tls
SNI: vpn.yourdomain.com
Fingerprint: chrome
```

---

## 🔧 Troubleshooting

### Panel Not Starting

**Symptoms**: Can't access menu, command not found

**Solutions**:
```bash
# Check if scripts are installed
ls -la /usr/local/vpnpanel/scripts/

# Run setup again
sudo ./setup.sh

# Manually create alias
echo 'alias vpnpanel="/usr/local/vpnpanel/scripts/menu.sh"' >> ~/.bashrc
source ~/.bashrc
```

### Xray Service Not Running

**Check status:**
```bash
systemctl status xray
```

**Common issues:**

1. **Config syntax error**
   ```bash
   xray test -c /usr/local/vpnpanel/config/xray_config.json
   ```

2. **Port already in use**
   ```bash
   netstat -tulpn | grep :443
   # Kill process using port
   kill -9 PID
   ```

3. **Restart service**
   ```bash
   systemctl restart xray
   journalctl -u xray -n 50
   ```

### Connection Issues

**Client can't connect:**

1. **Check firewall**
   ```bash
   ufw status
   ufw allow 443/tcp
   ufw allow 80/tcp
   ```

2. **Verify ports are open**
   ```bash
   netstat -tulpn | grep -E '(443|80)'
   ```

3. **Test from external**
   ```bash
   # From another machine
   telnet your-server-ip 443
   ```

4. **Check Xray logs**
   ```bash
   tail -f /usr/local/vpnpanel/logs/xray_error.log
   ```

### SSL Certificate Issues

**Certificate not installing:**

1. **Check DNS resolution**
   ```bash
   dig +short vpn.yourdomain.com
   # Should return server IP
   ```

2. **Ensure ports 80 and 443 are open**
   ```bash
   ufw allow 80/tcp
   ufw allow 443/tcp
   ```

3. **Manual certificate request**
   ```bash
   certbot certonly --standalone -d vpn.yourdomain.com
   ```

4. **Check certificate status**
   ```bash
   certbot certificates
   ```

**Certificate expired:**
```bash
# Manual renewal
certbot renew --force-renewal
systemctl restart nginx xray
```

### User Cannot Connect

**Checklist:**

- [ ] User account exists (check in panel)
- [ ] User not expired (check expiry date)
- [ ] Correct connection details
- [ ] Server IP/domain correct
- [ ] Port not blocked by ISP
- [ ] SSL certificate valid (if using domain)
- [ ] Client app up to date

**Verify user exists:**
```bash
cat /usr/local/vpnpanel/data/users.db | grep username
```

### Slow Connection Speed

1. **Check server load**
   - Go to `[3] Monitoring & Statistics`
   - View system resources

2. **Too many users**
   - Reduce concurrent connections
   - Upgrade server resources

3. **Network congestion**
   ```bash
   # Enable BBR (if not enabled)
   echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
   echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
   sysctl -p
   ```

4. **Check bandwidth**
   ```bash
   vnstat -l  # Live traffic monitor
   ```

---

## 🔒 Security Best Practices

### 1. Change Default SSH Port

```bash
# Edit SSH config
nano /etc/ssh/sshd_config

# Change line:
Port 2222

# Restart SSH
systemctl restart sshd

# Update firewall
ufw allow 2222/tcp
ufw delete allow 22/tcp
```

### 2. Enable Fail2Ban

```bash
# Install Fail2Ban
apt install fail2ban -y

# Configure for SSH
cat > /etc/fail2ban/jail.local << EOF
[sshd]
enabled = true
port = 22
maxretry = 3
bantime = 3600
EOF

# Start service
systemctl enable fail2ban
systemctl start fail2ban
```

### 3. Regular Backups

- Keep backups on external storage
- Test restore procedures monthly
- Verify backup integrity

```bash
# Verify backup contents
tar -tzf /usr/local/vpnpanel/backups/backup_*.tar.gz
```

### 4. Monitor Logs

```bash
# Watch panel logs
tail -f /usr/local/vpnpanel/logs/panel.log

# Watch Xray connections
tail -f /usr/local/vpnpanel/logs/xray_access.log

# Check for errors
grep ERROR /usr/local/vpnpanel/logs/*.log
```

### 5. Update Regularly

```bash
# Update system
apt update && apt upgrade -y

# Update Xray
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh) install

# Restart services
systemctl restart xray nginx
```

### 6. Limit User Access

- Set reasonable user limits
- Monitor bandwidth usage
- Remove inactive users
- Use strong passwords for SSH

### 7. Firewall Configuration

```bash
# Only allow necessary ports
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp      # SSH
ufw allow 80/tcp      # HTTP
ufw allow 443/tcp     # HTTPS
ufw enable
```

---

## ⚙️ Advanced Configuration

### Changing Xray Ports

Edit `/usr/local/vpnpanel/config/xray_config.json`:

```json
"inbounds": [
  {
    "port": 8443,  // Change from 443 to 8443
    "protocol": "vless",
    "settings": {...}
  }
]
```

**Update firewall:**
```bash
ufw allow 8443/tcp
systemctl restart xray
```

### Custom Backup Schedule

```bash
# Edit cron job
crontab -e

# Daily at 2 AM (default)
0 2 * * * /usr/local/vpnpanel/scripts/backup.sh auto

# Every 6 hours
0 */6 * * * /usr/local/vpnpanel/scripts/backup.sh auto

# Weekly on Sunday at 3 AM
0 3 * * 0 /usr/local/vpnpanel/scripts/backup.sh auto
```

### Traffic Limiting

Enable traffic limits in `panel.conf`:

```bash
# Edit config
nano /usr/local/vpnpanel/config/panel.conf

# Set traffic limit (in GB)
TRAFFIC_LIMIT_GB=100  # 100GB per user

# 0 = unlimited
```

### CDN Integration (Cloudflare)

For WebSocket connections:

1. **Add site to Cloudflare**
2. **Use WebSocket protocol**
3. **Configure Xray:**
   ```json
   "streamSettings": {
     "network": "ws",
     "wsSettings": {
       "path": "/ws",
       "headers": {
         "Host": "yourdomain.com"
       }
     }
   }
   ```
4. **Cloudflare settings:**
   - SSL/TLS: Full (strict)
   - Always Use HTTPS: On

### Multiple Domains

To use multiple domains:

1. Install certificates for each:
   ```bash
   certbot certonly --standalone -d vpn1.domain.com
   certbot certonly --standalone -d vpn2.domain.com
   ```

2. Configure multiple inbounds in Xray config

3. Update Nginx for each domain

---

## 🗑️ Uninstallation

### Complete Removal

```bash
# Stop services
systemctl stop xray nginx

# Remove panel files
rm -rf /usr/local/vpnpanel

# Remove Xray
bash <(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh) remove --purge

# Remove Nginx (optional)
apt remove nginx -y

# Remove other packages (optional)
apt remove certbot vnstat qrencode -y

# Remove alias
sed -i '/vpnpanel/d' ~/.bashrc

# Clean up
apt autoremove -y
```

### Keep Backups

Before uninstalling, save backups:

```bash
# Copy backups
cp -r /usr/local/vpnpanel/backups ~/vpn-backups

# Copy configs
cp -r /usr/local/vpnpanel/config ~/vpn-configs
```

---

## 📞 Support & Resources

### Getting Help

1. **Check this guide first**
2. **Search existing issues** on GitHub
3. **Check logs** for error messages
4. **Create new issue** with:
   - Problem description
   - System information
   - Relevant log excerpts
   - Steps to reproduce

### Useful Commands

```bash
# System info
uname -a
cat /etc/os-release

# Service status
systemctl status xray nginx

# Check disk space
df -h

# Check memory
free -h

# Active connections
netstat -tulpn

# Process list
ps aux | grep -E '(xray|nginx)'
```

### Log Locations

| Log File | Location |
|----------|----------|
| Panel Log | `/usr/local/vpnpanel/logs/panel.log` |
| Xray Access | `/usr/local/vpnpanel/logs/xray_access.log` |
| Xray Error | `/usr/local/vpnpanel/logs/xray_error.log` |
| Nginx Access | `/var/log/nginx/access.log` |
| Nginx Error | `/var/log/nginx/error.log` |
| System Log | `/var/log/syslog` |

---

## 📜 License

MIT License - Free to use, modify, and distribute.

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

## 📊 Version Information

- **Version**: 1.0.0
- **Last Updated**: December 2024
- **Compatibility**: Ubuntu 20.04+, Debian 10+
- **Xray Version**: Latest stable

---

**Made with ❤️ for a free and open internet**

For updates and more information, visit: https://github.com/yourusername/vlessxtls-script
