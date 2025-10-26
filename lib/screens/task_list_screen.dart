// lib/screens/task_list_screen.dart

import 'package:aplikasi_e_learning_smk/screens/create_task_screen.dart';
import 'package:aplikasi_e_learning_smk/screens/edit_task_screen.dart'; // Pastikan ada
import 'package:aplikasi_e_learning_smk/screens/submission_list_screen.dart';
import 'package:aplikasi_e_learning_smk/widgets/custom_loading_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TaskListScreen extends StatefulWidget {
  final bool showExpired; // true untuk Riwayat, false untuk Tugas Aktif
  const TaskListScreen({super.key, required this.showExpired});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'id_ID'; // Set locale Indonesia
  }

  // Fungsi untuk menghapus tugas
  Future<void> _deleteTask(String taskId) async {
    // ... (fungsi _deleteTask tetap sama) ...
    showDialog(
      context: context,
      barrierDismissible:
          false, // User tidak bisa menutup dialog dengan tap di luar
      builder: (BuildContext context) {
        return const Center(child: CustomLoadingIndicator());
      },
    );

    try {
      // Hapus dokumen tugas utama
      await FirebaseFirestore.instance.collection('tugas').doc(taskId).delete();

      // Hapus subkoleksi pengumpulan (opsional, jika ingin bersih-bersih total)
      QuerySnapshot submissionSnapshot = await FirebaseFirestore.instance
          .collection('tugas')
          .doc(taskId)
          .collection('pengumpulan')
          .get();

      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (DocumentSnapshot doc in submissionSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (!mounted) return;
      Navigator.of(context).pop(); // Tutup dialog loading

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tugas berhasil dihapus.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Tutup dialog loading jika error

      print("Error deleting task: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus tugas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Dialog konfirmasi hapus
  void _showDeleteConfirmationDialog(String taskId, String taskTitle) {
    // ... (fungsi _showDeleteConfirmationDialog tetap sama) ...
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text(
            'Apakah Anda yakin ingin menghapus tugas "$taskTitle"? Semua data pengumpulan terkait juga akan dihapus. Tindakan ini tidak dapat dibatalkan.',
          ), // Update pesan
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog konfirmasi
                _deleteTask(taskId); // Panggil fungsi hapus
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text("Silakan login kembali.")),
      );
    }

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tugas')
            .where('guruId', isEqualTo: currentUserId)
            .orderBy('tenggatWaktu', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomLoadingIndicator());
          }
          // Pindahkan pengecekan error ke sini agar tidak error saat docs kosong
          if (snapshot.hasError) {
            print("Error loading tasks: ${snapshot.error}");
            return const Center(
              child: Text(
                'Gagal memuat tugas. Coba lagi nanti.',
                style: TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  widget.showExpired
                      ? 'Belum ada riwayat tugas.'
                      : 'Belum ada tugas aktif.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ),
            );
          }

          // Filter dokumen berdasarkan showExpired
          final now = DateTime.now();
          print(
            "--- Memfilter Tugas (Tab Aktif: ${!widget.showExpired}, Waktu Sekarang: $now) ---",
          ); // DEBUG: Tambah waktu sekarang

          final filteredDocs = snapshot.data!.docs.where((doc) {
            final taskData = doc.data() as Map<String, dynamic>;
            final tenggatTimestamp = taskData['tenggatWaktu'] as Timestamp?;
            final String judulTugas =
                taskData['judul'] ?? 'Tanpa Judul'; // Ambil judul untuk debug

            print(
              "  Mengecek Tugas ID: ${doc.id} - Judul: $judulTugas",
            ); // DEBUG: Tambah ID

            DateTime? tenggatWaktu;
            bool isExpired = false; // Default false

            if (tenggatTimestamp != null) {
              tenggatWaktu = tenggatTimestamp.toDate();
              isExpired = tenggatWaktu.isBefore(now); // Lakukan perbandingan
              print("    Tenggat: $tenggatWaktu"); // DEBUG
              print(
                "    Apakah tenggat sebelum waktu sekarang ($now)? $isExpired",
              ); // DEBUG
            } else {
              print("    Tenggat: NULL (Dianggap tidak expired)"); // DEBUG
              // isExpired tetap false jika null
            }

            final bool shouldShow = widget.showExpired ? isExpired : !isExpired;
            print("    Tampilkan di tab ini? $shouldShow"); // DEBUG
            return shouldShow;
          }).toList();

          if (filteredDocs.isEmpty) {
            print("--- Tidak ada tugas yang lolos filter ---"); // DEBUG
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Text(
                  widget.showExpired
                      ? 'Belum ada riwayat tugas.'
                      : 'Belum ada tugas aktif.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0),
            itemCount: filteredDocs.length,
            itemBuilder: (context, index) {
              final taskDoc = filteredDocs[index];
              final taskData = taskDoc.data() as Map<String, dynamic>;
              final String judul = taskData['judul'] ?? 'Tanpa Judul';
              final String mapel = taskData['mataPelajaran'] ?? 'Mapel';
              final String kelas = taskData['untukKelas'] ?? '?';
              // Ambil timestamp lagi, pastikan ada fallback jika null
              final Timestamp tenggatTimestamp =
                  taskData['tenggatWaktu'] as Timestamp? ??
                  Timestamp.fromMillisecondsSinceEpoch(
                    0,
                  ); // Fallback jauh di masa lalu jika null
              final DateTime tenggatWaktu = tenggatTimestamp.toDate();
              // Hitung isExpired lagi di sini karena kita butuh untuk UI
              final bool isExpired = tenggatWaktu.isBefore(now);

              final String formattedTenggat = DateFormat(
                'dd MMM yyyy, HH:mm',
              ).format(tenggatWaktu);
              // Gunakan fungsi _calculate... hanya jika tidak expired
              final String sisaWaktu = isExpired
                  ? "Sudah Berakhir"
                  : _calculateRemainingTime(tenggatWaktu);

              // ... (sisa kode Card dan InkWell tetap sama) ...
              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                elevation: 3.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.0),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubmissionListScreen(
                          taskId: taskDoc.id,
                          taskTitle: judul,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment:
                              CrossAxisAlignment.start, // Align top
                          children: [
                            Expanded(
                              // Use Expanded for title
                              child: Text(
                                judul,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 2, // Allow title to wrap
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Tombol Opsi (Edit/Hapus) - Rapatkan ke kanan
                            SizedBox(
                              // Constrain the size of PopupMenuButton
                              width: 40, // Adjust width as needed
                              child: PopupMenuButton<String>(
                                padding: EdgeInsets.zero, // Remove padding
                                tooltip: 'Opsi Lain',
                                icon: Icon(
                                  Icons.more_vert,
                                  color: Colors.grey[600],
                                ),
                                onSelected: (String result) {
                                  switch (result) {
                                    case 'edit':
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditTaskScreen(
                                            // Pastikan EditTaskScreen ada
                                            taskId: taskDoc.id,
                                            initialData: taskData,
                                          ),
                                        ),
                                      );
                                      break;
                                    case 'delete':
                                      _showDeleteConfirmationDialog(
                                        taskDoc.id,
                                        judul,
                                      );
                                      break;
                                  }
                                },
                                itemBuilder: (BuildContext context) =>
                                    <PopupMenuEntry<String>>[
                                      const PopupMenuItem<String>(
                                        value: 'edit',
                                        child: ListTile(
                                          dense: true,
                                          leading: Icon(
                                            Icons.edit_outlined,
                                            size: 20,
                                          ),
                                          title: Text('Edit'),
                                        ),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'delete',
                                        child: ListTile(
                                          dense: true,
                                          leading: Icon(
                                            Icons.delete_outline,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          title: Text(
                                            'Hapus',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ),
                                    ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          '$mapel - Kelas $kelas',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[700]),
                        ),
                        const SizedBox(height: 12.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.timer_outlined,
                                  size: 16,
                                  color: isExpired
                                      ? Colors.red.shade700
                                      : Colors.orange.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  sisaWaktu,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isExpired
                                        ? Colors.red.shade700
                                        : Colors.orange.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Tenggat: $formattedTenggat',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: null, // Pastikan ini ada
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTaskScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Buat Tugas'),
      ),
    );
  }

  String _calculateRemainingTime(DateTime dueDate) {
    final now = DateTime.now();
    // Pastikan dueDate tidak di masa lalu saat memanggil ini
    if (dueDate.isBefore(now)) return "Sudah Berakhir";

    final difference = dueDate.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays} hari lagi';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam lagi';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit lagi';
    } else {
      return 'Segera Berakhir'; // Kurang dari semenit
    }
  }
}
