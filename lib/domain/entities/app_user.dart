/// Peran pengguna (§7, §8.1 koleksi `users`).
enum UserRole { warga, admin }

/// Akun pengguna (§7).
///
/// Hanya email, nama, dan peran — TIDAK ada data kependudukan warga (§1.4).
class AppUser {
  final String uid;
  final String email;
  final String nama;
  final UserRole role;

  const AppUser({
    required this.uid,
    required this.email,
    required this.nama,
    required this.role,
  });

  bool get isAdmin => role == UserRole.admin;
}
