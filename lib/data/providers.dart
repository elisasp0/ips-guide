import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ips_guide/data/repositories/auth_repository.dart';
import 'package:ips_guide/data/repositories/in_memory_auth_repository.dart';
import 'package:ips_guide/data/repositories/in_memory_kebutuhan_repository.dart';
import 'package:ips_guide/data/repositories/in_memory_knowledge_base_repository.dart';
import 'package:ips_guide/data/repositories/kebutuhan_repository.dart';
import 'package:ips_guide/domain/entities/guidance_service.dart';
import 'package:ips_guide/domain/entities/kebutuhan_warga.dart';

/// Provider repository — satu-satunya pintu masuk data (§3.1 aturan 3).
///
/// Tahap 2–4: in-memory dari seed. Tahap 6: diganti FirestoreKnowledgeBase —
/// UI tidak berubah karena antarmuka sama (§3.3).
final repositoryProvider = FutureProvider<InMemoryKnowledgeBaseRepository>(
  (ref) => InMemoryKnowledgeBaseRepository.fromAssets(),
);

/// Repository autentikasi (§3.3).
///
/// Tahap 5a: [InMemoryAuthRepository] — kontrak & UI diuji tanpa Firebase.
/// Tahap 5b: `FirebaseAuthRepository` — hanya baris ini yang berubah.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => InMemoryAuthRepository(),
);

/// Daftar layanan untuk H3 — SEMUA layanan termasuk nonaktif (T-06).
final servicesProvider =
    FutureProvider<List<GuidanceService>>((ref) async {
  final repo = await ref.watch(repositoryProvider.future);
  return repo.loadServices();
});

/// Penyimpanan kebutuhan warga (H7). Tahap ini di memori; data hilang saat
/// aplikasi ditutup (Modul Minggu 7 §5).
final kebutuhanRepositoryProvider = Provider<KebutuhanRepository>(
  (ref) => InMemoryKebutuhanRepository(),
);

/// Daftar kebutuhan yang sudah dikirim, terbaru lebih dulu.
///
/// Di-invalidate setelah penyimpanan berhasil — pola yang sama dengan
/// `adminKbProvider` di H6, jadi daftar selalu dibaca ulang dari repository.
final daftarKebutuhanProvider = FutureProvider<List<KebutuhanWarga>>(
  (ref) async => ref.watch(kebutuhanRepositoryProvider).daftar(),
);
