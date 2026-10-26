import 'dart:async';

import '../../domain/entities/app_user.dart';
import 'auth_repository.dart';

/// Implementasi autentikasi in-memory (Tahap 5a) — dipakai sampai proyek
/// Firebase siap.
///
/// Tujuannya bukan meniru Firebase, melainkan **membekukan kontrak**
/// ([AuthRepository]) supaya H1, guard rute, dan uji dapat diselesaikan dan
/// diuji lebih dulu. Saat `FirebaseAuthRepository` dipasang, tidak ada satu
/// pun baris UI yang berubah.
///
/// Akun percobaan:
/// - `warga@tegalsari.test` / `123456` (peran warga)
/// - `admin@tegalsari.test` / `123456` (peran admin)
class InMemoryAuthRepository implements AuthRepository {
  static const emailWargaDemo = 'warga@tegalsari.test';
  static const emailAdminDemo = 'admin@tegalsari.test';
  static const sandiDemo = '123456';

  final Map<String, _Akun> _akun = {};
  final Set<String> _emailTanpaProfil;

  /// Siaran (broadcast) agar beberapa `ProviderContainer` — mis. antar uji —
  /// dapat mendengarkan instance yang sama.
  final StreamController<AuthSnapshot> _kendali =
      StreamController<AuthSnapshot>.broadcast();

  AuthSnapshot _snapshot = const AuthSnapshot.keluar();

  /// [emailTanpaProfil] meniru keadaan U-07: akun Auth ada, dokumen
  /// `users/{uid}` tidak ada.
  InMemoryAuthRepository({Set<String> emailTanpaProfil = const {}})
      : _emailTanpaProfil = {...emailTanpaProfil} {
    _akun[emailWargaDemo] = _Akun(
      uid: 'u-warga',
      email: emailWargaDemo,
      nama: 'Warga Tegalsari',
      role: UserRole.warga,
      sandi: sandiDemo,
    );
    _akun[emailAdminDemo] = _Akun(
      uid: 'u-admin',
      email: emailAdminDemo,
      nama: 'Admin Kelurahan',
      role: UserRole.admin,
      sandi: sandiDemo,
    );
    // Pelanggan baru langsung menerima keadaan terkini.
    _kendali.onListen = () {
      if (!_kendali.isClosed) _kendali.add(_snapshot);
    };
  }

  @override
  Stream<AuthSnapshot> get authStateChanges => _kendali.stream;

  @override
  String? get petunjukDemo =>
      'Mode pengembangan (tanpa Firebase) — akun percobaan:\n'
      '$emailWargaDemo / $sandiDemo (warga) · '
      '$emailAdminDemo / $sandiDemo (admin)';

  @override
  Future<AppUser> masuk({
    required String email,
    required String password,
  }) async {
    final surel = _normalisasi(email);
    final akun = _akun[surel];
    if (akun == null || akun.sandi != password) {
      throw const AuthException(AuthErrorCode.kredensialSalah);
    }
    if (_emailTanpaProfil.contains(surel)) {
      _pancarkan(AuthSnapshot.tanpaProfil(surel));
      throw const AuthException(AuthErrorCode.profilTidakDitemukan);
    }
    final user = akun.toUser();
    _pancarkan(AuthSnapshot.masuk(user));
    return user;
  }

  @override
  Future<AppUser> daftar({
    required String nama,
    required String email,
    required String password,
  }) async {
    final surel = _normalisasi(email);
    if (_akun.containsKey(surel)) {
      throw const AuthException(AuthErrorCode.emailSudahTerdaftar);
    }
    if (password.length < 6) {
      throw const AuthException(AuthErrorCode.kataSandiLemah);
    }
    if (nama.trim().isEmpty) {
      // Aturan `create` Firestore menuntut field `nama` (§9.1).
      throw const AuthException(
        AuthErrorCode.galatTakDikenal,
        detail: 'nama kosong',
      );
    }
    final akun = _Akun(
      uid: 'u-${_akun.length + 1}',
      email: surel,
      nama: nama.trim(),
      role: UserRole.warga,
      sandi: password,
    );
    _akun[surel] = akun;
    final user = akun.toUser();
    _pancarkan(AuthSnapshot.masuk(user));
    return user;
  }

  @override
  Future<void> keluar() async => _pancarkan(const AuthSnapshot.keluar());

  void _pancarkan(AuthSnapshot snapshot) {
    _snapshot = snapshot;
    if (!_kendali.isClosed) _kendali.add(snapshot);
  }

  static String _normalisasi(String email) => email.trim().toLowerCase();
}

class _Akun {
  final String uid;
  final String email;
  final String nama;
  final UserRole role;
  final String sandi;

  const _Akun({
    required this.uid,
    required this.email,
    required this.nama,
    required this.role,
    required this.sandi,
  });

  AppUser toUser() => AppUser(uid: uid, email: email, nama: nama, role: role);
}
