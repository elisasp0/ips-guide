import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/layout/responsive.dart';
import '../application/admin_providers.dart';

/// H6 Kelola Panduan — daftar layanan (§5, §12.3 tahap A).
///
/// Perubahan yang disimpan di sini berlaku pada sesi panduan BERIKUTNYA
/// (S28) karena sesi selalu memuat basis pengetahuan dari repository.
class AdminPage extends ConsumerWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final ringkasan = ref.watch(adminRingkasanProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Panduan')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: kResultMaxWidth),
            child: ringkasan.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(kPagePadding),
                  child: Text('Gagal memuat data panduan.\n$e'),
                ),
              ),
              data: (daftar) => ListView(
                padding: const EdgeInsets.all(kPagePadding),
                children: [
                  Text(
                    'Perubahan berlaku pada sesi panduan berikutnya. '
                    'Setiap penyimpanan divalidasi lebih dulu; bila '
                    'melanggar aturan basis pengetahuan, penyimpanan ditolak.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  for (final r in daftar) ...[
                    Card(
                      child: ListTile(
                        key: Key('admin-layanan-${r.service.id}'),
                        onTap: () => context.go('/admin/${r.service.id}'),
                        leading: Icon(
                          r.sah
                              ? Icons.description_outlined
                              : Icons.error_outline,
                          color: r.sah ? null : AppColors.danger,
                        ),
                        title: Text(r.service.nama),
                        subtitle: Text(
                          r.sah
                              ? '${r.jumlahAturan} aturan · '
                                  '${r.jumlahPertanyaan} pertanyaan'
                              : 'Basis pengetahuan tidak valid',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: r.sah ? null : AppColors.danger,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
