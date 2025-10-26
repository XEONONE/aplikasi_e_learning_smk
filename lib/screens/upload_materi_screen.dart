// lib/screens/upload_materi_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_e_learning_smk/services/auth_service.dart';
import '../widgets/custom_loading_indicator.dart';

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
  final _mapelController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;

  List<String> _daftarKelas = [];
  String? _selectedKelas;

  @override
  void initState() {
    super.initState();
    _fetchKelas();
  }

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

  // --- FUNGSI BARU UNTUK MEMBUAT NOTIFIKASI ---
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
        // --- TAMBAHAN BARU ---
        'isRead': false, // Tandai sebagai belum dibaca
        // --- AKHIR TAMBAHAN BARU ---
      });
    } catch (e) {
      print('Gagal membuat notifikasi: $e');
      // Tidak perlu menampilkan error ke user, biarkan proses upload utama berjalan
    }
  }
  // --- AKHIR FUNGSI BARU ---

  Future<void> _uploadMateri() async {
    if (_formKey.currentState!.validate() && _selectedKelas != null) {
      setState(() => _isLoading = true);

      // Mengambil data sebelum proses async
      final String judul = _judulController.text.trim();
      final String mapel = _mapelController.text.trim();
      final String kelas = _selectedKelas!;

      try {
        await FirebaseFirestore.instance.collection('materi').add({
          'judul': judul,
          'deskripsi': _deskripsiController.text.trim(),
          'fileUrl': _linkController.text.trim(),
          'mataPelajaran': mapel,
          'diunggahPada': Timestamp.now(),
          'diunggahOlehUid': _authService.getCurrentUser()!.uid,
          'untukKelas': kelas,
        });

        // --- PANGGIL FUNGSI NOTIFIKASI SETELAH SUKSES ---
        await _createNotification(judul, mapel, kelas);
        // --- AKHIR PANGGILAN FUNGSI ---

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
          content: Text('Harap lengkapi semua field dan pilih kelas.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _linkController.dispose();
    _mapelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upload Materi Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _mapelController,
                decoration: const InputDecoration(
                  labelText: 'Mata Pelajaran (Contoh: Informatika)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Mata pelajaran tidak boleh kosong' : null,
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
              DropdownButtonFormField<String>(
                initialValue: _selectedKelas,
                hint: const Text('Pilih Kelas'),
                items: _daftarKelas.map((String kelas) {
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
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Link Google Drive Materi',
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
                      onPressed: _uploadMateri,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
