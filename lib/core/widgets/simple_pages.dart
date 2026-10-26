import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../layout/responsive.dart';

/// Halaman sementara untuk rute yang dibangun pada tahap berikutnya.
class PlaceholderPage extends StatelessWidget {
  final String title;
  final String pesan;

  const PlaceholderPage({
    super.key,
    required this.title,
    this.pesan = 'Halaman ini dibangun pada tahap berikutnya.',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(kPagePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction, size: 48),
              const SizedBox(height: 8),
              Text(pesan, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

/// Halaman 404 — rute tidak dikenal (§15 Tahap 3).
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Halaman tidak ditemukan')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(kPagePadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: AppColors.danger,
              ),
              const SizedBox(height: 8),
              const Text('Alamat yang Anda buka tidak dikenal.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).pop(),
                child: const Text('Kembali'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
