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
  List<String> _daftarKelas = []; // Hapus final
  List<String> _selectedKelas = [];

  @override
  void initState() {
    super.initState();
    _judulController = TextEditingController(text: widget.initialData['judul']);
    _isiController = TextEditingController(text: widget.initialData['isi']);
    final initialKelasData = widget.initialData['untukKelas'];
    if (initialKelasData is String) {
      if (initialKelasData.contains(', ')) {
        _selectedKelas = initialKelasData
            .split(', ')
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (initialKelasData.isNotEmpty) {
        _selectedKelas = [initialKelasData];
      } else {
        _selectedKelas = [];
      }
    } else if (initialKelasData is List) {
      _selectedKelas = List<String>.from(
        initialKelasData.map((e) => e.toString()),
      );
    } else {
      _selectedKelas = [];
    }
    _fetchKelas();
  }

  // Fungsi helper untuk mengurutkan nama kelas
  int _compareKelas(String a, String b) {
    if (a == 'Semua Kelas') return -1;
    if (b == 'Semua Kelas') return 1;
    RegExp regex = RegExp(r'^([XVI]+)\s*-?\s*(.*)$');
    Match? matchA = regex.firstMatch(a);
    Match? matchB = regex.firstMatch(b);
    if (matchA == null || matchB == null) return a.compareTo(b);
    String tingkatAStr = matchA.group(1)!;
    String jurusanA = matchA.group(2)!.trim();
    String tingkatBStr = matchB.group(1)!;
    String jurusanB = matchB.group(2)!.trim();
    int tingkatA = tingkatAStr == 'X' ? 10 : (tingkatAStr == 'XI' ? 11 : 12);
    int tingkatB = tingkatBStr == 'X' ? 10 : (tingkatBStr == 'XI' ? 11 : 12);
    int tingkatCompare = tingkatA.compareTo(tingkatB);
    if (tingkatCompare != 0) return tingkatCompare;
    return jurusanA.compareTo(jurusanB);
  }

  Future<void> _fetchKelas() async {
    try {
      var snapshot = await FirebaseFirestore.instance.collection('kelas').get();
      if (!mounted) return;
      List<String> kelas = snapshot.docs
          .map((doc) => doc['namaKelas'] as String)
          .toList();
      kelas.sort(_compareKelas); // Urutkan
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

  // --- MODIFIKASI: Return List<String>? ---
  Future<List<String>?> _showMultiSelectDialog() async {
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
                                dialogSelections.sort(_compareKelas);
                                tempSelected = dialogSelections;
                              });
                            },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, null), // Return null jika batal
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context, tempSelected), // Return hasil
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
    // Kembalikan hasil dialog
    return results;
  }
  // --- AKHIR MODIFIKASI ---

  Future<void> _updateAnnouncement() async {
    if (_formKey.currentState!.validate() && _selectedKelas.isNotEmpty) {
      setState(() => _isLoading = true);

      try {
        await FirebaseFirestore.instance
            .collection('pengumuman')
            .doc(widget.announcementId)
            .update({
              'judul': _judulController.text.trim(),
              'isi': _isiController.text.trim(),
              'untukKelas': _selectedKelas, // Simpan sebagai List<String>
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
    }
    // Tidak perlu else lagi karena validator sudah menangani
  }

  @override
  void dispose() {
    _judulController.dispose();
    _isiController.dispose();
    super.dispose();
  }

  String get _selectedClassesText {
    if (_selectedKelas.isEmpty) return 'Pilih kelas...';
    final sortedKelas = List<String>.from(_selectedKelas)..sort(_compareKelas);
    if (sortedKelas.contains('Semua Kelas')) return 'Semua Kelas';
    if (sortedKelas.length > 3) {
      return '${sortedKelas.take(3).join(', ')}... (+${sortedKelas.length - 3} lainnya)';
    }
    return sortedKelas.join(', ');
  }

  @override
  Widget build(BuildContext context) {
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
              FormField<List<String>>(
                initialValue: _selectedKelas,
                validator: (value) => value == null || value.isEmpty
                    ? 'Target harus dipilih'
                    : null, // Validator tetap
                builder: (FormFieldState<List<String>> state) {
                  return InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Pilih Kelas Tujuan',
                      hintText: 'Pilih kelas...',
                      border: const OutlineInputBorder(),
                      errorText: state.errorText,
                    ),
                    isEmpty: _selectedKelas.isEmpty,
                    child: InkWell(
                      // ================== PERUBAHAN LOGIKA onTap ==================
                      onTap: () async {
                        final List<String>? results =
                            await _showMultiSelectDialog();
                        if (results != null) {
                          setState(() {
                            _selectedKelas = results;
                          });
                          state.didChange(_selectedKelas);
                        }
                      },
                      // ================== AKHIR PERUBAHAN ==================
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
