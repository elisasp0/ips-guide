
# IPS-Guide

Aplikasi Panduan Interaktif Layanan Administrasi **Kelurahan Tegalsari, Kota Semarang**.

Proyek individu — Elisa Sandita Putri (23.01.55.0010, Kelas A1) — mata kuliah *Mobile and Web Application Development* (Ganjil 2026/2027).

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

| Komponen | Pemakaian saat ini |
| --- | --- |
| Flutter + Dart | Antarmuka aplikasi untuk web dan mobile. |
| `go_router` | Navigasi dan penjagaan rute berdasarkan sesi/peran. |
| `flutter_riverpod` | State management dan repository. |
| Firebase Authentication | Registrasi, login, logout, dan identitas pengguna (UID). |
| Cloud Firestore | Penyimpanan profil, basis pengetahuan, dan kebutuhan warga. |
| JSON seed (`assets/seed/`) | Sumber data awal/pembanding isi basis pengetahuan; aplikasi yang diuji telah membaca data dari Firestore. |
| GitHub | Repositori kode dan riwayat perubahan (commit/push Minggu 10 belum diverifikasi). |

Firebase Hosting **belum diverifikasi/digunakan** dalam pengujian Minggu 10; aplikasi diuji secara lokal di Chrome dengan `flutter run -d chrome`.

## Implementasi Cloud Firestore — Minggu 10

### Collection

| Collection | Fungsi |
| --- | --- |
| `users` | Profil pengguna yang berkaitan dengan Firebase Authentication. |
| `services` | Data tiga layanan utama (KK, KTP-el, Domisili). |
| `questions` | Pertanyaan panduan. |
| `rules` | Aturan keputusan panduan (bukan Security Rules). |
| `requirements` | Katalog persyaratan layanan; 28 ID terlihat dalam verifikasi Console pada 22 November 2026. |
| `steps` | Tahapan pelayanan. |
| `kebutuhan_warga` | Kiriman kebutuhan warga yang dapat dibaca kembali oleh pemiliknya. |

### Struktur dokumen `kebutuhan_warga`

| Field | Tipe | Keterangan |
| --- | --- | --- |
| `id` | string | Sama dengan ID dokumen. |
| `pemilikUid` | string | UID pengguna Firebase Auth yang mengirim kebutuhan. |
| `namaPemohon` | string | Nama pemohon dari formulir. |
| `serviceId` | string | ID layanan (`kk`, `ktp`, atau `domisili`). |
| `serviceNama` | string | Nama layanan pada waktu pengiriman. |
| `pesan` | string | Pesan atau kebutuhan warga. |
| `dibuatPada` | timestamp | Waktu penyimpanan dari server Firestore. |

Document ID menggunakan ID yang dihasilkan Firestore; tidak menggunakan nomor urut lokal. Struktur aktual ini menggantikan rancangan pra-Firebase yang dahulu menamai collection `kebutuhanWarga` dan merencanakan field `status`, `dibacaPada`, atau `catatanPetugas`. Field-field tambahan tersebut **belum termasuk pada dokumen yang diuji**.

### Keamanan

Cloud Firestore Security Rules telah dikonfigurasi agar pengguna login dapat membaca basis pengetahuan. Perubahan basis pengetahuan dibatasi pada akun dengan `role == 'admin'`. Profil pengguna hanya dapat dibaca oleh pemilik. Dokumen `kebutuhan_warga` hanya boleh dibuat oleh pemilik UID terkait dan dibaca oleh pemilik atau admin. Pembatasan pada akses baca langsung tanpa login diperiksa dari kode Security Rules, **belum diuji sebagai permintaan langsung yang menghasilkan `permission-denied`**.

Penggunaan role admin memerlukan profil pengguna yang sesuai; akun baru membuat profil warga. Aturan keamanan produksi perlu dievaluasi lebih lanjut bila ruang lingkup aplikasi berkembang.

Rancangan historis pra-integrasi masih tersedia pada [`docs/RANCANGAN-ARSITEKTUR.md`](docs/RANCANGAN-ARSITEKTUR.md); bila berbeda dari implementasi di atas, tandai sebagai rancangan lama, bukan kondisi aktif.

## Struktur Proyek

- `lib/app/` — bootstrap aplikasi, tema (style guide bagian 13), dan routing.
- `lib/domain/` — mesin aturan dan entity (*pure Dart*, tanpa impor Flutter atau Firestore).
- `lib/data/` — repository, antarmuka, serta implementasi Firebase Authentication dan Cloud Firestore; implementasi in-memory tetap tersedia untuk keperluan pengujian.
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

## Akun Pengujian

Aplikasi kini menggunakan Firebase Authentication. Akun untuk pengujian dibuat atau digunakan melalui Firebase Authentication, bukan kredensial demo yang dipastikan berlaku di setiap instalasi. **Jangan mencantumkan kata sandi akun dalam README atau commit.**

## Pengujian

### Pengujian manual Minggu 10 — 22 November 2026

Hasil berikut didokumentasikan melalui tangkapan layar aplikasi Chrome dan Firebase Console pada percakapan pengujian. Pengujian berjalan pada proyek Firebase IPS Guide, bukan hanya penyimpanan memori lokal.

| No. | Kasus uji | Hasil yang diharapkan | Hasil nyata | Status |
| --- | --- | --- | --- | --- |
| 1 | Login warga dan membuka panduan KK, KTP-el, Domisili | Pertanyaan, hasil aturan, persyaratan, dan tahapan muncul | Ketiga layanan berhasil menampilkan hasil pada skenario yang dicoba. Pada KTP sempat muncul error spasi operator `equals`, lalu hasil KTP berhasil dimuat setelah perbaikan. | Lulus untuk skenario yang diuji |
| 2 | Create: kirim kebutuhan warga | Data baru muncul di aplikasi dan collection `kebutuhan_warga` | Kiriman simulasi `Warga Uji Firestore` untuk layanan KK muncul, daftar bertambah dari 3 menjadi 4, dan dokumen dengan field terkait terlihat di Firestore Console. | Lulus |
| 3 | Read & refresh (F5) | Data tersimpan tetap terlihat setelah refresh | Setelah F5, daftar tetap 4 dan kiriman `Warga Uji Firestore` tetap ditampilkan. | Lulus |
| 4 | Isolasi akun kedua | Akun kedua tidak menampilkan kebutuhan milik akun pertama | Dengan akun warga kedua, daftar kebutuhan menunjukkan 0 dan kiriman akun pertama tidak muncul. | Lulus pada UI yang diuji |
| 5 | Akses aplikasi tanpa login (Incognito) | Halaman yang dilindungi mengarahkan ke login | Di Incognito, aplikasi menampilkan halaman login tanpa data warga. | Lulus untuk proteksi navigasi |
| 6 | Security Rules: baca langsung Firestore tanpa sesi | Permintaan baca ditolak (`permission-denied`) | Kode Security Rules mewajibkan autentikasi, tetapi simulasi/permintaan langsung tanpa login belum dijalankan. | Belum diuji langsung |

**Catatan:** Pengujian UI akun kedua tidak menggantikan pengujian Security Rules secara langsung. Foto Console juga membuktikan keberadaan dokumen saat diverifikasi, bukan kelengkapan isi semua dokumen dalam semua collection.

### Pengujian otomatis — 22 November 2026

Pengujian otomatis dilakukan pada versi aplikasi IPS Guide yang telah terintegrasi dengan Firebase Authentication dan Cloud Firestore.

**Hasil pengujian:**

- `flutter test`: **159 pengujian berhasil** (All tests passed).
- `flutter analyze`: **41 temuan berkategori info**, tanpa error maupun warning.
- Temuan analyzer meliputi 20 penggunaan API yang ditandai deprecated, 20 penggunaan `print()` untuk debugging, dan satu saran penyederhanaan constructor.

Secara fungsional, seluruh pengujian otomatis berhasil. Temuan analyzer dicatat sebagai pekerjaan perapian kode untuk pengembangan berikutnya.

Dokumentasi lama pengujian formulir: [`docs/UJI-FORM.md`](docs/UJI-FORM.md).

### Bukti yang perlu disimpan untuk pengumpulan

- Screenshot Firebase Console yang menunjukkan collection `users`, `services`, `questions`, `rules`, `requirements`, `steps`, dan `kebutuhan_warga` beserta dokumen relevan.
- Screenshot pengiriman kebutuhan warga, dokumen Firestore baru, dan daftar kebutuhan setelah F5.
- Screenshot daftar kosong pada akun warga kedua dan halaman login Incognito.
- Bila sudah dilakukan, bukti uji akses tanpa autentikasi yang mendapat `permission-denied`.
- Minimal dua commit baru dan `git push` ke repository GitHub sesuai arahan Minggu 10; statusnya belum diverifikasi.

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

IPS-Guide merupakan media panduan interaktif, **bukan sistem penerbitan dokumen administrasi kependudukan resmi**. Aplikasi tidak terintegrasi dengan SIAK dan tidak melakukan transaksi layanan administrasi resmi.

Firebase Authentication dan Cloud Firestore **sudah terintegrasi** pada versi yang diuji 22 November 2026. Firebase Hosting belum diverifikasi; demonstrasi Minggu 10 dijalankan secara lokal di Chrome. Fungsi Create dan Read kebutuhan warga sudah teruji, sedangkan Update/Delete bukan ruang lingkup pengujian Minggu 10. Pengujian langsung penolakan akses Firestore tanpa login serta audit seluruh skenario aturan panduan masih perlu dilakukan.

---

**IPS-Guide — Panduan Interaktif Layanan Administrasi Kelurahan Tegalsari.**
