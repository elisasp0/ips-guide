import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ips_guide/app/app.dart';

import '../support/widget_utils.dart';

/// Uji H7 Sampaikan Kebutuhan — form warga (Modul Minggu 7).
///
/// Sembilan kasus: struktur form & keadaan kosong, kirim kosong, nama terlalu
/// pendek, nama mengandung angka, nama terlalu panjang, pesan terlalu pendek,
/// pesan kosong saat kolom lain valid, layanan belum dipilih, dan satu kasus
/// semua valid (data tampil di daftar).
void main() {
  setUpAll(siapkanRepository);

  Future<void> bukaForm(WidgetTester tester) async {
    await tester.pumpWidget(bungkusAplikasi(const IpsGuideApp()));
    await tunggu(tester, find.text('Mulai Panduan'));

    // Kartu pintu masuk berada setelah tiga kartu layanan, jadi pada layar uji
    // 800x600 ia berada di bawah lipatan: gulir dulu agar tap benar-benar
    // mengenai sasaran.
    final pintu = find.byKey(const Key('h2-sampaikan-kebutuhan'));
    await tester.ensureVisible(pintu);
    await tenang(tester, frames: 2);
    await tester.tap(pintu);
    await tunggu(tester, find.byKey(const Key('h7-nama')));
  }

  Future<void> isiNama(WidgetTester tester, String nilai) async {
    await tester.enterText(find.byKey(const Key('h7-nama')), nilai);
    await tenang(tester, frames: 2);
  }

  Future<void> isiPesan(WidgetTester tester, String nilai) async {
    await tester.enterText(find.byKey(const Key('h7-pesan')), nilai);
    await tenang(tester, frames: 2);
  }

  Future<void> pilihLayanan(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.byKey(const Key('h7-layanan')));
    await tester.tap(find.byKey(const Key('h7-layanan')));
    await tenang(tester);
    await tester.tap(find.text(label).last);
    await tenang(tester);
  }

  Future<void> tekanKirim(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('h7-kirim')));
    await tester.tap(find.byKey(const Key('h7-kirim')));
    await tenang(tester);
  }

  testWidgets('H7 punya tiga kolom (dua jenis input) dan daftar masih kosong',
      (tester) async {
    await bukaForm(tester);

    expect(find.byKey(const Key('h7-nama')), findsOneWidget);
    expect(find.byKey(const Key('h7-layanan')), findsOneWidget);
    expect(find.byKey(const Key('h7-pesan')), findsOneWidget);
    expect(find.byKey(const Key('h7-kirim')), findsOneWidget);
    expect(find.text('Belum ada kebutuhan yang dikirim.'), findsOneWidget);
  });

  testWidgets('Kirim tanpa isi → tiga pesan galat + SnackBar gagal',
      (tester) async {
    await bukaForm(tester);
    await tekanKirim(tester);

    expect(find.text('Nama pemohon wajib diisi.'), findsOneWidget);
    expect(find.text('Pilih jenis layanan.'), findsOneWidget);
    expect(find.text('Pesan atau kebutuhan wajib diisi.'), findsOneWidget);
    expect(find.text('Periksa kembali isian yang ditandai merah.'),
        findsOneWidget);
    // Tidak ada data yang tersimpan.
    expect(find.text('Belum ada kebutuhan yang dikirim.'), findsOneWidget);
  });

  testWidgets('Nama kurang dari tiga karakter ditolak', (tester) async {
    await bukaForm(tester);
    await isiNama(tester, 'Bu');
    await tekanKirim(tester);

    expect(find.text('Nama minimal 3 karakter.'), findsOneWidget);
    expect(find.text('Belum ada kebutuhan yang dikirim.'), findsOneWidget);
  });

  testWidgets('Nama yang mengandung angka ditolak', (tester) async {
    await bukaForm(tester);
    await isiNama(tester, 'Budi 123');
    await tekanKirim(tester);

    expect(find.text('Nama tidak boleh mengandung angka.'), findsOneWidget);
    expect(find.text('Belum ada kebutuhan yang dikirim.'), findsOneWidget);
  });

  testWidgets('Nama lebih dari enam puluh karakter ditolak', (tester) async {
    await bukaForm(tester);

    // 61 huruf tanpa angka: memastikan yang menolak adalah batas panjang,
    // bukan aturan "tidak boleh mengandung angka".
    final namaPanjang = List.filled(61, 'a').join();
    expect(namaPanjang.length, 61);

    await isiNama(tester, namaPanjang);
    await tekanKirim(tester);

    expect(find.text('Nama maksimal 60 karakter.'), findsOneWidget);
    expect(find.text('Belum ada kebutuhan yang dikirim.'), findsOneWidget);
  });

  testWidgets('Pesan kosong ditolak meski nama dan layanan valid',
      (tester) async {
    await bukaForm(tester);
    await isiNama(tester, 'Budi Santoso');
    await pilihLayanan(tester, 'Kartu Keluarga');
    // Kolom pesan sengaja dibiarkan kosong.
    await tekanKirim(tester);

    expect(find.text('Pesan atau kebutuhan wajib diisi.'), findsOneWidget);
    // Kolom lain tidak ikut dinyatakan salah.
    expect(find.text('Nama pemohon wajib diisi.'), findsNothing);
    expect(find.text('Pilih jenis layanan.'), findsNothing);
    expect(find.text('Belum ada kebutuhan yang dikirim.'), findsOneWidget);
  });

  testWidgets('Pesan kurang dari sepuluh karakter ditolak', (tester) async {
    await bukaForm(tester);
    await isiNama(tester, 'Budi Santoso');
    await isiPesan(tester, 'Tolong');
    await tekanKirim(tester);

    expect(find.text('Pesan minimal 10 karakter.'), findsOneWidget);
    expect(find.text('Belum ada kebutuhan yang dikirim.'), findsOneWidget);
  });

  testWidgets('Layanan belum dipilih ditolak meski kolom lain valid',
      (tester) async {
    await bukaForm(tester);
    await isiNama(tester, 'Budi Santoso');
    await isiPesan(tester, 'Perlu menambah anggota keluarga baru.');
    await tekanKirim(tester);

    expect(find.text('Pilih jenis layanan.'), findsOneWidget);
    expect(find.text('Belum ada kebutuhan yang dikirim.'), findsOneWidget);
  });

  testWidgets('Data valid tersimpan, SnackBar sukses tampil, dan muncul di daftar',
      (tester) async {
    await bukaForm(tester);

    await isiNama(tester, 'Budi Santoso');
    await pilihLayanan(tester, 'Kartu Keluarga');
    await isiPesan(tester, 'Perlu menambah anggota keluarga baru.');
    await tekanKirim(tester);

    // Pesan status berhasil (Modul Minggu 7 §4).
    await tunggu(
      tester,
      find.text('Kebutuhan terkirim. Petugas akan menindaklanjuti.'),
    );

    // Data valid tampil pada daftar (Modul Minggu 7 §5).
    await tunggu(tester, find.text('Budi Santoso'));
    expect(find.text('Perlu menambah anggota keluarga baru.'), findsOneWidget);
    expect(find.text('Belum ada kebutuhan yang dikirim.'), findsNothing);

    // Formulir dikosongkan setelah berhasil: nama hanya tersisa di daftar.
    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('Nama pemohon wajib diisi.'), findsNothing);
  });
}
