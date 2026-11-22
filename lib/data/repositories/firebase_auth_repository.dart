
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/app_user.dart';
import 'auth_repository.dart';

/// Implementasi autentikasi menggunakan Firebase Auth dan Firestore.
class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  String? get petunjukDemo => null;

  /// Memantau perubahan autentikasi dan profil Firestore.
  @override
  Stream<AuthSnapshot> get authStateChanges {
    return _auth.authStateChanges().asyncExpand((firebaseUser) {
      if (firebaseUser == null) {
        return Stream<AuthSnapshot>.value(
          const AuthSnapshot.keluar(),
        );
      }

      return _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists || snapshot.data() == null) {
          return AuthSnapshot.tanpaProfil(
            firebaseUser.email ?? '',
          );
        }

        final data = snapshot.data()!;
        final nama = data['nama'];

        if (nama is! String || nama.trim().isEmpty) {
          return AuthSnapshot.tanpaProfil(
            firebaseUser.email ?? '',
          );
        }

        return AuthSnapshot.masuk(
          AppUser(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            nama: nama,
            role: data['role'] == 'admin'
                ? UserRole.admin
                : UserRole.warga,
          ),
        );
      });
    });
  }

  /// Login menggunakan Firebase Authentication.
  @override
  Future<AppUser> masuk({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('========== PROSES LOGIN ===========');
      debugPrint('EMAIL: ${email.trim()}');

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw const AuthException(
          AuthErrorCode.galatTakDikenal,
        );
      }

      debugPrint('AUTH BERHASIL');
      debugPrint('UID: ${firebaseUser.uid}');

      return await _ambilProfil(firebaseUser);
    } on FirebaseAuthException catch (e) {
      debugPrint('========== FIREBASE AUTH ERROR ==========');
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('=========================================');

      throw _terjemahkanGalat(e);
    } on FirebaseException catch (e) {
      debugPrint('========== FIRESTORE ERROR ==============');
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('=========================================');

      rethrow;
    }
  }

  /// Mendaftarkan akun baru sebagai warga.
  @override
  Future<AppUser> daftar({
    required String nama,
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('========== PROSES PENDAFTARAN ==========');

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final firebaseUser = credential.user;

      if (firebaseUser == null) {
        throw const AuthException(
          AuthErrorCode.galatTakDikenal,
        );
      }

      final user = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? email.trim(),
        nama: nama.trim(),
        role: UserRole.warga,
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set({
        'uid': user.uid,
        'email': user.email,
        'nama': user.nama,
        'role': 'warga',
      });

      debugPrint('PENDAFTARAN BERHASIL');
      debugPrint('UID: ${user.uid}');

      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('========== REGISTER AUTH ERROR =========');
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('=========================================');

      throw _terjemahkanGalat(e);
    } on FirebaseException catch (e) {
      debugPrint('========== REGISTER FIRESTORE ERROR =====');
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('=========================================');

      rethrow;
    }
  }

  /// Mengambil profil pengguna dari Firestore.
  Future<AppUser> _ambilProfil(User firebaseUser) async {
    try {
      debugPrint('========== MEMBACA PROFIL ===============');
      debugPrint('UID: ${firebaseUser.uid}');
      debugPrint('EMAIL: ${firebaseUser.email}');

      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      debugPrint('DOKUMEN ADA: ${doc.exists}');

      if (!doc.exists || doc.data() == null) {
        throw const AuthException(
          AuthErrorCode.profilTidakDitemukan,
        );
      }

      final data = doc.data()!;
      final nama = data['nama'];

      if (nama is! String || nama.trim().isEmpty) {
        throw const AuthException(
          AuthErrorCode.profilTidakDitemukan,
        );
      }

      debugPrint('PROFIL BERHASIL DIBACA');
      debugPrint('NAMA: $nama');
      debugPrint('ROLE: ${data['role']}');

      return AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        nama: nama,
        role: data['role'] == 'admin'
            ? UserRole.admin
            : UserRole.warga,
      );
    } on FirebaseException catch (e) {
      debugPrint('========== FIRESTORE PROFILE ERROR =====');
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('=========================================');

      rethrow;
    }
  }

  /// Menerjemahkan galat Firebase menjadi pesan aplikasi.
  AuthException _terjemahkanGalat(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return const AuthException(
          AuthErrorCode.emailTidakValid,
        );

      case 'email-already-in-use':
        return const AuthException(
          AuthErrorCode.emailSudahTerdaftar,
        );

      case 'weak-password':
        return const AuthException(
          AuthErrorCode.kataSandiLemah,
        );

      case 'too-many-requests':
        return const AuthException(
          AuthErrorCode.terlaluBanyakPercobaan,
        );

      case 'network-request-failed':
        return const AuthException(
          AuthErrorCode.tanpaKoneksi,
        );

      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-credential':
      case 'invalid-login-credentials':
        return const AuthException(
          AuthErrorCode.kredensialSalah,
        );

      default:
        return const AuthException(
          AuthErrorCode.galatTakDikenal,
        );
    }
  }

  /// Logout dari Firebase.
  @override
  Future<void> keluar() async {
    await _auth.signOut();
    debugPrint('LOGOUT BERHASIL');
  }
}
