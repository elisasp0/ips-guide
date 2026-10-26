import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ips_guide/app/app.dart';
import 'package:ips_guide/app/router.dart';
import 'package:ips_guide/data/repositories/auth_repository.dart';
import 'package:ips_guide/data/repositories/in_memory_auth_repository.dart';
import 'package:ips_guide/domain/entities/app_user.dart';

import '../support/widget_utils.dart';

/// Repository yang menghitung pemanggilan — dipakai membuktikan S24
/// (validasi klien menolak SEBELUM repository dipanggil).
class AuthTercatat extends InMemoryAuthRepository {
  int panggilanMasuk = 0;
  int panggilanDaftar = 0;

  @override
  Future<AppUser> masuk({
    required String email,
    required String password,
  }) {
    panggilanMasuk++;
    return super.masuk(email: email, password: password);
  }

  @override
  Future<AppUser> daftar({
    required String nama,
    required String email,
    required String password,
  }) {
    panggilanDaftar++;
    return super.daftar(nama: nama, email: email, password: password);
  }
}

/// Uji H1 Login & guard rute (Tahap 5; §9.1–§9.3, S23–S25).
void main() {
  setUpAll(siapkanRepository);

  final emailWarga = InMemoryAuthRepository.emailWargaDemo;
  final emailAdmin = InMemoryAuthRepository.emailAdminDemo;
  final sandi = InMemoryAuthRepository.sandiDemo;

  Future<void> bukaH1(WidgetTester tester, AuthRepository auth) async {
    await tester.pumpWidget(bungkusAplikasi(const IpsGuideApp(), auth: auth));
    await tunggu(tester, find.byKey(const Key('h1-email')));
  }

  Future<void> masukSebagai(WidgetTester tester, String email) async {
    await tester.enterText(find.byKey(const Key('h1-email')), email);
    await tester.enterText(find.byKey(const Key('h1-sandi')), sandi);
    await tester.tap(find.byKey(const Key('h1-kirim')));
    await tenang(tester);
  }

  testWidgets('Belum masuk → H1 Login tampil, bukan Beranda', (tester) async {
    await bukaH1(tester, InMemoryAuthRepository());

    expect(find.text('IPS-Guide'), findsOneWidget);
    expect(find.text('Mulai Panduan'), findsNothing);
  });

  testWidgets('S24: email tidak valid ditolak klien, repository tidak dipanggil',
      (tester) async {
    final auth = AuthTercatat();
    await bukaH1(tester, auth);

    await tester.enterText(find.byKey(const Key('h1-email')), 'bukan-email');
    await tester.enterText(find.byKey(const Key('h1-sandi')), sandi);
    await tester.tap(find.byKey(const Key('h1-kirim')));
    await tunggu(tester, find.text('Format email tidak valid.'));

    expect(auth.panggilanMasuk, 0);
    expect(find.text('Mulai Panduan'), findsNothing);
  });

  testWidgets('S23: kata sandi salah → tetap di H1 dengan pesan §9.2',
      (tester) async {
    final auth = AuthTercatat();
    await bukaH1(tester, auth);

    await tester.enterText(find.byKey(const Key('h1-email')), emailWarga);
    await tester.enterText(find.byKey(const Key('h1-sandi')), 'salah-sekali');
    await tester.tap(find.byKey(const Key('h1-kirim')));
    await tunggu(tester, find.text('Email atau kata sandi salah.'));

    // Masih di H1 — tidak diarahkan ke Beranda.
    expect(find.byKey(const Key('h1-email')), findsOneWidget);
    expect(find.text('Mulai Panduan'), findsNothing);
    expect(auth.panggilanMasuk, 1);
  });

  testWidgets('Masuk berhasil → Beranda dengan nama pengguna', (tester) async {
    await bukaH1(tester, InMemoryAuthRepository());

    await masukSebagai(tester, emailWarga);
    await tunggu(tester, find.text('Mulai Panduan'));

    expect(find.text('Selamat datang, Warga Tegalsari'), findsOneWidget);
    // Warga tidak melihat menu admin (S25).
    expect(find.text('Kelola Panduan'), findsNothing);
  });

  testWidgets('Daftar mewajibkan nama (§9.1)', (tester) async {
    final auth = AuthTercatat();
    await bukaH1(tester, auth);

    await tester.tap(find.text('Daftar'));
    await tenang(tester);
    await tunggu(tester, find.byKey(const Key('h1-nama')));

    await tester.enterText(find.byKey(const Key('h1-email')), 'baru@tegalsari.test');
    await tester.enterText(find.byKey(const Key('h1-sandi')), sandi);
    await tester.tap(find.byKey(const Key('h1-kirim')));
    await tunggu(tester, find.text('Nama wajib diisi.'));
    expect(auth.panggilanDaftar, 0);

    await tester.enterText(find.byKey(const Key('h1-nama')), 'Elisa Sandita');
    await tester.tap(find.byKey(const Key('h1-kirim')));
    await tunggu(tester, find.text('Mulai Panduan'));

    expect(find.text('Selamat datang, Elisa Sandita'), findsOneWidget);
    expect(auth.panggilanDaftar, 1);
  });

  testWidgets('S25: warga membuka /admin lewat URL → dialihkan ke Beranda',
      (tester) async {
    final container = buatContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const IpsGuideApp(),
      ),
    );
    await tunggu(tester, find.text('Mulai Panduan'));

    container.read(routerProvider).go('/admin');
    await tunggu(tester, find.text('Mulai Panduan'));

    expect(find.text('Dibangun pada Tahap 7.'), findsNothing);
    expect(find.text('Kelola Panduan'), findsNothing);
  });

  testWidgets('Admin melihat menu Kelola Panduan dan dapat membukanya',
      (tester) async {
    final auth = InMemoryAuthRepository();
    await auth.masuk(email: emailAdmin, password: sandi);

    final container = buatContainer(auth: auth);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const IpsGuideApp(),
      ),
    );
    await tunggu(tester, find.byKey(const Key('h2-kelola-panduan')));

    // Kartu admin berada di bawah lipatan layar uji 800x600.
    await tester.ensureVisible(find.byKey(const Key('h2-kelola-panduan')));
    await tenang(tester);
    await tester.tap(find.byKey(const Key('h2-kelola-panduan')));
    await tunggu(tester, find.text('Dibangun pada Tahap 7.'));
  });

  testWidgets('Keluar dari Beranda kembali ke H1', (tester) async {
    await tester.pumpWidget(bungkusAplikasi(const IpsGuideApp()));
    await tunggu(tester, find.text('Mulai Panduan'));

    await tester.tap(find.byKey(const Key('h2-keluar')));
    await tunggu(tester, find.byKey(const Key('h1-email')));

    expect(find.text('Mulai Panduan'), findsNothing);
  });

  testWidgets('K5: akun tanpa profil → pesan U-07 + tombol Keluar, bukan Beranda',
      (tester) async {
    final auth = InMemoryAuthRepository(emailTanpaProfil: {emailWarga});
    await bukaH1(tester, auth);

    await masukSebagai(tester, emailWarga);
    await tunggu(tester, find.text('Profil akun tidak ditemukan'));

    expect(find.byKey(const Key('h1-keluar')), findsOneWidget);
    expect(find.text('Mulai Panduan'), findsNothing);

    await tester.tap(find.byKey(const Key('h1-keluar')));
    await tunggu(tester, find.byKey(const Key('h1-email')));
  });
}
