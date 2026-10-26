import 'outcome.dart';

/// Aksi yang diterapkan mesin ketika sebuah [Rule] menyala (§7, §10.4).
class RuleAction {
  /// ID persyaratan yang ditambahkan (harus ada di katalog `requirements`).
  final List<String> addRequirements;

  /// Varian tahapan; pada v1.4 belum dipakai — tahapan umum berasal dari
  /// `services/{id}.stepsDasar` (§11.5, U-01).
  final List<String> addSteps;

  /// Fakta turunan yang ditulis ke kamus fakta, mis. `jenis_pengajuan_ktp`.
  final Map<String, String> addFacts;

  /// Teks catatan yang tampil di hasil panduan.
  final List<String> addNotes;

  /// null = aturan tidak menetapkan keputusan (outcome sementara tidak ada).
  final Outcome? setOutcome;

  /// true = tidak ada pertanyaan tersisa yang dapat mengubah keputusan;
  /// sesi berhenti (§10.6).
  final bool terminal;

  const RuleAction({
    this.addRequirements = const [],
    this.addSteps = const [],
    this.addFacts = const {},
    this.addNotes = const [],
    this.setOutcome,
    this.terminal = false,
  });
}
