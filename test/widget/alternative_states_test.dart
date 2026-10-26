import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ips_guide/app/app.dart';
import 'package:ips_guide/app/router.dart';

import '../support/widget_utils.dart';

/// Uji keadaan alternatif wajib (§5.1, §15 Tahap 8):
/// - H4 "jawaban belum lengkap";
/// - H5 "panduan belum tersedia" (outcome null);
/// - H5 tanpa sesi aktif.
void main() {
  setUpAll(siapkanRepository);

  Future<void> bukaAplikasi(WidgetTester tester) async {
    await tester.pumpWidget(bungkusAplikasi(const IpsGuideApp()));
    await tunggu(tester, find.text('Mulai Panduan'));
  }

  Future<void> jawab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pump();
    await tester.tap(find.text('Lanjut'));
    await tenang(tester);
  }

  testWidgets('H4: menekan Lanjut tanpa memilih jawaban menjelaskan alasannya',
      (tester) async {
    await bukaAplikasi(tester);

    await tester.tap(find.text('Mulai Panduan'));
    await tunggu(tester, find.text('Pilih Layanan'));
    await tester.tap(find.text('Kartu Tanda Penduduk Elektronik'));
    await tunggu(tester, find.text('Berapa usia Anda saat ini?'));

    await tester.tap(find.text('Lanjut'));
    await tunggu(tester, find.byKey(const Key('h4-pesan-pilihan')));

    expect(
      find.text('Pilih salah satu jawaban untuk melanjutkan.'),
      findsOneWidget,
    );
    // Masih di pertanyaan yang sama — sesi tidak berlanjut.
    expect(find.text('Berapa usia Anda saat ini?'), findsOneWidget);

    // Memilih jawaban menghapus pesan dan melanjutkan sesi.
    await jawab(tester, '17 tahun ke atas');
    await tunggu(tester, find.text('Apakah Anda sudah memiliki KTP?'));
    expect(find.byKey(const Key('h4-pesan-pilihan')), findsNothing);
  });

  testWidgets('H5: S35 outcome null → "Panduan belum tersedia" tanpa detail',
      (tester) async {
    await bukaAplikasi(tester);

    await tester.tap(find.text('Mulai Panduan'));
    await tunggu(tester, find.text('Pilih Layanan'));
    await tester.tap(find.text('Kartu Tanda Penduduk Elektronik'));

    await tunggu(tester, find.text('Berapa usia Anda saat ini?'));
    await jawab(tester, 'Di bawah 17 tahun');
    await tunggu(tester, find.text('Apa status perkawinan Anda?'));
    await jawab(tester, 'Pernah menikah');
    await tunggu(tester, find.text('Di mana domisili Anda?'));
    await jawab(tester, 'Kelurahan Tegalsari');

    await tunggu(tester, find.text('Panduan belum tersedia'));
    // §10.7: persyaratan & tahapan tidak boleh dikarang.
    expect(find.text('Dokumen yang perlu disiapkan'), findsNothing);
    expect(find.text('Tahapan pelayanan'), findsNothing);

    // Explanation facility tetap menjelaskan mengapa kosong: KTP-R10 menyala
    // tetapi tidak menetapkan outcome, jadi tidak ada "penentu status".
    await tester.tap(find.text('Mengapa hasilnya seperti ini?'));
    await tunggu(tester, find.textContaining('KTP-R10'));
    expect(find.textContaining('penentu status'), findsNothing);
  });

  testWidgets('H5: dibuka tanpa sesi → ajakan memilih layanan', (tester) async {
    final container = buatContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const IpsGuideApp(),
      ),
    );
    await tunggu(tester, find.text('Mulai Panduan'));

    container.read(routerProvider).go('/hasil');
    await tunggu(tester, find.text('Belum ada sesi panduan yang selesai.'));
    expect(find.text('Pilih Layanan'), findsOneWidget);
  });
}
