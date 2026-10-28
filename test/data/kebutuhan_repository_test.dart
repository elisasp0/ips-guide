import 'package:flutter_test/flutter_test.dart';
import 'package:ips_guide/data/repositories/in_memory_kebutuhan_repository.dart';
import 'package:ips_guide/data/repositories/kebutuhan_repository.dart';

/// Uji penyimpanan kebutuhan warga (Modul Minggu 7 §5: state sederhana).
void main() {
  group('InMemoryKebutuhanRepository', () {
    test('daftar kosong pada awalnya', () async {
      final repo = InMemoryKebutuhanRepository();
      expect(await repo.daftar(), isEmpty);
    });

    test('kirim menyimpan data; daftar mengembalikan terbaru lebih dulu',
        () async {
      final repo = InMemoryKebutuhanRepository();

      await repo.kirim(
        namaPemohon: 'Budi Santoso',
        serviceId: 'ktp',
        serviceNama: 'Kartu Tanda Penduduk Elektronik',
        pesan: 'Perlu mengganti alamat pada KTP.',
      );
      await repo.kirim(
        namaPemohon: 'Sari Dewi',
        serviceId: 'kk',
        serviceNama: 'Kartu Keluarga',
        pesan: 'Perlu menambah anggota keluarga baru.',
      );

      final hasil = await repo.daftar();
      expect(hasil.length, 2);
      expect(hasil.first.namaPemohon, 'Sari Dewi');
      expect(hasil.last.namaPemohon, 'Budi Santoso');
      expect(hasil.first.serviceNama, 'Kartu Keluarga');
    });

    test('kirim memangkas spasi di tepi dan memberi ID berurutan', () async {
      final repo = InMemoryKebutuhanRepository();

      final item = await repo.kirim(
        namaPemohon: '  Budi Santoso  ',
        serviceId: ' ktp ',
        serviceNama: 'Kartu Tanda Penduduk Elektronik',
        pesan: '  Perlu mengganti alamat pada KTP.  ',
      );

      expect(item.namaPemohon, 'Budi Santoso');
      expect(item.serviceId, 'ktp');
      expect(item.pesan, 'Perlu mengganti alamat pada KTP.');
      expect(item.id, 'KB-001');
    });

    test('kirim menolak nama, layanan, atau pesan yang kosong', () async {
      final repo = InMemoryKebutuhanRepository();

      await expectLater(
        repo.kirim(
          namaPemohon: '   ',
          serviceId: 'ktp',
          serviceNama: 'KTP',
          pesan: 'Perlu mengganti alamat pada KTP.',
        ),
        throwsA(isA<KebutuhanException>()),
      );
      await expectLater(
        repo.kirim(
          namaPemohon: 'Budi Santoso',
          serviceId: '  ',
          serviceNama: 'KTP',
          pesan: 'Perlu mengganti alamat pada KTP.',
        ),
        throwsA(isA<KebutuhanException>()),
      );
      await expectLater(
        repo.kirim(
          namaPemohon: 'Budi Santoso',
          serviceId: 'ktp',
          serviceNama: 'KTP',
          pesan: '   ',
        ),
        throwsA(isA<KebutuhanException>()),
      );

      // Tidak ada data setengah jadi yang tertinggal.
      expect(await repo.daftar(), isEmpty);
    });
  });
}
