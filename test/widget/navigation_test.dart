import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ips_guide/app/app.dart';
import 'package:ips_guide/app/router.dart';

/// Uji navigasi Tahap 3 (§15 bukti: navigasi berjalan, URL berubah,
/// halaman 404, kartu nonaktif tidak dapat dipilih).
void main() {
  Future<void> bukaAplikasi(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: IpsGuideApp()));
    await tester.pumpAndSettle();
  }

  testWidgets('Beranda → Layanan lewat tombol Mulai Panduan menampilkan 3 layanan',
      (tester) async {
    await bukaAplikasi(tester);

    await tester.tap(find.text('Mulai Panduan'));
    await tester.pumpAndSettle();

    expect(find.text('Pilih Layanan'), findsOneWidget);
    expect(find.text('Kartu Tanda Penduduk Elektronik'), findsOneWidget);
    expect(find.text('Kartu Keluarga'), findsOneWidget);
    expect(find.text('Surat Keterangan Domisili'), findsOneWidget);
  });

  testWidgets('Bottom navigation berpindah antar tab dan kembali',
      (tester) async {
    await bukaAplikasi(tester);

    await tester.tap(find.text('Panduan').last);
    await tester.pumpAndSettle();
    expect(
      find.text('Belum ada panduan yang sedang berjalan'),
      findsOneWidget,
    );

    await tester.tap(find.text('Beranda').last);
    await tester.pumpAndSettle();
    expect(find.text('Selamat datang'), findsOneWidget);
  });

    testWidgets('Kartu layanan di Beranda menuju H4 (placeholder Tahap 4)',
        (tester) async {
      await bukaAplikasi(tester);

      await tester.tap(find.text('Kartu Keluarga'));
      await tester.pumpAndSettle();

      expect(find.text('Pertanyaan Panduan'), findsOneWidget);
      expect(find.textContaining('(layanan: kk)'), findsOneWidget);
    });

  testWidgets('Rute tidak dikenal menampilkan halaman 404', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const IpsGuideApp(),
      ),
    );
    // Navigasi paksa ke rute asing lewat router.
    container.read(routerProvider).go('/rute-aneh');
    await tester.pumpAndSettle();

    expect(find.text('Halaman tidak ditemukan'), findsOneWidget);
  });
}
