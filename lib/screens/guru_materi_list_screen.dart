// lib/screens/guru_materi_list_screen.dart

import 'package:aplikasi_e_learning_smk/models/user_model.dart';
import 'package:aplikasi_e_learning_smk/screens/edit_materi_screen.dart';
import 'package:aplikasi_e_learning_smk/services/auth_service.dart';
import 'package:aplikasi_e_learning_smk/widgets/custom_loading_indicator.dart';
import 'package:aplikasi_e_learning_smk/widgets/materi_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GuruMateriListScreen extends StatefulWidget {
  const GuruMateriListScreen({super.key});

  @override
  State<GuruMateriListScreen> createState() => _GuruMateriListScreenState();
}

class _GuruMateriListScreenState extends State<GuruMateriListScreen> {
  final AuthService _authService = AuthService();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late Future<UserModel?> _userFuture;
  final Map<String, bool> _expansionState = {};

  @override
  void initState() {
    super.initState();
    if (currentUser != null) {
      _userFuture = _authService.getUserData(currentUser!.uid);
    } else {
      _userFuture = Future.value(null);
    }
  }

  Future<void> _hapusMateri(String materiId, String judul) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus materi "$judul"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Hapus',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await FirebaseFirestore.instance
            .collection('materi')
            .doc(materiId)
            .delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Materi "$judul" berhasil dihapus.'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // TODO: Hapus juga file terkait di Firebase Storage jika ada
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus materi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Ambil tema
    if (currentUser == null) {
      return const Center(child: Text('Silakan login ulang.'));
    }

    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CustomLoadingIndicator());
        }
        if (!userSnapshot.hasData || userSnapshot.data == null) {
          return const Center(child: Text('Gagal memuat data guru.'));
        }

        final guru = userSnapshot.data!;
        // *** INI ADALAH BAGIAN YANG DIPERBAIKI ***
        // Kita mengambil UID guru yang sedang login
        final String guruUid = currentUser!.uid;

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('materi')
              .where(
                'diunggahOlehUid',
                isEqualTo: guruUid,
              ) // <-- Persis 'diunggahOlehUid'
              .orderBy('mataPelajaran') // <-- Persis 'mataPelajaran'
              .orderBy(
                'diunggahPada',
                descending: false,
              ) // <-- Persis 'diunggahPada'
              .snapshots(),
          builder: (context, snapshot) {
            // Bagian ini akan menampilkan error jika indeks bermasalah
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CustomLoadingIndicator());
            }
            // *** BAGIAN INI YANG MENYEBABKAN ERROR TAMPIL DI LAYAR ***
            if (snapshot.hasError) {
              // Kode ini akan mencetak error detail ke konsol debug Anda
              print('Firestore Error: ${snapshot.error}');
              return Center(
                child: Text(
                  'Terjadi error saat memuat data materi.\nError: ${snapshot.error}',
                ), // Ini yang tampil di screenshot
              );
            }
            // Bagian ini akan tampil jika query berhasil tapi tidak ada data
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Text(
                  'Anda belum mengunggah materi.',
                  style: theme.textTheme.bodyMedium,
                ),
              );
            }

            // --- Jika kode sampai di sini, berarti data berhasil diambil ---
            var groupedMateri = <String, List<QueryDocumentSnapshot>>{};
            for (var doc in snapshot.data!.docs) {
              var data = doc.data() as Map<String, dynamic>;
              String mapel = data['mataPelajaran'] ?? 'Lainnya';
              groupedMateri.putIfAbsent(mapel, () => []).add(doc);
            }
            List<String> mapelKeys = groupedMateri.keys.toList();

            for (var key in mapelKeys) {
              _expansionState.putIfAbsent(key, () => true);
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8.0, bottom: 80.0),
              itemCount: mapelKeys.length,
              itemBuilder: (context, index) {
                final mapel = mapelKeys[index];
                final materis = groupedMateri[mapel]!;

                return Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 6.0,
                    horizontal: 16.0,
                  ),
                  elevation: 0.5,

                  child: ExpansionTile(
                    key: PageStorageKey(mapel),
                    title: Text(
                      mapel,

                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    initiallyExpanded: _expansionState[mapel] ?? true,
                    onExpansionChanged: (isExpanded) {
                      setState(() {
                        _expansionState[mapel] = isExpanded;
                      });
                    },

                    trailing: Icon(
                      _expansionState[mapel] ?? true
                          ? Icons.expand_less
                          : Icons.expand_more,
                    ),

                    backgroundColor: theme.cardColor.withAlpha(77),
                    collapsedBackgroundColor: Colors.transparent,
                    shape: const Border(),
                    collapsedShape: const Border(),
                    childrenPadding: const EdgeInsets.only(
                      bottom: 8.0,
                      left: 0.0,
                      right: 0.0,
                    ),

                    children: materis.map((materiDoc) {
                      var data = materiDoc.data() as Map<String, dynamic>;

                      DateTime uploadDate =
                          (data['diunggahPada'] as Timestamp? ??
                                  Timestamp.now())
                              .toDate();
                      String formattedDate = DateFormat(
                        'd MMM yyyy',
                        'id_ID',
                      ).format(uploadDate);

                      return MateriCard(
                        judul: data['judul'] ?? 'Tanpa Judul',
                        deskripsi: data['deskripsi'] ?? 'Tanpa Deskripsi',
                        fileUrl: data['fileUrl'] as String?,
                        guruNama: data['guruNama'] ?? guru.nama,
                        tanggalUpload: formattedDate,
                        isGuruView: true,
                        onEdit: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditMateriScreen(
                                materiId: materiDoc.id,
                                initialData: data,
                              ),
                            ),
                          );
                        },
                        onDelete: () => _hapusMateri(
                          materiDoc.id,
                          data['judul'] ?? 'Tanpa Judul',
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
