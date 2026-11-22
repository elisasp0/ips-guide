
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/kebutuhan_warga.dart';
import '../../services/layanan_firestore.dart';
import 'kebutuhan_repository.dart';

/// Implementasi penyimpanan kebutuhan warga menggunakan Firestore.
class FirestoreKebutuhanRepository implements KebutuhanRepository {
  final LayananFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreKebutuhanRepository({
    required LayananFirestore firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore,
        _auth = auth ?? FirebaseAuth.instance;

  /// Mengambil UID pengguna yang sedang login.
  String _ambilUid() {
    final user = _auth.currentUser;

    if (user == null) {
      throw const KebutuhanException(
        'Silakan login terlebih dahulu.',
      );
    }

    return user.uid;
  }

  /// Mengambil kebutuhan milik pengguna yang sedang login.
  @override
  Future<List<KebutuhanWarga>> daftar() async {
    final uid = _ambilUid();

    return _firestore.ambilKebutuhan(
      pemilikUid: uid,
    );
  }

  /// Menyimpan kebutuhan warga ke Cloud Firestore.
  @override
  Future<KebutuhanWarga> kirim({
    required String namaPemohon,
    required String serviceId,
    required String serviceNama,
    required String pesan,
  }) async {
    final uid = _ambilUid();

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

    return _firestore.simpanKebutuhan(
      pemilikUid: uid,
      namaPemohon: nama,
      serviceId: serviceId.trim(),
      serviceNama: serviceNama,
      pesan: isi,
    );
  }
}
