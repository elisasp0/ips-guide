import 'package:ips_guide/domain/entities/guidance_question.dart';
import 'package:ips_guide/domain/entities/guidance_service.dart';
import 'package:ips_guide/domain/entities/knowledge_base.dart';
import 'package:ips_guide/domain/entities/requirement.dart';
import 'package:ips_guide/domain/entities/rule.dart';
import 'package:ips_guide/domain/entities/service_step.dart';
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
///
/// Sejak Tahap 7 repository ini juga melayani operasi tulis H6 dengan
/// prosedur §12.5: bangun basis pengetahuan gabungan → validasi → tulis,
/// dan **kembalikan keadaan lama** bila validasi gagal (S44). Tahap C
/// (tambah aturan/pertanyaan) memakai prosedur yang sama, sehingga basis
/// pengetahuan dapat diperluas tanpa mengubah kode.
class InMemoryKnowledgeBaseRepository implements KnowledgeBaseRepository {
  final Map<String, GuidanceService> _services;
  final Map<String, List<GuidanceQuestion>> _questions;
  final Map<String, List<Rule>> _rules;
  final List<Requirement> _katalogPersyaratan;
  final List<ServiceStep> _katalogTahapan;

  /// Basis pengetahuan yang lolos validasi, siap dipakai mesin.
  final Map<String, KnowledgeBase> _validKb = {};

  /// Layanan yang gagal validasi → kode pelanggaran (S45).
  final Map<String, List<String>> _validationErrors = {};

  InMemoryKnowledgeBaseRepository._(
    this._services,
    this._questions,
    this._rules,
    this._katalogPersyaratan,
    this._katalogTahapan,
  ) {
    for (final id in _services.keys) {
      _validasiDanSimpan(id);
    }
  }

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

    return InMemoryKnowledgeBaseRepository._(
      services,
      questionsPerService,
      rulesPerService,
      [for (final doc in seed.requirements) SeedMappers.mapRequirement(doc)],
      [for (final doc in seed.steps) SeedMappers.mapStep(doc)],
    );
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

  @override
  Future<void> simpanAturan(String serviceId, Rule aturan) async {
    final daftar = _rules[serviceId];
    if (daftar == null) {
      throw KnowledgeBaseException('serviceId tidak dikenal: $serviceId');
    }
    final i = daftar.indexWhere((r) => r.id == aturan.id);
    if (i < 0) {
      throw KnowledgeBaseException(
        'Aturan ${aturan.id} tidak ada pada layanan $serviceId',
      );
    }
    final lama = daftar[i];
    daftar[i] = aturan;
    try {
      _validasiKandidat(serviceId, 'Perubahan aturan ${aturan.id} ditolak');
      _validasiDanSimpan(serviceId);
    } catch (_) {
      daftar[i] = lama; // S44: basis pengetahuan lama tetap utuh.
      rethrow;
    }
  }

  @override
  Future<void> simpanPertanyaan(
    String serviceId,
    GuidanceQuestion pertanyaan,
  ) async {
    final daftar = _questions[serviceId];
    if (daftar == null) {
      throw KnowledgeBaseException('serviceId tidak dikenal: $serviceId');
    }
    final i = daftar.indexWhere((q) => q.id == pertanyaan.id);
    if (i < 0) {
      throw KnowledgeBaseException(
        'Pertanyaan ${pertanyaan.id} tidak ada pada layanan $serviceId',
      );
    }
    final lama = daftar[i];
    daftar[i] = pertanyaan;
    try {
      _validasiKandidat(
        serviceId,
        'Perubahan pertanyaan ${pertanyaan.id} ditolak',
      );
      _validasiDanSimpan(serviceId);
    } catch (_) {
      daftar[i] = lama;
      rethrow;
    }
  }

  @override
  Future<void> simpanPersyaratan(Requirement persyaratan) async {
    final i = _katalogPersyaratan.indexWhere((r) => r.id == persyaratan.id);
    if (i < 0) {
      throw KnowledgeBaseException(
        'Persyaratan ${persyaratan.id} tidak ada di katalog',
      );
    }
    final lama = _katalogPersyaratan[i];
    _katalogPersyaratan[i] = persyaratan;
    // Katalog dipakai bersama seluruh layanan → validasi ulang semuanya.
    final gagal = <String, List<String>>{};
    for (final id in _services.keys) {
      final errors = KnowledgeBaseValidator.validate(_bangunKb(id));
      if (errors.isNotEmpty) gagal[id] = errors;
    }
    if (gagal.isNotEmpty) {
      _katalogPersyaratan[i] = lama;
      throw KnowledgeBaseException(
        'Perubahan persyaratan ditolak',
        gagal.values.expand((e) => e).toList(),
      );
    }
    for (final id in _services.keys) {
      _validasiDanSimpan(id);
    }
  }

  @override
  Future<void> tambahAturan(String serviceId, Rule aturan) async {
    final daftar = _rules[serviceId];
    if (daftar == null) {
      throw KnowledgeBaseException('serviceId tidak dikenal: $serviceId');
    }
    if (aturan.serviceId != serviceId) {
      throw KnowledgeBaseException(
        'Aturan ${aturan.id} milik ${aturan.serviceId}, bukan $serviceId',
      );
    }
    if (daftar.any((r) => r.id == aturan.id)) {
      throw KnowledgeBaseException(
        'Aturan ${aturan.id} sudah ada pada layanan $serviceId',
      );
    }
    daftar.add(aturan);
    try {
      _validasiKandidat(serviceId, 'Aturan ${aturan.id} ditolak');
      _validasiDanSimpan(serviceId);
    } catch (_) {
      daftar.removeLast(); // Basis pengetahuan lama tetap utuh (§12.5).
      rethrow;
    }
  }

  @override
  Future<void> tambahPertanyaan(
    String serviceId,
    GuidanceQuestion pertanyaan,
  ) async {
    final daftar = _questions[serviceId];
    if (daftar == null) {
      throw KnowledgeBaseException('serviceId tidak dikenal: $serviceId');
    }
    if (pertanyaan.serviceId != serviceId) {
      throw KnowledgeBaseException(
        'Pertanyaan ${pertanyaan.id} milik ${pertanyaan.serviceId}, '
        'bukan $serviceId',
      );
    }
    if (daftar.any((q) => q.id == pertanyaan.id)) {
      throw KnowledgeBaseException(
        'Pertanyaan ${pertanyaan.id} sudah ada pada layanan $serviceId',
      );
    }
    if (daftar.any((q) => q.factKey == pertanyaan.factKey)) {
      throw KnowledgeBaseException(
        'factKey ${pertanyaan.factKey} sudah dipakai pertanyaan lain pada '
        'layanan $serviceId (§10.4.1)',
      );
    }
    daftar.add(pertanyaan);
    try {
      _validasiKandidat(
        serviceId,
        'Pertanyaan ${pertanyaan.id} ditolak',
      );
      _validasiDanSimpan(serviceId);
    } catch (_) {
      daftar.removeLast();
      rethrow;
    }
  }

  /// Memeriksa basis pengetahuan gabungan TANPA mengubah keadaan (§12.5).
  void _validasiKandidat(String serviceId, String pesan) {
    final errors = KnowledgeBaseValidator.validate(_bangunKb(serviceId));
    if (errors.isNotEmpty) {
      throw KnowledgeBaseException(pesan, errors);
    }
  }

  /// Prosedur §12.5: validasi basis pengetahuan hasil gabungan, lalu simpan.
  void _validasiDanSimpan(String serviceId) {
    final kb = _bangunKb(serviceId);
    final errors = KnowledgeBaseValidator.validate(kb);
    if (errors.isEmpty) {
      _validKb[serviceId] = kb;
      _validationErrors.remove(serviceId);
    } else {
      _validationErrors[serviceId] = errors;
      _validKb.remove(serviceId);
    }
  }

  KnowledgeBase _bangunKb(String serviceId) => KnowledgeBase(
        service: _services[serviceId]!,
        questions: _questions[serviceId] ?? const [],
        rules: _rules[serviceId] ?? const [],
        requirements: _katalogPersyaratan,
        steps: _katalogTahapan,
      );
}
