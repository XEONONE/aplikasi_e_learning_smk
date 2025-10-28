// lib/screens/upload_materi_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_e_learning_smk/services/auth_service.dart';
import '../widgets/custom_loading_indicator.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:aplikasi_e_learning_smk/models/user_model.dart'; // Import UserModel

class UploadMateriScreen extends StatefulWidget {
  const UploadMateriScreen({super.key});

  @override
  State<UploadMateriScreen> createState() => _UploadMateriScreenState();
}

class _UploadMateriScreenState extends State<UploadMateriScreen> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _linkController = TextEditingController();
  final _authService = AuthService();
  final User? currentUser =
      FirebaseAuth.instance.currentUser; // Ambil user saat ini

  bool _isLoading = false;

  // Hapus _daftarKelas, kita akan pakai FutureBuilder untuk menampilkannya
  // List<String> _daftarKelas = [];
  String? _selectedKelas;

  List<String> _daftarMapel = [];
  String? _selectedMapel;

  // Future untuk mengambil data guru
  late Future<UserModel?> _guruFuture;

  @override
  void initState() {
    super.initState();
    // Ganti _fetchKelas() dengan inisialisasi _guruFuture
    if (currentUser != null) {
      _guruFuture = _authService.getUserData(currentUser!.uid);
    } else {
      _guruFuture = Future.value(null);
    }
    _fetchMapel();
  }

  // --- HAPUS FUNGSI _fetchKelas() LAMA ---
  /*
  Future<void> _fetchKelas() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('kelas').get();
      if (!mounted) return;
      List<String> kelas = snapshot.docs
          .map((doc) => doc['namaKelas'] as String)
          .toList();
      setState(() {
        _daftarKelas = kelas;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat daftar kelas: $e')));
    }
  }
  */

  // --- FUNGSI BARU UNTUK FETCH MAPEL (TETAP SAMA) ---
  Future<void> _fetchMapel() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('mapel').get();
      if (!mounted) return;
      List<String> mapelList = snapshot.docs
          .map((doc) => doc['namaMapel'] as String)
          .toList();
      setState(() {
        _daftarMapel = mapelList;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat daftar mapel: $e')));
    }
  }

  // --- FUNGSI BARU UNTUK MEMBUAT NOTIFIKASI (TETAP SAMA) ---
  Future<void> _createNotification(
    String judulMateri,
    String mapel,
    String kelas,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'new_materi', // Tipe notifikasi materi baru
        'title': 'Materi Baru: $judulMateri',
        'subtitle': 'Mapel: $mapel',
        'timestamp': Timestamp.now(),
        'targetAudience': [
          'kelas_$kelas',
        ], // Targetnya adalah kelas yang dipilih
        'isRead': false, // Tandai sebagai belum dibaca
      });
    } catch (e) {
      print('Gagal membuat notifikasi: $e');
    }
  }

  // --- FUNGSI UPLOAD MATERI (DIBUAT ASYNC AGAR BISA MENGGUNAKAN DATA GURU) ---
  Future<void> _uploadMateri(String guruId, String guruNama) async {
    if (_formKey.currentState!.validate() &&
        _selectedKelas != null &&
        _selectedMapel != null) {
      setState(() => _isLoading = true);

      final String judul = _judulController.text.trim();
      final String mapel = _selectedMapel!;
      final String kelas = _selectedKelas!;

      try {
        await FirebaseFirestore.instance.collection('materi').add({
          'judul': judul,
          'deskripsi': _deskripsiController.text.trim(),
          'fileUrl': _linkController.text.trim(),
          'mataPelajaran': mapel,
          'diunggahPada': Timestamp.now(),
          'diunggahOlehUid': guruId, // Gunakan ID guru
          'guruNama': guruNama, // Tambahkan nama guru
          'untukKelas': kelas,
        });

        await _createNotification(judul, mapel, kelas);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Materi berhasil diunggah!')),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengunggah: $e')));
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Harap lengkapi semua field, pilih mapel, dan pilih kelas.',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fieldColor =
        theme.inputDecorationTheme.fillColor ?? Colors.grey.shade200;

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Materi Baru')),
      // --- WRAP DENGAN FUTUREBUILDER UNTUK DATA GURU ---
      body: FutureBuilder<UserModel?>(
        future: _guruFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomLoadingIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Gagal memuat data guru.'));
          }
          if (currentUser == null) {
            return const Center(child: Text('User tidak terautentikasi.'));
          }

          final guruData = snapshot.data!;
          // Ambil daftar kelas dari data guru
          final List<String> kelasDiajar = guruData.mengajarKelas ?? [];
          final String guruId = currentUser!.uid;
          final String guruNama = guruData.nama;

          // Jika guru belum mengajar kelas apapun
          if (kelasDiajar.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  'Profil Anda belum diatur untuk mengajar di kelas mana pun. Silakan hubungi administrator.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            );
          }

          // Gunakan daftar kelas yang sudah difilter
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // DROPDOWN MATA PELAJARAN
                  DropdownButtonFormField<String>(
                    initialValue: _selectedMapel,
                    hint: const Text('Pilih Mata Pelajaran'),
                    items: _daftarMapel.map((String mapel) {
                      return DropdownMenuItem<String>(
                        value: mapel,
                        child: Text(mapel),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedMapel = newValue;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Mata pelajaran harus dipilih' : null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _judulController,
                    decoration: const InputDecoration(
                      labelText: 'Judul Materi',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Judul tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _deskripsiController,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                    validator: (value) =>
                        value!.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 16),

                  // DROPDOWN KELAS (Sudah Dibatasi Sesuai Guru)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedKelas,
                    hint: const Text('Pilih Kelas'),
                    items: kelasDiajar.map((String kelas) {
                      return DropdownMenuItem<String>(
                        value: kelas,
                        child: Text(kelas),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedKelas = newValue;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Kelas harus dipilih' : null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _linkController,
                    decoration: const InputDecoration(
                      labelText: 'Link Materi',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                    validator: (value) =>
                        value!.isEmpty ? 'Link tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CustomLoadingIndicator()
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.upload_file),
                          label: const Text('UPLOAD MATERI'),
                          // Panggil fungsi upload dengan data guru
                          onPressed: () => _uploadMateri(guruId, guruNama),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
