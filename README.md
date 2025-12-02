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

Jika berhasil, Anda akan melihat output seperti ini:

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

* Gunakan user dengan hak `sudo` selama instalasi.
* Jalankan node secara rutin agar ledger cepat sinkron.

---

## 📜 Lisensi

Open-source, bebas digunakan dan dimodifikasi sesuai kebutuhan.

---

## 🔗 Repository

[https://github.com/zendshost/Pi-Node-Ubuntu-24.04](https://github.com/zendshost/Pi-Node-Ubuntu-24.04.git)

---

Made with ❤️ for Pi Network ZendsHost
