import '../../domain/entities/app_user.dart';

/// Kode galat autentikasi + pesan Indonesia (§9.2).
///
/// Pesan sengaja TIDAK membedakan "email tidak terdaftar" dan "kata sandi
/// salah" agar keberadaan akun tidak bocor.
enum AuthErrorCode {
  emailTidakValid('invalid-email', 'Format email tidak valid.'),
  kredensialSalah('kredensial-salah', 'Email atau kata sandi salah.'),
  emailSudahTerdaftar('email-already-in-use', 'Email ini sudah terdaftar.'),
  kataSandiLemah('weak-password', 'Kata sandi minimal 6 karakter.'),
  terlaluBanyakPercobaan(
    'too-many-requests',
    'Terlalu banyak percobaan. Coba lagi nanti.',
  ),
  tanpaKoneksi('network-request-failed', 'Tidak ada koneksi internet.'),
  profilTidakDitemukan(
    'profil-tidak-ditemukan',
    'Akun Anda terdaftar, tetapi profilnya belum lengkap. '
        'Hubungi admin atau daftar ulang dengan email lain.',
  ),
  galatTakDikenal('unknown', 'Terjadi kesalahan. Coba lagi.');

  const AuthErrorCode(this.kode, this.pesan);

  /// Kode kanonik (sama dengan kode Firebase untuk yang bersesuaian).
  final String kode;

  /// Pesan siap tampil di H1.
  final String pesan;

  static AuthErrorCode dariKode(String kode) {
    for (final e in values) {
      if (e.kode == kode) return e;
    }
    return galatTakDikenal;
  }
}

/// Galat lapisan autentikasi — satu tipe untuk semua implementasi
/// (in-memory Tahap 5a, Firebase Auth Tahap 5b).
class AuthException implements Exception {
  final AuthErrorCode kode;
  final String? detail;

  const AuthException(this.kode, {this.detail});

  String get pesan => kode.pesan;

  @override
  String toString() =>
      'AuthException(${kode.kode}${detail == null ? '' : ': $detail'})';
}

/// Cuplikan keadaan autentikasi.
///
/// Membedakan tiga keadaan yang secara UI berbeda (§9.1, U-07):
/// - [AuthSnapshot.keluar]     → belum masuk / sudah keluar;
/// - [AuthSnapshot.masuk]      → akun Auth ada DAN dokumen `users/{uid}` ada;
/// - [AuthSnapshot.tanpaProfil]→ akun Auth ada tetapi profil hilang.
///
/// Keadaan ketiga tidak boleh disamakan dengan "belum masuk", karena
/// pengguna tidak dapat diarahkan ke Beranda (semua pembacaan akan ditolak).
class AuthSnapshot {
  final AppUser? user;

  /// Email akun yang terautentikasi tetapi profilnya tidak ditemukan.
  final String? email;

  const AuthSnapshot._({this.user, this.email});

  const AuthSnapshot.keluar() : this._();

  const AuthSnapshot.masuk(AppUser this.user) : email = null;

  const AuthSnapshot.tanpaProfil(String this.email) : user = null;

  bool get terautentikasi => user != null || email != null;
}

/// Kontrak lapisan autentikasi (§3.3 — UI tidak tahu implementasinya).
///
/// Implementasi: [InMemoryAuthRepository] (Tahap 5a, tanpa Firebase) dan
/// `FirebaseAuthRepository` (Tahap 5b). UI, guard rute, dan uji tidak berubah
/// saat implementasi diganti.
abstract class AuthRepository {
  /// Keadaan akun saat ini, dipancarkan setiap perubahan.
  ///
  /// Pelanggan baru menerima keadaan terkini segera setelah mendengarkan.
  Stream<AuthSnapshot> get authStateChanges;

  /// Masuk dengan email + kata sandi.
  ///
  /// Melempar [AuthException]; [AuthErrorCode.profilTidakDitemukan] bila
  /// akun terautentikasi tetapi profil `users/{uid}` tidak ada (U-07).
  Future<AppUser> masuk({required String email, required String password});

  /// Mendaftar akun baru; nama WAJIB (§9.1 — aturan `create` menuntutnya).
  Future<AppUser> daftar({
    required String nama,
    required String email,
    required String password,
  });

  Future<void> keluar();

  /// Petunjuk akun percobaan untuk mode pengembangan.
  ///
  /// `null` pada implementasi Firebase — tidak ada akun bawaan di produksi.
  String? get petunjukDemo;
}
