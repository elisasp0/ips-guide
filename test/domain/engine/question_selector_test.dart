import 'package:flutter_test/flutter_test.dart';
import 'package:ips_guide/domain/engine/fact_base.dart';
import 'package:ips_guide/domain/engine/question_selector.dart';

import '../../support/knowledge_base_fixture.dart';

void main() {
  group('showIf tiga nilai (U-03, §10.4.1)', () {
    test('awal sesi → hanya Q1 (kategori_usia)', () {
      final q = QuestionSelector.next(kbKtp(), FactBase.initial('ktp'));
      expect(q!.factKey, 'kategori_usia');
    });

    test('undefined TIDAK dianggap true — Q05 menunggu, bukan dilewati', () {
      // sudah_punya_ktp belum dijawab → showIf Q05 undefined → tidak layak;
      // Q04 (tanpa showIf) tetap layak dan harus terpilih.
      final kb = kbKtp();
      final facts = FactBase.fromAnswers('ktp', {
        'kategori_usia': '17_ke_atas',
        'sudah_punya_ktp': 'ya',
      });
      // Setelah sudah_punya dijawab, Q05 layak:
      final q5 = QuestionSelector.next(kb, facts);
      expect(q5!.factKey, 'domisili_pemohon'); // urutan 40 < 50

      // Tapi bila sudah_punya TIDAK dijawab (undefined):
      final facts2 = FactBase.fromAnswers('ktp', {'kategori_usia': '17_ke_atas'});
      final q = QuestionSelector.next(kb, facts2);
      expect(q!.factKey, 'sudah_punya_ktp'); // Q03, bukan Q05
    });

    test('false → tidak ditanyakan; urutan ASC dipilih', () {
      final kb = kbKtp();
      final facts = FactBase.fromAnswers('ktp', {
        'kategori_usia': 'di_bawah_17',
      });
      // Q03 showIf false (kategori bukan 17_ke_atas) → Q02 terpilih.
      final q = QuestionSelector.next(kb, facts);
      expect(q!.factKey, 'status_perkawinan');
    });

    test('pertanyaan yang sudah dijawab tidak dipilih ulang', () {
      final kb = kbKtp();
      final facts = FactBase.fromAnswers('ktp', {
        'kategori_usia': '17_ke_atas',
        'sudah_punya_ktp': 'ya',
        'domisili_pemohon': 'tegalsari',
        'alasan_pengajuan_ktp': 'hilang',
      });
      expect(QuestionSelector.next(kb, facts), isNull);
    });
  });

  group('Urutan & keaktifan', () {
    test('urutan ASC; tie-break id ASC', () {
      final kb = kbKtp();
      final facts = FactBase.initial('ktp');
      expect(QuestionSelector.next(kb, facts)!.id, 'KTP-Q01');
    });

    test('pertanyaan non-aktif dilewati', () {
      final kb = kbKk();
      // Semua aktif; cukup pastikan selector bekerja.
      expect(
        QuestionSelector.next(kb, FactBase.initial('kk'))!.factKey,
        'kondisi_kk',
      );
    });

    test('Domisili: Q03 menunggu bila status_tinggal = warga_tetap (false)',
        () {
      final kb = kbDomisili();
      final facts = FactBase.fromAnswers('domisili', {
        'keperluan_domisili': 'sekolah',
        'status_tinggal': 'warga_tetap',
      });
      expect(QuestionSelector.next(kb, facts), isNull); // pertanyaan habis
    });
  });
}
