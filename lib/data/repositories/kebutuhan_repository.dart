
import '../../domain/entities/kebutuhan_warga.dart';

/// Antarmuka penyimpanan kebutuhan warga.
abstract class KebutuhanRepository {
  /// Mengambil seluruh kebutuhan.
  Future<List<KebutuhanWarga>> daftar();

  /// Mengirim kebutuhan baru.
  Future<KebutuhanWarga> kirim({
    required String namaPemohon,
    required String serviceId,
    required String serviceNama,
    required String pesan,
  });

  /// Mengubah kebutuhan milik pengguna.
  Future<KebutuhanWarga> ubah({
    required String id,
    required String namaPemohon,
    required String serviceId,
    required String serviceNama,
    required String pesan,
  });

  /// Menghapus kebutuhan berdasarkan ID.
  Future<void> hapus({
    required String id,
  });
}

/// Galat penyimpanan kebutuhan warga.
class KebutuhanException implements Exception {
  final String pesan;

  const KebutuhanException(this.pesan);

  @override
  String toString() => pesan;
}
