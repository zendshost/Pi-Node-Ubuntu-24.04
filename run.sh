#!/bin/bash
set -euo pipefail

echo -e "\e[1;34m[INFO] Instalasi Pi Node (Official Version)\e[0m"

###############################################
# 1. Install dependencies
###############################################
echo -e "\e[1;32m[1/10] Install dependencies...\e[0m"
sudo apt update
sudo apt install -y ca-certificates curl gnupg

###############################################
# 2. Tambah GPG key Docker
###############################################
echo -e "\e[1;32m[2/10] Tambah Docker GPG key...\e[0m"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
 | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

###############################################
# 3. Tambah repository Docker
###############################################
echo -e "\e[1;32m[3/10] Tambah repo Docker...\e[0m"
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

###############################################
# 4. Install Docker CE
###############################################
echo -e "\e[1;32m[4/10] Install Docker...\e[0m"
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

###############################################
# 5. Start & enable Docker
###############################################
echo -e "\e[1;32m[5/10] Aktifkan Docker...\e[0m"
sudo systemctl start docker
sudo systemctl enable docker
sudo systemctl status docker --no-pager

###############################################
# 6. Tambah GPG Key Pi Network Repo
###############################################
echo -e "\e[1;32m[6/10] Tambah GPG repo Pi Network...\e[0m"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://apt.minepi.com/repository.gpg.key \
 | sudo gpg --dearmor -o /etc/apt/keyrings/pinetwork-archive-keyring.gpg
sudo chmod a+r /etc/apt/keyrings/pinetwork-archive-keyring.gpg

###############################################
# 7. Tambah repository Pi Network
###############################################
echo -e "\e[1;32m[7/10] Tambah repo apt Pi Network...\e[0m"
sudo rm -f /etc/apt/sources.list.d/pinetwork.list
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/pinetwork-archive-keyring.gpg] https://apt.minepi.com stable main" \
 | sudo tee /etc/apt/sources.list.d/pinetwork.list > /dev/null

###############################################
# 8. Install pi-node CLI (official)
###############################################
echo -e "\e[1;32m[8/10] Update & install Pi Node CLI...\e[0m"
sudo apt update
sudo apt install -y pi-node

###############################################
# 9. Tampilkan informasi repo dan versi
###############################################
echo -e "\e[1;32m[9/10] Cek repo & versi pi-node...\e[0m"
ls -l /etc/apt/sources.list.d/
cat /etc/apt/sources.list.d/pinetwork.list
pi-node --version

###############################################
# 10. Initialize Pi Node
###############################################
echo -e "\e[1;32m[10/10] Initialize Pi Node...\e[0m"
pi-node initialize

echo -e "\e[1;36m=== Instalasi selesai ===\e[0m"
echo "Masuk folder node:"
echo "   cd /root/pi-node"
echo
echo "Cek status node:"
echo "   pi-node status"
echo
echo -e "\e[1;32mPi Node siap digunakan.\e[0m"
