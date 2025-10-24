import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_e_learning_smk/services/auth_service.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() => _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _isiController = TextEditingController();
  final _authService = AuthService();

  final List<String> _daftarKelas = ['Semua Kelas']; // Opsi default
  String? _selectedKelas;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchKelas();
  }

  Future<void> _fetchKelas() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('kelas').get();
      if (!mounted) return;
      List<String> kelas = snapshot.docs.map((doc) => doc['namaKelas'] as String).toList();
      setState(() {
        _daftarKelas.addAll(kelas); // Tambahkan kelas dari DB ke daftar
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _simpanPengumuman() async {
    if (_formKey.currentState!.validate() && _selectedKelas != null) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection('pengumuman').add({
          'judul': _judulController.text.trim(),
          'isi': _isiController.text.trim(),
          'dibuatPada': Timestamp.now(),
          'dibuatOlehUid': _authService.getCurrentUser()!.uid,
          'untukKelas': _selectedKelas,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pengumuman berhasil dipublikasikan!')));
        Navigator.pop(context);

      } catch (e) {
        // Handle error
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else {
      // Handle error validasi
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Pengumuman Baru')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _judulController,
                decoration: const InputDecoration(
                    labelText: 'Judul Pengumuman', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Judul tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _isiController,
                decoration: const InputDecoration(
                    labelText: 'Isi Pengumuman', border: OutlineInputBorder()),
                maxLines: 8,
                validator: (value) => value!.isEmpty ? 'Isi tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedKelas,
                hint: const Text('Tujukan ke...'),
                items: _daftarKelas.map((String kelas) {
                  return DropdownMenuItem<String>(value: kelas, child: Text(kelas));
                }).toList(),
                onChanged: (String? newValue) => setState(() => _selectedKelas = newValue),
                validator: (value) => value == null ? 'Target harus dipilih' : null,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text('PUBLIKASIKAN'),
                      onPressed: _simpanPengumuman,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}