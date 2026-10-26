import 'guidance_question.dart';
import 'guidance_service.dart';
import 'requirement.dart';
import 'rule.dart';
import 'service_step.dart';

/// Basis pengetahuan satu layanan (§3.3, §7).
///
/// Dibangun oleh repository (in-memory dari seed, atau Firestore) dan
/// divalidasi saat dimuat — bukan saat runtime (§10.4.1 poin 5).
class KnowledgeBase {
  final GuidanceService service;
  final List<GuidanceQuestion> questions;

  /// Termasuk aturan non-aktif; penyaringan `aktif` dilakukan mesin.
  final List<Rule> rules;

  /// Katalog persyaratan yang dirujuk `rule.then.addRequirements`.
  final List<Requirement> requirements;

  /// Katalog tahapan yang dirujuk `stepsDasar` dan `addSteps`.
  final List<ServiceStep> steps;

  const KnowledgeBase({
    required this.service,
    required this.questions,
    required this.rules,
    required this.requirements,
    required this.steps,
  });

  String get serviceId => service.id;

  Requirement? requirementById(String id) {
    for (final r in requirements) {
      if (r.id == id) return r;
    }
    return null;
  }

  ServiceStep? stepById(String id) {
    for (final s in steps) {
      if (s.id == id) return s;
    }
    return null;
  }

  GuidanceQuestion? questionByFactKey(String factKey) {
    for (final q in questions) {
      if (q.factKey == factKey) return q;
    }
    return null;
  }
}
