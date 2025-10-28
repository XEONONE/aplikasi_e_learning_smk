// lib/screens/guru_home_screen.dart

import 'package:aplikasi_e_learning_smk/models/user_model.dart';
import 'package:aplikasi_e_learning_smk/screens/create_announcement_screen.dart';
import 'package:aplikasi_e_learning_smk/screens/edit_announcement_screen.dart';
import 'package:aplikasi_e_learning_smk/services/auth_service.dart';
import 'package:aplikasi_e_learning_smk/widgets/announcement_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GuruHomeScreen extends StatefulWidget {
  const GuruHomeScreen({super.key});

  @override
  // Perhatikan: State harus me-return _GuruHomeScreenState
  State<GuruHomeScreen> createState() => _GuruHomeScreenState();
}

class _GuruHomeScreenState extends State<GuruHomeScreen> {
  final AuthService _authService = AuthService();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  late Future<UserModel?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchUserData();
  }

  // Fungsi untuk memuat data guru
  Future<UserModel?> _fetchUserData() async {
    if (currentUser != null) {
      // Panggil service untuk mendapatkan data terbaru
      return _authService.getUserData(currentUser!.uid);
    }
    return null;
  }

  // ===== FUNGSI KRUSIAL: Dipanggil dari Dashboard =====
  void refreshUserData() {
    // Memaksa FutureBuilder untuk me-re-fetch data
    if (mounted) {
      // PENTING: Hanya panggil setState jika widget masih ada
      setState(() {
        _userFuture = _fetchUserData(); // Memuat ulang Future
      });
    }
  }
  // ===== AKHIR FUNGSI KRUSIAL =====

  // --- FUNGSI HAPUS PENGUMUMAN (Dibiarkan tetap) ---
  Future<void> _hapusPengumuman(String docId, String judul) async {
    // ... (kode implementasi hapus pengumuman) ...
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text(
            'Apakah Anda yakin ingin menghapus pengumuman "$judul"?',
          ),
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
            .collection('pengumuman')
            .doc(docId)
            .delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pengumuman "$judul" berhasil dihapus.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus pengumuman: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildSummaryCard(
    IconData icon,
    String label,
    Stream<QuerySnapshot> stream,
    Color iconColor,
  ) {
    final theme = Theme.of(context);
    final subtitleColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.7);

    return Expanded(
      child: Card(
        color: theme.cardColor,
        elevation: 2.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(color: subtitleColor, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: stream,
                      builder: (context, snapshot) {
                        final count = snapshot.data?.docs.length ?? 0;
                        return Text(
                          count.toString(),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.7);

    return Scaffold(
      body: FutureBuilder<UserModel?>(
        future: _userFuture, // PENTING: menggunakan Future ini
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting &&
              _userFuture != null) {
            // Tampilkan loading hanya jika ini bukan hasil dari refresh cepat
            return const Center(child: CircularProgressIndicator());
          }
          if (!userSnapshot.hasData || userSnapshot.data == null) {
            return const Center(child: Text('Gagal memuat data guru.'));
          }

          final user = userSnapshot.data!;
          final initial = user.nama.isNotEmpty
              ? user.nama[0].toUpperCase()
              : '?';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // -- BAGIAN HEADER (Nama ada di sini) --
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.brightness == Brightness.dark
                          ? Colors.grey[700]
                          : theme.colorScheme.primary.withOpacity(0.1),
                      child: Text(
                        initial,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark
                              ? Colors.white
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat datang,',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: subtitleColor,
                          ),
                        ),
                        // NAMA GURU
                        Text(
                          user.nama,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Card sapaan yang lebih besar (Nama juga ada di sini)
                Card(
                  color: theme.cardColor,
                  elevation: 2.0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          // NAMA GURU
                          'Selamat Datang. ${user.nama.split(' ').first}!',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (user.mengajarKelas != null &&
                            user.mengajarKelas!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Mengajar: ${user.mengajarKelas!.join(', ')}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // -- BAGIAN RINGKASAN & PENGUMUMAN (Dibiarkan tetap) --
                Row(
                  children: [
                    _buildSummaryCard(
                      Icons.library_books,
                      'Total Materi',
                      FirebaseFirestore.instance
                          .collection('materi')
                          .where('diunggahOlehUid', isEqualTo: currentUser!.uid)
                          .snapshots(),
                      Colors.green.shade400,
                    ),
                    const SizedBox(width: 16),
                    _buildSummaryCard(
                      Icons.edit_note,
                      'Total Tugas',
                      FirebaseFirestore.instance
                          .collection('tugas')
                          .where('guruId', isEqualTo: currentUser!.uid)
                          .snapshots(),
                      Colors.orange.shade400,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Text(
                  'Pengumuman Terkini',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('pengumuman')
                      .where(
                        'untukKelas',
                        whereIn: [...?user.mengajarKelas, 'Semua Kelas'],
                      )
                      .orderBy('dibuatPada', descending: true)
                      .limit(5)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          'Belum ada pengumuman.',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.7),
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      print("Error loading announcements: ${snapshot.error}");
                      return const Center(
                        child: Text(
                          'Gagal memuat pengumuman.',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        return AnnouncementCard(
                          judul: data['judul'] ?? 'Tanpa Judul',
                          isi: data['isi'] ?? 'Tidak ada isi.',
                          dibuatPada: data['dibuatPada'] ?? Timestamp.now(),
                          dibuatOlehUid: data['dibuatOlehUid'] ?? '',
                          untukKelas: data['untukKelas'] ?? 'Tidak diketahui',
                          isGuruView: true,
                          onEdit: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditAnnouncementScreen(
                                  announcementId: doc.id,
                                  initialData: data,
                                ),
                              ),
                            );
                          },
                          onDelete: () {
                            _hapusPengumuman(
                              doc.id,
                              data['judul'] ?? 'Tanpa Judul',
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateAnnouncementScreen(),
            ),
          );
        },
        label: const Text('Buat Pengumuman'),
        icon: const Icon(Icons.campaign),
      ),
    );
  }
}
