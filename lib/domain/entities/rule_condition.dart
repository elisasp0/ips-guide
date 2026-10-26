/// Operator kondisi yang dikenal mesin (§10.2).
///
/// `when` adalah AND dari seluruh klausa. `any` (OR) tersedia di engine
/// tetapi belum dipakai basis pengetahuan v1.4.
enum ConditionOperator {
  equals('equals'),
  notEquals('notEquals'),
  inList('inList'),
  notInList('notInList'),
  gte('gte'),
  lte('lte'),
  exists('exists'),
  notExists('notExists');

  const ConditionOperator(this.wireName);

  final String wireName;
}

/// Satu klausa kondisi.
///
/// Klausa daun menyatakan `fact <op> value`. Klausa komposit (`any != null`)
/// adalah OR atas klausa-klausa anak dan tidak memakai `fact`/`op`/`value`.
class RuleCondition {
  /// Hanya relevan untuk klausa daun; kosong pada klausa komposit.
  final String fact;
  final ConditionOperator op;

  /// Nilai pembanding: `String` untuk equals/notEquals/gte/lte,
  /// `List<String>` untuk inList/notInList, tidak dipakai untuk
  /// exists/notExists.
  final Object? value;

  /// Klausa anak untuk kombinasi OR; null berarti klausa daun.
  final List<RuleCondition>? any;

  const RuleCondition({
    this.fact = '',
    this.op = ConditionOperator.equals,
    this.value,
    this.any,
  });

  /// Klausa komposit OR (§10.2 — tersedia, belum dipakai v1.4).
  const RuleCondition.any(this.any)
      : fact = '',
        op = ConditionOperator.equals,
        value = null;
}
