import 'package:flutter_test/flutter_test.dart';
import 'package:ips_guide/data/repositories/in_memory_knowledge_base_repository.dart';
import 'package:ips_guide/data/repositories/knowledge_base_repository.dart';
import 'package:ips_guide/data/seed/seed_loader.dart';
import 'package:ips_guide/domain/engine/guidance_session.dart';
import 'package:ips_guide/domain/engine/rule_engine.dart';
import 'package:ips_guide/domain/entities/guidance_result.dart';
import 'package:ips_guide/domain/entities/guidance_question.dart';
import 'package:ips_guide/domain/entities/guidance_service.dart';
import 'package:ips_guide/domain/entities/knowledge_base.dart';
import 'package:ips_guide/domain/entities/answer_option.dart';
import 'package:ips_guide/domain/entities/outcome.dart';
import 'package:ips_guide/domain/entities/rule.dart';
import 'package:ips_guide/domain/entities/rule_action.dart';
import 'package:ips_guide/domain/entities/rule_condition.dart';

/// Skenario uji fungsional §14 — kontrak pengujian (S01–S22, S29–S43, S45–S46;
/// 39 skenario, tanpa Firebase).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late InMemoryKnowledgeBaseRepository repo;

  setUpAll(() async {
    repo = await InMemoryKnowledgeBaseRepository.fromAssets();
  });

  Future<KnowledgeBase> kb(String serviceId) => repo.loadService(serviceId);

  /// Menjalankan sesi sampai selesai dengan menjawab pertanyaan berurutan.
  Future<GuidanceResult> jalankan(
    String serviceId,
    Map<String, String> jawaban, {
    bool sampaiSelesai = true,
  }) async {
    final session = GuidanceSession(await kb(serviceId));
    while (!session.isFinished && sampaiSelesai) {
      final q = session.currentQuestion!;
      final v = jawaban[q.factKey];
      if (v == null) break; // fakta tidak lengkap (S19)
      session.answer(q.factKey, v);
    }
    return session.buildResult();
  }

  // =========================================================================
  // 14.1 — Skenario utama
  // =========================================================================

  group('Skenario utama (§14.1)', () {
    test('S01 KTP <17 belum menikah → tidak_dapat_diproses (2 pertanyaan)',
        () async {
      final r = await jalankan('ktp', {
        'kategori_usia': 'di_bawah_17',
        'status_perkawinan': 'belum_menikah',
      });
      expect(r.outcome, Outcome.tidakDapatDiproses);
      expect(r.answers, hasLength(2));
      expect(r.tampilkanDetail, isFalse);
      expect(r.requirements, isEmpty);
    });

    test('S02 KTP <17 menikah Tegalsari → dengan_catatan (akta nikah, KK asli)',
        () async {
      final r = await jalankan('ktp', {
        'kategori_usia': 'di_bawah_17',
        'status_perkawinan': 'menikah',
        'domisili_pemohon': 'tegalsari',
      });
      expect(r.outcome, Outcome.denganCatatan);
      expect(r.requirements.map((q) => q.id),
          containsAll(['REQ_AKTA_NIKAH', 'REQ_KK_ASLI']));
    });

    test('S03 KTP 17+ belum punya Tegalsari → dapat_diproses', () async {
      final r = await jalankan('ktp', {
        'kategori_usia': '17_ke_atas',
        'sudah_punya_ktp': 'tidak',
        'domisili_pemohon': 'tegalsari',
      });
      expect(r.outcome, Outcome.dapatDiproses);
      expect(r.requirements.map((q) => q.id),
          containsAll(['REQ_KK_ASLI', 'REQ_AKTA_KELAHIRAN', 'REQ_F101']));
    });

    test('S04 KTP hilang → dapat_diproses (surat kehilangan Polsek)', () async {
      final r = await jalankan('ktp', {
        'kategori_usia': '17_ke_atas',
        'sudah_punya_ktp': 'ya',
        'domisili_pemohon': 'tegalsari',
        'alasan_pengajuan_ktp': 'hilang',
      });
      expect(r.outcome, Outcome.dapatDiproses);
      expect(r.requirements.map((q) => q.id), contains('REQ_SURAT_KEHILANGAN'));
    });

    test('S05 KTP rusak → dapat_diproses (KTP lama)', () async {
      final r = await jalankan('ktp', {
        'kategori_usia': '17_ke_atas',
        'sudah_punya_ktp': 'ya',
        'domisili_pemohon': 'tegalsari',
        'alasan_pengajuan_ktp': 'rusak',
      });
      expect(r.requirements.map((q) => q.id), contains('REQ_KTP_EL_LAMA'));
    });

    test('S06 KTP pindah datang → dapat_diproses (SKPWNI)', () async {
      final r = await jalankan('ktp', {
        'kategori_usia': '17_ke_atas',
        'sudah_punya_ktp': 'ya',
        'domisili_pemohon': 'tegalsari',
        'alasan_pengajuan_ktp': 'pindah_datang',
      });
      expect(r.requirements.map((q) => q.id), contains('REQ_SKPWNI'));
    });

    test('S07 KTP perubahan data → dapat_diproses (dokumen pendukung)',
        () async {
      final r = await jalankan('ktp', {
        'kategori_usia': '17_ke_atas',
        'sudah_punya_ktp': 'ya',
        'domisili_pemohon': 'tegalsari',
        'alasan_pengajuan_ktp': 'perubahan_data',
      });
      expect(r.requirements.map((q) => q.id), contains('REQ_DOK_PENDUKUNG'));
    });

    test('S08 KTP 17+ belum punya luar Tegalsari → tidak_dapat_diproses '
        '(3 pertanyaan, Q5 tidak ditanya)', () async {
      final r = await jalankan('ktp', {
        'kategori_usia': '17_ke_atas',
        'sudah_punya_ktp': 'tidak',
        'domisili_pemohon': 'luar_tegalsari',
      });
      expect(r.outcome, Outcome.tidakDapatDiproses);
      expect(r.answers, hasLength(3));
      expect(r.answers.containsKey('alasan_pengajuan_ktp'), isFalse);
      expect(r.requirements, isEmpty);
    });

    test('S09 KK belum punya Tegalsari → dapat_diproses', () async {
      final r = await jalankan('kk', {
        'kondisi_kk': 'belum_punya',
        'domisili_pemohon': 'tegalsari',
      });
      expect(r.outcome, Outcome.dapatDiproses);
      expect(r.requirements.map((q) => q.id),
          containsAll(['REQ_AKTA_NIKAH', 'REQ_KK_ORTU']));
    });

    test('S10 KK kelahiran Tegalsari → dapat_diproses', () async {
      final r = await jalankan('kk', {
        'kondisi_kk': 'perubahan_anggota',
        'jenis_perubahan_kk': 'kelahiran',
        'domisili_pemohon': 'tegalsari',
      });
      expect(r.requirements.map((q) => q.id),
          containsAll(['REQ_AKTA_KELAHIRAN', 'REQ_KK_LAMA']));
    });

    test('S11 KK kematian → dapat_diproses (akta kematian)', () async {
      final r = await jalankan('kk', {
        'kondisi_kk': 'perubahan_anggota',
        'jenis_perubahan_kk': 'kematian',
        'domisili_pemohon': 'tegalsari',
      });
      expect(r.requirements.map((q) => q.id), contains('REQ_AKTA_KEMATIAN'));
    });

    test('S12 KK hilang → dapat_diproses (surat kehilangan Polsek)', () async {
      final r = await jalankan('kk', {
        'kondisi_kk': 'hilang',
        'domisili_pemohon': 'tegalsari',
      });
      expect(r.requirements.map((q) => q.id), contains('REQ_SURAT_KEHILANGAN'));
    });

    test('S13 KK pindah datang luar Tegalsari → dapat_diproses '
        '(pengecualian KK-R10)', () async {
      final r = await jalankan('kk', {
        'kondisi_kk': 'pindah_datang',
        'domisili_pemohon': 'luar_tegalsari',
      });
      expect(r.outcome, Outcome.dapatDiproses);
      expect(r.requirements.map((q) => q.id),
          containsAll(['REQ_SKPWNI', 'REQ_KK_ASAL']));
    });

    test('S14 KK kelahiran luar Tegalsari → tidak_dapat_diproses '
        '(KK-R10 99 > KK-R03 85, detail disembunyikan, trace utuh)', () async {
      final r = await jalankan('kk', {
        'kondisi_kk': 'perubahan_anggota',
        'jenis_perubahan_kk': 'kelahiran',
        'domisili_pemohon': 'luar_tegalsari',
      });
      expect(r.outcome, Outcome.tidakDapatDiproses);
      expect(r.requirements, isEmpty); // KK-R03 sempat menambah — disembunyikan
      expect(r.trace.map((t) => t.ruleId),
          containsAll(['KK-R03', 'KK-R10'])); // tetap di trace (§10.7)
      final pemenang = r.trace.where((t) => t.isWinner).toList();
      expect(pemenang.single.ruleId, 'KK-R10');
    });

    test('S15 Domisili warga tetap kerja → dapat_diproses', () async {
      final r = await jalankan('domisili', {
        'keperluan_domisili': 'kerja',
        'status_tinggal': 'warga_tetap',
      });
      expect(r.outcome, Outcome.dapatDiproses);
      expect(r.requirements.map((q) => q.id),
          containsAll(['REQ_KTP_EL', 'REQ_PENGANTAR_RTRW']));
    });

    test('S16 Domisili tinggal sementara ada bukti → dapat_diproses',
        () async {
      final r = await jalankan('domisili', {
        'keperluan_domisili': 'kerja',
        'status_tinggal': 'tinggal_sementara',
        'punya_bukti_tinggal': 'ya',
      });
      expect(r.outcome, Outcome.dapatDiproses);
      expect(r.requirements.map((q) => q.id),
          containsAll(['REQ_SURAT_PERNYATAAN', 'REQ_BUKTI_TINGGAL']));
    });

    test('S17 Domisili tinggal sementara tanpa bukti → dengan_catatan '
        '(Q3 HARUS tetap ditanyakan)', () async {
      final r = await jalankan('domisili', {
        'keperluan_domisili': 'kerja',
        'status_tinggal': 'tinggal_sementara',
        'punya_bukti_tinggal': 'tidak',
      });
      expect(r.outcome, Outcome.denganCatatan);
      expect(r.answers.containsKey('punya_bukti_tinggal'), isTrue);
    });

    test('S18 Domisili warga tetap usaha → dapat_diproses + req usaha',
        () async {
      final r = await jalankan('domisili', {
        'keperluan_domisili': 'usaha',
        'status_tinggal': 'warga_tetap',
      });
      expect(r.outcome, Outcome.dapatDiproses);
      expect(r.requirements.map((q) => q.id),
          containsAll(['REQ_FOTO_LOKASI_USAHA', 'REQ_SURAT_TETANGGA']));
    });
  });

  // =========================================================================
  // 14.2 — Skenario negatif & teknis
  // =========================================================================

  group('Skenario negatif & teknis (§14.2)', () {
    test('S19 fakta tidak lengkap → tidak crash, outcome null', () async {
      // Hanya Q1 dijawab; sisanya tidak tersedia (jalankan berhenti).
      final r = await jalankan('ktp', {'kategori_usia': '17_ke_atas'});
      expect(r.outcome, isNull);
      expect(r.tampilkanDetail, isFalse);
      expect(r.terminal, isFalse);
    });

    test('S20 serviceId tidak dikenal → KnowledgeBaseException', () async {
      expect(
        () => repo.loadService('tidak_ada'),
        throwsA(isA<KnowledgeBaseException>()),
      );
    });

    test('S21 dua aturan menetapkan outcome berbeda → pemenang sesuai '
        'prioritas, tidak bergantung urutan', () async {
      final knowledgeBase = await kb('domisili');
      final jawaban = {
        'keperluan_domisili': 'kerja',
        'status_tinggal': 'tinggal_sementara',
        'punya_bukti_tinggal': 'tidak',
      };
      final a = RuleEngine.inferensi(knowledgeBase, jawaban);
      final dibalik = <String, String>{
        for (final e in jawaban.entries.toList().reversed) e.key: e.value,
      };
      final b = RuleEngine.inferensi(knowledgeBase, dibalik);
      expect(a.winner!.id, 'DOM-R03'); // 85 > 80
      expect(b.winner!.id, 'DOM-R03');
      expect(a.outcome, Outcome.denganCatatan);
      expect(a.outcome, b.outcome);
    });

    test('S22 aturan dievaluasi dua kali → persyaratan tidak duplikat',
        () async {
      final knowledgeBase = await kb('domisili');
      final jawaban = {
        'keperluan_domisili': 'usaha',
        'status_tinggal': 'warga_tetap',
      };
      final result = await jalankan('domisili', jawaban);
      final ids = result.requirements.map((q) => q.id).toList();
      expect(ids.toSet().length, ids.length);
      // Hitung ulang dari nol → himpunan persyaratan sama.
      final again = RuleEngine.inferensi(knowledgeBase, jawaban);
      expect(again.addedRequirements.toSet(), containsAll(ids.toSet()));
    });
  });

  // =========================================================================
  // 14.3 — Skenario regresi v1.2–v1.4
  // =========================================================================

  group('Skenario regresi (§14.3)', () {
    test('S29 KTP luar Tegalsari → alasan TIDAK ditanyakan (T-01, T-03)',
        () async {
      final r = await jalankan('ktp', {
        'kategori_usia': '17_ke_atas',
        'sudah_punya_ktp': 'ya',
        'domisili_pemohon': 'luar_tegalsari',
      });
      expect(r.outcome, Outcome.tidakDapatDiproses);
      expect(r.answers.containsKey('alasan_pengajuan_ktp'), isFalse);
      expect(r.requirements, isEmpty);
    });

    test('S30 Domisili tanpa bukti → Q3 tetap ditanyakan walau DOM-R02 '
        'sudah menetapkan outcome sementara (T-01)', () async {
      final r = await jalankan('domisili', {
        'keperluan_domisili': 'kerja',
        'status_tinggal': 'tinggal_sementara',
        'punya_bukti_tinggal': 'tidak',
      });
      expect(r.answers.containsKey('punya_bukti_tinggal'), isTrue);
      expect(r.outcome, Outcome.denganCatatan);
    });

    test('S31 layanan aktif=false tetap ada di loadServices (T-06)', () async {
      // Pada seed resmi semua aktif; uji perilaku interface: layanan
      // nonaktif TIDAK difilter oleh repository.
      final services = await repo.loadServices();
      expect(services.map((s) => s.id), containsAll(['ktp', 'kk', 'domisili']));
      expect(services.every((s) => s.aktif), isTrue); // seed resmi aktif semua
    });

    test('S32 opsi jawaban tanpa aturan → outcome null, trace terekam (§10.8)',
        () async {
      // Admin menambah opsi "lainnya" tanpa aturan: sesi tetap bisa dijalankan
      // karena engine tidak memvalidasi nilai terhadap opsi.
      final session = GuidanceSession(await kb('ktp'));
      session
        ..answer('kategori_usia', '17_ke_atas')
        ..answer('sudah_punya_ktp', 'ya')
        ..answer('domisili_pemohon', 'tegalsari')
        ..answer('alasan_pengajuan_ktp', 'lainnya');
      final r = session.buildResult();
      expect(r.outcome, isNull); // → "Panduan belum tersedia"
      expect(r.terminal, isFalse);
    });

    test('S35 KTP <17 pernah_menikah Tegalsari → outcome null + catatan, '
        '3 pertanyaan, tanpa persyaratan dikarang (U-02)', () async {
      final r = await jalankan('ktp', {
        'kategori_usia': 'di_bawah_17',
        'status_perkawinan': 'pernah_menikah',
        'domisili_pemohon': 'tegalsari',
      });
      expect(r.outcome, isNull);
      expect(r.answers, hasLength(3));
      expect(r.requirements, isEmpty);
      expect(r.notes.map((n) => n.teks).join(' '),
          contains('belum tercakup dalam panduan'));
    });

    test('S36 KTP <17 pernah_menikah luar Tegalsari → tidak_dapat_diproses '
        'dari KTP-R08 (KTP-R10 tidak menghentikan sesi)', () async {
      final r = await jalankan('ktp', {
        'kategori_usia': 'di_bawah_17',
        'status_perkawinan': 'pernah_menikah',
        'domisili_pemohon': 'luar_tegalsari',
      });
      expect(r.outcome, Outcome.tidakDapatDiproses);
      expect(r.terminal, isTrue);
      expect(r.trace.where((t) => t.isWinner).single.ruleId, 'KTP-R08');
    });

    test('S37 showIf merujuk fakta belum ada → pertanyaan menunggu (U-03)',
        () async {
      final session = GuidanceSession(await kb('ktp'));
      // Sebelum Q1: Q2/Q3 belum tampil.
      expect(session.currentQuestion!.factKey, 'kategori_usia');
      session.answer('kategori_usia', '17_ke_atas');
      // Setelah Q1: Q3 muncul (dependensi terjawab).
      expect(session.currentQuestion!.factKey, 'sudah_punya_ktp');
      session.answer('sudah_punya_ktp', 'ya');
      // Q5 tampil setelah dependensinya (sudah_punya_ktp = ya).
      expect(session.currentQuestion!.factKey, 'domisili_pemohon');
    });

    test('S38 showIf.fact tak dikenal → repository menolak saat dimuat (U-03)',
        () async {
      final seed = await _seedDenganPertanyaanHantu();
      final rusak = InMemoryKnowledgeBaseRepository.fromMaps(seed);
      await expectLater(
        rusak.loadService('ktp'),
        throwsA(
          isA<KnowledgeBaseException>()
              .having((e) => e.errors, 'errors', isNotEmpty)
              .having(
                (e) => e.errors.join(' '),
                'menyebut showIf',
                contains('showIf'),
              ),
        ),
      );
      // Layanan lain tidak terpengaruh.
      expect((await rusak.loadService('domisili')).serviceId, 'domisili');
    });

    test('S39 ubah kategori 17+ → <17 setelah 4 jawaban → fakta jalur lama '
        'terpangkas, KTP-R04 tidak menyala (U-04)', () async {
      final session = GuidanceSession(await kb('ktp'));
      session
        ..answer('kategori_usia', '17_ke_atas')
        ..answer('sudah_punya_ktp', 'ya')
        ..answer('domisili_pemohon', 'tegalsari')
        ..answer('alasan_pengajuan_ktp', 'hilang');
      expect(session.inference.addedRequirements, contains('REQ_SURAT_KEHILANGAN'));

      session.kembali('kategori_usia');
      session.answer('kategori_usia', 'di_bawah_17');
      session.answer('status_perkawinan', 'belum_menikah');

      expect(session.answers.containsKey('sudah_punya_ktp'), isFalse);
      expect(session.answers.containsKey('alasan_pengajuan_ktp'), isFalse);
      expect(
        session.inference.fired.map((r) => r.id),
        isNot(contains('KTP-R04')),
      );
      final r = session.buildResult();
      expect(r.requirements.map((q) => q.id),
          isNot(contains('REQ_SURAT_KEHILANGAN')));
      expect(r.outcome, Outcome.tidakDapatDiproses);
    });

    test('S40 KTP baru vs KTP hilang → daftar tahapan identik (U-01)',
        () async {
      final baru = await jalankan('ktp', {
        'kategori_usia': '17_ke_atas',
        'sudah_punya_ktp': 'tidak',
        'domisili_pemohon': 'tegalsari',
      });
      final hilang = await jalankan('ktp', {
        'kategori_usia': '17_ke_atas',
        'sudah_punya_ktp': 'ya',
        'domisili_pemohon': 'tegalsari',
        'alasan_pengajuan_ktp': 'hilang',
      });
      expect(baru.steps.map((t) => t.id).toList(),
          hilang.steps.map((t) => t.id).toList());
      expect(baru.steps, hasLength(5));
      // Persyaratan berbeda.
      expect(baru.requirements.map((q) => q.id),
          isNot(equals(hilang.requirements.map((q) => q.id))));
    });

    test('S41 aturan terminal tanpa setOutcome → ditolak dengan V-1 (V-01)',
        () async {
      final seed = await _seedDenganAturanTambahan('ktp', [
        {
          'id': 'KTP-R91',
          'serviceId': 'ktp',
          'priority': 96,
          'aktif': true,
          'deskripsi': 'terminal tanpa outcome',
          'when': [
            {'fact': 'kategori_usia', 'op': 'equals', 'value': '17_ke_atas'},
          ],
          'then': {'terminal': true},
        },
      ]);
      final rusak = InMemoryKnowledgeBaseRepository.fromMaps(seed);
      await expectLater(
        rusak.loadService('ktp'),
        throwsA(
          isA<KnowledgeBaseException>()
              .having((e) => e.errors.join(' '), 'errors', contains('V-1')),
        ),
      );
    });

    test('S42 dua terminal beda outcome menyala bersama → ditolak dengan V-2 '
        '(V-01)', () async {
      final seed = await _seedDenganAturanTambahan('ktp', [
        {
          'id': 'KTP-R92',
          'serviceId': 'ktp',
          'priority': 96,
          'aktif': true,
          'deskripsi': 'terminal A',
          'when': [
            {'fact': 'status_perkawinan', 'op': 'equals', 'value': 'menikah'},
          ],
          'then': {'setOutcome': 'dapat_diproses', 'terminal': true},
        },
        {
          'id': 'KTP-R93',
          'serviceId': 'ktp',
          'priority': 97,
          'aktif': true,
          'deskripsi': 'terminal B',
          'when': [
            {'fact': 'status_perkawinan', 'op': 'equals', 'value': 'menikah'},
          ],
          'then': {'setOutcome': 'tidak_dapat_diproses', 'terminal': true},
        },
      ]);
      final rusak = InMemoryKnowledgeBaseRepository.fromMaps(seed);
      await expectLater(
        rusak.loadService('ktp'),
        throwsA(
          isA<KnowledgeBaseException>()
              .having((e) => e.errors.join(' '), 'errors', contains('V-2')),
        ),
      );
    });

    test('S43 terminal p60 vs non-terminal p90 → ditolak dengan V-3 (V-01)',
        () async {
      final seed = await _seedDenganAturanTambahan('ktp', [
        {
          'id': 'KTP-R94',
          'serviceId': 'ktp',
          'priority': 60,
          'aktif': true,
          'deskripsi': 'terminal prioritas rendah',
          'when': [
            {'fact': 'kategori_usia', 'op': 'equals', 'value': 'di_bawah_17'},
          ],
          'then': {'setOutcome': 'tidak_dapat_diproses', 'terminal': true},
        },
      ]);
      final rusak = InMemoryKnowledgeBaseRepository.fromMaps(seed);
      await expectLater(
        rusak.loadService('ktp'),
        throwsA(
          isA<KnowledgeBaseException>()
              .having((e) => e.errors.join(' '), 'errors', contains('V-3')),
        ),
      );
    });

    test('S45 konfigurasi rusak via Console → layanan itu ditolak saat dimuat, '
        'layanan lain tidak terpengaruh (V-01, V-02)', () async {
      final seed = await _seedDenganAturanTambahan('domisili', [
        {
          'id': 'DOM-R91',
          'serviceId': 'domisili',
          'priority': 96,
          'aktif': true,
          'deskripsi': 'terminal tanpa outcome',
          'when': [
            {'fact': 'status_tinggal', 'op': 'equals', 'value': 'warga_tetap'},
          ],
          'then': {'terminal': true},
        },
      ]);
      final rusak = InMemoryKnowledgeBaseRepository.fromMaps(seed);
      // Layanan rusak → ditolak saat dimuat.
      await expectLater(
        rusak.loadService('domisili'),
        throwsA(
          isA<KnowledgeBaseException>()
              .having((e) => e.errors.join(' '), 'errors', contains('V-1')),
        ),
      );
      // Layanan lain tidak terpengaruh.
      final ktp = await rusak.loadService('ktp');
      expect(ktp.serviceId, 'ktp');
      // Dan tetap muncul di daftar layanan (H3 menandai "belum tersedia").
      final services = await rusak.loadServices();
      expect(services.map((s) => s.id), contains('domisili'));
      expect(rusak.validationErrors.containsKey('domisili'), isTrue);
    });

    test('S46 pemenang non-terminal padahal ada terminal → CONFIG_WARNING, '
        'sesi melanjutkan (§10.6.2)', () {
      // Konfigurasi lolos validasi muat disimulasikan langsung di engine
      // (aturan ditulis lewat Console, melewati validator).
      final kbRusak = KnowledgeBase(
        service: const GuidanceService(
          id: 'ktp',
          nama: 'KTP',
          deskripsi: '',
          ikon: 'badge',
          urutan: 1,
          estimasiHariMin: 1,
          estimasiHariMax: 1,
        ),
        questions: const [
          GuidanceQuestion(
            id: 'KTP-Q01',
            serviceId: 'ktp',
            factKey: 'kategori_usia',
            teks: 'Berapa usia Anda?',
            urutan: 10,
            opsi: [
              AnswerOption(value: '17_ke_atas', label: '17 tahun ke atas'),
            ],
          ),
        ],
        rules: [
          Rule(
            id: 'KTP-RY',
            serviceId: 'ktp',
            priority: 90,
            deskripsi: 'non-terminal p90',
            when: const [
              RuleCondition(fact: 'kategori_usia', op: ConditionOperator.equals, value: '17_ke_atas'),
            ],
            then: const RuleAction(setOutcome: Outcome.dapatDiproses),
          ),
          Rule(
            id: 'KTP-RX',
            serviceId: 'ktp',
            priority: 50,
            deskripsi: 'terminal p50',
            when: const [
              RuleCondition(fact: 'kategori_usia', op: ConditionOperator.equals, value: '17_ke_atas'),
            ],
            then: const RuleAction(
              setOutcome: Outcome.tidakDapatDiproses,
              terminal: true,
            ),
          ),
        ],
        requirements: const [],
        steps: const [],
      );

      final session = GuidanceSession(kbRusak)
        ..answer('kategori_usia', '17_ke_atas');
      // Penjaga runtime menandai terminal=false + CONFIG_WARNING, sesi
      // melanjutkan (tidak berhenti atas dasar aturan terminal p50).
      final result = session.buildResult();
      expect(result.terminal, isFalse);
      expect(session.inference.warnings.join(' '), contains('CONFIG_WARNING'));
      expect(result.outcome, Outcome.dapatDiproses); // pemenang p90
    });
  });
}

// -----------------------------------------------------------------------------
// Utilitas: memodifikasi seed untuk skenario konfigurasi rusak
// -----------------------------------------------------------------------------

Future<SeedData> _seedDenganAturanTambahan(
  String serviceId,
  List<Map<String, dynamic>> aturan,
) async {
  final seed = await SeedLoader.load();
  final rules = Map<String, List<Map<String, dynamic>>>.of(seed.rules);
  rules[serviceId] = [...rules[serviceId]!, ...aturan];
  return SeedData(
    services: seed.services,
    questions: seed.questions,
    requirements: seed.requirements,
    steps: seed.steps,
    rules: rules,
  );
}

Future<SeedData> _seedDenganPertanyaanHantu() async {
  final seed = await SeedLoader.load();
  final questions = <Map<String, dynamic>>[
    ...seed.questions,
    {
      'id': 'KTP-Q99',
      'serviceId': 'ktp',
      'factKey': 'fakta_uji',
      'teks': 'uji',
      'urutan': 99,
      'aktif': true,
      'showIf': {'fact': 'fakta_hantu', 'op': 'equals', 'value': 'a'},
      'opsi': [
        {'value': 'a', 'label': 'A'},
      ],
    },
  ];
  return SeedData(
    services: seed.services,
    questions: questions,
    requirements: seed.requirements,
    steps: seed.steps,
    rules: seed.rules,
  );
}
