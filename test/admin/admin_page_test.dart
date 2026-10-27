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
    await tunggu(tester, find.byKey(const Key('admin-konfirmasi-nonaktif')));
    await tester.tap(find.byKey(const Key('admin-konfirmasi-nonaktif')));
    await tunggu(tester, find.textContaining('Nonaktif'));

    final kb = await repo.loadService('kk');
    expect(kb.questions.firstWhere((q) => q.id == 'KK-Q01').aktif, isFalse);
  });

  // --------------------------------------------- tahap C: create (§12.3 C)

  testWidgets('Tahap C: aturan baru dibuat lewat form H6', (tester) async {
    final repo = await bukaH6SebagaiAdmin(tester);
    await tester.tap(find.byKey(const Key('admin-layanan-ktp')));
    await tunggu(tester, find.byKey(const Key('admin-tambah-aturan')));

    await tester.tap(find.byKey(const Key('admin-tambah-aturan')));
    await tunggu(tester, find.byKey(const Key('admin-input-id')));

    await tester.enterText(find.byKey(const Key('admin-input-id')), 'KTP-R50');
    await tester.enterText(
      find.byKey(const Key('admin-input-prioritas')),
      '94',
    );
    await tester.enterText(
      find.byKey(const Key('admin-input-deskripsi')),
      'Uji aturan baru',
    );
    await tester.enterText(
      find.byKey(const Key('admin-input-nilai')),
      'hilang',
    );
    await tester.tap(find.byKey(const Key('admin-dialog-simpan')));

    // Prioritas 94 menempatkannya di urutan ketiga → terlihat tanpa menggulir.
    await tunggu(tester, find.text('KTP-R50 · prioritas 94'));

    final kb = await repo.loadService('ktp');
    final baru = kb.rules.firstWhere((r) => r.id == 'KTP-R50');
    expect(baru.when.single.fact, 'alasan_pengajuan_ktp');
    expect(baru.when.single.value, 'hilang');
    expect(baru.then.terminal, isFalse);
    expect(baru.aktif, isTrue);
  });

  testWidgets('Tahap C: pertanyaan baru dibuat lewat form H6', (tester) async {
    final repo = await bukaH6SebagaiAdmin(tester);
    await tester.tap(find.byKey(const Key('admin-layanan-kk')));
    await tunggu(tester, find.text('Pertanyaan'));

    await tester.tap(find.text('Pertanyaan'));
    await tenang(tester);
    await tunggu(tester, find.byKey(const Key('admin-tambah-pertanyaan')));

    await tester.tap(find.byKey(const Key('admin-tambah-pertanyaan')));
    await tunggu(tester, find.byKey(const Key('admin-input-factKey')));

    await tester.enterText(find.byKey(const Key('admin-input-id')), 'KK-Q99');
    await tester.enterText(
      find.byKey(const Key('admin-input-factKey')),
      'uji_baru',
    );
    await tester.enterText(
      find.byKey(const Key('admin-input-teks')),
      'Pertanyaan uji?',
    );
    await tester.enterText(find.byKey(const Key('admin-input-urutan')), '5');
    await tester.tap(find.byKey(const Key('admin-dialog-simpan')));

    // Urutan 5 → tampil paling atas, jadi tidak perlu menggulir.
    await tunggu(tester, find.text('Pertanyaan uji?'));

    final kb = await repo.loadService('kk');
    final q = kb.questions.firstWhere((q) => q.id == 'KK-Q99');
    expect(q.opsi.map((o) => o.value).toList(), ['ya', 'tidak']);
    expect(q.urutan, 5);
  });

  // ------------------------------------------ tahap D: nonaktifkan (§12.3 D)

  testWidgets('Tahap D: penonaktifan wajib dikonfirmasi', (tester) async {
    final repo = await bukaH6SebagaiAdmin(tester);
    await tester.tap(find.byKey(const Key('admin-layanan-kk')));
    await tunggu(tester, find.text('Pertanyaan'));

    await tester.tap(find.text('Pertanyaan'));
    await tenang(tester);
    await tunggu(tester, find.byKey(const Key('admin-aktif-KK-Q01')));

    // Batal → tidak ada yang berubah.
    await tester.tap(find.byKey(const Key('admin-aktif-KK-Q01')));
    await tunggu(tester, find.text('Nonaktifkan KK-Q01?'));
    await tester.tap(find.text('Batal'));
    await tenang(tester);

    var kb = await repo.loadService('kk');
    expect(kb.questions.firstWhere((q) => q.id == 'KK-Q01').aktif, isTrue);

    // Konfirmasi → nonaktif.
    await tester.tap(find.byKey(const Key('admin-aktif-KK-Q01')));
    await tunggu(tester, find.byKey(const Key('admin-konfirmasi-nonaktif')));
    await tester.tap(find.byKey(const Key('admin-konfirmasi-nonaktif')));
    await tunggu(tester, find.textContaining('Nonaktif'));

    kb = await repo.loadService('kk');
    expect(kb.questions.firstWhere((q) => q.id == 'KK-Q01').aktif, isFalse);
  });
}
