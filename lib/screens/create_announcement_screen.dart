// lib/screens/create_announcement_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_e_learning_smk/services/auth_service.dart';

class CreateAnnouncementScreen extends StatefulWidget {
  const CreateAnnouncementScreen({super.key});

  @override
  State<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState extends State<CreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _judulController = TextEditingController();
  final _isiController = TextEditingController();
  final _authService = AuthService();

  final List<String> _daftarKelas = [];
  List<String> _selectedKelas = [];
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
      List<String> kelas = snapshot.docs
          .map((doc) => doc['namaKelas'] as String)
          .toList();
      setState(() {
        _daftarKelas.clear();
        _daftarKelas.addAll(['Semua Kelas', ...kelas]);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat daftar kelas: $e')),
        );
      }
    }
  }

  Future<void> _showMultiSelectDialog() async {
    List<String> tempSelected = List.from(_selectedKelas);

    final List<String>? results = await showDialog<List<String>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateInternal) {
            List<String> dialogSelections = List.from(tempSelected);

            return AlertDialog(
              title: const Text('Pilih Kelas Tujuan'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _daftarKelas.map((kelas) {
                    final isAll = kelas == 'Semua Kelas';
                    final isSelected = dialogSelections.contains(kelas);
                    final isAllSelected = dialogSelections.contains(
                      'Semua Kelas',
                    );

                    final bool isEnabled = !isAllSelected || isAll;

                    return CheckboxListTile(
                      enabled: isEnabled,
                      value: isSelected,
                      title: Text(
                        kelas,
                        style: TextStyle(
                          color: isEnabled
                              ? Theme.of(context).textTheme.bodyLarge?.color
                              : Colors.grey,
                        ),
                      ),
                      onChanged: !isEnabled
                          ? null
                          : (bool? newValue) {
                              setStateInternal(() {
                                if (newValue == true) {
                                  if (isAll) {
                                    dialogSelections = ['Semua Kelas'];
                                  } else {
                                    dialogSelections.remove('Semua Kelas');
                                    dialogSelections.add(kelas);
                                  }
                                } else {
                                  dialogSelections.remove(kelas);
                                }
                                dialogSelections.sort(
                                  (a, b) => a == 'Semua Kelas' ? -1 : 1,
                                );
                                tempSelected = dialogSelections;
                              });
                            },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, tempSelected),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (results != null) {
      setState(() {
        _selectedKelas = results;
      });
      _formKey.currentState?.validate();
    }
  }

  Future<void> _simpanPengumuman() async {
    if (!_formKey.currentState!.validate() || _selectedKelas.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Harap lengkapi semua field dan pilih minimal satu kelas.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final String untukKelasText = _selectedKelas.contains('Semua Kelas')
        ? 'Semua Kelas'
        : _selectedKelas.join(', ');

    try {
      await FirebaseFirestore.instance.collection('pengumuman').add({
        'judul': _judulController.text.trim(),
        'isi': _isiController.text.trim(),
        'dibuatPada': Timestamp.now(),
        'dibuatOlehUid': _authService.getCurrentUser()!.uid,
        'untukKelas': untukKelasText,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengumuman berhasil dipublikasikan!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal publikasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _isiController.dispose();
    super.dispose();
  }

  String get _selectedClassesText {
    if (_selectedKelas.isEmpty) return 'Pilih kelas...';
    if (_selectedKelas.contains('Semua Kelas')) return 'Semua Kelas';
    if (_selectedKelas.length > 3) {
      return '${_selectedKelas.take(3).join(', ')}... (+${_selectedKelas.length - 3} lainnya)';
    }
    return _selectedKelas.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    // Variabel untuk menyimpan warna teks kontras dari tema
    final Color contrastTextColor = Theme.of(context).colorScheme.onSurface;

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
                  labelText: 'Judul Pengumuman',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Judul tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _isiController,
                decoration: const InputDecoration(
                  labelText: 'Isi Pengumuman',
                  border: OutlineInputBorder(),
                ),
                maxLines: 8,
                validator: (value) =>
                    value!.isEmpty ? 'Isi tidak boleh kosong' : null,
              ),
              const SizedBox(height: 16),

              // Custom FormField untuk Multi-select
              FormField<List<String>>(
                initialValue: _selectedKelas,
                validator: (value) =>
                    value!.isEmpty ? 'Target harus dipilih' : null,
                builder: (FormFieldState<List<String>> state) {
                  return InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Tujukan ke Kelas',
                      hintText: 'Pilih kelas...',
                      border: const OutlineInputBorder(),
                      errorText: state.errorText,
                    ),
                    isEmpty: _selectedKelas.isEmpty,
                    child: InkWell(
                      onTap: () async {
                        await _showMultiSelectDialog();
                        state.didChange(_selectedKelas);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _selectedClassesText,
                                // *** PERBAIKAN VISIBILITAS EKSPLISIT ***
                                style: _selectedKelas.isEmpty
                                    ? Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.copyWith(
                                        color: Theme.of(context).hintColor,
                                      )
                                    : Theme.of(context).textTheme.bodyLarge
                                          ?.copyWith(color: contrastTextColor),
                                // ***************************************
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text('PUBLIKASIKAN'),
                      onPressed: _simpanPengumuman,
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
