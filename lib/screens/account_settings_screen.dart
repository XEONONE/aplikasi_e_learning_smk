// lib/screens/account_settings_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_e_learning_smk/main.dart'; // Impor MyAppState

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _emailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  bool _notificationsEnabled = true;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final User? _currentUser = FirebaseAuth.instance.currentUser;
  int _selectedThemeIndex =
      1; // 0: Terang, 1: Gelap (sesuai default di main.dart)

  @override
  void initState() {
    super.initState();
    _emailController.text = _currentUser?.email ?? 'Email tidak ditemukan';

    // Ambil state tema saat ini setelah frame pertama selesai build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final myAppState = context.findAncestorStateOfType<MyAppState>();
        setState(() {
          _selectedThemeIndex = myAppState?.currentThemeMode == ThemeMode.dark
              ? 1
              : 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  // Fungsi ini HANYA menyimpan password dan notifikasi
  Future<void> _saveSettings() async {
    final newPassword = _newPasswordController.text.trim();
    if (newPassword.isNotEmpty && newPassword.length < 6) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password baru minimal harus 6 karakter.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Update password jika diisi
      if (newPassword.isNotEmpty && _currentUser != null) {
        await _currentUser.updatePassword(newPassword);
        _newPasswordController.clear();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // 2. Simpan status notifikasi
      // TODO: Implementasi simpan status notifikasi

      // 3. Simpan PREFERENSI TEMA
      // (Tidak perlu lagi di sini, sudah disimpan langsung saat tombol ditekan)
      // TODO: Simpan _selectedThemeIndex ke SharedPreferences di sini <-- DIHAPUS

      if (newPassword.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan berhasil disimpan!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Gagal memperbarui password.';
      if (e.code == 'requires-recent-login') {
        errorMessage =
            'Sesi login Anda sudah terlalu lama. Silakan logout dan login kembali untuk mengubah password.';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password terlalu lemah.';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan pengaturan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Ambil warna dari ColorScheme yang sudah didefinisikan di main.dart
    final fieldColor =
        theme.inputDecorationTheme.fillColor ?? Colors.grey.shade200;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.black87;
    final hintColor =
        theme.inputDecorationTheme.hintStyle?.color ?? Colors.grey.shade500;
    final iconColor = theme.iconTheme.color ?? Colors.grey.shade700;

    return Scaffold(
      appBar: AppBar(
        // Tombol back akan muncul otomatis jika halaman dibuka via push
        // leading: IconButton( ... ), // Tidak perlu jika dibuka via push
        title: const Text('Pengaturan'),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: theme.appBarTheme.foregroundColor?.withOpacity(0.7),
            ),
            onPressed: () {},
          ),
        ],
        // Style AppBar diambil dari tema
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- Field Email (Read Only) ---
            TextField(
              controller: _emailController,
              readOnly: true,
              style: TextStyle(
                color: textColor.withOpacity(0.7),
              ), // Sedikit pudar
              decoration: InputDecoration(
                labelText: 'Email',
                // Style lain diambil dari inputDecorationTheme
              ),
            ),
            const SizedBox(height: 16),

            // --- Field Ganti Password ---
            TextField(
              controller: _newPasswordController,
              obscureText: !_isPasswordVisible,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: 'Ganti Password',
                hintText: 'Masukkan password baru',
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                // Style lain diambil dari inputDecorationTheme
              ),
            ),
            const SizedBox(height: 24),

            // --- Toggle Notifikasi Push ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: fieldColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_active_outlined,
                        color: iconColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Notifikasi Push',
                        style: TextStyle(color: textColor, fontSize: 16),
                      ),
                    ],
                  ),
                  Switch(
                    value: _notificationsEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                    // Warna switch diambil dari tema
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- PILIHAN TEMA TAMPILAN ---
            Text(
              'Tema Tampilan',
              style: TextStyle(color: hintColor, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: fieldColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ToggleButtons(
                isSelected: [
                  _selectedThemeIndex == 0, // Terang
                  _selectedThemeIndex == 1, // Gelap
                ],
                onPressed: (index) {
                  // 1. Update UI lokal
                  setState(() {
                    _selectedThemeIndex = index;
                  });

                  // 2. Panggil MyAppState untuk mengubah tema
                  final myAppState = context
                      .findAncestorStateOfType<MyAppState>();
                  final newThemeMode = index == 1
                      ? ThemeMode.dark
                      : ThemeMode.light;

                  // 3. changeTheme sekarang juga akan *menyimpan* preferensi
                  myAppState?.changeTheme(newThemeMode);
                },
                // Ambil style dari toggleButtonsTheme
                borderRadius: theme.toggleButtonsTheme.borderRadius,
                selectedBorderColor:
                    theme.toggleButtonsTheme.selectedBorderColor,
                selectedColor: theme.toggleButtonsTheme.selectedColor,
                fillColor: theme.toggleButtonsTheme.fillColor,
                color: theme.toggleButtonsTheme.color,
                borderColor: theme.toggleButtonsTheme.borderColor,
                textStyle: theme.toggleButtonsTheme.textStyle,
                constraints: const BoxConstraints(
                  minHeight: 40.0,
                  minWidth: 100.0,
                ), // Beri minWidth
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.wb_sunny_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Terang'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.nightlight_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Gelap'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // --- Tombol Simpan ---
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _saveSettings,
                    // Style diambil dari elevatedButtonTheme
                    child: const Text('Simpan Pengaturan'),
                  ),
          ],
        ),
      ),
    );
  }
}
