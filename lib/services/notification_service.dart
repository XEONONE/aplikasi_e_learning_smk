// lib/services/notification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    // 1. Meminta izin notifikasi dari pengguna (untuk iOS & Android 13+)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Izin notifikasi diberikan oleh pengguna.');
      // 2. Dapatkan token FCM
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('FCM Token: $token');
        // 3. Simpan token ke database
        await _saveTokenToDatabase(token);
      }
    } else {
      print('Pengguna menolak izin notifikasi.');
    }
  }

  // ## FUNGSI YANG DIPERBAIKI ##
  Future<void> _saveTokenToDatabase(String token) async {
    // Dapatkan UID pengguna yang sedang login
    String? uid = _auth.currentUser?.uid;

    if (uid != null) {
      try {
        // Gunakan .set() dengan merge:true.
        // Ini akan membuat dokumen/field jika belum ada,
        // atau memperbaruinya jika sudah ada. Ini lebih aman daripada .update().
        await _firestore.collection('users').doc(uid).set({
          'fcmTokens': FieldValue.arrayUnion([token]),
        }, SetOptions(merge: true));

        print('Token berhasil disimpan ke Firestore untuk user: $uid');
      } catch (e) {
        print('Gagal menyimpan token ke Firestore: $e');
      }
    }
  }
}
