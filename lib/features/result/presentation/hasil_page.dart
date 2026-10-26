import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/responsive.dart';
import '../../../app/theme.dart';
import '../../../domain/entities/guidance_result.dart';
import '../../../domain/entities/outcome.dart';
import '../../guidance/application/guidance_controller.dart';
import '../application/hasil_provider.dart';

/// H5 Hasil Panduan (§5, §15 Tahap 4, §10.7):
/// banner status, ringkasan jawaban, checklist persyaratan (disembunyikan
/// bila tidak_dapat_diproses), timeline tahapan, catatan, "Mengapa?",
/// salin ringkasan, disclaimer.
class HasilPage extends ConsumerWidget {
  const HasilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasil = ref.watch(hasilPanduanProvider);

    // Guard sesi (§3.6): /hasil tanpa sesi aktif → arahkan ke /layanan.
    if (hasil == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hasil Panduan')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(kPagePadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Belum ada sesi panduan yang selesai.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => context.go('/layanan'),
                  child: const Text('Pilih Layanan'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final result = hasil.result;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(result.service.nama)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(kPagePadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kResultMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BannerStatus(outcome: result.outcome),
                  const SizedBox(height: 16),
                  _RingkasanJawaban(items: hasil.ringkasanJawaban),
                  if (result.tampilkanDetail) ...[
                    const SizedBox(height: 16),
                    _ChecklistPersyaratan(result: result),
                    const SizedBox(height: 16),
                    _TimelineTahapan(result: result),
                  ],
                  if (result.notes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _Catatan(result: result),
                  ],
                  const SizedBox(height: 16),
                  _Mengapa(result: result),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => _salin(context, hasil),
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Salin Ringkasan'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Aplikasi ini hanya media panduan — bukan keputusan '
                    'resmi. Silakan konfirmasi ke loket pelayanan '
                    'Kelurahan Tegalsari.',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      ref.read(guidanceControllerProvider.notifier).selesai();
                      context.go('/');
                    },
                    child: const Text('Selesai'),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _salin(BuildContext context, HasilPanduan hasil) {
    Clipboard.setData(ClipboardData(text: _teksRingkasan(hasil)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ringkasan disalin ke papan klip.')),
    );
  }

  String _teksRingkasan(HasilPanduan hasil) {
    final r = hasil.result;
    final b = StringBuffer()
      ..writeln('Panduan IPS-Guide — ${r.service.nama}')
      ..writeln('Status: ${statusLabel(r.outcome)}');
    if (hasil.ringkasanJawaban.isNotEmpty) {
      b.writeln('Jawaban:');
      for (final (q, a) in hasil.ringkasanJawaban) {
        b.writeln('- $q: $a');
      }
    }
    if (r.tampilkanDetail && r.requirements.isNotEmpty) {
      b.writeln('Persyaratan:');
      for (final q in r.requirements) {
        b.writeln('- ${q.wajib ? "[wajib] " : "[opsional] "}${q.nama}');
      }
    }
    if (r.tampilkanDetail && r.steps.isNotEmpty) {
      b.writeln('Tahapan:');
      var i = 1;
      for (final s in r.steps) {
        b.writeln('${i++}. ${s.judul}');
      }
    }
    if (r.notes.isNotEmpty) {
      b.writeln('Catatan:');
      for (final n in r.notes) {
        b.writeln('- ${n.teks}');
      }
    }
    return b.toString().trim();
  }
}

/// Visual status per §13.5 — TIDAK lewat warna saja (ikon + teks).
String statusLabel(Outcome? outcome) => switch (outcome) {
      Outcome.dapatDiproses => 'Dapat diproses',
      Outcome.denganCatatan => 'Dapat diproses dengan catatan',
      Outcome.tidakDapatDiproses => 'Belum dapat diproses di sini',
      null => 'Panduan belum tersedia',
    };

class _BannerStatus extends StatelessWidget {
  final Outcome? outcome;

  const _BannerStatus({required this.outcome});

  @override
  Widget build(BuildContext context) {
    final (ikon, warna, label) = switch (outcome) {
      Outcome.dapatDiproses => (
          Icons.check_circle_outline,
          AppColors.success,
          statusLabel(outcome),
        ),
      Outcome.denganCatatan => (
          Icons.warning_amber_outlined,
          AppColors.waiting,
          statusLabel(outcome),
        ),
      Outcome.tidakDapatDiproses => (
          Icons.cancel_outlined,
          AppColors.danger,
          statusLabel(outcome),
        ),
      null => (
          Icons.info_outline,
          AppColors.waiting,
          statusLabel(outcome),
        ),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(kPagePadding),
        child: Row(
          children: [
            Icon(ikon, color: warna, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: warna,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RingkasanJawaban extends StatelessWidget {
  final List<(String, String)> items;

  const _RingkasanJawaban({required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(kPagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jawaban Anda', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (items.isEmpty)
              Text('Tidak ada jawaban.', style: theme.textTheme.bodySmall)
            else
              for (final (q, a) in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(q, style: theme.textTheme.bodyMedium),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          a,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _ChecklistPersyaratan extends StatelessWidget {
  final GuidanceResult result;

  const _ChecklistPersyaratan({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(kPagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dokumen yang perlu disiapkan', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (result.requirements.isEmpty)
              Text('Tidak ada.', style: theme.textTheme.bodySmall)
            else
              for (final q in result.requirements)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    q.wajib ? Icons.check_box_outlined : Icons.check_box_outline_blank,
                    color: AppColors.primary,
                  ),
                  title: Text(q.nama),
                  subtitle: Text(
                    q.wajib ? 'Wajib · dari aturan ${q.sourceRuleId}' : 'Opsional',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _TimelineTahapan extends StatelessWidget {
  final GuidanceResult result;

  const _TimelineTahapan({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(kPagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tahapan pelayanan', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (var i = 0; i < result.steps.length; i++)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                title: Text(result.steps[i].judul),
                subtitle: Text(
                  result.steps[i].keterangan,
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Catatan extends StatelessWidget {
  final GuidanceResult result;

  const _Catatan({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(kPagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Catatan', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final n in result.notes)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(n.teks)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Explanation facility (§10.8, §2): aturan mana yang menyala dan mana
/// pemenangnya — untuk ditelusuri admin/penguji.
class _Mengapa extends StatelessWidget {
  final GuidanceResult result;

  const _Mengapa({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: kPagePadding),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Text('Mengapa hasilnya seperti ini?', style: theme.textTheme.titleMedium),
        children: [
          if (result.trace.isEmpty)
            Text(
              'Tidak ada aturan yang menyala untuk jawaban Anda — '
              'karena itu statusnya "Panduan belum tersedia".',
              style: theme.textTheme.bodySmall,
            )
          else
            for (final t in result.trace)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  t.isWinner ? Icons.emoji_events_outlined : Icons.rule_outlined,
                  color: t.isWinner ? AppColors.primary : AppColors.textSecondary,
                ),
                title: Text(
                  t.isWinner ? '${t.ruleId} — penentu status' : t.ruleId,
                  style: theme.textTheme.bodyMedium,
                ),
                subtitle: Text(
                  'prioritas ${t.priority} · ${t.deskripsi}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
        ],
      ),
    );
  }
}
