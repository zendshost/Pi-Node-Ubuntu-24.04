#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

log() { echo -e "\e[1;34m[INFO]\e[0m $1"; }
error() { echo -e "\e[1;31m[ERROR]\e[0m $1" >&2; }

# ----- CONFIG -----
PI_FOLDER="/root/pi-node"
DOCKER_VOLUMES="$PI_FOLDER/docker_volumes"
SERVICE_NAME="pi-node.service"
MONITOR_SERVICE="pi-node-monitor.service"

# Input Telegram token & chat ID
read -rp "Masukkan token bot Telegram: " TELEGRAM_TOKEN
read -rp "Masukkan chat ID Telegram: " TELEGRAM_CHAT_ID

# Generate random PostgreSQL password
PG_PASSWORD=$(openssl rand -base64 24)

# ----- INSTALL DEPENDENCIES -----
log "=== Update & install dependencies ==="
apt update && apt upgrade -y
apt install -y curl gnupg lsb-release ca-certificates git wget cron openssl jq

# ----- INSTALL DOCKER & COMPOSE -----
log "=== Install Docker & Compose ==="
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
systemctl enable docker
systemctl start docker

# ----- PI NODE FOLDER & DOCKER VOLUMES -----
log "=== Buat folder Pi Node & docker volumes ==="
mkdir -p "$DOCKER_VOLUMES/mainnet/stellar"
mkdir -p "$DOCKER_VOLUMES/mainnet/supervisor_logs"
mkdir -p "$DOCKER_VOLUMES/mainnet/history"

# ----- CREATE docker-compose.yml -----
log "=== Buat docker-compose.yml ==="
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

# ----- CREATE .env -----
# Auto-generate Pi Node private key
NODE_PRIVATE_KEY=$(openssl rand -hex 32)
cat > "$PI_FOLDER/.env" <<EOF
POSTGRES_PASSWORD=$PG_PASSWORD
NODE_PRIVATE_KEY=$NODE_PRIVATE_KEY
EOF

# ----- INITIALIZE PI NODE -----
log "=== Initialize Pi Node ==="
pi-node initialize \
  --pi-folder "$PI_FOLDER" \
  --docker-volumes "$DOCKER_VOLUMES" \
  --auto-confirm \
  --setup-auto-updates \
  --start-node \
  --postgres-password "$PG_PASSWORD" \
  --node-private-key "$NODE_PRIVATE_KEY" \
  --force

# ----- SYSTEMD SERVICE FOR PI NODE -----
log "=== Buat systemd service untuk Pi Node ==="
cat > /etc/systemd/system/$SERVICE_NAME <<EOF
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

# ----- SMART MONITORING SCRIPT -----
MONITOR_SCRIPT="$PI_FOLDER/pi-node-monitor.sh"
log "=== Buat smart monitoring script ==="
cat > "$MONITOR_SCRIPT" <<'EOF'
#!/bin/bash
set -euo pipefail

PI_FOLDER="/root/pi-node"
TELEGRAM_TOKEN="__TELEGRAM_TOKEN__"
TELEGRAM_CHAT_ID="__TELEGRAM_CHAT_ID__"
LAST_STATE=""

while true; do
  CORE_LEDGER=$(docker exec mainnet stellar-core info | jq -r '.info.ledger')
  INGEST_LEDGER=$(docker exec mainnet pi-node info | jq -r '.ingest_latest_ledger')

  if [[ "$INGEST_LEDGER" -lt "$CORE_LEDGER" ]]; then
    STATE="syncing"
    MESSAGE="Ledger belum sinkron. Ingest: $INGEST_LEDGER / Core: $CORE_LEDGER"
  else
    STATE="synced"
    MESSAGE="Ledger sudah sinkron! Ingest: $INGEST_LEDGER / Core: $CORE_LEDGER"
  fi

  if [[ "$STATE" != "$LAST_STATE" ]]; then
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage" \
         -d chat_id="$TELEGRAM_CHAT_ID" \
         -d text="$MESSAGE"
    LAST_STATE="$STATE"
  fi

  sleep 300
done
EOF

# Ganti token & chat_id
sed -i "s|__TELEGRAM_TOKEN__|$TELEGRAM_TOKEN|" "$MONITOR_SCRIPT"
sed -i "s|__TELEGRAM_CHAT_ID__|$TELEGRAM_CHAT_ID|" "$MONITOR_SCRIPT"
chmod +x "$MONITOR_SCRIPT"

# ----- SYSTEMD SERVICE FOR SMART MONITOR -----
log "=== Buat systemd service untuk smart monitoring ==="
cat > /etc/systemd/system/$MONITOR_SERVICE <<EOF
[Unit]
Description=Pi Node Smart Monitor & Telegram
After=pi-node.service
Requires=pi-node.service

[Service]
ExecStart=$MONITOR_SCRIPT
Restart=always
RestartSec=60

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "$MONITOR_SERVICE"
systemctl start "$MONITOR_SERVICE"

log "🎉 Pi Node siap transaksi & Smart Monitoring aktif!"
log "Node otomatis berjalan walau logout atau reboot."
log "Cek status node: sudo systemctl status $SERVICE_NAME"
log "Cek status smart monitoring: sudo systemctl status $MONITOR_SERVICE"
log "Private key Pi Node: $NODE_PRIVATE_KEY (jangan hilangkan!)"
