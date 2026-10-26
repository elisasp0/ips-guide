import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ips_guide/app/app.dart';

import '../support/widget_utils.dart';

/// Uji responsif (§6, §13, §15 Tahap 8): 360 / 768 / 1280 px.
///
/// Overflow `RenderFlex` otomatis menggagalkan uji widget, sehingga uji ini
/// sekaligus membuktikan tidak ada overflow pada lebar sempit.
void main() {
  setUpAll(siapkanRepository);

  Future<void> aturLayar(WidgetTester tester, Size ukuran) async {
    tester.view.physicalSize = ukuran;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('360 px: NavigationBar, alur sampai H4 tanpa overflow',
      (tester) async {
    await aturLayar(tester, const Size(360, 800));
    await tester.pumpWidget(bungkusAplikasi(const IpsGuideApp()));
    await tunggu(tester, find.text('Mulai Panduan'));

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    await tester.tap(find.text('Mulai Panduan'));
    await tunggu(tester, find.text('Pilih Layanan'));
    await tester.tap(find.text('Kartu Keluarga'));
    await tunggu(tester, find.text('Bagaimana kondisi Kartu Keluarga Anda?'));
  });

  testWidgets('768 px: NavigationRail menggantikan NavigationBar',
      (tester) async {
    await aturLayar(tester, const Size(768, 1024));
    await tester.pumpWidget(bungkusAplikasi(const IpsGuideApp()));
    await tunggu(tester, find.text('Mulai Panduan'));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    // Navigasi lewat rail tetap berfungsi.
    await tester.tap(find.text('Layanan'));
    await tunggu(tester, find.text('Pilih Layanan'));
    expect(find.text('Kartu Tanda Penduduk Elektronik'), findsOneWidget);
  });

  testWidgets('1280 px: lebar isi dibatasi, tetap tanpa overflow',
      (tester) async {
    await aturLayar(tester, const Size(1280, 900));
    await tester.pumpWidget(bungkusAplikasi(const IpsGuideApp()));
    await tunggu(tester, find.text('Mulai Panduan'));

    expect(find.byType(NavigationRail), findsOneWidget);

    // Kartu layanan tidak melebar melewati batas baca (720 px).
    final lebarKartu = tester.getSize(find.byType(Card).first).width;
    expect(lebarKartu, lessThanOrEqualTo(720));

    await tester.tap(find.text('Mulai Panduan'));
    await tunggu(tester, find.text('Pilih Layanan'));
    await tester.tap(find.text('Surat Keterangan Domisili'));
    await tunggu(tester, find.text('Untuk keperluan apa surat domisili ini?'));
  });
}
