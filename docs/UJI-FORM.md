# Tabel Uji Form — H7 "Sampaikan Kebutuhan"

Dokumen ini memenuhi butir luaran Modul Minggu 7: **tabel uji form ≥ 5 kasus terisi**.  
Seluruh hasil di bawah berasal dari eksekusi nyata, bukan perkiraan. Kasus yang belum  
punya uji otomatis ditandai apa adanya.

- Halaman: `lib/features/kebutuhan/presentation/kebutuhan_page.dart`
- Uji otomatis: `test/widget/kebutuhan_form_test.dart` (9 kasus),  
  `test/data/kebutuhan_repository_test.dart` (4 kasus)
- Penyimpanan: di memori (`InMemoryKebutuhanRepository`) — data hilang saat halaman dimuat ulang

## 1. Kolom dan aturan validasi

| Kolom                | Jenis input                         | Aturan                            | Pesan bila dilanggar                                                                                                           |
| -------------------- | ----------------------------------- | --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| Nama pemohon         | teks (satu baris)                   | wajib; 3–60 karakter; tanpa angka | `Nama pemohon wajib diisi.` · `Nama minimal 3 karakter.` · `Nama maksimal 60 karakter.` · `Nama tidak boleh mengandung angka.` |
| Jenis layanan        | dropdown (3 pilihan)                | wajib dipilih                     | `Pilih jenis layanan.`                                                                                                         |
| Pesan atau kebutuhan | teks multiline (batas 300 karakter) | wajib; minimal 10 karakter        | `Pesan atau kebutuhan wajib diisi.` · `Pesan minimal 10 karakter.`                                                             |

Validasi berjalan saat kolom disentuh (`autovalidateMode.onUserInteraction`) dan sekali lagi  
saat tombol **Kirim** ditekan. Bila ada yang gagal, muncul SnackBar merah  
**"Periksa kembali isian yang ditandai merah."**; bila semua lolos, muncul SnackBar  
**"Kebutuhan terkirim. Petugas akan menindaklanjuti."**

## 2. Tabel kasus uji

| No | Kasus                                        | Input                                                          | Hasil yang diharapkan                                                                        | Hasil nyata                                                                                            | Bukti                                                                                                             |
| -- | -------------------------------------------- | -------------------------------------------------------------- | -------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------- |
| 1  | Semua kolom kosong, langsung Kirim           | —                                                              | tiga pesan galat serentak + SnackBar gagal                                                   | **Sesuai.** Ketiga pesan tampil dan SnackBar merah muncul                                              | uji otomatis `Kirim tanpa isi → tiga pesan galat + SnackBar gagal`; dikonfirmasi manual di browser                |
| 2  | Nama terlalu pendek                          | `El`                                                           | `Nama minimal 3 karakter.`                                                                   | **Sesuai**                                                                                             | uji otomatis `Nama kurang dari tiga karakter ditolak`                                                             |
| 3  | Nama mengandung angka                        | `Elisa123`                                                     | `Nama tidak boleh mengandung angka.`                                                         | **Sesuai**                                                                                             | uji otomatis `Nama yang mengandung angka ditolak`                                                                 |
| 4  | Nama terlalu panjang                         | 61 karakter                                                    | `Nama maksimal 60 karakter.`                                                                 | **Sesuai**                                                                                             | uji otomatis `Nama lebih dari enam puluh karakter ditolak`                                                        |
| 5  | Nama dengan spasi di tepi                    | `  Elisa Sandita Putri  `                                      | spasi dipangkas sebelum disimpan                                                             | **Sesuai**                                                                                             | uji repository `kirim memangkas spasi di tepi dan memberi ID berurutan`                                           |
| 6  | Pesan terlalu pendek                         | 9 karakter                                                     | `Pesan minimal 10 karakter.`                                                                 | **Sesuai**                                                                                             | uji otomatis `Pesan kurang dari sepuluh karakter ditolak`                                                         |
| 7  | Layanan belum dipilih, kolom lain valid      | nama & pesan valid, dropdown kosong                            | `Pilih jenis layanan.`                                                                       | **Sesuai**                                                                                             | uji otomatis `Layanan belum dipilih ditolak meski kolom lain valid`                                               |
| 8  | Pesan kosong, nama & layanan valid           | pesan `""`                                                     | `Pesan atau kebutuhan wajib diisi.`                                                          | **Sesuai.** Dua kolom lain tidak ikut dinyatakan salah                                               | uji otomatis `Pesan kosong ditolak meski nama dan layanan valid`                                                  |
| 9  | Semua isian valid                            | `Elisa Sandita Putri` + `Kartu Keluarga` + pesan ≥ 10 karakter | SnackBar sukses, form kosong kembali tanpa pesan galat, data masuk daftar dengan ID `KB-001` | **Sesuai.** Data tampil di daftar; kolom kembali kosong tanpa memunculkan galat                        | uji otomatis `Data valid tersimpan, SnackBar sukses tampil, dan muncul di daftar`; dikonfirmasi manual di browser |
| 10 | Halaman dimuat ulang setelah kirim           | F5                                                             | daftar kembali kosong                                                                        | **Sesuai.** Ini perilaku yang diminta (penyimpanan di memori)                                          | dikonfirmasi manual di browser                                                                                    |
| 11 | Repositori menolak data kosong (lapis kedua) | `nama=""`, `pesan=""`                                          | `KebutuhanException`, tidak ada data tersimpan                                               | **Sesuai**                                                                                             | uji repository `kirim menolak nama, layanan, atau pesan yang kosong`                                              |

**Ringkasan: 11 dari 11 kasus lulus — 10 beruji otomatis, 1 (No. 10) diuji manual di browser.**

## 3. Cara menjalankan ulang

```bash
flutter analyze
flutter test test/widget/kebutuhan_form_test.dart test/data/kebutuhan_repository_test.dart
```

Hasil terakhir (28 Oktober 2026): `flutter analyze` tanpa temuan; **159 uji lulus**, termasuk 13 uji H7 di atas.

## 4. Catatan jujur

- Modul Minggu 7 menyebut contoh "huruf di kolom angka". Form ini **tidak punya kolom angka**,  
  sehingga padanannya adalah kolom nama yang menolak angka (kasus 3), bukan aturan yang sama.
- Kasus No. 4 dan No. 8 kini beruji otomatis (ditambahkan 28 Oktober 2026). Kasus No. 10  
  (muat ulang halaman) tetap manual karena bergantung pada siklus hidup peramban, bukan widget.
- Uji otomatis berjalan di lingkungan uji Flutter (bukan browser). Uji manual di browser  
  dilakukan pada build release yang disajikan di `http://localhost:8080`.
- Tangkapan layar halaman ini: [`docs/screenshots/07-sampaikan-kebutuhan.png`](screenshots/07-sampaikan-kebutuhan.png).
