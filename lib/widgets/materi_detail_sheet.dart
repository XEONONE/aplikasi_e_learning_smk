// lib/widgets/materi_detail_sheet.dart

import 'package:aplikasi_e_learning_smk/models/user_model.dart';
import 'package:aplikasi_e_learning_smk/services/auth_service.dart';
import 'package:aplikasi_e_learning_smk/widgets/comment_section.dart';
import 'package:aplikasi_e_learning_smk/widgets/custom_loading_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- Import baru

// --- KONVERSI KE STATEFULWIDGET ---
class MateriDetailSheet extends StatefulWidget {
  final Map<String, dynamic> materiData;
  final String materiId;

  const MateriDetailSheet({
    super.key,
    required this.materiData,
    required this.materiId,
  });

  @override
  State<MateriDetailSheet> createState() => _MateriDetailSheetState();
}

class _MateriDetailSheetState extends State<MateriDetailSheet> {
  // --- TAMBAHAN BARU ---
  final AuthService _authService = AuthService();
  final User? _currentUserAuth = FirebaseAuth.instance.currentUser;
  late Future<UserModel?> _userFuture;

  @override
  void initState() {
    super.initState();
    // Ambil data user yang sedang login
    if (_currentUserAuth != null) {
      // ===== PERBAIKAN: Menghapus '!' yang tidak perlu =====
      _userFuture = _authService.getUserData(_currentUserAuth.uid);
    } else {
      _userFuture = Future.value(null);
    }
  }
  // --- AKHIR TAMBAHAN BARU ---

  Future<void> _bukaLink(BuildContext context, String? fileUrl) async {
    if (fileUrl == null || fileUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada link/file yang dilampirkan.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final Uri url = Uri.parse(fileUrl);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Tidak dapat membuka $fileUrl';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal membuka link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = widget.materiData; // <-- Gunakan 'widget.materiData'

    final String judul = data['judul'] ?? 'Tanpa Judul';
    final String deskripsi = data['deskripsi'] ?? 'Tanpa Deskripsi';
    final String guruNama = data['guruNama'] ?? 'Nama Guru';
    final String? fileUrl = data['fileUrl'] as String?;

    DateTime uploadDate =
        (data['diunggahPada'] as Timestamp? ?? Timestamp.now()).toDate();
    String formattedDate = DateFormat(
      'd MMMM yyyy',
      'id_ID',
    ).format(uploadDate);

    // --- MODIFIKASI: Bungkus dengan FutureBuilder ---
    return FutureBuilder<UserModel?>(
      future: _userFuture,
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            heightFactor: 3, // Beri tinggi agar tidak aneh
            child: CustomLoadingIndicator(),
          );
        }

        if (userSnapshot.hasError) {
          return const Center(
            heightFactor: 3,
            child: Text('Gagal memuat data user.'),
          );
        }

        // Tidak perlu !userSnapshot.hasData karena jika null akan ditangani
        // di dalam CommentSection, tapi userFuture di atas sudah
        // menangani kasus _currentUserAuth == null.
        // Kita tetap bisa lanjut walau user null (misal: mode guest nanti)

        // final UserModel? currentUser = userSnapshot.data; // Kita tidak perlu ini lagi

        // Widget ini memastikan konten bisa di-scroll di dalam bottom sheet
        return Flexible(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header (Judul dan Tanggal)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        judul,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(guruNama, style: theme.textTheme.bodyMedium),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: theme.textTheme.bodySmall?.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            formattedDate,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Deskripsi
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Text(
                    deskripsi,
                    style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16),
                  ),
                ),

                // Tombol Buka Link
                if (fileUrl != null && fileUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.link),
                      label: const Text('Buka Link Materi (Drive)'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        foregroundColor: theme.colorScheme.onPrimary,
                        backgroundColor: theme.colorScheme.primary,
                      ),
                      onPressed: () => _bukaLink(context, fileUrl),
                    ),
                  ),

                // --- BAGIAN DISKUSI (TAMBAHAN BARU) ---
                const SizedBox(height: 16),
                const Divider(thickness: 1, height: 1),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'Diskusi & Tanya Jawab',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // ===== PERBAIKAN TOTAL DI SINI =====
                // Memanggil Widget CommentSection dengan parameter yang benar
                CommentSection(
                  documentId: widget.materiId, // ID dari materi ini
                  // Path: koleksi 'materi' -> dokumen (materiId) -> sub-koleksi 'comments'
                  collectionPath: 'materi/${widget.materiId}/comments',
                ),

                // ===== AKHIR PERBAIKAN =====
                const SizedBox(height: 16),
                // --- AKHIR BAGIAN DISKUSI ---
              ],
            ),
          ),
        );
      },
    );
  }
}
