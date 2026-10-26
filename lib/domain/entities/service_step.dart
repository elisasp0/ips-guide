/// Satu tahapan pelayanan (katalog lintas layanan, §11.5).
class ServiceStep {
  final String id; // mis. STEP_LOKET
  final String judul;
  final String keterangan;
  final int urutan; // kelipatan 10; seri dipecah dengan id ASC

  const ServiceStep({
    required this.id,
    required this.judul,
    required this.keterangan,
    required this.urutan,
  });
}
