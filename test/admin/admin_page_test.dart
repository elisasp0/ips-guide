import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ips_guide/app/app.dart';
import 'package:ips_guide/data/repositories/in_memory_auth_repository.dart';
import 'package:ips_guide/data/repositories/in_memory_knowledge_base_repository.dart';
import 'package:ips_guide/data/seed/seed_loader.dart';

import '../support/widget_utils.dart';

/// Uji H6 Kelola Panduan (§12.3 tahap A + B, §12.5, S28, S44).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SeedData seed;

  setUpAll(() async {
    seed = await SeedLoader.load();
  });

  /// Repository segar per uji agar perubahan tidak bocor antar uji.
  Future<InMemoryKnowledgeBaseRepository> bukaH6SebagaiAdmin(
    WidgetTester tester,
  ) async {
    final repo = InMemoryKnowledgeBaseRepository.fromMaps(seed);
    final auth = InMemoryAuthRepository();
    await auth.masuk(
      email: InMemoryAuthRepository.emailAdminDemo,
      password: InMemoryAuthRepository.sandiDemo,
    );

    await tester.pumpWidget(
      bungkusAplikasi(const IpsGuideApp(), auth: auth, kb: repo),
    );
    await tunggu(tester, find.byKey(const Key('h2-kelola-panduan')));

    await tester.ensureVisible(find.byKey(const Key('h2-kelola-panduan')));
    await tenang(tester);
    await tester.tap(find.byKey(const Key('h2-kelola-panduan')));
    await tunggu(tester, find.byKey(const Key('admin-layanan-ktp')));
    return repo;
  }

  testWidgets('H6 menampilkan tiga layanan beserta jumlah aturan', (tester) async {
    await bukaH6SebagaiAdmin(tester);

    expect(find.byKey(const Key('admin-layanan-ktp')), findsOneWidget);
    expect(find.byKey(const Key('admin-layanan-kk')), findsOneWidget);
    expect(find.byKey(const Key('admin-layanan-domisili')), findsOneWidget);
  });

  testWidgets('H6 menampilkan aturan satu layanan beserta prioritas',
      (tester) async {
    await bukaH6SebagaiAdmin(tester);

    await tester.tap(find.byKey(const Key('admin-layanan-ktp')));
    await tunggu(tester, find.byKey(const Key('admin-aturan-KTP-R01')));

    expect(find.textContaining('prioritas 95'), findsOneWidget);
    // Dokumen nonaktif tetap terlihat (§12.4) — semua aktif pada seed.
    expect(find.textContaining('Nonaktif'), findsNothing);
  });

  testWidgets('S44: prioritas yang melanggar V-3 ditolak di form H6',
      (tester) async {
    final repo = await bukaH6SebagaiAdmin(tester);
    await tester.tap(find.byKey(const Key('admin-layanan-ktp')));
    await tunggu(tester, find.byKey(const Key('admin-aturan-KTP-R01')));

    await tester.tap(find.byKey(const Key('admin-aturan-KTP-R01')));
    await tunggu(tester, find.byKey(const Key('admin-input-angka')));

    await tester.enterText(find.byKey(const Key('admin-input-angka')), '10');
    await tester.tap(find.byKey(const Key('admin-dialog-simpan')));
    await tunggu(tester, find.text('Penyimpanan ditolak'));

    // Pesan menyebut kode pelanggaran + saran perbaikan (§12.5).
    expect(find.textContaining('V-3'), findsOneWidget);
    expect(find.textContaining('Saran:'), findsOneWidget);

    await tester.tap(find.text('Mengerti'));
    await tenang(tester);

    // Basis pengetahuan lama tetap utuh.
    final kb = await repo.loadService('ktp');
    expect(kb.rules.firstWhere((r) => r.id == 'KTP-R01').priority, 95);
    expect(find.textContaining('prioritas 95'), findsOneWidget);
  });

  testWidgets('S28: teks pertanyaan diubah lewat H6 dan langsung tampil',
      (tester) async {
    final repo = await bukaH6SebagaiAdmin(tester);
    await tester.tap(find.byKey(const Key('admin-layanan-kk')));
    // TabBar hanya ada di halaman kelola → penanda halaman siap.
    await tunggu(tester, find.text('Pertanyaan'));

    await tester.tap(find.text('Pertanyaan'));
    await tenang(tester);
    await tunggu(tester, find.byKey(const Key('admin-pertanyaan-KK-Q01')));

    await tester.tap(find.byKey(const Key('admin-pertanyaan-KK-Q01')));
    await tunggu(tester, find.byKey(const Key('admin-input-teks')));

    await tester.enterText(
      find.byKey(const Key('admin-input-teks')),
      'Bagaimana kondisi Kartu Keluarga Anda sekarang?',
    );
    await tester.tap(find.byKey(const Key('admin-dialog-simpan')));
    await tunggu(
      tester,
      find.text('Bagaimana kondisi Kartu Keluarga Anda sekarang?'),
    );

    final kb = await repo.loadService('kk');
    expect(
      kb.questions.firstWhere((q) => q.id == 'KK-Q01').teks,
      'Bagaimana kondisi Kartu Keluarga Anda sekarang?',
    );
  });

  testWidgets('Menonaktifkan pertanyaan menandainya Nonaktif tetapi tetap tampil',
      (tester) async {
    final repo = await bukaH6SebagaiAdmin(tester);
    await tester.tap(find.byKey(const Key('admin-layanan-kk')));
    await tunggu(tester, find.text('Pertanyaan'));

    await tester.tap(find.text('Pertanyaan'));
    await tenang(tester);
    await tunggu(tester, find.byKey(const Key('admin-aktif-KK-Q01')));

    await tester.tap(find.byKey(const Key('admin-aktif-KK-Q01')));
    await tunggu(tester, find.textContaining('Nonaktif'));

    final kb = await repo.loadService('kk');
    expect(kb.questions.firstWhere((q) => q.id == 'KK-Q01').aktif, isFalse);
  });
}
