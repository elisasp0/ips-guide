import '../entities/knowledge_base.dart';
import '../entities/outcome.dart';
import '../entities/rule.dart';
import '../entities/rule_trace.dart';
import 'condition_evaluator.dart';
import 'fact_base.dart';

/// Hasil satu kali inferensi (§10.4).
class InferenceResult {
  /// Aturan yang menyala, berurutan sesuai penemuan (deterministik).
  final List<Rule> fired;

  /// Pemenang `pilihOutcome` — aturan, bukan hanya nilai (§10.5).
  final Rule? winner;
  final Outcome? outcome;

  /// true hanya bila pemenang adalah aturan terminal (§10.6.1–10.6.2).
  final bool terminal;

  /// Peringatan konfigurasi (mis. CONFIG_WARNING §10.6.2) — tampil di H6
  /// khusus admin, tidak pernah ke warga.
  final List<String> warnings;

  final List<RuleTrace> trace;

  /// ID persyaratan terakumulasi (urutan penyalaan, sebelum dedup akhir)
  /// beserta aturan sumbernya (explanation facility).
  final List<String> addedRequirements;
  final Map<String, String> requirementSource;

  /// ID tahapan tambahan dari `addSteps` (belum dipakai v1.4).
  final List<String> addedSteps;

  /// (teks catatan, id aturan sumber).
  final List<MapEntry<String, String>> addedNotes;

  const InferenceResult({
    required this.fired,
    required this.winner,
    required this.outcome,
    required this.terminal,
    required this.warnings,
    required this.trace,
    required this.addedRequirements,
    required this.requirementSource,
    required this.addedSteps,
    required this.addedNotes,
  });
}

/// Mesin inferensi forward chaining (§10.4, §10.5).
///
/// Prinsip (T-04): inferensi DIHITUNG ULANG DARI NOL setiap kali jawaban
/// berubah — tidak ada state `fired` yang dipertahankan.
class RuleEngine {
  /// Urutan peringkat kandidat (§10.4, §10.5):
  /// priority DESC → jumlah klausa DESC (spesifisitas) → id ASC.
  static int compareRank(Rule a, Rule b) {
    if (a.priority != b.priority) return b.priority - a.priority;
    if (a.when.length != b.when.length) return b.when.length - a.when.length;
    return a.id.compareTo(b.id);
  }

  /// Inferensi atas [kb] dengan [answers] (peta factKey → nilai jawaban).
  static InferenceResult inferensi(
    KnowledgeBase kb,
    Map<String, String> answers,
  ) {
    var facts = FactBase.fromAnswers(kb.serviceId, answers);

    final fired = <Rule>[];
    final firedIds = <String>{};
    final trace = <RuleTrace>[];
    final warnings = <String>[];

    final addedRequirements = <String>[];
    final requirementSource = <String, String>{};
    final addedSteps = <String>[];
    final addedNotes = <MapEntry<String, String>>[];

    var berubah = true;
    while (berubah) {
      berubah = false;
      final kandidat = kb.rules
          .where((r) => r.aktif && !firedIds.contains(r.id))
          .toList()
        ..sort(compareRank);

      for (final r in kandidat) {
        if (!ConditionEvaluator.evaluateWhen(r.when, facts)) continue;

        // Terapkan aksi (§10.4): requirements, steps, facts, notes.
        fired.add(r);
        firedIds.add(r.id);

        for (final id in r.then.addRequirements) {
          if (!addedRequirements.contains(id)) {
            addedRequirements.add(id);
            requirementSource[id] = r.id;
          }
        }
        for (final id in r.then.addSteps) {
          if (!addedSteps.contains(id)) addedSteps.add(id);
        }
        for (final teks in r.then.addNotes) {
          addedNotes.add(MapEntry(teks, r.id));
        }
        if (r.then.addFacts.isNotEmpty) {
          facts = facts.withAll(r.then.addFacts);
        }

        trace.add(RuleTrace(
          ruleId: r.id,
          deskripsi: r.deskripsi,
          priority: r.priority,
          setOutcome: r.then.setOutcome,
          terminal: r.then.terminal,
          addRequirements: List.unmodifiable(r.then.addRequirements),
          addSteps: List.unmodifiable(r.then.addSteps),
          addFacts: Map.unmodifiable(r.then.addFacts),
          addNotes: List.unmodifiable(r.then.addNotes),
        ));

        // Fakta baru bisa memicu aturan lain → ulangi seluruh pencarian.
        berubah = true;
        break;
      }
    }

    final (winner, outcome) = pilihOutcome(fired);

    // Tandai pemenang di trace (§10.5) — diperlukan untuk penelusuran H6.
    final traceFinal = [
      for (final t in trace)
        RuleTrace(
          ruleId: t.ruleId,
          deskripsi: t.deskripsi,
          priority: t.priority,
          setOutcome: t.setOutcome,
          terminal: t.terminal,
          addRequirements: t.addRequirements,
          addSteps: t.addSteps,
          addFacts: t.addFacts,
          addNotes: t.addNotes,
          isWinner: winner != null && t.ruleId == winner.id,
        ),
    ];

    // Penjaga runtime §10.6.2 (pertahanan terakhir, V-01):
    // bila ada aturan terminal menyala tetapi pemenang bukan terminal,
    // JANGAN hentikan sesi — lanjutkan bertanya, catat CONFIG_WARNING.
    var terminal = false;
    final adaTerminal = fired.any((r) => r.then.terminal);
    if (adaTerminal) {
      if (winner != null && winner.then.terminal) {
        terminal = true;
      } else {
        terminal = false;
        warnings.add(
          'CONFIG_WARNING: ada aturan terminal yang menyala tetapi pemenang '
          'outcome adalah aturan non-terminal (${winner?.id ?? 'tidak ada'}). '
          'Sesi dilanjutkan sesuai §10.6.2. Perbaiki prioritas/terminal di H6.',
        );
      }
    }

    return InferenceResult(
      fired: List.unmodifiable(fired),
      winner: winner,
      outcome: outcome,
      terminal: terminal,
      warnings: List.unmodifiable(warnings),
      trace: List.unmodifiable(traceFinal),
      addedRequirements: List.unmodifiable(addedRequirements),
      requirementSource: Map.unmodifiable(requirementSource),
      addedSteps: List.unmodifiable(addedSteps),
      addedNotes: List.unmodifiable(addedNotes),
    );
  }

  /// Resolusi konflik (§10.5, T-05): outcome ditentukan aturan berperingkat
  /// tertinggi di antara SELURUH aturan yang menyala — bukan yang terakhir.
  ///
  /// Mengembalikan (aturan pemenang, outcome). (null, null) berarti tidak
  /// ada aturan yang menetapkan outcome → "panduan belum tersedia" (§10.8).
  static (Rule?, Outcome?) pilihOutcome(List<Rule> fired) {
    final kandidat =
        fired.where((r) => r.then.setOutcome != null).toList()
          ..sort(compareRank);
    if (kandidat.isEmpty) return (null, null);
    return (kandidat.first, kandidat.first.then.setOutcome);
  }
}
