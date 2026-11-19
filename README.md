# 📱 MTs Suguja Attendance — Mobile Companion App

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Backend-Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![OneSignal](https://img.shields.io/badge/Push-OneSignal-E54B4D?style=for-the-badge&logo=onesignal&logoColor=white)
![Material 3](https://img.shields.io/badge/UI-Material_3-7C3AED?style=for-the-badge&logo=materialdesign&logoColor=white)

> Multi-role **Flutter** mobile app (Android & iOS) for the attendance information system of **MTs Sunan Gunung Jati (Suguja)**. It provides a continuous QR/barcode gate scanner, class attendance monitoring for teachers, digital leave-letter approval, a multi-child portal for parents, and real-time push notifications through **OneSignal** and **Supabase**.

---

## 📌 Project Overview

This app is the mobile companion of the school attendance system and serves three groups of users:

1. **Teachers & homeroom teachers** — manage daily class attendance, review and approve sick/leave letters, adjust attendance manually with notes, and update their profile.
2. **Gate scanner officers (admin)** — scan student ID card QR codes/barcodes continuously with instant verification.
3. **Parents / guardians** — follow their child's attendance in real time, switch between several children, view monthly statistics and charts, read school announcements, and submit sick/leave letters with compressed photo attachments.

The app reads and writes the same Supabase database as the web & desktop admin portal **[SIM-Dasbor-Absensi-Mts-Suguja](https://github.com/Aldidwiirawan/SIM-Dasbor-Absensi-Mts-Suguja)**.

---

## 🚀 Key Features

### 👨‍🏫 Teacher & Homeroom Teacher Portal (`features/auth`, `features/kelas`, `features/profil`)
- **Interactive daily dashboard** — live counts for present, sick, leave, absent, and late, with animated counters and lifecycle auto-refresh.
- **Class & student overview** — filter students by the classes a teacher handles or by all classes, with debounced instant search.
- **Manual attendance editing** — change a student's status with quick-select pills and add a teacher's note.
- **Leave-letter approval** (`features/persetujuan_surat`)
  - Status tabs: *Pending*, *Approved*, *Rejected*, and *All*.
  - Pinch-to-zoom preview of the attached doctor's note or letter.
  - Approve/reject with feedback that is pushed to the parent through OneSignal.
- **Teacher profile** — edit name, phone/WhatsApp number, and email; upload an avatar with automatic compression (`flutter_image_compress`); change password.

### 📷 Continuous QR & Barcode Scanner (`features/scanner`)
- **Continuous scanning** of student cards using `mobile_scanner` v7.
- **Per-student (NIS) debounce** to prevent duplicate scans within a short interval.
- **Visual & haptic feedback** — animated laser, colored border (green for check-in, orange for check-out, red for errors), and vibration.
- **Quick result pop-up** showing the student's name, NIS, status, and scan time without stopping the camera.
- **Battery-friendly controls** — power-save timeout, torch toggle, and front/back camera switch.

### 👨‍👩‍👧 Parent Portal (`features/wali`)
- **Quick login with the student's NIS** — no registration needed; the session is cached locally.
- **Multi-child support** — switch between children with one tap and add another child from a dialog.
- **Live attendance card** — today's status (present, late, checked out, sick, leave, absent), teacher notes, check-in/out times, and the reason when a letter is rejected.
- **Monthly statistics** — interactive attendance line chart and summary cards.
- **School announcements inbox** — announcements filtered by the child's grade, unread badges, and mark-all-as-read.
- **Digital sick/leave letters** — choose the letter type and date range; a photo is required for sick letters and is compressed before upload to Supabase Storage; track the status of each request.

### 🔔 Notifications (`data/services`, `supabase/functions/send-push`)
- Push notification to the parent when a student is scanned in or out at the gate.
- Push notification when a leave letter is approved or rejected.
- Role-based OneSignal tags (`role`, `nis`, `kelas`) synced automatically.
- Delivery through a Supabase Edge Function, with a REST API fallback for local development.

---

## 🛠️ Technology Stack

| Component | Library / Service | Purpose |
| :--- | :--- | :--- |
| **Framework** | [Flutter 3.x](https://flutter.dev/) & Dart 3.x | Cross-platform UI (Android & iOS) |
| **Backend & Database** | [`supabase_flutter`](https://pub.dev/packages/supabase_flutter) | PostgreSQL, Auth, Realtime, and Storage |
| **Push Notifications** | [`onesignal_flutter`](https://pub.dev/packages/onesignal_flutter) | Push delivery and audience tagging |
| **State Management** | [`provider`](https://pub.dev/packages/provider) | App state |
| **QR/Barcode Scanner** | [`mobile_scanner`](https://pub.dev/packages/mobile_scanner) | Camera scanning engine |
| **Media** | [`image_picker`](https://pub.dev/packages/image_picker), [`flutter_image_compress`](https://pub.dev/packages/flutter_image_compress) | Photo capture and compression before upload |
| **Local Storage** | [`shared_preferences`](https://pub.dev/packages/shared_preferences), [`path_provider`](https://pub.dev/packages/path_provider) | Parent session cache and notification read state |
| **Configuration** | [`flutter_dotenv`](https://pub.dev/packages/flutter_dotenv) | Environment variables from `.env` |
| **UI & Animation** | [`flutter_animate`](https://pub.dev/packages/flutter_animate), Material 3, custom painters | Transitions, charts, scanner overlay |
| **Localization** | [`intl`](https://pub.dev/packages/intl), `flutter_localizations` | Indonesian date and time formatting (`id_ID`) |
| **Build Optimization** | R8 / ProGuard | Code and resource shrinking for release APKs |

---

## 🌐 System Architecture

```text
        ┌──────────────────────────────────────────────────────────┐
        │  💻 SIM-Dasbor-Absensi-Mts-Suguja (Web & Desktop Admin)   │
        └────────────────────────────┬─────────────────────────────┘
                                     │
                                     ▼
                  ┌────────────────────────────────────┐
                  │        ☁️ SUPABASE BACKEND          │
                  │  - PostgreSQL database             │
                  │  - Auth & Row Level Security       │
                  │  - Storage (avatars & letters)     │
                  │  - Edge Function (send-push)       │
                  └────────────────┬─┬─────────────────┘
                                   │ │
                 ┌─────────────────┘ └─────────────────┐
                 ▼                                     ▼
   ┌───────────────────────────┐         ┌───────────────────────────┐
   │ 🔔 ONESIGNAL PUSH          │         │ 📱 FLUTTER MOBILE APP      │
   │ - Attendance alerts       │ ◄────── │ - Teacher portal          │
   │ - Letter approval alerts  │         │ - Parent portal           │
   │ - Announcements           │ ──────► │ - Continuous QR scanner   │
   └───────────────────────────┘         └───────────────────────────┘
```

---

## 📁 Project Structure

The app follows a **feature-first clean architecture**:

```text
lib/
├── core/                          # Shared utilities, theme, and constants
│   ├── constants.dart             # Table names, configuration, theme colors
│   ├── exceptions.dart            # Custom exceptions & user-friendly error formatter
│   └── ui/                        # Reusable UI components (counters, scanner overlay, status pills)
│
├── data/
│   ├── models/                    # Type-safe models: absensi, guru, kelas, siswa, surat, wali
│   ├── repositories/              # Supabase queries: absensi, auth, siswa, surat, wali
│   └── services/                  # onesignal_service, supabase_service, wali_storage_service
│
├── features/
│   ├── auth/                      # Login (teacher/admin & parent tabs), role-based routing, teacher dashboard
│   ├── edit_siswa/                # Manual attendance edit & teacher notes
│   ├── kelas/                     # Class attendance list & search
│   ├── persetujuan_surat/         # Leave-letter review & approval
│   ├── profil/                    # Teacher profile, avatar, password
│   ├── scanner/                   # Scanner home, full-screen continuous scanner, camera widget
│   └── wali/                      # Parent dashboard, announcements, letter form, child widgets
│
└── main.dart                      # Entry point, SDK initialization, theme setup

supabase/
└── functions/send-push/           # Edge Function that sends OneSignal notifications
```

---

## ⚙️ Installation & Setup

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.19 or newer (Dart 3.x)
- Android Studio or VS Code with the Flutter & Dart extensions
- Android SDK (API level 21+) or a physical Android/iOS device with developer mode enabled
- A Supabase project and a OneSignal app

### 1. Clone the repository
```bash
git clone https://github.com/Aldidwiirawan/Mobile-Absensi-Siswa-Mts-Suguja.git
cd Mobile-Absensi-Siswa-Mts-Suguja
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Create the environment file
```bash
cp .env.example .env
```
Fill in the values described in [Environment Variables](#-environment-variables).

### 4. (Optional) Regenerate the launcher icon
```bash
dart run flutter_launcher_icons
```

---

## 🔐 Environment Variables

| Variable | Required | Description |
| :--- | :---: | :--- |
| `SUPABASE_URL` | ✅ | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | ✅ | Supabase anon (public) key |
| `APP_ENVIRONMENT` | ✅ | `development` or `production` |
| `ONESIGNAL_APP_ID` | ✅ | OneSignal app ID |
| `ONESIGNAL_REST_API_KEY` | ➖ | Local development only. In production, keep this key in Supabase Secrets for the Edge Function. |

> ⚠️ Never commit the `.env` file or real credentials to a public repository.

---

## ▶️ How to Run

**Debug mode**
```bash
flutter run
```

**Release APK** (with R8/ProGuard shrinking)
```bash
flutter build apk --release
```
The APK is written to `build/app/outputs/flutter-apk/app-release.apk`.

### Roles & login methods

| Role | Login method | Main screens |
| :--- | :--- | :--- |
| **Teacher / homeroom teacher** | Email & password (Teacher tab) | Dashboard, class attendance, letter approval, profile |
| **Gate scanner admin** | Email & password (admin account) | Continuous QR code scanner |
| **Parent / guardian** | Student NIS (Parent tab) | Parent dashboard, multi-child, live attendance, letter form, announcements |

---

## 👨‍💻 Author

This repository is part of the **SIM Absensi MTs Suguja** team project — a Flutter mobile app and a Flutter admin dashboard that share one Supabase database, built by a team of five students.

- Mobile app development: [@AndhikaBagus115](https://github.com/AndhikaBagus115) and [@bimaibra](https://github.com/bimaibra)
- Admin dashboard team members: see [SIM-Dasbor-Absensi-Mts-Suguja](https://github.com/Aldidwiirawan/SIM-Dasbor-Absensi-Mts-Suguja#-author)

**Aldi Dwi Irawan** — team member (admin dashboard)
- GitHub: [@Aldidwiirawan](https://github.com/Aldidwiirawan)
- Portfolio: [aldidwiirawan.vercel.app](https://aldidwiirawan.vercel.app)
- Email: aldidwiirawan2004@gmail.com
