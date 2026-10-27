import 'package:flutter_test/flutter_test.dart';
import 'package:ips_guide/data/repositories/in_memory_knowledge_base_repository.dart';
import 'package:ips_guide/data/repositories/knowledge_base_repository.dart';
import 'package:ips_guide/data/seed/seed_loader.dart';
import 'package:ips_guide/domain/entities/answer_option.dart';
import 'package:ips_guide/domain/entities/guidance_question.dart';
import 'package:ips_guide/domain/entities/knowledge_base.dart';
import 'package:ips_guide/domain/entities/rule.dart';
import 'package:ips_guide/domain/entities/rule_action.dart';
import 'package:ips_guide/domain/entities/rule_condition.dart';
import 'package:ips_guide/domain/engine/guidance_session.dart';

/// Uji jalur simpan H6 (§12.5, S28, S33, S44) dan tahap C/D (§12.3).
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

  // ------------------------------------------------------- tahap C: create

  test('Tahap C: aturan baru langsung dipakai sesi berikutnya', () async {
    // Non-terminal & berprioritas di bawah aturan terminal terkecil (95),
    // agar tidak melanggar V-3.
    await repo.tambahAturan(
      'ktp',
      const Rule(
        id: 'KTP-R50',
        serviceId: 'ktp',
        priority: 50,
        deskripsi: 'Uji: pemohon belum punya KTP',
        when: [RuleCondition(fact: 'sudah_punya_ktp', value: 'tidak')],
        then: RuleAction(addNotes: ['Catatan uji']),
      ),
    );

    final kb = await repo.loadService('ktp');
    expect(kb.rules.any((r) => r.id == 'KTP-R50'), isTrue);

    // Aturan yang baru dibuat ikut menyala tanpa mengubah kode apa pun.
    final hasil = sesiKtp(kb).buildResult();
    expect(hasil.notes.map((n) => n.teks), contains('Catatan uji'));
    expect(
      hasil.trace.firstWhere((t) => t.ruleId == 'KTP-R50').addNotes,
      contains('Catatan uji'),
    );
    expect(repo.validationErrors, isEmpty);
  });

  test('Tahap C: ID aturan duplikat ditolak tanpa mengubah data', () async {
    final kb = await repo.loadService('ktp');
    final r01 = kb.rules.firstWhere((r) => r.id == 'KTP-R01');

    await expectLater(
      repo.tambahAturan('ktp', r01),
      throwsA(
        isA<KnowledgeBaseException>().having(
          (e) => e.message,
          'message',
          contains('sudah ada'),
        ),
      ),
    );

    final akhir = await repo.loadService('ktp');
    expect(akhir.rules.where((r) => r.id == 'KTP-R01').length, 1);
  });

  test('Tahap C: aturan terminal tanpa outcome ditolak (V-1)', () async {
    await expectLater(
      repo.tambahAturan(
        'ktp',
        const Rule(
          id: 'KTP-R60',
          serviceId: 'ktp',
          priority: 100,
          deskripsi: 'Terminal tanpa outcome',
          when: [RuleCondition(fact: 'sudah_punya_ktp', value: 'tidak')],
          then: RuleAction(terminal: true),
        ),
      ),
      throwsA(
        isA<KnowledgeBaseException>().having(
          (e) => e.errors.join(' '),
          'errors',
          contains('V-1'),
        ),
      ),
    );

    // Basis pengetahuan lama tetap utuh — aturan yang ditolak tidak tersisa.
    final kb = await repo.loadService('ktp');
    expect(kb.rules.any((r) => r.id == 'KTP-R60'), isFalse);
    expect(repo.validationErrors, isEmpty);
  });

  test('Tahap C: pertanyaan baru tersimpan; factKey duplikat ditolak', () async {
    const pertanyaan = GuidanceQuestion(
      id: 'KK-Q99',
      serviceId: 'kk',
      factKey: 'uji_baru',
      teks: 'Pertanyaan uji?',
      urutan: 90,
      opsi: [
        AnswerOption(value: 'ya', label: 'Ya'),
        AnswerOption(value: 'tidak', label: 'Tidak'),
      ],
    );

    await repo.tambahPertanyaan('kk', pertanyaan);
    final kb = await repo.loadService('kk');
    expect(kb.questions.any((q) => q.id == 'KK-Q99'), isTrue);

    // factKey wajib unik dalam satu layanan (§10.4.1 poin 6).
    await expectLater(
      repo.tambahPertanyaan(
        'kk',
        const GuidanceQuestion(
          id: 'KK-Q98',
          serviceId: 'kk',
          factKey: 'kondisi_kk',
          teks: 'Duplikat factKey?',
          urutan: 91,
          opsi: [
            AnswerOption(value: 'ya', label: 'Ya'),
            AnswerOption(value: 'tidak', label: 'Tidak'),
          ],
        ),
      ),
      throwsA(
        isA<KnowledgeBaseException>().having(
          (e) => e.message,
          'message',
          contains('factKey'),
        ),
      ),
    );

    final akhir = await repo.loadService('kk');
    expect(akhir.questions.any((q) => q.id == 'KK-Q98'), isFalse);
    expect(akhir.questions.where((q) => q.factKey == 'kondisi_kk').length, 1);
  });

  // ------------------------------------------------- tahap D: nonaktifkan

  test('Tahap D: nonaktifkan aturan penentu → panduan belum tersedia',
      () async {
    final kbAwal = await repo.loadService('domisili');
    final r01 = kbAwal.rules.firstWhere((r) => r.id == 'DOM-R01');
    await repo.simpanAturan('domisili', r01.copyWith(aktif: false));

    final kb = await repo.loadService('domisili');
    // Dokumen nonaktif TETAP ada di basis pengetahuan (§12.4) …
    expect(kb.rules.any((r) => r.id == 'DOM-R01' && !r.aktif), isTrue);
  });
}
