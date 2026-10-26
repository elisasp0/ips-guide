import 'answer_option.dart';
import 'rule_condition.dart';

/// Satu pertanyaan panduan (§7).
///
/// `factKey` wajib unik dalam satu layanan (§10.4.1 poin 6) — divalidasi
/// saat basis pengetahuan dimuat, bukan saat runtime.
class GuidanceQuestion {
  final String id;
  final String serviceId;
  final String factKey;
  final String teks;
  final int urutan;
  final List<AnswerOption> opsi;

  /// null = selalu layak ditanyakan. Selain itu dievaluasi dengan logika
  /// tiga nilai: true = layak, false = tidak ditanyakan, undefined (fakta
  /// rujukan belum ada) = menunggu jawaban lain (§10.4.1, U-03).
  final RuleCondition? showIf;
  final bool aktif;

  const GuidanceQuestion({
    required this.id,
    required this.serviceId,
    required this.factKey,
    required this.teks,
    required this.urutan,
    required this.opsi,
    this.showIf,
    this.aktif = true,
  });
}
