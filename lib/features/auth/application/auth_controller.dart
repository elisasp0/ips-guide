import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../domain/entities/app_user.dart';

/// Keadaan sesi autentikasi untuk UI & guard rute (§9.1).
///
/// `memuat` hanya berlangsung sampai cuplikan pertama tiba; `profilHilang`
/// adalah keadaan tersendiri (U-07) — pengguna TIDAK diarahkan ke Beranda.
enum AuthStatus { memuat, keluar, masuk, profilHilang }

class AuthState {
  final AuthStatus status;
  final AppUser? user;

  /// Email akun yang terautentikasi tetapi profilnya tidak ditemukan.
  final String? emailTanpaProfil;

  /// Pesan galat formulir H1 (§9.2).
  final String? pesanGalat;

  /// Permintaan sedang diproses (tombol dinonaktifkan).
  final bool sedangProses;

  const AuthState(
    this.status, {
    this.user,
    this.emailTanpaProfil,
    this.pesanGalat,
    this.sedangProses = false,
  });

  const AuthState.memuat() : this(AuthStatus.memuat);

  bool get sudahMasuk => status == AuthStatus.masuk;

  bool get isAdmin => user?.isAdmin ?? false;

  AuthState copyWith({
    AuthStatus? status,
    AppUser? user,
    String? emailTanpaProfil,
    String? pesanGalat,
    bool? sedangProses,
    bool hapusPesanGalat = false,
  }) {
    return AuthState(
      status ?? this.status,
      user: user ?? this.user,
      emailTanpaProfil: emailTanpaProfil ?? this.emailTanpaProfil,
      pesanGalat: hapusPesanGalat ? null : (pesanGalat ?? this.pesanGalat),
      sedangProses: sedangProses ?? this.sedangProses,
    );
  }
}

/// Pengendali sesi: meneruskan aksi ke [AuthRepository] dan mengubah
/// [AuthSnapshot] menjadi [AuthState] yang dipakai UI.
///
/// Satu sumber kebenaran: status sesi berasal dari aliran repository, bukan
/// dari hasil pemanggilan aksi. Galat aksi hanya mengisi [AuthState.pesanGalat].
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    final repo = ref.watch(authRepositoryProvider);
    final langganan = repo.authStateChanges.listen(_terapkan);
    ref.onDispose(langganan.cancel);
    return const AuthState.memuat();
  }

  void _terapkan(AuthSnapshot snapshot) {
    final user = snapshot.user;
    if (user != null) {
      state = AuthState(AuthStatus.masuk, user: user);
      return;
    }
    final email = snapshot.email;
    if (email != null) {
      state = AuthState(AuthStatus.profilHilang, emailTanpaProfil: email);
      return;
    }
    state = const AuthState(AuthStatus.keluar);
  }

  /// Masuk; mengembalikan `true` bila berhasil.
  ///
  /// Validasi format email/kata sandi dilakukan di H1 SEBELUM memanggil
  /// metode ini (S24) — repository tidak boleh menerima masukan tidak valid.
  Future<bool> masuk({required String email, required String password}) async {
    if (state.sedangProses) return false;
    state = state.copyWith(sedangProses: true, hapusPesanGalat: true);
    try {
      await ref.read(authRepositoryProvider).masuk(
            email: email,
            password: password,
          );
      // Status sesi datang dari aliran repository.
      state = state.copyWith(sedangProses: false, hapusPesanGalat: true);
      return true;
    } on AuthException catch (e) {
      state = AuthState(
        e.kode == AuthErrorCode.profilTidakDitemukan
            ? AuthStatus.profilHilang
            : AuthStatus.keluar,
        emailTanpaProfil:
            e.kode == AuthErrorCode.profilTidakDitemukan ? email : null,
        pesanGalat: e.pesan,
      );
      return false;
    } catch (_) {
      state = const AuthState(
        AuthStatus.keluar,
        pesanGalat: 'Terjadi kesalahan. Coba lagi.',
      );
      return false;
    }
  }

  /// Daftar akun baru (mode "Daftar" di dalam H1, §9.3).
  Future<bool> daftar({
    required String nama,
    required String email,
    required String password,
  }) async {
    if (state.sedangProses) return false;
    state = state.copyWith(sedangProses: true, hapusPesanGalat: true);
    try {
      await ref.read(authRepositoryProvider).daftar(
            nama: nama,
            email: email,
            password: password,
          );
      state = state.copyWith(sedangProses: false, hapusPesanGalat: true);
      return true;
    } on AuthException catch (e) {
      state = AuthState(AuthStatus.keluar, pesanGalat: e.pesan);
      return false;
    } catch (_) {
      state = const AuthState(
        AuthStatus.keluar,
        pesanGalat: 'Terjadi kesalahan. Coba lagi.',
      );
      return false;
    }
  }

  Future<void> keluar() async {
    await ref.read(authRepositoryProvider).keluar();
    state = const AuthState(AuthStatus.keluar);
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);
