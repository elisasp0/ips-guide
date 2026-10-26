import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/layout/responsive.dart';
import '../../../data/providers.dart';
import '../../../data/repositories/knowledge_base_repository.dart';
import '../../../domain/entities/guidance_question.dart';
import '../../../domain/entities/knowledge_base.dart';
import '../../../domain/entities/requirement.dart';
import '../../../domain/entities/rule.dart';
import '../application/admin_providers.dart';

/// H6 Kelola Panduan — satu layanan (§5, §12.3 tahap A + B).
///
/// Tahap A: menampilkan aturan, pertanyaan, persyaratan, dan tahapan —
/// termasuk dokumen NON-AKTIF dengan label "Nonaktif" (§12.4).
/// Tahap B: mengubah prioritas aturan, teks pertanyaan, nama/keterangan
/// persyaratan, serta mengaktifkan/menonaktifkan dokumen.
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

  Future<void> _ubahAktifAturan(Rule r, bool aktif) => _simpan(() async {
        final repo = await _repo;
        await repo.simpanAturan(
          widget.serviceId,
          r.copyWith(aktif: aktif),
        );
      });

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

  Future<void> _ubahAktifPertanyaan(GuidanceQuestion q, bool aktif) =>
      _simpan(() async {
        final repo = await _repo;
        await repo.simpanPertanyaan(
          widget.serviceId,
          q.copyWith(aktif: aktif),
        );
      });

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
                  Switch(
                    key: Key('admin-aktif-${r.id}'),
                    value: r.aktif,
                    onChanged: (v) => _ubahAktifAturan(r, v),
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
                  Switch(
                    key: Key('admin-aktif-${q.id}'),
                    value: q.aktif,
                    onChanged: (v) => _ubahAktifPertanyaan(q, v),
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

/// Satu kolom formulir H6.
class KolomForm {
  final String kunci;
  final String label;
  final String awal;
  final bool angka;
  final bool wajib;
  final int maxLines;

  const KolomForm({
    required this.kunci,
    required this.label,
    this.awal = '',
    this.angka = false,
    this.wajib = true,
    this.maxLines = 1,
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
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.judul),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.kolom.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              TextFormField(
                key: Key('admin-input-${widget.kolom[i].kunci}'),
                controller: _kendali[i],
                autofocus: i == 0,
                maxLines: widget.kolom[i].maxLines,
                keyboardType:
                    widget.kolom[i].angka ? TextInputType.number : null,
                decoration: InputDecoration(
                  labelText: widget.kolom[i].label,
                ),
                validator: (v) => _validasi(widget.kolom[i], v),
              ),
            ],
          ],
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
              Navigator.of(context).pop(
                [for (final c in _kendali) c.text.trim()],
              );
            }
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
