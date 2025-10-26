// lib/screens/student_materi_list_screen.dart

import 'package:aplikasi_e_learning_smk/models/user_model.dart'; //
import 'package:aplikasi_e_learning_smk/services/auth_service.dart'; //
import 'package:aplikasi_e_learning_smk/widgets/materi_card.dart'; // <<-- Ganti ke MateriCard
import 'package:aplikasi_e_learning_smk/widgets/custom_loading_indicator.dart'; //
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal

class StudentMateriListScreen extends StatefulWidget {
  const StudentMateriListScreen({super.key});

  @override
  State<StudentMateriListScreen> createState() =>
      _StudentMateriListScreenState();
}

class _StudentMateriListScreenState extends State<StudentMateriListScreen> {
  late Future<UserModel?> _userFuture; //
  final AuthService _authService = AuthService(); //
  final User? currentUser = FirebaseAuth.instance.currentUser;
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

  // Hapus _buildModuleItem, kita akan pakai MateriCard langsung

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return const Center(child: Text('Silakan login ulang.'));
    }
    final theme = Theme.of(context); // Ambil tema

    return Scaffold(
      // <<-- Tambahkan Scaffold di sini
      appBar: AppBar(
        // <<-- Tambahkan AppBar
        title: const Text('Materi Pelajaran'),
        backgroundColor: Colors.transparent, // Transparan agar menyatu
        elevation: 0,
      ),
      body: FutureBuilder<UserModel?>(
        //
        future: _userFuture,
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomLoadingIndicator()); //
          }
          if (!userSnapshot.hasData || userSnapshot.data == null) {
            return const Center(child: Text('Gagal memuat data siswa.'));
          }

          final userKelas = userSnapshot.data!.kelas;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('materi')
                .where('untukKelas', isEqualTo: userKelas)
                .orderBy('mataPelajaran')
                .orderBy('diunggahPada', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CustomLoadingIndicator()); //
              }
              if (snapshot.hasError) {
                print('Error loading materi: ${snapshot.error}');
                return const Center(
                  child: Text('Terjadi error saat memuat data.'),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'Belum ada materi untuk kelas $userKelas.',
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }

              var groupedMateri = <String, List<QueryDocumentSnapshot>>{};
              for (var doc in snapshot.data!.docs) {
                var data = doc.data() as Map<String, dynamic>;
                String mapel = data['mataPelajaran'] ?? 'Lainnya';
                groupedMateri.putIfAbsent(mapel, () => []).add(doc);
              }
              List<String> mapelKeys = groupedMateri.keys.toList();

              for (var key in mapelKeys) {
                _expansionState.putIfAbsent(key, () => true); // Default terbuka
              }

              return ListView.builder(
                padding: const EdgeInsets.only(
                  top: 8.0,
                  bottom: 16.0,
                ), // Padding atas bawah
                itemCount: mapelKeys.length,
                itemBuilder: (context, index) {
                  final mapel = mapelKeys[index];
                  final materis = groupedMateri[mapel]!;

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      vertical: 6.0,
                      horizontal: 16.0,
                    ),
                    elevation: 0.5, // Sedikit shadow
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
                      // Icon panah (otomatis pakai warna tema ikon)
                      trailing: Icon(
                        _expansionState[mapel] ?? true
                            ? Icons.expand_less
                            : Icons.expand_more,
                      ),
                      // Warna background diambil dari tema
                      backgroundColor: theme.cardColor.withOpacity(0.3),
                      collapsedBackgroundColor: Colors.transparent,
                      shape: const Border(),
                      collapsedShape: const Border(),
                      childrenPadding: const EdgeInsets.only(
                        bottom: 8.0,
                        left: 0.0,
                        right: 0.0,
                      ), // <<-- Hapus padding kiri kanan
                      // Gunakan MateriCard di sini
                      children: materis.map((materiDoc) {
                        var data = materiDoc.data() as Map<String, dynamic>;
                        // Format tanggal
                        DateTime uploadDate =
                            (data['diunggahPada'] as Timestamp? ??
                                    Timestamp.now())
                                .toDate();
                        String formattedDate = DateFormat(
                          'd MMM yyyy',
                          'id_ID',
                        ).format(uploadDate);

                        return MateriCard(
                          // <<-- Panggil MateriCard
                          judul: data['judul'] ?? 'Tanpa Judul',
                          deskripsi: data['deskripsi'] ?? 'Tanpa Deskripsi',
                          fileUrl: data['fileUrl'] as String?,
                          guruNama:
                              data['guruNama'] ?? 'Guru', // Ambil nama guru
                          tanggalUpload: formattedDate, // Kirim tanggal format
                          isGuruView: false, // Siswa view
                        );
                      }).toList(),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    ); // <<-- Tutup Scaffold
  }
}
