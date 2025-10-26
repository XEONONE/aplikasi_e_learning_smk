// lib/screens/edit_task_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditTaskScreen extends StatefulWidget {
  final String taskId;
  final Map<String, dynamic> initialData;

  const EditTaskScreen({
    super.key,
    required this.taskId,
    required this.initialData,
  });

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _judulController;
  late TextEditingController _deskripsiController;
  late TextEditingController _linkController;

  DateTime? _tenggatWaktu;
  bool _isLoading = false;
  List<String> _daftarKelas = [];
  String? _selectedKelas;

  @override
  void initState() {
    super.initState();
    _judulController = TextEditingController(text: widget.initialData['judul']);
    _deskripsiController = TextEditingController(text: widget.initialData['deskripsi']);
    _linkController = TextEditingController(text: widget.initialData['fileUrl'] ?? '');
    _selectedKelas = widget.initialData['untukKelas'];
    _tenggatWaktu = (widget.initialData['tenggatWaktu'] as Timestamp).toDate();

    _fetchKelas();
  }

  Future<void> _fetchKelas() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('kelas').get();
      if (!mounted) return;
      List<String> kelas = snapshot.docs.map((doc) => doc['namaKelas'] as String).toList();
      setState(() {
        _daftarKelas = kelas;
      });
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _pilihTanggal() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _tenggatWaktu ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && mounted) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_tenggatWaktu ?? DateTime.now()),
      );
      if (pickedTime != null) {
        setState(() {
          _tenggatWaktu = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _updateTugas() async {
    if (_formKey.currentState!.validate() && _tenggatWaktu != null && _selectedKelas != null) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection('tugas').doc(widget.taskId).update({
          'judul': _judulController.text.trim(),
          'deskripsi': _deskripsiController.text.trim(),
          'tenggatWaktu': Timestamp.fromDate(_tenggatWaktu!),
          'untukKelas': _selectedKelas,
          'fileUrl': _linkController.text.trim().isEmpty ? null : _linkController.text.trim(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tugas berhasil diperbarui!')));
        Navigator.pop(context);

      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memperbarui tugas: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
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
      appBar: AppBar(title: const Text('Edit Tugas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _judulController,
                decoration: const InputDecoration(labelText: 'Judul Tugas', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deskripsiController,
                decoration: const InputDecoration(labelText: 'Instruksi/Deskripsi', border: OutlineInputBorder()),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedKelas,
                hint: const Text('Pilih Kelas'),
                items: _daftarKelas.map((String kelas) => DropdownMenuItem<String>(value: kelas, child: Text(kelas))).toList(),
                onChanged: (String? newValue) => setState(() => _selectedKelas = newValue),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text('Tenggat: ${DateFormat('d MMM yyyy, HH:mm').format(_tenggatWaktu!)}'),
                onPressed: _pilihTanggal,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'Link Soal Google Drive (Opsional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('UPDATE TUGAS'),
                      onPressed: _updateTugas,
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