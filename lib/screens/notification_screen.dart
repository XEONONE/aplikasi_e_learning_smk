// lib/screens/notification_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_e_learning_smk/widgets/custom_loading_indicator.dart';
import 'package:aplikasi_e_learning_smk/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Untuk mendapatkan userId

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final AuthService _authService = AuthService();
  final User? currentUser = FirebaseAuth.instance.currentUser;
  String? _userKelas; // Untuk filter notifikasi berdasarkan kelas

  @override
  void initState() {
    super.initState();
    _fetchUserKelasAndMarkRead();
  }

  // --- FUNGSI BARU UNTUK MENGGABUNGKAN FETCH KELAS DAN MARK AS READ ---
  Future<void> _fetchUserKelasAndMarkRead() async {
    if (currentUser != null) {
      final userData = await _authService.getUserData(currentUser!.uid);
      if (mounted) {
        setState(() {
          _userKelas = userData?.kelas;
        });
        // Setelah mendapatkan kelas, panggil fungsi mark read
        if (_userKelas != null) {
          _markNotificationsAsRead();
        }
      }
    }
  }

  // --- FUNGSI BARU UNTUK MENANDAI NOTIFIKASI SEBAGAI DIBACA ---
  Future<void> _markNotificationsAsRead() async {
    if (currentUser == null || _userKelas == null) return;

    final query = FirebaseFirestore.instance
        .collection('notifications')
        .where(
          'targetAudience',
          arrayContainsAny: [
            (currentUser!.uid),
            'kelas_${_userKelas!}',
            'all_users',
          ],
        )
        .where('isRead', isEqualTo: false); // Hanya ambil yang belum dibaca

    try {
      final snapshot = await query.get();
      // Gunakan batch write untuk efisiensi
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
      print('Ditandai ${snapshot.docs.length} notifikasi sebagai dibaca.');
    } catch (e) {
      print('Gagal menandai notifikasi sebagai dibaca: $e');
    }
  }
  // --- AKHIR FUNGSI BARU ---

  // Fungsi untuk menghitung waktu relatif (e.g., "5 menit yang lalu")
  String _timeAgo(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    final Duration diff = DateTime.now().difference(dateTime);

    if (diff.inDays > 7) {
      return DateFormat('d MMM yyyy, HH:mm', 'id_ID').format(dateTime);
    } else if (diff.inDays > 0) {
      return '${diff.inDays} hari yang lalu';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} jam yang lalu';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  // --- WIDGET UNTUK KARTU NOTIFIKASI ---
  Widget _buildNotificationCard(
    BuildContext context,
    String type,
    String title,
    String subtitle,
    Timestamp timestamp, {
    Color? iconColor,
    IconData? icon,
    bool isRead = true, // Tambahkan parameter isRead
  }) {
    final theme = Theme.of(context);
    IconData defaultIcon;
    Color defaultColor;
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: isRead
          ? FontWeight.normal
          : FontWeight.bold, // Bold jika belum dibaca
    );
    final cardColor = isRead
        ? theme.cardColor
        : theme.colorScheme.primary.withOpacity(
            0.05,
          ); // Warna beda jika belum dibaca

    switch (type) {
      case 'new_materi': // Tambahkan case untuk materi baru
        defaultIcon = Icons.auto_stories_outlined;
        defaultColor = Colors.blue.shade600;
        break;
      case 'grade':
        defaultIcon = Icons.check_circle_outline;
        defaultColor = Colors.green.shade600;
        break;
      case 'new_task':
        defaultIcon = Icons.assignment_outlined;
        defaultColor = Colors.orange.shade600;
        break;
      case 'announcement':
        defaultIcon = Icons.campaign_outlined;
        defaultColor = Colors.purple.shade600;
        break;
      default:
        defaultIcon = Icons.info_outline;
        defaultColor = Colors.blue.shade600;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
      elevation: isRead ? 1.0 : 2.0, // Sedikit lebih menonjol jika belum dibaca
      color: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon ?? defaultIcon,
              color: iconColor ?? defaultColor,
              size: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: titleStyle),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(
                        0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _timeAgo(timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  // --- AKHIR WIDGET UNTUK KARTU NOTIFIKASI ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (currentUser == null || _userKelas == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Notifikasi'),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
        ),
        body: const Center(child: CustomLoadingIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitas Terbaru'), // Sesuai gambar
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Implementasi pencarian notifikasi
            },
            icon: Icon(Icons.search, color: theme.iconTheme.color),
          ),
          IconButton(
            onPressed: () {
              // TODO: Implementasi filter atau pengaturan notifikasi
            },
            icon: Icon(
              Icons.notifications_none_outlined, // Ubah jadi outline biasa
              color: theme.iconTheme.color,
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            // Filter notifikasi milik user ini atau notifikasi umum untuk kelas ini
            .where(
              'targetAudience',
              arrayContainsAny: [
                (currentUser!.uid), // Notifikasi personal
                'kelas_${_userKelas!}', // Notifikasi kelas
                'all_users', // Notifikasi untuk semua pengguna (misal: pengumuman penting)
              ],
            )
            .orderBy('timestamp', descending: true)
            .limit(20) // Batasi jumlah notifikasi yang diambil
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomLoadingIndicator());
          }
          if (snapshot.hasError) {
            print("Error fetching notifications: ${snapshot.error}");
            return Center(
              child: Text('Gagal memuat notifikasi: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Tidak ada notifikasi terbaru.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final String type = data['type'] ?? 'info';
              final String title = data['title'] ?? 'Notifikasi';
              final String subtitle = data['subtitle'] ?? '';
              final Timestamp timestamp = data['timestamp'] ?? Timestamp.now();
              // --- AMBIL STATUS isRead ---
              final bool isRead =
                  data['isRead'] ?? true; // Anggap dibaca jika tidak ada field

              return _buildNotificationCard(
                context,
                type,
                title,
                subtitle,
                timestamp,
                isRead: isRead, // Kirim status ke widget card
              );
            },
          );
        },
      ),
    );
  }
}
