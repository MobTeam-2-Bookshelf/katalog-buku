# Bookshelf — Reading Tracker and Book Catalogue Application

Bookshelf merupakan aplikasi pengelola koleksi buku pengguna secara privat. Bookshelf dirancang untuk mencatat dan merekap daftar buku yang telah dibaca oleh pengguna dalam jangka waktu tertentu. Di samping itu, Bookshelf juga mampu merekap progres pembacaan buku serta memberi rating-review pada buku yang telah dibaca. Data tersimpan lokal di IsarDB kemudian dapat disinkronkan ke backend agar koleksi buku bisa diakses dari mana saja. Bookshelf berbasis Mobile yang mendukung fungsionalitas secara luring memakai IsarDB dengan sinkronisasi data ke *cloud server* ketika user daring kembali.

Project ini dibuat untuk tugas MobTeam #2 — Backend & Local Database dengan studi kasus Aplikasi Katalog Buku & Reading Tracker.

---

## Anggota dan pembagian tugas Tim 2
 
### Mikail Achmad (Mobile Developer & Integrator)
- Membangun antarmuka (UI) aplikasi dengan Flutter.
- Mengimplementasikan database lokal (IsarDB) untuk mode offline-first.
- Menyusun logika sinkronisasi data yang robust dengan API.
- Mengatasi konfigurasi build APK Android.

### Marcelino Budi Prakasya (Backend Developer)
- Merancang dan membuat REST API menggunakan Golang.
- Mengelola basis data PostgreSQL.
- Menangani konversi tipe data dari JSON ke DB format.
- Melakukan deployment server API ke VPS Linux.

---

## Tech Stack Proyek

### Frontend Mobile
 
| Kebutuhan | Teknologi |
| :--- | :--- |
| Framework | Flutter |
| Language | Dart |
| State Management | `setState` / `StatefulWidget` (built-in Flutter, tanpa package eksternal) |
| Local Database | IsarDB (`isar`, `isar_flutter_libs`) |
| Code Generation | `build_runner`, `isar_generator` |
| HTTP Client | `dio` |
| Local Storage | `shared_preferences` |
| Barcode / QR Scanner | `mobile_scanner` |
| ID Generator | `uuid` |
| Typography | `google_fonts` |
| Path Management | `path_provider` |
 
### Backend & Server
 
| Layer | Teknologi | Catatan |
| :--- | :--- | :--- |
| **Back-end API** | Go (Chi) | Penyedia REST API untuk manajemen data terpusat |
| **Server Database** | PostgreSQL | Penyimpanan data persisten di tingkat *cloud server* |

---

## Fitur Utama Bookshelf
**Frontend Mobile (Aplikasi):**
- Autentikasi pengguna (Login & Register).
- Manajemen data buku (Create, Read, Update, Delete).
- Mode *Offline-First* (Bisa digunakan tanpa internet).
- Fitur sinkronisasi data 2 arah (Lokal ke Server & Server ke Lokal).
- Fitur *Scan Barcode/QR Code*.

**Backend API (Server):**
- RESTful API terpusat untuk melayani HTTP Request.
- Autentikasi keamanan berbasis Token JWT.
- Penerimaan operasi data jamak (*bulk actions*) via `HTTP POST`.

## Arsitektur Sistem
 
Bookshelf menggunakan arsitektur berlapis di sisi mobile agar antarmuka, database lokal, dan komunikasi ke server memiliki tanggung jawab yang jelas, mengikuti struktur folder `lib/` (`views`, `models`, `services`).
 
```text
Flutter Mobile App
├── Presentation Layer
│   └── views/                # UI Pages & Widgets (Login, Book List, Book Detail, dll)
│
├── State Management Layer
│   └── setState / StatefulWidget pada masing-masing View
│
├── Data Source Layer
│   ├── Local Data Source: IsarDB (models/)
│   └── Remote Data Source: REST API via Dio (services/)
│
└── Sync Layer
    └── Push perubahan lokal & pull data terbaru dari server
```
 
```text
Backend API
└── Go (Chi) + PostgreSQL
    ├── internal/   # Logika, autentikasi, database
    └── sql/        # Skema & migrasi DDL
```
 
> Catatan: arsitektur di atas mengikuti struktur direktori proyek yang sudah berjalan. Detail pembagian layer pada backend (routes/handlers) bisa dilengkapi lebih lanjut sesuai kode di `backend/internal/`.
 
---

## Alur Offline-First
 
Bookshelf menjadikan **IsarDB sebagai penyimpanan utama di sisi aplikasi mobile**. Data yang ditampilkan ke user berasal dari local database terlebih dahulu, sehingga aplikasi tetap responsif walau tanpa koneksi internet.
 
Alur utamanya:
 
1. User menambah, mengedit, atau menghapus data buku melalui aplikasi.
2. Perubahan disimpan terlebih dahulu ke IsarDB secara lokal.
3. Saat koneksi internet tersedia kembali, user dapat menekan tombol "Sinkronisasi" pada halaman Profile.
4. Aplikasi akan mengirim perubahan lokal ke backend dan menarik data terbaru dari server untuk disimpan kembali ke IsarDB.
> Catatan: fitur penandaan status sinkronisasi per-item (mis. status `pending`/`synced` pada tiap data) masih dalam tahap pengembangan dan belum stabil sepenuhnya.
 
---

## Struktur Direktori Proyek (Monorepo)
Untuk menjaga modularitas, repositori ini menggunakan arsitektur monorepo yang memisahkan kode aplikasi mobile dengan server backend:

```text
katalog-buku/
├── backend/                 # Workspace Marcel (Flask API)
│   ├── internal/            # Kode berisi logika, autentikasi, database, dan lain-lain.
│   ├── sql/                 # Skema dan migrasi DDL PostgreSQL
│   └── main.go              # Script utama server Go
│   └── sqlc.yaml            # Konfigurasi ORM/Database
│
├── apps/mobile/            # Area pengembangan frontend aplikasi mobile
│   ├── lib/                # Source code Dart (Views, Models, Services)
│   ├── ├── models/         # Definisi skema objek IsarDB
│   ├── ├── views/          # Komponen antarmuka (UI Pages & Widgets)
│   ├── ├── services/       # Handler integrasi HTTP / API (Dio)
│   └── ├── main.dart       # Entry point aplikasi Flutter
│   ├── android/            # Konfigurasi platform Android & Gradle
│   └── pubspec.yaml        # Daftar dependency Flutter (Isar, http, dll)
└── README.md                 # Dokumentasi proyek
```

--- 

## Preview Aplikasi

<table>
  <tr>
    <td align="center">
      <img src="docs/sign_up_page.jpeg" width="250"><br>
      <b>Sign Up</b>
    </td>
    <td align="center">
      <img src="docs/book_detail_page.jpeg" width="250"><br>
      <b>Book Detail</b>
    </td>
    <td align="center">
      <img src="docs/book_list_page.jpeg" width="250"><br>
      <b>Book List</b>
    </td>
  </tr>
</table>

## Links
- Endpoint Bookshelf:http://103.23.198.215/api/v1
- Dokumentasi API: https://mobteam-2-bookshelf.github.io/katalog-buku/
- Mendapatkan buku acak: https://api.bukuacak.shabsolute.tech/api/v1/random_book
--- 

### Pemasangan Aplikasi

Ikuti langkah-langkah berikut untuk menginstal aplikasi **Bookshelf** pada perangkat Android:

1. Unduh atau salin file **`app-arm64-v8a-release.apk`** ke perangkat Anda.
2. Buka file **`app-arm64-v8a-release.apk`** melalui File Manager.
3. Tekan tombol **Install** dan tunggu hingga proses instalasi selesai.
4. Setelah instalasi berhasil, tekan tombol **Open** atau buka aplikasi melalui ikon **Bookshelf** pada layar utama perangkat.
5. Aplikasi **Bookshelf** siap digunakan.

> **Catatan:** Jika muncul peringatan keamanan saat instalasi, aktifkan izin **Install from Unknown Sources** sesuai pengaturan perangkat Android yang digunakan.

---

## Menjalankan Aplikasi dengan Flutter
 
### Prasyarat
Pastikan sudah menginstall:
- Flutter SDK (`^3.11.0`)
- Dart SDK
- Android Studio & Android SDK
- Android Emulator atau device Android fisik
Cek environment Flutter:
```bash
flutter doctor -v
```
 
### Install dependency
```bash
flutter pub get
```
 
### Generate file Isar
Karena Bookshelf memakai `isar_generator` dan `build_runner` untuk model database lokal, jalankan:
```bash
dart run build_runner build --delete-conflicting-outputs
```
 
### Jalankan aplikasi
```bash
flutter run
```
Note: Jika ingin menggunakan REST API yang dijalankan secara lokal, ganti `_baseUrl` pada file `apps\mobile\lib\services\api_service.dart`. Misal `_baseUrl = 'localhost/api/v1`
 
### Build APK
```bash
flutter build apk --release
```
Hasil build APK release berada di:
```text
main/app-arm64-v8a-release.apk
```

--- 

## Menjalankan Backend Server
### 1. Install
<b>Database</b>
<ul>
<li>Install postgres Database </li> 
<li>Setup username (default: postgres), password, and PORT (default: 5432)</li>
<li>Pastikan server database aktif</li>
</ul>
<b> SQL Migration Helper </b>

```text
go install github.com/sqlc-dev/sqlc/cmd/sqlc@latest
go install github.com/pressly/goose/v3/cmd/goose@latest
```

### 2. Environment Variable
Pastikan environtment variable yg diperlukan sudah tersedia:
<ul>
<li>`PORT`</li> 
<li>`DB_URL`</li>
<li>`JWT_KEY`</li>
</ul>
lihat di `backend/.env_example`

### 3. Database migration
```
cd /backend/sql/schema
goose postgres "user=<db-user> password=<your-password> host=<url> port=5432 dbname=bookshelf sslmode=disable" up
```
### 4. Parse SQL into type-safe and idiomatic code (Optional)
```
cd /backend
sqlc generate
```
### 5. Build and Run Go server
```
cd /backend 
go build 
./bookshelf
```

## Alur Demo yang Disarankan
1. Autentikasi: Buka aplikasi dan lakukan Login (atau Register akun baru)
2. Kondisi Online: Tambahkan 1-2 buku baru dan pastikan data muncul di Beranda.
3. Kondisi Offline: Matikan koneksi internet HP (Airplane Mode).
4. Manipulasi Offline: Tambahkan 1 buku baru lagi, edit 1 buku lama, dan hapus 1 buku lainnya tanpa koneksi internet. Tunjukkan bahwa UI tetap merespons dengan cepat.
5. Kondisi Online: Nyalakan kembali internet.
6. Eksekusi Sinkronisasi: Buka halaman Profile dan tekan tombol "Sinkronisasi". Tunjukkan bahwa tidak ada data loss dan semua perubahan offline sukses terkirim ke server API.

## Status Akhir Project Saat Ini
Aplikasi Bookshelf telah berhasil dibangun menjadi format .apk akhir dengan kapabilitas Offline-First yang stabil dan bebas crash. Backend API telah aktif di-deploy ke VPS dan melayani permintaan sinkronisasi data antar client-server secara presisi.
