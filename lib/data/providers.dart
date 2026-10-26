import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ips_guide/data/repositories/auth_repository.dart';
import 'package:ips_guide/data/repositories/in_memory_auth_repository.dart';
import 'package:ips_guide/data/repositories/in_memory_knowledge_base_repository.dart';
import 'package:ips_guide/domain/entities/guidance_service.dart';

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
