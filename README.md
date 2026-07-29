# 📱 APP Mobile Absensi & Presensi MTs (Flutter Cross-Platform)

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Backend](https://img.shields.io/badge/Backend-Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![QR Scanner](https://img.shields.io/badge/Scanner-Mobile%20Scanner-FF6F00?style=for-the-badge&logo=qrcode&logoColor=white)
![State Management](https://img.shields.io/badge/State-Provider-007ACC?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

> **Aplikasi Mobile Companion berbasis Flutter (Android & iOS)** untuk Sistem Informasi Absensi & Presensi Sekolah MTs. Dilengkapi dengan **Fitur QR Code / Barcode Scanner**, manajemen presensi guru, monitoring real-time orang tua murid, serta pengajuan surat izin/sakit berbasis Supabase.

---

## 📌 Tentang Aplikasi

Aplikasi mobile ini dirancang untuk mempermudah operasional harian sekolah di lapangan:
1. **Guru**: Memungkinkan pemindaian (*scan*) QR Code / Barcode kartu siswa secara instan untuk presensi masuk/pulang tanpa perlu pencatatan manual.
2. **Orang Tua / Wali Murid**: Memantau status kehadiran anak secara *real-time* serta mengajukan dokumen surat perizinan (sakit/izin) langsung dari *smartphone*.

Aplikasi ini berpasangan secara sempurna dengan dashboard pusat **`SIM-Dasbor-Absensi-Mts-Suguja` (Web & Desktop Admin)**.

---

## 🚀 Fitur-Fitur Utama

### 📷 1. Pemindai Presensi QR Code / Barcode (`mobile_scanner`)
* **Instant QR Scanning**: Pemindaian cepat kartu siswa menggunakan kamera *smartphone* guru.
* **Verifikasi Otomatis**: Pencatatan status kehadiran (*Hadir, Terlambat, Pulang*) langsung tersinkronisasi ke database Supabase.

### 👩‍🏫 2. Portal Guru & Pengajar
* **Pencatatan Kehadiran & Jurnal**: Guru dapat mencatat presensi kelas dan jurnal mengajar harian.
* **Filter & Rekapitulasi Kelas**: Pemantauan statistik tingkat kehadiran siswa per rombel kelas.

### 👨‍👩‍👧 3. Portal Orang Tua / Wali Murid
* **Real-time Attendance Monitoring**: Orang tua dapat melihat riwayat dan status presensi harian anak secara *live*.
* **Pengajuan Surat Izin & Sakit**: Pengunggahan foto/dokumen bukti surat izin dengan kompresi gambar otomatis (`flutter_image_compress`, `image_picker`).

### 🏗️ 4. Feature-First Clean Architecture
Aplikasi dibangun dengan arsitektur kode modern yang terisolasi dan *scalable*:
* **Feature Isolation**: Pemisahan modul fitur (*Auth, Presensi, Surat, Profile*).
* **Type-Safe Data Repositories & Services**: Integrasi aman dengan Supabase API Client.
* **Provider State Management**: Manajemen status aplikasi yang responsif dan hemat memori.

---

## 🌐 Ekosistem Pasangan Aplikasi Sekolah

```text
 💻 SIM-Dasbor-Absensi-Mts-Suguja (Web & Desktop Admin Dashboard)
 ─────────────────────────────────────────────────────────────
                               ▲
                               │ Supabase Cloud DB
                               ▼
 📱 APP-Mobile-Absensi-Mts-Suguja (Flutter Mobile Companion App)
```

---

## 🛠️ Stack Teknologi & Pustaka

| Komponen | Pustaka / Teknologi |
| :--- | :--- |
| **Framework Utama** | [Flutter 3.x](https://flutter.dev/) (Android & iOS) |
| **Bahasa Pemrograman** | Dart 3.x |
| **Backend & Auth** | Supabase Flutter (`supabase_flutter`) |
| **QR/Barcode Scanner** | Mobile Scanner (`mobile_scanner`) |
| **Media & Kompresi** | `image_picker`, `flutter_image_compress` |
| **State Management** | Provider (`provider`) |
| **Environment Config** | Flutter Dotenv (`flutter_dotenv`) |

---

## 📁 Struktur Kode Project

```text
lib/
├── core/                         # Konfigurasi Tema, Konstanta, & Utilities
├── data/                         # Repositories, Data Sources, & Supabase Services
├── features/                     # Modul Fitur Aplikasi
│   ├── auth/                     # Autentikasi (Login & Session)
│   ├── absensi/                  # QR Code Scanner & Log Presensi
│   ├── surat/                    # Form & Upload Surat Perizinan
│   └── profile/                  # Pengaturan Akun & Profil
└── main.dart                     # Entrypoint Aplikasi & Provider Setup
```

---

## ⚙️ Panduan Build & Running Project

### 1. Clone Repositori
```bash
git clone https://github.com/AndhikaBagus115/APP-Mobile-Absensi-Mts-Suguja.git
cd APP-Mobile-Absensi-Mts-Suguja
```

### 2. Konfigurasi Environment (`.env`)
Salin file `.env.example` menjadi `.env`:
```bash
cp .env.example .env
```
Isi kredensial Supabase pada `.env`:
```env
SUPABASE_URL=https://your-supabase-url.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
```

### 3. Install Dependency
```bash
flutter pub get
```

### 4. Jalankan di Smartphone / Emulator
Hubungkan perangkat Android/iOS fisik atau jalankan Emulator, lalu ketik:
```bash
flutter run
```

---

## 👨‍💻 Penulis & Lisensi

Dikembangkan oleh **Andhika Bagus Satria** & Tim sebagai Aplikasi Mobile Presensi Sekolah MTs.

* **Lisensi**: Open-source di bawah lisensi [MIT License](LICENSE).
