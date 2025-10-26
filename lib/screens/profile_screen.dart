// lib/screens/profile_screen.dart

import 'package:aplikasi_e_learning_smk/models/user_model.dart'; //
import 'package:aplikasi_e_learning_smk/screens/account_settings_screen.dart'; //
import 'package:aplikasi_e_learning_smk/screens/edit_profile_screen.dart'; //
import 'package:aplikasi_e_learning_smk/services/auth_service.dart'; //
import 'package:aplikasi_e_learning_smk/widgets/custom_loading_indicator.dart'; //
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService(); //
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late Future<UserModel?> _userFuture; //

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      _userFuture = _authService.getUserData(currentUser!.uid);
    } else {
      _userFuture = Future.value(null);
    }
  }

  void _refreshUserData() {
    if (currentUser != null) {
      setState(() {
        _userFuture = _authService.getUserData(currentUser!.uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Ambil tema

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Akun Saya',
              // Ambil style dari tema (redup)
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
              ),
            ),
            // Ambil style dari tema
            const Text('Profil', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            // Ambil warna ikon dari tema (redup)
            icon: Icon(
              Icons.notifications_outlined,
              color: theme.iconTheme.color?.withOpacity(0.7),
            ),
          ),
        ],
        // Style AppBar otomatis dari tema
        backgroundColor: Colors.transparent, // Transparan agar menyatu
        elevation: 0,
      ),
      body: FutureBuilder<UserModel?>(
        //
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomLoadingIndicator()); //
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text(
                'Gagal memuat data profil.',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          final user = snapshot.data!;
          final initial = user.nama.isNotEmpty
              ? user.nama
                    .split(' ')
                    .map((e) => e.isNotEmpty ? e[0] : '')
                    .take(2)
                    .join()
              : '?';
          final String roleDescription = user.role == 'guru'
              ? 'Guru ${user.mengajarKelas?.join(', ') ?? 'Mapel'}'
              : 'Siswa ${user.kelas ?? 'Kelas tidak diketahui'}';
          final String idLabel = user.role == 'guru' ? 'NIP' : 'NIS';

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
                      backgroundColor: Colors.grey.shade700,
                      child: Text(
                        initial.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      user.nama,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ), // Ambil style dari tema
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$idLabel: ${user.id}',
                      // Ambil style dari tema (redup)
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      roleDescription,
                      // Ambil style dari tema (redup)
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildProfileActionTile(
                      icon: Icons.edit_outlined,
                      text: 'Edit Profil',
                      onTap: () async {
                        final bool? result = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EditProfileScreen(userData: user),
                          ), //
                        );
                        if (result == true) {
                          _refreshUserData();
                        }
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
                        ); //
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
                              // Dialog otomatis ikut tema
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
                        backgroundColor:
                            theme.colorScheme.error, // Warna error dari tema
                        foregroundColor:
                            theme.colorScheme.onError, // Warna teks dari tema
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.8), // Card semi transparan
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: theme.iconTheme.color?.withOpacity(0.7),
              size: 22,
            ), // Ikon redup dari tema
            const SizedBox(width: 16),
            Expanded(
              child: Text(text, style: theme.textTheme.bodyLarge),
            ), // Teks dari tema
            Icon(
              Icons.chevron_right,
              color: theme.iconTheme.color?.withOpacity(0.5),
            ), // Panah redup dari tema
          ],
        ),
      ),
    );
  }
}
