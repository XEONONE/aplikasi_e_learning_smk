// lib/screens/create_task_screen.dart
import 'package:aplikasi_e_learning_smk/models/user_model.dart';
import 'package:aplikasi_e_learning_smk/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_loading_indicator.dart'; // Impor loading indicator

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _mapelController = TextEditingController();
  final _linkController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  String? _selectedKelas;
  late Future<UserModel?> _guruFuture;
  final AuthService _authService = AuthService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      _guruFuture = _authService.getUserData(currentUser!.uid);
    } else {
      _guruFuture = Future.value(null);
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _deskripsiController.dispose();
    _mapelController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (pickedDate != null) {
      if (!context.mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedTime ?? TimeOfDay.now(),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDate = pickedDate;
          _selectedTime = pickedTime;
        });
      }
    }
  }

  Future<void> _createNotification(
    String judulTugas,
    String mapel,
    String kelas,
    DateTime tenggatWaktu,
  ) async {
    try {
      final String formattedTenggat = DateFormat(
        'd MMM, HH:mm',
        'id_ID',
      ).format(tenggatWaktu);

      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'new_task',
        'title': 'Tugas Baru: $judulTugas',
        'subtitle': 'Mapel: $mapel - Tenggat: $formattedTenggat',
        'timestamp': Timestamp.now(),
        'targetAudience': ['kelas_$kelas'],
        'isRead': false,
      });
    } catch (e) {
      print('Gagal membuat notifikasi: $e');
    }
  }

  Future<void> _submitTugas(String guruId, String guruNama) async {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedTime != null &&
        _selectedKelas != null) {
      setState(() => _isLoading = true);

      final String judul = _judulController.text.trim();
      final String mapel = _mapelController.text.trim();
      final String kelas = _selectedKelas!;
      final DateTime tenggatWaktu = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      try {
        String? lampiranUrl = _linkController.text.trim();
        if (lampiranUrl.isEmpty) {
          lampiranUrl = null;
        }

        await FirebaseFirestore.instance.collection('tugas').add({
          'judul': judul,
          'deskripsi': _deskripsiController.text,
          'mataPelajaran': mapel,
          'tenggatWaktu': Timestamp.fromDate(tenggatWaktu),
          'lampiranUrl': lampiranUrl,
          'dibuatPada': Timestamp.now(),
          'untukKelas': kelas,
          'guruId': guruId,
          'guruNama': guruNama,
        });

        await _createNotification(judul, mapel, kelas, tenggatWaktu);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tugas berhasil ditambahkan!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan tugas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else if (_selectedDate == null || _selectedTime == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih tenggat waktu.'),
          backgroundColor: Colors.orange,
        ),
      );
    } else if (_selectedKelas == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih kelas.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // === PERBAIKAN: Ambil warna dari tema ===
    final theme = Theme.of(context);
    // Kita gunakan `inputDecorationTheme` untuk konsistensi
    final inputDecorationTheme = theme.inputDecorationTheme;
    // Ambil warna border jika ada, jika tidak, default ke hitam
    final borderColor = inputDecorationTheme.border is OutlineInputBorder
        ? (inputDecorationTheme.border as OutlineInputBorder).borderSide.color
        : Colors.black;
    // === AKHIR PERBAIKAN ===

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Tugas Baru')),
      body: FutureBuilder<UserModel?>(
        future: _guruFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CustomLoadingIndicator(),
            ); // Gunakan loading custom
          }
          if (!snapshot.hasData ||
              snapshot.data == null ||
              currentUser == null) {
            return const Center(child: Text('Gagal memuat data guru.'));
          }
          final guruData = snapshot.data!;
          final List<String> kelasDiajar = guruData.mengajarKelas ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _judulController,
                    decoration: InputDecoration(
                      labelText: 'Judul Tugas',
                      // === PERBAIKAN: Tambahkan OutlineInputBorder ===
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                      // ===========================================
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Judul tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _mapelController,
                    decoration: InputDecoration(
                      labelText: 'Mata Pelajaran',
                      // === PERBAIKAN: Tambahkan OutlineInputBorder ===
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                      // ===========================================
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Mata pelajaran tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _deskripsiController,
                    decoration: InputDecoration(
                      labelText: 'Deskripsi',
                      hintText: 'Jelaskan detail tugas di sini...',
                      // === PERBAIKAN: Tambahkan OutlineInputBorder ===
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                      // ===========================================
                    ),
                    maxLines: 4,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Deskripsi tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedKelas, // Gunakan value, bukan initialValue
                    decoration: InputDecoration(
                      labelText: 'Untuk Kelas',
                      // === PERBAIKAN: Tambahkan OutlineInputBorder ===
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                      // ===========================================
                    ),
                    items: kelasDiajar
                        .map(
                          (String kelas) => DropdownMenuItem<String>(
                            value: kelas,
                            child: Text(kelas),
                          ),
                        )
                        .toList(),
                    onChanged: (String? newValue) =>
                        setState(() => _selectedKelas = newValue),
                    validator: (value) => value == null ? 'Pilih kelas' : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                    ), // Beri padding
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      _selectedDate == null || _selectedTime == null
                          ? 'Pilih Tenggat Waktu'
                          : 'Tenggat: ${DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, _selectedTime!.hour, _selectedTime!.minute))}',
                    ),
                    trailing: const Icon(Icons.edit_outlined), // Ganti ikon
                    onTap: () => _selectDateTime(context),
                    shape: OutlineInputBorder(
                      // Gunakan OutlineInputBorder
                      borderRadius: BorderRadius.circular(
                        4,
                      ), // Sesuaikan radius
                      borderSide: BorderSide(
                        color: borderColor,
                      ), // Gunakan warna border
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _linkController,
                    decoration: InputDecoration(
                      labelText: 'Salin link web (Opsional)',
                      hintText: 'https://...',
                      // === PERBAIKAN: Tambahkan OutlineInputBorder ===
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                      // ===========================================
                      prefixIcon: const Icon(Icons.link),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 32),
                  _isLoading
                      ? const Center(
                          child: CustomLoadingIndicator(),
                        ) // Gunakan loading custom
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.publish),
                          label: const Text('Terbitkan Tugas'),
                          onPressed: () =>
                              _submitTugas(currentUser!.uid, guruData.nama),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
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
