/// Kebutuhan/permintaan yang dikirim warga lewat H7 (Modul Minggu 7).
///
/// Ini **bukan** data panduan dan **bukan** data kependudukan: hanya nama
/// pemohon, layanan yang dimaksud, dan pesan bebas. Tidak ada NIK/KK yang
/// diminta (§1.4 dokumen arsitektur).
class KebutuhanWarga {
  final String id;
  final String namaPemohon;
  final String serviceId;
  final String serviceNama;
  final String pesan;
  final DateTime dibuatPada;

  const KebutuhanWarga({
    required this.id,
    required this.namaPemohon,
    required this.serviceId,
    required this.serviceNama,
    required this.pesan,
    required this.dibuatPada,
  });
}
