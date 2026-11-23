
import '../../domain/entities/kebutuhan_warga.dart';
import 'kebutuhan_repository.dart';

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
    final layanan = serviceId.trim();
    final isi = pesan.trim();

    _validasi(nama, layanan, isi);

    final item = KebutuhanWarga(
      id: 'KB-${(++_urut).toString().padLeft(3, '0')}',
      pemilikUid: 'in-memory',
      namaPemohon: nama,
      serviceId: layanan,
      serviceNama: serviceNama,
      pesan: isi,
      dibuatPada: DateTime.now(),
    );

    _items.add(item);
    return item;
  }

  @override
  Future<KebutuhanWarga> ubah({
    required String id,
    required String namaPemohon,
    required String serviceId,
    required String serviceNama,
    required String pesan,
  }) async {
    final index = _items.indexWhere((item) => item.id == id);

    if (index == -1) {
      throw const KebutuhanException('Kebutuhan tidak ditemukan.');
    }

    final lama = _items[index];

    if (!lama.bisaDiubah) {
      throw const KebutuhanException(
        'Kebutuhan tidak dapat diubah karena statusnya bukan Menunggu.',
      );
    }

    final nama = namaPemohon.trim();
    final layanan = serviceId.trim();
    final isi = pesan.trim();

    _validasi(nama, layanan, isi);

    final hasil = KebutuhanWarga(
      id: lama.id,
      pemilikUid: lama.pemilikUid,
      namaPemohon: nama,
      serviceId: layanan,
      serviceNama: serviceNama,
      pesan: isi,
      dibuatPada: lama.dibuatPada,
      status: lama.status,
      diubahPada: DateTime.now(),
    );

    _items[index] = hasil;
    return hasil;
  }

  @override
  Future<void> hapus({required String id}) async {
    final index = _items.indexWhere((item) => item.id == id);

    if (index == -1) {
      throw const KebutuhanException('Kebutuhan tidak ditemukan.');
    }

    if (!_items[index].bisaDiubah) {
      throw const KebutuhanException(
        'Kebutuhan tidak dapat dihapus karena statusnya bukan Menunggu.',
      );
    }

    _items.removeAt(index);
  }

  void _validasi(String nama, String layanan, String isi) {
    if (nama.isEmpty) {
      throw const KebutuhanException('Nama pemohon wajib diisi.');
    }
    if (layanan.isEmpty) {
      throw const KebutuhanException('Jenis layanan wajib dipilih.');
    }
    if (isi.isEmpty) {
      throw const KebutuhanException('Pesan atau kebutuhan wajib diisi.');
    }
    if (isi.length > 300) {
      throw const KebutuhanException('Pesan maksimal 300 karakter.');
    }
  }
}
