
# IPS-Guide

Aplikasi Panduan Interaktif Layanan Administrasi **Kelurahan Tegalsari, Kota Semarang**.

Proyek individu — Elisa Sandita Putri (23.01.55.0010, Kelas A1) — mata kuliah *Mobile and Web Application Development* (Ganjil 2026/2027), sekaligus penelitian skripsi.

## Tangkapan Layar

| Tampilan | Tampilan |
| --- | --- |
| **Beranda** — sapaan, tiga kartu layanan, dan pintu masuk bantuan. [Lihat screenshot](docs/screenshots/01-beranda.png) | **Pilih Layanan** — tiga layanan dengan keterangan singkat. [Lihat screenshot](docs/screenshots/02-pilih-layanan.png) |
| **Pertanyaan Panduan** — satu pertanyaan per layar, progres terlihat. [Lihat screenshot](docs/screenshots/03-pertanyaan-panduan.png) | **Hasil Panduan** — status, dokumen yang perlu disiapkan, dan tahapan. [Lihat screenshot](docs/screenshots/04-hasil-panduan.png) |
| **Mengapa?** — aturan penentu keputusan ditampilkan terbuka. [Lihat screenshot](docs/screenshots/05-mengapa-penjelasan.png) | **Kelola Panduan** (petugas) — aturan, pertanyaan, persyaratan, dan tahapan. [Lihat screenshot](docs/screenshots/06-kelola-panduan.png) |
| **Sampaikan Kebutuhan** — formulir tervalidasi untuk warga. [Lihat screenshot](docs/screenshots/07-sampaikan-kebutuhan.png) | **Validasi Form Kosong** — pesan kesalahan pada seluruh kolom. [Lihat screenshot](docs/screenshots/08-validasi-form-kosong.png) |
| **Validasi Nama Mengandung Angka** — sistem menolak nama yang tidak sesuai aturan. [Lihat screenshot](docs/screenshots/09-validasi-nama-mengandung-angka.png) | **Notifikasi Berhasil Dikirim** — pemberitahuan setelah formulir berhasil dikirim. [Lihat screenshot](docs/screenshots/10-notifikasi-berhasil-dikirim.png) |
| **Daftar Kebutuhan Terkirim** — data kiriman tampil pada daftar aplikasi. [Lihat screenshot](docs/screenshots/11-daftar-kebutuhan-terkirim.png) | |

## Halaman yang Tersedia

Login · Beranda · Pilih Layanan · Pertanyaan Panduan · Hasil Panduan · Kelola Panduan (khusus admin) · Sampaikan Kebutuhan.

## Teknologi

### Sudah Digunakan dalam Kode

| Komponen | Fungsi | Bukti |
| --- | --- | --- |
| Flutter + Dart | Pengembangan aplikasi web dan mobile | `pubspec.yaml`, `lib/` |
| go_router | Routing dan penjagaan rute berdasarkan peran | `lib/app/router.dart` |
| flutter_riverpod | Pengelolaan keadaan aplikasi dan penyediaan repository | `lib/data/providers.dart` |
| Aset JSON seed | Basis aturan panduan yang dimuat saat aplikasi dimulai | `assets/seed/` |
| GitHub | Penyimpanan kode sumber dan riwayat perubahan | Repositori ini |

### Direncanakan — Belum Terintegrasi

| Komponen | Rencana Pemakaian | Status Saat Ini |
| --- | --- | --- |
| Firebase Authentication | Login menggunakan email dan kata sandi | **Belum terpasang.** Tidak ada di `pubspec.yaml`; login masih memakai `InMemoryAuthRepository` dengan akun demo. |
| Cloud Firestore | Menyimpan data panduan dan kebutuhan warga | **Belum terpasang.** Basis aturan dibaca dari `assets/seed/*.json`; formulir warga disimpan di memori. |
| Firebase Hosting | Menayangkan aplikasi versi web | **Belum digunakan.** Versi web dijalankan secara lokal menggunakan `flutter build web` dan server statis. |

Ketiga komponen pada tabel kedua merupakan rencana pengembangan yang telah disiapkan melalui antarmuka repository, bukan fitur yang sudah berjalan. Tidak ada berkas konfigurasi Firebase di repositori ini.

## Rencana Database

**Penyimpanan saat ini masih menggunakan in-memory.**

Formulir **Sampaikan Kebutuhan (H7)** menyimpan kiriman warga melalui `InMemoryKebutuhanRepository`. Data hanya bertahan selama aplikasi berjalan dan akan hilang ketika halaman dimuat ulang.

Firebase **belum terintegrasi**. `pubspec.yaml` belum memuat paket Firebase, belum terdapat `firebase_options.dart`, dan belum terdapat `firestore.rules` di repositori ini.

Rencana pengembangan setelah UTS adalah memindahkan penyimpanan kiriman H7 ke koleksi Cloud Firestore bernama `kebutuhanWarga`.

### Rancangan Struktur Data

| Field | Tipe | Sumber Nilai | Keterangan |
| --- | --- | --- | --- |
| `uid` | string | `request.auth.uid` | Belum ada di kode. Identitas pemilik kiriman dan dasar aturan akses. |
| `namaPemohon` | string | Isian formulir | 3–60 karakter, tanpa angka. |
| `serviceId` | string | Dropdown | `ktp` / `kk` / `domisili`. |
| `serviceNama` | string | Data turunan | Nama layanan dibekukan agar riwayat tidak berubah. |
| `pesan` | string | Isian formulir | 10–300 karakter. |
| `status` | string | Default `'baru'` | Belum ada di kode. Rencana alur: `baru` → `dibaca` → `selesai`. |
| `dibuatPada` | timestamp | `serverTimestamp()` | Waktu server, bukan jam perangkat. |
| `dibacaPada` | timestamp | Admin | Belum ada di kode. Bersifat opsional. |
| `catatanPetugas` | string | Admin | Belum ada di kode. Bersifat opsional dan menunggu keputusan ruang lingkup. |

ID dokumen direncanakan menggunakan **auto-id Firestore**, bukan nomor urut seperti `KB-001` pada repository in-memory. Hal ini bertujuan menghindari benturan nomor ketika beberapa perangkat mengirim data secara bersamaan.

Rancangan lengkap, termasuk contoh dokumen, aturan keamanan, dan daftar berkas yang perlu diubah, tersedia pada [`docs/RANCANGAN-ARSITEKTUR.md` bagian 8.7](docs/RANCANGAN-ARSITEKTUR.md).

Catatan: bagian tersebut merupakan rancangan pengembangan, bukan laporan implementasi Firebase.

## Struktur Proyek

- `lib/app/` — bootstrap aplikasi, tema (style guide bagian 13), dan routing.
- `lib/domain/` — mesin aturan dan entity (*pure Dart*, tanpa impor Flutter atau Firestore).
- `lib/data/` — repository in-memory dan antarmuka yang disiapkan agar Firestore dapat dipasang tanpa mengubah UI.
- `lib/features/` — folder fitur berdasarkan halaman aplikasi.
- `assets/seed/` — data awal berupa JSON untuk aturan panduan.
- `test/` — pengujian otomatis aplikasi.
- `docs/` — dokumentasi teknis, desain, pengujian, dan video presentasi.

## Menjalankan Aplikasi

Pastikan Flutter SDK sudah terpasang.

Jalankan perintah berikut melalui terminal pada direktori proyek:

```bash
flutter pub get
flutter run -d chrome
```

### Membangun Versi Web

Untuk membuat versi web siap dijalankan:

```bash
flutter build web --release
```

Kemudian jalankan server lokal:

```bash
cd build/web
python -m http.server 8080
```

Buka browser dan akses:

`http://localhost:8080`

## Akun Demo

Selama Firebase Authentication belum dipasang, autentikasi menggunakan repository in-memory dengan akun demo berikut:

| Email | Kata Sandi | Peran |
| --- | --- | --- |
| `warga@tegalsari.test` | `123456` | Warga |
| `admin@tegalsari.test` | `123456` | Petugas (menu Kelola Panduan tersedia) |

## Pengujian

Pengujian dilakukan untuk memastikan fungsi aplikasi berjalan sesuai dengan kebutuhan.

Hasil pengujian terakhir:

- **159 pengujian otomatis berhasil** (`flutter test`).
- **Flutter Analyze:** tidak ditemukan masalah (`No issues found!`).
- **Pengujian formulir H7:** terdapat 11 kasus pengujian, terdiri atas 10 kasus otomatis dan 1 kasus pengujian manual melalui browser.

Dokumentasi pengujian formulir tersedia pada [`docs/UJI-FORM.md`](docs/UJI-FORM.md).

## Dokumentasi Lain

Dokumentasi pendukung proyek tersedia pada folder `docs/`:

- [`docs/RANCANGAN-ARSITEKTUR.md`](docs/RANCANGAN-ARSITEKTUR.md) — rancangan arsitektur, mesin aturan, dan tahapan pengerjaan.
- [`docs/RENCANA-VIDEO.md`](docs/RENCANA-VIDEO.md) — rencana video presentasi UTS.
- [`docs/NASKAH-VIDEO.md`](docs/NASKAH-VIDEO.md) — naskah narasi beserta penanda waktu.
- [`docs/UJI-FORM.md`](docs/UJI-FORM.md) — dokumentasi pengujian formulir.

## Video Presentasi UTS

Video presentasi aplikasi IPS-Guide dapat ditonton melalui YouTube berikut:

[**Tonton Video Presentasi UTS IPS-Guide di YouTube**](https://youtu.be/EnlbKMQutEw)

Status akses: **Unlisted (Tidak Publik)**.

Video mencakup penjelasan latar belakang permasalahan, target pengguna, ruang lingkup aplikasi, demonstrasi fitur, rancangan penyimpanan data, serta penutup proyek.

## Artefak Desain (Minggu 2–4)

Berkas asli tugas mingguan disalin ke dalam repositori sebagai dokumentasi proses perancangan aplikasi.

| Artefak | Berkas | Isi |
| --- | --- | --- |
| Persona | [`docs/desain/minggu-02-persona-user-story.docx`](docs/desain/minggu-02-persona-user-story.docx) | Satu persona warga dengan pemisahan temuan dan asumsi. |
| User Story | [`docs/desain/minggu-02-persona-user-story.docx`](docs/desain/minggu-02-persona-user-story.docx) | Lima user story beserta kriteria penerimaan. |
| User Flow & Sitemap | [`docs/desain/minggu-03-user-flow-sitemap.docx`](docs/desain/minggu-03-user-flow-sitemap.docx) | Alur inti Login hingga Hasil Panduan dengan cabang alternatif dan sitemap. |
| Wireframe & Gaya Visual | [`docs/desain/minggu-04-wireframe-figma.docx`](docs/desain/minggu-04-wireframe-figma.docx) | Frame mobile semua halaman utama, keadaan galat, style guide mini, versi web, dan sambungan prototipe. |

### Rancangan UI di Figma

Rancangan antarmuka aplikasi dapat dilihat melalui tautan berikut:

[Wireframe IPS-Guide — Figma](https://www.figma.com/design/R4cNNK3IPYIFB5Hwm3dVp5/23.01.55.0010-%E2%80%93-IPS-Guide-%E2%80%93-Wireframe?node-id=0-1&t=4gIjUGHjf0mNF3NS-1)

**Catatan:** Diagram alur pada dokumen Minggu 3 berhenti pada halaman Hasil Panduan. Halaman Kelola Panduan (H6) dan Sampaikan Kebutuhan (H7) ditambahkan setelah dokumen tersebut dibuat.

## Batasan Proyek

IPS-Guide merupakan aplikasi media panduan interaktif dan bukan sistem pelayanan administrasi kependudukan resmi.

Batasan aplikasi pada versi UTS ini meliputi:

1. Tidak menerbitkan dokumen administrasi kependudukan resmi.
2. Tidak melakukan transaksi pelayanan administrasi.
3. Tidak terintegrasi dengan SIAK maupun sistem kependudukan pemerintah.
4. Belum menggunakan Firebase Authentication dan Cloud Firestore.
5. Belum menggunakan Firebase Hosting.
6. Belum menggunakan billing account, Cloud Functions, maupun autentikasi telepon.
7. Data formulir Sampaikan Kebutuhan masih disimpan sementara di memori aplikasi dan akan hilang ketika halaman dimuat ulang.

Pengembangan selanjutnya diarahkan pada integrasi basis data, autentikasi pengguna, dan peningkatan pengelolaan data agar aplikasi dapat dikembangkan menjadi sistem panduan pelayanan yang lebih terstruktur.

---

**IPS-Guide — Panduan Interaktif Layanan Administrasi Kelurahan Tegalsari.**
