#!/bin/bash

set -euo pipefail
IFS=$'\n\t'

log() {
    echo -e "\e[1;34m[INFO]\e[0m $1"
}

error() {
    echo -e "\e[1;31m[ERROR]\e[0m $1" >&2
}

check_command() {
    if ! command -v "$1" &>/dev/null; then
        error "$1 tidak ditemukan. Install gagal."
        exit 1
    fi
}

# 1️⃣ Update sistem
log "Update & upgrade sistem..."
sudo apt update && sudo apt upgrade -y

# 2️⃣ Install dependencies
log "Install dependencies..."
sudo apt install -y curl gnupg lsb-release ca-certificates git wget

# 3️⃣ Install Docker & Docker Compose
log "Install Docker & Docker Compose..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
sudo systemctl enable docker
sudo systemctl start docker
check_command docker
log "Docker berhasil diinstall dan berjalan."

# 4️⃣ Install Pi Node
log "Tambahkan repo Pi Node & install..."
curl -fsSL https://apt.minepi.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/minepi-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/minepi-archive-keyring.gpg] https://apt.minepi.com stable main" | sudo tee /etc/apt/sources.list.d/minepi.list
sudo apt update
sudo apt install -y pi-node
check_command pi-node
log "Pi Node berhasil diinstall."

# 5️⃣ Buat folder node & docker volumes
PI_FOLDER="/root/pi-node"
DOCKER_VOLUMES="$PI_FOLDER/docker_volumes"
log "Buat folder node: $PI_FOLDER dan docker volumes: $DOCKER_VOLUMES..."
sudo mkdir -p "$DOCKER_VOLUMES"

# 6️⃣ Initialize Pi Node
log "Initialize Pi Node (force overwrite jika ada)..."
pi-node initialize \
  --pi-folder "$PI_FOLDER" \
  --docker-volumes "$DOCKER_VOLUMES" \
  --auto-confirm \
  --setup-auto-updates \
  --start-node \
  --force

# 7️⃣ Jalankan node dengan Docker Compose
log "Jalankan Pi Node dengan Docker Compose..."
cd "$PI_FOLDER"
sudo docker compose up -d

# 8️⃣ Aktifkan auto-start node saat reboot
log "Enable auto-start Docker Compose container..."
sudo systemctl enable docker
sudo docker compose -f "$PI_FOLDER/docker-compose.yml" up -d

# 9️⃣ Cek status node
log "Cek status node..."
pi-node status

log "🎉 Pi Node berhasil diinstall dan berjalan!"
