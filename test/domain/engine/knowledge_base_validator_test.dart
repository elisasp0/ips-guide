import 'package:flutter_test/flutter_test.dart';
import 'package:ips_guide/domain/engine/knowledge_base_validator.dart';
import 'package:ips_guide/domain/entities/guidance_question.dart';
import 'package:ips_guide/domain/entities/guidance_service.dart';
import 'package:ips_guide/domain/entities/knowledge_base.dart';
import 'package:ips_guide/domain/entities/outcome.dart';
import 'package:ips_guide/domain/entities/rule.dart';
import 'package:ips_guide/domain/entities/rule_action.dart';
import 'package:ips_guide/domain/entities/rule_condition.dart';
import 'package:ips_guide/domain/entities/answer_option.dart';

import '../../support/knowledge_base_fixture.dart';

void main() {
  group('Basis pengetahuan resmi (§11) valid', () {
    test('KTP, KK, dan Domisili lolos seluruh pemeriksaan', () {
      expect(KnowledgeBaseValidator.validate(kbKtp()), isEmpty);
      expect(KnowledgeBaseValidator.validate(kbKk()), isEmpty);
      expect(KnowledgeBaseValidator.validate(kbDomisili()), isEmpty);
    });
  });

  group('Pemeriksaan struktural (§10.4.1)', () {
    test('showIf merujuk fakta tak dikenal → ditolak', () {
      final kb = kbKtp();
      final q = GuidanceQuestion(
        id: 'KTP-Q99',
        serviceId: 'ktp',
        factKey: 'fakta_uji',
        teks: 'uji',
        urutan: 99,
        opsi: const [AnswerOption(value: 'a', label: 'A')],
        showIf: const RuleCondition(
          fact: 'fakta_hantu',
          op: ConditionOperator.equals,
          value: 'a',
        ),
      );
      final kbRusak = KnowledgeBase(
        service: kb.service,
        questions: [...kb.questions, q],
        rules: kb.rules,
        requirements: kb.requirements,
        steps: kb.steps,
      );
      final errors = KnowledgeBaseValidator.validate(kbRusak);
      expect(errors.where((e) => e.contains('showIf')), isNotEmpty);
    });

    test('factKey duplikat dalam satu layanan → ditolak', () {
      final kb = kbKtp();
      final q = GuidanceQuestion(
        id: 'KTP-Q98',
        serviceId: 'ktp',
        factKey: 'kategori_usia', // duplikat dengan KTP-Q01
        teks: 'uji',
        urutan: 98,
        opsi: const [AnswerOption(value: 'a', label: 'A')],
      );
      final kbRusak = KnowledgeBase(
        service: kb.service,
        questions: [...kb.questions, q],
        rules: kb.rules,
        requirements: kb.requirements,
        steps: kb.steps,
      );
      expect(
        KnowledgeBaseValidator.validate(kbRusak)
            .where((e) => e.contains('factKey duplikat')),
        isNotEmpty,
      );
    });

    test('aturan menambah persyaratan tak dikenal → ditolak', () {
      final kb = kbKtp();
      final kbRusak = KnowledgeBase(
        service: kb.service,
        questions: kb.questions,
        rules: [
          ...kb.rules,
          Rule(
            id: 'KTP-R99',
            serviceId: 'ktp',
            priority: 1,
            deskripsi: 'uji',
            when: const [],
            then: const RuleAction(addRequirements: ['REQ_TIDAK_ADA']),
          ),
        ],
        requirements: kb.requirements,
        steps: kb.steps,
      );
      expect(
        KnowledgeBaseValidator.validate(kbRusak)
            .where((e) => e.contains('REQ_TIDAK_ADA')),
        isNotEmpty,
      );
    });

    test('stepsDasar memuat tahap tak dikenal → ditolak', () {
      final kb = kbKtp();
      final serviceRusak = GuidanceService(
        id: kb.service.id,
        nama: kb.service.nama,
        deskripsi: kb.service.deskripsi,
        ikon: kb.service.ikon,
        urutan: kb.service.urutan,
        estimasiHariMin: kb.service.estimasiHariMin,
        estimasiHariMax: kb.service.estimasiHariMax,
        stepsDasar: [...kb.service.stepsDasar, 'STEP_HANTU'],
      );
      final kbRusak = KnowledgeBase(
        service: serviceRusak,
        questions: kb.questions,
        rules: kb.rules,
        requirements: kb.requirements,
        steps: kb.steps,
      );
      expect(
        KnowledgeBaseValidator.validate(kbRusak)
            .where((e) => e.contains('STEP_HANTU')),
        isNotEmpty,
      );
    });
  });

  group('Invarian terminal V-01 (§10.6.1)', () {
    KnowledgeBase denganAturan(KnowledgeBase kb, List<Rule> tambahan) =>
        KnowledgeBase(
          service: kb.service,
          questions: kb.questions,
          rules: [...kb.rules, ...tambahan],
          requirements: kb.requirements,
          steps: kb.steps,
        );

    test('V-1: aturan terminal tanpa setOutcome → ditolak', () {
      final kb = kbDomisili();
      final rusak = denganAturan(kb, [
        Rule(
          id: 'DOM-R90',
          serviceId: 'domisili',
          priority: 99,
          deskripsi: 'terminal tanpa outcome',
          when: const [
            RuleCondition(
              fact: 'status_tinggal',
              op: ConditionOperator.equals,
              value: 'warga_tetap',
            ),
          ],
          then: const RuleAction(terminal: true), // tidak ada setOutcome
        ),
      ]);
      expect(
        KnowledgeBaseValidator.validate(rusak).where((e) => e.contains('V-1')),
        isNotEmpty,
      );
    });

    test('V-3: prioritas terminal ≤ non-terminal → ditolak', () {
      final kb = kbKtp();
      // Turunkan prioritas KTP-R01 (95) di bawah KTP-R10 (88):
      final rules = kb.rules.map((r) {
        if (r.id == 'KTP-R01') {
          return Rule(
            id: r.id,
            serviceId: r.serviceId,
            priority: 60, // < 88
            deskripsi: r.deskripsi,
            when: r.when,
            then: r.then,
          );
        }
        return r;
      }).toList();
      final rusak = KnowledgeBase(
        service: kb.service,
        questions: kb.questions,
        rules: rules,
        requirements: kb.requirements,
        steps: kb.steps,
      );
      expect(
        KnowledgeBaseValidator.validate(rusak).where((e) => e.contains('V-3')),
        isNotEmpty,
      );
    });

    test('V-2: dua terminal beda outcome, tidak terbukti saling lepas → ditolak',
        () {
      final kb = kbDomisili();
      final rusak = denganAturan(kb, [
        Rule(
          id: 'DOM-R91',
          serviceId: 'domisili',
          priority: 96,
          deskripsi: 'terminal A',
          when: const [
            RuleCondition(
              fact: 'status_tinggal',
              op: ConditionOperator.equals,
              value: 'warga_tetap',
            ),
          ],
          then: const RuleAction(
            setOutcome: Outcome.dapatDiproses,
            terminal: true,
          ),
        ),
        Rule(
          id: 'DOM-R92',
          serviceId: 'domisili',
          priority: 97,
          deskripsi: 'terminal B',
          when: const [
            RuleCondition(
              fact: 'status_tinggal',
              op: ConditionOperator.equals,
              value: 'tinggal_sementara',
            ),
          ],
          then: const RuleAction(
            setOutcome: Outcome.tidakDapatDiproses,
            terminal: true,
          ),
        ),
      ]);
      // DOM-R91 & R92 saling lepas (equals pada fakta sama, nilai beda) →
      // LOLOS V-2; namun bentrok dengan aturan terminal yang sudah ada? Tidak
      // ada terminal lain di Domisili. Jadi error V-2 tidak boleh muncul.
      final errors = KnowledgeBaseValidator.validate(rusak);
      expect(errors.where((e) => e.contains('V-2')), isEmpty);
      // Sekarang buat pasangan yang TIDAK terbukti saling lepas:
      final rusak2 = denganAturan(kb, [
        Rule(
          id: 'DOM-R93',
          serviceId: 'domisili',
          priority: 96,
          deskripsi: 'terminal C',
          when: const [
            RuleCondition(
              fact: 'status_tinggal',
              op: ConditionOperator.equals,
              value: 'warga_tetap',
            ),
          ],
          then: const RuleAction(
            setOutcome: Outcome.dapatDiproses,
            terminal: true,
          ),
        ),
        Rule(
          id: 'DOM-R94',
          serviceId: 'domisili',
          priority: 97,
          deskripsi: 'terminal D — notEquals tidak eksak',
          when: [
            RuleCondition(
              fact: 'status_tinggal',
              op: ConditionOperator.notEquals,
              value: 'warga_tetap',
            ),
          ],
          then: const RuleAction(
            setOutcome: Outcome.tidakDapatDiproses,
            terminal: true,
          ),
        ),
      ]);
      expect(
        KnowledgeBaseValidator.validate(rusak2)
            .where((e) => e.contains('V-2')),
        isNotEmpty,
      );
    });
  });
}
