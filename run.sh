#!/bin/bash
set -euo pipefail

echo -e "\e[1;34m[INFO] Instalasi / Upgrade Pi Node (Official Version)\e[0m"

###############################################
# 1. Install dependencies
###############################################
echo -e "\e[1;32m[1/10] Install dependencies...\e[0m"
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

###############################################
# 2. Install Docker jika belum ada
###############################################
if ! command -v docker &> /dev/null; then
    echo -e "\e[1;32m[2/10] Install Docker...\e[0m"
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
      | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    sudo systemctl enable --now docker
else
    echo -e "\e[1;33mDocker sudah terinstal, lanjut...\e[0m"
fi

###############################################
# 3. Tambah Pi Network repo jika belum ada
###############################################
if [ ! -f /etc/apt/sources.list.d/pinetwork.list ]; then
    echo -e "\e[1;32m[3/10] Tambah repo Pi Network...\e[0m"
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://apt.minepi.com/repository.gpg.key \
      | sudo gpg --dearmor -o /etc/apt/keyrings/pinetwork-archive-keyring.gpg
    sudo chmod a+r /etc/apt/keyrings/pinetwork-archive-keyring.gpg
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/pinetwork-archive-keyring.gpg] https://apt.minepi.com stable main" \
      | sudo tee /etc/apt/sources.list.d/pinetwork.list > /dev/null
fi

###############################################
# 4. Install / Upgrade pi-node CLI
###############################################
echo -e "\e[1;32m[4/10] Install / Upgrade pi-node CLI...\e[0m"
sudo apt update
sudo apt install -y pi-node
pi-node --version

###############################################
# 5. Backup node lama jika ada
###############################################
if [ -d "$HOME/pi-node" ]; then
    echo -e "\e[1;33mBackup data node lama...\e[0m"
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    mv "$HOME/pi-node" "$HOME/pi-node-backup-$TIMESTAMP"
fi

###############################################
# 6. Stop container lama jika ada
###############################################
if docker ps -a --format '{{.Names}}' | grep -q '^mainnet$'; then
    echo -e "\e[1;33mStop container lama...\e[0m"
    docker stop mainnet || true
    docker rm mainnet || true
fi

###############################################
# 7. Initialize / Upgrade node
###############################################
echo -e "\e[1;32m[5/10] Initialize / Upgrade Pi Node...\e[0m"
pi-node initialize

###############################################
# 8. Tunggu node & Horizon siap
###############################################
echo "Menunggu Horizon siap..."
while true; do
    STATUS=$(pi-node status | grep "Horizon Status" -A2 | grep "Status" | awk '{print $2}')
    if [ "$STATUS" == "✅" ]; then
        echo -e "\e[1;32mHorizon sudah running.\e[0m"
        break
    else
        echo -e "\e[1;33mMenunggu Horizon siap, cek lagi dalam 15 detik...\e[0m"
        sleep 15
    fi
done

echo
echo -e "\e[1;32mNode Pi Network siap digunakan!\e[0m"
echo "Cek status node: pi-node status"
echo "Masuk folder node: cd /root/pi-node"
