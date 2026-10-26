import 'guidance_note.dart';
import 'guidance_service.dart';
import 'outcome.dart';
import 'requirement.dart';
import 'rule_trace.dart';
import 'service_step.dart';

/// Hasil panduan yang dirender H5 — render murni, tanpa akses jaringan (§3.4).
///
/// Penyaringan tampilan (§10.7) dilakukan di pembangun hasil, bukan UI:
/// bila [outcome] `tidakDapatDiproses` atau null, [requirements] dan [steps]
/// dikosongkan; data tetap ada di [trace].
class GuidanceResult {
  final GuidanceService service;
  final Outcome? outcome; // null → "panduan belum tersedia"
  final List<Requirement> requirements;
  final List<ServiceStep> steps;
  final List<GuidanceNote> notes;
  final Map<String, String> answers;
  final List<RuleTrace> trace;
  final bool terminal;

  const GuidanceResult({
    required this.service,
    required this.outcome,
    required this.requirements,
    required this.steps,
    required this.notes,
    required this.answers,
    required this.trace,
    required this.terminal,
  });

  /// Persyaratan & tahapan boleh ditampilkan (§10.7).
  bool get tampilkanDetail =>
      outcome != null && outcome != Outcome.tidakDapatDiproses;
}
