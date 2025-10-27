#!/bin/bash

# VLESS XTLS-Reality VPN Kurulum
# En güvenli ve DPI bypass

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
cat << "EOF"
╔═══════════════════════════════════════════════════════╗
║     VLESS XTLS-Reality - Güvenli & DPI Bypass        ║
╚═══════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Bu script root olarak çalıştırılmalı!${NC}"
   exit 1
fi

echo -e "${GREEN}[1/9] Sistem güncelleniyor...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt upgrade -y

echo -e "${GREEN}[2/9] Gerekli paketler kuruluyor...${NC}"
apt install -y curl wget unzip jq ufw socat cron openssl net-tools

echo -e "${GREEN}[3/9] Sunucu bilgileri alınıyor...${NC}"
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

echo ""
echo -e "${YELLOW}Reality Destination (Maskeleme Sitesi):${NC}"
echo "1. www.microsoft.com   (Önerilen - Stabil)"
echo "2. www.cloudflare.com  (Hızlı)"
echo "3. www.amazon.com      (Güvenilir)"
echo "4. www.apple.com       (iOS için ideal)"
echo "5. www.google.com      (Popüler)"
echo "6. Özel domain gir"
echo ""
read -p "Seçiminiz [1]: " DEST_CHOICE
DEST_CHOICE=${DEST_CHOICE:-1}

case $DEST_CHOICE in
    1) DEST_SITE="www.microsoft.com" ;;
    2) DEST_SITE="www.cloudflare.com" ;;
    3) DEST_SITE="www.amazon.com" ;;
    4) DEST_SITE="www.apple.com" ;;
    5) DEST_SITE="www.google.com" ;;
    6) 
        read -p "Özel domain (örn: www.example.com): " CUSTOM_DEST
        if [[ -z "$CUSTOM_DEST" ]]; then
            echo -e "${RED}Domain boş bırakılamaz!${NC}"
            exit 1
        fi
        DEST_SITE="$CUSTOM_DEST"
        ;;
    *) 
        echo -e "${YELLOW}Geçersiz seçim, varsayılan kullanılıyor...${NC}"
        DEST_SITE="www.microsoft.com"
        ;;
esac

echo -e "${BLUE}✓ Seçilen Destination: ${DEST_SITE}${NC}"

# Destination erişilebilirlik kontrolü
echo -e "${GREEN}Destination erişilebilirliği test ediliyor...${NC}"
if timeout 5 bash -c "curl -sI https://${DEST_SITE} > /dev/null 2>&1"; then
    echo -e "${GREEN}✓ ${DEST_SITE} erişilebilir${NC}"
else
    echo -e "${YELLOW}⚠️  ${DEST_SITE} erişiminde sorun olabilir, devam ediliyor...${NC}"
fi

echo -e "${GREEN}[4/9] Xray Core kuruluyor...${NC}"
if ! bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install; then
    echo -e "${RED}Xray kurulumu başarısız!${NC}"
    exit 1
fi

# Xray binary kontrolü
if ! command -v xray &> /dev/null; then
    echo -e "${RED}Xray yüklenmedi!${NC}"
    exit 1
fi

XRAY_VERSION=$(xray version 2>&1 | head -n 1)
echo -e "${BLUE}✓ Xray yüklendi: ${XRAY_VERSION}${NC}"

echo -e "${GREEN}[5/9] UUID ve Reality Keypair oluşturuluyor...${NC}"

# UUID'ler oluştur
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
    echo -e "${BLUE}Kullanıcı $i UUID: $UUID${NC}"
done

# Reality keypair oluştur
KEYS_FILE="/tmp/xray_keys_$$.txt"
xray x25519 > "$KEYS_FILE" 2>&1

# Farklı format deneme
PRIVATE_KEY=$(grep -i "private" "$KEYS_FILE" | awk '{print $NF}' | tr -d ' \r\n')
PUBLIC_KEY=$(grep -i "public" "$KEYS_FILE" | awk '{print $NF}' | tr -d ' \r\n')

# Eğer boşsa başka formatları dene
if [[ -z "$PRIVATE_KEY" ]]; then
    PRIVATE_KEY=$(grep "PrivateKey:" "$KEYS_FILE" | cut -d':' -f2 | tr -d ' \r\n')
fi
if [[ -z "$PUBLIC_KEY" ]]; then
    PUBLIC_KEY=$(grep "PublicKey:" "$KEYS_FILE" | cut -d':' -f2 | tr -d ' \r\n')
fi

echo -e "${BLUE}Private Key: $PRIVATE_KEY${NC}"
echo -e "${BLUE}Public Key: $PUBLIC_KEY${NC}"

if [[ -z "$PRIVATE_KEY" ]] || [[ -z "$PUBLIC_KEY" ]]; then
    echo -e "${RED}Keypair oluşturulamadı!${NC}"
    echo -e "${YELLOW}Key dosyası içeriği:${NC}"
    cat "$KEYS_FILE"
    rm -f "$UUIDS_FILE" "$KEYS_FILE"
    exit 1
fi

# Short ID oluştur
SHORT_ID=$(openssl rand -hex 8)
echo -e "${BLUE}Short ID: $SHORT_ID${NC}"

echo -e "${GREEN}[6/9] Xray config dosyası oluşturuluyor...${NC}"

CONFIG_FILE="/usr/local/etc/xray/config.json"
CONFIG_DIR=$(dirname "$CONFIG_FILE")

# Config dizini oluştur
mkdir -p "$CONFIG_DIR"

# Client array oluştur
CLIENTS_ARRAY="["
FIRST=true
USER_INDEX=0

while IFS= read -r UUID; do
    if [[ -z "$UUID" ]]; then
        continue
    fi
    
    if [[ "$FIRST" = false ]]; then
        CLIENTS_ARRAY="${CLIENTS_ARRAY},"
    fi
    FIRST=false
    USER_INDEX=$((USER_INDEX+1))
    
    CLIENTS_ARRAY="${CLIENTS_ARRAY}
    {
      \"id\": \"${UUID}\",
      \"flow\": \"xtls-rprx-vision\"
    }"
done < "$UUIDS_FILE"

CLIENTS_ARRAY="${CLIENTS_ARRAY}
  ]"

# Config dosyası oluştur
cat > "$CONFIG_FILE" << 'CONFIGEOF'
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log"
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": PORT_PLACEHOLDER,
      "protocol": "vless",
      "settings": {
        "clients": CLIENTS_PLACEHOLDER,
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "DEST_PLACEHOLDER:443",
          "xver": 0,
          "serverNames": ["DEST_PLACEHOLDER"],
          "privateKey": "PRIVATE_KEY_PLACEHOLDER",
          "shortIds": ["", "SHORT_ID_PLACEHOLDER"]
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
CONFIGEOF

# Placeholder'ları değiştir
sed -i "s/PORT_PLACEHOLDER/${PORT}/g" "$CONFIG_FILE"
sed -i "s/DEST_PLACEHOLDER/${DEST_SITE}/g" "$CONFIG_FILE"
sed -i "s/PRIVATE_KEY_PLACEHOLDER/${PRIVATE_KEY}/g" "$CONFIG_FILE"
sed -i "s/SHORT_ID_PLACEHOLDER/${SHORT_ID}/g" "$CONFIG_FILE"
sed -i "s|CLIENTS_PLACEHOLDER|${CLIENTS_ARRAY}|g" "$CONFIG_FILE"

# Log dizini oluştur
mkdir -p /var/log/xray
chmod 755 /var/log/xray

echo -e "${GREEN}[7/9] Config dosyası test ediliyor...${NC}"

# Private key kontrolü
if grep -q '"privateKey": ""' "$CONFIG_FILE"; then
    echo -e "${RED}Private key boş!${NC}"
    rm -f "$UUIDS_FILE" "$KEYS_FILE"
    exit 1
fi

# Config test
CONFIG_TEST_OUTPUT=$(xray run -test -c "$CONFIG_FILE" 2>&1)
if echo "$CONFIG_TEST_OUTPUT" | grep -q "Configuration OK"; then
    echo -e "${GREEN}✓ Config dosyası geçerli${NC}"
else
    echo -e "${RED}Config dosyası hatalı!${NC}"
    echo "$CONFIG_TEST_OUTPUT"
    rm -f "$UUIDS_FILE" "$KEYS_FILE"
    exit 1
fi

echo -e "${GREEN}[8/9] Firewall ayarlanıyor...${NC}"

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

echo -e "${GREEN}[9/9] Xray servisi başlatılıyor...${NC}"

systemctl enable xray
systemctl restart xray
sleep 4

# Servis durumu kontrol
if ! systemctl is-active --quiet xray; then
    echo -e "${RED}Xray başlatılamadı!${NC}"
    echo -e "${YELLOW}Son 30 log satırı:${NC}"
    journalctl -u xray -n 30 --no-pager
    rm -f "$UUIDS_FILE" "$KEYS_FILE"
    exit 1
fi

echo -e "${GREEN}✓ Xray başarıyla çalışıyor!${NC}"

# Port dinleme kontrolü
if netstat -tulpn | grep -q ":${PORT}.*xray"; then
    echo -e "${GREEN}✓ Port ${PORT} dinleniyor${NC}"
else
    echo -e "${YELLOW}⚠️  Port ${PORT} dinlenmiyor olabilir${NC}"
fi

# Bağlantı bilgileri dosyası oluştur
INFO_FILE="/root/xray-reality-info.txt"

cat > "$INFO_FILE" << INFOEOF
╔═══════════════════════════════════════════════════════╗
║          XRAY REALITY VPN - GÜVENLİ & HIZLI          ║
╚═══════════════════════════════════════════════════════╝

📡 SUNUCU BİLGİLERİ:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IP Adresi    : ${SERVER_IP}
Port         : ${PORT}
Protocol     : VLESS + XTLS-Reality
Destination  : ${DEST_SITE}
Kullanıcı    : ${USER_COUNT} adet

🔐 REALITY ANAHTARLARI:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Public Key   : ${PUBLIC_KEY}
Short ID     : ${SHORT_ID}

⚠️  Bu anahtarlar client'ta gerekli! Kaydedin!

════════════════════════════════════════════════════════

✨ ÖZELLİKLER:

✓ DPI Bypass (Deep Packet Inspection)
✓ Çok yüksek hız (XTLS-Vision)
✓ Maksimum güvenlik (Reality protokolü)
✓ Domain gerektirmez
✓ Tespit edilmesi çok zor

════════════════════════════════════════════════════════

🔗 CLIENT BAĞLANTI LİNKLERİ:

INFOEOF

USER_NUM=0
while IFS= read -r UUID; do
    if [[ -z "$UUID" ]]; then
        continue
    fi
    
    USER_NUM=$((USER_NUM+1))
    
    CONNECTION_LINK="vless://${UUID}@${SERVER_IP}:${PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=${DEST_SITE}&fp=chrome&pbk=${PUBLIC_KEY}&sid=${SHORT_ID}&type=tcp&headerType=none#Reality-User${USER_NUM}"
    
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

macOS:
  • V2Box (App Store)
  • Hiddify    : https://github.com/hiddify/hiddify-next/releases

Linux:
  • Nekoray    : https://github.com/MatsuriDayo/nekoray/releases

════════════════════════════════════════════════════════

⚙️  BAĞLANTI KURMA ADIMLAR:

1. Client uygulamasını indir ve yükle
2. Yukarıdaki bağlantı linkini kopyala (vless://...)
3. Client'ta + butonuna bas
4. "Import from clipboard" veya "Scan QR" seç
5. Bağlan!

⚠️  Reality'de SNI değiştirilemez! Otomatik gelir.

════════════════════════════════════════════════════════

🔧 YÖNETİM KOMUTLARI:

Durum kontrol     : systemctl status xray
Yeniden başlat    : systemctl restart xray
Durdur            : systemctl stop xray
Logları görüntüle : journalctl -u xray -f
Config test       : xray run -test -c /usr/local/etc/xray/config.json
Config düzenle    : nano /usr/local/etc/xray/config.json

════════════════════════════════════════════════════════

🛡️  GÜVENLİK İPUÇLARI:

1. Public Key ve Short ID'yi kimseyle paylaşma
2. Sadece güvendiğiniz kişilere bağlantı linki ver
3. Düzenli olarak logları kontrol et
4. Firewall'u kapatma
5. SSH portunu değiştirmeyi düşün

════════════════════════════════════════════════════════

📊 PERFORMANS İYİLEŞTİRME:

# BBR congestion control etkinleştir (Ubuntu 22.04+)
echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

# BBR kontrolü
sysctl net.ipv4.tcp_congestion_control

════════════════════════════════════════════════════════

❓ SORUN GİDERME:

Client bağlanamıyor:
  → Public key doğru mu kontrol et
  → Short ID doğru mu kontrol et
  → Sunucu IP ve port doğru mu
  → Firewall açık mı: ufw status
  → Servis çalışıyor mu: systemctl status xray

Yavaş bağlantı:
  → Farklı destination dene
  → BBR'yi etkinleştir (yukarıdaki komutlar)
  → Config'i test et: xray run -test -c /usr/local/etc/xray/config.json

Servis başlamıyor:
  → Logları kontrol et: journalctl -u xray -n 50
  → Config test et: xray run -test -c /usr/local/etc/xray/config.json
  → Port kullanımda mı: netstat -tulpn | grep PORT_NUMBER

════════════════════════════════════════════════════════

🔄 GÜNCELLEME:

# Xray'i güncelle
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
systemctl restart xray

# Versiyonu kontrol et
xray version

════════════════════════════════════════════════════════

🗑️  KALDIRMA:

# Xray'i tamamen kaldır
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove --purge
rm -rf /usr/local/etc/xray
rm -rf /var/log/xray
rm -f /root/xray-reality-info.txt

════════════════════════════════════════════════════════

Kurulum tarihi: $(date '+%Y-%m-%d %H:%M:%S')
Bilgiler dosyası: /root/xray-reality-info.txt

Bu dosyayı güvenli bir yerde sakla!

INFOEOF2

# Temp dosyaları temizle
rm -f "$UUIDS_FILE" "$KEYS_FILE"

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          REALITY KURULUMU BAŞARIYLA TAMAMLANDI!      ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}🔐 REALITY ANAHTARLARI:${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Public Key:${NC}  ${PUBLIC_KEY}"
echo -e "${GREEN}Short ID:${NC}    ${SHORT_ID}"
echo -e "${GREEN}Destination:${NC} ${DEST_SITE}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}⚠️  Bu anahtarları kaydedin! Client'ta gerekli olacak.${NC}"
echo ""
echo -e "${BLUE}📄 Tüm bilgiler ve bağlantı linkleri:${NC}"
echo -e "${GREEN}   ${INFO_FILE}${NC}"
echo ""
echo -e "${YELLOW}📋 Bilgileri görüntüle:${NC}"
echo -e "${BLUE}   cat ${INFO_FILE}${NC}"
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

echo -e "${GREEN}🚀 Reality VPN hazır! İyi kullanımlar!${NC}"
echo -e "${BLUE}💡 İpucu: systemctl status xray komutuyla servis durumunu kontrol edebilirsiniz${NC}"
echo ""
