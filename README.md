
# Pi Node Ubuntu 24.04 Installer

![Pi Network Logo](https://minepi.com/favicon.ico)

Skrip ini mempermudah instalasi **Pi Node (Official Version)** pada sistem **Ubuntu 24.04**. Semua langkah, mulai dari instalasi dependensi hingga inisialisasi node, telah diotomatisasi dengan `run.sh`.

---

## 🔹 Fitur

- Instalasi semua dependensi yang diperlukan
- Setup Docker CE (container runtime untuk Pi Node)
- Menambahkan repository resmi Pi Network
- Instalasi Pi Node CLI resmi
- Inisialisasi node untuk mulai berpartisipasi dalam jaringan Pi

---

## 📦 Persyaratan

- Sistem: **Ubuntu 24.04 LTS**
- Akses **root** atau **sudo**
- Koneksi internet stabil

---

## ⚡ Instalasi

1. **Clone repository**

```bash
git clone https://github.com/zendshost/Pi-Node-Ubuntu-24.04.git
cd Pi-Node-Ubuntu-24.04
````

2. **Jalankan skrip instalasi**

```bash
sudo bash run.sh
```

Skrip akan melakukan langkah-langkah berikut:

1. Install dependensi (`ca-certificates`, `curl`, `gnupg`)
2. Menambahkan GPG key Docker
3. Menambahkan repository Docker
4. Install Docker CE
5. Start dan enable Docker service
6. Tambah GPG key Pi Network repository
7. Tambah repository Pi Network
8. Install Pi Node CLI
9. Tampilkan informasi repo dan versi
10. Initialize Pi Node

---

## 🛠️ Penggunaan

Setelah instalasi selesai:

* Masuk ke folder node:

```bash
cd /root/pi-node
```

* Cek status node:

```bash
pi-node status
```

Node Anda sekarang siap digunakan di jaringan Pi.

---

## ✅ Cek Versi

Untuk memastikan Pi Node terpasang dengan benar:

```bash
pi-node --version
```

---

## 💡 Catatan

* Pastikan Docker berjalan sebelum memulai node.
* Gunakan user dengan hak akses `sudo` untuk instalasi.
* Skrip ini dirancang khusus untuk **Ubuntu 24.04** dan arsitektur **amd64**.

---

## 📜 Lisensi

Repository ini bersifat **open-source**. Gunakan dan modifikasi sesuai kebutuhan Anda.

---

## 🔗 Link Repository

[https://github.com/zendshost/Pi-Node-Ubuntu-24.04](https://github.com/zendshost/Pi-Node-Ubuntu-24.04.git)


Apakah mau saya buatkan versi itu juga?
```
