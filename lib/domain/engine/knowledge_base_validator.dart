import '../entities/knowledge_base.dart';
import '../entities/rule.dart';
import '../entities/rule_condition.dart';

/// Validasi basis pengetahuan saat DIMUAT, bukan saat runtime (§10.4.1 poin 5).
///
/// Mencakup pemeriksaan struktural + tiga invarian terminal V-01 (§10.6.1):
/// - **V-1**: aturan `terminal: true` wajib menetapkan `setOutcome`.
/// - **V-2**: dua aturan terminal pada layanan sama boleh berbeda outcome
///   hanya bila TERBUKTI saling lepas (fakta sama, himpunan nilai beririsan
///   kosong — hanya eksak untuk `equals`/`inList`; operator lain dianggap
///   tidak terbukti, konservatif).
/// - **V-3**: prioritas setiap aturan terminal > seluruh aturan non-terminal
///   pada layanan yang sama — menjamin pemenang `pilihOutcome` selalu aturan
///   terminal.
class KnowledgeBaseValidator {
  static final RegExp _idPattern = RegExp(r'^[A-Z]+-R\d+$');

  static List<String> validate(KnowledgeBase kb) {
    final errors = <String>[];

    // ---- Struktural: pertanyaan ------------------------------------------
    final qIds = <String>{};
    final factKeys = <String>{};
    for (final q in kb.questions) {
      if (!qIds.add(q.id)) {
        errors.add('ID pertanyaan duplikat: ${q.id}');
      }
      if (!factKeys.add(q.factKey)) {
        errors.add('factKey duplikat dalam satu layanan: ${q.factKey} (§10.4.1)');
      }
    }

    // ---- Struktural: persyaratan & tahapan -------------------------------
    final reqIds = <String>{};
    for (final r in kb.requirements) {
      if (!reqIds.add(r.id)) errors.add('ID persyaratan duplikat: ${r.id}');
    }
    final stepIds = <String>{};
    for (final s in kb.steps) {
      if (!stepIds.add(s.id)) errors.add('ID tahapan duplikat: ${s.id}');
    }
    for (final id in kb.service.stepsDasar) {
      if (!stepIds.contains(id)) {
        errors.add('stepsDasar memuat tahap tak dikenal: $id');
      }
    }

    // ---- Struktural: aturan ----------------------------------------------
    final ruleIds = <String>{};
    for (final r in kb.rules) {
      if (!ruleIds.add(r.id)) errors.add('ID aturan duplikat: ${r.id}');
      if (!_idPattern.hasMatch(r.id)) {
        errors.add('ID aturan tidak berformat <LAYANAN>-R<nn>: ${r.id}');
      }
      if (r.serviceId != kb.serviceId) {
        errors.add('Aturan ${r.id} milik layanan ${r.serviceId}, bukan ${kb.serviceId}');
      }
      for (final id in r.then.addRequirements) {
        if (!reqIds.contains(id)) {
          errors.add('Aturan ${r.id} menambah persyaratan tak dikenal: $id');
        }
      }
      for (final id in r.then.addSteps) {
        if (!stepIds.contains(id)) {
          errors.add('Aturan ${r.id} menambah tahap tak dikenal: $id');
        }
      }
    }

    // Pemeriksaan rujukan `showIf.fact` (§10.4.1 poin 5).
    validateShowIfFacts(kb, errors);

    // ---- Invarian terminal V-01 (§10.6.1) ---------------------------------
    errors.addAll(_validateTerminalInvariants(kb));

    return errors;
  }

  /// Pemeriksaan `showIf.fact` — setiap fakta yang dirujuk harus `service`
  /// atau factKey pertanyaan lain pada layanan yang sama.
  static void validateShowIfFacts(KnowledgeBase kb, List<String> errors) {
    final factKeys = kb.questions.map((q) => q.factKey).toSet();
    void walk(RuleCondition c, String owner) {
      final any = c.any;
      if (any != null) {
        for (final child in any) {
          walk(child, owner);
        }
        return;
      }
      if (c.fact != 'service' && !factKeys.contains(c.fact)) {
        errors.add(
          'showIf pada $owner merujuk fakta tak dikenal: ${c.fact} (§10.4.1)',
        );
      }
    }

    for (final q in kb.questions) {
      if (q.showIf != null) walk(q.showIf!, q.id);
    }
  }

  static List<String> _validateTerminalInvariants(KnowledgeBase kb) {
    final errors = <String>[];
    final terminal = kb.rules.where((r) => r.then.terminal).toList();
    final nonTerminal = kb.rules.where((r) => !r.then.terminal).toList();

    // V-1: aturan terminal wajib menetapkan outcome.
    for (final r in terminal) {
      if (r.then.setOutcome == null) {
        errors.add('V-1: aturan terminal ${r.id} tidak menetapkan setOutcome');
      }
    }

    // V-3: prioritas terminal > seluruh non-terminal.
    if (terminal.isNotEmpty && nonTerminal.isNotEmpty) {
      final minTerminal =
          terminal.map((r) => r.priority).reduce((a, b) => a < b ? a : b);
      final maxNonTerminal =
          nonTerminal.map((r) => r.priority).reduce((a, b) => a > b ? a : b);
      if (minTerminal <= maxNonTerminal) {
        errors.add(
          'V-3: prioritas aturan terminal minimum ($minTerminal) harus '
          'lebih tinggi dari non-terminal maksimum ($maxNonTerminal)',
        );
      }
    }

    // V-2: pasangan terminal berbeda outcome harus terbukti saling lepas.
    for (var i = 0; i < terminal.length; i++) {
      for (var j = i + 1; j < terminal.length; j++) {
        final a = terminal[i];
        final b = terminal[j];
        if (a.then.setOutcome == b.then.setOutcome) continue;
        if (!_terbuktiSalingLepas(a, b)) {
          errors.add(
            'V-2: aturan terminal ${a.id} dan ${b.id} berbeda outcome tetapi '
            'tidak terbukti saling lepas',
          );
        }
      }
    }
    return errors;
  }

  /// "Terbukti saling lepas" (§10.6.1): keduanya mengonstrain fakta yang sama
  /// dengan himpunan nilai tidak beririsan — eksak hanya untuk `equals` dan
  /// `inList`; operator lain dianggap TIDAK terbukti (konservatif).
  static bool _terbuktiSalingLepas(Rule a, Rule b) {
    final va = _constrainedValues(a);
    final vb = _constrainedValues(b);
    for (final entry in va.entries) {
      final other = vb[entry.key];
      if (other == null) continue;
      if (entry.value.intersection(other).isEmpty) return true;
    }
    return false;
  }

  /// Himpunan nilai eksak per fakta dari klausa `equals`/`inList`.
  static Map<String, Set<String>> _constrainedValues(Rule r) {
    final map = <String, Set<String>>{};
    void walk(RuleCondition c) {
      final any = c.any;
      if (any != null) {
        for (final child in any) {
          walk(child); // komposit OR: himpunan gabungan, tetap konservatif
        }
        return;
      }
      if (c.op == ConditionOperator.equals) {
        if (c.value is String) {
          map.putIfAbsent(c.fact, () => {}).add(c.value as String);
        }
      } else if (c.op == ConditionOperator.inList) {
        if (c.value is List) {
          map.putIfAbsent(c.fact, () => {}).addAll(
                (c.value as List).map((v) => v.toString()),
              );
        }
      }
      // notEquals, notInList, gte, lte, exists, notExists: tidak eksak.
    }

    for (final c in r.when) {
      walk(c);
    }
    return map;
  }
}
