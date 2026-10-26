import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../data/repositories/knowledge_base_repository.dart';
import '../../../domain/entities/guidance_service.dart';
import '../../../domain/entities/knowledge_base.dart';

/// Ringkasan satu layanan untuk daftar H6 (§12.3 tahap A).
class RingkasanLayanan {
  final GuidanceService service;
  final int jumlahAturan;
  final int jumlahPertanyaan;

  /// `false` bila basis pengetahuan layanan gagal validasi saat dimuat.
  final bool sah;

  const RingkasanLayanan({
    required this.service,
    required this.jumlahAturan,
    required this.jumlahPertanyaan,
    required this.sah,
  });
}

/// Daftar layanan + jumlah aturan/pertanyaan untuk H6.
final adminRingkasanProvider =
    FutureProvider<List<RingkasanLayanan>>((ref) async {
  final repo = await ref.watch(repositoryProvider.future);
  final services = await repo.loadServices();
  final hasil = <RingkasanLayanan>[];
  for (final s in services) {
    try {
      final kb = await repo.loadService(s.id);
      hasil.add(
        RingkasanLayanan(
          service: s,
          jumlahAturan: kb.rules.length,
          jumlahPertanyaan: kb.questions.length,
          sah: true,
        ),
      );
    } on KnowledgeBaseException {
      hasil.add(
        RingkasanLayanan(
          service: s,
          jumlahAturan: 0,
          jumlahPertanyaan: 0,
          sah: false,
        ),
      );
    }
  }
  return hasil;
});

/// Basis pengetahuan satu layanan untuk H6 — termasuk dokumen NON-AKTIF
/// (§12.4: admin harus melihatnya agar dapat mengaktifkan kembali).
final adminKbProvider =
    FutureProvider.family<KnowledgeBase, String>((ref, serviceId) async {
  final repo = await ref.watch(repositoryProvider.future);
  return repo.loadService(serviceId);
});
