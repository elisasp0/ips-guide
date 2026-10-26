import 'package:flutter_test/flutter_test.dart';
import 'package:ips_guide/domain/engine/rule_engine.dart';
import 'package:ips_guide/domain/entities/knowledge_base.dart';
import 'package:ips_guide/domain/entities/outcome.dart';
import 'package:ips_guide/domain/entities/rule.dart';
import 'package:ips_guide/domain/entities/rule_action.dart';
import 'package:ips_guide/domain/entities/rule_condition.dart';
import 'package:ips_guide/domain/entities/guidance_service.dart';

import '../../support/knowledge_base_fixture.dart';

KnowledgeBase _kbSintetis(List<Rule> rules) => KnowledgeBase(
      service: const GuidanceService(
        id: 'ktp',
        nama: 'KTP',
        deskripsi: '',
        ikon: 'badge',
        urutan: 1,
        estimasiHariMin: 1,
        estimasiHariMax: 1,
      ),
      questions: const [],
      rules: rules,
      requirements: const [],
      steps: const [],
    );

Rule _rule(
  String id,
  int priority,
  List<RuleCondition> when,
  RuleAction then,
) =>
    Rule(
      id: id,
      serviceId: 'ktp',
      priority: priority,
      deskripsi: id,
      when: when,
      then: then,
    );

RuleCondition _eq(String fact, String value) =>
    RuleCondition(fact: fact, op: ConditionOperator.equals, value: value);

void main() {
  group('Chaining (§10.4) — fakta turunan memicu aturan lain', () {
    test('dua tingkat: R-A menulis addFacts, R-B menyala setelahnya', () {
      final kb = _kbSintetis([
        _rule('KTP-RA', 10, [_eq('kategori_usia', '17_ke_atas')],
            const RuleAction(addFacts: {'jenis_pengajuan_ktp': 'baru'})),
        _rule(
          'KTP-RB',
          5,
          [_eq('jenis_pengajuan_ktp', 'baru')],
          const RuleAction(
            setOutcome: Outcome.dapatDiproses,
            addNotes: ['Catatan dari aturan B'],
          ),
        ),
      ]);

      final result = RuleEngine.inferensi(kb, {'kategori_usia': '17_ke_atas'});

      expect(result.fired.map((r) => r.id), containsAll(['KTP-RA', 'KTP-RB']));
      expect(result.outcome, Outcome.dapatDiproses);
      expect(result.winner!.id, 'KTP-RB');
      expect(result.addedNotes.single.key, 'Catatan dari aturan B');
    });
  });

  group('Idempotensi & determinisme (§10.5)', () {
    test('aturan hanya menyala sekali per perhitungan', () {
      final kb = kbKtp();
      final answers = {
        'kategori_usia': '17_ke_atas',
        'sudah_punya_ktp': 'ya',
        'domisili_pemohon': 'tegalsari',
        'alasan_pengajuan_ktp': 'hilang',
      };
      final a = RuleEngine.inferensi(kb, answers);
      final b = RuleEngine.inferensi(kb, answers);

      final idA = a.fired.map((r) => r.id).toSet();
      expect(idA.length, a.fired.length); // tidak ada duplikat
      expect(idA, b.fired.map((r) => r.id).toSet());
      expect(a.outcome, b.outcome);
      expect(a.winner!.id, b.winner!.id);
    });

    test('hasil tidak bergantung urutan baca daftar aturan', () {
      final kb = kbDomisili();
      final answers = {
        'keperluan_domisili': 'usaha',
        'status_tinggal': 'tinggal_sementara',
        'punya_bukti_tinggal': 'tidak',
      };
      final a = RuleEngine.inferensi(kb, answers);
      // Peta kedua dengan urutan kunci dibalik — hasil harus identik.
      final dibalik = <String, String>{
        for (final e in answers.entries.toList().reversed) e.key: e.value,
      };
      final b = RuleEngine.inferensi(kb, dibalik);

      expect(a.winner!.id, b.winner!.id);
      expect(a.outcome, b.outcome);
    });
  });

  group('Resolusi konflik — prioritas, bukan urutan (T-05, §10.5)', () {
    test('DOM-R03 (p85) mengalahkan DOM-R02 (p80) meski R02 lebih dulu cocok',
        () {
      final kb = kbDomisili();
      final result = RuleEngine.inferensi(kb, {
        'keperluan_domisili': 'lainnya',
        'status_tinggal': 'tinggal_sementara',
        'punya_bukti_tinggal': 'tidak',
      });

      // Keduanya menyala...
      expect(result.fired.map((r) => r.id),
          containsAll(['DOM-R02', 'DOM-R03']));
      // ...tetapi pemenangnya R03.
      expect(result.winner!.id, 'DOM-R03');
      expect(result.outcome, Outcome.denganCatatan);
      // Trace menandai pemenang.
      expect(
        result.trace.where((t) => t.isWinner).map((t) => t.ruleId),
        ['DOM-R03'],
      );
    });

    test('persyaratan dari aturan kalah tetap terakumulasi (akumulatif)', () {
      final kb = kbDomisili();
      final result = RuleEngine.inferensi(kb, {
        'keperluan_domisili': 'usaha',
        'status_tinggal': 'warga_tetap',
      });
      // DOM-R01 (outcome) + DOM-R04 (tanpa outcome, p85 menambah req).
      expect(result.addedRequirements,
          containsAll(['REQ_FOTO_LOKASI_USAHA', 'REQ_SURAT_TETANGGA']));
      expect(result.outcome, Outcome.dapatDiproses);
    });

    test('tidak ada aturan ber-outcome → (null, null) → belum tersedia (§10.8)',
        () {
      final kb = kbKtp();
      final result = RuleEngine.inferensi(kb, {
        'kategori_usia': 'di_bawah_17',
        'status_perkawinan': 'pernah_menikah',
        'domisili_pemohon': 'tegalsari',
      });
      expect(result.fired.map((r) => r.id), contains('KTP-R10'));
      expect(result.winner, isNull);
      expect(result.outcome, isNull);
    });
  });

  group('Terminal & penjaga runtime (§10.6.1–10.6.2, V-01)', () {
    test('pemenang terminal → sesi berhenti', () {
      final kb = kbKtp();
      final result =
          RuleEngine.inferensi(kb, {'domisili_pemohon': 'luar_tegalsari'});
      expect(result.terminal, isTrue);
      expect(result.winner!.id, 'KTP-R08');
      expect(result.warnings, isEmpty);
    });

    test('CONFIG_WARNING bila pemenang non-terminal padahal ada terminal',
        () {
      // Konfigurasi bermasalah: terminal p50, non-terminal p90.
      final kb = _kbSintetis([
        _rule(
          'KTP-RY',
          90,
          [_eq('kategori_usia', '17_ke_atas')],
          const RuleAction(setOutcome: Outcome.dapatDiproses),
        ),
        _rule(
          'KTP-RX',
          50,
          [_eq('kategori_usia', '17_ke_atas')],
          const RuleAction(
            setOutcome: Outcome.tidakDapatDiproses,
            terminal: true,
          ),
        ),
      ]);

      final result =
          RuleEngine.inferensi(kb, {'kategori_usia': '17_ke_atas'});

      expect(result.terminal, isFalse); // JANGAN hentikan sesi
      expect(result.winner!.id, 'KTP-RY'); // pemenang tetap p90
      expect(result.outcome, Outcome.dapatDiproses);
      expect(result.warnings, hasLength(1));
      expect(result.warnings.single, contains('CONFIG_WARNING'));
    });
  });

  test('Fakta turunan (addFacts) tercatat di trace', () {
    final kb = kbKtp();
    final result = RuleEngine.inferensi(kb, {
      'kategori_usia': '17_ke_atas',
      'sudah_punya_ktp': 'ya',
      'domisili_pemohon': 'tegalsari',
      'alasan_pengajuan_ktp': 'hilang',
    });
    final traceR04 =
        result.trace.firstWhere((t) => t.ruleId == 'KTP-R04');
    expect(traceR04.addFacts['jenis_pengajuan_ktp'], 'penggantian_hilang');
  });
}
