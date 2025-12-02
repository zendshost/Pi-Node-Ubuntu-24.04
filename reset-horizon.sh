#!/bin/bash
set -euo pipefail

echo -e "\e[1;34m[INFO] Reset Horizon Database Pi Node\e[0m"

# Masuk container mainnet
CONTAINER="mainnet"
echo -e "\e[1;32m[1/6] Masuk container $CONTAINER\e[0m"

docker exec -it $CONTAINER bash -c "

echo '[2/6] Stop Horizon & Stellar-Core'
supervisorctl stop horizon
supervisorctl stop stellar-core

echo '[3/6] Terminate koneksi database Horizon'
su - postgres -c \"psql -c \\\"SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='horizon';\\\"\"

echo '[4/6] Drop dan recreate database Horizon'
su - postgres -c \"dropdb horizon || true\"
su - postgres -c \"createdb horizon\"

echo '[5/6] Start Stellar-Core & Horizon'
supervisorctl start stellar-core
supervisorctl start horizon

echo '[6/6] Proses reset selesai, cek status node'
pi-node status
"
