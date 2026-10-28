import '../../domain/entities/kebutuhan_warga.dart';
import 'kebutuhan_repository.dart';

/// Penyimpanan kebutuhan warga di memori (Modul Minggu 7 §5).
///
/// Data **hilang saat aplikasi dijalankan ulang** — ini disengaja: modul
/// meminta state sederhana dulu, database menyusul setelah UTS. Karena itu
/// halaman H7 menampilkan catatan bahwa data hanya bertahan selama sesi.
class InMemoryKebutuhanRepository implements KebutuhanRepository {
  final List<KebutuhanWarga> _items = <KebutuhanWarga>[];
  int _urut = 0;

  @override
  Future<List<KebutuhanWarga>> daftar() async =>
      List<KebutuhanWarga>.unmodifiable(_items.reversed);

  @override
  Future<KebutuhanWarga> kirim({
    required String namaPemohon,
    required String serviceId,
    required String serviceNama,
    required String pesan,
  }) async {
    final nama = namaPemohon.trim();
    final isi = pesan.trim();

    if (nama.isEmpty) {
      throw const KebutuhanException('Nama pemohon wajib diisi.');
    }
    if (serviceId.trim().isEmpty) {
      throw const KebutuhanException('Jenis layanan wajib dipilih.');
    }
    if (isi.isEmpty) {
      throw const KebutuhanException('Pesan atau kebutuhan wajib diisi.');
    }

    final item = KebutuhanWarga(
      id: 'KB-${(++_urut).toString().padLeft(3, '0')}',
      namaPemohon: nama,
      serviceId: serviceId.trim(),
      serviceNama: serviceNama,
      pesan: isi,
      dibuatPada: DateTime.now(),
    );
    _items.add(item);
    return item;
  }
}
