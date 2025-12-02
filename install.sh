#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

log() { echo -e "\e[1;34m[INFO]\e[0m $1"; }
error() { echo -e "\e[1;31m[ERROR]\e[0m $1" >&2; }

PI_FOLDER="/root/pi-node"
DOCKER_VOLUMES="$PI_FOLDER/docker_volumes"
SERVICE_NAME="pi-node.service"
AUTO_UPDATE_SCRIPT="/usr/local/bin/pi-node-auto-update.sh"

# Random PostgreSQL password
PG_PASSWORD=$(openssl rand -base64 24)

log "=== Update & install dependencies ==="
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl gnupg lsb-release ca-certificates git wget cron openssl jq

log "=== Install Docker & Compose ==="
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl enable docker
sudo systemctl start docker

log "=== Buat folder node & docker volumes ==="
sudo mkdir -p "$DOCKER_VOLUMES/mainnet/stellar" "$DOCKER_VOLUMES/mainnet/supervisor_logs" "$DOCKER_VOLUMES/mainnet/history"
mkdir -p "$PI_FOLDER"
cd "$PI_FOLDER"

log "=== Buat docker-compose.yml ==="
tee docker-compose.yml > /dev/null <<EOF
version: '3.8'
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

log "=== Buat file .env dengan node private key ==="
if [ ! -f .env ]; then
  NODE_KEY=$(openssl rand -hex 32)
  echo "NODE_PRIVATE_KEY=$NODE_KEY" > .env
  echo "PRIVATE_KEY=$NODE_KEY" >> .env
  log "Node private key telah digenerate dan disimpan di .env"
else
  log ".env sudah ada, menggunakan node key yang ada."
fi

log "=== Jalankan container mainnet ==="
sudo docker compose up -d

log "=== Buat wrapper pi-node ==="
tee pi-node > /dev/null <<'EOF'
#!/bin/bash
set -euo pipefail
PI_FOLDER="/root/pi-node"
cd "$PI_FOLDER"

case "${1:-}" in
  status)
    sudo docker ps --filter "name=mainnet"
    ;;
  logs)
    sudo docker logs -f mainnet
    ;;
  start)
    sudo docker start mainnet
    ;;
  stop)
    sudo docker stop mainnet
    ;;
  restart)
    sudo docker restart mainnet
    ;;
  key)
    grep PRIVATE_KEY .env | cut -d'=' -f2
    ;;
  sync)
    echo "[INFO] Menunggu node sinkronisasi ledger penuh..."
    while true; do
      LEDGER=$(sudo docker exec mainnet curl -s http://localhost:8000/ledgers | jq '.ledgers | length')
      if [ "$LEDGER" -gt 0 ]; then
        echo "[INFO] Node sudah sinkron."
        break
      else
        echo "[INFO] Node belum sinkron, tunggu 30 detik..."
        sleep 30
      fi
    done
    ;;
  *)
    echo "Usage: pi-node {status|logs|start|stop|restart|key|sync}"
    ;;
esac
EOF
chmod +x pi-node
sudo mv pi-node /usr/local/bin/

log "=== Buat systemd service ==="
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

log "=== Buat script auto-update ==="
tee "$AUTO_UPDATE_SCRIPT" > /dev/null <<EOF
#!/bin/bash
set -euo pipefail
PI_FOLDER="$PI_FOLDER"
SERVICE_NAME="$SERVICE_NAME"

echo "[INFO] Memulai update Pi Node..."
cd "\$PI_FOLDER"
# backup .env & docker volumes
cp .env .env.backup_\$(date +%Y%m%d%H%M)
sudo docker compose down
sudo docker pull pinetwork/pi-node-docker:organization_mainnet-v1.2-p19.6
sudo docker compose up -d
echo "[INFO] Update selesai, node berjalan kembali."
EOF
sudo chmod +x "$AUTO_UPDATE_SCRIPT"

log "=== Jadwalkan cron auto-update setiap 6 jam ==="
(crontab -l 2>/dev/null; echo "0 */6 * * * $AUTO_UPDATE_SCRIPT >> /var/log/pi-node-auto-update.log 2>&1") | crontab -

log "🎉 Pi Node siap transaksi!"
log "Gunakan perintah:"
echo "  pi-node status   -> cek status node"
echo "  pi-node logs     -> lihat log realtime"
echo "  pi-node start    -> start node"
echo "  pi-node stop     -> stop node"
echo "  pi-node restart  -> restart node"
echo "  pi-node key      -> lihat private key node (untuk transaksi)"
echo "  pi-node sync     -> tunggu ledger penuh agar siap transaksi"
