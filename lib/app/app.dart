import 'package:flutter/material.dart';

import 'theme.dart';

/// Root aplikasi IPS-Guide.
///
/// Tahap 0: bootstrap minimal — tema dari §13, tanpa demo counter.
/// Routing (go_router), guard, dan halaman riil menyusul pada Tahap 3.
class IpsGuideApp extends StatelessWidget {
  const IpsGuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPS-Guide',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const PlaceholderPage(),
    );
  }
}

/// Halaman sementara sebelum kerangka navigasi dibangun di Tahap 3.
class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('IPS-Guide')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Aplikasi Panduan Interaktif Layanan Administrasi Kelurahan',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Kerangka halaman dibangun pada Tahap 3. '
                'Mesin aturan (Tahap 1) dikerjakan terlebih dahulu.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
