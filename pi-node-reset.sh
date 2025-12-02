#!/bin/bash
set -euo pipefail

echo -e "\e[1;31m=== PI NODE FULL RESET ===\e[0m"
echo "Script ini akan menghapus SEMUA data Pi Node:"
echo "  - Container & image"
echo "  - Docker volumes"
echo "  - Folder /root/pi-node"
echo "  - Systemd service"
echo "  - Cron auto-update"
echo "  - Wrapper command pi-node"
echo ""
read -rp "LANJUTKAN? (yes/no): " confirm

if [[ "$confirm" != "yes" ]]; then
    echo "Dibatalkan."
    exit 0
fi

echo -e "\e[1;34m[1/10] Stop service Pi Node...\e[0m"
systemctl stop pi-node.service 2>/dev/null || true
systemctl disable pi-node.service 2>/dev/null || true

echo -e "\e[1;34m[2/10] Stop monitor service...\e[0m"
systemctl stop pi-node-monitor.service 2>/dev/null || true
systemctl disable pi-node-monitor.service 2>/dev/null || true

echo -e "\e[1;34m[3/10] Hapus container...\e[0m"
docker stop mainnet 2>/dev/null || true
docker rm -f mainnet 2>/dev/null || true

echo -e "\e[1;34m[4/10] Hapus image Pi Node...\e[0m"
docker rmi pinetwork/pi-node-docker:organization_mainnet-v1.2-p19.6 2>/dev/null || true

echo -e "\e[1;34m[5/10] Hapus docker volumes Pi Node...\e[0m"
rm -rf /root/pi-node/docker_volumes 2>/dev/null || true

echo -e "\e[1;34m[6/10] Hapus folder pi-node...\e[0m"
rm -rf /root/pi-node 2>/dev/null || true

echo -e "\e[1;34m[7/10] Hapus wrapper command pi-node...\e[0m"
rm -f /usr/local/bin/pi-node 2>/dev/null || true

echo -e "\e[1;34m[8/10] Hapus systemd service file...\e[0m"
rm -f /etc/systemd/system/pi-node.service 2>/dev/null || true
rm -f /etc/systemd/system/pi-node-monitor.service 2>/dev/null || true
systemctl daemon-reload

echo -e "\e[1;34m[9/10] Hapus cron auto-update...\e[0m"
crontab -l 2>/dev/null | grep -v "pi-node-auto-update.sh" | crontab - || true
rm -f /usr/local/bin/pi-node-auto-update.sh 2>/dev/null || true

echo -e "\e[1;34m[10/10] (Opsional) Bersihkan docker system...\e[0m"
docker system prune -a -f --volumes

echo -e "\e[1;32m=== PI NODE SUDAH DIHAPUS SEPENUHNYA ===\e[0m"
echo "Server Anda sekarang bersih dan siap install ulang."
