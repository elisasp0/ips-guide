import 'rule_action.dart';
import 'rule_condition.dart';

/// Satu aturan IF–THEN yang disimpan sebagai data, bukan `if/else` kode (§10.1).
class Rule {
  final String id; // format `<LAYANAN>-R<nn>`, mis. KTP-R03
  final String serviceId;
  final int priority;
  final String deskripsi;

  /// AND dari seluruh klausa (§10.2).
  final List<RuleCondition> when;
  final RuleAction then;
  final bool aktif;

  const Rule({
    required this.id,
    required this.serviceId,
    required this.priority,
    required this.deskripsi,
    required this.when,
    required this.then,
    this.aktif = true,
  });

  /// Dipakai jalur simpan H6 (§12.5) — hanya field yang boleh diubah admin
  /// yang diekspos; `id`, `serviceId`, `when`, dan `then` tetap.
  Rule copyWith({int? priority, String? deskripsi, bool? aktif}) => Rule(
        id: id,
        serviceId: serviceId,
        priority: priority ?? this.priority,
        deskripsi: deskripsi ?? this.deskripsi,
        when: when,
        then: then,
        aktif: aktif ?? this.aktif,
      );
}
