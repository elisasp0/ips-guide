import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/responsive.dart';

/// H2 Beranda (§5, wireframe Minggu 4): sapaan, kartu layanan, tombol
/// "Mulai Panduan".
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('IPS-Guide')),
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
                    'Selamat datang',
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
                  Text('Layanan yang tersedia', style: theme.textTheme.titleMedium),
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
