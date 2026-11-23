
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

  /// Memvalidasi data kebutuhan.
  void _validasi({
    required String namaPemohon,
    required String serviceId,
    required String pesan,
  }) {
    if (namaPemohon.trim().isEmpty) {
      throw const KebutuhanException(
        'Nama pemohon wajib diisi.',
      );
    }

    if (serviceId.trim().isEmpty) {
      throw const KebutuhanException(
        'Jenis layanan wajib dipilih.',
      );
    }

    if (pesan.trim().isEmpty) {
      throw const KebutuhanException(
        'Pesan atau kebutuhan wajib diisi.',
      );
    }

    if (pesan.trim().length > 300) {
      throw const KebutuhanException(
        'Pesan maksimal 300 karakter.',
      );
    }
  }

  /// Mengambil kebutuhan milik pengguna yang sedang login.
  @override
  Future<List<KebutuhanWarga>> daftar() async {
    final uid = _ambilUid();

    return _firestore.ambilKebutuhan(
      pemilikUid: uid,
    );
  }


  /// Memantau kebutuhan milik pengguna secara real-time.
  @override
  Stream<List<KebutuhanWarga>> pantau() {
    final uid = _ambilUid();

    return _firestore.pantauKebutuhan(
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

    _validasi(
      namaPemohon: namaPemohon,
      serviceId: serviceId,
      pesan: pesan,
    );

    return _firestore.simpanKebutuhan(
      pemilikUid: uid,
      namaPemohon: namaPemohon.trim(),
      serviceId: serviceId.trim(),
      serviceNama: serviceNama,
      pesan: pesan.trim(),
    );
  }

  /// Mengubah kebutuhan milik pengguna yang sedang login.
  @override
  Future<KebutuhanWarga> ubah({
    required String id,
    required String namaPemohon,
    required String serviceId,
    required String serviceNama,
    required String pesan,
  }) async {
    final uid = _ambilUid();

    _validasi(
      namaPemohon: namaPemohon,
      serviceId: serviceId,
      pesan: pesan,
    );

    return _firestore.ubahKebutuhan(
      id: id,
      pemilikUid: uid,
      namaPemohon: namaPemohon.trim(),
      serviceId: serviceId.trim(),
      serviceNama: serviceNama,
      pesan: pesan.trim(),
    );
  }

  /// Menghapus kebutuhan milik pengguna yang sedang login.
  @override
  Future<void> hapus({
    required String id,
  }) async {
    final uid = _ambilUid();

    await _firestore.hapusKebutuhan(
      id: id,
      pemilikUid: uid,
    );
  }
}
