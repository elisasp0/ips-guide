import '../../domain/entities/kebutuhan_warga.dart';

/// Antarmuka penyimpanan kebutuhan warga (H7, Modul Minggu 7).
///
/// Tahap ini hanya punya satu implementasi: [InMemoryKebutuhanRepository].
/// Saat Firestore dipasang nanti, kontrak ini tidak berubah — sama seperti
/// pola `KnowledgeBaseRepository` (§3.3).
abstract class KebutuhanRepository {
  /// Semua kebutuhan yang sudah dikirim, **terbaru lebih dulu**.
  Future<List<KebutuhanWarga>> daftar();

  /// Simpan satu kebutuhan.
  ///
  /// Melempar [KebutuhanException] bila data wajib kosong — pertahanan lapis
  /// kedua: form sudah memvalidasi, tetapi repository tidak boleh menerima
  /// data yang tidak masuk akal.
  Future<KebutuhanWarga> kirim({
    required String namaPemohon,
    required String serviceId,
    required String serviceNama,
    required String pesan,
  });
}

/// Galat penyimpanan kebutuhan warga.
class KebutuhanException implements Exception {
  final String pesan;

  const KebutuhanException(this.pesan);

  @override
  String toString() => pesan;
}
