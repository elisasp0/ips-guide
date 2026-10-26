/// Layanan administrasi yang dipandu (§7).
class GuidanceService {
  final String id; // `ktp` | `kk` | `domisili`
  final String nama;
  final String deskripsi;
  final String ikon;
  final int urutan;
  final int estimasiHariMin;
  final int estimasiHariMax;

  /// false → kartu tampil "belum tersedia", tidak bisa dipilih (§7).
  final bool aktif;

  /// ID tahapan umum untuk SEMUA pengajuan layanan ini — satu-satunya sumber
  /// tahapan umum (§11.5, U-01).
  final List<String> stepsDasar;

  const GuidanceService({
    required this.id,
    required this.nama,
    required this.deskripsi,
    required this.ikon,
    required this.urutan,
    required this.estimasiHariMin,
    required this.estimasiHariMax,
    this.aktif = true,
    this.stepsDasar = const [],
  });
}
