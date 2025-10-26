// lib/widgets/task_card.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskCard extends StatelessWidget {
  final String taskId;
  final String judul;
  final Timestamp tenggatWaktu;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.taskId,
    required this.judul,
    required this.tenggatWaktu,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    DateTime tenggat = tenggatWaktu.toDate();
    String formattedTenggat = DateFormat('d MMM yyyy, HH:mm').format(tenggat);
    bool isLate = DateTime.now().isAfter(tenggat);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                judul,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 16,
                    color: isLate ? Colors.red : Colors.black54,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tenggat: $formattedTenggat',
                    style: TextStyle(
                      color: isLate ? Colors.red : Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ## PERUBAHAN UTAMA: MENGGUNAKAN WRAP ##
              Wrap(
                spacing: 8.0, // Jarak horizontal antar item
                runSpacing: 4.0, // Jarak vertikal jika ada baris baru
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Widget untuk menampilkan jumlah pengumpul
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('tugas')
                        .doc(taskId)
                        .collection('pengumpulan')
                        .snapshots(),
                    builder: (context, snapshot) {
                      int submissionCount = 0;
                      if (snapshot.hasData) {
                        submissionCount = snapshot.data!.docs.length;
                      }
                      return Row(
                        mainAxisSize:
                            MainAxisSize.min, // Agar tidak memakan semua lebar
                        children: [
                          const Icon(
                            Icons.people_alt_outlined,
                            size: 16,
                            color: Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text('$submissionCount siswa telah mengumpulkan'),
                        ],
                      );
                    },
                  ),
                  // Widget untuk tombol-tombol
                  Row(
                    mainAxisSize:
                        MainAxisSize.min, // Agar tidak memakan semua lebar
                    children: [
                      if (onEdit != null)
                        IconButton(
                          icon: Icon(
                            Icons.edit_note,
                            color: Colors.orange.shade700,
                          ),
                          onPressed: onEdit,
                          tooltip: 'Edit Tugas',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      if (onDelete != null)
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade700,
                          ),
                          onPressed: onDelete,
                          tooltip: 'Hapus Tugas',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ],
              ),
              // ## AKHIR PERUBAHAN ##
            ],
          ),
        ),
      ),
    );
  }
}
