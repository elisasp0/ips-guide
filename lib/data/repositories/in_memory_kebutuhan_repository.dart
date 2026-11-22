import 'dart:async';
import '../../domain/entities/kebutuhan_warga.dart';
import 'kebutuhan_repository.dart';

/// Penyimpanan kebutuhan warga di memori.
///
/// Implementasi cadangan untuk pengujian lokal.
/// Bukan penyimpanan utama aplikasi.
class InMemoryKebutuhanRepository implements KebutuhanRepository {
  final List<KebutuhanWarga> _items = <KebutuhanWarga>[];
  int _urut = 0;


  final StreamController<List<KebutuhanWarga>> _perubahan =
      StreamController<List<KebutuhanWarga>>.broadcast();

  @override
  Stream<List<KebutuhanWarga>> pantau() async* {
    yield await daftar();
    yield* _perubahan.stream;
  }


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
      throw const KebutuhanException(
        'Nama pemohon wajib diisi.',
      );
    }

    if (serviceId.trim().isEmpty) {
      throw const KebutuhanException(
        'Jenis layanan wajib dipilih.',
      );
    }

    if (isi.isEmpty) {
      throw const KebutuhanException(
        'Pesan atau kebutuhan wajib diisi.',
      );
    }

    if (isi.length > 300) {
      throw const KebutuhanException(
        'Pesan maksimal 300 karakter.',
      );
    }

    final item = KebutuhanWarga(
      id: 'KB-${(++_urut).toString().padLeft(3, '0')}',
      pemilikUid: 'in-memory',
      namaPemohon: nama,
      serviceId: serviceId.trim(),
      serviceNama: serviceNama,
      pesan: isi,
      dibuatPada: DateTime.now(),
    );


    _items.add(item);

    // Memberi tahu pendengar saat data baru disimpan.
    if (!_perubahan.isClosed) {
      _perubahan.add(
        List<KebutuhanWarga>.unmodifiable(_items.reversed),
      );
    }

    return item;

  }
}
