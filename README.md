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

Jika berhasil, output awal akan terlihat seperti ini (node **baru**):

```
🐳 Container Status
==================
✅ Container: mainnet (Running)

⭐ Protocol Status
=================
State: Catching up
Status: Catching up to ledger 24001791: Applying buckets 7%. Currently on level 10
Ledger: 1
Quorum Ledger: 24001849

🌅 Horizon Status
=================
Status: ✅ Running
Core Latest Ledger: 1
History Latest Ledger: Not synced
Ingest Latest Ledger: Not synced

🌐 Peer Connections
==================
Incoming: 5 peers
Outgoing: 57 peers
```

---

## ⚠️ Node Baru vs Node Siap Digunakan

### Node Baru (Belum Sinkron)

* Node **belum bisa melakukan transaksi**.
* Perlu waktu **±1–2 hari** untuk menyinkronkan ledger dengan jaringan.
* Cek status JSON secara berkala:

```json
{
  "horizon_version": "2.23.1-6def2295c2e739883f028b5098c30d82969a94a5",
  "core_version": "stellar-core 19.6.0",
  "ingest_latest_ledger": 0,
  "history_latest_ledger": 0,
  "core_latest_ledger": 1,
  "network_passphrase": "Pi Network",
  "current_protocol_version": 0,
  "supported_protocol_version": 19
}
```

### Node Siap Digunakan

Setelah sinkronisasi selesai, JSON status akan menunjukkan ledger terbaru:

```json
{
  "horizon_version": "2.23.1-6def2295c2e739883f028b5098c30d82969a94a5",
  "core_version": "stellar-core 19.6.0",
  "ingest_latest_ledger": 24001909,
  "history_latest_ledger": 24001909,
  "history_latest_ledger_closed_at": "2025-12-02T13:22:06Z",
  "history_elder_ledger": 22488704,
  "core_latest_ledger": 24001909,
  "network_passphrase": "Pi Network",
  "current_protocol_version": 19,
  "supported_protocol_version": 19,
  "core_supported_protocol_version": 19
}
```

* Node sekarang **siap melakukan transaksi**.
* Ledger dan status protokol sudah sinkron dengan jaringan.

---

## 🗺️ Diagram Alur Sinkronisasi Node

```mermaid
flowchart TD
    A[Initialize Node] --> B[Catching Up Ledger]
    B --> C[Ledger Sync in Progress]
    C --> D[Synced with Network]
    D --> E[Node Ready for Transactions]

    %% Status JSON examples
    B -->|ingest_latest_ledger = 0| B_note[{"ingest_latest_ledger":0, "history_latest_ledger":0}]
    C -->|ledger increasing| C_note[{"ingest_latest_ledger":24001000, "history_latest_ledger":24001000}]
    D -->|ledger up to date| D_note[{"ingest_latest_ledger":24001909, "history_latest_ledger":24001909}]
```

**Penjelasan Tahap:**

1. **Initialize Node**: Node baru saja di-install. Ledger belum sinkron.
2. **Catching Up Ledger**: Node mulai mengunduh ledger dari jaringan. Status `Catching up`.
3. **Ledger Sync in Progress**: Ledger meningkat bertahap. Node masih belum bisa transaksi.
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

---

## 📜 Lisensi

Open-source, bebas digunakan dan dimodifikasi sesuai kebutuhan.

---

## 🔗 Repository

[https://github.com/zendshost/Pi-Node-Ubuntu-24.04](https://github.com/zendshost/Pi-Node-Ubuntu-24.04.git)

---

Made with ❤️ for Pi Network ZendsHost
