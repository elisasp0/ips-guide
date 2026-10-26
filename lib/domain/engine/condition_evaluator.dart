import '../entities/rule_condition.dart';
import 'fact_base.dart';

/// Evaluator kondisi — pure Dart, tanpa Flutter/Firestore (§3.1, §10.2).
///
/// Evaluasi `showIf` memakai **logika tiga nilai** (§10.4.1, U-03):
/// `true` = kondisi terpenuhi, `false` = tidak terpenuhi,
/// `null` = undefined — fakta yang dirujuk belum tersedia.
///
/// Aturan penting: `undefined` TIDAK boleh diperlakukan sebagai `true`
/// (pertanyaan menunggu, bukan dilewati) dan TIDAK boleh dianggap `false`
/// permanen (ditinjau ulang setiap ada jawaban baru).
class ConditionEvaluator {
  /// Evaluasi satu klausa (daun atau komposit) dalam logika tiga nilai.
  static bool? evaluateTrinary(RuleCondition c, FactBase facts) {
    final any = c.any;
    if (any != null) return _evaluateOr(any, facts);
    return _evaluateLeaf(c, facts);
  }

  /// AND dari seluruh klausa `when` dalam logika tiga nilai.
  ///
  /// - satu saja `false` → `false`;
  /// - tidak ada `false` tetapi ada `null` (undefined) → `null`;
  /// - semua `true` → `true`.
  static bool? evaluateWhenTrinary(
    List<RuleCondition> when,
    FactBase facts,
  ) {
    var undefined = false;
    for (final c in when) {
      final r = evaluateTrinary(c, facts);
      if (r == false) return false;
      if (r == null) undefined = true;
    }
    return undefined ? null : true;
  }

  /// Evaluasi `when` untuk penyalaan aturan: undefined diperlakukan false
  /// (aturan tidak menyala bila ada fakta yang belum diketahui).
  static bool evaluateWhen(List<RuleCondition> when, FactBase facts) =>
      evaluateWhenTrinary(when, facts) == true;

  /// OR atas klausa anak (§10.2 — tersedia, belum dipakai basis pengetahuan).
  static bool? _evaluateOr(List<RuleCondition> children, FactBase facts) {
    var undefined = false;
    for (final child in children) {
      final r = evaluateTrinary(child, facts);
      if (r == true) return true;
      if (r == null) undefined = true;
    }
    return undefined ? null : false;
  }

  static bool? _evaluateLeaf(RuleCondition c, FactBase facts) {
    switch (c.op) {
      // exists/notExists tidak merujuk nilai lain — tidak pernah undefined.
      case ConditionOperator.exists:
        return facts.contains(c.fact);
      case ConditionOperator.notExists:
        return !facts.contains(c.fact);
      default:
        break;
    }

    final actual = facts[c.fact];
    if (actual == null) return null; // undefined — fakta belum ada

    switch (c.op) {
      case ConditionOperator.equals:
        return actual == c.value;
      case ConditionOperator.notEquals:
        return actual != c.value;
      case ConditionOperator.inList:
        return _values(c.value).contains(actual);
      case ConditionOperator.notInList:
        return !_values(c.value).contains(actual);
      case ConditionOperator.gte:
        return _compare(actual, c.value, (d) => d >= 0);
      case ConditionOperator.lte:
        return _compare(actual, c.value, (d) => d <= 0);
      case ConditionOperator.exists:
      case ConditionOperator.notExists:
        return null; // tidak mungkin — ditangani di atas
    }
  }

  static Set<String> _values(Object? value) {
    if (value is List) return value.map((v) => v.toString()).toSet();
    if (value is String) return {value};
    return {};
  }

  /// Perbandingan angka; nilai non-numerik berarti perbandingan gagal (false),
  /// bukan undefined — faktanya sudah ada.
  static bool _compare(String actual, Object? expected, bool Function(int d) ok) {
    final a = num.tryParse(actual);
    final b = expected == null ? null : num.tryParse(expected.toString());
    if (a == null || b == null) return false;
    return ok(a.compareTo(b));
  }
}
