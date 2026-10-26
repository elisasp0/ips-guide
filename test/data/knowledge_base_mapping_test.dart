import 'package:flutter_test/flutter_test.dart';
import 'package:ips_guide/data/models/seed_mappers.dart';
import 'package:ips_guide/domain/entities/outcome.dart';
import 'package:ips_guide/domain/entities/rule_condition.dart';

void main() {
  group('mapService', () {
    final doc = {
      'id': 'ktp',
      'nama': 'KTP',
      'deskripsi': 'd',
      'ikon': 'badge',
      'urutan': 1,
      'estimasiHariMin': 3,
      'estimasiHariMax': 7,
      'aktif': true,
      'stepsDasar': ['STEP_LOKET'],
    };

    test('dokumen sah → entity terisi', () {
      final s = SeedMappers.mapService(doc);
      expect(s.id, 'ktp');
      expect(s.aktif, isTrue);
      expect(s.stepsDasar, ['STEP_LOKET']);
    });

    test('field hilang → FormatException', () {
      for (final field in ['id', 'nama', 'urutan', 'estimasiHariMin']) {
        final rusak = Map<String, dynamic>.of(doc)..remove(field);
        expect(() => SeedMappers.mapService(rusak), throwsFormatException,
            reason: 'field "$field" hilang harus ditolak');
      }
    });

    test('"aktif" tidak ada → FormatException (T-07, §8.3)', () {
      final rusak = Map<String, dynamic>.of(doc)..remove('aktif');
      expect(() => SeedMappers.mapService(rusak), throwsFormatException);
    });
  });

  group('mapQuestion', () {
    final doc = {
      'id': 'KTP-Q05',
      'serviceId': 'ktp',
      'factKey': 'alasan_pengajuan_ktp',
      'teks': 'Apa alasan pengajuan?',
      'urutan': 50,
      'aktif': true,
      'showIf': {'fact': 'sudah_punya_ktp', 'op': 'equals', 'value': 'ya'},
      'opsi': [
        {'value': 'hilang', 'label': 'Hilang'},
      ],
    };

    test('showIf dipetakan; tanpa showIf → null', () {
      final q = SeedMappers.mapQuestion(doc);
      expect(q.showIf!.fact, 'sudah_punya_ktp');
      expect(q.showIf!.op, ConditionOperator.equals);
      expect(q.showIf!.value, 'ya');

      final tanpaShowIf = Map<String, dynamic>.of(doc)..remove('showIf');
      expect(SeedMappers.mapQuestion(tanpaShowIf).showIf, isNull);
    });

    test('"aktif" tidak ada → FormatException', () {
      final rusak = Map<String, dynamic>.of(doc)..remove('aktif');
      expect(() => SeedMappers.mapQuestion(rusak), throwsFormatException);
    });
  });

  group('mapRule', () {
    final doc = {
      'id': 'KTP-R03',
      'serviceId': 'ktp',
      'priority': 70,
      'aktif': true,
      'deskripsi': 'KTP baru',
      'when': [
        {'fact': 'kategori_usia', 'op': 'equals', 'value': '17_ke_atas'},
      ],
      'then': {
        'setOutcome': 'dapat_diproses',
        'terminal': false,
        'addRequirements': ['REQ_F101'],
        'addFacts': {'jenis_pengajuan_ktp': 'baru'},
        'addNotes': [],
      },
    };

    test('dokumen sah → entity terisi', () {
      final r = SeedMappers.mapRule(doc);
      expect(r.then.setOutcome, Outcome.dapatDiproses);
      expect(r.then.addFacts['jenis_pengajuan_ktp'], 'baru');
    });

    test('tanpa setOutcome/terminal/opsional → default aman (KTP-R10)', () {
      final r10 = Map<String, dynamic>.of(doc)
        ..['id'] = 'KTP-R10'
        ..['then'] = {'terminal': false, 'addRequirements': <String>[], 'addNotes': []};
      final r = SeedMappers.mapRule(r10);
      expect(r.then.setOutcome, isNull);
      expect(r.then.terminal, isFalse);
    });

    test('setOutcome tidak dikenal → FormatException', () {
      final rusak = Map<String, dynamic>.of(doc)
        ..['then'] = {'setOutcome': 'entahlah', 'terminal': false};
      expect(() => SeedMappers.mapRule(rusak), throwsFormatException);
    });

    test('"aktif" tidak ada → FormatException', () {
      final rusak = Map<String, dynamic>.of(doc)..remove('aktif');
      expect(() => SeedMappers.mapRule(rusak), throwsFormatException);
    });
  });

  group('mapCondition', () {
    test('klausa komposit any dipetakan rekursif', () {
      final c = SeedMappers.mapCondition({
        'any': [
          {'fact': 'a', 'op': 'equals', 'value': '1'},
          {'fact': 'b', 'op': 'notEquals', 'value': '2'},
        ],
      });
      expect(c.any, hasLength(2));
      expect(c.fact, isEmpty);
    });

    test('operator tidak dikenal → FormatException', () {
      expect(
        () => SeedMappers.mapCondition(
            {'fact': 'a', 'op': 'mirip_saja', 'value': 'x'}),
        throwsFormatException,
      );
    });

    test('value list untuk inList dipertahankan', () {
      final c = SeedMappers.mapCondition({
        'fact': 'a',
        'op': 'inList',
        'value': ['x', 'y'],
      });
      expect(c.value, ['x', 'y']);
    });
  });

  group('mapRequirement & mapStep', () {
    test('"aktif" wajib pada katalog juga', () {
      expect(
        () => SeedMappers.mapRequirement({'id': 'REQ_X', 'nama': 'x'}),
        throwsFormatException,
      );
      expect(
        () => SeedMappers.mapStep({
          'id': 'STEP_X',
          'judul': 'x',
          'keterangan': 'y',
          'urutan': 10,
        }),
        throwsFormatException,
      );
    });
  });
}
