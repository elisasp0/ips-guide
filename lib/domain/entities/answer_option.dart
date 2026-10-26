/// Satu pilihan jawaban pada [GuidanceQuestion] (§7).
class AnswerOption {
  final String value; // nilai yang ditulis ke fakta, mis. `ya`
  final String label; // teks yang tampil di UI, mis. "Ya"
  final String? keterangan;

  const AnswerOption({
    required this.value,
    required this.label,
    this.keterangan,
  });
}
