// lib/screens/siswa_dashboard_screen.dart
import 'package:aplikasi_e_learning_smk/models/user_model.dart';
import 'package:aplikasi_e_learning_smk/screens/profile_screen.dart';
import 'package:aplikasi_e_learning_smk/screens/student_graded_tasks_screen.dart'; // <-- IMPORT BARU
import 'package:aplikasi_e_learning_smk/screens/student_home_screen.dart';
import 'package:aplikasi_e_learning_smk/screens/student_materi_list_screen.dart';
// import 'package:aplikasi_e_learning_smk/screens/student_task_list_screen.dart'; // <-- HAPUS IMPORT LAMA
// import 'package:aplikasi_e_learning_smk/screens/student_nilai_screen.dart'; // <-- HAPUS IMPORT LAMA
import 'package:aplikasi_e_learning_smk/services/auth_service.dart';
import 'package:aplikasi_e_learning_smk/services/notification_service.dart'; // Pastikan ini ada jika Anda pakai notifikasi
import 'package:flutter/material.dart';

class SiswaDashboardScreen extends StatefulWidget {
  const SiswaDashboardScreen({super.key});

  @override
  State<SiswaDashboardScreen> createState() => _SiswaDashboardScreenState();
}

class _SiswaDashboardScreenState extends State<SiswaDashboardScreen> {
  int _selectedIndex = 0;
  UserModel? _userData;
  bool _isLoading = true;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    NotificationService().initialize(); // Panggil inisialisasi notifikasi
  }

  Future<void> _fetchUserData() async {
    String? userId = _authService.getCurrentUser()?.uid;
    if (userId != null) {
      _userData = await _authService.getUserData(userId);
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Method untuk membuat daftar widget halaman
  List<Widget> _buildWidgetOptions(String? kelasId) {
    final currentKelasId = kelasId ?? '';

    // --- PERUBAHAN DI SINI ---
    return <Widget>[
      StudentHomeScreen(kelasId: currentKelasId), // Indeks 0
      const StudentMateriListScreen(), // Indeks 1
      const StudentGradedTasksScreen(), // Indeks 2 (MENGGANTIKAN 2 HALAMAN LAMA)
      const ProfileScreen(), // Indeks 3
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_userData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Gagal memuat data pengguna.'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _isLoading = true;
                  });
                  await _fetchUserData();
                  if (_userData == null && mounted) {
                    _authService.signOut();
                  }
                },
                child: const Text('Coba Lagi'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => _authService.signOut(),
                child: const Text('Logout'),
              ),
            ],
          ),
        ),
      );
    }

    final userKelasId = _userData!.kelas;

    return Scaffold(
      body: Center(child: _buildWidgetOptions(userKelasId)[_selectedIndex]),
      // --- PASTIKAN TOMBOL NAVIGASI SESUAI (4 TOMBOL) ---
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda', // Indeks 0
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: 'Materi', // Indeks 1
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Tugas', // Indeks 2
          ),
          // Item Nilai sudah dihapus
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil', // Indeks 3
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
