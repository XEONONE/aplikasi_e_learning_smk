// lib/screens/edit_announcement_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditAnnouncementScreen extends StatefulWidget {
  final String announcementId;
  final Map<String, dynamic> initialData;

  const EditAnnouncementScreen({
    super.key,
    required this.announcementId,
    required this.initialData,
  });

  @override
  State<EditAnnouncementScreen> createState() => _EditAnnouncementScreenState();
}

class _EditAnnouncementScreenState extends State<EditAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _judulController;
  late TextEditingController _isiController;

  bool _isLoading = false;
  List<String> _daftarKelas = [];

  List<String> _selectedKelas = [];

  @override
  void initState() {
    super.initState();
    _judulController = TextEditingController(text: widget.initialData['judul']);
    _isiController = TextEditingController(text: widget.initialData['isi']);

    // Inisialisasi _selectedKelas dari String Firestore
    final initialKelasString =
        widget.initialData['untukKelas'] as String? ?? '';
    _selectedKelas = initialKelasString
        .split(', ')
        .where((e) => e.isNotEmpty)
        .toList();

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
        _daftarKelas = ['Semua Kelas', ...kelas];
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal memuat daftar kelas: $e')));
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

  Future<void> _updateAnnouncement() async {
    if (_formKey.currentState!.validate() && _selectedKelas.isNotEmpty) {
      setState(() => _isLoading = true);

      final String untukKelasText = _selectedKelas.contains('Semua Kelas')
          ? 'Semua Kelas'
          : _selectedKelas.join(', ');

      try {
        await FirebaseFirestore.instance
            .collection('pengumuman')
            .doc(widget.announcementId)
            .update({
              'judul': _judulController.text.trim(),
              'isi': _isiController.text.trim(),
              'untukKelas': untukKelasText,
            });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengumuman berhasil diperbarui!')),
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
    }
  }

  @override
  void dispose() {
    _judulController.dispose();
    _isiController.dispose();
    super.dispose();
  }

  // Helper untuk menampilkan teks kelas yang dipilih
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
    // Variable untuk mengatasi masalah visibilitas teks (PERBAIKAN VISIBILITAS)
    final Color contrastTextColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Pengumuman')),
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

              // Custom FormField untuk Multi-select (PERBAIKAN FUNGSI)
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
                                style: _selectedKelas.isEmpty
                                    ? Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.copyWith(
                                        color: Theme.of(context).hintColor,
                                      )
                                    // Menerapkan warna teks kontras yang pasti terlihat
                                    : Theme.of(context).textTheme.bodyLarge
                                          ?.copyWith(color: contrastTextColor),
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
                      icon: const Icon(Icons.save),
                      label: const Text('UPDATE PENGUMUMAN'),
                      onPressed: _updateAnnouncement,
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
