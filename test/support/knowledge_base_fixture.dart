import 'package:ips_guide/domain/entities/answer_option.dart';
import 'package:ips_guide/domain/entities/guidance_question.dart';
import 'package:ips_guide/domain/entities/guidance_service.dart';
import 'package:ips_guide/domain/entities/knowledge_base.dart';
import 'package:ips_guide/domain/entities/outcome.dart';
import 'package:ips_guide/domain/entities/requirement.dart';
import 'package:ips_guide/domain/entities/rule.dart';
import 'package:ips_guide/domain/entities/rule_action.dart';
import 'package:ips_guide/domain/entities/rule_condition.dart';
import 'package:ips_guide/domain/entities/service_step.dart';

/// Basis pengetahuan uji — mereplikasi §11.1–§11.5 RANCANGAN-ARSITEKTUR.md.
///
/// Dipakai uji engine Tahap 1 dan skenario Tahap 2 (S01–S46).

// ---------------------------------------------------------------------------
// Katalog tahapan (§11.5)
// ---------------------------------------------------------------------------

const _stepLoket = ServiceStep(
  id: 'STEP_LOKET',
  judul: 'Datang ke loket pelayanan',
  keterangan: 'Kelurahan Tegalsari, ambil nomor antrean',
  urutan: 10,
);
const _stepSerahBerkas = ServiceStep(
  id: 'STEP_SERAH_BERKAS',
  judul: 'Serahkan berkas',
  keterangan: 'Petugas memeriksa kelengkapan awal',
  urutan: 20,
);
const _stepVerifikasi = ServiceStep(
  id: 'STEP_VERIFIKASI',
  judul: 'Verifikasi dan validasi',
  keterangan: 'Pencocokan dokumen dengan data pemohon',
  urutan: 30,
);
const _stepRekam = ServiceStep(
  id: 'STEP_REKAM',
  judul: 'Perekaman biometrik',
  keterangan: 'Dilakukan bila petugas menilai perlu (KTP)',
  urutan: 40,
);
const _stepDisdukcapil = ServiceStep(
  id: 'STEP_DISDUKCAPIL',
  judul: 'Diteruskan ke Disdukcapil',
  keterangan: 'Kota Semarang (KK)',
  urutan: 40,
);
const _stepTtdLurah = ServiceStep(
  id: 'STEP_TTD_LURAH',
  judul: 'Penandatanganan Lurah',
  keterangan: 'Surat domisili',
  urutan: 40,
);
const _stepAmbil = ServiceStep(
  id: 'STEP_AMBIL',
  judul: 'Pengambilan dokumen',
  keterangan: 'Sesuai estimasi hari kerja',
  urutan: 50,
);

const katalogSteps = <ServiceStep>[
  _stepLoket,
  _stepSerahBerkas,
  _stepVerifikasi,
  _stepRekam,
  _stepDisdukcapil,
  _stepTtdLurah,
  _stepAmbil,
];

// ---------------------------------------------------------------------------
// Katalog persyaratan (§11.2–§11.4)
// ---------------------------------------------------------------------------

const katalogRequirements = <Requirement>[
  Requirement(id: 'REQ_F101', nama: 'Formulir F-1.01', sourceRuleId: '*'),
  Requirement(
    id: 'REQ_PENGANTAR_RTRW',
    nama: 'Surat pengantar RT/RW',
    sourceRuleId: '*',
  ),
  Requirement(id: 'REQ_KK_ASLI', nama: 'Kartu Keluarga asli', sourceRuleId: '*'),
  Requirement(id: 'REQ_KK_LAMA', nama: 'Kartu Keluarga lama', sourceRuleId: '*'),
  Requirement(id: 'REQ_KK_BARU', nama: 'Kartu Keluarga baru', sourceRuleId: '*'),
  Requirement(
    id: 'REQ_KK_FOTO',
    nama: 'Fotokopi Kartu Keluarga',
    sourceRuleId: '*',
  ),
  Requirement(
    id: 'REQ_KK_ORTU',
    nama: 'Kartu Keluarga orang tua',
    sourceRuleId: '*',
  ),
  Requirement(id: 'REQ_KTP_ORTU', nama: 'KTP orang tua', sourceRuleId: '*'),
  Requirement(id: 'REQ_KK_ASAL', nama: 'Kartu Keluarga asal', sourceRuleId: '*'),
  Requirement(
    id: 'REQ_AKTA_KELAHIRAN',
    nama: 'Akta kelahiran',
    sourceRuleId: '*',
  ),
  Requirement(id: 'REQ_AKTA_NIKAH', nama: 'Buku/akta nikah', sourceRuleId: '*'),
  Requirement(
    id: 'REQ_AKTA_KEMATIAN',
    nama: 'Akta kematian',
    sourceRuleId: '*',
  ),
  Requirement(
    id: 'REQ_SURAT_KEHILANGAN',
    nama: 'Surat kehilangan dari Polsek',
    sourceRuleId: '*',
  ),
  Requirement(id: 'REQ_KTP_EL_LAMA', nama: 'KTP-el lama', sourceRuleId: '*'),
  Requirement(id: 'REQ_KTP_EL', nama: 'KTP-el', sourceRuleId: '*'),
  Requirement(id: 'REQ_KTP_ASAL', nama: 'KTP asal (luar kota)', sourceRuleId: '*'),
  Requirement(id: 'REQ_KTP_PEMOHON', nama: 'KTP pemohon', sourceRuleId: '*'),
  Requirement(id: 'REQ_KTP_PASANGAN', nama: 'KTP pasangan', sourceRuleId: '*'),
  Requirement(
    id: 'REQ_KTP_SUAMI_ISTRI',
    nama: 'KTP suami dan istri',
    sourceRuleId: '*',
  ),
  Requirement(id: 'REQ_KTP_PELAPOR', nama: 'KTP pelapor', sourceRuleId: '*'),
  Requirement(
    id: 'REQ_KTP_ANGGOTA',
    nama: 'KTP anggota keluarga',
    sourceRuleId: '*',
  ),
  Requirement(id: 'REQ_SKPWNI', nama: 'SKPWNI', sourceRuleId: '*'),
  Requirement(
    id: 'REQ_SKPWNI_SKPTB',
    nama: 'SKPWNI/SKPTB',
    sourceRuleId: '*',
  ),
  Requirement(
    id: 'REQ_DOK_PENDUKUNG',
    nama: 'Dokumen pendukung perubahan data',
    sourceRuleId: '*',
  ),
  Requirement(
    id: 'REQ_SURAT_PERNYATAAN',
    nama: 'Surat pernyataan bermaterai',
    sourceRuleId: '*',
  ),
  Requirement(id: 'REQ_BUKTI_TINGGAL', nama: 'Bukti tinggal', sourceRuleId: '*'),
  Requirement(
    id: 'REQ_FOTO_LOKASI_USAHA',
    nama: 'Foto lokasi usaha',
    sourceRuleId: '*',
  ),
  Requirement(
    id: 'REQ_SURAT_TETANGGA',
    nama: 'Surat pernyataan tidak keberatan tetangga',
    sourceRuleId: '*',
  ),
];

// ---------------------------------------------------------------------------
// Layanan (§7, §11.5)
// ---------------------------------------------------------------------------

GuidanceService _serviceKtp() => const GuidanceService(
      id: 'ktp',
      nama: 'Kartu Tanda Penduduk Elektronik',
      deskripsi: 'Pengurusan KTP-el: baru, penggantian, dan perubahan data.',
      ikon: 'badge',
      urutan: 1,
      estimasiHariMin: 3,
      estimasiHariMax: 7,
      stepsDasar: [
        'STEP_LOKET',
        'STEP_SERAH_BERKAS',
        'STEP_VERIFIKASI',
        'STEP_REKAM',
        'STEP_AMBIL',
      ],
    );

GuidanceService _serviceKk() => const GuidanceService(
      id: 'kk',
      nama: 'Kartu Keluarga',
      deskripsi: 'Pengurusan KK: baru, pindah datang, dan perubahan anggota.',
      ikon: 'family_restroom',
      urutan: 2,
      estimasiHariMin: 3,
      estimasiHariMax: 7,
      stepsDasar: [
        'STEP_LOKET',
        'STEP_SERAH_BERKAS',
        'STEP_VERIFIKASI',
        'STEP_DISDUKCAPIL',
        'STEP_AMBIL',
      ],
    );

GuidanceService _serviceDomisili() => const GuidanceService(
      id: 'domisili',
      nama: 'Surat Keterangan Domisili',
      deskripsi: 'Surat keterangan domisili untuk sekolah, kerja, bank, usaha.',
      ikon: 'home',
      urutan: 3,
      estimasiHariMin: 1,
      estimasiHariMax: 2,
      stepsDasar: [
        'STEP_LOKET',
        'STEP_SERAH_BERKAS',
        'STEP_VERIFIKASI',
        'STEP_TTD_LURAH',
        'STEP_AMBIL',
      ],
    );

// ---------------------------------------------------------------------------
// Pertanyaan (§11.1)
// ---------------------------------------------------------------------------

GuidanceQuestion _q(
  String id,
  String serviceId,
  String factKey,
  String teks,
  int urutan,
  List<AnswerOption> opsi, [
  RuleCondition? showIf,
]) =>
    GuidanceQuestion(
      id: id,
      serviceId: serviceId,
      factKey: factKey,
      teks: teks,
      urutan: urutan,
      opsi: opsi,
      showIf: showIf,
    );

const _opsiYaTidak = <AnswerOption>[
  AnswerOption(value: 'ya', label: 'Ya'),
  AnswerOption(value: 'tidak', label: 'Tidak'),
];

const _opsiDomisili = <AnswerOption>[
  AnswerOption(value: 'tegalsari', label: 'Kelurahan Tegalsari'),
  AnswerOption(value: 'luar_tegalsari', label: 'Di luar Kelurahan Tegalsari'),
];

final List<GuidanceQuestion> pertanyaanKtp = [
  _q('KTP-Q01', 'ktp', 'kategori_usia', 'Berapa usia Anda saat ini?', 10, const [
    AnswerOption(value: 'di_bawah_17', label: 'Di bawah 17 tahun'),
    AnswerOption(value: '17_ke_atas', label: '17 tahun ke atas'),
  ]),
  _q(
    'KTP-Q02',
    'ktp',
    'status_perkawinan',
    'Apa status perkawinan Anda?',
    20,
    const [
      AnswerOption(value: 'belum_menikah', label: 'Belum pernah menikah'),
      AnswerOption(value: 'menikah', label: 'Sedang menikah'),
      AnswerOption(value: 'pernah_menikah', label: 'Pernah menikah'),
    ],
    const RuleCondition(
      fact: 'kategori_usia',
      op: ConditionOperator.equals,
      value: 'di_bawah_17',
    ),
  ),
  _q(
    'KTP-Q03',
    'ktp',
    'sudah_punya_ktp',
    'Apakah Anda sudah memiliki KTP?',
    30,
    _opsiYaTidak,
    const RuleCondition(
      fact: 'kategori_usia',
      op: ConditionOperator.equals,
      value: '17_ke_atas',
    ),
  ),
  _q(
    'KTP-Q04',
    'ktp',
    'domisili_pemohon',
    'Di mana domisili Anda?',
    40,
    _opsiDomisili,
  ),
  _q(
    'KTP-Q05',
    'ktp',
    'alasan_pengajuan_ktp',
    'Apa alasan pengajuan KTP?',
    50,
    const [
      AnswerOption(value: 'hilang', label: 'Hilang'),
      AnswerOption(value: 'rusak', label: 'Rusak'),
      AnswerOption(value: 'pindah_datang', label: 'Pindah datang'),
      AnswerOption(value: 'perubahan_data', label: 'Perubahan data'),
    ],
    const RuleCondition(
      fact: 'sudah_punya_ktp',
      op: ConditionOperator.equals,
      value: 'ya',
    ),
  ),
];

final List<GuidanceQuestion> pertanyaanKk = [
  _q('KK-Q01', 'kk', 'kondisi_kk', 'Bagaimana kondisi KK Anda?', 10, const [
    AnswerOption(value: 'belum_punya', label: 'Belum pernah punya'),
    AnswerOption(value: 'pindah_datang', label: 'Pindah datang ke Tegalsari'),
    AnswerOption(value: 'perubahan_anggota', label: 'Perubahan anggota keluarga'),
    AnswerOption(value: 'hilang', label: 'Hilang'),
    AnswerOption(value: 'rusak', label: 'Rusak'),
  ]),
  _q(
    'KK-Q02',
    'kk',
    'jenis_perubahan_kk',
    'Perubahan apa yang terjadi?',
    20,
    const [
      AnswerOption(value: 'kelahiran', label: 'Kelahiran'),
      AnswerOption(value: 'kematian', label: 'Kematian'),
      AnswerOption(value: 'perkawinan', label: 'Perkawinan'),
      AnswerOption(value: 'perpindahan', label: 'Perpindahan'),
    ],
    const RuleCondition(
      fact: 'kondisi_kk',
      op: ConditionOperator.equals,
      value: 'perubahan_anggota',
    ),
  ),
  _q(
    'KK-Q03',
    'kk',
    'domisili_pemohon',
    'Di mana domisili Anda?',
    30,
    _opsiDomisili,
  ),
];

final List<GuidanceQuestion> pertanyaanDomisili = [
  _q(
    'DOM-Q01',
    'domisili',
    'keperluan_domisili',
    'Untuk keperluan apa surat domisili ini?',
    10,
    const [
      AnswerOption(value: 'sekolah', label: 'Sekolah'),
      AnswerOption(value: 'kerja', label: 'Pekerjaan'),
      AnswerOption(value: 'bank', label: 'Perbankan'),
      AnswerOption(value: 'usaha', label: 'Usaha'),
      AnswerOption(value: 'lainnya', label: 'Lainnya'),
    ],
  ),
  _q(
    'DOM-Q02',
    'domisili',
    'status_tinggal',
    'Bagaimana status tinggal Anda di Tegalsari?',
    20,
    const [
      AnswerOption(value: 'warga_tetap', label: 'Warga tetap'),
      AnswerOption(value: 'tinggal_sementara', label: 'Tinggal sementara'),
    ],
  ),
  _q(
    'DOM-Q03',
    'domisili',
    'punya_bukti_tinggal',
    'Apakah Anda memiliki bukti tinggal?',
    30,
    _opsiYaTidak,
    const RuleCondition(
      fact: 'status_tinggal',
      op: ConditionOperator.equals,
      value: 'tinggal_sementara',
    ),
  ),
];

// ---------------------------------------------------------------------------
// Aturan (§11.2–§11.4)
// ---------------------------------------------------------------------------

RuleCondition _eq(String fact, String value) => RuleCondition(
      fact: fact,
      op: ConditionOperator.equals,
      value: value,
    );

final List<Rule> aturanKtp = [
  Rule(
    id: 'KTP-R01',
    serviceId: 'ktp',
    priority: 95,
    deskripsi: 'Di bawah 17 tahun dan belum pernah menikah',
    when: [_eq('kategori_usia', 'di_bawah_17'), _eq('status_perkawinan', 'belum_menikah')],
    then: const RuleAction(
      setOutcome: Outcome.tidakDapatDiproses,
      terminal: true,
      addNotes: [
        'Anak di bawah 17 tahun yang belum pernah menikah belum wajib '
            'memiliki KTP-el. Identitas dapat menggunakan KIA.',
      ],
    ),
  ),
  Rule(
    id: 'KTP-R02',
    serviceId: 'ktp',
    priority: 90,
    deskripsi: 'Di bawah 17 tahun tetapi sudah/pernah menikah',
    when: [_eq('kategori_usia', 'di_bawah_17'), _eq('status_perkawinan', 'menikah')],
    then: const RuleAction(
      setOutcome: Outcome.denganCatatan,
      addRequirements: [
        'REQ_KK_ASLI',
        'REQ_AKTA_NIKAH',
        'REQ_AKTA_KELAHIRAN',
        'REQ_PENGANTAR_RTRW',
        'REQ_F101',
      ],
      addNotes: ['Pengajuan didampingi orang tua/wali.'],
    ),
  ),
  Rule(
    id: 'KTP-R03',
    serviceId: 'ktp',
    priority: 70,
    deskripsi: '17 tahun ke atas, belum pernah punya KTP',
    when: [_eq('kategori_usia', '17_ke_atas'), _eq('sudah_punya_ktp', 'tidak')],
    then: const RuleAction(
      setOutcome: Outcome.dapatDiproses,
      addFacts: {'jenis_pengajuan_ktp': 'baru'},
      addRequirements: [
        'REQ_KK_ASLI',
        'REQ_AKTA_KELAHIRAN',
        'REQ_PENGANTAR_RTRW',
        'REQ_F101',
      ],
    ),
  ),
  Rule(
    id: 'KTP-R04',
    serviceId: 'ktp',
    priority: 75,
    deskripsi: 'Penggantian karena hilang',
    when: [_eq('sudah_punya_ktp', 'ya'), _eq('alasan_pengajuan_ktp', 'hilang')],
    then: const RuleAction(
      setOutcome: Outcome.dapatDiproses,
      addFacts: {'jenis_pengajuan_ktp': 'penggantian_hilang'},
      addRequirements: ['REQ_SURAT_KEHILANGAN', 'REQ_KK_FOTO', 'REQ_F101'],
    ),
  ),
  Rule(
    id: 'KTP-R05',
    serviceId: 'ktp',
    priority: 75,
    deskripsi: 'Penggantian karena rusak',
    when: [_eq('sudah_punya_ktp', 'ya'), _eq('alasan_pengajuan_ktp', 'rusak')],
    then: const RuleAction(
      setOutcome: Outcome.dapatDiproses,
      addFacts: {'jenis_pengajuan_ktp': 'penggantian_rusak'},
      addRequirements: ['REQ_KTP_EL_LAMA', 'REQ_KK_FOTO', 'REQ_F101'],
    ),
  ),
  Rule(
    id: 'KTP-R06',
    serviceId: 'ktp',
    priority: 75,
    deskripsi: 'Pindah datang',
    when: [
      _eq('sudah_punya_ktp', 'ya'),
      _eq('alasan_pengajuan_ktp', 'pindah_datang'),
    ],
    then: const RuleAction(
      setOutcome: Outcome.dapatDiproses,
      addFacts: {'jenis_pengajuan_ktp': 'pindah_datang'},
      addRequirements: ['REQ_SKPWNI', 'REQ_KK_BARU', 'REQ_KTP_EL_LAMA', 'REQ_F101'],
    ),
  ),
  Rule(
    id: 'KTP-R07',
    serviceId: 'ktp',
    priority: 75,
    deskripsi: 'Perubahan data',
    when: [
      _eq('sudah_punya_ktp', 'ya'),
      _eq('alasan_pengajuan_ktp', 'perubahan_data'),
    ],
    then: const RuleAction(
      setOutcome: Outcome.dapatDiproses,
      addFacts: {'jenis_pengajuan_ktp': 'perubahan_data'},
      addRequirements: [
        'REQ_KTP_EL_LAMA',
        'REQ_KK_FOTO',
        'REQ_DOK_PENDUKUNG',
        'REQ_F101',
      ],
    ),
  ),
  Rule(
    id: 'KTP-R08',
    serviceId: 'ktp',
    priority: 99,
    deskripsi: 'Domisili di luar Kelurahan Tegalsari',
    when: [_eq('domisili_pemohon', 'luar_tegalsari')],
    then: const RuleAction(
      setOutcome: Outcome.tidakDapatDiproses,
      terminal: true,
      addNotes: [
        'Pengurusan KTP dilakukan di kelurahan tempat domisili pemohon.',
      ],
    ),
  ),
  Rule(
    id: 'KTP-R10',
    serviceId: 'ktp',
    priority: 88,
    deskripsi: 'Di bawah 17 tahun, pernah menikah (belum tervalidasi — U-02)',
    when: [_eq('kategori_usia', 'di_bawah_17'), _eq('status_perkawinan', 'pernah_menikah')],
    then: const RuleAction(
      addNotes: [
        'Kasus Anda belum tercakup dalam panduan ini. Silakan konfirmasi '
            'langsung ke loket pelayanan Kelurahan Tegalsari.',
      ],
    ),
  ),
];

final List<Rule> aturanKk = [
  Rule(
    id: 'KK-R01',
    serviceId: 'kk',
    priority: 80,
    deskripsi: 'Belum pernah punya KK',
    when: [_eq('kondisi_kk', 'belum_punya')],
    then: const RuleAction(
      setOutcome: Outcome.dapatDiproses,
      addRequirements: [
        'REQ_AKTA_NIKAH',
        'REQ_KK_ORTU',
        'REQ_KTP_SUAMI_ISTRI',
        'REQ_PENGANTAR_RTRW',
        'REQ_F101',
      ],
    ),
  ),
  Rule(
    id: 'KK-R02',
    serviceId: 'kk',
    priority: 80,
    deskripsi: 'Pindah datang',
    when: [_eq('kondisi_kk', 'pindah_datang')],
    then: const RuleAction(
      setOutcome: Outcome.dapatDiproses,
      addRequirements: [
        'REQ_SKPWNI',
        'REQ_KK_ASAL',
        'REQ_KTP_PEMOHON',
        'REQ_PENGANTAR_RTRW',
        'REQ_F101',
      ],
    ),
  ),
  Rule(
    id: 'KK-R03',
    serviceId: 'kk',
    priority: 85,
    deskripsi: 'Perubahan anggota: kelahiran',
    when: [_eq('jenis_perubahan_kk', 'kelahiran')],
    then: const RuleAction(
      setOutcome: Outcome.dapatDiproses,
      addRequirements: [
        'REQ_AKTA_KELAHIRAN',
        'REQ_KK_LAMA',
        'REQ_KTP_ORTU',
        'REQ_F101',
      ],
    ),
  ),
  Rule(
    id: 'KK-R04',
    serviceId: 'kk',
    priority: 85,
    deskripsi: 'Perubahan anggota: kematian',
    when: [_eq('jenis_perubahan_kk', 'kematian')],
    then: const RuleAction(
      setOutcome: Outcome.dapatDiproses,
      addRequirements: [
        'REQ_AKTA_KEMATIAN',
        'REQ_KK_LAMA',
        'REQ_KTP_PELAPOR',
        'REQ_F101',
      ],
    ),
  ),
  Rule(
    id: 'KK-R05',
    serviceId: 'kk',
    priority: 85,
    deskripsi: 'Perubahan anggota: perkawinan',
    when: [_eq('jenis_perubahan_kk', 'perkawinan')],
    then: const RuleAction(
      setOutcome: Outcome.dapatDiproses,
      addRequirements: ['REQ_AKTA_NIKAH', 'REQ_KK_LAMA', 'REQ_KTP_PASANGAN', 'REQ_F101'],
    ),
  ),
  Rule(
    id: 'KK-R06',
    serviceId: 'kk',
    priority: 85,
    deskripsi: 'Perubahan anggota: perpindahan',
    when: [_eq('jenis_perubahan_kk', 'perpindahan')],
    then: const RuleAction(
      setOutcome: Outcome.dapatDiproses,
      addRequirements: ['REQ_SKPWNI_SKPTB', 'REQ_KK_LAMA', 'REQ_KTP_ANGGOTA', 'REQ_F101'],
    ),
  ),
  Rule(
    id: 'KK-R07',
    serviceId: 'kk',
    priority: 75,
    deskripsi: 'KK hilang',
    when: [_eq('kondisi_kk', 'hilang')],
    then: const RuleAction(
      setOutcome: Outcome.dapatDiproses,
      addRequirements: ['REQ_SURAT_KEHILANGAN', 'REQ_KK_FOTO', 'REQ_KTP_PEMOHON', 'REQ_F101'],
    ),
  ),
  Rule(
    id: 'KK-R08',
    serviceId: 'kk',
    priority: 75,
    deskripsi: 'KK rusak',
    when: [_eq('kondisi_kk', 'rusak')],
    then: const RuleAction(
      setOutcome: Outcome.dapatDiproses,
      addRequirements: ['REQ_KK_LAMA', 'REQ_KTP_PEMOHON', 'REQ_F101'],
    ),
  ),
  Rule(
    id: 'KK-R10',
    serviceId: 'kk',
    priority: 99,
    deskripsi: 'Domisili luar Tegalsari dan bukan pindah datang',
    when: [
      _eq('domisili_pemohon', 'luar_tegalsari'),
      RuleCondition(
        fact: 'kondisi_kk',
        op: ConditionOperator.notEquals,
        value: 'pindah_datang',
      ),
    ],
    then: const RuleAction(
      setOutcome: Outcome.tidakDapatDiproses,
      terminal: true,
      addNotes: ['Perubahan KK dilakukan di kelurahan domisili pemohon.'],
    ),
  ),
];

final List<Rule> aturanDomisili = [
  Rule(
    id: 'DOM-R01',
    serviceId: 'domisili',
    priority: 80,
    deskripsi: 'Warga tetap',
    when: [_eq('status_tinggal', 'warga_tetap')],
    then: const RuleAction(
      setOutcome: Outcome.dapatDiproses,
      addRequirements: ['REQ_KTP_EL', 'REQ_KK_LAMA', 'REQ_PENGANTAR_RTRW', 'REQ_F101'],
    ),
  ),
  Rule(
    id: 'DOM-R02',
    serviceId: 'domisili',
    priority: 80,
    deskripsi: 'Tinggal sementara',
    when: [_eq('status_tinggal', 'tinggal_sementara')],
    then: const RuleAction(
      setOutcome: Outcome.dapatDiproses,
      addRequirements: [
        'REQ_KTP_ASAL',
        'REQ_KK_LAMA',
        'REQ_SURAT_PERNYATAAN',
        'REQ_BUKTI_TINGGAL',
        'REQ_PENGANTAR_RTRW',
        'REQ_F101',
      ],
    ),
  ),
  Rule(
    id: 'DOM-R03',
    serviceId: 'domisili',
    priority: 85,
    deskripsi: 'Tinggal sementara tanpa bukti tinggal',
    when: [
      _eq('status_tinggal', 'tinggal_sementara'),
      _eq('punya_bukti_tinggal', 'tidak'),
    ],
    then: const RuleAction(
      setOutcome: Outcome.denganCatatan,
      addNotes: [
        'Bukti tinggal wajib dilengkapi (mis. surat keterangan pemilik rumah).',
      ],
    ),
  ),
  Rule(
    id: 'DOM-R04',
    serviceId: 'domisili',
    priority: 85,
    deskripsi: 'Keperluan usaha',
    when: [_eq('keperluan_domisili', 'usaha')],
    then: const RuleAction(
      addRequirements: ['REQ_FOTO_LOKASI_USAHA', 'REQ_SURAT_TETANGGA'],
    ),
  ),
  Rule(
    id: 'DOM-R05',
    serviceId: 'domisili',
    priority: 70,
    deskripsi: 'Keperluan sekolah',
    when: [_eq('keperluan_domisili', 'sekolah')],
    then: const RuleAction(
      addNotes: ['Sertakan keterangan tujuan sekolah.'],
    ),
  ),
];

// ---------------------------------------------------------------------------
// KnowledgeBase
// ---------------------------------------------------------------------------

KnowledgeBase kbKtp() => KnowledgeBase(
      service: _serviceKtp(),
      questions: pertanyaanKtp,
      rules: aturanKtp,
      requirements: katalogRequirements,
      steps: katalogSteps,
    );

KnowledgeBase kbKk() => KnowledgeBase(
      service: _serviceKk(),
      questions: pertanyaanKk,
      rules: aturanKk,
      requirements: katalogRequirements,
      steps: katalogSteps,
    );

KnowledgeBase kbDomisili() => KnowledgeBase(
      service: _serviceDomisili(),
      questions: pertanyaanDomisili,
      rules: aturanDomisili,
      requirements: katalogRequirements,
      steps: katalogSteps,
    );
