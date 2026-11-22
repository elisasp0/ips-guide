
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../domain/entities/app_user.dart';

/// Keadaan sesi autentikasi untuk UI dan guard rute (§9.1).
///
/// memuat       : status autentikasi sedang diperiksa.
/// keluar       : pengguna belum login.
/// masuk        : pengguna berhasil login dan memiliki profil.
/// profilHilang : akun Firebase ada tetapi profil Firestore tidak ditemukan.
enum AuthStatus {
  memuat,
  keluar,
  masuk,
  profilHilang,
}

class AuthState {
  final AuthStatus status;
  final AppUser? user;

  /// Email akun yang terautentikasi tetapi profilnya tidak ditemukan.
  final String? emailTanpaProfil;

  /// Pesan galat formulir H1.
  final String? pesanGalat;

  /// Permintaan sedang diproses.
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
      emailTanpaProfil:
          emailTanpaProfil ?? this.emailTanpaProfil,
      pesanGalat:
          hapusPesanGalat ? null : (pesanGalat ?? this.pesanGalat),
      sedangProses: sedangProses ?? this.sedangProses,
    );
  }
}

/// Pengendali sesi autentikasi.
///
/// Sumber utama status sesi berasal dari authStateChanges
/// milik AuthRepository.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    debugPrint('========== AUTH CONTROLLER BUILD ==========');

    final repo = ref.watch(authRepositoryProvider);

    final langganan = repo.authStateChanges.listen(
      _terapkan,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('========== AUTH STREAM ERROR ==========');
        debugPrint('ERROR: $error');
        debugPrint('STACK: $stackTrace');
      },
      onDone: () {
        debugPrint('AUTH STREAM SELESAI');
      },
    );

    ref.onDispose(() {
      debugPrint('AUTH CONTROLLER DISPOSE');
      langganan.cancel();
    });

    return const AuthState.memuat();
  }

  /// Mengubah AuthSnapshot menjadi AuthState.
  void _terapkan(AuthSnapshot snapshot) {
    debugPrint('========== AUTH SNAPSHOT ==========');
    debugPrint('USER: ${snapshot.user?.nama}');
    debugPrint('EMAIL: ${snapshot.email}');

    final user = snapshot.user;

    if (user != null) {
      debugPrint('STATUS BERUBAH: MASUK');
      debugPrint('NAMA: ${user.nama}');
      debugPrint('ROLE ADMIN: ${user.isAdmin}');

      state = AuthState(
        AuthStatus.masuk,
        user: user,
      );

      debugPrint('AUTH STATE SEKARANG: ${state.status}');
      return;
    }

    final email = snapshot.email;

    if (email != null) {
      debugPrint('STATUS BERUBAH: PROFIL HILANG');

      state = AuthState(
        AuthStatus.profilHilang,
        emailTanpaProfil: email,
      );

      debugPrint('AUTH STATE SEKARANG: ${state.status}');
      return;
    }

    debugPrint('STATUS BERUBAH: KELUAR');

    state = const AuthState(AuthStatus.keluar);

    debugPrint('AUTH STATE SEKARANG: ${state.status}');
  }

  /// Login menggunakan email dan kata sandi.
  ///
  /// Mengembalikan true apabila repository berhasil memproses login.
  Future<bool> masuk({
    required String email,
    required String password,
  }) async {
    if (state.sedangProses) {
      debugPrint('LOGIN DITOLAK: MASIH ADA PROSES LOGIN');
      return false;
    }

    debugPrint('========== AUTH CONTROLLER LOGIN ==========');

    state = state.copyWith(
      sedangProses: true,
      hapusPesanGalat: true,
    );

    try {
      await ref.read(authRepositoryProvider).masuk(
            email: email,
            password: password,
          );

      debugPrint('LOGIN REPOSITORY BERHASIL');
      debugPrint('STATUS SEBELUM SELESAI: ${state.status}');

      state = state.copyWith(
        sedangProses: false,
        hapusPesanGalat: true,
      );

      debugPrint('LOGIN SELESAI');
      debugPrint('STATUS AKHIR: ${state.status}');

      return true;
    } on AuthException catch (e) {
      debugPrint('========== LOGIN AUTH EXCEPTION ==========');
      debugPrint('KODE: ${e.kode.kode}');
      debugPrint('PESAN: ${e.pesan}');

      state = AuthState(
        e.kode == AuthErrorCode.profilTidakDitemukan
            ? AuthStatus.profilHilang
            : AuthStatus.keluar,
        emailTanpaProfil:
            e.kode == AuthErrorCode.profilTidakDitemukan
                ? email
                : null,
        pesanGalat: e.pesan,
      );

      return false;
    } catch (e, stackTrace) {
      debugPrint('========== LOGIN UNKNOWN ERROR ==========');
      debugPrint('ERROR: $e');
      debugPrint('STACK: $stackTrace');

      state = const AuthState(
        AuthStatus.keluar,
        pesanGalat: 'Terjadi kesalahan. Coba lagi.',
      );

      return false;
    }
  }

  /// Registrasi akun warga baru.
  Future<bool> daftar({
    required String nama,
    required String email,
    required String password,
  }) async {
    if (state.sedangProses) return false;

    debugPrint('========== AUTH CONTROLLER REGISTER ==========');

    state = state.copyWith(
      sedangProses: true,
      hapusPesanGalat: true,
    );

    try {
      await ref.read(authRepositoryProvider).daftar(
            nama: nama,
            email: email,
            password: password,
          );

      debugPrint('REGISTER REPOSITORY BERHASIL');

      state = state.copyWith(
        sedangProses: false,
        hapusPesanGalat: true,
      );

      return true;
    } on AuthException catch (e) {
      debugPrint('REGISTER AUTH ERROR: ${e.pesan}');

      state = AuthState(
        AuthStatus.keluar,
        pesanGalat: e.pesan,
      );

      return false;
    } catch (e, stackTrace) {
      debugPrint('REGISTER UNKNOWN ERROR: $e');
      debugPrint('STACK: $stackTrace');

      state = const AuthState(
        AuthStatus.keluar,
        pesanGalat: 'Terjadi kesalahan. Coba lagi.',
      );

      return false;
    }
  }

  /// Logout dari aplikasi.
  Future<void> keluar() async {
    debugPrint('========== AUTH CONTROLLER LOGOUT ==========');

    try {
      await ref.read(authRepositoryProvider).keluar();

      state = const AuthState(AuthStatus.keluar);

      debugPrint('LOGOUT CONTROLLER BERHASIL');
      debugPrint('STATUS AKHIR: ${state.status}');
    } catch (e, stackTrace) {
      debugPrint('LOGOUT ERROR: $e');
      debugPrint('STACK: $stackTrace');

      rethrow;
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
