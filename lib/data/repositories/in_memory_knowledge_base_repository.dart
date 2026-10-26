import 'package:ips_guide/domain/entities/guidance_question.dart';
import 'package:ips_guide/domain/entities/guidance_service.dart';
import 'package:ips_guide/domain/entities/knowledge_base.dart';
import 'package:ips_guide/domain/entities/rule.dart';
import 'package:ips_guide/domain/engine/knowledge_base_validator.dart';

import '../models/seed_mappers.dart';
import '../seed/seed_loader.dart';
import 'knowledge_base_repository.dart';

/// Repository in-memory dari seed (§3.3) — dipakai Tahap 2–4 agar UI dan
/// engine bisa dibangun & diuji SEBELUM Firebase ada.
///
/// Validasi basis pengetahuan dijalankan **saat memuat** (bukan saat runtime
/// — §10.4.1 poin 5). Layanan yang gagal validasi ditandai; permintaan atas
/// layanan itu melempar [KnowledgeBaseException] berisi kode pelanggaran,
/// sedangkan layanan lain tetap dapat dimuat (S38, S41–S43, S45).
class InMemoryKnowledgeBaseRepository implements KnowledgeBaseRepository {
  final Map<String, GuidanceService> _services;
  final Map<String, KnowledgeBase> _validKb;
  final Map<String, List<String>> _validationErrors;

  InMemoryKnowledgeBaseRepository._(
    this._services,
    this._validKb,
    this._validationErrors,
  );

  /// Membangun repository dari dokumen seed mentah.
  factory InMemoryKnowledgeBaseRepository.fromMaps(SeedData seed) {
    final services = <String, GuidanceService>{};
    for (final doc in seed.services) {
      final s = SeedMappers.mapService(doc);
      if (services.containsKey(s.id)) {
        throw KnowledgeBaseException('ID layanan duplikat: ${s.id}');
      }
      services[s.id] = s;
    }

    final questionsPerService = <String, List<GuidanceQuestion>>{};
    for (final doc in seed.questions) {
      final q = SeedMappers.mapQuestion(doc);
      questionsPerService.putIfAbsent(q.serviceId, () => []).add(q);
    }

    final rulesPerService = <String, List<Rule>>{};
    for (final entry in seed.rules.entries) {
      final list = <Rule>[];
      for (final doc in entry.value) {
        final r = SeedMappers.mapRule(doc);
        if (r.serviceId != entry.key) {
          throw KnowledgeBaseException(
            'Aturan ${r.id} milik ${r.serviceId} tetapi ada di berkas '
            'rules/${entry.key}.json',
          );
        }
        list.add(r);
      }
      rulesPerService[entry.key] = list;
    }

    final requirementCatalog = [
      for (final doc in seed.requirements) SeedMappers.mapRequirement(doc),
    ];
    final stepCatalog = [
      for (final doc in seed.steps) SeedMappers.mapStep(doc),
    ];

    final validKb = <String, KnowledgeBase>{};
    final validationErrors = <String, List<String>>{};
    for (final id in services.keys) {
      final kb = KnowledgeBase(
        service: services[id]!,
        questions: questionsPerService[id] ?? const [],
        rules: rulesPerService[id] ?? const [],
        requirements: requirementCatalog,
        steps: stepCatalog,
      );
      final errors = KnowledgeBaseValidator.validate(kb);
      if (errors.isEmpty) {
        validKb[id] = kb;
      } else {
        validationErrors[id] = errors;
      }
    }

    return InMemoryKnowledgeBaseRepository._(services, validKb, validationErrors);
  }

  /// Membangun repository dari `assets/seed/`.
  static Future<InMemoryKnowledgeBaseRepository> fromAssets() async =>
      InMemoryKnowledgeBaseRepository.fromMaps(await SeedLoader.load());

  /// Layanan yang basis pengetahuannya gagal validasi saat dimuat (S45).
  Map<String, List<String>> get validationErrors =>
      Map.unmodifiable(_validationErrors);

  @override
  Future<List<GuidanceService>> loadServices() async =>
      List.unmodifiable(_services.values.toList()
        ..sort((a, b) => a.urutan.compareTo(b.urutan)));

  @override
  Future<KnowledgeBase> loadService(String serviceId) async {
    final service = _services[serviceId];
    if (service == null) {
      throw KnowledgeBaseException('serviceId tidak dikenal: $serviceId');
    }
    final errors = _validationErrors[serviceId];
    if (errors != null) {
      throw KnowledgeBaseException(
        'Basis pengetahuan "$serviceId" gagal validasi saat dimuat',
        errors,
      );
    }
    return _validKb[serviceId]!;
  }
}
