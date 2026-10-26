import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/responsive.dart';
import '../application/guidance_controller.dart';

/// H4 Pertanyaan Panduan (§5, §15 Tahap 4): SATU pertanyaan per langkah,
/// progres, tombol Kembali memicu recompute di controller.
class PertanyaanPage extends ConsumerStatefulWidget {
  final String serviceId;

  const PertanyaanPage({super.key, required this.serviceId});

  @override
  ConsumerState<PertanyaanPage> createState() => _PertanyaanPageState();
}

class _PertanyaanPageState extends ConsumerState<PertanyaanPage> {
  String? _pilihanUntukPertanyaan; // id pertanyaan yang sedang dipilih
  String? _pilihan;
  String? _pesanPilihan; // keadaan "jawaban belum lengkap" (§5.1)

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guidanceControllerProvider);

    // Mulai sesi bila belum berjalan untuk layanan ini (post-frame agar
    // tidak memodifikasi provider saat build).
    final perluMulai = state.phase == GuidancePhase.idle ||
        (state.phase != GuidancePhase.loading &&
            state.serviceId != widget.serviceId);
    if (perluMulai) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(guidanceControllerProvider.notifier).mulai(widget.serviceId);
        }
      });
    }

    // Navigasi ke H5 begitu sesi selesai.
    ref.listen<GuidanceState>(guidanceControllerProvider, (prev, next) {
      if (next.phase == GuidancePhase.completed) {
        context.go('/hasil');
      }
    });

    final theme = Theme.of(context);
    final question = state.question;

    // Reset pilihan bila pertanyaan berganti.
    if (question != null && _pilihanUntukPertanyaan != question.id) {
      _pilihanUntukPertanyaan = question.id;
      _pilihan = null;
      _pesanPilihan = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(state.serviceNama ?? 'Pertanyaan Panduan'),
      ),
      body: switch (state.phase) {
        GuidancePhase.idle ||
        GuidancePhase.loading =>
          const Center(child: CircularProgressIndicator()),
        GuidancePhase.error => Center(
            child: Padding(
              padding: const EdgeInsets.all(kPagePadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Layanan belum tersedia'),
                  const SizedBox(height: 8),
                  Text(
                    state.error ?? '',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        ref.read(guidanceControllerProvider.notifier).mulai(
                              widget.serviceId,
                            ),
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            ),
          ),
        GuidancePhase.completed => const Center(
            child: CircularProgressIndicator(),
          ),
        GuidancePhase.questioning => SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(kPagePadding),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LinearProgressIndicator(
                        value: state.totalQuestions == 0
                            ? null
                            : state.answered / state.totalQuestions,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Jawaban tersimpan: ${state.answered}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(kPagePadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                question!.teks,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              RadioGroup<String>(
                                groupValue: _pilihan,
                                onChanged: (v) => setState(() {
                                  _pilihan = v;
                                  _pesanPilihan = null;
                                }),
                                child: Column(
                                  children: [
                                    for (final opsi in question.opsi)
                                      RadioListTile<String>(
                                        value: opsi.value,
                                        title: Text(opsi.label),
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Keadaan alternatif §5.1: "jawaban belum lengkap".
                      // Tombol tetap aktif agar alasannya dapat dijelaskan —
                      // tombol mati tanpa keterangan membingungkan pengguna.
                      if (_pesanPilihan != null) ...[
                        Text(
                          _pesanPilihan!,
                          key: const Key('h4-pesan-pilihan'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.error,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Row(
                        children: [
                          OutlinedButton(
                            onPressed: state.answered > 0
                                ? () => ref
                                    .read(guidanceControllerProvider.notifier)
                                    .kembali()
                                : null,
                            child: const Text('Kembali'),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () {
                              final pilihan = _pilihan;
                              if (pilihan == null) {
                                setState(
                                  () => _pesanPilihan =
                                      'Pilih salah satu jawaban untuk '
                                      'melanjutkan.',
                                );
                                return;
                              }
                              ref
                                  .read(guidanceControllerProvider.notifier)
                                  .jawab(pilihan);
                            },
                            child: const Text('Lanjut'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      },
    );
  }
}
