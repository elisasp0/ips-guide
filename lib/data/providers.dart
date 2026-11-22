
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ips_guide/data/repositories/auth_repository.dart';
import 'package:ips_guide/data/repositories/firebase_auth_repository.dart';
import 'package:ips_guide/data/repositories/firestore_kebutuhan_repository.dart';
import 'package:ips_guide/data/repositories/firestore_knowledge_base_repository.dart';
import 'package:ips_guide/data/repositories/knowledge_base_repository.dart';
import 'package:ips_guide/data/repositories/kebutuhan_repository.dart';

import 'package:ips_guide/domain/entities/guidance_service.dart';
import 'package:ips_guide/domain/entities/kebutuhan_warga.dart';

import 'package:ips_guide/services/layanan_firestore.dart';

/// Provider layanan Firestore.
final layananFirestoreProvider = Provider<LayananFirestore>(
  (ref) => LayananFirestore(),
);

/// Repository basis pengetahuan menggunakan Cloud Firestore.
/// Aturan, pertanyaan, persyaratan, dan tahapan dibaca
/// langsung dari koleksi Firestore.
final repositoryProvider =
    FutureProvider<KnowledgeBaseRepository>(
  (ref) async {
    return FirestoreKnowledgeBaseRepository();
  },
);

/// Repository autentikasi menggunakan Firebase Authentication.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(),
);

/// Daftar layanan H3 dibaca dari Cloud Firestore.

final servicesProvider = FutureProvider<List<GuidanceService>>(
  (ref) async {
    final repo = await ref.watch(repositoryProvider.future);
    return repo.loadServices();
  },
);


/// Repository kebutuhan warga menggunakan Cloud Firestore.
final kebutuhanRepositoryProvider = Provider<KebutuhanRepository>(
  (ref) {
    return FirestoreKebutuhanRepository(
      firestore: ref.watch(layananFirestoreProvider),
    );
  },
);


/// Daftar kebutuhan warga dipantau secara real-time dari Firestore.
final daftarKebutuhanProvider =
    StreamProvider<List<KebutuhanWarga>>(
  (ref) {
    return ref.watch(kebutuhanRepositoryProvider).pantau();
  },
);

