# 📱 Aplikasi Mobile Absensi & Presensi MTs Sunan Gunung Jati

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Backend](https://img.shields.io/badge/Backend-Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![Notifications](https://img.shields.io/badge/Push_Notif-OneSignal-E54B4D?style=for-the-badge&logo=onesignal&logoColor=white)
![Scanner](https://img.shields.io/badge/Scanner-Mobile_Scanner_v7-FF6F00?style=for-the-badge&logo=qrcode&logoColor=white)
![Design](https://img.shields.io/badge/UI-Material_3-7C3AED?style=for-the-badge&logo=materialdesign&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

> **Aplikasi Mobile Multi-Role berbasis Flutter (Android & iOS)** untuk Sistem Informasi Absensi & Presensi Sekolah MTs Sunan Gunung Jati. Dilengkapi dengan **Continuous QR/Barcode Scanner**, portal pemantauan siswa untuk Guru & Wali Kelas, persetujuan surat izin/sakit digital, sistem multi-anak untuk Wali Murid, serta integrasi **Push Notification OneSignal & Supabase Cloud**.

---

## 📌 Ringkasan Proyek

Aplikasi mobile ini dirancang sebagai solusi *mobile companion* yang komprehensif, modern, dan andal untuk operasional harian sekolah:
1. **Guru & Wali Kelas**: Mengelola presensi harian siswa per kelas, meninjau dan memvalidasi pengajuan surat izin/sakit, mengedit status kehadiran manual disertai catatan guru, serta memperbarui profil pribadi.
2. **Admin / Petugas Scanner Gerbang**: Melakukan pemindaian (*scan*) QR Code / Barcode kartu pelajar siswa secara cepat dan kontinu (*continuous scanning*) dengan verifikasi instan.
3. **Orang Tua / Wali Murid**: Memantau status kehadiran harian anak secara *real-time*, mengelola lebih dari satu anak (*multi-child switcher*), melihat statistik absensi bulanan & grafik kehadiran, menerima pengumuman resmi sekolah, serta mengajukan surat izin/sakit dengan lampiran foto terkompresi.

Aplikasi ini terhubung langsung secara *real-time* dengan database Supabase Cloud dan bekerja berdampingan dengan dashboard admin web/desktop **`SIM-Dasbor-Absensi-Mts-Suguja`**.

---

## 🌐 Ekosistem Arsitektur Sistem

```text
       ┌───────────────────────────────────────────────────────────┐
       │   💻 SIM-Dasbor-Absensi-Mts-Suguja (Web & Desktop Admin)   │
       └─────────────────────────────┬─────────────────────────────┘
                                     │
                                     ▼
                   ┌───────────────────────────────────┐
                   │    ☁️ SUPABASE CLOUD BACKEND       │
                   │  - PostgreSQL Database            │
                   │  - Row Level Security & Auth      │
                   │  - Storage (Foto Profil & Surat)  │
                   │  - Edge Functions Trigger         │
                   └───────────────┬─┬─────────────────┘
                                   │ │
                 ┌─────────────────┘ └─────────────────┐
                 │                                     │
                 ▼                                     ▼
   ┌───────────────────────────┐         ┌───────────────────────────┐
   │ 🔔 ONESIGNAL PUSH CLOUD   │         │ 📱 FLUTTER MOBILE APP     │
   │ - Real-time Attendance    │ ◄────── │ - Portal Guru & Wali Kls  │
   │ - Surat Approval Alerts   │         │ - Portal Wali Murid       │
   │ - Broadcast Pengumuman    │ ──────► │ - Continuous QR Scanner   │
   └───────────────────────────┘         └───────────────────────────┘
```

---

## 🚀 Fitur Unggulan Berdasarkan Peran

### 👨‍🏫 1. Portal Guru & Wali Kelas (`/features/auth`, `/features/kelas`, `/features/profil`)
* **Dashboard Interaktif & Ringkasan Harian**: Menampilkan statistik kehadiran (Hadir, Sakit, Izin, Alfa, Terlambat) secara langsung dengan *Animated Counter* dan sistem *Lifecycle Auto-Refresh*.
* **Manajemen Kelas & Rekap Siswa**: Filter daftar siswa berdasarkan kelas yang diampu atau seluruh kelas, pencarian siswa *instant debounce*, serta status kehadiran harian.
* **Edit Kehadiran Manual & Catatan Guru**: Penyesuaian status kehadiran siswa dengan tombol cepat (*Quick Pills*) dan input catatan keterangan guru.
* **Persetujuan Surat Izin & Sakit (`/features/persetujuan_surat`)**:
  * Tab filter status: *Menunggu*, *Disetujui*, *Ditolak*, dan *Semua*.
  * Preview foto lampiran surat dokter/keterangan dengan *pinch-to-zoom*.
  * Konfirmasi persetujuan/penolakan dengan catatan feedback yang otomatis terkirim ke orang tua melalui OneSignal.
* **Manajemen Profil Guru (`/features/profil`)**:
  * Ubah nama, kontak No. HP/WhatsApp, dan email.
  * Upload foto avatar profil dengan kompresi gambar otomatis (`flutter_image_compress`).
  * Ganti kata sandi akun secara aman.

---

### 📷 2. Continuous QR & Barcode Scanner (`/features/scanner`)
* **Continuous Scanning Engine**: Pemindaian kartu pelajar tanpa henti menggunakan pustaka performa tinggi `mobile_scanner` v7.
* **Per-NIS Smart Debounce**: Menghindari pemindaian ganda untuk siswa yang sama dalam interval waktu tertentu.
* **Visual & Haptic Feedback**: Animasi laser bergerak, border glowing indikator (hijau untuk hadir, oranye untuk pulang, merah untuk error), serta *haptic vibration*.
* **Popup Konfirmasi Cepat**: Menampilkan nama siswa, NIS, status, dan waktu scan secara instan tanpa menghentikan kamera.
* **Efisiensi Daya & Baterai**: Fitur *power-save timeout*, kontrol *torch/flashlight*, dan tombol *flip camera* (kamera depan/belakang).

---

### 👨‍👩‍👧 3. Portal Orang Tua / Wali Murid (`/features/wali`)
* **Login Cepat via NIS**: Akses aman dan instan menggunakan NIS siswa tanpa proses registrasi rumit, dengan sesi lokal terenkripsi (*SharedPreferences*).
* **Dukungan Multi-Anak (*Child Switcher Bar*)**: Memungkinkan orang tua yang memiliki lebih dari satu anak di sekolah untuk berpindah profil anak dengan satu ketukan, serta dialog *Tambah Anak*.
* **Kartu Presensi Live (*Live Attendance Card*)**:
  * Status kehadiran harian terkini (*Hadir, Terlambat, Pulang, Sakit, Izin, Alfa*).
  * Catatan guru, jam masuk, jam pulang, dan alasan penolakan jika surat ditolak.
* **Statistik & Grafik Kehadiran Bulanan**:
  * Visualisasi *interactive line chart* persentase kehadiran bulanan.
  * Kartu rekapitulasi total hadir, sakit, izin, dan alfa.
* **Feed Pengumuman Sekolah & Notifikasi (`/features/wali/wali_notifications_screen.dart`)**:
  * Kotak masuk pengumuman resmi sekolah terintegrasi database dan push inbox.
  * Filter otomatis pengumuman yang relevan berdasarkan tingkatan kelas anak.
  * Indikator pesan belum dibaca (*unread badge*) dan opsi tandai semua telah dibaca.
* **Pengajuan Surat Izin & Sakit Digital (`/features/wali/pengajuan_surat_screen.dart`)**:
  * Formulir jenis surat (*Izin* / *Sakit*) dengan kalender rentang tanggal (*Date Range*).
  * **Wajib unggah foto** untuk surat sakit (foto surat dokter/kuitansi klinik).
  * Kompresi foto cerdas otomatis sebelum diunggah ke Supabase Storage.
  * Riwayat dan pelacakan status pengajuan (*Menunggu, Disetujui, Ditolak*).

---

### 🔔 4. Sistem Notifikasi OneSignal & Background Service (`/data/services`)
* **Push Notification Presensi**: Notifikasi instan langsung ke HP wali murid saat siswa berhasil di-scan masuk atau pulang di gerbang sekolah.
* **Push Notification Status Surat**: Notifikasi otomatis saat surat perizinan disetujui atau ditolak oleh wali kelas.
* **Segmentasi & Tagging Berbasis Peran**: Sinkronisasi tag OneSignal otomatis (`role: guru`, `nis: [list_nis]`, `kelas: [list_kelas]`).
* **Supabase Edge Function & REST API Fallback**: Menjamin notifikasi tetap terkirim secara andal melalui Edge Function backend.

---

## 🛠️ Stack Teknologi & Dependensi

| Komponen | Pustaka / Layanan | Fungsi & Keterangan |
| :--- | :--- | :--- |
| **Core Framework** | [Flutter 3.x](https://flutter.dev/) & Dart 3.x | Framework UI Multiplatform (Android & iOS) |
| **Backend & Database** | [`supabase_flutter`](https://pub.dev/packages/supabase_flutter) | PostgreSQL Database, Auth, Realtime, & Storage |
| **Push Notification** | [`onesignal_flutter`](https://pub.dev/packages/onesignal_flutter) | Push Notification Service & Audience Tagging |
| **State Management** | [`provider`](https://pub.dev/packages/provider) | Manajemen status aplikasi yang terstruktur & efisien |
| **QR/Barcode Scanner** | [`mobile_scanner`](https://pub.dev/packages/mobile_scanner) | Engine pemindai kamera responsif dan hemat daya |
| **Media & Kompresi** | [`image_picker`](https://pub.dev/packages/image_picker), [`flutter_image_compress`](https://pub.dev/packages/flutter_image_compress) | Pengambilan foto & kompresi cerdas sebelum upload |
| **Penyimpanan Lokal** | [`shared_preferences`](https://pub.dev/packages/shared_preferences), [`path_provider`](https://pub.dev/packages/path_provider) | Session caching profil anak & offline notification read status |
| **UI & Animasi** | [`flutter_animate`](https://pub.dev/packages/flutter_animate), `Material 3`, `Custom Painters` | Transisi halus, grafik custom, laser scanner, & micro-interactions |
| **Format & Lokalisasi**| [`intl`](https://pub.dev/packages/intl), `flutter_localizations` | Format tanggal & jam Bahasa Indonesia (`id_ID`) |
| **Optimasi Build** | R8 / ProGuard Code & Resource Shrinking | Ukuran APK yang ringkas, aman, dan performa tinggi |

---

## 📁 Struktur Direktori Proyek

Arsitektur aplikasi menerapkan pola **Feature-First Clean Architecture**:

```text
lib/
├── core/                               # Utilitas inti, tema, dan konstanta global
│   ├── constants.dart                  # Konfigurasi konstanta, tabel database, & warna tema
│   ├── exceptions.dart                 # Custom exceptions & ErrorFormatter ramah pengguna
│   └── ui/                             # Widget visual bersama (Reusable UI Components)
│       ├── animated_counter.dart       # Komponen angka animasi penghitung statistik
│       ├── bouncing_widget.dart        # Micro-interaction bouncing saat tombol ditekan
│       ├── scan_result_sheet.dart      # Popup bottom sheet hasil pemindaian scanner
│       ├── scanner_laser_overlay.dart  # Efek laser animasi & border scanner
│       └── status_selector_pills.dart  # Komponen pil selektor status kehadiran
│
├── data/                               # Lapisan data, model, repository, & service
│   ├── models/                         # Definisi model data (Type-Safe Dart Data Models)
│   │   ├── absensi.dart                # Model log absensi harian
│   │   ├── class_summary.dart          # Model ringkasan kehadiran kelas
│   │   ├── guru.dart                   # Model data guru & profil akun
│   │   ├── kelas.dart                  # Model rombel & informasi kelas
│   │   ├── siswa.dart                  # Model siswa & status akademik
│   │   ├── surat.dart                  # Model surat perizinan & approval
│   │   └── wali_murid_models.dart      # Model sesi wali, profil anak, & notifikasi
│   │
│   ├── repositories/                   # Lapisan query & transaksi database Supabase
│   │   ├── absensi_repository.dart     # Query absensi, summary, & pencatatan scan
│   │   ├── auth_repository.dart        # Autentikasi guru, session check, & update profil
│   │   ├── siswa_repository.dart       # Query daftar siswa per kelas
│   │   ├── surat_repository.dart       # Query pengajuan, histori, & persetujuan surat
│   │   └── wali_repository.dart        # Query login NIS, data absensi anak, & pengumuman
│   │
│   └── services/                       # Integrasi service eksternal & backend
│       ├── onesignal_service.dart      # Inisialisasi, listener, & pengiriman push notification
│       ├── supabase_service.dart       # Singleton Supabase Client instance
│       └── wali_storage_service.dart   # Manajemen cache lokal SharedPreferences sesi wali
│
├── features/                           # Modul-modul fitur aplikasi (Feature-First)
│   ├── auth/                           # Fitur Autentikasi & Dashboard Utama Guru
│   │   ├── auth_wrapper.dart           # Route dispatcher berdasarkan role sesi login
│   │   ├── dashboard_logic.dart        # State logic ringkasan dashboard guru
│   │   ├── dashboard_screen.dart       # Tampilan dashboard utama guru & drawer navigasi
│   │   └── form_login.dart             # Layar login dwifungsi (Tab Guru/Admin & Tab Wali)
│   │
│   ├── edit_siswa/                     # Fitur Edit Kehadiran Manual & Catatan Guru
│   │   ├── edit_siswa_logic.dart       # State handler update presensi & keterangan
│   │   └── edit_siswa_screen.dart      # Layar formulir ubah status & catatan siswa
│   │
│   ├── kelas/                          # Fitur Pemantauan Presensi Kelas
│   │   ├── kelas_logic.dart            # State logic daftar siswa & filter pencarian
│   │   └── kelas_screen.dart           # Layar list presensi siswa & quick action
│   │
│   ├── persetujuan_surat/              # Fitur Verifikasi & Approval Surat oleh Guru
│   │   └── persetujuan_surat_screen.dart # Tab pengajuan surat, review foto, & approval modal
│   │
│   ├── profil/                         # Fitur Akun & Pengaturan Profil Guru
│   │   └── profil_guru_screen.dart     # Layar edit profil, kontak, ganti password, & avatar
│   │
│   ├── scanner/                        # Fitur Continuous QR Code & Barcode Scanner
│   │   ├── scan_dashboard_screen.dart  # Layar beranda modul scanner admin
│   │   ├── scanner_dialog.dart         # Fullscreen dialog continuous camera scanner
│   │   └── scanner_widget.dart         # Widget kamera mobile_scanner & overlay controls
│   │
│   └── wali/                           # Fitur Portal Khusus Orang Tua / Wali Murid
│       ├── pengajuan_surat_screen.dart # Formulir upload surat izin/sakit & riwayat pengajuan
│       ├── wali_dashboard_screen.dart  # Beranda utama wali murid, multi-anak, & live status
│       ├── wali_notifications_screen.dart # Kotak masuk pengumuman sekolah & detail dialog
│       └── widgets/                    # Komponen modular khusus portal wali
│           ├── add_child_dialog.dart   # Modal tambah anak dengan validasi NIS
│           ├── attendance_line_chart.dart # Custom widget grafik kehadiran bulanan
│           ├── child_switcher_bar.dart # Bar pemilihan profil anak aktif
│           ├── live_attendance_card.dart # Kartu status kehadiran hari ini real-time
│           └── monthly_stats_card.dart # Kartu rekapitulasi statistik kehadiran per bulan
│
└── main.dart                           # Entrypoint aplikasi, inisialisasi SDK, & setup tema
```

---

## ⚙️ Panduan Instalasi & Menjalankan Proyek

### 1. Prasyarat Sistem
* [Flutter SDK](https://docs.flutter.dev/get-started/install) versi 3.19.x atau yang lebih baru.
* [Dart SDK](https://dart.dev/get-dart) versi 3.x.
* Android Studio / VS Code dengan ekstensi Flutter & Dart.
* Android SDK (API Level 21+) atau perangkat fisik Android/iOS dengan mode Developer diaktifkan.

### 2. Clone Repositori
```bash
git clone https://github.com/AndhikaBagus115/Mobile-Absensi-Siswa-Mts-Suguja.git
cd Mobile-Absensi-Siswa-Mts-Suguja
```

### 3. Konfigurasi File Environment (`.env`)
Salin file template `.env.example` menjadi `.env` pada root direktori:
```bash
cp .env.example .env
```

Buka file `.env` dan lengkapi konfigurasi Supabase dan OneSignal Anda:
```env
# Supabase Configuration
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-public-key
APP_ENVIRONMENT=development

# OneSignal Push Notification Configuration
ONESIGNAL_APP_ID=your-onesignal-app-id-uuid

# (Opsional untuk development lokal jika tidak menggunakan Supabase Edge Function)
ONESIGNAL_REST_API_KEY=your-onesignal-rest-api-key
```

> ⚠️ **PENTING**: Jangan pernah melakukan commit file `.env` yang berisi kredensial asli ke repositori publik!

### 4. Install Dependensi
Jalankan perintah berikut untuk mengunduh semua pustaka yang dibutuhkan:
```bash
flutter pub get
```

### 5. Generate Icon Aplikasi *(Opsional)*
Jika ingin memperbarui ikon aplikasi launcher:
```bash
dart run flutter_launcher_icons
```

### 6. Jalankan Aplikasi

#### Mode Debug:
```bash
flutter run
```

#### Build APK Release (Dengan optimasi ProGuard / R8):
```bash
flutter build apk --release
```
File output APK siap pasang akan berada di: `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🔒 Hak Akses & Akun Demo Pengujian

| Peran (Role) | Metode Login | Target Tampilan Utama |
| :--- | :--- | :--- |
| **Guru / Wali Kelas** | Email & Password (Tab Guru) | Dashboard Guru, Rekap Kelas, Persetujuan Surat, Profil |
| **Admin Scanner** | Email & Password Akun Admin | Modul Continuous QR Code Scanner Gerbang |
| **Wali Murid** | NIS Siswa (Tab Wali Murid) | Dashboard Wali, Multi-Anak, Live Attendance, Form Surat, Notifikasi |

---

## 👨‍💻 Kontributor & Lisensi

Dikembangkan dengan penuh dedikasi oleh **Andhika Bagus Satria** & Tim Pengembang Sistem Informasi Sekolah MTs Sunan Gunung Jati.

Proyek ini dilisensikan di bawah lisensi terbuka [MIT License](LICENSE).
