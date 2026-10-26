import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/responsive.dart';
import '../../auth/application/auth_controller.dart';

/// H2 Beranda (§5, wireframe Minggu 4): sapaan, kartu layanan, tombol
/// "Mulai Panduan", serta aksi sesi (Keluar, Kelola Panduan untuk admin).
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final nama = auth.user?.nama;

    return Scaffold(
      appBar: AppBar(
        title: const Text('IPS-Guide'),
        actions: [
          IconButton(
            key: const Key('h2-keluar'),
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(authControllerProvider.notifier).keluar(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(kPagePadding),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    nama == null
                        ? 'Selamat datang'
                        : 'Selamat datang, $nama',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Panduan interaktif layanan administrasi '
                    'Kelurahan Tegalsari. Pilih layanan, jawab beberapa '
                    'pertanyaan, dan dapatkan daftar persyaratan serta '
                    'tahapan yang sesuai dengan kondisi Anda.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context.go('/layanan'),
                    icon: const Icon(Icons.explore_outlined),
                    label: const Text('Mulai Panduan'),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Layanan yang tersedia',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _KartuLayanan(
                    ikon: Icons.badge_outlined,
                    judul: 'Kartu Tanda Penduduk Elektronik',
                    onTap: () => context.go('/panduan/ktp'),
                  ),
                  _KartuLayanan(
                    ikon: Icons.family_restroom_outlined,
                    judul: 'Kartu Keluarga',
                    onTap: () => context.go('/panduan/kk'),
                  ),
                  _KartuLayanan(
                    ikon: Icons.home_outlined,
                    judul: 'Surat Keterangan Domisili',
                    onTap: () => context.go('/panduan/domisili'),
                  ),
                  // Menu admin hanya untuk peran admin (S25). Guard rute tetap
                  // menolak akses langsung lewat URL.
                  if (auth.isAdmin) ...[
                    const SizedBox(height: 24),
                    Text('Administrasi', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        key: const Key('h2-kelola-panduan'),
                        onTap: () => context.go('/admin'),
                        leading: const Icon(Icons.tune_outlined),
                        title: const Text('Kelola Panduan'),
                        subtitle: const Text(
                          'Tambah, ubah, atau nonaktifkan aturan panduan.',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Informasi di aplikasi ini bersifat panduan dan belum '
                    'menggantikan konfirmasi resmi petugas kelurahan.',
                    style: theme.textTheme.bodySmall,
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
}

class _KartuLayanan extends StatelessWidget {
  final IconData ikon;
  final String judul;
  final VoidCallback onTap;

  const _KartuLayanan({
    required this.ikon,
    required this.judul,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(ikon),
        title: Text(judul),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
