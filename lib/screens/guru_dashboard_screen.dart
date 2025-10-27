// lib/screens/guru_dashboard_screen.dart

import 'package:aplikasi_e_learning_smk/models/user_model.dart';
import 'package:aplikasi_e_learning_smk/screens/guru_home_screen.dart';
import 'package:aplikasi_e_learning_smk/screens/guru_materi_list_screen.dart';
import 'package:aplikasi_e_learning_smk/screens/task_list_screen.dart';
import 'package:aplikasi_e_learning_smk/services/auth_service.dart';
import 'package:aplikasi_e_learning_smk/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:aplikasi_e_learning_smk/screens/account_settings_screen.dart';
import 'package:aplikasi_e_learning_smk/screens/create_task_screen.dart';
import 'package:aplikasi_e_learning_smk/screens/upload_materi_screen.dart';
import 'package:aplikasi_e_learning_smk/screens/edit_profile_screen.dart';

// --- Widget GuruProfileScreen ---
class GuruProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;
  const GuruProfileScreen({super.key, this.onProfileUpdated});

  @override
  State<GuruProfileScreen> createState() => _GuruProfileScreenState();
}

class _GuruProfileScreenState extends State<GuruProfileScreen> {
  final AuthService _authService = AuthService();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late Future<UserModel?> _userFuture;

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      _userFuture = _authService.getUserData(currentUser!.uid);
    } else {
      _userFuture = Future.value(null);
    }
  }

  // Fungsi internal untuk me-refresh data lokal dan memanggil callback
  void _refreshUserData() {
    if (currentUser != null) {
      // 1. Refresh tampilan Profil
      setState(() {
        _userFuture = _authService.getUserData(currentUser!.uid);
      });
    }
    // 2. Beri sinyal ke Dashboard (untuk diteruskan ke Beranda)
    widget.onProfileUpdated?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.7);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Akun Saya',
              style: theme.textTheme.titleMedium?.copyWith(
                color: subtitleColor,
              ),
            ),
            const Text(
              'Profil',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<UserModel?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Gagal memuat data profil.'));
          }

          final user = snapshot.data!;
          final initial = user.nama.isNotEmpty
              ? user.nama.split(' ').map((e) => e[0]).take(2).join()
              : '?';
          final roleDescription =
              'Guru ${user.mengajarKelas?.join(', ') ?? 'Mapel'}';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: theme.brightness == Brightness.dark
                          ? Colors.grey[700]
                          : theme.colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        initial.toUpperCase(),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.nama,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NIP: ${user.id}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      roleDescription,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildProfileActionTile(
                      icon: Icons.edit_outlined,
                      text: 'Edit Profil',
                      onTap: () {
                        // PENTING: Mendorong ke EditProfileScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditProfileScreen(userData: user),
                          ),
                        ).then((berhasilUpdate) {
                          // Menerima sinyal 'true' dari EditProfileScreen
                          if (berhasilUpdate == true) {
                            _refreshUserData(); // Panggil fungsi refresh
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildProfileActionTile(
                      icon: Icons.settings_outlined,
                      text: 'Pengaturan Akun',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AccountSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text('Keluar'),
                      onPressed: () async {
                        bool? confirmLogout = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Konfirmasi Keluar'),
                              content: const Text(
                                'Apakah Anda yakin ingin keluar?',
                              ),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: Text(
                                    'Keluar',
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        if (confirmLogout == true) {
                          await _authService.signOut();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileActionTile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final iconColor = theme.iconTheme.color?.withOpacity(0.7);
    final textColor = theme.textTheme.bodyLarge?.color;
    final chevronColor = theme.iconTheme.color?.withOpacity(0.5);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(color: textColor),
              ),
            ),
            Icon(Icons.chevron_right, color: chevronColor),
          ],
        ),
      ),
    );
  }
}

// --- Widget GuruTaskManagementScreen (Fix: Pastikan kelas ada) ---
class GuruTaskManagementScreen extends StatefulWidget {
  const GuruTaskManagementScreen({super.key});
  @override
  State<GuruTaskManagementScreen> createState() =>
      _GuruTaskManagementScreenState();
}

class _GuruTaskManagementScreenState extends State<GuruTaskManagementScreen> {
  int _selectedToggleIndex = 0;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleColor = theme.textTheme.titleLarge?.color?.withOpacity(0.7);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manajemen',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: subtitleColor,
                    ),
                  ),
                  Text(
                    'Tugas',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ToggleButtons(
                      isSelected: [
                        _selectedToggleIndex == 0,
                        _selectedToggleIndex == 1,
                      ],
                      onPressed: (index) {
                        setState(() {
                          _selectedToggleIndex = index;
                        });
                      },
                      constraints: const BoxConstraints(
                        minHeight: 40.0,
                        minWidth: 120.0,
                      ),
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text('Tugas Aktif'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text('Riwayat'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Expanded(
              child: TaskListScreen(showExpired: _selectedToggleIndex == 1),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_tugas',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTaskScreen()),
          );
        },
        label: const Text('Tambah Tugas'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

// --- CLASS DASHBOARD UTAMA (GURU DASHBOARD SCREEN) ---
class GuruDashboardScreen extends StatefulWidget {
  const GuruDashboardScreen({super.key});

  @override
  State<GuruDashboardScreen> createState() => _GuruDashboardScreenState();
}

class _GuruDashboardScreenState extends State<GuruDashboardScreen> {
  int _selectedIndex = 0;
  // ===== PERBAIKAN UTAMA: Menggunakan tipe publik State<GuruHomeScreen> =====
  // Ini memperbaiki error 'non_type_as_type_argument'
  final GlobalKey<State<GuruHomeScreen>> _homeKey =
      GlobalKey<State<GuruHomeScreen>>();

  @override
  void initState() {
    super.initState();
    NotificationService().initialize();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Daftar halaman
  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = <Widget>[
      // --- Halaman Beranda (Indeks 0) ---
      GuruHomeScreen(key: _homeKey), // Menggunakan key
      // --- Halaman Materi (Indeks 1) ---
      Scaffold(
        appBar: AppBar(
          title: Builder(
            builder: (context) {
              final theme = Theme.of(context);
              final subtitleColor = theme.textTheme.titleLarge?.color
                  ?.withOpacity(0.7);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manajemen',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: subtitleColor,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    'Materi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                ],
              );
            },
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const GuruMateriListScreen(),
        floatingActionButton: Builder(
          builder: (BuildContext context) {
            return FloatingActionButton.extended(
              heroTag: 'fab_materi',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UploadMateriScreen(),
                  ),
                );
              },
              label: const Text('Tambah Materi'),
              icon: const Icon(Icons.add),
            );
          },
        ),
      ),
      // --- Halaman Tugas (Indeks 2) ---
      const GuruTaskManagementScreen(),
      // --- Halaman Profil (Indeks 3) ---
      // Meneruskan Callback ke GuruProfileScreen
      GuruProfileScreen(
        onProfileUpdated: () {
          // ===== PENTING: MENGAKSES FUNGSI REFRESH DENGAN CASTING DINAMIS =====
          final homeState = _homeKey.currentState;
          if (homeState != null && homeState.mounted) {
            // Kita harus menggunakan 'dynamic' untuk memanggil method publik
            // 'refreshUserData' dari state privat '_GuruHomeScreenState'
            (homeState as dynamic).refreshUserData();
          }
        },
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _selectedIndex, children: _pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: 'Materi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Tugas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
