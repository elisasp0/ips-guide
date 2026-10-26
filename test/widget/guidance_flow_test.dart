import 'package:flutter_test/flutter_test.dart';
import 'package:ips_guide/app/app.dart';

import '../support/widget_utils.dart';

/// Uji alur H4 → H5 (§15 Tahap 4 bukti: S03 dan S14 dapat ditelusuri penuh).
void main() {
  setUpAll(siapkanRepository);

  Future<void> bukaAplikasi(WidgetTester tester) async {
    await tester.pumpWidget(bungkusAplikasi(const IpsGuideApp()));
    await tunggu(tester, find.text('Mulai Panduan'));
  }

  /// Pilih opsi lalu tekan Lanjut.
  Future<void> jawab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pump();
    await tester.tap(find.text('Lanjut'));
    await tenang(tester);
  }

  testWidgets('S03: KTP baru di Tegalsari → Dapat diproses dengan '
      'checklist dan 5 tahapan', (tester) async {
    await bukaAplikasi(tester);

    await tester.tap(find.text('Mulai Panduan'));
    await tunggu(tester, find.text('Pilih Layanan'));
    await tester.tap(find.text('Kartu Tanda Penduduk Elektronik'));

    // Q1 kategori_usia
    await tunggu(tester, find.text('Berapa usia Anda saat ini?'));
    await jawab(tester, '17 tahun ke atas');
    // Q3 sudah_punya_ktp
    await tunggu(tester, find.text('Apakah Anda sudah memiliki KTP?'));
    await jawab(tester, 'Tidak');
    // Q4 domisili
    await tunggu(tester, find.text('Di mana domisili Anda?'));
    await jawab(tester, 'Kelurahan Tegalsari');

    // H5 — sesi selesai, pertanyaan habis.
    await tunggu(tester, find.text('Dapat diproses'));
    expect(find.text('Kartu Keluarga asli'), findsOneWidget);
    expect(find.text('Akta kelahiran'), findsOneWidget);
    expect(find.text('Datang ke loket pelayanan'), findsOneWidget);
    expect(find.text('Pengambilan dokumen'), findsOneWidget);
    // Explanation facility.
    expect(find.text('Mengapa hasilnya seperti ini?'), findsOneWidget);
  });

  testWidgets('S14: KK kelahiran luar Tegalsari → Belum dapat diproses, '
      'persyaratan disembunyikan tetapi trace terekam', (tester) async {
    await bukaAplikasi(tester);

    await tester.tap(find.text('Kartu Keluarga'));
    await tunggu(tester, find.text('Bagaimana kondisi Kartu Keluarga Anda?'));

    await jawab(tester, 'Perubahan anggota keluarga');
    await tunggu(tester, find.text('Perubahan apa yang terjadi?'));
    await jawab(tester, 'Kelahiran');
    await tunggu(tester, find.text('Di mana domisili Anda?'));
    await jawab(tester, 'Di luar Kelurahan Tegalsari');

    await tunggu(tester, find.text('Belum dapat diproses di sini'));
    // Persyaratan & tahapan disembunyikan (§10.7) — KK-R03 sempat menambah.
    expect(find.text('Akta kelahiran'), findsNothing);
    expect(find.text('Dokumen yang perlu disiapkan'), findsNothing);
    expect(find.text('Tahapan pelayanan'), findsNothing);
    // Tetap ada di "Mengapa?".
    await tester.tap(find.text('Mengapa hasilnya seperti ini?'));
    await tunggu(tester, find.text('KK-R10 — penentu status'));
  });

  testWidgets('Tombol Kembali menghapus jawaban terakhir dan pertanyaan '
      'ditanyakan ulang (T-04)', (tester) async {
    await bukaAplikasi(tester);

    await tester.tap(find.text('Mulai Panduan'));
    await tunggu(tester, find.text('Pilih Layanan'));
    await tester.tap(find.text('Kartu Tanda Penduduk Elektronik'));

    await tunggu(tester, find.text('Berapa usia Anda saat ini?'));
    await jawab(tester, '17 tahun ke atas');
    await tunggu(tester, find.text('Apakah Anda sudah memiliki KTP?'));

    await tester.tap(find.text('Kembali'));
    await tenang(tester);
    // Kembali ke Q1 — pertanyaan ditanyakan ulang.
    expect(find.text('Berapa usia Anda saat ini?'), findsOneWidget);

    // Jawab berbeda → jalur baru berjalan bersih.
    await jawab(tester, 'Di bawah 17 tahun');
    await tunggu(tester, find.text('Apa status perkawinan Anda?'));
  });

  testWidgets('Tab Panduan menampilkan keadaan kosong saat belum ada sesi',
      (tester) async {
    await bukaAplikasi(tester);

    await tester.tap(find.text('Panduan').last);
    await tunggu(tester, find.text('Belum ada panduan yang sedang berjalan'));
  });
}
