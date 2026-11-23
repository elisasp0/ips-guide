
import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/guidance_service.dart';
import '../domain/entities/kebutuhan_warga.dart';

/// Layanan akses Cloud Firestore untuk IPS-Guide.
class LayananFirestore {
  final FirebaseFirestore _firestore;

  LayananFirestore({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Collection layanan administrasi.
  CollectionReference<Map<String, dynamic>> get _services =>
      _firestore.collection('services');

  /// Collection kebutuhan warga.
  CollectionReference<Map<String, dynamic>> get _kebutuhan =>
      _firestore.collection('kebutuhan_warga');

  /// Membaca tanggal dari Firestore.
  DateTime? _bacaTanggal(dynamic nilai) {
    if (nilai is Timestamp) {
      return nilai.toDate();
    }

    if (nilai is DateTime) {
      return nilai;
    }

    return null;
  }

  /// Memastikan data wajib valid.
  void _validasi({
    required String namaPemohon,
    required String serviceId,
    required String pesan,
  }) {
    if (namaPemohon.trim().isEmpty) {
      throw Exception('Nama pemohon wajib diisi.');
    }

    if (serviceId.trim().isEmpty) {
      throw Exception('Jenis layanan wajib dipilih.');
    }

    if (pesan.trim().isEmpty) {
      throw Exception('Pesan atau kebutuhan wajib diisi.');
    }

    if (pesan.trim().length > 300) {
      throw Exception('Pesan maksimal 300 karakter.');
    }
  }

  /// Membaca semua layanan dari Firestore.
  Future<List<GuidanceService>> ambilLayanan() async {
    final snapshot = await _services.orderBy('urutan').get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return GuidanceService(
        id: data['id'] as String? ?? doc.id,
        nama: data['nama'] as String? ?? '',
        deskripsi: data['deskripsi'] as String? ?? '',
        ikon: data['ikon'] as String? ?? '',
        urutan: (data['urutan'] as num?)?.toInt() ?? 0,
        estimasiHariMin:
            (data['estimasiHariMin'] as num?)?.toInt() ?? 0,
        estimasiHariMax:
            (data['estimasiHariMax'] as num?)?.toInt() ?? 0,
        aktif: data['aktif'] as bool? ?? true,
        stepsDasar: List<String>.from(
          data['stepsDasar'] ?? const [],
        ),
      );
    }).toList();
  }

  /// Menyimpan kebutuhan warga baru ke Firestore.
  Future<KebutuhanWarga> simpanKebutuhan({
    required String pemilikUid,
    required String namaPemohon,
    required String serviceId,
    required String serviceNama,
    required String pesan,
  }) async {
    final uid = pemilikUid.trim();
    final nama = namaPemohon.trim();
    final layanan = serviceId.trim();
    final isi = pesan.trim();

    if (uid.isEmpty) {
      throw Exception('Pengguna belum terautentikasi.');
    }

    _validasi(
      namaPemohon: nama,
      serviceId: layanan,
      pesan: isi,
    );

    final doc = _kebutuhan.doc();
    final waktu = DateTime.now();

    final kebutuhan = KebutuhanWarga(
      id: doc.id,
      pemilikUid: uid,
      namaPemohon: nama,
      serviceId: layanan,
      serviceNama: serviceNama,
      pesan: isi,
      dibuatPada: waktu,
      status: KebutuhanWarga.statusMenunggu,
    );

    await doc.set({
      'id': kebutuhan.id,
      'pemilikUid': kebutuhan.pemilikUid,
      'namaPemohon': kebutuhan.namaPemohon,
      'serviceId': kebutuhan.serviceId,
      'serviceNama': kebutuhan.serviceNama,
      'pesan': kebutuhan.pesan,
      'dibuatPada': Timestamp.fromDate(waktu),
      'status': kebutuhan.status,
      'diubahPada': null,
    });

    return kebutuhan;
  }

  /// Membaca kebutuhan milik pengguna tertentu.
  Future<List<KebutuhanWarga>> ambilKebutuhan({
    required String pemilikUid,
  }) async {
    final uid = pemilikUid.trim();

    if (uid.isEmpty) {
      throw Exception('Pengguna belum terautentikasi.');
    }

    final snapshot = await _kebutuhan
        .where('pemilikUid', isEqualTo: uid)
        .get();

    final hasil = snapshot.docs.map((doc) {
      final data = doc.data();

      final dibuatPada = _bacaTanggal(data['dibuatPada']);

      if (dibuatPada == null) {
        throw StateError(
          'Data kebutuhan ${doc.id} tidak memiliki tanggal pembuatan yang valid.',
        );
      }

      return KebutuhanWarga(
        id: data['id'] as String? ?? doc.id,
        pemilikUid: data['pemilikUid'] as String? ?? '',
        namaPemohon: data['namaPemohon'] as String? ?? '',
        serviceId: data['serviceId'] as String? ?? '',
        serviceNama: data['serviceNama'] as String? ?? '',
        pesan: data['pesan'] as String? ?? '',
        dibuatPada: dibuatPada,
        // Dokumen lama yang belum memiliki status dianggap Menunggu.
        status: data['status'] as String? ??
            KebutuhanWarga.statusMenunggu,
        diubahPada: _bacaTanggal(data['diubahPada']),
      );
    }).toList();

    hasil.sort(
      (a, b) => b.dibuatPada.compareTo(a.dibuatPada),
    );

    return hasil;
  }

  /// Memastikan kebutuhan merupakan milik pengguna
  /// dan masih berstatus Menunggu.
  Future<DocumentReference<Map<String, dynamic>>>
      _periksaKebutuhan({
    required String id,
    required String pemilikUid,
  }) async {
    final uid = pemilikUid.trim();

    if (uid.isEmpty) {
      throw Exception('Pengguna belum terautentikasi.');
    }

    if (id.trim().isEmpty) {
      throw Exception('ID kebutuhan tidak valid.');
    }

    final doc = _kebutuhan.doc(id);
    final snapshot = await doc.get();

    if (!snapshot.exists) {
      throw Exception('Kebutuhan tidak ditemukan.');
    }

    final data = snapshot.data()!;

    if (data['pemilikUid'] != uid) {
      throw Exception('Kamu tidak memiliki akses ke kebutuhan ini.');
    }

    final status = data['status'] as String? ??
        KebutuhanWarga.statusMenunggu;

    if (status != KebutuhanWarga.statusMenunggu) {
      throw Exception(
        'Kebutuhan tidak dapat diubah karena statusnya bukan Menunggu.',
      );
    }

    return doc;
  }

  /// Mengubah data kebutuhan warga menggunakan update().
  Future<KebutuhanWarga> ubahKebutuhan({
    required String id,
    required String pemilikUid,
    required String namaPemohon,
    required String serviceId,
    required String serviceNama,
    required String pesan,
  }) async {
    final nama = namaPemohon.trim();
    final layanan = serviceId.trim();
    final isi = pesan.trim();

    _validasi(
      namaPemohon: nama,
      serviceId: layanan,
      pesan: isi,
    );

    final doc = await _periksaKebutuhan(
      id: id,
      pemilikUid: pemilikUid,
    );

    final snapshot = await doc.get();
    final data = snapshot.data()!;

    final dibuatPada = _bacaTanggal(data['dibuatPada']);

    if (dibuatPada == null) {
      throw Exception('Tanggal pembuatan kebutuhan tidak valid.');
    }

    final waktuUbah = DateTime.now();

    await doc.update({
      'namaPemohon': nama,
      'serviceId': layanan,
      'serviceNama': serviceNama,
      'pesan': isi,
      'diubahPada': Timestamp.fromDate(waktuUbah),
    });

    return KebutuhanWarga(
      id: id,
      pemilikUid: pemilikUid.trim(),
      namaPemohon: nama,
      serviceId: layanan,
      serviceNama: serviceNama,
      pesan: isi,
      dibuatPada: dibuatPada,
      status: data['status'] as String? ??
          KebutuhanWarga.statusMenunggu,
      diubahPada: waktuUbah,
    );
  }

  /// Menghapus kebutuhan warga menggunakan delete().
  Future<void> hapusKebutuhan({
    required String id,
    required String pemilikUid,
  }) async {
    final doc = await _periksaKebutuhan(
      id: id,
      pemilikUid: pemilikUid,
    );

    await doc.delete();
  }
}
