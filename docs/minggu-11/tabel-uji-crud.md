
# Tabel Pengujian CRUD — IPS Guide

**Praktikum:** Minggu 11 — CRUD Lengkap: Edit, Hapus, dan Dialog Konfirmasi  
**Aplikasi:** IPS Guide — Panduan Layanan Administrasi Kelurahan Tegalsari  
**Platform:** Flutter Web (Google Chrome)  
**Database:** Cloud Firestore  
**Koleksi:** `kebutuhan_warga`

## A. Pengujian CRUD pada Aplikasi

| No. | Kasus Uji | Hasil yang Diharapkan | Hasil Pengujian |
|---|---|---|---|
| 1 | Membuat kebutuhan baru | Data tersimpan dengan status Menunggu | LULUS — kebutuhan baru tampil dan tetap ada setelah refresh |
| 2 | Membaca daftar kebutuhan | Data milik pengguna ditampilkan | LULUS — daftar kebutuhan berhasil dimuat |
| 3 | Mengedit kebutuhan sendiri berstatus Menunggu | Isi berubah tanpa mengganti pemilik dan tanggal pembuatan | LULUS — perubahan tersimpan, waktu perubahan tampil |
| 4 | Membatalkan penghapusan | Dialog tertutup dan data tetap ada | LULUS — data tidak terhapus |
| 5 | Mengonfirmasi penghapusan | Dokumen terhapus dan daftar diperbarui | LULUS — kartu hilang dan notifikasi berhasil tampil |
| 6 | Memuat ulang setelah Edit/Hapus | Perubahan tetap tersimpan | LULUS — hasil tetap sama setelah refresh |
| 7 | Sinkronisasi real-time antar-tab | Data baru muncul tanpa refresh | LULUS — data baru terlihat pada tab kedua |

## B. Pengujian Firestore Security Rules

Pengujian menggunakan Firestore Emulator dan `@firebase/rules-unit-testing`.

| No. | Kasus Uji | Hasil yang Diharapkan | Hasil Pengujian |
|---|---|---|---|
| 1 | Pemilik mengedit kebutuhan berstatus Menunggu | Diizinkan | LULUS |
| 2 | Pemilik menghapus kebutuhan berstatus Menunggu | Diizinkan | LULUS |
| 3 | Pengguna lain mengedit kebutuhan | Ditolak | LULUS |
| 4 | Pengguna lain menghapus kebutuhan | Ditolak | LULUS |
| 5 | Mengedit kebutuhan berstatus Diproses | Ditolak | LULUS |
| 6 | Menghapus kebutuhan berstatus Diproses | Ditolak | LULUS |
| 7 | Membuat kebutuhan milik sendiri | Diizinkan | LULUS |
| 8 | Warga mengubah status menjadi Diproses | Ditolak | LULUS |
| 9 | Warga mengganti pemilik kebutuhan | Ditolak | LULUS |
| 10 | Membuat kebutuhan milik orang lain | Ditolak | LULUS |
| 11 | Pemilik mengedit data lama tanpa field status | Diizinkan | LULUS |
| 12 | Mengubah tanggal pembuatan | Ditolak | LULUS |
| 13 | Mengubah ID kebutuhan | Ditolak | LULUS |

**Ringkasan:** Pengujian Security Rules terakhir mencatat 18 kasus lulus dan 0 gagal. Tabel ini mencantumkan 13 kasus yang rincian langkah dan hasilnya telah diperiksa.

## C. Pengujian Kualitas Kode

| Pemeriksaan | Hasil |
|---|---|
| `flutter analyze` | 0 error, 0 warning, 41 informasi lint |
| `flutter test` | 159 test lulus |
| Security Rules | Telah dipublikasikan di Firebase Console |
| GitHub | Commit terakhir `4250df7` berhasil di-push ke branch `main` |

## D. Kesimpulan

Pengujian menunjukkan fitur Create, Read, Update, dan Delete pada kebutuhan warga IPS Guide telah berjalan. Pengubahan dan penghapusan dibatasi oleh kepemilikan dokumen serta status Menunggu melalui pemeriksaan aplikasi dan Firestore Security Rules. Penghapusan dilengkapi dialog konfirmasi untuk mencegah tindakan yang tidak disengaja. Data yang ditambahkan atau diubah tetap tersimpan setelah halaman dimuat ulang, sedangkan sinkronisasi penambahan data antar-tab berhasil diuji tanpa refresh.
