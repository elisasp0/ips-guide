
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ips_guide/data/providers.dart';
import 'package:ips_guide/data/repositories/auth_repository.dart';
import 'package:ips_guide/data/repositories/in_memory_auth_repository.dart';
import 'package:ips_guide/data/repositories/in_memory_kebutuhan_repository.dart';
import 'package:ips_guide/data/repositories/in_memory_knowledge_base_repository.dart';
import 'package:ips_guide/data/repositories/knowledge_base_repository.dart';

/// Utilitas pompa dan penyiapan untuk uji widget IPS-Guide.
///
/// `pumpAndSettle` tidak dapat dipakai karena fase loading menggunakan
/// CircularProgressIndicator dengan animasi tak berhingga.
/// Karena itu digunakan pompa berbatas dan polling.

/// Pompa [frames] frame @100 ms.
///
/// Dipakai untuk menyelesaikan animasi transisi rute (300 ms).
Future<void> tenang(
  WidgetTester tester, {
  int frames = 8,
}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(
      const Duration(milliseconds: 100),
    );
  }
}

/// Pompa bertahap sampai [finder] menemukan sesuatu.
///
/// Maksimal 10 detik, kemudian tenangkan transisi agar siap menerima tap.
Future<void> tunggu(
  WidgetTester tester,
  Finder finder,
) async {
  for (var i = 0; i < 100; i++) {
    await tester.pump(
      const Duration(milliseconds: 100),
    );

    if (finder.evaluate().isNotEmpty) {
      await tenang(tester);

      if (finder.evaluate().isNotEmpty) {
        return;
      }
    }
  }

  fail('Tidak muncul dalam 10 detik: $finder');
}

/// Repository basis pengetahuan untuk pengujian.
///
/// Dimuat sekali di luar zona fake-async testWidgets.
late InMemoryKnowledgeBaseRepository testRepository;

/// Repository autentikasi bersama untuk pengujian.
///
/// Kondisi awal: sudah masuk sebagai warga.
late InMemoryAuthRepository testAuth;

/// Menyiapkan repository sebelum pengujian dimulai.
///
/// Dipakai sebagai setUpAll(siapkanRepository).
Future<void> siapkanRepository() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  testRepository =
      await InMemoryKnowledgeBaseRepository.fromAssets();

  testAuth = InMemoryAuthRepository();

  await testAuth.masuk(
    email: InMemoryAuthRepository.emailWargaDemo,
    password: InMemoryAuthRepository.sandiDemo,
  );
}

/// Bungkus widget uji dengan ProviderScope.
///
/// Repository basis pengetahuan, autentikasi, dan kebutuhan warga
/// menggunakan implementasi in-memory selama pengujian.
///
/// [kb] dapat diisi repository segar untuk pengujian H6.
Widget bungkusAplikasi(
  Widget child, {
  AuthRepository? auth,
  InMemoryKnowledgeBaseRepository? kb,
}) {
  return ProviderScope(
    overrides: [
      repositoryProvider.overrideWithValue(
        AsyncData<KnowledgeBaseRepository>(
          kb ?? testRepository,
        ),
      ),

      authRepositoryProvider.overrideWithValue(
        auth ?? testAuth,
      ),

      kebutuhanRepositoryProvider.overrideWithValue(
        InMemoryKebutuhanRepository(),
      ),
    ],
    child: child,
  );
}

/// ProviderContainer dengan override yang sama.
///
/// Digunakan untuk pengujian provider dan rute langsung.
ProviderContainer buatContainer({
  AuthRepository? auth,
  InMemoryKnowledgeBaseRepository? kb,
}) {
  return ProviderContainer(
    overrides: [
      repositoryProvider.overrideWithValue(
        AsyncData<KnowledgeBaseRepository>(
          kb ?? testRepository,
        ),
      ),

      authRepositoryProvider.overrideWithValue(
        auth ?? testAuth,
      ),

      kebutuhanRepositoryProvider.overrideWithValue(
        InMemoryKebutuhanRepository(),
      ),
    ],
  );
}
