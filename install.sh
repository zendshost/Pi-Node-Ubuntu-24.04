#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# --------- Fungsi log ----------
log() { echo -e "\e[1;34m[INFO]\e[0m $1"; }
warn() { echo -e "\e[1;33m[WARN]\e[0m $1"; }
error() { echo -e "\e[1;31m[ERROR]\e[0m $1" >&2; }

# --------- Variabel ----------
PI_FOLDER="/root/pi-node"
DOCKER_VOLUMES="$PI_FOLDER/docker_volumes"
ENV_FILE="$PI_FOLDER/.env"
COMPOSE_FILE="$PI_FOLDER/docker-compose.yml"
SERVICE_NAME="pi-node.service"

# Generate random PostgreSQL password
PG_PASSWORD=$(openssl rand -base64 24)

# --------- Update & install dependencies ----------
log "=== Update & install dependencies ==="
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl gnupg lsb-release ca-certificates git wget cron openssl jq

# --------- Install Docker & Compose ----------
log "=== Install Docker & Compose ==="
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl enable docker
sudo systemctl start docker

# --------- Buat folder node & docker volumes ----------
log "=== Buat folder node & docker volumes ==="
sudo mkdir -p "$DOCKER_VOLUMES/mainnet/stellar"
sudo mkdir -p "$DOCKER_VOLUMES/mainnet/supervisor_logs"
sudo mkdir -p "$DOCKER_VOLUMES/mainnet/history"

# --------- Buat file .env jika belum ada ----------
if [ ! -f "$ENV_FILE" ]; then
    log "=== Buat file .env default ==="
    cat > "$ENV_FILE" <<EOF
POSTGRES_PASSWORD=$PG_PASSWORD
EOF
fi

# --------- Buat docker-compose.yml ----------
log "=== Buat docker-compose.yml ==="
cat > "$COMPOSE_FILE" <<EOF
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

# --------- Jalankan node ----------
log "=== Menjalankan container Pi Node ==="
cd "$PI_FOLDER"
sudo docker compose up -d

# --------- Buat systemd service ----------
log "=== Membuat systemd service ==="
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
sudo tee "$SERVICE_PATH" > /dev/null <<EOF
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

sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl start "$SERVICE_NAME"

# --------- Script untuk monitor ledger catch-up ----------
MONITOR_SCRIPT="/usr/local/bin/pi-node-monitor.sh"
sudo tee "$MONITOR_SCRIPT" > /dev/null <<'EOF'
#!/bin/bash
PI_FOLDER="/root/pi-node"
while true; do
    if ! docker ps | grep -q mainnet; then
        echo "[WARN] Container mainnet tidak berjalan"
    else
        STATUS=$(docker exec mainnet pi-node status 2>/dev/null || echo "Tidak tersedia")
        LEDGER=$(echo "$STATUS" | grep "Ledger:" | awk '{print $2}')
        QUORUM=$(echo "$STATUS" | grep "Quorum Ledger:" | awk '{print $3}')
        STATE=$(echo "$STATUS" | grep "State:" | awk -F": " '{print $2}')
        echo "[INFO] State: $STATE, Ledger: $LEDGER, Quorum Ledger: $QUORUM"
        if [[ "$STATE" == "Catching up" ]]; then
            echo "[INFO] Node masih catch-up..."
        else
            echo "[INFO] Node sudah synced!"
        fi
    fi
    sleep 60
done
EOF
sudo chmod +x "$MONITOR_SCRIPT"

log "🎉 Pi Node siap dijalankan dan bisa dimonitor!"
log "Pantau node realtime: sudo journalctl -u $SERVICE_NAME -f"
log "Pantau status catch-up ledger: sudo $MONITOR_SCRIPT"
