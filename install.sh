#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

log() { echo -e "\e[1;34m[INFO]\e[0m $1"; }
error() { echo -e "\e[1;31m[ERROR]\e[0m $1" >&2; }

PI_FOLDER="/root/pi-node"
DOCKER_VOLUMES="$PI_FOLDER/docker_volumes"
SERVICE_NAME="pi-node.service"
COMPOSE_FILE="$PI_FOLDER/docker-compose.yml"

# Generate random PostgreSQL password
PG_PASSWORD=$(openssl rand -base64 24)

log "=== Update & install dependencies ==="
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl gnupg lsb-release ca-certificates git wget cron openssl

log "=== Install Docker & Compose ==="
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl enable docker
sudo systemctl start docker

log "=== Tambahkan repo Pi Node & install ==="
curl -fsSL https://apt.minepi.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/minepi-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/minepi-archive-keyring.gpg] https://apt.minepi.com stable main" | sudo tee /etc/apt/sources.list.d/minepi.list
sudo apt update
sudo apt install -y pi-node || true  # pi-node package optional, kita pakai docker-compose manual

log "=== Buat folder node & docker volumes ==="
sudo mkdir -p "$DOCKER_VOLUMES/mainnet/stellar"
sudo mkdir -p "$DOCKER_VOLUMES/mainnet/supervisor_logs"
sudo mkdir -p "$DOCKER_VOLUMES/mainnet/history"

log "=== Buat docker-compose.yml ==="
sudo tee "$COMPOSE_FILE" > /dev/null <<EOF
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

log "=== Jalankan container mainnet ==="
sudo docker compose -f "$COMPOSE_FILE" up -d

log "=== Buat script wrapper pi-node ==="
WRAPPER="/usr/local/bin/pi-node"
sudo tee "$WRAPPER" > /dev/null <<'EOF'
#!/bin/bash
PI_FOLDER="/root/pi-node"
COMPOSE_FILE="$PI_FOLDER/docker-compose.yml"

case "$1" in
  status)
    sudo docker ps | grep mainnet
    sudo docker logs --tail 20 mainnet
    ;;
  logs)
    sudo docker logs -f mainnet
    ;;
  start)
    sudo docker compose -f "$COMPOSE_FILE" up -d
    ;;
  stop)
    sudo docker compose -f "$COMPOSE_FILE" down
    ;;
  restart)
    sudo docker compose -f "$COMPOSE_FILE" down
    sudo docker compose -f "$COMPOSE_FILE" up -d
    ;;
  *)
    echo "Usage: pi-node {status|logs|start|stop|restart}"
    exit 1
    ;;
esac
EOF
sudo chmod +x "$WRAPPER"

log "=== Buat systemd service agar otomatis start saat boot ==="
SERVICE_PATH="/etc/systemd/system/$SERVICE_NAME"
sudo tee "$SERVICE_PATH" > /dev/null <<EOF
[Unit]
Description=Pi Node
After=docker.service
Requires=docker.service

[Service]
WorkingDirectory=$PI_FOLDER
ExecStart=/usr/local/bin/pi-node start
ExecStop=/usr/local/bin/pi-node stop
Restart=always
RestartSec=10
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable "$SERVICE_NAME"
sudo systemctl start "$SERVICE_NAME"

log "=== Buat script auto-update Pi Node ==="
AUTO_UPDATE_SCRIPT="/usr/local/bin/pi-node-auto-update.sh"
sudo tee "$AUTO_UPDATE_SCRIPT" > /dev/null <<EOF
#!/bin/bash
set -euo pipefail
PI_FOLDER="$PI_FOLDER"
SERVICE_NAME="$SERVICE_NAME"

echo "[INFO] Memulai update Pi Node..."
sudo apt update
sudo apt install -y pi-node || true
sudo docker compose -f "\$PI_FOLDER/docker-compose.yml" pull
sudo systemctl restart "\$SERVICE_NAME"
EOF
sudo chmod +x "$AUTO_UPDATE_SCRIPT"

log "=== Jadwalkan cron job auto-update setiap 6 jam ==="
(crontab -l 2>/dev/null; echo "0 */6 * * * $AUTO_UPDATE_SCRIPT >> /var/log/pi-node-auto-update.log 2>&1") | crontab -

log "🎉 Pi Node siap dijalankan!"
log "Gunakan perintah:"
log "  pi-node status   -> cek status node"
log "  pi-node logs     -> lihat log realtime"
log "  pi-node start    -> start node"
log "  pi-node stop     -> stop node"
log "  pi-node restart  -> restart node"
