#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

# ======================
# Fungsi log
# ======================
log() { echo -e "\e[1;34m[INFO]\e[0m $1"; }
error() { echo -e "\e[1;31m[ERROR]\e[0m $1" >&2; }

# ======================
# Konfigurasi
# ======================
PI_FOLDER="/root/pi-node"
DOCKER_VOLUMES="$PI_FOLDER/docker_volumes"
SERVICE_NAME="pi-node.service"

# Ambil private key Pi dari user
read -p "Masukkan PRIVATE KEY Pi Anda: " NODE_PRIVATE_KEY

# Generate random PostgreSQL password
PG_PASSWORD=$(openssl rand -base64 24)

# ======================
# Update & Install dependencies
# ======================
log "=== Update & install dependencies ==="
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl gnupg lsb-release ca-certificates git wget cron openssl

# ======================
# Install Docker & Compose
# ======================
log "=== Install Docker & Compose ==="
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl enable docker
sudo systemctl start docker

# ======================
# Tambahkan repo Pi Node & install
# ======================
log "=== Tambahkan repo Pi Node & install ==="
curl -fsSL https://apt.minepi.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/minepi-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/minepi-archive-keyring.gpg] https://apt.minepi.com stable main" | sudo tee /etc/apt/sources.list.d/minepi.list
sudo apt update
sudo apt install -y pi-node

# ======================
# Buat folder node & docker volumes
# ======================
log "=== Buat folder node & docker volumes ==="
sudo mkdir -p "$DOCKER_VOLUMES/mainnet/stellar"
sudo mkdir -p "$DOCKER_VOLUMES/mainnet/supervisor_logs"
sudo mkdir -p "$DOCKER_VOLUMES/mainnet/history"

# ======================
# Initialize Pi Node
# ======================
log "=== Initialize Pi Node (auto-confirm) ==="
pi-node initialize \
  --pi-folder "$PI_FOLDER" \
  --docker-volumes "$DOCKER_VOLUMES" \
  --auto-confirm \
  --setup-auto-updates \
  --start-node \
  --node-private-key "$NODE_PRIVATE_KEY" \
  --postgres-password "$PG_PASSWORD" \
  --force

# ======================
# Buat docker-compose.yml sesuai cara pertama
# ======================
cat <<EOF > "$PI_FOLDER/docker-compose.yml"
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

# ======================
# Jalankan container mainnet
# ======================
log "=== Jalankan container mainnet ==="
cd "$PI_FOLDER"
sudo docker compose up -d

# ======================
# Buat systemd service agar otomatis start saat boot
# ======================
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

# ======================
# Buat script auto-update Pi Node
# ======================
log "=== Buat script auto-update Pi Node ==="
AUTO_UPDATE_SCRIPT="/usr/local/bin/pi-node-auto-update.sh"
sudo tee "$AUTO_UPDATE_SCRIPT" > /dev/null <<EOF
#!/bin/bash
set -euo pipefail
PI_FOLDER="$PI_FOLDER"
SERVICE_NAME="$SERVICE_NAME"

echo "[INFO] Memulai update Pi Node..."
sudo apt update
sudo apt install -y pi-node
sudo systemctl restart "\$SERVICE_NAME"
EOF
sudo chmod +x "$AUTO_UPDATE_SCRIPT"

# ======================
# Jadwalkan cron job auto-update setiap 6 jam
# ======================
log "=== Jadwalkan cron job auto-update setiap 6 jam ==="
(crontab -l 2>/dev/null; echo "0 */6 * * * $AUTO_UPDATE_SCRIPT >> /var/log/pi-node-auto-update.log 2>&1") | crontab -

log "🎉 Pi Node siap dijalankan & siap transaksi!"
log "Pantau node realtime: sudo journalctl -u $SERVICE_NAME -f"
log "Pantau log auto-update: tail -f /var/log/pi-node-auto-update.log"
