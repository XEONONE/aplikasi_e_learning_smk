import 'package:aplikasi_e_learning_smk/models/user_model.dart';
import 'package:aplikasi_e_learning_smk/screens/guru_dashboard_screen.dart';
import 'package:aplikasi_e_learning_smk/screens/login_screen.dart';
import 'package:aplikasi_e_learning_smk/screens/siswa_dashboard_screen.dart';
import 'package:aplikasi_e_learning_smk/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          // User sudah login, cek peran
          return FutureBuilder<UserModel?>(
            future: AuthService().getUserData(snapshot.data!.uid),
            builder: (context, userModelSnapshot) {
              if (userModelSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (userModelSnapshot.hasData && userModelSnapshot.data != null) {
                final userRole = userModelSnapshot.data!.role;
                if (userRole == 'guru') {
                  // Jika const tidak bisa, hapus const
                  return const GuruDashboardScreen();
                } else {
                  // Jika const tidak bisa, hapus const
                  return const SiswaDashboardScreen();
                }
              }
              // Data user tidak ditemukan, paksa logout
              AuthService().signOut();
              // ## PERBAIKAN: Hapus const ##
              return LoginScreen();
            },
          );
        } else {
          // User belum login
          // ## PERBAIKAN: Hapus const ##
          return LoginScreen();
        }
      },
    );
  }
}