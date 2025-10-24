// lib/screens/guru_home_screen.dart

import 'package:aplikasi_e_learning_smk/models/user_model.dart';
import 'package:aplikasi_e_learning_smk/screens/create_announcement_screen.dart';
import 'package:aplikasi_e_learning_smk/services/auth_service.dart';
import 'package:aplikasi_e_learning_smk/widgets/announcement_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GuruHomeScreen extends StatefulWidget {
  const GuruHomeScreen({super.key});

  @override
  State<GuruHomeScreen> createState() => _GuruHomeScreenState();
}

class _GuruHomeScreenState extends State<GuruHomeScreen> {
  final AuthService _authService = AuthService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Helper widget untuk membuat kartu ringkasan
  Widget _buildSummaryCard(
    IconData icon,
    String label,
    Stream<QuerySnapshot> stream,
    Color iconColor,
  ) {
    final theme = Theme.of(context);
    // Tentukan warna teks subtitle berdasarkan tema
    final subtitleColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.7);

    return Expanded(
      child: Card(
        // Style Card diambil dari tema
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 30),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    // --- PERBAIKAN: Gunakan subtitleColor ---
                    style: TextStyle(
                      color: subtitleColor,
                      // color: Colors.grey[400], <-- HAPUS
                      fontSize: 14,
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: stream,
                    builder: (context, snapshot) {
                      final count = snapshot.data?.docs.length ?? 0;
                      return Text(
                        count.toString(),
                        // --- PERBAIKAN: Ambil warna dari tema ---
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          // color: Colors.white, <-- HAPUS
                        ),
                      );
                    },
                  ),
                ],
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
    // Tentukan warna teks subtitle berdasarkan tema
    final subtitleColor = theme.textTheme.bodyMedium?.color?.withOpacity(0.7);

    return Scaffold(
      body: FutureBuilder<UserModel?>(
        future: _authService.getUserData(currentUser!.uid),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
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
                // -- BAGIAN HEADER --
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
                          // --- PERBAIKAN: Gunakan subtitleColor ---
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: subtitleColor,
                            // color: Colors.grey[400], <-- HAPUS
                          ),
                        ),
                        Text(
                          user.nama,
                          // --- PERBAIKAN: Ambil warna dari tema ---
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            // color: Colors.white, <-- HAPUS
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Card sapaan yang lebih besar
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang, Bpk. ${user.nama.split(' ').first}!',
                          // --- PERBAIKAN: Ambil warna dari tema ---
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            // color: Colors.white, <-- HAPUS
                          ),
                        ),
                        if (user.mengajarKelas != null &&
                            user.mengajarKelas!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Mengajar: ${user.mengajarKelas!.join(', ')}',
                            // --- PERBAIKAN: Gunakan subtitleColor ---
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: subtitleColor,
                              // color: Colors.grey[400], <-- HAPUS
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // -- BAGIAN RINGKASAN --
                Row(
                  children: [
                    _buildSummaryCard(
                      Icons.library_books,
                      'Total Materi',
                      FirebaseFirestore.instance
                          .collection('materi')
                          .snapshots(),
                      Colors.green.shade400,
                    ),
                    const SizedBox(width: 16),
                    _buildSummaryCard(
                      Icons.edit_note,
                      'Total Tugas',
                      FirebaseFirestore.instance
                          .collection('tugas')
                          .snapshots(),
                      Colors.orange.shade400,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // -- BAGIAN PENGUMUMAN --
                Text(
                  'Pengumuman Terkini',
                  // --- PERBAIKAN: Ambil warna dari tema ---
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    // color: Colors.white, <-- HAPUS
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
                          // Ambil warna teks dari tema (lebih redup)
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
                        );
                      }).toList(),
                    );
                  },
                ),

                // -- AKHIR BAGIAN PENGUMUMAN --
                const SizedBox(height: 80), // Ruang untuk FAB
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
