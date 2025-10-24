// lib/services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aplikasi_e_learning_smk/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mendapatkan stream status autentikasi user
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Mendapatkan data user dari Firestore berdasarkan UID
  Future<UserModel?> getUserData(String uid) async {
    try {
      // Cari di koleksi users berdasarkan field 'uid'
      var snapshot = await _firestore
          .collection('users')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Ambil ID dokumen (yaitu NIP/NISN)
        String docId = snapshot.docs.first.id;
        // Ambil data dan tambahkan ID ke dalamnya
        Map<String, dynamic> data = snapshot.docs.first.data();
        data['id'] = docId; // Memastikan field 'id' terisi
        return UserModel.fromMap(data);
      }
      return null;
    } catch (e) {
      print("Error getting user data: $e");
      return null;
    }
  }

// Tambahkan ini di dalam class AuthService
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Fungsi Aktivasi Akun
  Future<String> activateAccount({
    required String nipNisn,
    required String password,
  }) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(nipNisn).get();

      if (!userDoc.exists) {
        return "NIP/NISN tidak terdaftar.";
      }

      final data = userDoc.data() as Map<String, dynamic>;
      if (data['uid'] != null && data['uid'] != '') {
        return "Akun ini sudah aktif. Silakan login.";
      }

      String email = data['email'];
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(nipNisn).update({
        'uid': userCredential.user!.uid,
      });

      return "Sukses";
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Terjadi error.";
    } catch (e) {
      return "Terjadi error tidak diketahui.";
    }
  }

  // Fungsi Login
  Future<String> login({
    required String nipNisn,
    required String password,
  }) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(nipNisn).get();
      if (!userDoc.exists) {
        return "NIP/NISN atau Password salah.";
      }
      String email = (userDoc.data() as Map<String, dynamic>)['email'];

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return "Sukses";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return "NIP/NISN atau Password salah.";
      }
      return e.message ?? "Terjadi error.";
    } catch (e) {
      return "Terjadi error tidak diketahui.";
    }
  }

  // Fungsi Logout
  Future<void> signOut() async {
    await _auth.signOut();
  }
}