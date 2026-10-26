import 'package:flutter_test/flutter_test.dart';
import 'package:ips_guide/domain/engine/guidance_session.dart';
import 'package:ips_guide/domain/entities/guidance_result.dart';
import 'package:ips_guide/domain/entities/outcome.dart';

import '../../support/knowledge_base_fixture.dart';

void main() {
  group('Alur KTP (§11.1, §11.2)', () {
    test('<17 belum menikah → berhenti terminal KTP-R01 setelah 2 pertanyaan',
        () {
      final s = GuidanceSession(kbKtp());
      s.answer('kategori_usia', 'di_bawah_17');
      expect(s.currentQuestion!.factKey, 'status_perkawinan');

      s.answer('status_perkawinan', 'belum_menikah');

      expect(s.isTerminal, isTrue);
      expect(s.isFinished, isTrue);
      expect(s.answers, hasLength(2)); // Q04/Q05 tidak ditanya

      final r = s.buildResult();
      expect(r.outcome, Outcome.tidakDapatDiproses);
      expect(r.terminal, isTrue);
      expect(r.tampilkanDetail, isFalse); // persyaratan disembunyikan §10.7
      expect(r.requirements, isEmpty);
      expect(r.steps, isEmpty);
      // Catatan R01 tetap tampil.
      expect(r.notes.map((n) => n.sourceRuleId), contains('KTP-R01'));
      // Data tetap ada di trace (§10.7).
      expect(r.trace.map((t) => t.ruleId), contains('KTP-R01'));
    });

    test('17+ belum punya, Tegalsari → dapat diproses, 5 tahapan umum', () {
      final s = GuidanceSession(kbKtp());
      s.answer('kategori_usia', '17_ke_atas');
      expect(s.currentQuestion!.factKey, 'sudah_punya_ktp');
      s.answer('sudah_punya_ktp', 'tidak');
      expect(s.inference.outcome, Outcome.dapatDiproses); // sementara (R03)
      expect(s.isTerminal, isFalse); // masih ditanya Q04

      s.answer('domisili_pemohon', 'tegalsari');
      expect(s.isFinished, isTrue); // pertanyaan habis (Q05 showIf false)
      expect(s.answers, hasLength(3)); // Q05 tidak ditanya

      final r = s.buildResult();
      expect(r.outcome, Outcome.dapatDiproses);
      expect(r.tampilkanDetail, isTrue);
      expect(
        r.requirements.map((q) => q.id),
        containsAll(
            ['REQ_KK_ASLI', 'REQ_AKTA_KELAHIRAN', 'REQ_PENGANTAR_RTRW', 'REQ_F101']),
      );
      // Explanation facility: sourceRuleId = KTP-R03.
      expect(r.requirements.every((q) => q.sourceRuleId == 'KTP-R03'), isTrue);
      // Tahapan dari stepsDasar, urut ASC.
      expect(
        r.steps.map((t) => t.id).toList(),
        [
          'STEP_LOKET',
          'STEP_SERAH_BERKAS',
          'STEP_VERIFIKASI',
          'STEP_REKAM',
          'STEP_AMBIL',
        ],
      );
    });

    test('Tahapan S03–S07 identik (U-01, §11.5) — hanya dokumen yang beda',
        () {
      GuidanceResult build(Map<String, String> jawaban) {
        final s = GuidanceSession(kbKtp());
        for (final e in jawaban.entries) {
          s.answer(e.key, e.value);
        }
        return s.buildResult();
      }

      final tahapanBaru = build({
        'kategori_usia': '17_ke_atas',
        'sudah_punya_ktp': 'tidak',
        'domisili_pemohon': 'tegalsari',
      }).steps.map((t) => t.id).toList();

      final tahapanHilang = build({
        'kategori_usia': '17_ke_atas',
        'sudah_punya_ktp': 'ya',
        'domisili_pemohon': 'tegalsari',
        'alasan_pengajuan_ktp': 'hilang',
      }).steps.map((t) => t.id).toList();

      final tahapanRusak = build({
        'kategori_usia': '17_ke_atas',
        'sudah_punya_ktp': 'ya',
        'domisili_pemohon': 'tegalsari',
        'alasan_pengajuan_ktp': 'rusak',
      }).steps.map((t) => t.id).toList();

      expect(tahapanBaru, tahapanHilang);
      expect(tahapanBaru, tahapanRusak);
      // Tetapi persyaratannya berbeda.
      final reqHilang = build({
        'kategori_usia': '17_ke_atas',
        'sudah_punya_ktp': 'ya',
        'domisili_pemohon': 'tegalsari',
        'alasan_pengajuan_ktp': 'hilang',
      }).requirements.map((q) => q.id);
      expect(reqHilang, contains('REQ_SURAT_KEHILANGAN'));
    });

    test('17+ sudah punya, luar Tegalsari → terminal KTP-R08, Q05 dilewati',
        () {
      final s = GuidanceSession(kbKtp());
      s.answer('kategori_usia', '17_ke_atas');
      s.answer('sudah_punya_ktp', 'ya');
      expect(s.currentQuestion!.factKey, 'domisili_pemohon'); // Q04 sebelum Q05

      s.answer('domisili_pemohon', 'luar_tegalsari');

      expect(s.isTerminal, isTrue);
      expect(s.answers, hasLength(3)); // alasan tidak ditanya (T-03)
      final r = s.buildResult();
      expect(r.outcome, Outcome.tidakDapatDiproses);
      expect(r.requirements, isEmpty); // tidak menyesatkan (§10.7)
      expect(r.notes.map((n) => n.sourceRuleId), contains('KTP-R08'));
    });

    test('<17 pernah menikah, Tegalsari → outcome null "belum tersedia" (U-02)',
        () {
      final s = GuidanceSession(kbKtp());
      s.answer('kategori_usia', 'di_bawah_17');
      s.answer('status_perkawinan', 'pernah_menikah');
      // Sesi tetap berjalan sampai Q4 — KTP-R10 tidak menghentikan.
      expect(s.currentQuestion!.factKey, 'domisili_pemohon');

      s.answer('domisili_pemohon', 'tegalsari');
      expect(s.isFinished, isTrue); // pertanyaan habis, bukan terminal
      expect(s.isTerminal, isFalse);

      final r = s.buildResult();
      expect(r.outcome, isNull); // → H5 "Panduan belum tersedia"
      expect(r.requirements, isEmpty); // tidak ada persyaratan yang dikarang
      expect(r.notes.map((n) => n.sourceRuleId), contains('KTP-R10'));
    });
  });

  group('Pemangkasan fakta jalur lama (U-04, §10.4.2)', () {
    test('kembali ke Q1 lalu ubah jawaban → fakta jalur lama terpangkas', () {
      final s = GuidanceSession(kbKtp());
      s.answer('kategori_usia', '17_ke_atas');
      s.answer('sudah_punya_ktp', 'ya');
      s.answer('domisili_pemohon', 'tegalsari');
      s.answer('alasan_pengajuan_ktp', 'hilang');
      expect(s.inference.addedRequirements, contains('REQ_SURAT_KEHILANGAN'));

      // Kembali ke Q1 dan mengubah: kategori_usia = di_bawah_17.
      s.kembali('kategori_usia');

      // Pemangkasan iteratif: sudah_punya_ktp ikut hilang, lalu alasan ikut.
      expect(s.answers.containsKey('sudah_punya_ktp'), isFalse);
      expect(s.answers.containsKey('alasan_pengajuan_ktp'), isFalse);
      // domisili_pemohon (showIf null = selalu layak) TIDAK dipangkas.
      expect(s.answers.containsKey('domisili_pemohon'), isTrue);
      // Tidak ada aturan basi: R04 tidak menyala.
      expect(s.inference.fired.map((r) => r.id), isNot(contains('KTP-R04')));
      expect(s.inference.addedRequirements, isNot(contains('REQ_SURAT_KEHILANGAN')));
      // Pertanyaan berikutnya kembali ke jalur <17.
      expect(s.currentQuestion!.factKey, 'kategori_usia');
    });

    test('setelah pangkas, jalur baru berjalan bersih (S34)', () {
      final s = GuidanceSession(kbKtp());
      s.answer('kategori_usia', '17_ke_atas');
      s.answer('sudah_punya_ktp', 'ya');
      s.answer('alasan_pengajuan_ktp', 'hilang');
      s.kembali('kategori_usia');
      s.answer('kategori_usia', 'di_bawah_17');

      s.answer('status_perkawinan', 'menikah');

      final r = s.buildResult();
      expect(r.outcome, Outcome.denganCatatan); // KTP-R02
      final ids = r.requirements.map((q) => q.id).toList();
      expect(ids, contains('REQ_KK_ASLI'));
      expect(ids, isNot(contains('REQ_SURAT_KEHILANGAN'))); // tidak tersisa basi
    });
  });

  group('Alur KK (§11.3)', () {
    test('perubahan kelahiran, luar Tegalsari → terminal KK-R10', () {
      final s = GuidanceSession(kbKk());
      s.answer('kondisi_kk', 'perubahan_anggota');
      s.answer('jenis_perubahan_kk', 'kelahiran');
      s.answer('domisili_pemohon', 'luar_tegalsari');

      expect(s.isTerminal, isTrue);
      final r = s.buildResult();
      expect(r.outcome, Outcome.tidakDapatDiproses);
      expect(r.notes.map((n) => n.sourceRuleId), contains('KK-R10'));
    });

    test('pindah datang, luar Tegalsari → KK-R10 TIDAK menyala (notEquals)',
        () {
      final s = GuidanceSession(kbKk());
      s.answer('kondisi_kk', 'pindah_datang');
      s.answer('domisili_pemohon', 'luar_tegalsari');

      expect(s.isTerminal, isFalse); // KK-R10: kondisi ≠ pindah_datang gagal
      expect(s.isFinished, isTrue);
      expect(s.buildResult().outcome, Outcome.dapatDiproses); // KK-R02
    });

    test('perubahan kelahiran, Tegalsari → dapat diproses (KK-R03)', () {
      final s = GuidanceSession(kbKk());
      s.answer('kondisi_kk', 'perubahan_anggota');
      s.answer('jenis_perubahan_kk', 'kelahiran');
      s.answer('domisili_pemohon', 'tegalsari');

      final r = s.buildResult();
      expect(r.outcome, Outcome.dapatDiproses);
      expect(r.requirements.map((q) => q.id), contains('REQ_AKTA_KELAHIRAN'));
      // Tahapan KK memakai STEP_DISDUKCAPIL, bukan STEP_REKAM.
      expect(r.steps.map((t) => t.id), contains('STEP_DISDUKCAPIL'));
      expect(r.steps.map((t) => t.id), isNot(contains('STEP_REKAM')));
    });
  });

  group('Alur Surat Domisili (§11.4)', () {
    test('tinggal sementara tanpa bukti, usaha → dengan catatan (DOM-R03)',
        () {
      final s = GuidanceSession(kbDomisili());
      s.answer('keperluan_domisili', 'usaha');
      s.answer('status_tinggal', 'tinggal_sementara');
      expect(s.currentQuestion!.factKey, 'punya_bukti_tinggal');
      s.answer('punya_bukti_tinggal', 'tidak');

      final r = s.buildResult();
      expect(r.outcome, Outcome.denganCatatan); // R03 (85) > R02 (80)
      // Persyaratan R02 + R04 digabung (akumulatif, dedup).
      final ids = r.requirements.map((q) => q.id).toList();
      expect(ids, containsAll(['REQ_BUKTI_TINGGAL', 'REQ_FOTO_LOKASI_USAHA']));
      expect(ids.toSet().length, ids.length); // dedup
      expect(r.notes.map((n) => n.sourceRuleId), contains('DOM-R03'));
    });

    test('warga tetap, sekolah → dapat diproses + catatan DOM-R05', () {
      final s = GuidanceSession(kbDomisili());
      s.answer('keperluan_domisili', 'sekolah');
      s.answer('status_tinggal', 'warga_tetap');
      expect(s.isFinished, isTrue); // Q03 showIf false

      final r = s.buildResult();
      expect(r.outcome, Outcome.dapatDiproses);
      expect(r.notes.map((n) => n.sourceRuleId), contains('DOM-R05'));
    });
  });

  test('KTP valid tanpa CONFIG_WARNING (basis pengetahuan sehat)', () {
    final s = GuidanceSession(kbKtp());
    s.answer('kategori_usia', 'di_bawah_17');
    s.answer('status_perkawinan', 'belum_menikah');
    expect(s.inference.warnings, isEmpty);
  });

  test('menjawab factKey tak dikenal ditolak', () {
    final s = GuidanceSession(kbKtp());
    expect(() => s.answer('fakta_hantu', 'ya'), throwsArgumentError);
  });
}
