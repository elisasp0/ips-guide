import '../entities/guidance_note.dart';
import '../entities/guidance_question.dart';
import '../entities/guidance_result.dart';
import '../entities/knowledge_base.dart';
import '../entities/requirement.dart';
import '../entities/service_step.dart';
import '../entities/outcome.dart';
import 'condition_evaluator.dart';
import 'fact_base.dart';
import 'question_selector.dart';
import 'rule_engine.dart';

/// Sesi panduan satu layanan (§10.4).
///
/// Urutan operasi yang tidak boleh ditukar: **jawab → pangkas → inferensi →
/// pilih pertanyaan berikutnya** (U-04). Inferensi selalu dihitung ulang dari
/// nol (T-04); tidak ada state `fired` yang dipertahankan.
class GuidanceSession {
  final KnowledgeBase kb;
  final Map<String, String> _answers;
  InferenceResult? _last;

  GuidanceSession(this.kb) : _answers = {};

  /// Jawaban pengguna saat ini (factKey → nilai), tanpa fakta `service`.
  Map<String, String> get answers => Map.unmodifiable(_answers);

  /// Hasil inferensi terbaru (dihitung ulang bila belum ada).
  InferenceResult get inference => _last ??= RuleEngine.inferensi(kb, _answers);

  FactBase get _factBase => FactBase.fromAnswers(kb.serviceId, _answers);

  /// Pertanyaan berikutnya yang layak, atau null bila sesi selesai.
  GuidanceQuestion? get currentQuestion =>
      QuestionSelector.next(kb, _factBase);

  /// Sesi berhenti karena aturan terminal menyala (§10.6).
  bool get isTerminal => inference.terminal;

  /// Tidak ada pertanyaan tersisa yang `showIf`-nya terpenuhi.
  bool get pertanyaanHabis => currentQuestion == null;

  bool get isFinished => isTerminal || pertanyaanHabis;

  /// Pengguna menjawab pertanyaan [factKey].
  ///
  /// Melempar [ArgumentError] bila [factKey] bukan milik pertanyaan aktif —
  /// mencegah fakta palsu masuk kamus.
  void answer(String factKey, String value) {
    final q = kb.questionByFactKey(factKey);
    if (q == null || !q.aktif) {
      throw ArgumentError('Tidak ada pertanyaan aktif dengan factKey $factKey');
    }
    _answers[factKey] = value;
    _pangkas();
    _last = RuleEngine.inferensi(kb, _answers);
  }

  /// Pengguna menekan "Kembali" sampai [factKey] dan mengubah jawabannya:
  /// fakta itu (dan turunannya, lewat pangkas) dibuang, lalu inferensi
  /// dihitung ulang — tidak menyisakan aturan basi (T-04).
  void kembali(String factKey) {
    _answers.remove(factKey);
    _pangkas();
    _last = RuleEngine.inferensi(kb, _answers);
  }

  /// Pemangkasan fakta jalur lama (§10.4.2, U-04) — ITERATIF.
  ///
  /// Menghapus satu fakta dapat membuat fakta lain ikut tidak relevan
  /// (mis. `sudah_punya_ktp` dihapus → `alasan_pengajuan_ktp` ikut dihapus),
  /// sehingga diulang sampai tidak ada perubahan. Hanya menyentuh fakta yang
  /// berasal dari jawaban pengguna; fakta turunan tidak ada di `_answers`.
  void _pangkas() {
    var berubah = true;
    while (berubah) {
      berubah = false;
      for (final fact in List<String>.of(_answers.keys)) {
        if (fact == 'service') continue;
        final q = kb.questionByFactKey(fact);
        if (q == null) continue; // bukan jawaban pengguna — lewati
        if (q.showIf == null) continue; // selalu layak — tidak dipangkas
        final factBase = FactBase.fromAnswers(kb.serviceId, _answers);
        if (ConditionEvaluator.evaluateTrinary(q.showIf!, factBase) != true) {
          _answers.remove(fact);
          berubah = true;
        }
      }
    }
  }

  /// `bangunHasil` (§10.7, §11.5): susun [GuidanceResult] dari inferensi
  /// terakhir — render murni, tanpa akses jaringan.
  GuidanceResult buildResult() {
    final inf = inference;

    // Penyaringan tampilan §10.7: persyaratan & tahapan disembunyikan bila
    // outcome `tidak_dapat_diproses` atau null. Data tetap ada di trace.
    final tampilkanDetail =
        inf.outcome != null && inf.outcome != Outcome.tidakDapatDiproses;

    final requirements = <Requirement>[];
    if (tampilkanDetail) {
      final terlihat = <String>{};
      for (final id in inf.addedRequirements) {
        final katalog = kb.requirementById(id);
        if (katalog == null) continue; // validator menangkap saat memuat
        if (terlihat.add(katalog.id)) {
          requirements.add(Requirement(
            id: katalog.id,
            nama: katalog.nama,
            keterangan: katalog.keterangan,
            wajib: katalog.wajib,
            sourceRuleId: inf.requirementSource[katalog.id] ?? '',
          ));
        }
      }
    }

    final steps = <ServiceStep>[];
    if (tampilkanDetail) {
      final ids = <String>[...kb.service.stepsDasar, ...inf.addedSteps];
      final terlihat = <String>{};
      for (final id in ids) {
        final katalog = kb.stepById(id);
        if (katalog == null) continue;
        if (terlihat.add(katalog.id)) steps.add(katalog);
      }
      steps.sort((a, b) {
        if (a.urutan != b.urutan) return a.urutan - b.urutan;
        return a.id.compareTo(b.id);
      });
    }

    final notes = [
      for (final n in inf.addedNotes)
        GuidanceNote(teks: n.key, sourceRuleId: n.value),
    ];

    return GuidanceResult(
      service: kb.service,
      outcome: inf.outcome,
      requirements: List.unmodifiable(requirements),
      steps: List.unmodifiable(steps),
      notes: List.unmodifiable(notes),
      answers: Map.unmodifiable(_answers),
      trace: inf.trace,
      terminal: inf.terminal,
    );
  }
}
