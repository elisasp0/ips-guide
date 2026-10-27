import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/layout/responsive.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/knowledge_base_repository.dart';
import '../../../domain/entities/answer_option.dart';
import '../../../domain/entities/guidance_question.dart';
import '../../../domain/entities/knowledge_base.dart';
import '../../../domain/entities/outcome.dart';
import '../../../domain/entities/requirement.dart';
import '../../../domain/entities/rule.dart';
import '../../../domain/entities/rule_action.dart';
import '../../../domain/entities/rule_condition.dart';
import '../application/admin_providers.dart';

/// H6 Kelola Panduan — satu layanan (§5, §12.3 tahap A–D).
///
/// Tahap A: menampilkan aturan, pertanyaan, persyaratan, dan tahapan —
/// termasuk dokumen NON-AKTIF dengan label "Nonaktif" (§12.4).
/// Tahap B: mengubah prioritas aturan, teks pertanyaan, nama/keterangan
/// persyaratan, serta mengaktifkan/menonaktifkan dokumen.
/// Tahap C: menambah aturan dan pertanyaan lewat form — membuktikan basis
/// pengetahuan dapat diperluas tanpa mengubah kode.
/// Tahap D: menonaktifkan dokumen SELALU lewat konfirmasi; penghapusan
/// fisik tidak dipakai agar tidak ada rujukan terputus (§12.3 D).
///
/// Setiap penyimpanan melewati validator yang sama dengan jalur muat
/// (§12.5, V-02). Penolakan menampilkan kode pelanggaran + saran perbaikan.
class KelolaLayananPage extends ConsumerStatefulWidget {
  final String serviceId;

  const KelolaLayananPage({super.key, required this.serviceId});

  @override
  ConsumerState<KelolaLayananPage> createState() => _KelolaLayananPageState();
}

class _KelolaLayananPageState extends ConsumerState<KelolaLayananPage> {
  Future<KnowledgeBaseRepository> get _repo =>
      ref.read(repositoryProvider.future);

  // ---------------------------------------------------------------- simpan

  Future<void> _simpan(Future<void> Function() aksi) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await aksi();
      ref.invalidate(adminKbProvider(widget.serviceId));
      ref.invalidate(adminRingkasanProvider);
      messenger.showSnackBar(
        const SnackBar(content: Text('Tersimpan')),
      );
    } on KnowledgeBaseException catch (e) {
      if (!mounted) return;
      await _tampilkanPenolakan(e);
    }
  }

  Future<void> _tampilkanPenolakan(KnowledgeBaseException e) {
    final theme = Theme.of(context);
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.block, color: AppColors.danger),
            SizedBox(width: 8),
            Expanded(child: Text('Penyimpanan ditolak')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(e.message, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 12),
              for (final galat in e.errors) ...[
                Text('• $galat', style: theme.textTheme.bodySmall),
                if (_saran(galat) != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 8),
                    child: Text(
                      'Saran: ${_saran(galat)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  /// Saran perbaikan untuk pelanggaran invarian terminal (§12.5).
  String? _saran(String galat) {
    if (galat.startsWith('V-1')) {
      return 'Aturan terminal wajib menetapkan outcome, atau ubah menjadi '
          'non-terminal.';
    }
    if (galat.startsWith('V-2')) {
      return 'Dua aturan terminal dengan outcome berbeda hanya boleh bila '
          'terbukti saling lepas (fakta sama, himpunan nilai tak beririsan).';
    }
    if (galat.startsWith('V-3')) {
      return 'Naikkan prioritas aturan terminal sehingga lebih tinggi dari '
          'SEMUA aturan non-terminal pada layanan ini.';
    }
    if (galat.contains('duplikat') || galat.contains('sudah')) {
      return 'Pakai ID/factKey lain yang belum dipakai pada layanan ini.';
    }
    if (galat.contains('tak dikenal') || galat.contains('tidak dikenal')) {
      return 'Pastikan rujukan menunjuk ID yang ada di katalog layanan ini.';
    }
    return null;
  }

  // ----------------------------------------------------------------- dialog

  /// Menampilkan formulir dialog; mengembalikan nilai tiap kolom (urut) atau
  /// null bila dibatalkan.
  ///
  /// Kendali teks dimiliki oleh [DialogForm] sehingga dibuang saat rutenya
  /// dilepas — bukan di sini, karena dialog masih beranimasi keluar ketika
  /// showDialog selesai.
  Future<List<String>?> _tanya({
    required String judul,
    required List<KolomForm> kolom,
  }) =>
      showDialog<List<String>>(
        context: context,
        builder: (_) => DialogForm(judul: judul, kolom: kolom),
      );

  /// Konfirmasi nonaktifkan (§12.3 tahap D).
  ///
  /// Penonaktifan tidak dapat dibatalkan lewat tombol "Urungkan", dan bila
  /// yang dinonaktifkan adalah satu-satunya aturan penentu keputusan, seluruh
  /// warga akan melihat "Panduan belum tersedia" — karena itu wajib
  /// dikonfirmasi, sedangkan pengaktifan kembali tidak.
  Future<bool> _konfirmasiNonaktif({
    required String judul,
    required String pesan,
  }) async {
    final ya = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(judul),
        content: Text(pesan),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            key: const Key('admin-konfirmasi-nonaktif'),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Nonaktifkan'),
          ),
        ],
      ),
    );
    return ya ?? false;
  }

  // ------------------------------------------------------------------ aksi

  Future<void> _ubahPrioritas(Rule r) async {
    final nilai = await _tanya(
      judul: 'Prioritas ${r.id}',
      kolom: [
        KolomForm(
          kunci: 'angka',
          label: 'Prioritas',
          awal: '${r.priority}',
          angka: true,
        ),
      ],
    );
    if (nilai == null) return;
    final baru = int.parse(nilai.first);
    await _simpan(() async {
      final repo = await _repo;
      await repo.simpanAturan(widget.serviceId, r.copyWith(priority: baru));
    });
  }

  Future<void> _ubahAktifAturan(Rule r, bool aktif) async {
    if (!aktif) {
      final lanjut = await _konfirmasiNonaktif(
        judul: 'Nonaktifkan ${r.id}?',
        pesan: 'Aturan ini tidak lagi dievaluasi mesin. Bila ia satu-satunya '
            'aturan yang menetapkan keputusan, hasil panduan menjadi '
            '"Panduan belum tersedia". Dokumen tetap tampil di sini dan dapat '
            'diaktifkan kembali.',
      );
      if (!lanjut) return;
    }
    await _simpan(() async {
      final repo = await _repo;
      await repo.simpanAturan(widget.serviceId, r.copyWith(aktif: aktif));
    });
  }

  Future<void> _ubahTeksPertanyaan(GuidanceQuestion q) async {
    final nilai = await _tanya(
      judul: 'Ubah teks ${q.id}',
      kolom: [
        KolomForm(
          kunci: 'teks',
          label: 'Teks pertanyaan',
          awal: q.teks,
          maxLines: 2,
        ),
      ],
    );
    if (nilai == null) return;
    final baru = nilai.first;
    await _simpan(() async {
      final repo = await _repo;
      await repo.simpanPertanyaan(
        widget.serviceId,
        q.copyWith(teks: baru),
      );
    });
  }

  Future<void> _ubahAktifPertanyaan(GuidanceQuestion q, bool aktif) async {
    if (!aktif) {
      final lanjut = await _konfirmasiNonaktif(
        judul: 'Nonaktifkan ${q.id}?',
        pesan: 'Pertanyaan ini tidak lagi ditanyakan, sehingga fakta '
            '"${q.factKey}" tidak pernah terisi dan aturan yang bergantung '
            'padanya tidak akan menyala. Dokumen tetap tampil di sini dan '
            'dapat diaktifkan kembali.',
      );
      if (!lanjut) return;
    }
    await _simpan(() async {
      final repo = await _repo;
      await repo.simpanPertanyaan(
        widget.serviceId,
        q.copyWith(aktif: aktif),
      );
    });
  }

  Future<void> _ubahPersyaratan(Requirement r) async {
    final nilai = await _tanya(
      judul: 'Ubah ${r.id}',
      kolom: [
        KolomForm(kunci: 'nama', label: 'Nama', awal: r.nama),
        KolomForm(
          kunci: 'keterangan',
          label: 'Keterangan',
          awal: r.keterangan ?? '',
          wajib: false,
          maxLines: 2,
        ),
      ],
    );
    if (nilai == null) return;
    final baru = r.copyWith(
      nama: nilai[0],
      keterangan: nilai[1].isEmpty ? null : nilai[1],
    );
    await _simpan(() async {
      final repo = await _repo;
      await repo.simpanPersyaratan(baru);
    });
  }

  /// Tahap C — tambah aturan. Kondisi dibuat sebagai SATU klausa `equals`
  /// pada fakta yang dipilih dari daftar (bukan diketik bebas), sehingga
  /// salah ketik `factKey` tidak mungkin terjadi. Kondisi majemuk atau
  /// operator lain masih ditulis lewat seed/Firestore.
  Future<void> _tambahAturan(KnowledgeBase kb) async {
    final factKeys = kb.questions.map((q) => q.factKey).toSet().toList()
      ..sort();
    if (factKeys.isEmpty) {
      await _pesan('Belum ada pertanyaan pada layanan ini. Tambah pertanyaan '
          'lebih dulu agar aturan punya fakta yang dapat dirujuk.');
      return;
    }
    final nilai = await _tanya(
      judul: 'Aturan baru · ${kb.serviceId.toUpperCase()}',
      kolom: [
        KolomForm(
          kunci: 'id',
          label: 'ID aturan',
          cek: (t) => RegExp(r'^[A-Z]+-R\d+$').hasMatch(t)
              ? null
              : 'Format <LAYANAN>-R<nn>, mis. '
                  '${kb.serviceId.toUpperCase()}-R99.',
        ),
        KolomForm(kunci: 'prioritas', label: 'Prioritas', angka: true),
        KolomForm(kunci: 'deskripsi', label: 'Deskripsi', maxLines: 2),
        KolomForm(kunci: 'fakta', label: 'Fakta (kondisi)', pilihan: factKeys),
        KolomForm(kunci: 'nilai', label: 'Nilai fakta'),
        KolomForm(
          kunci: 'terminal',
          label: 'Terminal (hentikan sesi)',
          saklar: true,
          awal: 'false',
        ),
        KolomForm(
          kunci: 'outcome',
          label: 'Outcome',
          pilihan: [
            kTanpaOutcome,
            for (final o in Outcome.values) o.wireName,
          ],
          awal: kTanpaOutcome,
        ),
      ],
    );
    if (nilai == null) return;

    final aturan = Rule(
      id: nilai[0],
      serviceId: widget.serviceId,
      priority: int.parse(nilai[1]),
      deskripsi: nilai[2],
      when: [RuleCondition(fact: nilai[3], value: nilai[4])],
      then: RuleAction(
        terminal: nilai[5] == 'true',
        setOutcome: Outcome.fromWireName(nilai[6]),
      ),
    );
    await _simpan(() async {
      final repo = await _repo;
      await repo.tambahAturan(widget.serviceId, aturan);
    });
  }

  /// Tahap C — tambah pertanyaan. Opsi ditulis satu per baris dengan format
  /// `nilai|label` karena satu pertanyaan dapat memiliki dua atau tiga opsi.
  Future<void> _tambahPertanyaan(KnowledgeBase kb) async {
    final urutanSaran = kb.questions.isEmpty
        ? 10
        : kb.questions
                .map((q) => q.urutan)
                .reduce((a, b) => a > b ? a : b) +
            10;
    final nilai = await _tanya(
      judul: 'Pertanyaan baru · ${kb.serviceId.toUpperCase()}',
      kolom: [
        KolomForm(
          kunci: 'id',
          label: 'ID pertanyaan',
          cek: (t) => RegExp(r'^[A-Z]+-Q\d+$').hasMatch(t)
              ? null
              : 'Format <LAYANAN>-Q<nn>, mis. '
                  '${kb.serviceId.toUpperCase()}-Q99.',
        ),
        KolomForm(kunci: 'factKey', label: 'factKey'),
        KolomForm(kunci: 'teks', label: 'Teks pertanyaan', maxLines: 2),
        KolomForm(
          kunci: 'urutan',
          label: 'Urutan',
          awal: '$urutanSaran',
          angka: true,
        ),
        KolomForm(
          kunci: 'opsi',
          label: 'Opsi — satu per baris, format nilai|label',
          awal: 'ya|Ya\ntidak|Tidak',
          maxLines: 4,
          cek: _cekOpsi,
        ),
      ],
    );
    if (nilai == null) return;

    final pertanyaan = GuidanceQuestion(
      id: nilai[0],
      serviceId: widget.serviceId,
      factKey: nilai[1],
      teks: nilai[2],
      urutan: int.parse(nilai[3]),
      opsi: _uraiOpsi(nilai[4]),
    );
    await _simpan(() async {
      final repo = await _repo;
      await repo.tambahPertanyaan(widget.serviceId, pertanyaan);
    });
  }

  Future<void> _pesan(String teks) => showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(teks),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );

  /// Memeriksa format kolom opsi SEBELUM dialog ditutup, agar pengguna tidak
  /// kehilangan isian yang sudah diketik.
  String? _cekOpsi(String teks) {
    final baris = teks
        .split('\n')
        .map((b) => b.trim())
        .where((b) => b.isNotEmpty)
        .toList();
    if (baris.length < 2) return 'Isi minimal dua opsi.';
    for (final b in baris) {
      final i = b.indexOf('|');
      if (i <= 0 || i == b.length - 1) return 'Format tiap baris: nilai|label';
    }
    return null;
  }

  List<AnswerOption> _uraiOpsi(String teks) => [
        for (final b in teks.split('\n'))
          if (b.trim().isNotEmpty)
            AnswerOption(
              value: b.substring(0, b.indexOf('|')).trim(),
              label: b.substring(b.indexOf('|') + 1).trim(),
            ),
      ];

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final kbAsync = ref.watch(adminKbProvider(widget.serviceId));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(kbAsync.asData?.value.service.nama ?? 'Kelola Panduan'),
        ),
        body: SafeArea(
          child: kbAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(kPagePadding),
                child: Text('Gagal memuat basis pengetahuan.\n$e'),
              ),
            ),
            data: (kb) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: kResultMaxWidth),
                child: Column(
                  children: [
                    const TabBar(
                      tabs: [
                        Tab(text: 'Aturan'),
                        Tab(text: 'Pertanyaan'),
                        Tab(text: 'Persyaratan'),
                        Tab(text: 'Tahapan'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _daftarAturan(kb),
                          _daftarPertanyaan(kb),
                          _daftarPersyaratan(kb),
                          _daftarTahapan(kb),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _daftarAturan(KnowledgeBase kb) {
    final theme = Theme.of(context);
    final aturan = [...kb.rules]..sort((a, b) {
        final p = b.priority.compareTo(a.priority);
        return p != 0 ? p : a.id.compareTo(b.id);
      });
    return ListView(
      padding: const EdgeInsets.all(kPagePadding),
      children: [
        Text(
          'Urutan: prioritas tertinggi lebih dulu. Aturan nonaktif tidak '
          'dievaluasi mesin, tetapi tetap tampil di sini.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            key: const Key('admin-tambah-aturan'),
            onPressed: () => _tambahAturan(kb),
            icon: const Icon(Icons.add),
            label: const Text('Tambah aturan'),
          ),
        ),
        const SizedBox(height: 12),
        for (final r in aturan)
          Card(
            child: ListTile(
              key: Key('admin-aturan-${r.id}'),
              onTap: () => _ubahPrioritas(r),
              title: Text('${r.id} · prioritas ${r.priority}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.deskripsi),
                  const SizedBox(height: 4),
                  Text(
                    [
                      r.then.terminal ? 'Terminal' : 'Non-terminal',
                      if (r.then.setOutcome != null)
                        r.then.setOutcome!.wireName,
                      if (!r.aktif) 'Nonaktif',
                    ].join(' · '),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: r.aktif ? null : AppColors.danger,
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    label: 'Aktifkan aturan ${r.id}',
                    child: Switch(
                      key: Key('admin-aktif-${r.id}'),
                      value: r.aktif,
                      onChanged: (v) => _ubahAktifAturan(r, v),
                    ),
                  ),
                  const Icon(Icons.edit_outlined, size: 18),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _daftarPertanyaan(KnowledgeBase kb) {
    final theme = Theme.of(context);
    final pertanyaan = [...kb.questions]
      ..sort((a, b) => a.urutan.compareTo(b.urutan));
    return ListView(
      padding: const EdgeInsets.all(kPagePadding),
      children: [
        Text(
          'Mengubah teks pertanyaan tidak mengubah aturan: aturan merujuk '
          'factKey, bukan teks.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.tonalIcon(
            key: const Key('admin-tambah-pertanyaan'),
            onPressed: () => _tambahPertanyaan(kb),
            icon: const Icon(Icons.add),
            label: const Text('Tambah pertanyaan'),
          ),
        ),
        const SizedBox(height: 12),
        for (final q in pertanyaan)
          Card(
            child: ListTile(
              key: Key('admin-pertanyaan-${q.id}'),
              onTap: () => _ubahTeksPertanyaan(q),
              title: Text(q.teks),
              subtitle: Text(
                '${q.id} · ${q.factKey} · urutan ${q.urutan}'
                '${q.aktif ? '' : ' · Nonaktif'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: q.aktif ? null : AppColors.danger,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    label: 'Aktifkan pertanyaan ${q.id}',
                    child: Switch(
                      key: Key('admin-aktif-${q.id}'),
                      value: q.aktif,
                      onChanged: (v) => _ubahAktifPertanyaan(q, v),
                    ),
                  ),
                  const Icon(Icons.edit_outlined, size: 18),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _daftarPersyaratan(KnowledgeBase kb) {
    final theme = Theme.of(context);
    final daftar = [...kb.requirements]..sort((a, b) => a.id.compareTo(b.id));
    return ListView(
      padding: const EdgeInsets.all(kPagePadding),
      children: [
        Text(
          'Katalog persyaratan dipakai bersama seluruh layanan. '
          'Dari aturan mana persyaratan berasal tetap tercatat '
          '(explanation facility).',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        for (final r in daftar)
          Card(
            child: ListTile(
              key: Key('admin-persyaratan-${r.id}'),
              onTap: () => _ubahPersyaratan(r),
              title: Text(r.nama),
              subtitle: Text(
                '${r.id}${r.keterangan == null ? '' : ' · ${r.keterangan}'}',
                style: theme.textTheme.bodySmall,
              ),
              trailing: const Icon(Icons.edit_outlined, size: 18),
            ),
          ),
      ],
    );
  }

  Widget _daftarTahapan(KnowledgeBase kb) {
    final theme = Theme.of(context);
    final dasar = kb.service.stepsDasar.toSet();
    final tahapan = [...kb.steps]..sort((a, b) => a.urutan.compareTo(b.urutan));
    return ListView(
      padding: const EdgeInsets.all(kPagePadding),
      children: [
        Text(
          'Tahapan umum layanan berasal dari services.stepsDasar (U-01); '
          'tanda ● berarti tahap itu termasuk alur dasar.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 12),
        for (final s in tahapan)
          Card(
            child: ListTile(
              leading: Text(
                dasar.contains(s.id) ? '●' : '○',
                style: theme.textTheme.titleMedium,
              ),
              title: Text(s.judul),
              subtitle: Text(
                '${s.id} · urutan ${s.urutan}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
      ],
    );
  }
}

/// Nilai dropdown "tidak menetapkan outcome" pada form aturan.
const String kTanpaOutcome = '(tidak menetapkan)';

/// Satu kolom formulir H6.
class KolomForm {
  final String kunci;
  final String label;
  final String awal;
  final bool angka;
  final bool wajib;
  final int maxLines;

  /// Bila tidak null, kolom menjadi dropdown dengan pilihan ini — dipakai agar
  /// admin memilih fakta/outcome yang PASTI ada, bukan mengetiknya.
  final List<String>? pilihan;

  /// Bila true, kolom menjadi saklar; nilainya dikembalikan "true"/"false".
  final bool saklar;

  /// Pemeriksaan tambahan per kolom; mengembalikan pesan galat atau null.
  final String? Function(String teks)? cek;

  const KolomForm({
    required this.kunci,
    required this.label,
    this.awal = '',
    this.angka = false,
    this.wajib = true,
    this.maxLines = 1,
    this.pilihan,
    this.saklar = false,
    this.cek,
  });
}

/// Dialog formulir yang MEMILIKI kendali teksnya sendiri.
///
/// Kendali dibuang saat rute dialog dilepas — bukan segera setelah
/// `showDialog` selesai, karena dialog masih beranimasi keluar dan
/// `TextFormField`-nya masih dibangun pada saat itu.
class DialogForm extends StatefulWidget {
  final String judul;
  final List<KolomForm> kolom;

  const DialogForm({super.key, required this.judul, required this.kolom});

  @override
  State<DialogForm> createState() => _DialogFormState();
}

class _DialogFormState extends State<DialogForm> {
  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _kendali = [
    for (final k in widget.kolom) TextEditingController(text: k.awal),
  ];

  /// Nilai kolom non-teks (dropdown/saklar); kolom teks dibaca dari kendali.
  late final List<String> _nilai = [for (final k in widget.kolom) k.awal];

  @override
  void dispose() {
    for (final c in _kendali) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validasi(KolomForm kolom, String? nilai) {
    final teks = (nilai ?? '').trim();
    if (kolom.angka) {
      final n = int.tryParse(teks);
      if (n == null || n <= 0) return 'Isi bilangan bulat lebih dari 0.';
      return null;
    }
    if (kolom.wajib && teks.isEmpty) return 'Tidak boleh kosong.';
    if (kolom.cek != null) return kolom.cek!(teks);
    return null;
  }

  List<String> _hasil() => [
        for (var i = 0; i < widget.kolom.length; i++)
          if (widget.kolom[i].saklar || widget.kolom[i].pilihan != null)
            _nilai[i]
          else
            _kendali[i].text.trim(),
      ];

  Widget _kolomWidget(int i) {
    final k = widget.kolom[i];
    if (k.saklar) {
      return SwitchListTile(
        key: Key('admin-input-${k.kunci}'),
        contentPadding: EdgeInsets.zero,
        title: Text(k.label),
        value: _nilai[i] == 'true',
        onChanged: (v) => setState(() => _nilai[i] = '$v'),
      );
    }
    if (k.pilihan != null) {
      final pilihan = k.pilihan!;
      final awal =
          pilihan.contains(_nilai[i]) ? _nilai[i] : pilihan.first;
      _nilai[i] = awal;
      return DropdownButtonFormField<String>(
        key: Key('admin-input-${k.kunci}'),
        initialValue: awal,
        decoration: InputDecoration(labelText: k.label),
        items: [
          for (final p in pilihan)
            DropdownMenuItem(value: p, child: Text(p)),
        ],
        onChanged: (v) => setState(() => _nilai[i] = v ?? _nilai[i]),
      );
    }
    return TextFormField(
      key: Key('admin-input-${k.kunci}'),
      controller: _kendali[i],
      autofocus: i == 0,
      maxLines: k.maxLines,
      keyboardType: k.angka ? TextInputType.number : null,
      decoration: InputDecoration(labelText: k.label),
      validator: (v) => _validasi(k, v),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.judul),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.kolom.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _kolomWidget(i),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          key: const Key('admin-dialog-simpan'),
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(_hasil());
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
