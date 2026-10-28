# IPS-Guide

Aplikasi Panduan Interaktif Layanan Administrasi **Kelurahan Tegalsari, Kota Semarang**.

Proyek individu — Elisa Sandita Putri (23.01.55.0010, Kelas A1) — mata kuliah *Mobile and Web Application Development* (Ganjil 2026/2027), sekaligus penelitian skripsi.

## Tangkapan layar

|                                                                                                                                    |                                                                                                                                       |
| ---------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **Beranda** — sapaan, tiga kartu layanan, dan pintu masuk bantuan<br />[Beranda](docs/screenshots/01-beranda.png)                  | **Pilih Layanan** — tiga layanan dengan keterangan singkat<br />[Pilih Layanan](docs/screenshots/02-pilih-layanan.png)                |
| **Pertanyaan Panduan** — satu pertanyaan per layar, progres terlihat<br />[Pertanyaan](docs/screenshots/03-pertanyaan-panduan.png) | **Hasil Panduan** — status, dokumen yang perlu disiapkan, dan tahapan<br />[Hasil](docs/screenshots/04-hasil-panduan.png)             |
| **Mengapa?** — aturan penentu keputusan ditampilkan terbuka<br />[Mengapa](docs/screenshots/05-mengapa-penjelasan.png)             | **Kelola Panduan** (petugas) — aturan, pertanyaan, persyaratan, tahapan<br />[Kelola Panduan](docs/screenshots/06-kelola-panduan.png) |
| **Sampaikan Kebutuhan** — formulir tervalidasi untuk warga<br />[Sampaikan Kebutuhan](docs/screenshots/07-sampaikan-kebutuhan.png) |                                                                                                                                       |

## Halaman yang tersedia

Login · Beranda · Pilih Layanan · Pertanyaan Panduan · Hasil Panduan · Kelola Panduan (khusus admin) · Sampaikan Kebutuhan

## Teknologi

### Sudah dipakai di kode ini

| Komponen           | Fungsi                                        | Bukti                          |
| ------------------ | --------------------------------------------- | ------------------------------ |
| Flutter + Dart     | Aplikasi web & mobile                         | `pubspec.yaml`, `lib/`         |
| go_router          | Routing dan penjagaan rute per peran          | `lib/app/router.dart`          |
| flutter_riverpod   | Keadaan aplikasi dan penyediaan repository    | `lib/data/providers.dart`      |
| Aset JSON seed     | Basis aturan panduan dimuat saat aplikasi mulai | `assets/seed/`              |
| GitHub             | Kode dan riwayat perubahan                    | repositori ini                 |

### Direncanakan — belum terintegrasi

| Komponen                | Rencana pemakaian                                | Status nyata saat ini                                                                                                     |
| ----------------------- | ------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------- |
| Firebase Authentication | Login email/kata sandi                           | **Belum terpasang.** Tidak ada di `pubspec.yaml`; login memakai `InMemoryAuthRepository` dengan akun demo                  |
| Cloud Firestore         | Menyimpan data panduan (bukan data pribadi warga) | **Belum terpasang.** Basis aturan dibaca dari `assets/seed/*.json`; formulir warga disimpan di memori                      |
| Firebase Hosting        | Menayangkan versi web                            | **Belum dipakai.** Versi web dijalankan lokal: `flutter build web` lalu disajikan server statis                            |

Ketiga komponen di tabel kedua adalah rencana yang sudah disiapkan kontraknya (antarmuka
repository), bukan fitur yang berjalan. Tidak ada berkas konfigurasi Firebase di repositori ini.

## Struktur

- `lib/app/` — bootstrap, tema (style guide §13), routing
- `lib/domain/` — mesin aturan & entity (**pure Dart**, tanpa impor Flutter/Firestore)
- `lib/data/` — repository in-memory; antarmukanya disiapkan agar Firestore bisa dipasang tanpa mengubah UI
- `lib/features/` — satu folder per halaman

## Menjalankan

```bash
flutter pub get
flutter run -d chrome
```

Versi web siap tayang:

```bash
flutter build web --release
cd build/web && python -m http.server 8080
```

## Akun demo

Selama Firebase belum dipasang, autentikasi memakai repository di memori:

| Email                  | Kata sandi | Peran                                |
| ---------------------- | ---------- | ------------------------------------ |
| `warga@tegalsari.test` | `123456`   | warga                                |
| `admin@tegalsari.test` | `123456`   | petugas (menu Kelola Panduan muncul) |

## Pengujian

- 159 uji otomatis lulus; `flutter analyze` tanpa temuan.
- Tabel uji form H7 (11 kasus; 10 beruji otomatis, 1 diuji manual di browser): [`docs/UJI-FORM.md`](docs/UJI-FORM.md).

## Dokumentasi lain

- [`docs/RANCANGAN-ARSITEKTUR.md`](docs/RANCANGAN-ARSITEKTUR.md) — rancangan arsitektur, mesin aturan, dan tahapan pengerjaan
- [`docs/RENCANA-VIDEO.md`](docs/RENCANA-VIDEO.md) — rencana video presentasi UTS
- [`docs/NASKAH-VIDEO.md`](docs/NASKAH-VIDEO.md) — naskah narasi beserta penanda waktu

## Artefak desain (Minggu 2–4)

Berkas asli tugas mingguan, disalin apa adanya ke repositori:

| Artefak | Berkas | Isi |
| --- | --- | --- |
| Persona | [`docs/desain/minggu-02-persona-user-story.docx`](docs/desain/minggu-02-persona-user-story.docx) | Satu persona warga, dengan pemisahan temuan dan asumsi |
| User story | [`docs/desain/minggu-02-persona-user-story.docx`](docs/desain/minggu-02-persona-user-story.docx) | Lima user story beserta kriteria penerimaan |
| User flow & sitemap | [`docs/desain/minggu-03-user-flow-sitemap.docx`](docs/desain/minggu-03-user-flow-sitemap.docx) | Alur inti Login → Hasil Panduan dengan cabang alternatif, dan sitemap |
| Wireframe & gaya visual | [`docs/desain/minggu-04-wireframe-figma.docx`](docs/desain/minggu-04-wireframe-figma.docx) | Frame mobile semua halaman Must, keadaan galat, style guide mini, versi web, sambungan prototipe |

Rancangan UI di Figma (akses view): [Wireframe IPS-Guide](https://www.figma.com/design/R4cNNK3IPYIFB5Hwm3dVp5/23.01.55.0010-%E2%80%93-IPS-Guide-%E2%80%93-Wireframe?node-id=0-1&t=4gIjUGHjf0mNF3NS-1)

Catatan: diagram alur pada dokumen Minggu 3 berhenti di Hasil Panduan. Halaman Kelola Panduan (H6)
dan Sampaikan Kebutuhan (H7) ditambahkan setelah dokumen itu dibuat.

## Batasan proyek

Hanya media panduan — tidak menerbitkan dokumen resmi, tidak melakukan transaksi, tidak terintegrasi SIAK/kependudukan. Tanpa billing account, Cloud Functions, atau autentikasi telepon. Pada prototipe ini data formulir warga masih tersimpan di memori dan hilang saat halaman dimuat ulang.
