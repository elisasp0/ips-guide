
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/guidance_question.dart';
import '../../domain/entities/guidance_service.dart';
import '../../domain/entities/knowledge_base.dart';
import '../../domain/entities/requirement.dart';
import '../../domain/entities/rule.dart';
import '../../domain/entities/rule_condition.dart';
import '../../domain/engine/knowledge_base_validator.dart';

import '../models/seed_mappers.dart';
import 'knowledge_base_repository.dart';

/// Repository basis pengetahuan menggunakan Cloud Firestore.
///
/// Koleksi:
/// services/{serviceId}
/// questions/{questionId}
/// rules/{ruleId}
/// requirements/{requirementId}
/// steps/{stepId}
///
/// Semua data divalidasi menggunakan KnowledgeBaseValidator
/// sebelum perubahan disimpan.
class FirestoreKnowledgeBaseRepository
    implements KnowledgeBaseRepository {
  final FirebaseFirestore _firestore;

  FirestoreKnowledgeBaseRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _services =>
      _firestore.collection('services');

  CollectionReference<Map<String, dynamic>> get _questions =>
      _firestore.collection('questions');

  CollectionReference<Map<String, dynamic>> get _rules =>
      _firestore.collection('rules');

  CollectionReference<Map<String, dynamic>> get _requirements =>
      _firestore.collection('requirements');

  CollectionReference<Map<String, dynamic>> get _steps =>
      _firestore.collection('steps');

  // ------------------------------------------------------------
  // PEMBACAAN DATA
  // ------------------------------------------------------------

  /// Membersihkan nama field Firestore dari spasi dan karakter tak terlihat.
  ///
  /// Contohnya, field "aktif ", " aktif", atau field yang mengandung
  /// zero-width character akan dibaca sebagai "aktif".
  String _normalisasiNamaField(String nama) {
    return nama
        .replaceAll(RegExp(r'[\u200B-\u200D\uFEFF]'), '')
        .trim();
  }

  /// Mengambil data dokumen dengan nama field yang sudah dinormalisasi.
  Map<String, dynamic> _data(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final raw = doc.data();

    if (raw == null) {
      throw KnowledgeBaseException(
        'Dokumen Firestore "${doc.id}" tidak memiliki data.',
      );
    }
print('========== CEK NAMA FIELD ==========');

for (final key in raw.keys) {
  print(
    'KEY=<$key> | '
    'PANJANG=${key.length} | '
    'KODE=${key.codeUnits} | '
    'VALUE=${raw[key]}',
  );
}

print('HASIL AKTIF: ${raw['aktif']}');
print('====================================');
    final hasil = <String, dynamic>{};

    for (final entry in raw.entries) {
      final namaField = _normalisasiNamaField(entry.key);
      if (namaField.isNotEmpty) {
        hasil[namaField] = entry.value;
      }
    }

    hasil['id'] = hasil['id'] ?? doc.id;
    return hasil;
  }

  @override
  Future<List<GuidanceService>> loadServices() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;

print('======= CEK FIREBASE AUTH =======');
print('UID: ${firebaseUser?.uid}');
print('EMAIL: ${firebaseUser?.email}');
print('IS ANONYMOUS: ${firebaseUser?.isAnonymous}');
print('================================');
      final snapshot = await _services.orderBy('urutan').get();

      final hasil = <GuidanceService>[];

      for (final doc in snapshot.docs) {
        final data = _data(doc);

        // Field "aktif" harus berupa boolean agar status layanan jelas.
        // Pesan ini membantu menemukan dokumen Firestore yang belum lengkap.
        if (data['aktif'] is! bool) {
          throw KnowledgeBaseException(
            'Field "aktif" pada dokumen "${doc.id}" harus bertipe bool '
            '(true/false). Field yang terbaca: ${data.keys.toList()}.',
          );
        }

        hasil.add(SeedMappers.mapService(data));
      }

      return hasil;
    } catch (e) {
      print('ERROR LOAD SERVICES: $e');

      throw KnowledgeBaseException(
        'Gagal memuat layanan dari Firestore: $e',
      );
    }
  }

  @override
  Future<KnowledgeBase> loadService(String serviceId) async {
    try {
      final serviceDoc = await _services.doc(serviceId).get();

      if (!serviceDoc.exists) {
        throw KnowledgeBaseException(
          'Layanan tidak ditemukan: $serviceId',
        );
      }

      // Gunakan normalisasi field yang sama dengan loadServices().
      // Sebelumnya loadService() membaca data mentah sehingga field seperti
      // "aktif " atau field dengan karakter tak terlihat terbaca sebagai null.
      final serviceData = _data(serviceDoc);

      if (serviceData['aktif'] is! bool) {
        throw KnowledgeBaseException(
          'Field "aktif" pada dokumen "${serviceDoc.id}" harus bertipe bool '
          '(true/false). Field yang terbaca: ${serviceData.keys.toList()}.',
        );
      }

      final service = SeedMappers.mapService(serviceData);

      final questionSnapshot = await _questions
          .where('serviceId', isEqualTo: serviceId)
          .get();

      final ruleSnapshot = await _rules
          .where('serviceId', isEqualTo: serviceId)
          .get();

      final requirementSnapshot = await _requirements.get();

      final stepSnapshot = await _steps.get();

      final questions = questionSnapshot.docs
          .map((doc) => SeedMappers.mapQuestion(_data(doc)))
          .toList()
        ..sort((a, b) => a.urutan.compareTo(b.urutan));

      final rules = ruleSnapshot.docs
          .map((doc) => SeedMappers.mapRule(_data(doc)))
          .toList()
        ..sort((a, b) {
          final priority = b.priority.compareTo(a.priority);
          return priority != 0
              ? priority
              : a.id.compareTo(b.id);
        });

      final requirements = requirementSnapshot.docs
          .map((doc) => SeedMappers.mapRequirement(_data(doc)))
          .toList();

      final steps = stepSnapshot.docs
          .map((doc) => SeedMappers.mapStep(_data(doc)))
          .toList()
        ..sort((a, b) {
          final order = a.urutan.compareTo(b.urutan);
          return order != 0 ? order : a.id.compareTo(b.id);
        });

      final kb = KnowledgeBase(
        service: service,
        questions: questions,
        rules: rules,
        requirements: requirements,
        steps: steps,
      );
      print('===== CEK PERTANYAAN KK =====');

for (final q in kb.questions) {
  print('ID: ${q.id}');
  print('factKey: <${q.factKey}>');
  print('KODE: ${q.factKey.codeUnits}');
}

print('=============================');

      final errors = KnowledgeBaseValidator.validate(kb);

print('========== DETAIL VALIDASI ==========');
print('LAYANAN: $serviceId');
print('JUMLAH ERROR: ${errors.length}');

for (final error in errors) {
  print('ERROR VALIDASI: $error');
}

print('======================================');

      if (errors.isNotEmpty) {
        throw KnowledgeBaseException(
          'Basis pengetahuan "$serviceId" gagal validasi.',
          errors,
        );
      }

      return kb;
    } on KnowledgeBaseException {
      rethrow;
    } catch (e) {
      throw KnowledgeBaseException(
        'Gagal memuat basis pengetahuan "$serviceId": $e',
      );
    }
  }

  // ------------------------------------------------------------
  // VALIDASI
  // ------------------------------------------------------------

  void _validasi(
    KnowledgeBase kb,
    String pesan,
  ) {
    final errors = KnowledgeBaseValidator.validate(kb);

    if (errors.isNotEmpty) {
      throw KnowledgeBaseException(pesan, errors);
    }
  }

  KnowledgeBase _gantiAturan(
    KnowledgeBase kb,
    List<Rule> rules,
  ) {
    return KnowledgeBase(
      service: kb.service,
      questions: kb.questions,
      rules: rules,
      requirements: kb.requirements,
      steps: kb.steps,
    );
  }

  KnowledgeBase _gantiPertanyaan(
    KnowledgeBase kb,
    List<GuidanceQuestion> questions,
  ) {
    return KnowledgeBase(
      service: kb.service,
      questions: questions,
      rules: kb.rules,
      requirements: kb.requirements,
      steps: kb.steps,
    );
  }

  KnowledgeBase _gantiPersyaratan(
    KnowledgeBase kb,
    List<Requirement> requirements,
  ) {
    return KnowledgeBase(
      service: kb.service,
      questions: kb.questions,
      rules: kb.rules,
      requirements: requirements,
      steps: kb.steps,
    );
  }

  // ------------------------------------------------------------
  // PEMETAAN ENTITY KE FIRESTORE
  // ------------------------------------------------------------

  Map<String, dynamic> _questionToMap(
    GuidanceQuestion q,
  ) {
    return {
      'id': q.id,
      'serviceId': q.serviceId,
      'factKey': q.factKey,
      'teks': q.teks,
      'urutan': q.urutan,
      'aktif': q.aktif,
      'opsi': [
        for (final o in q.opsi)
          {
            'value': o.value,
            'label': o.label,
            if (o.keterangan != null)
              'keterangan': o.keterangan,
          },
      ],
      if (q.showIf != null)
        'showIf': _conditionToMap(q.showIf!),
    };
  }

  Map<String, dynamic> _ruleToMap(Rule r) {
    return {
      'id': r.id,
      'serviceId': r.serviceId,
      'priority': r.priority,
      'deskripsi': r.deskripsi,
      'aktif': r.aktif,
      'when': r.when.map(_conditionToMap).toList(),
      'then': {
        'addRequirements': r.then.addRequirements,
        'addSteps': r.then.addSteps,
        'addFacts': r.then.addFacts,
        'addNotes': r.then.addNotes,
        if (r.then.setOutcome != null)
          'setOutcome': r.then.setOutcome!.wireName,
        'terminal': r.then.terminal,
      },
    };
  }

  Map<String, dynamic> _conditionToMap(
    RuleCondition c,
  ) {
    if (c.any != null) {
      return {
        'any': c.any!
            .map(_conditionToMap)
            .toList(),
      };
    }

    return {
      'fact': c.fact,
      'op': c.op.wireName,
      if (c.value != null) 'value': c.value,
    };
  }

  Map<String, dynamic> _requirementToMap(
    Requirement r,
  ) {
    return {
      'id': r.id,
      'nama': r.nama,
      'keterangan': r.keterangan,
      'wajib': r.wajib,
      'aktif': true,
      'sourceRuleId': r.sourceRuleId,
    };
  }

  // ------------------------------------------------------------
  // UBAH ATURAN
  // ------------------------------------------------------------

  @override
  Future<void> simpanAturan(
    String serviceId,
    Rule aturan,
  ) async {
    if (aturan.serviceId != serviceId) {
      throw KnowledgeBaseException(
        'Aturan bukan milik layanan $serviceId.',
      );
    }

    final kb = await loadService(serviceId);
    final rules = [...kb.rules];

    final index = rules.indexWhere(
      (r) => r.id == aturan.id,
    );

    if (index < 0) {
      throw KnowledgeBaseException(
        'Aturan ${aturan.id} tidak ditemukan.',
      );
    }

    rules[index] = aturan;

    _validasi(
      _gantiAturan(kb, rules),
      'Perubahan aturan ${aturan.id} ditolak.',
    );

    await _rules.doc(aturan.id).set(
      _ruleToMap(aturan),
    );
  }

  // ------------------------------------------------------------
  // UBAH PERTANYAAN
  // ------------------------------------------------------------

  @override
  Future<void> simpanPertanyaan(
    String serviceId,
    GuidanceQuestion pertanyaan,
  ) async {
    if (pertanyaan.serviceId != serviceId) {
      throw KnowledgeBaseException(
        'Pertanyaan bukan milik layanan $serviceId.',
      );
    }

    final kb = await loadService(serviceId);
    final questions = [...kb.questions];

    final index = questions.indexWhere(
      (q) => q.id == pertanyaan.id,
    );

    if (index < 0) {
      throw KnowledgeBaseException(
        'Pertanyaan ${pertanyaan.id} tidak ditemukan.',
      );
    }

    questions[index] = pertanyaan;

    _validasi(
      _gantiPertanyaan(kb, questions),
      'Perubahan pertanyaan ${pertanyaan.id} ditolak.',
    );

    await _questions.doc(pertanyaan.id).set(
      _questionToMap(pertanyaan),
    );
  }

  // ------------------------------------------------------------
  // UBAH PERSYARATAN
  // ------------------------------------------------------------

  @override
  Future<void> simpanPersyaratan(
    Requirement persyaratan,
  ) async {
    final services = await loadServices();
    final daftar = <KnowledgeBase>[];

    List<Requirement>? katalogBaru;

    for (final service in services) {
      final kb = await loadService(service.id);
      final requirements = [...kb.requirements];

      final index = requirements.indexWhere(
        (r) => r.id == persyaratan.id,
      );

      if (index >= 0) {
        requirements[index] = persyaratan;
        katalogBaru ??= requirements;
      }

      daftar.add(
        _gantiPersyaratan(kb, requirements),
      );
    }

    if (katalogBaru == null) {
      throw KnowledgeBaseException(
        'Persyaratan ${persyaratan.id} tidak ditemukan.',
      );
    }

    for (final kb in daftar) {
      _validasi(
        kb,
        'Perubahan persyaratan ${persyaratan.id} ditolak.',
      );
    }

    await _requirements.doc(persyaratan.id).set(
      _requirementToMap(persyaratan),
    );
  }

  // ------------------------------------------------------------
  // TAMBAH ATURAN
  // ------------------------------------------------------------

  @override
  Future<void> tambahAturan(
    String serviceId,
    Rule aturan,
  ) async {
    if (aturan.serviceId != serviceId) {
      throw KnowledgeBaseException(
        'Aturan bukan milik layanan $serviceId.',
      );
    }

    final kb = await loadService(serviceId);

    if (kb.rules.any((r) => r.id == aturan.id)) {
      throw KnowledgeBaseException(
        'ID aturan ${aturan.id} sudah digunakan.',
      );
    }

    final rules = [...kb.rules, aturan];

    _validasi(
      _gantiAturan(kb, rules),
      'Aturan ${aturan.id} ditolak.',
    );

    await _rules.doc(aturan.id).set(
      _ruleToMap(aturan),
    );
  }

  // ------------------------------------------------------------
  // TAMBAH PERTANYAAN
  // ------------------------------------------------------------

  @override
  Future<void> tambahPertanyaan(
    String serviceId,
    GuidanceQuestion pertanyaan,
  ) async {
    if (pertanyaan.serviceId != serviceId) {
      throw KnowledgeBaseException(
        'Pertanyaan bukan milik layanan $serviceId.',
      );
    }

    final kb = await loadService(serviceId);

    if (kb.questions.any((q) => q.id == pertanyaan.id)) {
      throw KnowledgeBaseException(
        'ID pertanyaan ${pertanyaan.id} sudah digunakan.',
      );
    }

    if (kb.questions.any(
      (q) => q.factKey == pertanyaan.factKey,
    )) {
      throw KnowledgeBaseException(
        'factKey ${pertanyaan.factKey} sudah digunakan.',
      );
    }

    final questions = [
      ...kb.questions,
      pertanyaan,
    ];

    _validasi(
      _gantiPertanyaan(kb, questions),
      'Pertanyaan ${pertanyaan.id} ditolak.',
    );

    await _questions.doc(pertanyaan.id).set(
      _questionToMap(pertanyaan),
    );
  }
}
