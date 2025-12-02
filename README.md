# Pi Node Ubuntu 24.04

Script ini otomatis menginstal **Pi Network Node** di Ubuntu 24.04, lengkap dengan:

- Docker & Docker Compose
- Folder node dan docker volumes
- Pi Node container (Mainnet)
- Systemd service untuk auto-start node
- Smart monitoring script untuk cek ledger & kirim notifikasi ke Telegram

---

## Persyaratan

- Ubuntu 24.04 minimal
- Akses root / sudo
- Koneksi internet stabil
- Akun Telegram dan bot Telegram untuk notifikasi

---

## Instalasi

1. **Clone repository**

```bash
git clone https://github.com/zendshost/Pi-Node-Ubuntu-24.04.git
cd Pi-Node-Ubuntu-24.04
````

2. **Jalankan script instalasi**

```bash
sudo bash install_pi_node.sh
```

> Script akan meminta:
>
> * **Token bot Telegram**
> * **Chat ID Telegram**

Script akan otomatis:

* Update & install dependencies
* Install Docker & Compose
* Buat folder node dan docker volumes
* Buat file `.env` dengan PostgreSQL password dan node private key
* Buat docker-compose.yml untuk Pi Node Mainnet
* Inisialisasi node
* Buat systemd service untuk node & smart monitoring
* Jalankan node dan monitoring otomatis

---

## Perintah penting

* **Cek status node Pi**:

```bash
sudo systemctl status pi-node.service
```

* **Cek log node realtime**:

```bash
sudo docker logs -f mainnet
```

* **Cek status monitoring Telegram**:

```bash
sudo systemctl status pi-node-monitor.service
```

---

## Informasi tambahan

* Private key node **tidak sama** dengan akun Pi di aplikasi.
* Node akan berjalan terus **walau logout atau reboot**.
* Monitoring Telegram akan mengirimkan notifikasi ketika ledger sinkron atau belum.
* Ledger sync bisa memakan waktu beberapa jam tergantung koneksi dan spesifikasi server.

---

## Reset Node / Reinstall

Jika ingin mengulang instalasi node, gunakan:

```bash
sudo pi-node initialize --force
```

> Hati-hati, ini akan overwrite konfigurasi node yang ada.

---

## Disclaimer

Script ini dibuat untuk **node operator** Pi Network.
Tidak digunakan untuk transaksi akun pribadi di aplikasi Pi Network.

---

## Repository

[https://github.com/zendshost/Pi-Node-Ubuntu-24.04](https://github.com/zendshost/Pi-Node-Ubuntu-24.04.git)

---
