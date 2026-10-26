import 'package:ips_guide/domain/entities/answer_option.dart';
import 'package:ips_guide/domain/entities/guidance_question.dart';
import 'package:ips_guide/domain/entities/guidance_service.dart';
import 'package:ips_guide/domain/entities/outcome.dart';
import 'package:ips_guide/domain/entities/requirement.dart';
import 'package:ips_guide/domain/entities/rule.dart';
import 'package:ips_guide/domain/entities/rule_action.dart';
import 'package:ips_guide/domain/entities/rule_condition.dart';
import 'package:ips_guide/domain/entities/service_step.dart';

/// Pemetaan dokumen seed/Firestore (Map) → entity domain (§3.1: DTO tidak
/// bocor ke domain).
///
/// Ketat sesuai §8.3: field `aktif` **wajib ada secara eksplisit** — dokumen
/// tanpa `aktif` akan "hilang" diam-diam pada query Firestore, sehingga
/// penulisannya ditolak sejak di sini (T-07).
class SeedMappers {
  static Never _missing(String field, String docId) =>
      throw FormatException(
        'Field "$field" wajib ada dan tidak boleh null pada dokumen "$docId"',
      );

  static String _str(Map<String, dynamic> doc, String field) {
    final v = doc[field];
    if (v is! String || v.isEmpty) _missing(field, _idOf(doc));
    return v;
  }

  static int _int(Map<String, dynamic> doc, String field) {
    final v = doc[field];
    if (v is! int) _missing(field, _idOf(doc));
    return v;
  }

  static bool _bool(Map<String, dynamic> doc, String field) {
    final v = doc[field];
    if (v is! bool) _missing(field, _idOf(doc));
    return v;
  }

  static String _idOf(Map<String, dynamic> doc) =>
      doc['id'] is String ? doc['id'] as String : '?';

  // -------------------------------------------------------------------------

  static GuidanceService mapService(Map<String, dynamic> doc) {
    final stepsDasar = doc['stepsDasar'];
    return GuidanceService(
      id: _str(doc, 'id'),
      nama: _str(doc, 'nama'),
      deskripsi: _str(doc, 'deskripsi'),
      ikon: _str(doc, 'ikon'),
      urutan: _int(doc, 'urutan'),
      estimasiHariMin: _int(doc, 'estimasiHariMin'),
      estimasiHariMax: _int(doc, 'estimasiHariMax'),
      aktif: _bool(doc, 'aktif'),
      stepsDasar: stepsDasar is List
          ? List<String>.from(stepsDasar)
          : _missing('stepsDasar', _idOf(doc)),
    );
  }

  static GuidanceQuestion mapQuestion(Map<String, dynamic> doc) {
    final opsiRaw = doc['opsi'];
    if (opsiRaw is! List) _missing('opsi', _idOf(doc));
    final showIfRaw = doc['showIf'];
    return GuidanceQuestion(
      id: _str(doc, 'id'),
      serviceId: _str(doc, 'serviceId'),
      factKey: _str(doc, 'factKey'),
      teks: _str(doc, 'teks'),
      urutan: _int(doc, 'urutan'),
      aktif: _bool(doc, 'aktif'),
      opsi: [
        for (final o in opsiRaw)
          o is Map
              ? AnswerOption(
                  value: _str(Map<String, dynamic>.from(o), 'value'),
                  label: _str(Map<String, dynamic>.from(o), 'label'),
                  keterangan: o['keterangan'] as String?,
                )
              : _missing('opsi', _idOf(doc)),
      ],
      showIf: showIfRaw == null
          ? null
          : mapCondition(
              showIfRaw is Map ? Map<String, dynamic>.from(showIfRaw) : null,
            ),
    );
  }

  static Rule mapRule(Map<String, dynamic> doc) {
    final whenRaw = doc['when'];
    if (whenRaw is! List) _missing('when', _idOf(doc));
    final thenRaw = doc['then'];
    if (thenRaw is! Map) _missing('then', _idOf(doc));
    final then = Map<String, dynamic>.from(thenRaw);

    final setOutcomeRaw = then['setOutcome'];
    if (setOutcomeRaw != null &&
        Outcome.fromWireName(setOutcomeRaw as String) == null) {
      throw FormatException(
        'setOutcome tidak dikenal: "$setOutcomeRaw" pada aturan "${_idOf(doc)}"',
      );
    }

    return Rule(
      id: _str(doc, 'id'),
      serviceId: _str(doc, 'serviceId'),
      priority: _int(doc, 'priority'),
      deskripsi: _str(doc, 'deskripsi'),
      aktif: _bool(doc, 'aktif'),
      when: [
        for (final c in whenRaw)
          c is Map
              ? mapCondition(Map<String, dynamic>.from(c))
              : _missing('when', _idOf(doc)),
      ],
      then: RuleAction(
        addRequirements: then['addRequirements'] is List
            ? List<String>.from(then['addRequirements'] as List)
            : const [],
        addSteps: then['addSteps'] is List
            ? List<String>.from(then['addSteps'] as List)
            : const [],
        addFacts: then['addFacts'] is Map
            ? Map<String, String>.from(then['addFacts'] as Map)
            : const {},
        addNotes: then['addNotes'] is List
            ? List<String>.from(then['addNotes'] as List)
            : const [],
        setOutcome:
            setOutcomeRaw == null ? null : Outcome.fromWireName(setOutcomeRaw),
        terminal: then['terminal'] is bool ? then['terminal'] as bool : false,
      ),
    );
  }

  static Requirement mapRequirement(Map<String, dynamic> doc) {
    // `aktif` wajib eksplisit (§8.3) meski entity katalog tidak menyimpannya.
    _bool(doc, 'aktif');
    return Requirement(
      id: _str(doc, 'id'),
      nama: _str(doc, 'nama'),
      keterangan: doc['keterangan'] as String?,
      wajib: doc['wajib'] is bool ? doc['wajib'] as bool : true,
      sourceRuleId: doc['sourceRuleId'] as String? ?? '',
    );
  }

  static ServiceStep mapStep(Map<String, dynamic> doc) {
    // `aktif` wajib eksplisit (§8.3) meski entity katalog tidak menyimpannya.
    _bool(doc, 'aktif');
    return ServiceStep(
      id: _str(doc, 'id'),
      judul: _str(doc, 'judul'),
      keterangan: _str(doc, 'keterangan'),
      urutan: _int(doc, 'urutan'),
    );
  }

  /// Memetakan satu klausa kondisi; komposit `any` dipetakan rekursif.
  static RuleCondition mapCondition(Map<String, dynamic>? doc) {
    if (doc == null) {
      throw const FormatException('Kondisi tidak boleh null');
    }
    final anyRaw = doc['any'];
    if (anyRaw != null) {
      if (anyRaw is! List || anyRaw.isEmpty) {
        throw const FormatException('Klausa "any" harus berupa array tak kosong');
      }
      return RuleCondition.any([
        for (final child in anyRaw)
          child is Map
              ? mapCondition(Map<String, dynamic>.from(child))
              : throw const FormatException('Klausa "any" memuat elemen tak sah'),
      ]);
    }

    final opRaw = _str(doc, 'op');
    ConditionOperator? op;
    for (final o in ConditionOperator.values) {
      if (o.wireName == opRaw) {
        op = o;
        break;
      }
    }
    if (op == null) {
      throw FormatException('Operator kondisi tidak dikenal: "$opRaw"');
    }
    return RuleCondition(
      fact: _str(doc, 'fact'),
      op: op,
      value: doc['value'],
    );
  }
}
