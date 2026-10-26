import 'package:flutter_test/flutter_test.dart';
import 'package:ips_guide/domain/engine/condition_evaluator.dart';
import 'package:ips_guide/domain/engine/fact_base.dart';
import 'package:ips_guide/domain/entities/rule_condition.dart';

void main() {
  final facts = FactBase({
    'service': 'ktp',
    'kategori_usia': '17_ke_atas',
    'sudah_punya_ktp': 'ya',
    'alasan_pengajuan_ktp': 'hilang',
    'usia': '19',
  });

  RuleCondition c(String fact, ConditionOperator op, [Object? value]) =>
      RuleCondition(fact: fact, op: op, value: value);

  group('Operator daun — fakta tersedia', () {
    test('equals → true bila sama, false bila beda', () {
      expect(
        ConditionEvaluator.evaluateTrinary(
            c('kategori_usia', ConditionOperator.equals, '17_ke_atas'), facts),
        isTrue,
      );
      expect(
        ConditionEvaluator.evaluateTrinary(
            c('kategori_usia', ConditionOperator.equals, 'di_bawah_17'), facts),
        isFalse,
      );
    });

    test('notEquals → inverse equals', () {
      expect(
        ConditionEvaluator.evaluateTrinary(
            c('kategori_usia', ConditionOperator.notEquals, 'di_bawah_17'),
            facts),
        isTrue,
      );
      expect(
        ConditionEvaluator.evaluateTrinary(
            c('kategori_usia', ConditionOperator.notEquals, '17_ke_atas'),
            facts),
        isFalse,
      );
    });

    test('inList / notInList', () {
      final hilang = c(
        'alasan_pengajuan_ktp',
        ConditionOperator.inList,
        ['hilang', 'rusak'],
      );
      final bukanPindah = c(
        'alasan_pengajuan_ktp',
        ConditionOperator.notInList,
        ['pindah_datang', 'perubahan_data'],
      );
      expect(ConditionEvaluator.evaluateTrinary(hilang, facts), isTrue);
      expect(ConditionEvaluator.evaluateTrinary(bukanPindah, facts), isTrue);
    });

    test('inList → false bila tidak anggota', () {
      final c2 = c('alasan_pengajuan_ktp', ConditionOperator.inList,
          ['pindah_datang']);
      expect(ConditionEvaluator.evaluateTrinary(c2, facts), isFalse);
    });

    test('gte / lte — perbandingan angka', () {
      expect(
        ConditionEvaluator.evaluateTrinary(
            c('usia', ConditionOperator.gte, '17'), facts),
        isTrue,
      );
      expect(
        ConditionEvaluator.evaluateTrinary(
            c('usia', ConditionOperator.lte, '17'), facts),
        isFalse,
      );
      // non-numerik → perbandingan gagal (false), bukan undefined
      expect(
        ConditionEvaluator.evaluateTrinary(
            c('kategori_usia', ConditionOperator.gte, '17'), facts),
        isFalse,
      );
    });

    test('exists / notExists — tidak pernah undefined', () {
      expect(
        ConditionEvaluator.evaluateTrinary(
            c('sudah_punya_ktp', ConditionOperator.exists), facts),
        isTrue,
      );
      expect(
        ConditionEvaluator.evaluateTrinary(
            c('status_perkawinan', ConditionOperator.exists), facts),
        isFalse,
      );
      expect(
        ConditionEvaluator.evaluateTrinary(
            c('status_perkawinan', ConditionOperator.notExists), facts),
        isTrue,
      );
    });
  });

  group('Logika tiga nilai — fakta BELUM tersedia (U-03)', () {
    test('equals/notEquals/inList/gte → undefined (null)', () {
      for (final op in [
        ConditionOperator.equals,
        ConditionOperator.notEquals,
        ConditionOperator.inList,
        ConditionOperator.notInList,
        ConditionOperator.gte,
        ConditionOperator.lte,
      ]) {
        expect(
          ConditionEvaluator.evaluateTrinary(
              c('status_perkawinan', op, op == ConditionOperator.inList ||
                      op == ConditionOperator.notInList
                  ? ['menikah']
                  : 'menikah'),
              facts),
          isNull,
          reason: 'operator $op harus undefined bila fakta belum ada',
        );
      }
    });

    test('undefined TIDAK boleh dianggap true', () {
      // KTP-Q05: showIf sudah_punya_ktp = ya — belum dijawab → bukan layak.
      final factsTanpaPunya = FactBase({
        'service': 'ktp',
        'kategori_usia': '17_ke_atas',
      });
      final showIfQ05 = c('sudah_punya_ktp', ConditionOperator.equals, 'ya');
      expect(
        ConditionEvaluator.evaluateTrinary(showIfQ05, factsTanpaPunya) == true,
        isFalse,
      );
    });
  });

  group('AND (when) — tiga nilai', () {
    test('semua true → true', () {
      final when = [
        c('kategori_usia', ConditionOperator.equals, '17_ke_atas'),
        c('sudah_punya_ktp', ConditionOperator.equals, 'ya'),
      ];
      expect(ConditionEvaluator.evaluateWhenTrinary(when, facts), isTrue);
    });

    test('satu false → false (menang atas undefined)', () {
      final when = [
        c('kategori_usia', ConditionOperator.equals, '17_ke_atas'),
        c('sudah_punya_ktp', ConditionOperator.equals, 'tidak'), // false
        c('status_perkawinan', ConditionOperator.equals, 'menikah'), // undefined
      ];
      expect(ConditionEvaluator.evaluateWhenTrinary(when, facts), isFalse);
    });

    test('tidak ada false tetapi ada undefined → undefined', () {
      final when = [
        c('kategori_usia', ConditionOperator.equals, '17_ke_atas'),
        c('status_perkawinan', ConditionOperator.equals, 'menikah'),
      ];
      expect(ConditionEvaluator.evaluateWhenTrinary(when, facts), isNull);
    });

    test('when kosong → true (aturan tanpa kondisi)', () {
      expect(ConditionEvaluator.evaluateWhenTrinary([], facts), isTrue);
    });
  });

  group('OR (any) — tersedia di engine (§10.2)', () {
    test('satu anak true → true', () {
      final or = RuleCondition(
        any: [
          c('sudah_punya_ktp', ConditionOperator.equals, 'tidak'),
          c('sudah_punya_ktp', ConditionOperator.equals, 'ya'),
        ],
      );
      expect(ConditionEvaluator.evaluateTrinary(or, facts), isTrue);
    });

    test('semua false → false', () {
      final or = RuleCondition(
        any: [
          c('sudah_punya_ktp', ConditionOperator.equals, 'x'),
          c('kategori_usia', ConditionOperator.equals, 'y'),
        ],
      );
      expect(ConditionEvaluator.evaluateTrinary(or, facts), isFalse);
    });

    test('ada undefined dan sisanya false → undefined', () {
      final or = RuleCondition(
        any: [
          c('status_perkawinan', ConditionOperator.equals, 'menikah'),
          c('sudah_punya_ktp', ConditionOperator.equals, 'x'),
        ],
      );
      expect(ConditionEvaluator.evaluateTrinary(or, facts), isNull);
    });
  });

  test('evaluateWhen: undefined diperlakukan false (aturan tidak menyala)',
      () {
    final when = [
      c('status_perkawinan', ConditionOperator.equals, 'menikah'), // undefined
    ];
    expect(ConditionEvaluator.evaluateWhen(when, facts), isFalse);
  });
}
