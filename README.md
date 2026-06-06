# Aplikasi Katalog Buku dan Reading Tracker

# MobTeam #2 — Aplikasi Katalog Buku & Reading Tracker

Proyek ini merupakan aplikasi manajemen koleksi buku pribadi, pelacakan progres membaca, dan pemberian ulasan berbasis Mobile yang mendukung fungsionalitas penuh secara *offline* dengan sinkronisasi data ke *cloud server*.

---

## Anggota Tim 2
* **Marcelino Budi Prakasya**: bertanggung jawab pada pengembangan **Back-end API & Server Database**.
* **Mikail Achmad**: bertanggung jawab pada pengembangan **Front-end Mobile Application & Local Database**.

---

## Tech Stack Proyek

| Layer | Teknologi | Catatan |
| :--- | :--- | :--- |
| **Mobile Front-end** | Flutter (Dart SDK) | Manajemen UI/UX dan State Management |
| **Local Database** | IsarDB | Penyimpanan model Buku, Progres, dan Review secara lokal (*offline*) |
| **Back-end API** | Go (Chi) | Penyedia REST API untuk manajemen data terpusat |
| **Server Database** | PostgreSQL | Penyimpanan data persisten di tingkat *cloud server* |
| **HTTP Client** | Dio / Http (Package) | Media komunikasi data dari Flutter menuju Flask API |

---

## Struktur Direktori Proyek (Monorepo)
Untuk menjaga modularitas, repositori ini menggunakan arsitektur monorepo yang memisahkan kode aplikasi mobile dengan server backend:

```text
Aplikasi Katalog Buku & Reading Tracker/
├── backend/                  # Workspace Marcel (Flask API)
│   ├── internal/             # Kode berisi logika, autentikasi, database, dan lain-lain.
│   ├── sql/                  # Skema dan migrasi DDL PostgreSQL
│   └── main.go               # Script utama server Go
│
├── lib/                      # Workspace Miko (Flutter Application)
│   ├── models/               # Definisi skema objek IsarDB
│   ├── views/                # Komponen antarmuka (UI Pages & Widgets)
│   ├── services/             # Handler integrasi HTTP / API (Dio)
│   └── main.dart             # Entry point aplikasi Flutter
│
├── pubspec.yaml              # Konfigurasi package Flutter
└── README.md                 # Dokumentasi proyek
```

--- 

## Dokumentasi API

https://mobteam-2-bookshelf.github.io/katalog-buku/

--- 

### Install Aplikasi

Ikuti langkah-langkah berikut untuk menginstal aplikasi **Bookshelf** pada perangkat Android:

1. Unduh atau salin file **`app-arm64-v8a-release.apk`** ke perangkat Anda.
2. Buka file **`app-arm64-v8a-release.apk`** melalui File Manager.
3. Tekan tombol **Install** dan tunggu hingga proses instalasi selesai.
4. Setelah instalasi berhasil, tekan tombol **Open** atau buka aplikasi melalui ikon **Bookshelf** pada layar utama perangkat.
5. Aplikasi **Bookshelf** siap digunakan.

> **Catatan:** Jika muncul peringatan keamanan saat instalasi, aktifkan izin **Install from Unknown Sources** sesuai pengaturan perangkat Android yang digunakan.


...

---

## Menjalankan Aplikasi dengan Flutter
```text
flutter pub get
flutter run
```
Note: Jika ingin menggunakan REST API yang dijalankan secara lokal, ganti `_baseUrl` pada file `apps\mobile\lib\services\api_service.dart`. Misal `_baseUrl = 'localhost/api/v1`

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
### 5. 5. Build and Run Go server
```
cd /backend 
go build 
./bookshelf
```
