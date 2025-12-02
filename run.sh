#!/bin/bash
set -euo pipefail

echo -e "\e[1;34m[INFO] Instalasi Pi Node (Official Version)\e[0m"

###############################################
# 0. Bersihkan folder node lama (opsional tapi direkomendasikan)
###############################################
if [ -d "/root/pi-node" ]; then
    echo -e "\e[1;33m[0/11] Menghapus folder node lama...\e[0m"
    sudo rm -rf /root/pi-node
fi

###############################################
# 1. Install dependencies
###############################################
echo -e "\e[1;32m[1/11] Install dependencies...\e[0m"
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release apt-transport-https

###############################################
# 2. Tambah folder keyrings
###############################################
sudo install -m 0755 -d /etc/apt/keyrings

###############################################
# 3. Tambah GPG key Docker
###############################################
echo -e "\e[1;32m[2/11] Tambah Docker GPG key...\e[0m"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
 | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

###############################################
# 4. Tambah repository Docker
###############################################
echo -e "\e[1;32m[3/11] Tambah repo Docker...\e[0m"
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
 $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

###############################################
# 5. Install Docker CE
###############################################
echo -e "\e[1;32m[4/11] Install Docker...\e[0m"
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

###############################################
# 6. Start & enable Docker
###############################################
echo -e "\e[1;32m[5/11] Aktifkan Docker...\e[0m"
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
sudo systemctl status docker --no-pager

###############################################
# 7. Tambah GPG Key Pi Network Repo
###############################################
echo -e "\e[1;32m[6/11] Tambah GPG repo Pi Network...\e[0m"
curl -fsSL https://apt.minepi.com/repository.gpg.key \
 | sudo gpg --dearmor -o /etc/apt/keyrings/pinetwork-archive-keyring.gpg
sudo chmod a+r /etc/apt/keyrings/pinetwork-archive-keyring.gpg

###############################################
# 8. Tambah repository Pi Network
###############################################
echo -e "\e[1;32m[7/11] Tambah repo apt Pi Network...\e[0m"
sudo rm -f /etc/apt/sources.list.d/pinetwork.list
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/pinetwork-archive-keyring.gpg] https://apt.minepi.com stable main" \
 | sudo tee /etc/apt/sources.list.d/pinetwork.list > /dev/null

###############################################
# 9. Install pi-node CLI (official)
###############################################
echo -e "\e[1;32m[8/11] Update & install Pi Node CLI...\e[0m"
sudo apt update
sudo apt install -y pi-node

###############################################
# 10. Initialize Pi Node
###############################################
echo -e "\e[1;32m[9/11] Initialize Pi Node...\e[0m"
pi-node initialize

###############################################
# 11. Start Pi Node otomatis
###############################################
echo -e "\e[1;32m[10/11] Start Pi Node...\e[0m"
pi-node start

# Tunggu sebentar & cek status
sleep 5
pi-node status

###############################################
# 12. Informasi selesai
###############################################
echo -e "\e[1;36m=== Instalasi selesai ===\e[0m"
echo "Masuk folder node:"
echo "   cd /root/pi-node"
echo
echo "Cek status node:"
echo "   pi-node status"
echo
echo -e "\e[1;32mPi Node siap digunakan dan otomatis berjalan.\e[0m"
