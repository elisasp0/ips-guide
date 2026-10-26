import 'package:ips_guide/domain/entities/guidance_question.dart';
import 'package:ips_guide/domain/entities/guidance_service.dart';
import 'package:ips_guide/domain/entities/knowledge_base.dart';
import 'package:ips_guide/domain/entities/requirement.dart';
import 'package:ips_guide/domain/entities/rule.dart';

/// Antarmuka repository basis pengetahuan (§3.3) — satu-satunya pintu masuk
/// data (§3.1 aturan 3).
///
/// Dua implementasi: [InMemoryKnowledgeBaseRepository] (Tahap 2–4, dari
/// seed JSON) dan FirestoreKnowledgeBaseRepository (Tahap 6+). UI tidak
/// berubah saat sumber data berganti.
///
/// Operasi tulis (Tahap 7) WAJIB memvalidasi basis pengetahuan hasil
/// gabungan sebelum menyimpan (§12.5, V-02) — validator yang sama dengan
/// jalur muat.
abstract class KnowledgeBaseRepository {
  /// Untuk H3 — SEMUA layanan TERMASUK yang nonaktif (T-06): layanan
  /// nonaktif tetap tampil bertanda "belum tersedia".
  Future<List<GuidanceService>> loadServices();

  /// Untuk H4/H5 — basis pengetahuan satu layanan.
  ///
  /// Melempar [KnowledgeBaseException] bila `serviceId` tidak dikenal atau
  /// basis pengetahuannya gagal validasi saat dimuat (S20, S38, S45).
  Future<KnowledgeBase> loadService(String serviceId);

  /// Simpan perubahan satu aturan (prioritas/deskripsi/`aktif`) dari H6.
  ///
  /// Bila basis pengetahuan hasil gabungan melanggar aturan validasi,
  /// penyimpanan DITOLAK dan basis pengetahuan lama tetap utuh (S44).
  Future<void> simpanAturan(String serviceId, Rule aturan);

  /// Simpan perubahan teks/`aktif` satu pertanyaan dari H6.
  Future<void> simpanPertanyaan(
    String serviceId,
    GuidanceQuestion pertanyaan,
  );

  /// Simpan perubahan nama/keterangan satu persyaratan dari H6 (S28).
  Future<void> simpanPersyaratan(Requirement persyaratan);
}

/// Galat pemuatan/pencarian basis pengetahuan (S20, S38, S45).
class KnowledgeBaseException implements Exception {
  final String message;

  /// Daftar pelanggaran validasi (mis. "V-1: ...", "V-2: ...") bila ada.
  final List<String> errors;

  const KnowledgeBaseException(this.message, [this.errors = const []]);

  @override
  String toString() =>
      'KnowledgeBaseException: $message'
      '${errors.isEmpty ? '' : '\n  - ${errors.join('\n  - ')}'}';
}
