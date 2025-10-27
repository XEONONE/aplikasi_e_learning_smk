// lib/screens/edit_profile_screen.dart

import 'package:aplikasi_e_learning_smk/models/user_model.dart';
import 'package:aplikasi_e_learning_smk/services/auth_service.dart';
import 'package:aplikasi_e_learning_smk/widgets/custom_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Tambahkan import Firestore

class EditProfileScreen extends StatefulWidget {
  final UserModel userData;
  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nipController =
      TextEditingController(); // NIP/NISN (ID)
  bool _isSaving = false;
  final AuthService _authService = AuthService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.userData.nama;
    _nipController.text =
        widget.userData.id; // ID should be pre-filled and read-only
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nipController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate() || currentUser == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedData = {
        'nama': _nameController.text.trim(),
        // NIP/NISN tidak perlu diubah karena sudah digunakan sebagai doc ID atau field unik
      };

      // Pastikan service ini mengupdate data di Firestore
      // NOTE: Kode ini mengandalkan fungsi 'updateUserData' di AuthService
      // yang mencari dokumen user berdasarkan UID untuk diupdate.
      await _authService.updateUserData(currentUser!.uid, updatedData);

      if (mounted) {
        // Tampilkan snackbar sukses
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
        // **********************************************
        // PENTING: Kembali ke halaman sebelumnya dan kirim nilai TRUE
        Navigator.pop(context, true);
        // **********************************************
      }
    } catch (e) {
      print("Error updating profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui profil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Tentukan role untuk tampilan
    final isGuru = widget.userData.role == 'guru';
    final idLabel = isGuru ? 'NIP' : 'NISN';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Perbarui Informasi Dasar',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Nama Lengkap
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // NIP/NISN (Biasanya read-only)
              TextFormField(
                controller: _nipController,
                readOnly: true, // ID tidak boleh diubah
                decoration: InputDecoration(
                  labelText: idLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.badge_outlined),
                  filled: true,
                  fillColor: theme.brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
                ),
              ),
              const SizedBox(height: 30),
              _isSaving
                  ? const Center(child: CustomLoadingIndicator())
                  : ElevatedButton.icon(
                      onPressed: _saveProfile,
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan Perubahan'),
                      style: ElevatedButton.styleFrom(
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
  }
}
