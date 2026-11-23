
/// Kebutuhan/permintaan yang dikirim warga lewat H7.
///
/// Data berisi identitas pemohon, layanan, dan pesan kebutuhan.
/// Mendukung fitur Edit dan Hapus pada Minggu 11.
class KebutuhanWarga {
  /// Status awal setiap kebutuhan baru.
  static const String statusMenunggu = 'Menunggu';

  final String id;
  final String pemilikUid;
  final String namaPemohon;
  final String serviceId;
  final String serviceNama;
  final String pesan;
  final DateTime dibuatPada;

  /// Status kebutuhan warga.
  final String status;

  /// Waktu terakhir kebutuhan diperbarui.
  /// Bernilai null jika belum pernah diedit.
  final DateTime? diubahPada;

  const KebutuhanWarga({
    required this.id,
    required this.pemilikUid,
    required this.namaPemohon,
    required this.serviceId,
    required this.serviceNama,
    required this.pesan,
    required this.dibuatPada,
    this.status = statusMenunggu,
    this.diubahPada,
  });

  /// Hanya kebutuhan berstatus Menunggu yang dapat diubah/dihapus.
  bool get bisaDiubah => status == statusMenunggu;
}
