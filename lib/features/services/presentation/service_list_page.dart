import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/layout/responsive.dart';
import '../../../data/providers.dart';
import '../../../domain/entities/guidance_service.dart';

/// H3 Pilih Layanan (§5, T-06): semua layanan tampil — yang nonaktif
/// bertanda "Belum tersedia" dan tidak dapat dipilih.
class ServiceListPage extends ConsumerWidget {
  const ServiceListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(servicesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Layanan')),
      body: servicesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => _KeadaanGalat(pesan: '$e'),
        data: (services) => SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(kPagePadding),
            itemCount: services.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) =>
                _KartuLayanan(service: services[i]),
          ),
        ),
      ),
    );
  }
}

class _KartuLayanan extends StatelessWidget {
  final GuidanceService service;

  const _KartuLayanan({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tersedia = service.aktif;

    return Card(
      child: ListTile(
        // Target sentuh >=48 (§13.3); ListTile standar memenuhi.
        onTap: tersedia
            ? () => context.go('/panduan/${service.id}')
            : null,
        enabled: tersedia,
        leading: Icon(
          tersedia ? Icons.description_outlined : Icons.block_outlined,
        ),
        title: Text(service.nama),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(service.deskripsi),
            const SizedBox(height: 4),
            Text(
              tersedia
                  ? 'Estimasi ${service.estimasiHariMin}–'
                      '${service.estimasiHariMax} hari kerja'
                  : 'Belum tersedia',
              style: theme.textTheme.bodySmall?.copyWith(
                color: tersedia
                    ? theme.textTheme.bodySmall?.color
                    : theme.colorScheme.error,
                fontWeight: tersedia ? null : FontWeight.w700,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _KeadaanGalat extends StatelessWidget {
  final String pesan;

  const _KeadaanGalat({required this.pesan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(kPagePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Layanan belum tersedia'),
            const SizedBox(height: 8),
            Text(pesan, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
