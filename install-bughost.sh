#!/bin/bash

# VLESS XTLS-Vision VPN Kurulum (BugHost/SNI Trick için)
# Reality YOK - SNI özgürlüğü VAR!

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║   VLESS XTLS-Vision - BugHost/SNI Trick Installer    ║
║   Reality YOK - Serbest SNI!                         ║
╚═══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Bu script root olarak çalıştırılmalı!${NC}"
   exit 1
fi

echo -e "${GREEN}[1/7] Sistem güncelleniyor...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt upgrade -y

echo -e "${GREEN}[2/7] Gerekli paketler kuruluyor...${NC}"
apt install -y curl wget unzip jq ufw openssl

echo -e "${GREEN}[3/7] Sunucu bilgileri alınıyor...${NC}"
echo ""
read -p "Sunucu IP adresi: " SERVER_IP
if [[ -z "$SERVER_IP" ]]; then
    echo -e "${RED}IP adresi boş bırakılamaz!${NC}"
    exit 1
fi

# IP format kontrolü
if ! [[ $SERVER_IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    echo -e "${YELLOW}⚠️  Geçersiz IP formatı, devam ediliyor...${NC}"
fi

read -p "Port numarası [443]: " PORT
PORT=${PORT:-443}

# Port kontrolü
if ! [[ $PORT =~ ^[0-9]+$ ]] || [ $PORT -lt 1 ] || [ $PORT -gt 65535 ]; then
    echo -e "${RED}Geçersiz port! 1-65535 arası olmalı.${NC}"
    exit 1
fi

read -p "Kullanıcı sayısı [3]: " USER_COUNT
USER_COUNT=${USER_COUNT:-3}

# Kullanıcı sayısı kontrolü
if ! [[ $USER_COUNT =~ ^[0-9]+$ ]] || [ $USER_COUNT -lt 1 ]; then
    echo -e "${RED}Kullanıcı sayısı en az 1 olmalı!${NC}"
    exit 1
fi

echo -e "${GREEN}[4/8] Xray Core kuruluyor...${NC}"
if ! bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install; then
    echo -e "${RED}Xray kurulumu başarısız!${NC}"
    exit 1
fi

# Xray binary kontrolü
if ! command -v xray &> /dev/null; then
    echo -e "${RED}Xray yüklenmedi!${NC}"
    exit 1
fi

echo -e "${GREEN}[5/8] Self-signed TLS sertifikası oluşturuluyor...${NC}"
mkdir -p /etc/xray/certs
openssl req -x509 -newkey rsa:4096 -keyout /etc/xray/certs/key.pem -out /etc/xray/certs/cert.pem -days 3650 -nodes -subj "/CN=${SERVER_IP}" 2>/dev/null

# Sertifika izinlerini ayarla
chmod 644 /etc/xray/certs/cert.pem
chmod 600 /etc/xray/certs/key.pem
echo -e "${BLUE}✓ TLS sertifikası oluşturuldu${NC}"

echo -e "${GREEN}[6/8] UUID'ler oluşturuluyor...${NC}"
UUIDS_FILE="/tmp/xray_uuids_$$.txt"
> "$UUIDS_FILE"

for ((i=1; i<=$USER_COUNT; i++)); do
    UUID=$(xray uuid)
    if [[ -z "$UUID" ]]; then
        echo -e "${RED}UUID oluşturulamadı!${NC}"
        rm -f "$UUIDS_FILE"
        exit 1
    fi
    echo "$UUID" >> "$UUIDS_FILE"
    echo -e "${BLUE}Kullanıcı $i: $UUID${NC}"
done

echo -e "${GREEN}[7/8] Xray config dosyası oluşturuluyor...${NC}"

CONFIG_FILE="/usr/local/etc/xray/config.json"
CONFIG_DIR=$(dirname "$CONFIG_FILE")

# Config dizini oluştur
mkdir -p "$CONFIG_DIR"

# Client array oluştur
CLIENTS_JSON="["
FIRST=true

while IFS= read -r UUID; do
    if [[ -z "$UUID" ]]; then
        continue
    fi
    
    if [[ "$FIRST" = false ]]; then
        CLIENTS_JSON="${CLIENTS_JSON},"
    fi
    FIRST=false
    
    CLIENTS_JSON="${CLIENTS_JSON}{\"id\":\"${UUID}\",\"flow\":\"xtls-rprx-vision\"}"
done < "$UUIDS_FILE"

CLIENTS_JSON="${CLIENTS_JSON}]"

# Config dosyası oluştur (jq ile güvenli)
cat > "$CONFIG_FILE" << EOF
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log"
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": ${PORT},
      "protocol": "vless",
      "settings": {
        "clients": ${CLIENTS_JSON},
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "alpn": ["h2", "http/1.1"],
          "certificates": [
            {
              "certificateFile": "/etc/xray/certs/cert.pem",
              "keyFile": "/etc/xray/certs/key.pem"
            }
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "block"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "ip": [
          "geoip:private"
        ],
        "outboundTag": "block"
      }
    ]
  }
}
EOF

# Log dizini oluştur
mkdir -p /var/log/xray
chmod 755 /var/log/xray

echo -e "${GREEN}Config dosyası test ediliyor...${NC}"
if ! xray run -test -c "$CONFIG_FILE" 2>&1 | grep -q "Configuration OK"; then
    echo -e "${RED}Config dosyası hatalı!${NC}"
    xray run -test -c "$CONFIG_FILE"
    rm -f "$UUIDS_FILE"
    exit 1
fi

echo -e "${GREEN}[8/8] Firewall ayarlanıyor ve Xray başlatılıyor...${NC}"

# UFW kur (yoksa)
if ! command -v ufw &> /dev/null; then
    apt install -y ufw
fi

# UFW ayarla
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ${PORT}/tcp
ufw allow 22/tcp
ufw --force reload

# Xray servis dosyasını root kullanıcısı için yeniden yapılandır
echo -e "${BLUE}Xray servisini root olarak yapılandırılıyor...${NC}"

# Drop-in override dosyalarını sil (bunlar servis dosyasını override ediyor)
rm -rf /etc/systemd/system/xray.service.d
rm -rf /etc/systemd/system/xray@.service.d

# Servis dosyasını tamamen yeniden yaz
cat > /etc/systemd/system/xray.service << 'SERVICEEOF'
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1000000

[Install]
WantedBy=multi-user.target
SERVICEEOF

# Eski log dosyalarını temizle ve yeniden oluştur
rm -f /var/log/xray/access.log /var/log/xray/error.log
touch /var/log/xray/access.log /var/log/xray/error.log
chmod 644 /var/log/xray/access.log /var/log/xray/error.log

# Log ve config dizinlerine tam izin ver
chmod -R 755 /var/log/xray
chmod -R 755 /etc/xray

# Daemon'ı yeniden yükle
systemctl daemon-reload
echo -e "${GREEN}✓ Servis dosyası root kullanıcısı için yapılandırıldı${NC}"

# Xray servisini etkinleştir ve başlat
systemctl enable xray
systemctl restart xray

# Servisin başlamasını bekle (retry logic)
echo -e "${BLUE}Xray servisinin başlaması bekleniyor...${NC}"
for i in {1..10}; do
    sleep 1
    if systemctl is-active --quiet xray; then
        echo -e "${GREEN}✓ Xray servisi başarıyla başlatıldı!${NC}"
        break
    fi
    if [ $i -eq 10 ]; then
        echo -e "${RED}Xray başlatılamadı!${NC}"
        echo -e "${YELLOW}Son loglar:${NC}"
        journalctl -u xray -n 30 --no-pager
        echo -e "${YELLOW}Servis durumu:${NC}"
        systemctl status xray --no-pager
        rm -f "$UUIDS_FILE"
        exit 1
    fi
done

# Bağlantı bilgileri dosyası oluştur
INFO_FILE="/root/xray-bughost-info.txt"

cat > "$INFO_FILE" << INFOEOF
╔═══════════════════════════════════════════════════════╗
║        VLESS XTLS-Vision BugHost/SNI Trick           ║
╚═══════════════════════════════════════════════════════╝

📡 SUNUCU BİLGİLERİ:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IP Adresi    : ${SERVER_IP}
Port         : ${PORT}
Protocol     : VLESS + XTLS-Vision
Security     : TLS (self-signed)
Kullanıcı    : ${USER_COUNT} adet

════════════════════════════════════════════════════════

🎯 SNI TRICK NASIL KULLANILIR (XTLS ile):

1. Client uygulamasında profili düzenle
2. SNI/Host alanını değiştir (varsayılan: ${SERVER_IP})
3. Örnek: www.whatsapp.com, www.instagram.com
4. "allowInsecure" veya "Skip Cert Verify" seçeneğini AÇ
5. Operatör SNI'ye bakıp ücretsiz uygulama trafiği sanır
6. Sen tüm interneti kullanırsın!

════════════════════════════════════════════════════════

💡 ÖNERİLEN ÜCRETSİZ SNI'LER:

WhatsApp     : www.whatsapp.com
Instagram    : www.instagram.com
Facebook     : www.facebook.com
Spotify      : www.spotify.com
Twitter/X    : www.twitter.com
TikTok       : www.tiktok.com
YouTube      : www.youtube.com

⚠️  Operatörünüzün hangi uygulamaları ücretsiz sunduğunu 
    öğrenin ve o domain'i kullanın!

════════════════════════════════════════════════════════

🔗 CLIENT BAĞLANTI LİNKLERİ:

INFOEOF

USER_NUM=0
while IFS= read -r UUID; do
    if [[ -z "$UUID" ]]; then
        continue
    fi
    
    USER_NUM=$((USER_NUM+1))
    
    # XTLS-Vision with TLS - SNI değiştirilebilir!
    CONNECTION_LINK="vless://${UUID}@${SERVER_IP}:${PORT}?encryption=none&flow=xtls-rprx-vision&security=tls&sni=${SERVER_IP}&alpn=h2,http/1.1&type=tcp&allowInsecure=1#BugHost-User${USER_NUM}"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$INFO_FILE"
    echo "Kullanıcı ${USER_NUM}:" >> "$INFO_FILE"
    echo "${CONNECTION_LINK}" >> "$INFO_FILE"
    echo "" >> "$INFO_FILE"
done < "$UUIDS_FILE"

cat >> "$INFO_FILE" << 'INFOEOF2'
════════════════════════════════════════════════════════

📱 CLIENT UYGULAMALAR:

Android:
  • v2rayNG    : https://github.com/2dust/v2rayNG/releases
  • Hiddify    : https://github.com/hiddify/hiddify-next/releases

iOS:
  • Shadowrocket (App Store - Ücretli)
  • Hiddify    : https://github.com/hiddify/hiddify-next/releases

Windows:
  • v2rayN     : https://github.com/2dust/v2rayN/releases
  • Hiddify    : https://github.com/hiddify/hiddify-next/releases

════════════════════════════════════════════════════════

⚙️  SNI AYARLAMA ADIMLAR (v2rayNG Örnek):

1. Bağlantı linkini kopyala
2. v2rayNG'de + butonuna bas
3. "Import config from clipboard" seç
4. Profili düzenle (✏️ ikonu)
5. "Server name / SNI / Host" alanını bul
6. Ücretsiz uygulama domain'ini yaz: www.whatsapp.com
7. "Allow insecure" seçeneğini AÇ (🔒 bypass için)
8. Kaydet (✓) ve bağlan!

════════════════════════════════════════════════════════

🔧 YÖNETİM KOMUTLARI:

Durum kontrol     : systemctl status xray
Yeniden başlat    : systemctl restart xray
Durdur            : systemctl stop xray
Logları görüntüle : journalctl -u xray -f
Config test       : xray run -test -c /usr/local/etc/xray/config.json

════════════════════════════════════════════════════════

⚠️  ÖNEMLİ NOTLAR:

1. Her operatörde çalışmayabilir
2. Operatörünüzün ücretsiz paketini öğrenin
3. SNI'yi client'ta MUTLAKA ayarlayın
4. Doğru domain kullanın (www. ön ekiyle)
5. Bazı operatörler bu yöntemi engelleyebilir

════════════════════════════════════════════════════════

Kurulum tarihi: $(date '+%Y-%m-%d %H:%M:%S')
Bilgiler dosyası: /root/xray-bughost-info.txt

INFOEOF2

# Temp dosyayı temizle
rm -f "$UUIDS_FILE"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          BUGHOST/SNI TRICK KURULUMU TAMAMLANDI!      ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}⚠️  ÖNEMLİ HATIRLATMA:${NC}"
echo -e "${BLUE}Client uygulamasında SNI/Host alanına operatörünüzün${NC}"
echo -e "${BLUE}ücretsiz sunduğu uygulamanın domain'ini girmeyi unutmayın!${NC}"
echo ""
echo -e "${YELLOW}📋 Popüler SNI Örnekleri:${NC}"
echo -e "  • ${GREEN}www.whatsapp.com${NC}  (WhatsApp paketi varsa)"
echo -e "  • ${GREEN}www.instagram.com${NC} (Instagram paketi varsa)"
echo -e "  • ${GREEN}www.spotify.com${NC}   (Spotify paketi varsa)"
echo ""
echo -e "${BLUE}📄 Tüm bilgiler:${NC} ${GREEN}${INFO_FILE}${NC}"
echo ""
echo -e "${GREEN}🔗 CLIENT BAĞLANTI LİNKLERİ:${NC}"
echo ""

USER_NUM=0
while IFS= read -r line; do
    if [[ $line == Kullanıcı* ]]; then
        echo -e "${YELLOW}${line}${NC}"
    elif [[ $line == vless://* ]]; then
        echo -e "${GREEN}${line}${NC}"
        echo ""
    fi
done < "$INFO_FILE"

echo -e "${GREEN}🚀 BugHost/SNI Trick hazır! İyi kullanımlar!${NC}"
echo -e "${BLUE}💡 İpucu: cat ${INFO_FILE} komutuyla bilgileri tekrar görüntüleyebilirsiniz${NC}"
echo ""
