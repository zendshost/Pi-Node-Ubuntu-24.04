#!/bin/bash
# File: install_and_monitor_pi_node.sh
# Versi: 1.0
# Fungsi: Install Pi Node, setup docker, systemd, dan monitoring dengan Telegram

set -euo pipefail
IFS=$'\n\t'

##############################
# Fungsi logging
##############################
log() { echo -e "\e[1;34m[INFO]\e[0m $1"; }
error() { echo -e "\e[1;31m[ERROR]\e[0m $1" >&2; }

##############################
# INPUT TELEGRAM
##############################
read -rp "Masukkan Telegram Bot Token: " TELEGRAM_BOT_TOKEN
read -rp "Masukkan Telegram Chat ID: " TELEGRAM_CHAT_ID

##############################
# Variabel
##############################
PI_FOLDER="/root/pi-node"
DOCKER_VOLUMES="$PI_FOLDER/docker_volumes"
SERVICE_NAME="pi-node.service"
CHECK_INTERVAL=300 # detik
NODE_CONTAINER_NAME="mainnet"

##############################
# Update & Install dependencies
##############################
log "=== Update & install dependencies ==="
apt update && apt upgrade -y
apt install -y curl gnupg lsb-release ca-certificates git wget cron openssl

##############################
# Install Docker & Compose
##############################
log "=== Install Docker & Compose ==="
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl enable docker
systemctl start docker

##############################
# Install Pi Node (manual .deb)
##############################
log "=== Install Pi Node ==="
mkdir -p "$PI_FOLDER" "$DOCKER_VOLUMES"

# Buat .env contoh
cat > "$PI_FOLDER/.env" <<EOF
# Pi Node Environment
EOF

# Buat docker-compose.yml (versi berhasil)
cat > "$PI_FOLDER/docker-compose.yml" <<EOF
services:
  mainnet:
    image: pinetwork/pi-node-docker:organization_mainnet-v1.2-p19.6
    container_name: mainnet
    env_file:
      - ./.env
    volumes:
      - $DOCKER_VOLUMES/mainnet/stellar:/opt/stellar
      - $DOCKER_VOLUMES/mainnet/supervisor_logs:/var/log/supervisor
      - $DOCKER_VOLUMES/mainnet/history:/history
    ports:
      - "31401:8000"
      - "31402:31402"
      - "31403:1570"
    command: ["--mainnet"]
    restart: unless-stopped
EOF

##############################
# Jalankan Pi Node pertama kali
##############################
log "=== Jalankan container Pi Node ==="
cd "$PI_FOLDER"
docker compose up -d

##############################
# Buat systemd service Pi Node
##############################
log "=== Buat systemd service Pi Node ==="
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
tee "$SERVICE_PATH" > /dev/null <<EOF
[Unit]
Description=Pi Node
After=docker.service
Requires=docker.service

[Service]
WorkingDirectory=$PI_FOLDER
ExecStart=/usr/bin/docker compose up
ExecStop=/usr/bin/docker compose down
Restart=always
RestartSec=10
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl start "$SERVICE_NAME"

##############################
# Buat script monitoring & notifikasi Telegram
##############################
log "=== Buat script monitoring Pi Node & Telegram ==="
MONITOR_SCRIPT="$PI_FOLDER/pi-node-monitor.sh"
tee "$MONITOR_SCRIPT" > /dev/null <<EOF
#!/bin/bash
set -euo pipefail

NODE_CONTAINER_NAME="$NODE_CONTAINER_NAME"
CHECK_INTERVAL=$CHECK_INTERVAL
TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN"
TELEGRAM_CHAT_ID="$TELEGRAM_CHAT_ID"

send_telegram() {
    local message="\$1"
    curl -s -X POST "https://api.telegram.org/bot\${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d chat_id="\${TELEGRAM_CHAT_ID}" \
        -d text="\${message}" > /dev/null
}

log() { echo -e "[INFO] \$(date '+%Y-%m-%d %H:%M:%S') - \$1"; }

log "Memulai monitoring Pi Node..."
while true; do
    if ! docker ps --format '{{.Names}}' | grep -q "^\\${NODE_CONTAINER_NAME}\$"; then
        log "Container \${NODE_CONTAINER_NAME} tidak berjalan."
        send_telegram "⚠️ Pi Node container \${NODE_CONTAINER_NAME} tidak berjalan!"
        sleep \$CHECK_INTERVAL
        continue
    fi

    INGEST_LEDGER=\$(docker exec -i "\$NODE_CONTAINER_NAME" pi-node status 2>/dev/null | grep "Ingest Latest Ledger" | awk '{print \$NF}' || echo 0)
    CORE_LEDGER=\$(docker exec -i "\$NODE_CONTAINER_NAME" pi-node status 2>/dev/null | grep "Core Latest Ledger" | awk '{print \$NF}' || echo 0)

    if [[ "\$INGEST_LEDGER" == "\$CORE_LEDGER" ]] && [[ "\$CORE_LEDGER" != "0" ]]; then
        log "✅ Node sudah sinkron! Ledger: \$INGEST_LEDGER"
        send_telegram "🎉 Pi Node siap transaksi! Ledger: \$INGEST_LEDGER"
        break
    else
        log "Ledger belum sinkron. Ingest: \$INGEST_LEDGER / Core: \$CORE_LEDGER"
    fi
    sleep \$CHECK_INTERVAL
done
EOF

chmod +x "$MONITOR_SCRIPT"

##############################
# Jalankan monitoring di background
##############################
log "=== Jalankan monitoring Pi Node & Telegram ==="
"$MONITOR_SCRIPT" &

log "🎉 Pi Node & Monitoring siap! Pantau realtime ledger melalui:"
log "sudo docker logs -f $NODE_CONTAINER_NAME"
