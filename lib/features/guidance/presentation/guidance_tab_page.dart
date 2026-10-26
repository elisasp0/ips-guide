import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/responsive.dart';

/// Tab Panduan (§3.6): menampilkan sesi aktif, atau keadaan kosong bila
/// belum ada sesi. Sesi nyata (H4/H5) dibangun pada Tahap 4.
class GuidanceTabPage extends StatelessWidget {
  const GuidanceTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panduan')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(kPagePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.route_outlined, size: 48),
              const SizedBox(height: 8),
              Text(
                'Belum ada panduan yang sedang berjalan',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Mulai dari Pilih Layanan untuk menjawab pertanyaan dan '
                'mendapatkan panduan persyaratan.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
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
}
