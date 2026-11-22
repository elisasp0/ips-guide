
/// Kebutuhan/permintaan yang dikirim warga lewat H7 (Modul Minggu 7).
///
/// Bukan data panduan dan bukan data kependudukan.
/// Data hanya berisi identitas pemohon, layanan, dan pesan kebutuhan.
class KebutuhanWarga {
  final String id;
  final String pemilikUid;
  final String namaPemohon;
  final String serviceId;
  final String serviceNama;
  final String pesan;
  final DateTime dibuatPada;

  const KebutuhanWarga({
    required this.id,
    required this.pemilikUid,
    required this.namaPemohon,
    required this.serviceId,
    required this.serviceNama,
    required this.pesan,
    required this.dibuatPada,
  });
}
