# Rencana Video UTS — IPS-Guide (Remotion + TTS gratis)

**Status:** **Sudah dijalankan.** Kandidat `out/uts-ips-guide-kandidat.mp4` (192,704 dtk, 1920×1080, 5.781 frame) sudah dirender dan diperiksa; `docs/NASKAH-VIDEO.md` mengikuti timeline kandidat. Berkas lama `out/uts-ips-guide.mp4` tidak diubah.  
**Tanggal:** 27 Oktober 2026  
**Pemilik:** Elisa Sandita Putri — 23.01.55.0010 — Kelas A1

---

## 1. Sumber acuan, dan batasnya (dinyatakan terbuka)

Saya mengekstrak teks dari tiga berkas modul di `C:\Users\DELL\Downloads\modul` lalu mencari kata  
`remotion`, `text to speech`, `TTS`, `narasi`, `suara`, dan `video`. Hasil pencarian:

| Berkas modul                                  | `remotion` | `TTS` | `text to speech` | `video` |
| --------------------------------------------- | ---------- | ----- | ---------------- | ------- |
| modul-minggu-05-setup-project-repository.docx | 0          | 0     | 0                | 0       |
| modul-minggu-06-widget-layout-navigasi.docx   | 0          | 0     | 0                | 0       |
| modul-minggu-07-form-validasi-state.docx      | 0          | 0     | 0                | 1       |

Satu-satunya kemunculan kata "video" ada di bagian **Persiapan UTS**:

> "Proposal ringkas (video) — Masalah, target pengguna, dan scope aplikasi."

**Kesimpulan yang jujur:** arahan "Remotion + TTS gratis" **tidak ada** di tiga modul yang saya pegang.  
Arahan itu saya terima dari Anda (hasil penyampaian dosen di kelas), bukan dari dokumen yang bisa saya  
kutip. Karena itu rencana ini memisahkan dua hal secara tegas:

- **Isi video** → mengikuti modul (yang bisa dikutip).
- **Alat produksi** → mengikuti arahan dosen (yang tidak bisa saya verifikasi dari berkas).

Tidak ada modul Minggu 8 dan seterusnya di folder tersebut, jadi tidak ada ketentuan tambahan  
(durasi, format, atau rubrik video) yang bisa saya baca. Asumsi durasi 3 menit saya tandai sebagai  
**usulan**, bukan kutipan.

---

## 2. Yang wajib muncul di video (dari modul Minggu 7)

Modul menyebut lima bagian UTS; video hanya memikul bagian pertama, tetapi isinya harus konsisten  
dengan empat bagian lain karena penguji akan menanyakan hal yang sama.

| Bagian UTS (kutipan modul)                                              | Porsi video                                     |
| ----------------------------------------------------------------------- | ----------------------------------------------- |
| **Proposal ringkas (video)** — masalah, target pengguna, scope aplikasi | seluruh video                                   |
| Artefak desain — persona, user story, user flow, wireframe              | disebut lisan 1 kalimat + tautan Figma di akhir |
| Demo prototype — minimal tiga halaman + form yang dapat diuji           | adegan demo (rekaman layar asli)                |
| Rencana teknis — tech stack + rencana database dari field form          | adegan "bagaimana data disimpan"                |
| Repository — GitHub dengan README dan riwayat commit                    | adegan penutup                                  |

Modul juga mencantumkan **empat pertanyaan penguji**, dan inilah tulang punggung naskah:

1. Masalah apa yang diselesaikan?
2. Siapa pengguna utama?
3. Mengapa fitur ini diprioritaskan?
4. Bagaimana data akan disimpan?

Naskah di §7 disusun persis mengikuti empat pertanyaan itu, supaya video dan sesi tanya-jawab  
menyampaikan cerita yang sama.

**Usulan durasi: 3 menit (maksimum 3 menit 30 detik).** Alasannya: "proposal ringkas", dan penguji  
biasanya memotong di menit ketiga. Ini usulan saya, bukan angka dari modul.

---

## 3. Keputusan teknis

### 3.1 Peran Remotion: kompositor, bukan tiruan UI

Ada dua cara memakai Remotion, dan pilihannya menentukan kejujuran video:

| Cara                                    | Isi                                                                                        | Penilaian                                                                                                                                        |
| --------------------------------------- | ------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| **A. Bikin ulang UI aplikasi di React** | Seluruh layar dibuat ulang sebagai komponen React, lalu direkam Remotion                   | Ditolak. Menduplikasi pekerjaan, dan yang tampil di video bukan aplikasi yang benar-benar ada — berisiko dianggap menyesatkan saat demo langsung |
| **B. Remotion sebagai kompositor**      | Rekaman layar asli (`<OffthreadVideo>`) + narasi TTS + judul, subtitle, dan gerakan kamera | **Dipilih.** Yang tampil adalah aplikasi nyata; Remotion dipakai untuk hal yang memang butuh kode: timing, teks, transisi, subtitle              |

Konsekuensi cara B: rekaman layar harus diambil lebih dulu (lihat §3.4). Kalau rekaman belum ada,  
Remotion tetap bisa di-scaffold, tetapi adegan demo akan kosong.

### 3.2 Lisensi dan prasyarat (sudah diverifikasi)

- **Lisensi Remotion.** Remotion gratis untuk individu dan organisasi sampai 3 orang; perusahaan  
  lebih besar wajib Company License. Saya cek langsung di `remotion.dev` pada 27 Oktober 2026.  
  Sebagai mahasiswa perorangan, Anda memenuhi syarat Free License — cukup dicatat di laporan,  
  tidak perlu membeli apa pun.
- **Node.js.** Sudah tersedia di mesin ini: v22.22.2 (managed) dan v24.18.0 (sistem). Remotion  
  berjalan di Node, bukan di Flutter — jadi ini **tidak melanggar** batas stack mata kuliah  
  (Flutter/Firebase), karena video adalah deliverable terpisah, bukan bagian aplikasi.
- **Chrome Headless Shell.** Render pertama mengunduh Chrome Headless Shell otomatis (±150 MB).  
  Butuh koneksi stabil sekali saja; sesudahnya render jalan offline.
- **Tidak ada billing, tidak ada API key berbayar.** Sesuai batas mata kuliah.

### 3.3 Lokasi proyek: folder terpisah, di luar repo Flutter

```
C:\dev\ips-video\          ← proyek Remotion (Node), TIDAK masuk repo skripsi
C:\dev\ips_guide\          ← repo Flutter (tetap bersih)
```

Alasan: `node_modules` berukuran ratusan MB, tidak relevan bagi penguji Flutter, dan akan mengotori  
riwayat commit. Yang masuk repo hanya dua dokumen: `docs/RENCANA-VIDEO.md` (berkas ini) dan  
`docs/NASKAH-VIDEO.md` (naskah final, dibuat pada tahap V3).

### 3.4 Aset rekaman layar

- Sumber: **build web release** yang sudah berjalan di `http://localhost:8080` — bukan  
  `flutter run -d chrome`, karena debug service (DWDS) bermasalah di lingkungan ini dan sudah  
  terbukti menghasilkan halaman putih.
- Perangkat: **Xbox Game Bar (Win+G)** — sudah ada di Windows, gratis, tanpa instalasi; alternatif  
  OBS Studio kalau butuh rekam per-adegan lebih rapi.
- Spesifikasi: MP4 H.264, 1920×1080, 30 fps, tanpa kursor bila memungkinkan.
- Penyimpanan: `ips-video/public/rekaman/`.
- Rencana cadangan bila rekaman terasa goyah: tangkapan layar resolusi tinggi + gerakan kamera  
  lambat (efek Ken Burns) di Remotion. Tetap jujur, karena tetap gambar aplikasi asli.

---

## 4. TTS gratis — pilihan, dan rekomendasi

Remotion **tidak** menyediakan TTS. Audio dibuat lebih dulu oleh alat lain, lalu dimasukkan sebagai  
`<Audio src={staticFile('narasi/scene-01.wav')} />`. Empat opsi gratis yang realistis:

| Opsi                               | Suara Indonesia                                                                  | Lisensi / status                                                                                        | Offline | Keluaran      | Catatan                                                                                        |
| ---------------------------------- | -------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- | ------- | ------------- | ---------------------------------------------------------------------------------------------- |
| **Piper** (`OHF-Voice/piper1-gpl`) | Tersedia — "Bahasa Indonesia (Indonesian, Indonesia)" ada di daftar sampel resmi | Kode terbuka (GPL); lisensi tiap model berbeda                                                          | Ya      | WAV 22,05 kHz | Paling aman untuk skripsi: reproducible, tanpa layanan pihak ketiga, tidak bisa tiba-tiba mati |
| **edge-tts**                       | `id-ID-GadisNeural` (perempuan), `id-ID-ArdiNeural` (laki-laki)                  | **Tidak resmi** — membungkus fitur baca-nyaring Edge; bisa berubah, ada batas ±2000 karakter/permintaan | Tidak   | MP3           | Kualitas paling natural, tetapi status tidak resmi sebaiknya disebut di laporan                |
| **gTTS**                           | `id`                                                                             | Tidak resmi (Google Translate)                                                                          | Tidak   | MP3           | Paling datar/robotik                                                                           |
| **Windows SAPI bawaan**            | Tergantung language pack (mis. Microsoft Gadis)                                  | Bawaan Windows                                                                                          | Ya      | WAV           | Nol instalasi, tapi intonasi paling kaku dan ketersediaan tidak pasti                          |

**Rekomendasi: Piper sebagai pilihan utama**, dengan uji A/B lebih dulu (tahap V2): bacakan tiga  
kalimat khas naskah — satu kalimat tanya, satu berisi istilah "Kartu Keluarga", satu berisi angka  
"23.01.55.0010" — lalu dengarkan. Bila intonasi Indonesia terasa mengganggu, baru pindah ke  
edge-tts, dan catat pilihan beserta alasannya di laporan.

**Yang sudah saya verifikasi:** daftar bahasa Piper memuat Bahasa Indonesia, dan kedua nama suara
Azure/edge-tts Indonesia memang ada. Pada V2 nama modelnya terkonfirmasi: **`id_ID-news_tts-medium`**
(satu-satunya suara Indonesia di Piper, 22.050 Hz), berhasil diunduh dan dipakai untuk seluruh narasi.
Rincian hasil tiap tahap ada di §8.

---

## 5. Struktur proyek video (terpasang)

```
C:\dev\ips-video\
├─ package.json
├─ tsconfig.json
├─ voices\              id_ID-news_tts-medium.onnx (+ .json, MODEL_CARD)
├─ scripts\
│  ├─ tts.py            naskah → 28 WAV + timeline
│  ├─ timeline.py       susun ulang timeline dari WAV yang sudah ada
│  ├─ naskah-md.py      timeline → docs/NASKAH-VIDEO.md
│  ├─ rekam*.cjs        tangkapan layar aplikasi via Chrome headless
│  └─ periksa-video.cjs verifikasi MP4: putar, baca metadata, potret beberapa detik
├─ public\
│  ├─ rekaman\          12 PNG 3840×2160; 7 dipakai di adegan, 5 sisanya cadangan/diagnostik
│  └─ narasi\           28 WAV, satu berkas per kalimat
├─ src\
│  ├─ index.ts          registerRoot
│  ├─ Root.tsx          <Composition id="UTS-IpsGuide">
│  ├─ Video.tsx         Sequence per adegan + audio + subtitle
│  ├─ scenes.tsx        7 adegan
│  ├─ komponen.tsx      Latar, Kartu, Subtitle, TangkapanLayar
│  ├─ tema.ts           warna & tipografi
│  ├─ naskah.json       sumber tunggal teks narasi
│  └─ timeline.json     durasi & offset hasil ukur WAV
└─ out\                 hasil render (tidak di-commit)
```

`durationInFrames` tidak ditetapkan manual: dihitung dari `timeline.totalDetik` dengan
`Math.ceil(totalDetik × 30)`. Untuk kandidat: 192,679 × 30 = 5.780,37 → **5.781 frame**. Karena itu
muncul dua angka yang berbeda dan keduanya benar: **192,679 dtk** adalah jumlah durasi audio di
`timeline.json` (dasar perhitungan frame), sedangkan **192,704 dtk** adalah durasi kontainer MP4 hasil
ukur `ffprobe` (= 5.781 ÷ 30, ditambah ekor audio beberapa milidetik). Selisihnya 0,025 dtk dan tidak
berarti apa pun secara teknis — jangan salah satu angka dikira salah tulis. Setiap adegan memakai
`<Sequence>` dengan durasi masing-masing, dan satu berkas audio per kalimat — sehingga menyunting satu
kalimat hanya mengganti satu WAV, seperti yang dilakukan pada perbaikan kalimat 1:47.

---

## 6. Storyboard 3 menit

> **Tabel di bawah adalah rancangan awal, bukan hasil render.** Penanda waktu nyata bergeser karena
> durasi tiap kalimat mengikuti hasil sintesis Piper, bukan perkiraan kata per menit. Urutan tujuh
> adegan tetap sama, tetapi batas waktunya berbeda: hasil akhirnya 0:00–0:24 · 0:24–1:01 · 1:01–1:22 ·
> 1:22–2:01 · 2:01–2:36 · 2:36–2:59 · 2:59–3:13 (total 3:13). Angka yang berlaku ada di
> `docs/NASKAH-VIDEO.md`; tabel ini dipertahankan sebagai jejak perencanaan.

| Waktu     | Adegan          | Visual                                                                                                       | Fungsi terhadap rubrik |
| --------- | --------------- | ------------------------------------------------------------------------------------------------------------ | ---------------------- |
| 0:00–0:12 | Pembuka         | Teks besar "Bolak-balik ke kelurahan?" di atas rekaman Beranda yang di-blur                                  | pemikat perhatian      |
| 0:12–0:40 | Masalah         | Tiga kartu layanan + tiga kartu keluhan (syarat tersebar, tidak tahu urutan, pertanyaan berulang)            | pertanyaan penguji 1   |
| 0:40–1:00 | Target pengguna | Dua kartu persona: warga 20–55 th; petugas kelurahan                                                         | pertanyaan penguji 2   |
| 1:00–1:20 | Prioritas fitur | Diagram alur tiga langkah: pilih layanan → jawab → hasil                                                     | pertanyaan penguji 3   |
| 1:20–2:10 | Demo (scope)    | Rekaman asli: Login → Pilih Layanan → Pertanyaan → Hasil + "Mengapa?" → Kelola Panduan → Sampaikan Kebutuhan | demo prototype         |
| 2:10–2:30 | Batas & data    | Dua kolom: "Yang dilakukan" vs "Yang tidak dilakukan"; sketsa koleksi Firestore                              | pertanyaan penguji 4   |
| 2:30–2:45 | Penutup         | Tech stack, tautan repo + Figma, identitas                                                                   | repository             |

---

## 7. Naskah narasi (draf, ±410 kata ≈ 2 menit 45 detik)

> **Ini draf perencanaan.** Naskah yang benar-benar dibacakan ada di `docs/NASKAH-VIDEO.md` (28 kalimat,
> 3:13). Perbedaan utamanya: kalimat penutup adegan demo sudah diperbaiki — frasa "dan tahapan"
> dihapus karena pengubahan tahapan belum tersedia di H6.

Laju baca Indonesia ±150 kata/menit. Angka di bawah adalah target durasi per adegan, bukan hasil  
render.

**A1 — Pembuka (12 dtk, 30 kata)**

> Bu Sri datang ke Kelurahan Tegalsari untuk mengurus KTP. Ia pulang karena fotokopi Kartu Keluarga  
> tertinggal. Besoknya ia kembali, dan masih ada satu berkas yang kurang.

**A2 — Masalah (28 dtk, 70 kata)**

> Kejadian ini berulang. Informasi persyaratan tersebar di banyak tempat: papan pengumuman, grup  
> WhatsApp, dan penuturan mulut ke mulut. Warga tidak tahu harus mulai dari mana, sehingga sering  
> datang dua sampai tiga kali. Di sisi lain, petugas menjawab pertanyaan yang sama setiap hari.  
> Pengetahuan itu sebenarnya ada, tetapi belum terkumpul dalam satu sistem yang bisa diakses kapan  
> saja.


**A3 — Pengguna (20 dtk, 50 kata)**
> Pengguna utama aplikasi ini ada dua. Pertama, warga Kelurahan Tegalsari usia dua puluh sampai lima
> puluh lima tahun, pengguna ponsel sehari-hari, yang membutuhkan kepastian syarat sebelum datang.
> Kedua, petugas kelurahan yang mengelola isi panduan agar informasinya tetap sesuai prosedur.

**A4 — Prioritas (20 dtk, 50 kata)**
> Fitur ini diprioritaskan karena menyelesaikan masalah di titik paling awal: sebelum warga
> berangkat. Alurnya tiga langkah. Pilih layanan, jawab pertanyaan singkat, lalu terima hasil: daftar
> persyaratan, tahapan, dan alasan keputusan tersebut.

**A5 — Demo (50 dtk, 125 kata)**
> Aplikasi dibangun dengan Flutter dan berjalan di ponsel maupun peramban. Setelah
> masuk, warga memilih satu dari tiga layanan: KTP, Kartu Keluarga, atau Surat Keterangan Domisili.
> Sistem lalu menanyakan satu pertanyaan per layar, misalnya apakah KTP sebelumnya diterbitkan di
> Semarang. Jawaban itu diproses oleh mesin aturan, bukan deretan if yang ditulis tangan. Hasilnya
> menampilkan status dapat atau belum dapat diproses, daftar persyaratan yang relevan, dan tahapan
> yang harus dilalui. Setiap keputusan bisa dipertanggungjawabkan lewat tombol Mengapa, yang
> menampilkan aturan mana yang menentukan. Petugas juga punya halaman Kelola Panduan untuk mengubah
> aturan, pertanyaan, dan persyaratan tanpa menyentuh kode. Ada pula form Sampaikan Kebutuhan bagi
> warga yang pertanyaannya belum terjawab.

**A6 — Batas & data (20 dtk, 50 kata)**
> Ada batas yang jelas. Aplikasi ini media panduan, bukan penerbit dokumen resmi, dan tidak terhubung
> ke data kependudukan. Data yang disimpan hanya isi panduan dan akun pengguna. Pada prototipe ini
> penyimpanan form masih di memori; rencana penyimpanan permanen memakai Cloud Firestore.

**A7 — Penutup (15 dtk, 35 kata)**
> Seluruh kode tersedia di repositori GitHub, lengkap dengan riwayat commit dan README. Saya Elisa
> Sandita Putri, dua tiga nol satu lima lima nol nol satu nol. Terima kasih.

**Catatan kejujuran akademik.** Draf A5 sempat menyebut "dibangun dengan Flutter dan Firebase".
Kalimat itu **dihapus** karena integrasi Firebase belum terpasang (Tahap 5b/6 masih menunggu proyek
Firebase); naskah final di `docs/NASKAH-VIDEO.md` hanya menyebut Flutter. A6 tetap menyebut bahwa
penyimpanan form masih di memori — jangan dihapus, justru itu yang membuat video tahan ditanya.

---

## 8. Tahap eksekusi (sudah dijalankan)

| Tahap | Isi | Hasil nyata (28 Oktober 2026) |
|---|---|---|
| **V1** | Scaffold proyek Remotion di `C:\dev\ips-video`, cek lisensi & versi Node | Proyek berdiri: Remotion 4.0.539, React 19.3.1, Node 22.22.2 |
| **V2** | Uji A/B TTS: unduh model Piper `id_ID`, bacakan 3 kalimat uji, bandingkan dengan edge-tts | Piper biner resmi + model `id_ID-news_tts-medium` (satu-satunya suara Indonesia di Piper) |
| **V3** | Naskah final → `docs/NASKAH-VIDEO.md`; hitung durasi per adegan dari hasil TTS nyata | 28 kalimat; durasi dibaca dari header WAV, bukan perkiraan |
| **V4** | Rekaman layar 1080p dari `localhost:8080` (Game Bar/OBS) | 7 tangkapan **3840×2160** lewat Chrome headless, diskalakan ke 1080p saat komposisi — bukan Game Bar/OBS, karena keduanya butuh antarmuka GUI |
| **V5** | Tulis 7 scene + komponen subtitle; susun audio per adegan | 7 adegan; subtitle dibaca dari `src/timeline.json` |
| **V6** | Render final + QC (sinkron audio, keterbacaan teks di 1080p, tidak ada data pribadi) | `out/uts-ips-guide.mp4` 194,112 dtk; kandidat `out/uts-ips-guide-kandidat.mp4` 192,704 dtk setelah kalimat 1:47 diperbaiki |
| **V7** | Unggah (Drive/YouTube unlisted), tautkan di README | **Belum** — video belum diunggah, README belum memuat tautan video |

Catatan pelaksanaan: render di lingkungan asisten diblokir sandbox (`TimeoutError: Timed out after
25000 ms while trying to connect to the browser!`), sehingga render dijalankan di terminal pengguna.
Berkas lama `out/uts-ips-guide.mp4` tidak ditimpa; kandidat memakai nama berbeda.

Perintah yang dipakai:

```bash
# V1 — scaffold (interaktif: pilih template "Blank")
cd /c/dev
npx create-video@latest ips-video
cd ips-video && npm install
npx remotion studio            # pratinjau di browser

# V6 — render kandidat (nama berbeda agar berkas lama tidak tertimpa)
npx remotion render src/index.ts UTS-IpsGuide out/uts-ips-guide-kandidat.mp4 \
  --codec=h264 --timeout=180000
```

---

## 9. Risiko dan mitigasi

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Suara Piper Indonesia terasa kaku | narasi mengganggu | uji A/B di V2 sebelum menulis naskah final; edge-tts sebagai cadangan |
| Rekaman layar goyah / teks terlalu kecil | video terlihat tidak profesional | rekam 1080p dengan zoom peramban 125%, potong per 3–6 detik, perbesar area penting di Remotion |
| Audio tidak sinkron setelah menyunting naskah | harus render ulang dari nol | satu berkas audio per adegan, bukan satu berkas panjang |
| MP4 > 50 MB | GitHub menolak / repo bengkak | jangan commit MP4; unggah ke Drive/YouTube unlisted lalu tautkan |
| Render pertama mengunduh Chrome Headless Shell | gagal di koneksi lambat | unduh sekali di awal, render di akhir saja |
| Klaim berlebihan soal Firebase | rapuh saat ditanya penguji | A6 wajib menyebut penyimpanan masih di memori (§7) |

---

## 10. Batas yang dijaga, dan yang masih terbuka

Bagian ini dulu berjudul "Yang tidak dilakukan pada tahap ini" dan berisi daftar penundaan.
Daftar itu **sudah kedaluwarsa**; isinya diganti dengan keadaan per 28 Oktober 2026.

### 10.1 Yang dulu ditunda, sekarang sudah selesai

| Butir | Status | Bukti |
|---|---|---|
| Video kandidat | **Selesai** — dirender dan diverifikasi | `C:\dev\ips-video\out\uts-ips-guide-kandidat.mp4`, 192,704 dtk, 1920×1080, 5.781 frame; diperiksa dengan `scripts/periksa-video.cjs` (§8 V6) |
| `docs/UJI-FORM.md` | **Tersedia** | 11 kasus uji form H7: 10 beruji otomatis, 1 diuji manual di browser; tertaut dari README §Pengujian |
| Screenshot | **Tersedia, tujuh berkas** | `docs/screenshots/01-beranda.png` … `07-sampaikan-kebutuhan.png`, 3840×2160 (tangkapan HiDPI), tertaut dari tabel halaman di README |
| Artefak desain Minggu 2–4 | **Tersedia, tiga dokumen** | `docs/desain/minggu-02-persona-user-story.docx`, `minggu-03-user-flow-sitemap.docx`, `minggu-04-wireframe-figma.docx`; tertaut dari README §Artefak desain |

### 10.2 Yang tetap tidak dilakukan

- **`node_modules` dan MP4 tidak masuk repo Git.** Proyek Remotion tetap di `C:\dev\ips-video`;
  yang masuk repo hanya `docs/RENCANA-VIDEO.md` (berkas ini) dan `docs/NASKAH-VIDEO.md`.
  Folder `out/` tidak di-commit (§9).
- **Pembuatan video tidak mengubah kode aplikasi Flutter.** Fitur H7 ditambahkan lewat pekerjaan
  terpisah, bukan sebagai akibat dari produksi video.
- **Tidak ada layanan berbayar dan tidak ada API key.** Tidak ada billing account, sesuai batas
  mata kuliah (§3.2).
- **MP4 lama tidak ditimpa.** `out/uts-ips-guide.mp4` (194,112 dtk) tetap utuh; kandidat memakai
  nama berbeda, sehingga kedua berkas bisa dibandingkan.
- **Video belum diunggah.** Tahap V7 belum dikerjakan: belum ada tautan Drive/YouTube, dan README
  belum memuat tautan video. Ini satu-satunya butir yang masih terbuka di dokumen ini.
