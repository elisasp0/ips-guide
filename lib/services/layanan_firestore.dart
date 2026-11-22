
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

  /// Menyimpan kebutuhan warga ke Firestore.
  Future<KebutuhanWarga> simpanKebutuhan({
    required String pemilikUid,
    required String namaPemohon,
    required String serviceId,
    required String serviceNama,
    required String pesan,
  }) async {
    final uid = pemilikUid.trim();
    final nama = namaPemohon.trim();
    final isi = pesan.trim();

    if (uid.isEmpty) {
      throw Exception('Pengguna belum terautentikasi.');
    }

    if (nama.isEmpty) {
      throw Exception('Nama pemohon wajib diisi.');
    }

    if (serviceId.trim().isEmpty) {
      throw Exception('Jenis layanan wajib dipilih.');
    }

    if (isi.isEmpty) {
      throw Exception('Pesan atau kebutuhan wajib diisi.');
    }

    if (isi.length > 300) {
      throw Exception('Pesan maksimal 300 karakter.');
    }

    final doc = _kebutuhan.doc();
    final waktu = DateTime.now();

    final kebutuhan = KebutuhanWarga(
      id: doc.id,
      pemilikUid: uid,
      namaPemohon: nama,
      serviceId: serviceId.trim(),
      serviceNama: serviceNama,
      pesan: isi,
      dibuatPada: waktu,
    );

    await doc.set({
      'id': kebutuhan.id,
      'pemilikUid': kebutuhan.pemilikUid,
      'namaPemohon': kebutuhan.namaPemohon,
      'serviceId': kebutuhan.serviceId,
      'serviceNama': kebutuhan.serviceNama,
      'pesan': kebutuhan.pesan,
      'dibuatPada': Timestamp.fromDate(waktu),
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
      final waktu = data['dibuatPada'] as Timestamp;

      return KebutuhanWarga(
        id: data['id'] as String? ?? doc.id,
        pemilikUid: data['pemilikUid'] as String? ?? '',
        namaPemohon: data['namaPemohon'] as String? ?? '',
        serviceId: data['serviceId'] as String? ?? '',
        serviceNama: data['serviceNama'] as String? ?? '',
        pesan: data['pesan'] as String? ?? '',
        dibuatPada: waktu.toDate(),
      );
    }).toList();

    // Data terbaru ditampilkan terlebih dahulu.
    hasil.sort(
      (a, b) => b.dibuatPada.compareTo(a.dibuatPada),
    );

    return hasil;
  }

  /// Memantau kebutuhan warga secara real-time.
  Stream<List<KebutuhanWarga>> pantauKebutuhan({
    required String pemilikUid,
  }) {
    final uid = pemilikUid.trim();

    if (uid.isEmpty) {
      return Stream.error(
        Exception('Pengguna belum terautentikasi.'),
      );
    }

    return _kebutuhan
        .where('pemilikUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final hasil = snapshot.docs.map((doc) {
        final data = doc.data();
        final waktu = data['dibuatPada'] as Timestamp;

        return KebutuhanWarga(
          id: data['id'] as String? ?? doc.id,
          pemilikUid: data['pemilikUid'] as String? ?? '',
          namaPemohon: data['namaPemohon'] as String? ?? '',
          serviceId: data['serviceId'] as String? ?? '',
          serviceNama: data['serviceNama'] as String? ?? '',
          pesan: data['pesan'] as String? ?? '',
          dibuatPada: waktu.toDate(),
        );
      }).toList();

      hasil.sort(
        (a, b) => b.dibuatPada.compareTo(a.dibuatPada),
      );

      return hasil;
    });
  }
  
}
