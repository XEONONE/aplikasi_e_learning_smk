// lib/widgets/task_summary_card.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskSummaryCard extends StatelessWidget {
  final String taskId;
  final Map<String, dynamic> taskData;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const TaskSummaryCard({
    super.key,
    required this.taskId,
    required this.taskData,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  Future<int> _getSubmissionCount(String taskId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('tugas')
          .doc(taskId)
          .collection('pengumpulan')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print("Error counting submissions: $e");
      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('tugas')
            .doc(taskId)
            .collection('submissions')
            .get();
        return snapshot.docs.length;
      } catch (e2) {
        print("Error counting submissions (fallback): $e2");
        return 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Tentukan warna teks subtitle berdasarkan tema
    final subtitleColor = theme.textTheme.bodySmall?.color?.withOpacity(0.7);
    final now = DateTime.now();

    final String judul = taskData['judul'] ?? 'Tanpa Judul';
    final String untukKelas =
        taskData['untukKelas'] as String? ?? 'Tidak Diketahui';
    final Timestamp tenggatTimestamp =
        taskData['tenggatWaktu'] as Timestamp? ?? Timestamp.now();
    final DateTime dueDate = tenggatTimestamp.toDate();
    final difference = dueDate.difference(now);
    bool isOverdue = dueDate.isBefore(now);

    String deadlineText;
    Color deadlineColor;

    if (isOverdue) {
      deadlineText =
          'Tenggat: ${DateFormat('dd MMM yyyy', 'id_ID').format(dueDate)} (Berakhir)';
      deadlineColor = theme.colorScheme.error; // Warna error dari tema
    } else if (difference.inDays >= 1) {
      deadlineText =
          'Sisa ${difference.inDays + 1} hari (${DateFormat('dd MMM yyyy', 'id_ID').format(dueDate)})';
      deadlineColor = Colors.orangeAccent; // Orange cukup kontras
    } else if (difference.inHours >= 1) {
      deadlineText =
          'Sisa ${difference.inHours} jam (${DateFormat('HH:mm', 'id_ID').format(dueDate)})';
      deadlineColor = Colors.orangeAccent;
    } else {
      deadlineText = 'Kurang dari 1 jam lagi';
      deadlineColor = theme.colorScheme.error; // Warna error dari tema
    }

    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        // Style Card diambil dari tema
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                judul,
                // --- PERBAIKAN: Ambil warna dari tema ---
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  // color: Colors.white, <-- HAPUS
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Untuk: $untukKelas',
                // --- PERBAIKAN: Gunakan subtitleColor ---
                style: theme.textTheme.bodySmall?.copyWith(
                  color: subtitleColor,
                  // color: Colors.grey[400], <-- HAPUS
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: deadlineColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      deadlineText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: deadlineColor, // Warna deadline tetap spesifik
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FutureBuilder<int>(
                    future: _getSubmissionCount(taskId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text(
                          'Memuat...',
                          // --- PERBAIKAN: Gunakan subtitleColor ---
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: subtitleColor,
                            // color: Colors.grey[400], <-- HAPUS
                          ),
                        );
                      }
                      final count = snapshot.data ?? 0;
                      return Text(
                        '$count Siswa Mengumpulkan',
                        // --- PERBAIKAN: Gunakan subtitleColor ---
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: subtitleColor,
                          // color: Colors.grey[400], <-- HAPUS
                        ),
                      );
                    },
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        // Warna ikon tombol bisa spesifik atau dari tema
                        color: theme.colorScheme.primary,
                        onPressed: onEdit,
                        tooltip: 'Edit Tugas',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        // Warna ikon tombol bisa spesifik atau dari tema
                        color: theme.colorScheme.error,
                        onPressed: onDelete,
                        tooltip: 'Hapus Tugas',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
