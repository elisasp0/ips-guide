/// Kamus fakta saat inferensi (§10.3).
///
/// Fakta awal: `service`. Fakta jawaban ditambahkan sesi; fakta turunan
/// (`addFacts`) dihitung ulang oleh inferensi setiap kali.
class FactBase {
  final Map<String, String> _facts;

  FactBase(Map<String, String> facts) : _facts = Map.unmodifiable(facts);

  /// Fakta awal sesi: hanya `service` (§10.3).
  factory FactBase.initial(String serviceId) =>
      FactBase({'service': serviceId});

  /// FactBase = { service } ∪ answers (§10.4).
  factory FactBase.fromAnswers(
    String serviceId,
    Map<String, String> answers,
  ) =>
      FactBase({'service': serviceId, ...answers});

  bool contains(String fact) => _facts.containsKey(fact);

  String? operator [](String fact) => _facts[fact];

  Map<String, String> toMap() => Map.unmodifiable(_facts);

  FactBase withFact(String fact, String value) {
    final next = Map<String, String>.of(_facts);
    next[fact] = value;
    return FactBase(next);
  }

  FactBase withAll(Map<String, String> facts) {
    final next = Map<String, String>.of(_facts);
    next.addAll(facts);
    return FactBase(next);
  }

  FactBase without(String fact) {
    final next = Map<String, String>.of(_facts);
    next.remove(fact);
    return FactBase(next);
  }
}
