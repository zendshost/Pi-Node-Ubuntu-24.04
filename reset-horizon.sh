#!/bin/bash
set -euo pipefail

echo -e "\e[1;34m[INFO] Full Reset Horizon Database Pi Node\e[0m"

CONTAINER="mainnet"

echo -e "\e[1;32m[1/5] Stop Horizon & Stellar-Core\e[0m"
docker exec -it $CONTAINER bash -c "
supervisorctl stop horizon
supervisorctl stop stellar-core
"

echo -e "\e[1;32m[2/5] Terminate semua koneksi ke database Horizon\e[0m"
docker exec -it $CONTAINER bash -c "
su - postgres -c \"psql -c \\\"SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='horizon';\\\"\"
"

echo -e "\e[1;32m[3/5] Drop & recreate database Horizon\e[0m"
docker exec -it $CONTAINER bash -c "
su - postgres -c 'dropdb horizon || true'
su - postgres -c 'createdb horizon'
"

echo -e "\e[1;32m[4/5] Hapus cache dan history Horizon\e[0m"
docker exec -it $CONTAINER bash -c "
rm -rf /root/.local/share/horizon/*
"

echo -e "\e[1;32m[5/5] Restart Stellar-Core & Horizon\e[0m"
docker exec -it $CONTAINER bash -c "
supervisorctl start stellar-core
supervisorctl start horizon
"

echo -e "\e[1;36m=== Reset selesai ===\e[0m"
echo "Cek status node dengan:"
echo "   pi-node status"
