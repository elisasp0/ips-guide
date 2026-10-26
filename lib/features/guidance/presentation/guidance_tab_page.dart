import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/responsive.dart';
import '../application/guidance_controller.dart';

/// Tab Panduan (§3.6): menampilkan sesi aktif (lanjutkan / lihat hasil)
/// atau keadaan kosong bila belum ada sesi.
class GuidanceTabPage extends ConsumerWidget {
  const GuidanceTabPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(guidanceControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Panduan')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(kPagePadding),
          child: switch (state.phase) {
            GuidancePhase.loading => const CircularProgressIndicator(),
            GuidancePhase.questioning => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.route, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Panduan "${state.serviceNama ?? '-'}" sedang berjalan',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/panduan/${state.serviceId}'),
                    child: const Text('Lanjutkan Panduan'),
                  ),
                ],
              ),
            GuidancePhase.completed => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.task_alt, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Panduan "${state.serviceNama ?? '-'}" selesai',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/hasil'),
                    child: const Text('Lihat Hasil'),
                  ),
                ],
              ),
            GuidancePhase.error => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    state.error ?? 'Terjadi kesalahan.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/layanan'),
                    child: const Text('Pilih Layanan'),
                  ),
                ],
              ),
            GuidancePhase.idle => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.route_outlined, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Belum ada panduan yang sedang berjalan',
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mulai dari Pilih Layanan untuk menjawab pertanyaan dan '
                    'mendapatkan panduan persyaratan.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.go('/layanan'),
                    child: const Text('Pilih Layanan'),
                  ),
                ],
              ),
          },
        ),
      ),
    );
  }
}
