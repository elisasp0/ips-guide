import 'outcome.dart';

/// Jejak satu aturan yang menyala selama inferensi (§7, §10.8).
///
/// Data tetap tersimpan di trace meskipun persyaratannya disembunyikan dari
/// H5 — agar dapat diuji dan dijelaskan (§10.7).
class RuleTrace {
  final String ruleId;
  final String deskripsi;
  final int priority;
  final Outcome? setOutcome;
  final bool terminal;
  final List<String> addRequirements;
  final List<String> addSteps;
  final Map<String, String> addFacts;
  final List<String> addNotes;

  /// true hanya untuk pemenang `pilihOutcome`.
  final bool isWinner;

  const RuleTrace({
    required this.ruleId,
    required this.deskripsi,
    required this.priority,
    required this.setOutcome,
    required this.terminal,
    this.addRequirements = const [],
    this.addSteps = const [],
    this.addFacts = const {},
    this.addNotes = const [],
    this.isWinner = false,
  });
}
