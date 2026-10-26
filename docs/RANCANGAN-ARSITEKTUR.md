# IPS-Guide — Rancangan Arsitektur Aplikasi

**Interactive Public Service Guidance System**
Panduan Layanan Administrasi Kelurahan Tegalsari, Kota Semarang

| Item | Nilai |
|---|---|
| Versi dokumen | **1.4** (pemeriksaan akhir: invarian terminal & validasi tahapan) |
| Versi sebelumnya | 1.3 (review lanjutan) · 1.2 (perbaikan mesin aturan) · 1.1 (integrasi Firebase) · 1.0 (awal) |
| Tanggal | 26 Oktober 2026 |
| Mahasiswa | Elisa Sandita Putri / 23.01.55.0010 / Kelas A1 |
| Teknologi | Flutter 3.47.7 · Dart 3.13.5 · Firebase Authentication · Cloud Firestore · Firebase Hosting |
| Target platform | Flutter Web (Chrome) sebagai prioritas; mobile ikut karena satu basis kode |
| Jumlah halaman | 6 (H1–H6) sesuai sitemap Minggu 3 |
| Status implementasi | **Belum ada kode aplikasi.** Proyek masih scaffold Flutter bawaan (counter app). Tidak ada fitur yang berjalan, belum ada proyek Firebase, belum ada berkas uji. **Belum ada satu pun pengujian yang dijalankan.** |

---

## 0. Riwayat Revisi & Alasan Perubahan

### 0.1 Status nyata saat ini (jangan diklaim lebih)

| Komponen | Status |
|---|---|
| `lib/main.dart` | Masih template counter bawaan Flutter. Belum diubah. |
| Halaman H1–H6 | Belum ada. |
| Mesin aturan IF–THEN | Belum ada. Baru berupa rancangan di dokumen ini. |
| Proyek Firebase | Belum dibuat. Belum ada `firebase_options.dart`. |
| Berkas uji | Hanya `test/widget_test.dart` bawaan (menguji counter). |
| Repository Git | Belum diinisialisasi. |
| Firebase Hosting | Belum ada deployment. |
| Validasi aturan ke Kelurahan | **Belum dilakukan.** Isi persyaratan di §11 belum diverifikasi petugas. |

Dokumen ini adalah **rancangan**, bukan laporan hasil. Setiap klaim "selesai" pada rencana §15 hanya sah setelah ada bukti uji yang menyertainya. Tidak ada hasil pengujian yang dikarang di dokumen ini.

### 0.2 Apa yang berubah dari v1.0

| Aspek | v1.0 | v1.1 | Alasan |
|---|---|---|---|
| Sumber data panduan | JSON statis di `assets/` | **Cloud Firestore** | Batas teknis mata kuliah (Minggu 1–2) mewajibkan Firestore + CRUD |
| Autentikasi | Tidak ada | **Firebase Authentication email/password** | Halaman H1 Login adalah Must (Minggu 1 & 3) |
| Jumlah halaman | 5 halaman bebas | **6 halaman baku H1–H6** | Sitemap Minggu 3 |
| Navigasi | go_router tanpa shell | **Bottom navigation / sidebar** | Rancangan navigasi Minggu 3–4 |
| Gaya visual | Usulan biru/teal | **Style guide Minggu 4** (`#0F766E`) | Konsistensi dengan Figma |
| Hosting | Tidak dibahas | **Firebase Hosting** | Batas teknis mata kuliah |
| Mesin aturan | Pure Dart | **Tetap pure Dart** | Rancangan v1.0 sudah mendukung |
| JSON di `assets/` | Sumber kebenaran | **Hanya data awal (seed)** | Sesuai arahan; tanpa mekanisme offline |

### 0.3 Temuan review teknis atas v1.1 (dasar perubahan ke v1.2)

Review difokuskan pada kebenaran algoritma mesin aturan, bukan pada tampilan. Sepuluh temuan berikut ditemukan **sebelum** satu baris kode ditulis.

| # | Temuan | Bukti / dampak | Perbaikan | Bagian |
|---|---|---|---|---|
| **T-01** | Sesi berhenti begitu `outcome` ditetapkan | `KTP-R03` menetapkan `dapat_diproses` sebelum `domisili_pemohon` ditanyakan, sehingga `KTP-R08` (domisili luar) **tidak pernah** dievaluasi. Hal sama terjadi pada `DOM-R02` vs `DOM-R03`. | Pisahkan **outcome sementara** dari **kondisi terminal**; sesi hanya berhenti bila aturan `terminal` menyala | §10.4, §10.5 |
| **T-02** | `KTP-R04`–`R07` menambah persyaratan tetapi **tidak menetapkan outcome** | S04–S07 (penggantian KTP) akan menghasilkan `outcome == null` → "panduan belum tersedia", padahal jalurnya sah | Setiap aturan cabang wajib menetapkan outcome | §11.2 |
| **T-03** | Pertanyaan yang dapat menghentikan sesi diletakkan paling akhir | `domisili_pemohon` adalah Q5, padahal ia bisa menghentikan sesi | Urutkan pertanyaan penentu-terminal lebih awal | §11.1 |
| **T-04** | Tombol "Kembali" menghapus fakta, tetapi `fired` tidak direset | Aturan yang bergantung pada fakta terhapus tetap menyala → persyaratan "hantu" | Inferensi dihitung ulang **dari nol** setiap kali jawaban berubah | §10.4 |
| **T-05** | Outcome ditentukan "yang terakhir menang" | Bergantung urutan evaluasi, tidak reprodusibel | Outcome = aturan **berprioritas tertinggi** di antara yang menyala | §10.5 |
| **T-06** | Query `services` memfilter `aktif == true` | Layanan nonaktif **hilang dari daftar**, padahal wireframe Minggu 4 meminta ia tetap tampil bertanda "belum tersedia" | Baca semua layanan, tandai status di UI | §8.3 |
| **T-07** | Filter `aktif` pada `questions`/`rules` tidak ada; index tidak memuat `aktif` | Data nonaktif ikut terbaca; query komposit gagal | Tambahkan filter + index berisi `aktif` | §8.3 |
| **T-08** | Aturan baca `guidanceLogs` memakai `resource.data.uid` tanpa syarat query | Query daftar akan ditolak (permission denied) | Query wajib `where('uid', isEqualTo: uid)` | §8.4 |
| **T-09** | Penjelasan privasi menyebut "hanya email dan nama", tanpa menyatakan keduanya tetap data pribadi | Risiko etis dan salah paham | Nyatakan eksplisit: email/nama **adalah** data pribadi; NIK/KK **tidak** disimpan | §1.4 |
| **T-10** | Klaim "pengguna <17 berhenti setelah 1 pertanyaan" | Salah: `status_perkawinan` tetap harus ditanya → **2 pertanyaan** | Perbaiki angka pada §11.1 | §11.1 |

**Kesimpulan review:** rancangan v1.1 tidak dapat langsung diimplementasikan. Temuan T-01, T-02, dan T-04 bersifat **fungsional** — bila diimplementasikan apa adanya, aplikasi akan memberi jawaban salah pada jalur yang sah. Ketiganya diperbaiki di v1.2 sebelum Tahap 1 dimulai.

### 0.4 Temuan review lanjutan atas v1.2 (dasar perubahan ke v1.3)

| # | Temuan | Bukti | Perbaikan | Bagian |
|---|---|---|---|---|
| **U-01** | Sumber tahapan tidak jelas | `KTP-R03` di §8.2 memuat 5 tahap, di §11.2 hanya "+ perekaman", sedangkan trace S03 menampilkan 5 tahap. Tiga sumber saling bertentangan → implementasi akan menebak | Tahapan umum dipindah ke `services.stepsDasar`; aturan tidak lagi menambah tahap | §8.1, §11.5 |
| **U-02** | `status_perkawinan = pernah_menikah` pada usia <17 tidak ditangani aturan mana pun | `outcome == null` tanpa penjelasan; pengguna pada jalur sah tidak mendapat arah | Aturan `KTP-R10` yang **tidak** menetapkan outcome dan **tidak** mengarang persyaratan; hanya catatan "belum tervalidasi" | §11.2 |
| **U-03** | Perilaku `showIf` saat fakta belum tersedia tidak didefinisikan | Pertanyaan dapat terlewati keliru | Logika tiga nilai (`true`/`false`/`undefined`) + validasi dependensi saat basis pengetahuan dimuat | §10.4.1 |
| **U-04** | Fakta jalur lama tidak dibersihkan saat jawaban diubah | Aturan jalur lama tetap menyala → persyaratan salah untuk kondisi baru | **Pemangkasan fakta** iteratif sebelum inferensi | §10.4.2 |
| **U-05** | Tiga lapis pengamanan tidak dibedakan | Klaim "warga tidak bisa membuka H6" disalahartikan sebagai jaminan server | Tabel lapisan + batas klaim masing-masing | §8.5 |
| **U-06** | `allow write` mengizinkan hapus permanen | Bertentangan dengan keputusan "hapus = nonaktifkan"; referensi aturan dapat terputus | `allow delete: if false` pada seluruh koleksi pengetahuan | §8.4 |
| **U-07** | Dokumen `users/{uid}` yang hilang membuat `isAdmin()` galat | Semua pembacaan basis pengetahuan ditolak | Ditangani eksplisit saat login | §9.1 |
| **U-08** | `KTP-R09`, `KK-R09`, `DOM-R06` hanya menambah tahapan | Redundan setelah U-01; berisiko menduplikasi tahapan | Ketiga aturan dihentikan (tidak dipakai lagi) | §11 |

**Sifat perubahan v1.3:** seluruh perbaikan v1.2 **dipertahankan tanpa diubah**. v1.3 hanya menutup celah yang masih terbuka, bukan merombak mekanisme. Yang berubah secara struktural hanyalah sumber tahapan (U-01), dan itu justru menyederhanakan basis aturan.

### 0.5 Temuan pemeriksaan akhir atas v1.3 (dasar perubahan ke v1.4)

Pemeriksaan difokuskan pada dua hal saja: kebenaran interaksi terminal–outcome, dan status validasi tahapan.

| # | Temuan | Bukti | Perbaikan | Bagian |
|---|---|---|---|---|
| **V-01** | Tidak ada invarian yang menjamin outcome pemenang berasal dari aturan terminal | §10.6 hanya berisi **tabel bukti** (dokumentasi), bukan pemeriksaan. Bila aturan terminal berprioritas lebih rendah daripada aturan non-terminal yang juga menyala, sesi berhenti dengan outcome milik aturan lain — bisa berbeda nilainya | Tiga invarian `V-1`/`V-2`/`V-3` yang diperiksa saat basis pengetahuan dimuat + penjaga saat runtime | §10.6.1 |
| **V-02** | Validasi untuk aturan buatan admin tidak ada di jalur simpan | Admin dapat menyimpan aturan terminal tanpa outcome, atau dua aturan terminal yang bertentangan, lalu basis pengetahuan baru ditolak saat dimuat — pengguna melihat error tanpa sebab yang jelas | Validasi yang sama dijalankan **sebelum simpan** di H6, bukan hanya saat muat | §12.5 |
| **V-03** | Penanda "belum divalidasi" pada tahapan tersebar dan tidak seragam | §11.5 menyebut asumsi perekaman, tetapi trace S03 dan tabel `stepsDasar` menampilkannya sebagai fakta | Tabel status validasi per tahap + penanda baku yang wajib dipertahankan | §11.5, §14.4 |

**Sifat perubahan v1.4:** minimal dan aditif. Tidak ada mekanisme v1.3 yang dibatalkan. Yang ditambahkan hanyalah **pemeriksaan** (agar konfigurasi bertentangan ditolak lebih awal) dan **penanda** (agar asumsi tidak terbaca sebagai ketentuan resmi).

---

## 1. Ringkasan & Ruang Lingkup

IPS-Guide memandu warga memilih layanan, menjawab pertanyaan bertahap, lalu menerima daftar persyaratan dokumen dan tahapan pelayanan yang sesuai kondisi mereka. Penentuan hasil dilakukan oleh mesin inferensi berbasis aturan IF–THEN yang berjalan di sisi klien.

### 1.1 Yang dilakukan sistem
- Autentikasi warga dengan email dan kata sandi.
- Menampilkan 3 layanan: Pengurusan KTP, Kartu Keluarga (KK), Surat Domisili.
- Memberikan pertanyaan bertahap yang **adaptif** (pertanyaan berikutnya bergantung jawaban sebelumnya).
- Mengevaluasi jawaban dengan basis aturan IF–THEN yang tersimpan di Firestore.
- Menampilkan persyaratan dokumen, tahapan pelayanan, catatan, dan status kelayakan.
- Menjelaskan aturan mana yang menyebabkan suatu dokumen diminta (*explanation facility*).
- Menyediakan halaman admin untuk mengelola data panduan (CRUD).

### 1.2 Batasan ruang lingkup skripsi
- Hanya media panduan. **Tidak** menerbitkan dokumen resmi.
- **Tidak** melakukan transaksi administrasi.
- **Tidak** terintegrasi dengan database kependudukan (SIAK) atau sistem pemerintahan lain.
- Tidak ada unggah berkas, tidak ada pengajuan layanan online, tidak ada notifikasi WhatsApp.
- Data yang digunakan adalah **data simulasi** hasil penyusunan aturan, bukan data warga sungguhan.

### 1.3 Batas teknis mata kuliah (Minggu 1–4)
- Stack wajib: Flutter/Dart, Firebase Authentication (email/password), Cloud Firestore, Firebase Hosting, GitHub, Figma.
- Dilarang: billing account, Cloud Functions, autentikasi telepon/OTP, kewajiban unggah berkas besar.
- Halaman Must: H1–H5. Halaman pendukung: H6.

### 1.4 Privasi dan data pribadi (diperjelas pada v1.2)

Bagian ini ditulis eksplisit karena v1.1 terlalu kabur dan dapat menimbulkan kesalahpahaman etis.

**Yang disimpan sebagai data pribadi:**

| Data | Lokasi | Sifat |
|---|---|---|
| Email | Firebase Authentication + `users/{uid}.email` | **Data pribadi** |
| Nama akun | `users/{uid}.nama` | **Data pribadi** |
| UID | Firebase Authentication | Pengenal teknis |
| Peran (`warga`/`admin`) | `users/{uid}.role` | Data internal |

Email dan nama **adalah data pribadi** dan diperlakukan sebagai data pribadi: hanya dapat dibaca pemiliknya dan admin, sesuai `firestore.rules` §8.4. Aplikasi tidak mengirimkannya ke pihak ketiga mana pun selain Firebase sebagai penyedia backend.

**Yang TIDAK disimpan sama sekali:**

- NIK, nomor Kartu Keluarga, nomor akta, atau nomor dokumen apa pun.
- Alamat, tanggal lahir, nama anggota keluarga.
- Salinan/foto dokumen (tidak ada fitur unggah berkas).
- **Jawaban kuesioner pengguna.** Peta jawaban hanya hidup di memori selama satu sesi; hilang saat halaman ditutup atau di-refresh. Tidak ada koleksi yang menyimpan jawaban.

**Yang bersifat opsional dan harus diputuskan:** koleksi `guidanceLogs` (§8.1) bila dipakai hanya menyimpan `uid`, `serviceId`, `outcome`, dan waktu — **tidak** menyimpan peta jawaban, karena jawaban dapat mengungkap kondisi pribadi (mis. status perkawinan, kepemilikan dokumen). Bila tidak diperlukan untuk "ringkasan panduan terakhir" di Beranda, koleksi ini sebaiknya tidak dibuat.

**Batas tegas terhadap data kependudukan:** tidak ada koneksi ke SIAK, Disdukcapil, atau basis data pemerintah mana pun. Aplikasi tidak membaca maupun menulis data kependudukan. Karena itu batasan skripsi "tidak terintegrasi database kependudukan" terpenuhi, sementara batas mata kuliah "wajib Firestore" juga terpenuhi — Firestore hanya menyimpan **basis pengetahuan panduan** dan **akun aplikasi**.

---

## 2. Pemetaan ke Komponen Sistem Pakar

| Komponen sistem pakar | Wujud konkret | Lokasi |
|---|---|---|
| **Knowledge Base** | Koleksi Firestore: `services`, `questions`, `rules`, `requirements`, `steps` | Firestore |
| **Inference Engine** | *Forward chaining* + resolusi konflik, pure Dart | `lib/domain/engine/` |
| **Working Memory** | `FactBase` — fakta jawaban + fakta turunan, hanya di memori sesi | `lib/domain/engine/fact_base.dart` |
| **Explanation Facility** | `sourceRuleId` pada setiap persyaratan; sheet "Mengapa dokumen ini diminta?" | `lib/features/result/` |
| **User Interface** | H1–H6 | `lib/features/` |
| **Knowledge Acquisition** | H6 Kelola Panduan (Admin) — CRUD ke Firestore | `lib/features/admin/` |
| **Penyimpanan pengguna** | Firebase Authentication + koleksi `users` | Firebase |

---

## 3. Arsitektur Aplikasi

### 3.1 Gaya arsitektur

**Layered + feature-first**, dengan ketergantungan satu arah:

```
Presentation (features/)  →  Application (controller)  →  Domain (engine + entities)  →  Data (repository)  →  Firestore
```

Aturan yang tidak boleh dilanggar:
1. **`lib/domain/` tidak boleh mengimpor `package:flutter/*` maupun `cloud_firestore`.** Harus pure Dart agar bisa diuji cepat dan tidak terikat vendor.
2. **UI tidak pernah mengevaluasi aturan sendiri.**
3. **Repository adalah satu-satunya pintu masuk data.**
4. **DTO Firestore tidak bocor ke domain.**

### 3.2 Lapisan

| Lapisan | Tanggung jawab | Contoh |
|---|---|---|
| `app/` | Bootstrap, tema, routing, guard autentikasi | `app.dart`, `router.dart`, `theme.dart` |
| `core/` | Konstanta, widget bersama, formatter status | `AppScaffold`, `StatusBadge` |
| `domain/entities/` | Model domain immutable | `Rule`, `GuidanceQuestion`, `Requirement` |
| `domain/engine/` | Mesin inferensi & sesi panduan | `RuleEngine`, `ConditionEvaluator`, `GuidanceSession` |
| `data/` | Repository + DTO + pemetaan | `FirestoreKnowledgeBaseRepository` |
| `features/` | Satu folder per halaman | `auth/`, `home/`, `services/`, `guidance/`, `result/`, `admin/` |

### 3.3 Dua implementasi repository

```dart
abstract class KnowledgeBaseRepository {
  Future<List<GuidanceService>> loadServices();   // untuk H3 — termasuk yang nonaktif
  Future<KnowledgeBase> loadService(String serviceId); // untuk H4/H5
}
```

| Implementasi | Kapan dipakai | Untuk apa |
|---|---|---|
| `InMemoryKnowledgeBaseRepository` | Tahap 2–4 | Membaca `assets/seed/` agar **UI dan engine bisa dibangun & diuji sebelum Firebase ada** |
| `FirestoreKnowledgeBaseRepository` | Tahap 6 dan seterusnya | Sumber data resmi aplikasi |

Keduanya memenuhi antarmuka yang sama, sehingga **UI tidak berubah** saat sumber data berganti.

> **Yang sengaja tidak dibuat:** cache offline kustom, sinkronisasi dua arah, antrean tulis luring, atau logika "pakai Firestore, kalau gagal pakai JSON". Bila Firestore gagal dimuat, aplikasi menampilkan keadaan **"layanan belum tersedia"**.

### 3.4 Alur data saat runtime

```
Login (Firebase Auth) → Beranda → Pilih Layanan
   │
   ▼
repository.loadService(serviceId)      ← satu-satunya titik akses jaringan untuk panduan
   │  dipetakan ke Entity (aktif difilter)
   ▼
GuidanceSession (memegang answers + KnowledgeBase)
   │  pengguna menjawab → inferensi dihitung ulang dari nol → outcome
   ▼
Hasil Panduan (render murni, tanpa akses jaringan)
```

Jaringan hanya disentuh dua kali: saat login, dan saat memuat basis pengetahuan satu layanan.

### 3.5 State management

**`flutter_riverpod`**. Controller testable tanpa `BuildContext`; `Provider` mudah di-*override* saat pengujian (ganti Firestore dengan in-memory); `AsyncValue` menangani loading/error/data secara eksplisit.

### 3.6 Navigasi

`go_router` dengan **ShellRoute**:

```
ShellRoute (navigasi utama)
├── /            → H2 Beranda
├── /layanan     → H3 Pilih Layanan
└── /panduan     → tab Panduan (sesi aktif atau keadaan kosong)

Di luar shell:
├── /login              → H1 Login
├── /panduan/:serviceId → H4 Pertanyaan Panduan
├── /hasil              → H5 Hasil Panduan
└── /admin              → H6 Kelola Panduan (Admin)
```

- **Guard login**: belum masuk → `/login`.
- **Guard peran**: `/admin` hanya `role == 'admin'`.
- **Guard sesi**: `/hasil` tanpa sesi aktif → `/layanan`.
- Refresh di tengah kuesioner mengembalikan pengguna ke `/layanan`.

---

## 4. Struktur Folder

```
ips_guide/
├── lib/
│   ├── main.dart
│   ├── firebase_options.dart
│   ├── app/{app,router,theme}.dart
│   ├── core/
│   │   ├── constants/{app_strings,app_colors}.dart
│   │   ├── layout/responsive.dart
│   │   └── widgets/{app_scaffold,status_badge,info_callout,section_title}.dart
│   ├── domain/                         # PURE DART
│   │   ├── entities/
│   │   │   ├── guidance_service.dart
│   │   │   ├── guidance_question.dart
│   │   │   ├── answer_option.dart
│   │   │   ├── rule.dart
│   │   │   ├── rule_condition.dart
│   │   │   ├── rule_action.dart
│   │   │   ├── requirement.dart
│   │   │   ├── service_step.dart
│   │   │   ├── guidance_note.dart
│   │   │   ├── guidance_result.dart
│   │   │   ├── knowledge_base.dart
│   │   │   └── app_user.dart
│   │   └── engine/
│   │       ├── fact_base.dart
│   │       ├── condition_evaluator.dart
│   │       ├── rule_engine.dart          # inferensi + pilihOutcome + terminal
│   │       ├── question_selector.dart
│   │       └── guidance_session.dart     # jawaban + recompute
│   ├── data/
│   │   ├── models/                       # DTO + mapper
│   │   ├── repositories/
│   │   │   ├── knowledge_base_repository.dart
│   │   │   ├── in_memory_knowledge_base_repository.dart
│   │   │   ├── firestore_knowledge_base_repository.dart
│   │   │   └── auth_repository.dart
│   │   └── seed/seed_loader.dart
│   └── features/
│       ├── auth/{application,presentation}
│       ├── home/presentation/home_page.dart
│       ├── services/presentation/service_list_page.dart
│       ├── guidance/{application,presentation}
│       ├── result/{application,presentation}
│       └── admin/presentation/admin_page.dart
├── assets/seed/{services,questions,requirements,steps}.json
├── assets/seed/rules/{ktp,kk,domisili}.json
├── test/
│   ├── domain/engine/{condition_evaluator,rule_engine,question_selector}_test.dart
│   ├── data/knowledge_base_mapping_test.dart
│   ├── scenario/scenario_test.dart
│   └── widget/{login_flow,guidance_flow,result_flow}_test.dart
├── firestore.rules
├── firebase.json
└── docs/RANCANGAN-ARSITEKTUR.md
```

---

## 5. Daftar Halaman (H1–H6)

| Kode | Nama halaman | Rute | Tujuan | Prioritas |
|---|---|---|---|---|
| H1 | **Login** | `/login` | Autentikasi email/password; pesan bila kredensial salah | Must |
| H2 | **Beranda** | `/` | Pusat awal, sapaan, tombol "Mulai Panduan" | Must |
| H3 | **Pilih Layanan** | `/layanan` | KTP, KK, Surat Domisili; menandai layanan yang belum tersedia | Must |
| H4 | **Pertanyaan Panduan** | `/panduan/:serviceId` | Pertanyaan bertahap; validasi kelengkapan | Must |
| H5 | **Hasil Panduan** | `/hasil` | Persyaratan, tahapan, catatan; atau "panduan belum tersedia" | Must |
| H6 | **Kelola Panduan (Admin)** | `/admin` | CRUD data layanan, pertanyaan, aturan, persyaratan, tahapan | Should |

Nama halaman dipakai identik di flow, sitemap, menu, judul AppBar, dan nama frame Figma. "Pertanyaan Interaktif" (Minggu 4) dibakukan menjadi **Pertanyaan Panduan**.

### 5.1 Keadaan alternatif wajib

| Halaman | Keadaan | Pemicu |
|---|---|---|
| H1 Login | **Login – Galat** | Email/password salah, email tidak valid, kolom kosong |
| H3 Pilih Layanan | **Layanan belum tersedia** | Firestore kosong/gagal, atau `service.aktif == false` |
| H4 Pertanyaan Panduan | **Galat jawaban belum lengkap** | "Lihat Panduan" ditekan sebelum semua pertanyaan terjawab |
| H5 Hasil Panduan | **Panduan belum tersedia** | Tidak ada aturan yang menetapkan outcome (`outcome == null`) |

---

## 6. Navigasi Mobile & Web

| Layar | Pola | Widget |
|---|---|---|
| < 600 px | Bottom navigation, 3 item | `NavigationBar` |
| ≥ 600 px | Sidebar kiri, item sama | `NavigationRail` |

Item: `Beranda` · `Layanan` · `Panduan`. Tombol **Keluar** di AppBar. Menu **Kelola Panduan** hanya muncul untuk admin. H4/H5 dibatasi lebar 720 px pada layar lebar; H2/H3 memakai grid 2–3 kolom.

---

## 7. Model Data (Entity)

```dart
class AppUser { final String uid, email, nama; final UserRole role; }

class GuidanceService {
  final String id, nama, deskripsi, ikon;
  final int urutan, estimasiHariMin, estimasiHariMax;
  final bool aktif;            // false → kartu tampil "belum tersedia", tidak bisa dipilih
  final List<String> stepsDasar; // ID tahapan umum untuk SEMUA pengajuan layanan ini
}

class GuidanceQuestion {
  final String id, serviceId, factKey, teks;
  final int urutan;
  final List<AnswerOption> opsi;
  final RuleCondition? showIf;
  final bool aktif;
}

class Rule {
  final String id, serviceId;
  final int priority;
  final String deskripsi;
  final List<RuleCondition> when;   // AND
  final RuleAction then;
  final bool aktif;
}

class RuleAction {
  final List<String> addRequirements;
  final List<String> addSteps;      // varian tahapan; pada v1.3 belum dipakai (§11.5)
  final Map<String, String> addFacts;
  final List<String> addNotes;
  final Outcome? setOutcome;        // null = aturan tidak menetapkan keputusan
  final bool terminal;              // true = tidak ada pertanyaan tersisa yang dapat mengubah keputusan
}

class Requirement {
  final String id, nama; final String? keterangan;
  final bool wajib; final String sourceRuleId;
}

class GuidanceResult {
  final GuidanceService service;
  final Outcome? outcome;             // null → "panduan belum tersedia"
  final List<Requirement> requirements; // kosong bila outcome == tidakDapatDiproses
  final List<ServiceStep> steps;
  final List<GuidanceNote> notes;
  final Map<String, String> answers;
  final List<RuleTrace> trace;
  final bool terminal;
}
```

Semua entity immutable. `Map<String, dynamic>` hanya hidup di `data/models/`.

---

## 8. Struktur Cloud Firestore

### 8.1 Daftar koleksi

| Koleksi | Dokumen | Isi | Dibaca | Ditulis |
|---|---|---|---|---|
| `services` | `ktp`, `kk`, `domisili` | Data layanan + `aktif` + **`stepsDasar`** (tahapan umum) | Warga, Admin | Admin |
| `questions` | `Q_KTP_SUDAH_PUNYA`, … | Pertanyaan + `showIf` + opsi + `aktif` | Warga, Admin | Admin |
| `rules` | `KTP-R03`, … | Aturan IF–THEN + `aktif` | Warga, Admin | Admin |
| `requirements` | `REQ_KK_ASLI`, … | Katalog persyaratan + `aktif` | Warga, Admin | Admin |
| `steps` | `STEP_LOKET`, … | Katalog tahapan + `aktif` | Warga, Admin | Admin |
| `users` | `{uid}` | Email, nama, peran | Pemilik + Admin | Pemilik (terbatas) / Admin |
| `guidanceLogs` | auto-id | `uid`, `serviceId`, `outcome`, `createdAt` — **tanpa peta jawaban** | Pemilik + Admin | Pemilik (create) |

### 8.2 Contoh dokumen

**`services/ktp`** — perhatikan `stepsDasar` (U-01)
```json
{ "kode": "ktp", "nama": "Pengurusan KTP", "deskripsi": "Penerbitan dan penggantian KTP-el",
  "ikon": "badge", "urutan": 1, "aktif": true, "estimasiHariMin": 3, "estimasiHariMax": 7,
  "stepsDasar": ["STEP_LOKET", "STEP_SERAH_BERKAS", "STEP_VERIFIKASI", "STEP_REKAM", "STEP_AMBIL"] }
```

**`rules/KTP-R03`** — tidak lagi memuat `addSteps`
```json
{
  "serviceId": "ktp", "priority": 70, "aktif": true,
  "deskripsi": "Pemohon 17 tahun atau lebih dan belum pernah memiliki KTP, sehingga termasuk pengajuan KTP baru.",
  "when": [
    { "fact": "kategori_usia", "op": "equals", "value": "17_ke_atas" },
    { "fact": "sudah_punya_ktp", "op": "equals", "value": "tidak" }
  ],
  "then": {
    "setOutcome": "dapat_diproses",
    "terminal": false,
    "addRequirements": ["REQ_KK_ASLI", "REQ_AKTA_KELAHIRAN", "REQ_RTRW", "REQ_F101"],
    "addFacts": { "jenis_pengajuan_ktp": "baru" },
    "addNotes": ["NOTE_REKAM_DI_KELURAHAN"]
  }
}
```

**`rules/KTP-R10`** — jalur belum tervalidasi (U-02), sengaja **tanpa** `setOutcome`
```json
{
  "serviceId": "ktp", "priority": 88, "aktif": true,
  "deskripsi": "Pemohon berusia di bawah 17 tahun dengan status pernah menikah. Ketentuan administrasi untuk jalur ini belum divalidasi petugas.",
  "when": [
    { "fact": "kategori_usia", "op": "equals", "value": "di_bawah_17" },
    { "fact": "status_perkawinan", "op": "equals", "value": "pernah_menikah" }
  ],
  "then": {
    "terminal": false,
    "addRequirements": [],
    "addNotes": ["NOTE_KASUS_BELUM_TERCAKUP"]
  }
}
```

**`users/{uid}`**
```json
{ "email": "warga@contoh.ac.id", "nama": "Warga Contoh", "role": "warga", "createdAt": "<timestamp>" }
```

### 8.3 Query yang dijalankan (diperbaiki pada v1.2)

```dart
// H3 — SEMUA layanan, TANPA filter aktif.
// Alasan: layanan nonaktif harus tetap tampil bertanda "belum tersedia" (wireframe Minggu 4).
// Bila difilter, ia hilang dari daftar dan status itu tidak pernah muncul. (T-06)
services.get();

// H4/H5 — hanya pertanyaan & aturan yang aktif (T-07)
questions.where('serviceId', isEqualTo: serviceId)
         .where('aktif', isEqualTo: true);

rules.where('serviceId', isEqualTo: serviceId)
     .where('aktif', isEqualTo: true);

// Katalog kecil (±20 dan ±10 dokumen): dibaca utuh, lalu difilter `aktif` di memori.
requirements.get();
steps.get();
```

**Index komposit yang wajib dibuat di Firebase Console:**

| Koleksi | Field 1 | Field 2 | Field 3 |
|---|---|---|---|
| `questions` | `serviceId` ASC | `aktif` ASC | `urutan` ASC |
| `rules` | `serviceId` ASC | `aktif` ASC | `priority` DESC |

**Jebakan yang harus dihindari:** filter `where('aktif', isEqualTo: true)` **tidak akan mencocokkan dokumen yang tidak memiliki field `aktif`**. Setiap penulisan — termasuk seed importer dan form admin — **wajib** menyertakan `aktif: true` secara eksplisit. Dokumen tanpa field itu akan "hilang" tanpa pesan galat, dan penyebabnya sulit dilacak. Validasi ini juga dijalankan di `test/data/knowledge_base_mapping_test.dart`.

### 8.4 Aturan keamanan (`firestore.rules`)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function signedIn() { return request.auth != null; }
    function isAdmin() {
      return signedIn() &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // Koleksi pengetahuan: baca = semua pengguna terautentikasi.
    // Tulis = admin. Hapus permanen = TIDAK diizinkan (U-06) — "hapus" berarti aktif: false.
    match /services/{id}     { allow read: if signedIn(); allow create, update: if isAdmin(); allow delete: if false; }
    match /questions/{id}    { allow read: if signedIn(); allow create, update: if isAdmin(); allow delete: if false; }
    match /rules/{id}        { allow read: if signedIn(); allow create, update: if isAdmin(); allow delete: if false; }
    match /requirements/{id} { allow read: if signedIn(); allow create, update: if isAdmin(); allow delete: if false; }
    match /steps/{id}        { allow read: if signedIn(); allow create, update: if isAdmin(); allow delete: if false; }

    match /users/{uid} {
      allow read:   if signedIn() && (request.auth.uid == uid || isAdmin());
      allow create: if signedIn() && request.auth.uid == uid
                    && request.resource.data.role == 'warga'
                    && request.resource.data.keys().hasAll(['email', 'nama', 'role']);
      allow update: if isAdmin()
                    || (request.auth.uid == uid
                        && request.resource.data.role == resource.data.role);
      allow delete: if isAdmin();
    }

    match /guidanceLogs/{id} {
      allow create: if signedIn() && request.resource.data.uid == request.auth.uid;
      allow read:   if signedIn() && (resource.data.uid == request.auth.uid || isAdmin());
      allow update, delete: if false;
    }
  }
}
```

**Catatan penting (T-08):** aturan `read` pada `guidanceLogs` mengacu `resource.data.uid`. Untuk operasi `list`, Firestore mensyaratkan query **memuat filter yang sama**, yaitu:

```dart
// BENAR
firestore.collection('guidanceLogs').where('uid', isEqualTo: uid).get();

// SALAH — akan ditolak dengan permission-denied, bukan hasil kosong
firestore.collection('guidanceLogs').get();
```

**Bootstrap admin pertama:** tidak bisa lewat aplikasi (aturan `create` hanya mengizinkan `role: 'warga'`). Admin pertama diubah **manual** di Firebase Console. Prosedur ini didokumentasikan, bukan diakali di kode.

**Perilaku `isAdmin()` bila dokumen `users/{uid}` tidak ada (U-07):** `get()` mengembalikan `null`, lalu `.data.role` menimbulkan galat evaluasi, dan Firestore **menolak** permintaan. Artinya aman dari sisi keamanan (gagal-tertutup), tetapi berakibat **semua pembacaan basis pengetahuan ditolak** untuk pengguna yang sudah terautentikasi namun dokumen profilnya hilang. Penanganan di aplikasi ada di §9.1.

**Belum diuji.** Aturan keamanan di atas baru berupa rancangan. Pengujian dengan Emulator Suite bersifat opsional dan **belum dijalankan**; tidak ada satu pun kasus di bawah ini yang boleh disebut "lulus" sampai benar-benar dieksekusi.

### 8.5 Tiga lapis pengamanan (dibedakan pada v1.3 — U-05)

Klaim "warga tidak dapat membuka H6" **bukan** jaminan keamanan. Ia hanya kenyamanan antarmuka. Yang benar-benar melindungi data adalah aturan Firestore.

| Lapis | Mekanisme | Yang dicegah | Dapat dilewati? | Tingkat keandalan |
|---|---|---|---|---|
| **1. UI** | Menu admin tidak dirender; tombol dinonaktifkan | Salah klik oleh pengguna biasa | **Ya** — sangat mudah (ubah state, devtools) | Kosmetik |
| **2. Guard rute** | `go_router` redirect berdasarkan status login & `role` | Membuka `/admin` lewat URL | **Ya** — panggilan SDK langsung tidak melewati router | Kenyamanan + pertahanan dangkal |
| **3. Otorisasi server** | `firestore.rules` (`isAdmin()` pada setiap tulis) | Menulis/mengubah data panduan | **Tidak** — dievaluasi di server | **Satu-satunya yang menentukan** |

Konsekuensi yang harus dinyatakan jujur dalam skripsi:

- Warga **dapat** membaca koleksi `services`, `questions`, `rules`, `requirements`, `steps` — dan itu memang diperlukan agar panduan berjalan. Isi koleksi ini bukan rahasia.
- Warga **tidak dapat** menulis ke koleksi tersebut, sekalipun ia tahu ID dokumen dan memanggil SDK langsung. Inilah klaim yang sah.
- `role` di klien hanya dipakai untuk **menampilkan menu**. Bila diubah di sisi klien, tampilan berubah tetapi setiap penulisan tetap ditolak server.
- Bila admin diturunkan perannya saat pengguna masih login, menu admin dapat **masih tampak** (nilai `role` di memori belum diperbarui). Penulisan tetap gagal. Ini perilaku yang benar dan perlu dijelaskan, bukan bug.

| Kemampuan | Warga | Admin |
|---|---|---|
| Login / keluar | ✅ | ✅ |
| Membaca basis pengetahuan (via SDK langsung pun) | ✅ | ✅ |
| Menjalankan panduan H4 → H5 | ✅ | ✅ |
| **Menulis** data panduan | ❌ **ditolak server** | ✅ |
| Melihat halaman H6 | ❌ menu tidak tampil + rute dijaga (lapis 1–2) | ✅ |
| Mengubah peran sendiri | ❌ ditolak server | ⚠️ hanya lewat Console |
| Menghapus permanen data panduan | ❌ `delete: if false` | ❌ juga ditolak — gunakan `aktif: false` |

**Alternatif yang dipertimbangkan dan ditolak:** *custom claims* (`admin: true` pada token) lebih murah karena tidak memerlukan `get()` setiap penulisan, tetapi memerlukan Admin SDK atau Cloud Functions — keduanya di luar batas mata kuliah. Konsekuensi pilihan ini: setiap penulisan oleh admin menambah **satu pembacaan dokumen** (`isAdmin()` memanggil `get()`). Untuk aplikasi dengan puluhan dokumen, biaya ini tidak berarti.

### 8.6 Strategi seed dari `assets/`

JSON dipakai hanya untuk (1) data awal lewat tombol "Impor data awal" di H6, dan (2) bahan uji `InMemoryKnowledgeBaseRepository`.

Aturan seed yang wajib dipatuhi:
- Setiap dokumen **wajib** menulis `aktif: true` eksplisit (§8.3).
- Tulis dengan `WriteBatch`, maksimal 500 operasi per batch (batas Firestore).
- Seed bersifat **idempotent**: memakai `set(..., SetOptions(merge: false))` dengan ID tetap, sehingga menjalankan ulang menimpa, bukan menduplikasi.
- Tidak ada pembacaan `assets/` saat runtime normal; tidak ada fallback otomatis.

---

## 9. Autentikasi & Otorisasi

### 9.1 Alur

```
Buka aplikasi
   ├─ authStateChanges == null → /login (H1)
   └─ authStateChanges != null → / (H2)

H1 Login
   ├─ Masuk: validasi klien → signInWithEmailAndPassword
   │     ├─ sukses → baca users/{uid} → simpan role → / (H2)
   │     └─ gagal  → pesan spesifik, tetap di H1
   └─ Daftar: nama + email + password → createUserWithEmailAndPassword
         ├─ sukses → tulis users/{uid} { email, nama, role: 'warga', createdAt }
         └─ gagal  → pesan, tetap di H1
```

**Perbaikan v1.2:** formulir Daftar wajib meminta **nama**. Aturan `create` mensyaratkan `keys().hasAll(['email','nama','role'])`; tanpa nama, penulisan dokumen `users` akan ditolak dan pengguna berakhir dalam keadaan "sudah terdaftar di Auth tetapi tidak punya dokumen profil".

**Penanganan dokumen profil yang hilang (U-07).** Keadaan ini dapat terjadi bila penulisan `users/{uid}` gagal setelah akun Auth terbentuk (jaringan putus, aturan ditolak), atau bila admin menghapus dokumen profil. Karena `isAdmin()` akan galat dan seluruh pembacaan ditolak, keadaan ini **wajib ditangani eksplisit**, bukan dibiarkan muncul sebagai "layanan belum tersedia" yang membingungkan:

```
Setelah login berhasil:
  doc ← users/{uid}.get()
  JIKA doc tidak ada:
     tampilkan H1 dalam keadaan "Profil akun tidak ditemukan"
     pesan: "Akun Anda terdaftar, tetapi profilnya belum lengkap.
             Hubungi admin atau daftar ulang dengan email lain."
     tombol: "Keluar"  (tidak diarahkan ke Beranda)
  SELAIN ITU:
     simpan role → / (H2)
```

Pemulihan otomatis (membuat dokumen profil saat login) **tidak** dipilih, karena `nama` tidak tersedia pada saat login dan menebaknya dari email akan mengisi data pribadi dengan nilai karangan. Bila kelak diperlukan, jalur yang benar adalah formulir pelengkapan profil — bukan penebakan.

### 9.2 Pemetaan galat

| Kode Firebase | Pesan |
|---|---|
| `invalid-email` | "Format email tidak valid." |
| `user-not-found` / `wrong-password` / `invalid-credential` | "Email atau kata sandi salah." |
| `email-already-in-use` | "Email ini sudah terdaftar." |
| `weak-password` | "Kata sandi minimal 6 karakter." |
| `too-many-requests` | "Terlalu banyak percobaan. Coba lagi nanti." |
| `network-request-failed` | "Tidak ada koneksi internet." |

Pesan tidak membedakan "email tidak terdaftar" dan "password salah" agar tidak membocorkan keberadaan akun.

### 9.3 Daftar di dalam H1

Sitemap menetapkan 6 halaman; menambah halaman Daftar akan melanggar jumlah halaman Must. Pendaftaran ditempatkan sebagai **mode di dalam H1** (segmented "Masuk | Daftar").

---

## 10. Mesin Aturan IF–THEN

### 10.1 Prinsip

Aturan disimpan sebagai data terstruktur di Firestore, **bukan** `if/else` di kode Dart. Mesin inferensi membaca data dan mengevaluasinya secara umum.

### 10.2 Operator kondisi

| Operator | Arti |
|---|---|
| `equals` / `notEquals` | kesamaan nilai |
| `inList` / `notInList` | keanggotaan daftar |
| `gte` / `lte` | perbandingan angka |
| `exists` / `notExists` | fakta terisi / belum |

`when` adalah **AND** dari seluruh klausa. `any` (OR) tersedia di engine tetapi belum dipakai basis pengetahuan v1.2.

### 10.3 Kamus fakta

**Fakta awal:** `service` = `ktp` | `kk` | `domisili`.

**Fakta hasil jawaban:**

| Fakta | Nilai | Layanan |
|---|---|---|
| `kategori_usia` | `di_bawah_17`, `17_ke_atas` | KTP |
| `status_perkawinan` | `belum_menikah`, `menikah`, `pernah_menikah` | KTP |
| `sudah_punya_ktp` | `ya`, `tidak` | KTP |
| `domisili_pemohon` | `tegalsari`, `luar_tegalsari` | KTP, KK |
| `alasan_pengajuan_ktp` | `hilang`, `rusak`, `pindah_datang`, `perubahan_data` | KTP |
| `kondisi_kk` | `belum_punya`, `pindah_datang`, `perubahan_anggota`, `hilang`, `rusak` | KK |
| `jenis_perubahan_kk` | `kelahiran`, `kematian`, `perkawinan`, `perpindahan` | KK |
| `keperluan_domisili` | `sekolah`, `kerja`, `bank`, `usaha`, `lainnya` | Domisili |
| `status_tinggal` | `warga_tetap`, `tinggal_sementara` | Domisili |
| `punya_bukti_tinggal` | `ya`, `tidak` | Domisili |

**Fakta turunan (diisi `addFacts`):**

| Fakta | Diturunkan oleh | Nilai |
|---|---|---|
| `jenis_pengajuan_ktp` | `KTP-R03`…`R07` | `baru`, `penggantian_hilang`, … |
| `jenis_pengajuan_kk` | `KK-R01`…`R08` | `baru`, `pindah_datang`, `tambah_anggota`, … |

### 10.4 Algoritma sesi (diperbaiki — T-01, T-03, T-04, U-03, U-04)

**Prinsip baru yang menggantikan v1.1:**

> **Outcome bukan alasan untuk berhenti bertanya.** Sesi hanya berhenti bila sebuah aturan bertanda `terminal: true` menyala, atau bila tidak ada pertanyaan tersisa yang `showIf`-nya terpenuhi.

```
PROSEDUR mulaiSesi(kb, serviceId):
  answers  ← {}
  terminal ← false

  ULANGI:
    JIKA terminal: KELUAR

    q ← pertanyaan pada kb.questions yang:
          aktif = true
          DAN factKey ∉ answers
          DAN showIf(fakta(answers)) = TRUE      ← bukan "≠ FALSE"
        urut `urutan` ASC, ambil yang pertama

    JIKA q tidak ada: KELUAR

    answers[q.factKey] ← tanyaPengguna(q)
    pangkas(kb, answers)                        ← buang fakta jalur lama (§10.4.2)

    (fired, outcome, terminal) ← inferensi(kb, answers)   ← DIHITUNG ULANG DARI NOL

  KEMBALIKAN bangunHasil(inferensi(kb, answers))
```

**Urutan operasi yang benar — tidak boleh ditukar:**

```
jawab → pangkas → inferensi → pilih pertanyaan berikutnya
```

Bila `inferensi` dijalankan sebelum `pangkas`, aturan jalur lama masih akan menyala pada satu langkah, lalu hilang pada langkah berikutnya. Itu menghasilkan kedipan persyaratan yang salah dan membuat pengujian tidak reprodusibel.

#### 10.4.1 `showIf` saat fakta belum tersedia (U-03)

`showIf` dievaluasi dengan **logika tiga nilai**, bukan boolean biasa:

| Keadaan fakta yang dirujuk | Hasil `showIf` | Perlakuan terhadap pertanyaan |
|---|---|---|
| Semua fakta tersedia **dan** kondisi terpenuhi | `true` | **Layak** ditanyakan |
| Semua fakta tersedia **dan** kondisi tidak terpenuhi | `false` | Tidak ditanyakan (permanen untuk sesi ini) |
| Ada fakta yang dirujuk **belum ada** | `undefined` | **Belum** layak — ditinjau ulang setiap ada jawaban baru |

Aturan operasional:

1. `undefined` **tidak boleh** diperlakukan sebagai `true`. Inilah yang mencegah pertanyaan terlewati keliru: pertanyaan **menunggu**, bukan dilewati.
2. `undefined` juga tidak boleh diperlakukan sebagai `false` secara permanen — pertanyaan harus ditinjau ulang pada setiap iterasi.
3. `showIf = null` berarti selalu layak.
4. Siklus **selalu berakhir**: setiap iterasi menambah tepat satu fakta, dan jumlah fakta yang mungkin terbatas. Tidak ada kemungkinan *loop* tak berujung.
5. **Validasi saat memuat basis pengetahuan** (bukan saat runtime): setiap `showIf.fact` wajib merupakan `factKey` milik pertanyaan lain pada layanan yang sama, atau `service`. Bila tidak, basis pengetahuan **ditolak dengan galat**. Tanpa validasi ini, salah ketik `factKey` membuat pertanyaan hilang diam-diam dan pengguna tidak pernah ditanya — kegagalan yang sangat sulit dilacak saat demo.
6. **`factKey` wajib unik** dalam satu layanan. Dua pertanyaan yang menulis fakta yang sama membuat hasil bergantung urutan.

#### 10.4.2 Pemangkasan fakta jalur lama (U-04)

Mengubah jawaban dapat membuat jawaban **berikutnya** tidak lagi relevan. Contoh nyata:

```
Pengguna menjawab: kategori_usia = 17_ke_atas → sudah_punya_ktp = ya → alasan = hilang
Lalu menekan "Kembali" sampai Q1 dan mengubah: kategori_usia = di_bawah_17

Tanpa pemangkasan:
  answers masih memuat sudah_punya_ktp = ya dan alasan = hilang
  showIf kedua pertanyaan itu kini false, tetapi faktanya tetap ada
  → KTP-R04 tetap menyala → meminta "surat kehilangan Polsek"
    untuk pemohon berusia 15 tahun
```

```
PROSEDUR pangkas(kb, answers):
  ULANGI:
    berubah ← false
    UNTUK setiap (fact, _) DALAM answers:
      JIKA fact = 'service': LANJUT
      q ← pertanyaan dengan factKey = fact
      JIKA q = null: LANJUT                    # fakta turunan, bukan jawaban pengguna
      JIKA showIf(q, answers) ≠ TRUE:
        hapus answers[fact]
        berubah ← true
  SAMPAI berubah = false
```

Pemangkasan bersifat **iteratif** karena menghapus satu fakta dapat membuat fakta lain ikut tidak relevan (mis. menghapus `sudah_punya_ktp` membuat `alasan_pengajuan_ktp` ikut tidak relevan). Pemangkasan hanya menyentuh fakta yang berasal dari **jawaban pengguna**; fakta turunan (`addFacts`) tidak disentuh karena ia dihitung ulang oleh inferensi.

Dua keputusan penting lainnya:

1. **Inferensi dihitung ulang dari nol setiap kali jawaban berubah** (T-04). Tidak ada state `fired` yang dipertahankan. Biayanya dapat diabaikan (≤25 aturan, ≤6 fakta), dan hasilnya selalu konsisten — jauh lebih aman daripada mencoba "membatalkan" aturan yang sudah menyala.
2. **Pertanyaan diurutkan agar penentu-terminal lebih awal** (T-03). `domisili_pemohon` dinaikkan ke Q4 pada alur KTP, sebelum `alasan_pengajuan_ktp`, sehingga pengguna di luar Tegalsari tidak perlu menjawab pertanyaan yang tidak lagi relevan.

```
PROSEDUR inferensi(kb, answers):
  factBase ← { service: kb.serviceId } ∪ answers
  fired    ← []
  berubah  ← true

  SELAMA berubah:
    berubah ← false
    kandidat ← kb.rules yang aktif DAN belum ada di fired
               urut: priority DESC, jumlahKondisi DESC, id ASC
    UNTUK r DALAM kandidat:
      JIKA evaluasi(r.when, factBase):
        terapkan(r.then, factBase)     # requirements, steps, facts, notes
        fired.add(r); berubah ← true
        ULANGI SELAMA          # fakta baru bisa memicu aturan lain

  outcome  ← pilihOutcome(fired)
  terminal ← ada r ∈ fired dengan r.then.terminal = true
  KEMBALIKAN (fired, outcome, terminal)
```

### 10.5 Resolusi konflik (diperbaiki — T-05)

**Outcome tidak ditentukan oleh aturan yang terakhir menyala**, melainkan oleh aturan dengan peringkat tertinggi di antara **seluruh** aturan yang menyala:

```
FUNGSI pilihOutcome(fired) → (rule, outcome):
  kandidat ← [r ∈ fired | r.then.setOutcome ≠ null]
  JIKA kandidat kosong: KEMBALIKAN (null, null)   # → "panduan belum tersedia"
  urutkan kandidat: priority DESC, jumlahKondisi DESC, id ASC
  KEMBALIKAN (kandidat[0], kandidat[0].then.setOutcome)
```

Fungsi mengembalikan **aturan pemenang**, bukan hanya nilainya. Ini diperlukan oleh §10.6.1: mesin harus tahu apakah pemenang tersebut sebuah aturan terminal.

Urutan peringkat:
1. **Prioritas** (`priority` DESC)
2. **Spesifisitas** (jumlah klausa DESC)
3. **ID** (ASC)

Sifatnya:
- **Deterministik** — tidak bergantung urutan baca Firestore maupun urutan evaluasi.
- **Idempoten** — aturan hanya menyala sekali per perhitungan.
- **Akumulatif untuk penambahan** — persyaratan/tahapan dari semua aturan yang menyala digabung, lalu dideduplikasi berdasarkan ID.
- **Eksklusif untuk outcome** — hanya satu nilai yang menang.

### 10.6 Outcome sementara vs kondisi terminal (baru di v1.2)

Ini pembedaan inti yang tidak ada di v1.1 dan menjadi akar T-01.

| Konsep | Arti | Efek pada sesi |
|---|---|---|
| **Outcome sementara** (`setOutcome` pada aturan `terminal: false`) | Keputusan terbaik berdasarkan fakta yang sudah diketahui | **Tidak menghentikan** sesi; boleh ditimpa aturan berprioritas lebih tinggi |
| **Kondisi terminal** (`terminal: true`) | Tidak ada pertanyaan tersisa yang **dapat mengubah** keputusan | Sesi berhenti; sisa pertanyaan tidak ditanyakan |

Aturan hanya boleh ditandai `terminal: true` bila ada **bukti** bahwa semua kemungkinan jawaban pertanyaan tersisa menghasilkan outcome yang sama. Bukti itu wajib ditulis, bukan diasumsikan:

| Aturan terminal | Pertanyaan tersisa | Bukti outcome tidak berubah |
|---|---|---|
| `KTP-R01` (usia <17 & belum menikah) | `domisili_pemohon` | Baik `tegalsari` maupun `luar_tegalsari`, outcome tetap `tidak_dapat_diproses` (`KTP-R08` menetapkan nilai yang sama) |
| `KTP-R08` (domisili luar) | `alasan_pengajuan_ktp` | Semua nilai alasan tetap `tidak_dapat_diproses` karena pengurusan dilakukan di kelurahan domisili |
| `KK-R10` (domisili luar & bukan pindah datang) | — (domisili adalah pertanyaan terakhir) | Tidak ada pertanyaan tersisa |

Aturan yang **bukan** terminal meskipun menetapkan outcome: `KTP-R02`–`R07`, `KK-R01`–`R08`, `DOM-R01`–`R04`. Semuanya masih dapat ditimpa oleh aturan domisili atau aturan kelengkapan dokumen.

`KTP-R10` (usia <17 dengan status pernah menikah) **sengaja tidak terminal** dan **tidak menetapkan outcome**. Alasannya: bila pengguna ternyata berdomisili di luar Tegalsari, `KTP-R08` masih dapat memberi jawaban yang pasti (`tidak_dapat_diproses`). Menghentikan sesi lebih awal akan menukar jawaban pasti itu dengan "panduan belum tersedia" — lebih buruk bagi pengguna. Prinsipnya: **aturan yang tidak dapat memutuskan tidak berhak menghentikan sesi.**

#### 10.6.1 Invarian terminal (baru di v1.4 — V-01)

Tabel bukti di atas adalah **dokumentasi**, bukan pemeriksaan. Ia menjelaskan *mengapa* suatu aturan dianggap terminal, tetapi tidak mencegah konfigurasi yang bertentangan. Tanpa pemeriksaan, keadaan berikut dapat terjadi:

```
KTP-Rx  (p60, terminal: true, setOutcome: tidak_dapat_diproses)   → menyala, menghentikan sesi
KTP-Ry  (p90, terminal: false, setOutcome: dapat_diproses)        → juga menyala
pemenang = KTP-Ry (prioritas 90 > 60)

→ Sesi berhenti dengan alasan "tidak ada pertanyaan yang dapat mengubah keputusan",
  tetapi keputusan yang ditampilkan justru berasal dari aturan yang bukan terminal.
```

Sesi berhenti atas dasar klaim yang tidak dimiliki oleh pemenangnya. Untuk mencegahnya, ditetapkan **tiga invarian** yang diperiksa setiap kali basis pengetahuan dimuat:

| Kode | Invarian | Bila dilanggar |
|---|---|---|
| **V-1** | Setiap aturan `terminal: true` **wajib** menetapkan `setOutcome` | **Ditolak.** Aturan terminal yang tidak memutuskan akan menghentikan sesi dengan `outcome == null` → "panduan belum tersedia", padahal mesin mengklaim sudah pasti |
| **V-2** | Dua aturan terminal pada layanan yang sama boleh menetapkan outcome **berbeda hanya bila terbukti saling lepas** | **Ditolak.** Bila keduanya dapat menyala bersamaan dengan outcome berbeda, hasilnya bergantung pada aturan mana yang lebih dulu dievaluasi |
| **V-3** | Prioritas **setiap** aturan terminal lebih tinggi daripada prioritas **seluruh** aturan non-terminal pada layanan yang sama | **Ditolak.** Tanpa ini, pemenang `pilihOutcome` dapat berupa aturan non-terminal — persis keadaan di atas |

**Definisi "terbukti saling lepas" (V-2).** Dua aturan dianggap saling lepas bila keduanya mengonstrain **fakta yang sama** dengan himpunan nilai yang **tidak beririsan** — mis. `status_perkawinan = belum_menikah` dan `status_perkawinan = menikah`. Untuk operator `equals` dan `inList`, himpunan nilai diketahui sehingga pemeriksaan ini eksak. Untuk `notEquals`, `notInList`, `gte`, dan `lte`, aturan **dianggap tidak terbukti saling lepas** (konservatif), sehingga pasangan tersebut ditolak bila outcome-nya berbeda. Sikap konservatif dipilih karena tujuan pemeriksaan ini adalah mencegah kesalahan, bukan memaksimalkan jumlah aturan yang lolos.

**Konsekuensi V-3 yang perlu dipahami:** begitu V-1 dan V-3 terpenuhi, **outcome akhir selalu berasal dari aturan terminal yang menyebabkan sesi berhenti**. V-2 memastikan tidak ada dua aturan terminal yang dapat menyala bersamaan dengan nilai berbeda. Dengan ketiganya, klaim "tidak ada pertanyaan tersisa yang dapat mengubah keputusan" menjadi benar secara struktural, bukan sekadar berdasarkan tabel dokumentasi.

**Pemeriksaan pada basis pengetahuan v1.4:**

| Layanan | Aturan terminal | Prioritas | Aturan non-terminal tertinggi | V-3 |
|---|---|---|---|---|
| KTP | `KTP-R01` (95), `KTP-R08` (99) | min 95 | `KTP-R02` (90) | ✅ 95 > 90 |
| KK | `KK-R10` (99) | 99 | `KK-R03`–`R06` (85) | ✅ 99 > 85 |
| Domisili | — | — | `DOM-R03`, `DOM-R04` (85) | ✅ vacuous |

V-1: ketiga aturan terminal menetapkan outcome ✅. V-2: `KTP-R01` dan `KTP-R08` sama-sama menetapkan `tidak_dapat_diproses` ✅.

#### 10.6.2 Penjaga saat runtime (pertahanan terakhir)

Validasi saat muat dapat dilewati bila aturan ditulis langsung lewat Firebase Console (di luar aplikasi). Karena itu mesin tetap memeriksa satu hal terakhir pada setiap perhitungan:

```
(fired, pemenang, outcome) ← inferensi(kb, answers)

JIKA ada aturan terminal di `fired`:
   JIKA pemenang.terminal = false:
      catat CONFIG_WARNING ke trace        # konfigurasi bertentangan
      terminal ← false                     # JANGAN hentikan sesi
   SELAIN ITU:
      terminal ← true
```

Perilakunya **fail-open untuk kelanjutan sesi, fail-closed untuk klaim**: bila pemenang bukan aturan terminal, sesi **melanjutkan pertanyaan** alih-alih berhenti dengan jawaban yang mungkin salah. Pengguna tidak pernah menerima hasil yang bertentangan dengan alasan sesi berhenti; paling buruk ia menjawab satu-dua pertanyaan tambahan.

`CONFIG_WARNING` ditampilkan di H6 (khusus admin) agar penyebabnya dapat diperbaiki, dan **tidak** ditampilkan ke warga.

### 10.7 Status keluaran dan penyaringan tampilan

| Outcome | Label UI | Warna | Kapan | Persyaratan ditampilkan? |
|---|---|---|---|---|
| `dapat_diproses` | Dapat diproses | `#15803D` | Kondisi memenuhi | ✅ |
| `dengan_catatan` | Dapat diproses dengan catatan | `#C2410C` | Ada kekurangan yang masih bisa dilengkapi | ✅ |
| `tidak_dapat_diproses` | Belum dapat diproses di sini | `#B91C1C` | Usia <17 tanpa menikah, atau domisili di luar kelurahan | ❌ **disembunyikan** |
| `null` | Panduan belum tersedia | `#C2410C` | Tidak ada aturan yang menetapkan outcome | ❌ |

**Aturan penyaringan (baru di v1.2):** bila outcome akhir `tidak_dapat_diproses`, daftar persyaratan dan tahapan **tidak ditampilkan** di H5, meskipun aturan lain sempat menambahkannya. Alasannya: memberi tahu "bawa surat kehilangan dari Polsek" kepada orang yang justru diminta mengurus di kelurahan lain adalah menyesatkan. Data tetap tersimpan di `trace` agar dapat diuji dan dijelaskan.

Penyaringan ini dilakukan di **pembangun hasil** (`bangunHasil`), bukan di UI — sehingga dapat diuji tanpa membuka aplikasi.

### 10.8 Bagaimana "panduan belum tersedia" muncul

`outcome == null` hanya terjadi bila **tidak satu pun** aturan menetapkan outcome. Ini bukan keadaan normal, dan sengaja dibiarkan terlihat karena berfungsi sebagai **deteksi celah basis pengetahuan**:

- Admin menambah opsi jawaban baru (mis. `alasan_pengajuan_ktp = "lainnya"`) tanpa menambah aturan → pengguna memilih opsi itu → `outcome == null` → H5 menampilkan "Panduan belum tersedia".
- Kombinasi yang belum tercakup tidak pernah "ditebak" menjadi `dapat_diproses`. Sistem memilih mengaku belum punya jawaban daripada memberi panduan yang salah.
- `trace` tetap mencatat aturan mana yang menyala (bila ada) sehingga admin dapat menelusuri penyebabnya di H6.

---

## 11. Basis Pengetahuan per Layanan

> Isi persyaratan disusun dari pemahaman umum prosedur adminduk (rujukan Permendagri 108/2019 dan praktik layanan kelurahan). **Belum divalidasi petugas Kelurahan Tegalsari.** Seluruh teks berada di Firestore sehingga koreksi tidak menyentuh kode.

### 11.1 Alur pertanyaan (urutan diperbaiki — T-03)

**KTP** — maksimal 4 pertanyaan

| Urut | Fakta | Kapan ditanyakan |
|---|---|---|
| Q1 | `kategori_usia` | selalu |
| Q2 | `status_perkawinan` | `kategori_usia = di_bawah_17` |
| Q3 | `sudah_punya_ktp` | `kategori_usia = 17_ke_atas` |
| Q4 | `domisili_pemohon` | selalu (kecuali sudah terminal) |
| Q5 | `alasan_pengajuan_ktp` | `sudah_punya_ktp = ya` |

Jumlah pertanyaan per jalur:

| Kondisi | Jumlah | Berhenti karena |
|---|---|---|
| <17, belum menikah | **2** | terminal `KTP-R01` |
| <17, menikah | 3 | pertanyaan habis |
| <17, pernah menikah | 3 | pertanyaan habis — **outcome `null`** (lihat catatan) |
| 17+, belum punya | 3 | pertanyaan habis |
| 17+, sudah punya, Tegalsari | 4 | pertanyaan habis |
| 17+, sudah punya, luar Tegalsari | **3** | terminal `KTP-R08` (Q5 dilewati) |

> **Catatan `pernah_menikah` (U-02).** Nilai ini ada di kamus fakta, tetapi **ketentuan administrasinya belum diketahui dan tidak dikarang**. Yang diketahui hanya: KTP-el diwajibkan bagi yang sudah menikah (termasuk pernah menikah), sehingga jalur `<17 + belum_menikah` jelas tidak berlaku. Apakah pemohon berstatus pernah menikah di bawah 17 tahun diperlakukan sama dengan "menikah" (cukup akta nikah/akta cerai) atau memerlukan dokumen lain — **belum ada dasar yang cukup untuk memutuskan**.
>
> Perilaku aman yang dipilih:
> - **Tidak** ada aturan yang menetapkan outcome untuk kombinasi ini.
> - **Tidak** ada persyaratan yang dikarang.
> - Sesi **tetap berjalan** sampai Q4, agar pengguna di luar Tegalsari tetap memperoleh jawaban pasti dari `KTP-R08`.
> - Bila berdomisili di Tegalsari, hasilnya `outcome == null` → H5 menampilkan **"Panduan belum tersedia"** disertai catatan: *"Kasus Anda belum tercakup dalam panduan ini. Silakan konfirmasi langsung ke loket pelayanan Kelurahan Tegalsari."*
>
> Ini bukan kegagalan sistem, melainkan perilaku yang disengaja: lebih baik mengaku belum tahu daripada memberi daftar dokumen yang salah. Jalur ini wajib ditanyakan saat validasi ke petugas (§19 butir 6) dan diuji lewat S35–S36.

**KK** — maksimal 3 pertanyaan

| Urut | Fakta | Kapan |
|---|---|---|
| Q1 | `kondisi_kk` | selalu |
| Q2 | `jenis_perubahan_kk` | `kondisi_kk = perubahan_anggota` |
| Q3 | `domisili_pemohon` | selalu |

**Surat Domisili** — maksimal 3 pertanyaan

| Urut | Fakta | Kapan |
|---|---|---|
| Q1 | `keperluan_domisili` | selalu |
| Q2 | `status_tinggal` | selalu |
| Q3 | `punya_bukti_tinggal` | `status_tinggal = tinggal_sementara` |

### 11.2 Aturan KTP (outcome eksplisit — T-02)

| ID | P | IF | THEN |
|---|---|---|---|
| `KTP-R01` | 95 | `kategori_usia = di_bawah_17` **AND** `status_perkawinan = belum_menikah` | outcome `tidak_dapat_diproses` · **terminal** · note: belum wajib KTP-el, arahkan ke KIA |
| `KTP-R02` | 90 | `kategori_usia = di_bawah_17` **AND** `status_perkawinan = menikah` | outcome `dengan_catatan` · req: KK asli, akta nikah, akta kelahiran, pengantar RT/RW, F-1.01 · note: didampingi orang tua/wali |
| `KTP-R03` | 70 | `kategori_usia = 17_ke_atas` **AND** `sudah_punya_ktp = tidak` | outcome `dapat_diproses` · req: KK asli, akta kelahiran, pengantar RT/RW, F-1.01 · **tanpa** `addSteps` (tahapan dari `stepsDasar`) |
| `KTP-R04` | 75 | `sudah_punya_ktp = ya` **AND** `alasan = hilang` | outcome `dapat_diproses` · req: surat kehilangan Polsek, fotokopi KK, F-1.01 |
| `KTP-R05` | 75 | `sudah_punya_ktp = ya` **AND** `alasan = rusak` | outcome `dapat_diproses` · req: KTP-el lama, fotokopi KK, F-1.01 |
| `KTP-R06` | 75 | `sudah_punya_ktp = ya` **AND** `alasan = pindah_datang` | outcome `dapat_diproses` · req: SKPWNI, KK baru, KTP-el lama, F-1.01 |
| `KTP-R07` | 75 | `sudah_punya_ktp = ya` **AND** `alasan = perubahan_data` | outcome `dapat_diproses` · req: KTP-el lama, fotokopi KK, dokumen pendukung, F-1.01 |
| `KTP-R08` | 99 | `domisili_pemohon = luar_tegalsari` | outcome `tidak_dapat_diproses` · **terminal** · note: pengurusan di kelurahan domisili |
| `KTP-R10` | 88 | `kategori_usia = di_bawah_17` **AND** `status_perkawinan = pernah_menikah` | **tanpa outcome** · **tidak terminal** · tanpa persyaratan · note: `NOTE_KASUS_BELUM_TERCAKUP` — jalur belum tervalidasi (U-02) |

Perubahan dari v1.1: `R04`–`R07` kini **menetapkan outcome** (sebelumnya tidak, sehingga S04–S07 gagal); `R01` dan `R08` ditandai terminal.
Perubahan dari v1.2: `KTP-R09` **dihentikan** karena hanya menambah tahapan yang kini berasal dari `stepsDasar` (U-01); `KTP-R10` **ditambahkan** untuk jalur `pernah_menikah` (U-02). Penomoran R09 sengaja tidak dipakai ulang agar ID aturan pada catatan pengujian lama tetap sah.

**Sumber tahapan KTP (U-01).** Seluruh pengajuan KTP — baru, hilang, rusak, pindah datang, perubahan data — memakai **lima tahapan yang sama** dari `services/ktp.stepsDasar`. Tidak ada aturan yang menambah tahap. Ini keputusan yang konsisten dengan sifat prosesnya: yang membedakan jenis pengajuan adalah **dokumen**, bukan langkah pelayanan. Bila kelak ditemukan varian nyata (mis. jalur tanpa perekaman), varian itu ditambahkan sebagai `addSteps` pada aturan terkait — mekanismenya sudah tersedia dan belum dipakai.

### 11.3 Aturan KK

| ID | P | IF | THEN |
|---|---|---|---|
| `KK-R01` | 80 | `kondisi_kk = belum_punya` | outcome `dapat_diproses` · req: buku nikah, KK orang tua, KTP suami & istri, pengantar RT/RW, F-1.01 |
| `KK-R02` | 80 | `kondisi_kk = pindah_datang` | outcome `dapat_diproses` · req: SKPWNI, KK asal, KTP pemohon, pengantar RT/RW, F-1.01 |
| `KK-R03` | 85 | `jenis_perubahan_kk = kelahiran` | outcome `dapat_diproses` · req: akta kelahiran, KK lama, KTP orang tua, F-1.01 |
| `KK-R04` | 85 | `jenis_perubahan_kk = kematian` | outcome `dapat_diproses` · req: akta kematian, KK lama, KTP pelapor, F-1.01 |
| `KK-R05` | 85 | `jenis_perubahan_kk = perkawinan` | outcome `dapat_diproses` · req: buku nikah, KK lama, KTP pasangan, F-1.01 |
| `KK-R06` | 85 | `jenis_perubahan_kk = perpindahan` | outcome `dapat_diproses` · req: SKPWNI/SKPTB, KK lama, KTP anggota, F-1.01 |
| `KK-R07` | 75 | `kondisi_kk = hilang` | outcome `dapat_diproses` · req: surat kehilangan Polsek, fotokopi KK lama, KTP, F-1.01 |
| `KK-R08` | 75 | `kondisi_kk = rusak` | outcome `dapat_diproses` · req: KK lama, KTP pemohon, F-1.01 |
| `KK-R10` | 99 | `domisili_pemohon = luar_tegalsari` **AND** `kondisi_kk ≠ pindah_datang` | outcome `tidak_dapat_diproses` · **terminal** · note: perubahan KK di kelurahan domisili |

`KK-R09` (tahapan perubahan anggota) **dihentikan** pada v1.3 — tahapan kini berasal dari `services/kk.stepsDasar` (U-01). Seluruh pengajuan KK memakai lima tahapan yang sama; yang berbeda antar-jenis hanya dokumennya.

### 11.4 Aturan Surat Domisili

| ID | P | IF | THEN |
|---|---|---|---|
| `DOM-R01` | 80 | `status_tinggal = warga_tetap` | outcome `dapat_diproses` · req: KTP-el, KK, pengantar RT/RW, F-101 |
| `DOM-R02` | 80 | `status_tinggal = tinggal_sementara` | outcome `dapat_diproses` · req: KTP asal, KK, surat pernyataan bermaterai, bukti tinggal, pengantar RT/RW, F-101 |
| `DOM-R03` | 85 | `status_tinggal = tinggal_sementara` **AND** `punya_bukti_tinggal = tidak` | outcome `dengan_catatan` · note: bukti tinggal wajib dilengkapi (surat keterangan pemilik rumah) |
| `DOM-R04` | 85 | `keperluan_domisili = usaha` | req tambahan: foto lokasi usaha, surat pernyataan tidak keberatan tetangga (tanpa outcome) |
| `DOM-R05` | 70 | `keperluan_domisili = sekolah` | note: sertakan keterangan tujuan (tanpa outcome) |

`DOM-R06` (tahapan layanan domisili) **dihentikan** pada v1.3 — tahapan kini berasal dari `services/domisili.stepsDasar` (U-01).

Perhatikan `DOM-R02` vs `DOM-R03`: keduanya menyala pada jalur "tinggal sementara tanpa bukti". `DOM-R03` menang karena prioritas 85 > 80. Pada v1.1, `DOM-R03` **tidak pernah dievaluasi** karena sesi sudah berhenti setelah Q2 — inilah T-01 pada layanan ketiga.

### 11.5 Katalog tahapan: umum vs khusus (baru di v1.3 — U-01)

Sebelum v1.3, sumber tahapan bercampur di tiga tempat: contoh JSON `KTP-R03` (lima tahap), tabel aturan ("+ perekaman"), dan trace S03 (lima tahap). Ketiganya tidak konsisten. v1.3 menetapkan **satu sumber tunggal**:

| Jenis tahapan | Sumber | Contoh |
|---|---|---|
| **Tahapan umum** — berlaku untuk semua pengajuan pada satu layanan | `services/{id}.stepsDasar` | `["STEP_LOKET","STEP_SERAH_BERKAS","STEP_VERIFIKASI","STEP_REKAM","STEP_AMBIL"]` |
| **Tahapan khusus** — varian yang hanya berlaku pada kondisi tertentu | `rules/{id}.then.addSteps` | **belum dipakai di v1.3** |

**Cara hasil dibentuk** (`bangunHasil`):

```
daftar = services.stepsDasar ∪ (⋃ addSteps dari aturan yang menyala)
buang duplikat berdasarkan ID
urutkan berdasarkan steps.urutan ASC, lalu id ASC
```

**Katalog `steps`** (satu dokumen per tahap, dipakai lintas layanan):

| ID | `urutan` | Judul | Keterangan |
|---|---|---|---|
| `STEP_LOKET` | 10 | Datang ke loket pelayanan | Kelurahan Tegalsari, ambil nomor antrean |
| `STEP_SERAH_BERKAS` | 20 | Serahkan berkas | Petugas memeriksa kelengkapan awal |
| `STEP_VERIFIKASI` | 30 | Verifikasi dan validasi | Pencocokan dokumen dengan data pemohon |
| `STEP_REKAM` | 40 | Perekaman biometrik | Dilakukan bila petugas menilai perlu (KTP) |
| `STEP_DISDUKCAPIL` | 40 | Diteruskan ke Disdukcapil | Kota Semarang (KK) |
| `STEP_TTD_LURAH` | 40 | Penandatanganan Lurah | Surat domisili |
| `STEP_AMBIL` | 50 | Pengambilan dokumen | Sesuai estimasi hari kerja |

Karena setiap layanan hanya memakai **satu** tahap ber-`urutan` 40, tidak pernah ada seri di dalam satu layanan. Bila kelak ada seri, pengurutan diakhiri dengan `id ASC` agar tetap deterministik.

**Konsistensi yang dijamin:** S03 (KTP baru) dan S04–S07 (penggantian) kini menghasilkan **daftar tahapan identik** — lima langkah yang sama, karena kelimanya memakai `stepsDasar` yang sama dan tidak ada aturan yang menambah tahap. Yang berbeda hanya daftar persyaratan. Ini juga yang dituntut oleh Skenario S03–S07 pada §14.1.

**Yang perlu divalidasi:** apakah benar semua jenis pengajuan KTP melewati perekaman biometrik. Bila petugas menyatakan penggantian karena rusak tidak perlu perekaman ulang, maka `STEP_REKAM` dipindah dari `stepsDasar` ke `addSteps` pada `KTP-R03`, `R06`, `R07`. Perubahan itu **hanya menyentuh data**, bukan kode — dan sampai ada konfirmasi, rancangan memakai asumsi paling konservatif (semua melewati perekaman).

**Status validasi setiap tahap (V-03).** Tidak satu pun tahap di bawah ini sudah dikonfirmasi petugas. Kolom "Dasar penetapan" menjelaskan dari mana asal setiap tahap, bukan tingkat kebenarannya.

| Tahap | Dasar penetapan | Status validasi |
|---|---|---|
| `STEP_LOKET`, `STEP_SERAH_BERKAS`, `STEP_VERIFIKASI`, `STEP_AMBIL` | Pola umum pelayanan kelurahan | **belum divalidasi** |
| `STEP_REKAM` | **Asumsi rancangan**: seluruh pengajuan KTP melewati perekaman biometrik | **belum dikonfirmasi petugas** |
| `STEP_DISDUKCAPIL` | **Asumsi rancangan**: berkas KK diteruskan ke Disdukcapil Kota Semarang | **belum dikonfirmasi petugas** |
| `STEP_TTD_LURAH` | **Asumsi rancangan**: surat domisili ditandatangani Lurah | **belum dikonfirmasi petugas** |

> **Penanda yang wajib dipertahankan** di seluruh dokumen, laporan skripsi, dan teks aplikasi sampai ada konfirmasi tertulis dari Kelurahan Tegalsari:
>
> **`STEP_REKAM` pada `stepsDasar` KTP adalah ASUMSI RANCANGAN — bukan ketentuan resmi.**
>
> Kalimat "semua jenis pengajuan KTP melewati perekaman biometrik" **tidak boleh** ditulis sebagai fakta. Yang boleh ditulis: *"rancangan mengasumsikan seluruh pengajuan KTP melewati perekaman; asumsi ini belum dikonfirmasi petugas."*
>
> Alasan penegasan ini: `stepsDasar` membuat kelima tahap tampil identik untuk S03–S07. Bila asumsi keliru, kesalahan itu akan tampak seperti kepastian — dan justru itu yang paling sulit dipertanggungjawabkan saat sidang.

Di UI, `STEP_REKAM` memakai keterangan **"dilakukan bila petugas menilai perlu"** (§11.5 katalog), bukan pernyataan bahwa perekaman pasti dilakukan. Keterangan ini **tidak boleh** diubah menjadi kalimat definitif sebelum ada konfirmasi.

---

## 12. Catatan Prioritas CRUD Admin (perbedaan yang TIDAK dihapus)

### 12.1 Perbedaan yang tercatat

| Sumber | Kebutuhan | Prioritas | Konteks |
|---|---|---|---|
| Modul Minggu 2 (Latihan 4) | **K5** — admin menambah/melihat/mengubah/menghapus data panduan di Firestore | **Must** | Mendukung requirement CRUD mata kuliah |
| Modul Minggu 3 (Latihan 4) | **H6 Kelola Panduan (Admin)** | **Should** | Diturunkan agar halaman Must tetap 3–5 dan alur warga tetap inti |

Keduanya menjawab pertanyaan berbeda: Minggu 2 bertanya *"kebutuhan apa yang harus ada agar requirement CRUD terpenuhi?"* → Must. Minggu 3 bertanya *"halaman mana yang dilalui alur inti warga?"* → Should, karena warga tidak pernah melewati H6.

### 12.2 Sikap rancangan

| Sumbu | Status H6 |
|---|---|
| Kelengkapan requirement mata kuliah (CRUD) | **Wajib dipenuhi** — tidak boleh dihilangkan |
| Alur inti pengguna | **Pendukung** — tidak dilalui warga, tidak menghambat H1–H5 |

H6 **akan dibuat**, tetapi **setelah** H1–H5 berjalan. Bila waktu tidak cukup, yang dipotong adalah **kelengkapan operasi CRUD**, bukan keberadaan H6.

### 12.3 Implementasi CRUD bertahap

| Tahap | Operasi | Cakupan | Alasan urutan |
|---|---|---|---|
| **A** | **Read** | H6 menampilkan daftar layanan, pertanyaan, aturan, persyaratan, tahapan | Paling murah; membuktikan integrasi Firestore dua arah |
| **B** | **Update** | Ubah teks pertanyaan, nama/keterangan persyaratan, prioritas aturan | Paling bernilai untuk pengujian aturan |
| **C** | **Create** | Tambah pertanyaan atau aturan lewat form | Membuktikan basis pengetahuan dapat diperluas tanpa kode |
| **D** | **Delete** | Nonaktifkan (`aktif = false`) dengan konfirmasi | Menghindari referensi terputus |

Minimal agar mata kuliah terpenuhi: **A + B**.

### 12.4 Konsistensi `aktif` antara repository, query, dan CRUD (diperiksa di v1.2)

Temuan T-06/T-07 menuntut aturan konsistensi yang eksplisit, karena `aktif` dipakai di empat tempat sekaligus:

| Tempat | Perlakuan terhadap `aktif` |
|---|---|
| **Query H3** (`loadServices`) | **Tidak** memfilter. Semua layanan dikembalikan; `aktif` dipakai untuk menandai kartu |
| **Query H4/H5** (`loadService`) | **Memfilter** `questions` dan `rules` dengan `aktif == true` |
| **Katalog** (`requirements`, `steps`) | Dibaca semua, difilter di memori |
| **Seed importer** | **Wajib menulis** `aktif: true` eksplisit |
| **CRUD admin (C)** | Form create menulis `aktif: true` sebagai nilai bawaan |
| **CRUD admin (D)** | Tombol "Hapus" = `update({ aktif: false })`, bukan `delete()` |
| **CRUD admin (A/B)** | Menampilkan data nonaktif dengan label "Nonaktif" agar admin bisa mengaktifkan kembali |

Dua konsekuensi yang harus dijaga:
1. **Layanan nonaktif tetap muncul di H3** tetapi kartunya tidak dapat ditekan. Ini memenuhi wireframe "layanan belum tersedia ditandai dengan teks status".
2. **Pertanyaan/aturan nonaktif tidak boleh ikut dievaluasi**, tetapi **tetap terlihat di H6**. Bila admin menonaktifkan satu-satunya aturan yang menetapkan outcome, hasilnya `outcome == null` → "panduan belum tersedia". Perilaku ini benar, dan harus diuji (S33).

### 12.5 Validasi sebelum simpan di H6 (baru di v1.4 — V-02)

Validasi saat memuat basis pengetahuan saja **tidak cukup**. Tanpa validasi di jalur simpan, urutan kejadiannya menjadi:

```
Admin menyimpan aturan terminal tanpa outcome
  → simpan berhasil (tidak ada pemeriksaan)
  → warga membuka panduan
  → seluruh basis pengetahuan layanan itu ditolak
  → warga melihat "layanan belum tersedia"
  → admin tidak tahu penyebabnya
```

Karena itu validator yang sama dijalankan **sebelum** penulisan, pada data hasil gabungan (aturan lama + aturan yang sedang diedit):

```
PROSEDUR simpanAturan(kandidat):
  kb' ← basisPengetahuan(layanan) dengan kandidat menggantikan dokumen lama
  hasil ← validasi(kb')            # validator yang sama dengan saat muat
  JIKA hasil.adaPelanggaran:
     TOLAK penyimpanan
     tampilkan daftar pelanggaran di form H6 (kode + pesan)
     JIKA ada pelanggaran V-1/V-2/V-3:
        sertakan saran perbaikan (mis. "prioritas terminal harus > 90")
  SELAIN ITU:
     tulis ke Firestore
```

Konsekuensi yang perlu disadari: **admin tidak dapat menyimpan aturan yang merusak basis pengetahuan**, termasuk bila ia sendiri tidak memahami invarian V-1/V-2/V-3. Pesan pelanggaran ditulis dalam bahasa yang dapat ditindaklanjuti, bukan sekadar kode galat.

Dua jalur yang tetap dapat melewati validasi, beserta penanganannya:

| Jalur | Penanganan |
|---|---|
| Admin menulis langsung lewat Firebase Console | Validasi saat muat menolak; aplikasi menampilkan "layanan belum tersedia" untuk layanan itu saja, dan `CONFIG_WARNING` tercatat di trace |
| Aturan dinonaktifkan (`aktif: false`) sehingga menyisakan konfigurasi timpang | Validasi hanya memeriksa aturan **aktif**, karena hanya aturan aktif yang dievaluasi mesin |

Validasi ini **belum diimplementasikan dan belum diuji**. Yang ada di dokumen ini adalah rancangan pemeriksaan, bukan bukti bahwa pemeriksaan berjalan.

---

## 13. Style Guide & Konsistensi dengan Figma

### 13.1 Token warna

| Peran | Hex | Pemakaian |
|---|---|---|
| Primer | `#0F766E` | Tombol utama, item navigasi aktif, fokus |
| Teks utama | `#0F172A` | Judul, isi |
| Teks sekunder | `#475569` | Keterangan, label |
| Garis | `#CBD5E1` | Batas kartu, pemisah |
| Latar | `#F8FAFC` | Latar halaman |
| Permukaan | `#FFFFFF` | Kartu, AppBar |
| Berhasil | `#15803D` | `dapat_diproses` |
| Menunggu | `#C2410C` | `dengan_catatan`, panduan belum tersedia |
| Galat | `#B91C1C` | `tidak_dapat_diproses`, galat login/validasi |

### 13.2 Tipografi

Inter — judul 22/700, subjudul 16/700, isi 14/400, keterangan 12/400.

### 13.3 Komponen

Tombol utama: isi `#0F766E`, teks putih, radius 12, tinggi ≥48. Tombol sekunder: putih, garis `#0F766E`. Kartu: putih, garis `#CBD5E1`, radius 12, padding 16. Target sentuh ≥48×48. Jarak kelipatan 8. Margin tepi 16.

### 13.4 Catatan penting untuk `ThemeData`

Jangan memakai `ColorScheme.fromSeed(seedColor: Color(0xFF0F766E))` sebagai satu-satunya sumber warna — palet tonalnya menyimpang dari hex Figma. Susun eksplisit:

```dart
const ColorScheme scheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF0F766E), onPrimary: Colors.white,
  secondary: Color(0xFF0F766E), onSecondary: Colors.white,
  error: Color(0xFFB91C1C), onError: Colors.white,
  surface: Color(0xFFFFFFFF), onSurface: Color(0xFF0F172A),
);
```

Latar `#F8FAFC` dipasang di `Scaffold.backgroundColor`, bukan `surface`, agar kartu tetap putih.

### 13.5 Status tidak boleh disampaikan lewat warna saja

| Outcome | Ikon | Teks |
|---|---|---|
| `dapat_diproses` | centang | "Dapat diproses" |
| `dengan_catatan` | tanda seru | "Dapat diproses dengan catatan" |
| `tidak_dapat_diproses` | silang | "Belum dapat diproses di sini" |
| `null` | info | "Panduan belum tersedia" |

### 13.6 Keselarasan dengan frame Figma

| Frame Figma (Minggu 4) | Halaman | Catatan |
|---|---|---|
| Login | H1 | + mode Daftar (tambahan v1.2, belum ada di Figma) |
| Login – Galat | H1 (state) | Inline error di bawah field |
| Beranda | H2 | Grid 2–3 kolom pada ≥600 px |
| Pilih Layanan | H3 | + keadaan "layanan belum tersedia" |
| Pertanyaan Interaktif | H4 | Nama dibakukan → **Pertanyaan Panduan** |
| Pertanyaan Interaktif – Galat | H4 (state) | "Lihat Panduan" nonaktif + pesan |
| Hasil Panduan | H5 | Lebar maks 720 px |
| Hasil Panduan – Belum Tersedia | H5 (state) | `outcome == null` |
| *(belum ada di Figma)* | H6 | Perlu frame tambahan bila dosen meminta |

**Perbedaan yang perlu disiapkan sebagai penjelasan saat demo:** wireframe menampilkan tiga pertanyaan tetap untuk KTP, sedangkan rancangan ini adaptif (2–4 pertanyaan). Susunan layar tidak berubah; hanya jumlah langkah dan indikator progres yang dinamis.

---

## 14. Skenario Uji Fungsional

Tabel ini adalah **kontrak pengujian**. Setiap baris menjadi satu `test` di `test/scenario/scenario_test.dart` (level engine, tanpa Firebase). **Belum satu pun dijalankan** — statusnya "direncanakan", bukan "lulus".

### 14.1 Skenario utama

| # | Layanan | Jawaban | Outcome | Catatan |
|---|---|---|---|---|
| S01 | KTP | <17, belum menikah | `tidak_dapat_diproses` | 2 pertanyaan; persyaratan tidak ditampilkan |
| S02 | KTP | <17, menikah, Tegalsari | `dengan_catatan` | akta nikah, KK asli |
| S03 | KTP | 17+, belum punya, Tegalsari | `dapat_diproses` | KK asli, akta kelahiran, F-1.01 |
| S04 | KTP | 17+, sudah punya, hilang | `dapat_diproses` | surat kehilangan Polsek |
| S05 | KTP | 17+, sudah punya, rusak | `dapat_diproses` | KTP lama |
| S06 | KTP | 17+, sudah punya, pindah datang | `dapat_diproses` | SKPWNI |
| S07 | KTP | 17+, sudah punya, perubahan data | `dapat_diproses` | dokumen pendukung |
| S08 | KTP | 17+, belum punya, luar Tegalsari | `tidak_dapat_diproses` | 3 pertanyaan; Q5 tidak ditanya; persyaratan kosong |
| S09 | KK | belum punya, Tegalsari | `dapat_diproses` | buku nikah, KK orang tua |
| S10 | KK | perubahan anggota, kelahiran, Tegalsari | `dapat_diproses` | akta kelahiran, KK lama |
| S11 | KK | perubahan anggota, kematian | `dapat_diproses` | akta kematian |
| S12 | KK | hilang | `dapat_diproses` | surat kehilangan Polsek |
| S13 | KK | pindah datang, luar Tegalsari | `dapat_diproses` | **pengecualian `KK-R10`**: SKPWNI, KK asal |
| S14 | KK | perubahan anggota, kelahiran, luar Tegalsari | `tidak_dapat_diproses` | `KK-R10` mengalahkan `KK-R03` (99 > 85) |
| S15 | Domisili | warga tetap, kerja | `dapat_diproses` | KTP, KK, pengantar RT/RW |
| S16 | Domisili | tinggal sementara, ada bukti | `dapat_diproses` | surat pernyataan, bukti tinggal |
| S17 | Domisili | tinggal sementara, tanpa bukti | `dengan_catatan` | Q3 **harus** tetap ditanyakan |
| S18 | Domisili | warga tetap, usaha | `dapat_diproses` | + foto usaha, surat tidak keberatan |

Catatan tahapan (U-01): S03–S07 **semuanya** menghasilkan lima tahapan yang sama dari `services/ktp.stepsDasar`. Yang membedakan kelimanya hanya daftar persyaratan. Bila suatu saat daftar tahapan S03 dan S04 berbeda, itu tanda bahwa `addSteps` dipakai tanpa alasan yang terdokumentasi — dan S40 akan gagal.

### 14.2 Skenario negatif & teknis

| # | Skenario | Harapan |
|---|---|---|
| S19 | Fakta tidak lengkap | Tidak crash; `outcome == null` + "panduan belum tersedia" |
| S20 | `serviceId` tidak dikenal | `KnowledgeBaseException`; UI menampilkan error state |
| S21 | Dua aturan menetapkan outcome berbeda | Pemenang sesuai prioritas; hasil tidak bergantung urutan |
| S22 | Aturan dievaluasi dua kali | Persyaratan tidak duplikat |
| S23 | Login password salah | Tetap di H1, pesan "Email atau kata sandi salah" |
| S24 | Login email tidak valid | Validasi klien menolak sebelum memanggil Firebase |
| S25 | Membuka `/admin` sebagai warga | Dialihkan ke H2; menu tidak tampil |
| S26 | Firestore kosong (belum di-seed) | H3 menampilkan "layanan belum tersedia"; tidak crash |
| S27 | Koneksi terputus saat memuat layanan | Error state + tombol "Coba lagi" |
| S28 | Admin mengubah teks persyaratan | Perubahan tampil pada sesi panduan berikutnya |

### 14.3 Skenario regresi khusus v1.2 dan v1.3

Skenario berikut dibuat **khusus** untuk mengunci perbaikan T-01, T-02, T-04, T-06, U-02, U-03, dan U-04. Tanpa skenario ini, bug yang sama dapat muncul kembali tanpa ketahuan.

| # | Skenario | Harapan | Mengunci |
|---|---|---|---|
| **S29** | KTP 17+, sudah punya, **luar Tegalsari**, alasan hilang | `tidak_dapat_diproses`; `alasan_pengajuan_ktp` **tidak ditanyakan**; persyaratan kosong | T-01, T-03 |
| **S30** | Domisili tinggal sementara **tanpa** bukti | `dengan_catatan`; `punya_bukti_tinggal` **tetap ditanyakan** walau `DOM-R02` sudah menetapkan outcome sementara | T-01 |
| **S31** | Layanan `aktif = false` | Tetap muncul di H3 bertanda "belum tersedia"; tidak dapat dipilih | T-06 |
| **S32** | Opsi jawaban tanpa aturan (mis. `alasan = lainnya`) | `outcome == null` → "Panduan belum tersedia"; `trace` tetap terekam | §10.8 |
| **S33** | Admin menonaktifkan seluruh aturan sebuah layanan | `outcome == null` pada layanan itu; layanan lain tidak terpengaruh | §12.4 |
| **S34** | Tekan "Kembali" setelah 3 jawaban, lalu jawab berbeda | Tidak ada persyaratan "hantu" dari jalur lama; hasil = hasil jalur baru | T-04 |
| **S35** | KTP **<17, `pernah_menikah`, Tegalsari** | `outcome == null` → "Panduan belum tersedia" + `NOTE_KASUS_BELUM_TERCAKUP`; **tidak ada persyaratan** yang dikarang; 3 pertanyaan ditanyakan | U-02 |
| **S36** | KTP **<17, `pernah_menikah`, luar Tegalsari** | `tidak_dapat_diproses` dari `KTP-R08`; membuktikan `KTP-R10` **tidak** menghentikan sesi sebelum domisili ditanyakan | U-02, §10.6 |
| **S37** | `showIf` merujuk fakta yang belum ada | Pertanyaan **tidak** tampil sebelum dependensinya terjawab; tampil setelahnya | U-03 |
| **S38** | Basis pengetahuan dengan `showIf.fact` yang tidak dikenal | Repository **menolak** saat dimuat (`KnowledgeBaseException`), bukan melewati pertanyaan diam-diam | U-03 |
| **S39** | Ubah `kategori_usia` dari 17+ ke <17 setelah 4 jawaban | Fakta `sudah_punya_ktp` dan `alasan_pengajuan_ktp` **terpangkas**; `KTP-R04` tidak menyala; tidak ada "surat kehilangan Polsek" | U-04 |
| **S40** | KTP baru vs KTP hilang (S03 vs S04) | **Daftar tahapan identik** (5 langkah dari `stepsDasar`); hanya persyaratan yang berbeda | U-01 |
| **S41** | Basis pengetahuan dengan aturan terminal **tanpa** `setOutcome` | Ditolak saat dimuat dengan pelanggaran **V-1**; bukan diterima lalu berhenti dengan "panduan belum tersedia" | V-01 |
| **S42** | Dua aturan terminal, outcome berbeda, dapat menyala bersamaan (`status_perkawinan` berbeda) | Ditolak dengan pelanggaran **V-2** | V-01 |
| **S43** | Aturan terminal berprioritas 60, aturan non-terminal berprioritas 90 | Ditolak dengan pelanggaran **V-3**; tanpa ini, sesi berhenti dengan outcome milik aturan non-terminal | V-01 |
| **S44** | Admin menyimpan aturan yang melanggar V-1/V-2/V-3 lewat H6 | Penyimpanan **ditolak** di form, pesan menyebut kode pelanggaran; basis pengetahuan lama tetap utuh | V-02 |
| **S45** | Konfigurasi rusak ditulis langsung lewat Console (melewati validasi simpan) | Saat dimuat ditolak; layanan itu menampilkan "layanan belum tersedia", layanan lain tidak terpengaruh | V-01, V-02 |
| **S46** | Konfigurasi lolos validasi muat, tetapi pemenang outcome bukan aturan terminal | `CONFIG_WARNING` tercatat; sesi **melanjutkan** pertanyaan, bukan berhenti (§10.6.2) | V-01 |

**Catatan penomoran:** S29–S34 berasal dari v1.2; S35–S40 dari v1.3; S41–S46 ditambahkan pada v1.4 untuk mengunci invarian terminal dan validasi jalur simpan. Total skenario menjadi **46**, seluruhnya masih berstatus **direncanakan** dan belum dijalankan.

### 14.4 Contoh penelusuran (trace) empat skenario

Bagian ini menunjukkan bagaimana aturan, terminal, dan resolusi konflik bekerja pada jalur nyata. Berguna sebagai bahan BAB IV dan untuk memverifikasi implementasi Tahap 1–2.

**A. Pengajuan KTP baru** (S03)

```
Fakta awal   : { service: ktp }

Q1 kategori_usia        → 17_ke_atas
Q2 status_perkawinan    → (tidak ditanya, showIf = di_bawah_17)
Q3 sudah_punya_ktp      → tidak
   inferensi #1: KTP-R03 menyala (p70)
                 outcome sementara = dapat_diproses
                 terminal = false  → lanjut
Q4 domisili_pemohon     → tegalsari
   inferensi #2: KTP-R03 tetap menyala, tidak ada aturan domisili yang cocok
                 terminal = false  → lanjut
Q5 alasan_pengajuan_ktp → (tidak ditanya, showIf = sudah_punya_ktp = ya)
Pertanyaan habis → inferensi akhir

Aturan menyala : KTP-R03 (p70)
Outcome        : dapat_diproses
Persyaratan    : KK asli · akta kelahiran · pengantar RT/RW · F-1.01
Tahapan        : stepsDasar[ktp] = loket → serah berkas → verifikasi → rekam → ambil
                 (tidak ada addSteps dari aturan mana pun)
                 ⚠ STEP_REKAM masih ASUMSI RANCANGAN — belum dikonfirmasi petugas (§11.5)
Terminal       : tidak
```

Perhatikan dua hal. **Pertama**, `KTP-R03` menetapkan outcome pada inferensi #1, tetapi sesi **tetap berlanjut** ke Q4 karena `terminal: false` — inilah perbaikan T-01. **Kedua**, tahapan **tidak** berasal dari aturan, melainkan dari `services/ktp.stepsDasar` (U-01). Karena itu S03 dan S04–S07 akan menghasilkan daftar tahapan yang identik (S40).

**B. Penggantian KTP hilang** (S04)

```
Fakta awal   : { service: ktp }

Q1 kategori_usia        → 17_ke_atas
Q3 sudah_punya_ktp      → ya
   inferensi #1: belum ada aturan yang cocok (alasan belum diketahui)
                 outcome = null, terminal = false → lanjut
Q4 domisili_pemohon     → tegalsari
   inferensi #2: masih belum ada aturan yang cocok
                 outcome = null, terminal = false → lanjut
Q5 alasan_pengajuan_ktp → hilang
   inferensi #3: KTP-R04 menyala (p75) → outcome dapat_diproses
                 terminal = false
Pertanyaan habis → inferensi akhir

Aturan menyala : KTP-R04 (p75)
Outcome        : dapat_diproses
Persyaratan    : surat kehilangan Polsek · fotokopi KK · F-1.01
Tahapan        : stepsDasar[ktp] = loket → serah berkas → verifikasi → rekam → ambil
                 ⚠ STEP_REKAM masih ASUMSI RANCANGAN — belum dikonfirmasi petugas (§11.5)
Terminal       : tidak
```

Perhatikan: sebelum Q5, `outcome` masih `null` — dan itu **normal**, bukan kegagalan. H5 tidak pernah ditampilkan pada keadaan ini karena sesi belum selesai. Bila `KTP-R04` lupa menetapkan outcome (seperti pada v1.1), hasil akhirnya tetap `null` → "panduan belum tersedia" padahal jalurnya sah. Inilah T-02.

**C. Perubahan data KK untuk pemohon di luar Tegalsari** (S14)

```
Fakta awal   : { service: kk }

Q1 kondisi_kk           → perubahan_anggota
   inferensi #1: belum ada aturan yang cocok (jenis perubahan belum diketahui)
                 outcome = null, terminal = false → lanjut
Q2 jenis_perubahan_kk   → kelahiran
   inferensi #2: KK-R03 menyala (p85) → outcome dapat_diproses
                 terminal = false → lanjut
Q3 domisili_pemohon     → luar_tegalsari
   inferensi #3: KK-R10 menyala (p99, terminal)
                 → outcome tidak_dapat_diproses

Aturan menyala : KK-R03 (p85), KK-R10 (p99)
Pemilihan outcome:
   kandidat = [KK-R03 → dapat_diproses (85), KK-R10 → tidak_dapat_diproses (99)]
   pemenang = KK-R10  (prioritas 99 > 85)
Outcome        : tidak_dapat_diproses
Persyaratan    : DISEMBUNYIKAN (outcome = tidak_dapat_diproses) — §10.7
                 (meski KK-R03 sempat menambahkannya; tetap ada di trace)
Tahapan        : DISEMBUNYIKAN (aturan yang sama)
Terminal       : ya (KK-R10) — namun tidak ada pertanyaan tersisa
```

Perhatikan: tanpa perbaikan T-01, sesi akan berhenti setelah Q2 dengan outcome `dapat_diproses` — **jawaban yang salah**, karena pemohon justru diarahkan ke kelurahan lain. Inilah kasus paling berbahaya pada v1.1.

**D. KTP di bawah 17 tahun dengan status pernah menikah** (S35 — baru di v1.3)

```
Fakta awal   : { service: ktp }

Q1 kategori_usia        → di_bawah_17
Q2 status_perkawinan    → pernah_menikah
   inferensi #1: KTP-R10 menyala (p88)
                 tanpa setOutcome → outcome = null
                 terminal = false → lanjut     ← sengaja, lihat §10.6
Q4 domisili_pemohon     → tegalsari
   inferensi #2: KTP-R10 tetap menyala, KTP-R08 tidak cocok
                 outcome = null, terminal = false
Q3 sudah_punya_ktp      → (tidak ditanya, showIf = 17_ke_atas)
Q5 alasan_pengajuan_ktp → (tidak ditanya, showIf = sudah_punya_ktp = ya)
Pertanyaan habis → inferensi akhir

Aturan menyala : KTP-R10 (p88)
Outcome        : null  → "Panduan belum tersedia"
Catatan        : "Kasus Anda belum tercakup dalam panduan ini.
                  Silakan konfirmasi langsung ke loket pelayanan Kelurahan Tegalsari."
Persyaratan    : kosong (tidak dikarang)
Tahapan        : tidak ditampilkan
```

Bila jawaban Q4 adalah `luar_tegalsari`, `KTP-R08` (p99) menyala dan outcome menjadi `tidak_dapat_diproses` — jawaban yang pasti. Inilah alasan `KTP-R10` **tidak** dibuat terminal (S36).

---

## 15. Rencana Implementasi Bertahap

Urutan: **periksa struktur proyek → uji mesin aturan → UI → autentikasi → integrasi Firestore → uji alur → deployment.**

Prinsip: **jangan menyentuh Firebase sebelum mesin aturan lulus uji.** Bila ada bug, Anda tahu pasti bug itu ada di aturan, bukan di jaringan, autentikasi, atau aturan keamanan.

### Tahap 0 — Pemeriksaan struktur proyek (Minggu 5, checkpoint)
- `git init`, commit pertama, `.gitignore` (pastikan `firebase_options.dart` dan berkas kunci tidak ikut).
- Ganti identitas default: `com.example.ips_guide` → paket resmi kampus; nama tampilan "IPS-Guide".
- Hapus demo counter; `main.dart` ditulis ulang minimal.
- `theme.dart` dari §13 (warna eksplisit, Inter).
- Dependensi: `go_router`, `flutter_riverpod` (Firebase belum).
- **Bukti:** repo GitHub berisi commit pertama; `flutter analyze` bersih; aplikasi berjalan di Chrome.

### Tahap 1 — Domain & mesin aturan (pure Dart)
- Seluruh entity, termasuk `RuleAction.terminal` dan `GuidanceService.stepsDasar`.
- `FactBase`, `ConditionEvaluator` (8 operator), `RuleEngine` (`inferensi` + `pilihOutcome` + `terminal`), `QuestionSelector`, `GuidanceSession` (**recompute dari nol** + **`pangkas`**).
- Uji unit: setiap operator; `when` bersarang; chaining dua tingkat; idempotensi; **outcome dipilih berdasarkan prioritas, bukan urutan**; **terminal menghentikan sesi**; **`showIf` tiga nilai** (`undefined` tidak boleh dianggap `true`); **`pangkas` membuang fakta jalur lama secara iteratif**; **recompute setelah "Kembali" tidak menyisakan aturan basi**.
- **Kriteria lulus:** seluruh uji engine hijau; `lib/domain/` tidak mengimpor Flutter maupun Firestore.

### Tahap 2 — Basis pengetahuan awal + uji skenario
- `assets/seed/*.json` (layanan + `stepsDasar`, pertanyaan, persyaratan, tahapan, aturan KTP/KK/Domisili) — **setiap dokumen memuat `aktif: true`**.
- DTO + `InMemoryKnowledgeBaseRepository` + **validasi basis pengetahuan** (lihat daftar di bawah).
- `scenario_test.dart`: S01–S22, S29–S43, S45–S46.
- **Bukti:** 39 skenario hijau **tanpa Firebase sama sekali**. (S44 diuji di Tahap 7 karena memerlukan form H6.)

**Validasi wajib saat basis pengetahuan dimuat** (bukan saat runtime, agar kesalahan data tidak muncul sebagai bug UI):

| Pemeriksaan | Alasan |
|---|---|
| ID dokumen unik | Mencegah dokumen saling menimpa saat seed |
| Setiap `addRequirements` ada di katalog `requirements` | Mencegah persyaratan hilang diam-diam |
| Setiap ID di `stepsDasar` ada di katalog `steps` | Mencegah tahapan kosong |
| Setiap `showIf.fact` adalah `factKey` pertanyaan lain atau `service` | Mencegah pertanyaan hilang karena salah ketik (U-03) |
| `factKey` unik dalam satu layanan | Mencegah hasil bergantung urutan |
| Setiap ID aturan `terminal: true` tercantum di tabel bukti §10.6 | Mencegah terminal ditambahkan tanpa alasan |
| **V-1**: setiap aturan terminal menetapkan `setOutcome` | Aturan terminal tanpa keputusan akan berhenti dengan "panduan belum tersedia" (§10.6.1) |
| **V-2**: dua aturan terminal dengan outcome berbeda harus terbukti saling lepas | Mencegah hasil bergantung pada urutan evaluasi |
| **V-3**: prioritas aturan terminal > prioritas seluruh aturan non-terminal pada layanan yang sama | Menjamin outcome pemenang selalu berasal dari aturan terminal |
| Setiap nilai opsi jawaban tertangani minimal satu aturan **atau** didokumentasikan sebagai celah yang disengaja | Membedakan "belum tercakup" dari "lupa dibuat" |

Validator yang sama dipakai ulang di H6 sebelum penyimpanan (§12.5) — satu implementasi, dua titik pemanggilan. Ini disengaja: bila aturan validasi hanya hidup di jalur muat, admin dapat menyimpan konfigurasi rusak dan baru mengetahuinya saat warga membuka panduan.

### Tahap 3 — Kerangka UI & navigasi (data palsu)
- `router.dart` dengan ShellRoute, `NavigationBar`/`NavigationRail`, breakpoint 600 px.
- H2 Beranda, H3 Pilih Layanan (termasuk kartu nonaktif), halaman 404.
- **Bukti:** navigasi berjalan di Chrome; URL berubah; back browser wajar.

### Tahap 4 — H4 Pertanyaan Panduan & H5 Hasil Panduan
- `GuidanceController` (`loading → questioning → completed | error`).
- Satu pertanyaan per langkah; progres; tombol kembali menghapus jawaban terakhir **dan memicu recompute**.
- H5: banner status, ringkasan jawaban, checklist persyaratan (**disembunyikan bila `tidak_dapat_diproses`**), timeline tahapan, catatan, disclaimer, "Mengapa?", salin ringkasan.
- **Bukti:** S03 dan S14 dapat ditelusuri penuh di Chrome; uji widget alur hijau.

### Tahap 5 — Firebase & autentikasi (H1)
- Proyek Firebase (paket Spark, **tanpa billing**), `flutterfire configure`.
- Authentication email/password.
- H1 Login + mode Daftar (**meminta nama**); pemetaan galat §9.2; guard rute; tombol Keluar.
- Koleksi `users` + aturan keamanan untuk `users`.
- **Bukti:** login/daftar/keluar berjalan; S23–S24, S25 lulus.

### Tahap 6 — Integrasi Firestore
- Koleksi + **dua index komposit** (§8.3).
- Terapkan `firestore.rules` (§8.4).
- `FirestoreKnowledgeBaseRepository` + mapper; ganti provider (UI tidak berubah).
- Tombol "Impor data awal" di H6 untuk seed dari `assets/seed/` (batch, idempotent, `aktif` eksplisit).
- **Bukti:** S26–S28, S31, S45 lulus; 39 skenario engine tetap hijau; data terbaca dari Firestore.

### Tahap 7 — H6 Kelola Panduan (Admin), bertahap
- **7A Read** → **7B Update** (wajib) → **7C Create** → **7D Delete** (nonaktifkan).
- Setiap penyimpanan melewati validator yang sama dengan jalur muat (§12.5), termasuk invarian V-1/V-2/V-3.
- **Bukti:** S28, S33, S44 lulus; perubahan dari H6 terlihat pada panduan berikutnya.

### Tahap 8 — Pengujian alur menyeluruh
- Uji black box S01–S46 dengan tabel hasil (bahan BAB IV).
- Keadaan alternatif: Login–Galat, Layanan belum tersedia, Jawaban belum lengkap, Panduan belum tersedia.
- **Uji matriks keamanan manual** (§8.5): enam kasus di bawah, dicatat apa adanya.
- Responsif 360 / 768 / 1280 px; tidak ada overflow.
- Aksesibilitas dasar: target sentuh ≥48 px, label `Semantics`, kontras.
- **Bukti:** tabel uji terisi lengkap dengan status lulus/gagal **yang sebenarnya**.

**Matriks uji keamanan manual** — belum dijalankan; kolom "Hasil" sengaja dibiarkan kosong sampai dieksekusi.

| # | Kasus | Cara menguji | Hasil yang diharapkan | Hasil nyata |
|---|---|---|---|---|
| K1 | Warga menulis ke `rules` lewat SDK | Panggil `set()` dari konsol aplikasi | `permission-denied` | *belum diuji* |
| K2 | Warga membuka `/admin` lewat URL | Ketik rute langsung | Dialihkan ke Beranda | *belum diuji* |
| K3 | Warga mengubah `role` miliknya sendiri | `update({role:'admin'})` | Ditolak server | *belum diuji* |
| K4 | Admin menghapus dokumen `rules` | `delete()` dari H6 | Ditolak (`delete: if false`) | *belum diuji* |
| K5 | Pengguna login tanpa dokumen `users` | Hapus dokumen profil di Console, lalu login | Pesan "Profil akun tidak ditemukan" (§9.1) | *belum diuji* |
| K6 | Pengguna tanpa login membaca `services` | Panggil SDK sebelum login | Ditolak | *belum diuji* |

### Tahap 9 — Deployment Firebase Hosting
- `flutter build web --release` → `firebase deploy --only hosting`.
- Tambahkan domain Hosting ke authorized domains Authentication.
- **Bukti:** tautan Hosting dapat dibuka; login dan panduan berjalan di domain publik.

### Tahap 10 — Validasi & dokumentasi skripsi
- Validasi isi aturan oleh petugas Kelurahan Tegalsari (`docs/VALIDASI-ATURAN.md`).
- Pemetaan BAB III dan BAB IV ke dokumen ini.
- **Bukti:** lembar validasi terisi; revisi aturan hanya menyentuh Firestore/JSON.

### 15.1 Ketergantungan antar tahap

```
T0 struktur ──► T1 engine ──► T2 skenario ──► T3 UI kerangka ──► T4 H4/H5
                                                                    │
                            T5 auth ◄───────────────────────────────┘
                              │
                              ▼
                            T6 Firestore ──► T7 admin CRUD ──► T8 uji alur ──► T9 hosting
                                                                                  │
                                                                                  ▼
                                                                              T10 dokumentasi
```

Tahap 5 tidak boleh dimulai sebelum Tahap 2 lulus; Tahap 6 tidak sebelum Tahap 5 stabil. Bila waktu mepet, yang dipotong **7C/7D**, bukan Tahap 8.

---

## 16. Strategi Pengujian

| Level | Alat | Cakupan | Butuh Firebase? |
|---|---|---|---|
| Unit — engine | `flutter test` | Evaluator, chaining, `pilihOutcome`, `terminal`, `showIf` tiga nilai, `pangkas`, recompute | Tidak |
| Unit — mapper | `flutter test` | `Map` → Entity; field hilang; **`aktif` tidak ada**; validasi basis pengetahuan | Tidak |
| Skenario | `flutter test` | S01–S22 + S29–S43 + S45–S46 (39 skenario) | Tidak |
| Widget | `flutter_test` | H3→H4→H5, H1 galat, keadaan kosong | Tidak (repository di-override) |
| Integrasi manual | Chrome | S23–S28, S31, S33, S44 | Ya |
| Black box | Chrome | Seluruh S01–S46 | Ya |
| Keamanan manual | Chrome + Console | Matriks K1–K6 (§15 Tahap 8) | Ya |
| Aturan Firestore | Emulator Suite | Warga ditolak menulis; admin diizinkan | Opsional, **belum dijalankan** |

**Yang belum boleh diklaim:** login berhasil, data terbaca dari Firestore, deploy Hosting, aturan keamanan bekerja. Semua itu baru boleh ditulis "lulus" setelah ada tangkapan layar atau keluaran uji. Tabel pada §14 adalah **rencana**, bukan hasil.

---

## 17. Keputusan Teknis & Alternatif

| Keputusan | Pilihan | Alasan | Alternatif yang ditolak |
|---|---|---|---|
| Sumber data panduan | Firestore | Batas mata kuliah; CRUD oleh admin | JSON statis (tidak memenuhi requirement CRUD) |
| Mesin aturan | Pure Dart | Dapat diuji cepat; tidak terikat vendor | Evaluasi di Cloud Functions (dilarang) |
| Penghentian sesi | Flag `terminal` per aturan | Outcome ≠ alasan berhenti (T-01) | Berhenti saat outcome ditetapkan (salah) |
| State inferensi | Recompute dari nol | Kebenaran lebih penting daripada optimasi mikro (T-04) | Menyimpan `fired` dan membatalkannya (rawan) |
| Pemilihan outcome | Prioritas tertinggi | Deterministik (T-05) | "Yang terakhir menang" |
| Repository | Antarmuka + dua implementasi | UI dibangun sebelum Firebase ada | Langsung Firestore |
| State | `flutter_riverpod` | Controller testable | `ChangeNotifier` |
| Navigasi | `go_router` + ShellRoute | URL nyata, guard rapi | `Navigator` 1.0 |
| Hapus data | Nonaktifkan (`aktif = false`) | Menghindari referensi terputus | Hapus permanen |
| Offline | Tidak dibuat | Tidak ada kebutuhan jelas | Cache kustom (kompleks) |
| Cetak hasil | `Clipboard` bawaan | 0 dependensi | `printing`/PDF |

Dependensi: `firebase_core`, `firebase_auth`, `cloud_firestore`, `go_router`, `flutter_riverpod`, `google_fonts`.

---

## 18. Risiko & Mitigasi

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Bug logika aturan lolos ke UI | Jawaban salah, sulit dilacak | Engine diuji tuntas (T1–T2) sebelum UI; S29–S40 sebagai regresi |
| Waktu habis sebelum Tahap 6 | Tidak terintegrasi Firestore | Engine & UI selesai lebih dulu |
| Aturan keamanan salah | Data tidak terbaca | Uji dua akun di T6; matriks K1–K6 di T8 |
| Klaim keamanan berlebihan ("warga tidak bisa buka H6") | Dipertanyakan penguji | Tiga lapis dibedakan eksplisit (§8.5); klaim dibatasi pada penolakan server |
| Admin pertama tak bisa dibuat dari aplikasi | Tidak bisa kelola data | Bootstrap manual di Console, terdokumentasi |
| Isi persyaratan tidak sesuai praktik kelurahan | Dipertanyakan saat sidang | Validasi petugas (T10); teks di Firestore |
| Jalur `pernah_menikah` belum tervalidasi | Jawaban "belum tersedia" dianggap bug | Dinyatakan sebagai perilaku sengaja (§11.1); diuji S35–S36; ditanyakan saat validasi |
| Tahapan KTP diasumsikan seragam | Salah menyebut perekaman | Asumsi dinyatakan terbuka (§11.5); koreksi hanya mengubah data |
| Perbedaan Must/Should admin dianggap tidak konsisten | Nilai berkurang | Dinyatakan eksplisit di §12 |
| Tampilan berbeda dari Figma | Revisi berulang | `ColorScheme` eksplisit (§13.4) |
| Kuota Spark terlampaui | Demo berhenti | Data <100 dokumen; hindari listener realtime |
| Dokumen tanpa field `aktif` "hilang" diam-diam | Sulit dilacak | Validasi mapper + seed wajib `aktif` (§8.3) |
| Sesi hilang saat refresh | Pengguna mengulang | Diterima untuk prototype; tombol "Mulai ulang" jelas |

---

## 19. Yang Perlu Dikonfirmasi Sebelum Implementasi

1. **Paket aplikasi** — `id.ac.undip.ipsguide` atau nama lain?
2. **Proyek Firebase** — sudah ada atau dibuat pada Tahap 5?
3. **Akun demo** — perlu akun warga & admin contoh untuk sidang?
4. **`guidanceLogs`** — dipakai (menyimpan `uid`+`serviceId`+`outcome`), atau tidak dibuat sama sekali? (§1.4)
5. **H6 di Figma** — perlu frame Kelola Panduan digambar?
6. **Validasi aturan** — sudah ada SOP resmi Kelurahan Tegalsari, atau §11 masih perlu disesuaikan?
7. **Jalur `pernah_menikah` di bawah 17 tahun** — apakah diperlakukan sama dengan "menikah", atau memerlukan dokumen lain? **Tanpa jawaban ini, jalur tersebut tetap menghasilkan "Panduan belum tersedia"** (§11.1).
8. **Perekaman biometrik** — apakah semua jenis pengajuan KTP melewati perekaman, atau hanya pengajuan baru? Jawaban ini menentukan apakah `STEP_REKAM` tetap di `stepsDasar` atau dipindah ke `addSteps` (§11.5).

Tahap 0–2 tidak bergantung pada satu pun dari kedelapan poin di atas.

---

*Dokumen ini adalah rancangan. Tidak ada kode aplikasi yang diubah saat v1.4 disusun, tidak ada pengujian yang dijalankan, dan tidak ada hasil validasi petugas Kelurahan yang diklaim. Asumsi tahapan pelayanan — khususnya perekaman biometrik pada seluruh pengajuan KTP — tetap berstatus asumsi sampai dikonfirmasi Kelurahan Tegalsari.*
