import 'package:flutter_test/flutter_test.dart';
import 'package:ips_guide/data/repositories/in_memory_knowledge_base_repository.dart';
import 'package:ips_guide/data/repositories/knowledge_base_repository.dart';
import 'package:ips_guide/data/seed/seed_loader.dart';
import 'package:ips_guide/domain/entities/knowledge_base.dart';
import 'package:ips_guide/domain/engine/guidance_session.dart';

/// Uji jalur simpan H6 (§12.5, S28, S33, S44).
///
/// Repository dibangun ulang dari `SeedData` yang sama untuk setiap uji agar
/// perubahan satu uji tidak bocor ke uji lain.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SeedData seed;
  late InMemoryKnowledgeBaseRepository repo;

  setUpAll(() async {
    seed = await SeedLoader.load();
  });

  setUp(() {
    repo = InMemoryKnowledgeBaseRepository.fromMaps(seed);
  });

  /// Jawaban jalur S03 (KTP baru di Tegalsari).
  GuidanceSession sesiKtp(KnowledgeBase kb) {
    const jawaban = {
      'kategori_usia': '17_ke_atas',
      'sudah_punya_ktp': 'tidak',
      'domisili_pemohon': 'tegalsari',
    };
    final sesi = GuidanceSession(kb);
    while (sesi.currentQuestion != null) {
      final q = sesi.currentQuestion!;
      final nilai = jawaban[q.factKey];
      if (nilai == null) break;
      sesi.answer(q.factKey, nilai);
    }
    return sesi;
  }

  test('S28: nama persyaratan yang diubah tampil pada sesi berikutnya', () async {
    final kbAwal = await repo.loadService('ktp');
    final akta = kbAwal.requirements.firstWhere(
      (r) => r.nama == 'Akta kelahiran',
    );

    await repo.simpanPersyaratan(akta.copyWith(nama: 'Akta kelahiran (revisi)'));

    // Basis pengetahuan baru dipakai sesi berikutnya.
    final kbBaru = await repo.loadService('ktp');
    expect(kbBaru.requirementById(akta.id)!.nama, 'Akta kelahiran (revisi)');

    final hasil = sesiKtp(kbBaru).buildResult();
    expect(
      hasil.requirements.map((r) => r.nama),
      contains('Akta kelahiran (revisi)'),
    );
  });

  test('S33: seluruh aturan KTP dinonaktifkan → outcome null, KK tidak terpengaruh',
      () async {
    final kb = await repo.loadService('ktp');
    for (final r in kb.rules) {
      await repo.simpanAturan('ktp', r.copyWith(aktif: false));
    }

    final kbKtp = await repo.loadService('ktp');
    expect(kbKtp.rules.where((r) => r.aktif), isEmpty);

    final hasil = sesiKtp(kbKtp).buildResult();
    expect(hasil.outcome, isNull, reason: 'Tidak ada aturan yang menyala');
    expect(hasil.tampilkanDetail, isFalse);

    // Layanan lain tidak terpengaruh.
    final kbKk = await repo.loadService('kk');
    expect(kbKk.rules.where((r) => r.aktif).length, kbKk.rules.length);
  });

  test('S44: aturan terminal berprioritas rendah ditolak, basis pengetahuan utuh',
      () async {
    final kbAwal = await repo.loadService('ktp');
    final r01 = kbAwal.rules.firstWhere((r) => r.id == 'KTP-R01');
    expect(r01.priority, 95);

    await expectLater(
      repo.simpanAturan('ktp', r01.copyWith(priority: 10)),
      throwsA(
        isA<KnowledgeBaseException>().having(
          (e) => e.errors.join(' '),
          'errors',
          contains('V-3'),
        ),
      ),
    );

    // S44: basis pengetahuan lama tetap utuh.
    final kbAkhir = await repo.loadService('ktp');
    expect(kbAkhir.rules.firstWhere((r) => r.id == 'KTP-R01').priority, 95);
    expect(repo.validationErrors, isEmpty);
  });

  test('Ubah teks pertanyaan tersimpan dan factKey tidak berubah', () async {
    final kb = await repo.loadService('kk');
    final q01 = kb.questions.firstWhere((q) => q.id == 'KK-Q01');

    await repo.simpanPertanyaan(
      'kk',
      q01.copyWith(teks: 'Bagaimana kondisi Kartu Keluarga Anda sekarang?'),
    );

    final baru = await repo.loadService('kk');
    final qBaru = baru.questions.firstWhere((q) => q.id == 'KK-Q01');
    expect(qBaru.teks, 'Bagaimana kondisi Kartu Keluarga Anda sekarang?');
    expect(qBaru.factKey, q01.factKey);
  });

  test('Aturan tak dikenal ditolak', () async {
    final kb = await repo.loadService('ktp');
    final asing = kb.rules.first.copyWith();
    await expectLater(
      repo.simpanAturan('domisili', asing),
      throwsA(isA<KnowledgeBaseException>()),
    );
  });
}
