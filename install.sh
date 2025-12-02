#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

log() { echo -e "\e[1;34m[INFO]\e[0m $1"; }
error() { echo -e "\e[1;31m[ERROR]\e[0m $1" >&2; }

PI_FOLDER="/root/pi-node"
DOCKER_VOLUMES="$PI_FOLDER/docker_volumes"
COMPOSE_FILE="$PI_FOLDER/docker-compose.yml"
SERVICE_NAME="pi-node.service"

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

log "=== Buat folder node & docker volumes ==="
sudo mkdir -p "$DOCKER_VOLUMES/mainnet/stellar" "$DOCKER_VOLUMES/mainnet/supervisor_logs" "$DOCKER_VOLUMES/mainnet/history"

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

log "=== Buat file .env kosong (jika perlu) ==="
touch "$PI_FOLDER/.env"

log "=== Jalankan container mainnet ==="
sudo docker compose -f "$COMPOSE_FILE" up -d

log "=== Buat script wrapper pi-node ==="
sudo tee /usr/local/bin/pi-node > /dev/null <<EOF
#!/bin/bash
PI_FOLDER="$PI_FOLDER"
COMPOSE_FILE="\$PI_FOLDER/docker-compose.yml"

case "\$1" in
  status)
    sudo docker exec mainnet /start --status
    ;;
  logs)
    sudo docker compose -f "\$COMPOSE_FILE" logs -f
    ;;
  start)
    sudo docker compose -f "\$COMPOSE_FILE" up -d
    ;;
  stop)
    sudo docker compose -f "\$COMPOSE_FILE" down
    ;;
  restart)
    sudo docker compose -f "\$COMPOSE_FILE" down
    sudo docker compose -f "\$COMPOSE_FILE" up -d
    ;;
  *)
    echo "Usage: pi-node {status|logs|start|stop|restart}"
    exit 1
    ;;
esac
EOF

sudo chmod +x /usr/local/bin/pi-node

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

log "🎉 Pi Node siap dijalankan!"
log "Gunakan perintah:"
log "  pi-node status   -> cek status node"
log "  pi-node logs     -> lihat log realtime"
log "  pi-node start    -> start node"
log "  pi-node stop     -> stop node"
log "  pi-node restart  -> restart node"
