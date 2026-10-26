# IPS-Guide

Aplikasi Panduan Interaktif Layanan Administrasi **Kelurahan Tegalsari, Kota Semarang**.

Proyek individu — Elisa Sandita Putri (23.01.55.0010, Kelas A1) — mata kuliah *Mobile and Web Application Development* (Ganjil 2026/2027), sekaligus penelitian skripsi.

## Teknologi

| Komponen | Fungsi |
|---|---|
| Flutter + Dart | Aplikasi mobile & web |
| Firebase Authentication | Login email/password |
| Cloud Firestore | Menyimpan data panduan (bukan data pribadi warga) |
| Firebase Hosting | Menayangkan versi web |
| GitHub | Kode & bukti perubahan |
| Figma | Rancangan UI (Minggu 4) |

## Struktur

Rancangan arsitektur lengkap: [`docs/RANCANGAN-ARSITEKTUR.md`](docs/RANCANGAN-ARSITEKTUR.md).

- `lib/app/` — bootstrap, tema (style guide §13), routing
- `lib/domain/` — mesin aturan & entity (**pure Dart**, tanpa impor Flutter/Firestore)
- `lib/data/` — repository (in-memory & Firestore)
- `lib/features/` — satu folder per halaman

## Menjalankan

```bash
flutter pub get
flutter run -d chrome
```

## Batasan proyek

Hanya media panduan — tidak menerbitkan dokumen resmi, tidak melakukan transaksi, tidak terintegrasi SIAK/kependudukan. Tanpa billing account, Cloud Functions, atau autentikasi telepon.
