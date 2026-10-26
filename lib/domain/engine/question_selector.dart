import '../entities/guidance_question.dart';
import '../entities/knowledge_base.dart';
import 'condition_evaluator.dart';
import 'fact_base.dart';

/// Pemilih pertanyaan berikutnya (§10.4).
///
/// Kriteria: aktif, `factKey` belum dijawab, dan `showIf` dievaluasi
/// **= TRUE** dalam logika tiga nilai (bukan "≠ FALSE" — undefined berarti
/// menunggu, bukan dilewati). Urutan `urutan` ASC, tie-break `id` ASC.
class QuestionSelector {
  static GuidanceQuestion? next(KnowledgeBase kb, FactBase facts) {
    GuidanceQuestion? terpilih;
    for (final q in kb.questions) {
      if (!q.aktif) continue;
      if (facts.contains(q.factKey)) continue;
      if (q.showIf != null &&
          ConditionEvaluator.evaluateTrinary(q.showIf!, facts) != true) {
        continue;
      }
      if (terpilih == null ||
          q.urutan < terpilih.urutan ||
          (q.urutan == terpilih.urutan && q.id.compareTo(terpilih.id) < 0)) {
        terpilih = q;
      }
    }
    return terpilih;
  }
}
