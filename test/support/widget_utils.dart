import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ips_guide/data/providers.dart';
import 'package:ips_guide/data/repositories/auth_repository.dart';
import 'package:ips_guide/data/repositories/in_memory_auth_repository.dart';
import 'package:ips_guide/data/repositories/in_memory_knowledge_base_repository.dart';

/// Utilitas pompa & penyiapan untuk uji widget IPS-Guide.
///
/// `pumpAndSettle` tidak dapat dipakai: fase loading memakai
/// `CircularProgressIndicator` (animasi tak berhingga) sehingga
/// `pumpAndSettle` selalu melempar timeout. Karena itu dipakai pompa
/// berbatas + polling.

/// Pompa [frames] frame @100 ms. Dipakai untuk menyelesaikan animasi
/// transisi rute (300 ms) — selama transisi berjalan Flutter membungkus
/// rute dengan `IgnorePointer` sehingga tap tidak akan mengenai sasaran.
Future<void> tenang(WidgetTester tester, {int frames = 8}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Pompa bertahap sampai [finder] menemukan sesuatu (maks 10 detik), lalu
/// tenangkan transisi agar siap menerima tap.
///
/// Bila hasil pencarian berasal dari halaman lama yang sedang ditransisikan,
/// [tenang] akan membuangnya; pencarian diulang sampai stabil.
Future<void> tunggu(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      await tenang(tester);
      if (finder.evaluate().isNotEmpty) return;
    }
  }
  fail('Tidak muncul dalam 10 detik: $finder');
}

/// Repository seed yang dimuat SEKALI di luar zona fake-async `testWidgets`.
///
/// `InMemoryKnowledgeBaseRepository.fromAssets()` membaca `rootBundle` (IO
/// nyata). Di dalam `testWidgets` waktu adalah waktu palsu sehingga IO nyata
/// dapat kalah balapan dan fase loading tidak pernah selesai. Memuatnya di
/// `setUpAll` lalu menimpakan [repositoryProvider] membuat uji deterministik;
/// jalur pemuatan aset sendiri sudah diuji di `test/data` dan `test/scenario`.
late InMemoryKnowledgeBaseRepository testRepository;

/// Repository autentikasi bersama, sudah dalam keadaan MASUK sebagai warga.
///
/// Uji yang membutuhkan keadaan lain (belum masuk, admin, profil hilang)
/// membuat instance sendiri dan mengopernya ke [bungkusAplikasi].
late InMemoryAuthRepository testAuth;

/// Dipakai sebagai `setUpAll(siapkanRepository)`.
Future<void> siapkanRepository() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  testRepository = await InMemoryKnowledgeBaseRepository.fromAssets();
  testAuth = InMemoryAuthRepository();
  await testAuth.masuk(
    email: InMemoryAuthRepository.emailWargaDemo,
    password: InMemoryAuthRepository.sandiDemo,
  );
}

/// Bungkus widget uji dengan `ProviderScope` yang memakai repository uji.
Widget bungkusAplikasi(Widget child, {AuthRepository? auth}) => ProviderScope(
      overrides: [
        repositoryProvider.overrideWithValue(AsyncData(testRepository)),
        authRepositoryProvider.overrideWithValue(auth ?? testAuth),
      ],
      child: child,
    );

/// `ProviderContainer` dengan override yang sama (untuk uji rute langsung).
ProviderContainer buatContainer({AuthRepository? auth}) => ProviderContainer(
      overrides: [
        repositoryProvider.overrideWithValue(AsyncData(testRepository)),
        authRepositoryProvider.overrideWithValue(auth ?? testAuth),
      ],
    );
