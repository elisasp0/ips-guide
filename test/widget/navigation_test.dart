import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ips_guide/app/app.dart';
import 'package:ips_guide/app/router.dart';

import '../support/widget_utils.dart';

/// Uji navigasi Tahap 3 (§15 bukti: navigasi berjalan, URL berubah,
/// halaman 404, kartu nonaktif tidak dapat dipilih).
void main() {
  setUpAll(siapkanRepository);

  Future<void> bukaAplikasi(WidgetTester tester) async {
    await tester.pumpWidget(bungkusAplikasi(const IpsGuideApp()));
    await tunggu(tester, find.text('Mulai Panduan'));
  }

  testWidgets('Beranda → Layanan lewat tombol Mulai Panduan menampilkan 3 layanan',
      (tester) async {
    await bukaAplikasi(tester);

    await tester.tap(find.text('Mulai Panduan'));
    // 'Pilih Layanan' hanya ada di H3 (judul AppBar).
    await tunggu(tester, find.text('Pilih Layanan'));

    expect(find.text('Kartu Tanda Penduduk Elektronik'), findsOneWidget);
    expect(find.text('Kartu Keluarga'), findsOneWidget);
    expect(find.text('Surat Keterangan Domisili'), findsOneWidget);
  });

  testWidgets('Bottom navigation berpindah antar tab dan kembali',
      (tester) async {
    await bukaAplikasi(tester);

    await tester.tap(find.text('Panduan').last);
    await tunggu(tester, find.text('Belum ada panduan yang sedang berjalan'));

    await tester.tap(find.text('Beranda').last);
    await tunggu(tester, find.text('Selamat datang'));
  });

  testWidgets('Kartu layanan di Beranda menuju H4 Pertanyaan Panduan',
      (tester) async {
    await bukaAplikasi(tester);

    await tester.tap(find.text('Kartu Keluarga'));
    // H4 menampilkan pertanyaan pertama KK.
    await tunggu(tester, find.text('Bagaimana kondisi Kartu Keluarga Anda?'));
  });

  testWidgets('Rute tidak dikenal menampilkan halaman 404', (tester) async {
    final container = buatContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const IpsGuideApp(),
      ),
    );
    // Navigasi paksa ke rute asing lewat router.
    container.read(routerProvider).go('/rute-aneh');
    await tunggu(tester, find.text('Halaman tidak ditemukan'));
  });
}
