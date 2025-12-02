# Pi Node Ubuntu 24.04 Installer 🚀

![Pi Network Logo](https://minepi.com/favicon.ico)

Automatis installer untuk **Pi Node (Official Version)** di **Ubuntu 24.04 LTS**.  
Memudahkan setup node dari awal hingga siap menjalankan protokol Pi.

---

## 🔥 Status Proyek

| Component | Status |
|-----------|--------|
| Docker    | ![Docker](https://img.shields.io/badge/Docker-Installed-blue) |
| Pi Node   | ![Pi Node](https://img.shields.io/badge/Pi_Node-Ready-brightgreen) |
| Ubuntu   | ![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04-orange) |

---

## 📦 Fitur Utama

- Install dependensi (`ca-certificates`, `curl`, `gnupg`)
- Setup Docker CE (container runtime)
- Tambahkan repository resmi Pi Network
- Instalasi Pi Node CLI resmi
- Initialize node untuk berpartisipasi dalam jaringan
- Reset Horizon database jika perlu
- Monitoring status node & ledger

---

## ⚙️ Persyaratan

- Ubuntu 24.04 LTS (amd64)  
- User dengan hak akses `sudo` atau `root`  
- Koneksi internet stabil  
- Minimal 2GB RAM (disarankan 4GB+)  
- Storage minimal 10GB  

---

## 🚀 Cara Instalasi

1. **Clone repository**

```bash
git clone https://github.com/zendshost/Pi-Node-Ubuntu-24.04.git
cd Pi-Node-Ubuntu-24.04
````

2. **Jalankan skrip instalasi**

```bash
sudo bash run.sh
```

Skrip akan otomatis:

1. Install dependensi
2. Tambah GPG key & repository Docker
3. Install Docker CE
4. Aktifkan service Docker
5. Tambah GPG key & repository Pi Network
6. Install Pi Node CLI
7. Tampilkan repo & versi
8. Initialize Pi Node

---

## 🛠️ Penggunaan

* Masuk ke folder node:

```bash
cd /root/pi-node
```

* Cek status node:

```bash
pi-node status
```

Jika berhasil, output awal akan terlihat seperti ini (**node baru**):

```
🐳 Container Status
==================
✅ Container: mainnet (Running)

⭐ Protocol Status
=================
State: Catching up
Status: Waiting for trigger ledger: 24004633/24004673, ETA: 200s
Ledger: 1
Quorum Ledger: 24004632

🌅 Horizon Status
=================
Status: ✅ Running
Core Latest Ledger: 1
History Latest Ledger: Not synced
Ingest Latest Ledger: Not synced

🌐 Peer Connections
==================
Incoming: 1 peers
Outgoing: 56 peers
```

---

## ⚠️ Node Baru vs Node Siap Digunakan

### Node Baru (Belum Sinkron)

* Node **belum bisa melakukan transaksi**.
* Ledger mulai dari 1, perlu proses ingestion dari checkpoint.
* Proses sinkronisasi bisa memakan waktu **±1–2 hari**, tergantung performa server dan koneksi.

### Node Siap Digunakan

* Setelah sinkronisasi selesai, ledger sudah up-to-date.
* Node sekarang **siap melakukan transaksi**.

---

## 🔄 Reset Horizon Database

Jika Horizon error atau ingestion macet, lakukan **reset Horizon**:

```bash
sudo bash reset-horizon.sh
```

Proses ini akan:

1. Stop Horizon & Stellar-Core
2. Terminate semua koneksi ke database Horizon
3. Drop & recreate database Horizon
4. Hapus cache dan history Horizon
5. Restart Stellar-Core & Horizon

Setelah reset, node akan mulai ingest ledger dari awal.

---

## 🗺️ Diagram Alur Sinkronisasi Node (GitHub-Compatible)

```mermaid
flowchart TD
    A[Initialize Node] --> B[Catching Up Ledger]
    B --> C[Ledger Sync in Progress]
    C --> D[Synced with Network]
    D --> E[Node Ready for Transactions]

    %% Teks sederhana sebagai contoh status
    B -->|Ledger 0| B_note[Starting ledger]
    C -->|Ledger increasing| C_note[Updating ledger]
    D -->|Ledger up-to-date| D_note[Ledger synced]
```

**Penjelasan Tahap:**

1. **Initialize Node**: Node baru di-install, ledger belum sinkron.
2. **Catching Up Ledger**: Node mulai mengunduh ledger dari jaringan.
3. **Ledger Sync in Progress**: Ledger meningkat bertahap, node belum bisa transaksi penuh.
4. **Synced with Network**: Node sudah sinkron dengan ledger terbaru jaringan.
5. **Node Ready for Transactions**: Node siap digunakan untuk transaksi.

---

## ✅ Cek Versi Pi Node

```bash
pi-node --version
```

---

## 💡 Tips

* Pastikan Docker aktif:

```bash
sudo systemctl status docker
```

* Jalankan node secara rutin agar ledger cepat sinkron.
* Gunakan user dengan hak `sudo` selama instalasi.
* Jika ingestion macet, gunakan `reset-horizon.sh` untuk restart proses.

---

## 📜 Lisensi

Open-source, bebas digunakan dan dimodifikasi sesuai kebutuhan.

---

## 🔗 Repository

[https://github.com/zendshost/Pi-Node-Ubuntu-24.04](https://github.com/zendshost/Pi-Node-Ubuntu-24.04.git)

---

Made with ❤️ for Pi Network ZendsHost
