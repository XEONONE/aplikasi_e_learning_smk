import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditMateriScreen extends StatefulWidget {
  final String materiId;
  final Map<String, dynamic> initialData;

  const EditMateriScreen({
    super.key,
    required this.materiId,
    required this.initialData,
  });

  @override
  State<EditMateriScreen> createState() => _EditMateriScreenState();
}

class _EditMateriScreenState extends State<EditMateriScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _judulController;
  late TextEditingController _deskripsiController;
  late TextEditingController _linkController;

  bool _isLoading = false;
  List<String> _daftarKelas = [];
  String? _selectedKelas;

  @override
  void initState() {
    super.initState();
    // Isi controller dengan data yang ada
    _judulController = TextEditingController(text: widget.initialData['judul']);
    _deskripsiController = TextEditingController(
      text: widget.initialData['deskripsi'],
    );
    _linkController = TextEditingController(
      text: widget.initialData['fileUrl'],
    );
    _selectedKelas = widget.initialData['untukKelas'];

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

  Future<void> _updateMateri() async {
    if (_formKey.currentState!.validate() && _selectedKelas != null) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance
            .collection('materi')
            .doc(widget.materiId)
            .update({
              'judul': _judulController.text.trim(),
              'deskripsi': _deskripsiController.text.trim(),
              'fileUrl': _linkController.text.trim(),
              'untukKelas': _selectedKelas,
            });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Materi berhasil diperbarui!')),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memperbarui: $e')));
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Materi')),
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
                initialValue: _selectedKelas, // Tampilkan kelas yang sudah dipilih
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
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('UPDATE MATERI'),
                      onPressed: _updateMateri,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade700,
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
