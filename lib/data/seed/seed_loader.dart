import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../repositories/knowledge_base_repository.dart';

/// Memuat berkas seed JSON dari `assets/seed/` (§8.6).
///
/// JSON dipakai hanya untuk (1) data awal lewat tombol "Impor data awal" di
/// H6 dan (2) bahan uji `InMemoryKnowledgeBaseRepository` — tidak ada
/// pembacaan `assets/` saat runtime normal, tanpa fallback otomatis.
class SeedLoader {
  static const String _base = 'assets/seed';

  /// Memuat seluruh koleksi seed. Aturan dipisah per `serviceId`
  /// (`assets/seed/rules/<serviceId>.json`).
  static Future<SeedData> load() async {
    final services = await _loadList('$_base/services.json');
    final questions = await _loadList('$_base/questions.json');
    final requirements = await _loadList('$_base/requirements.json');
    final steps = await _loadList('$_base/steps.json');

    final rules = <String, List<Map<String, dynamic>>>{};
    for (final s in services) {
      final id = s['id'];
      if (id is! String || id.isEmpty) {
        throw const KnowledgeBaseException(
          'Dokumen services memiliki "id" yang tidak sah',
        );
      }
      rules[id] = await _loadList('$_base/rules/$id.json');
    }

    return SeedData(
      services: services,
      questions: questions,
      requirements: requirements,
      steps: steps,
      rules: rules,
    );
  }

  static Future<List<Map<String, dynamic>>> _loadList(String path) async {
    String raw;
    try {
      raw = await rootBundle.loadString(path);
    } catch (e) {
      throw KnowledgeBaseException('Gagal memuat seed: $path ($e)');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (e) {
      throw KnowledgeBaseException('JSON tidak sah: $path ($e)');
    }
    if (decoded is! List) {
      throw KnowledgeBaseException('Seed "$path" harus berupa array dokumen');
    }
    return [
      for (final item in decoded)
        item is Map
            ? Map<String, dynamic>.from(item)
            : throw KnowledgeBaseException(
                'Seed "$path" memuat elemen bukan objek',
              ),
    ];
  }
}

/// Hasil pemuatan seed mentah (Map, belum dipetakan ke entity).
class SeedData {
  final List<Map<String, dynamic>> services;
  final List<Map<String, dynamic>> questions;
  final List<Map<String, dynamic>> requirements;
  final List<Map<String, dynamic>> steps;
  final Map<String, List<Map<String, dynamic>>> rules;

  const SeedData({
    required this.services,
    required this.questions,
    required this.requirements,
    required this.steps,
    required this.rules,
  });
}
