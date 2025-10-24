// lib/screens/submission_list_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
// ## 1. IMPORT WIDGET KOMENTAR ##
import 'package:aplikasi_e_learning_smk/widgets/comment_section.dart';

class SubmissionListScreen extends StatefulWidget {
  final String taskId;
  final String taskTitle;

  const SubmissionListScreen({
    super.key,
    required this.taskId,
    required this.taskTitle,
  });

  @override
  State<SubmissionListScreen> createState() => _SubmissionListScreenState();
}

class _SubmissionListScreenState extends State<SubmissionListScreen> {
  // --- PERBAIKAN: Tambahkan pengecekan null dan string kosong ---
  Future<void> _launchUrl(String? fileUrl) async {
    if (fileUrl == null || fileUrl.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Siswa ini tidak melampirkan link.')),
        );
      }
      return;
    }

    String urlString = fileUrl;
    if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
      urlString = 'https://$urlString';
    }

    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $url';
      }
    } catch (e) {
      print("Error launching URL: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka link: $urlString')),
        );
      }
    }
  }

  Future<String> _getStudentName(String uid) async {
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (userDoc.docs.isNotEmpty) {
        // --- PERBAIKAN: Pastikan mengembalikan String ---
        return userDoc.docs.first.data()['nama'] as String? ?? 'Siswa Anonim';
      }
      return 'Siswa Anonim';
    } catch (e) {
      print("Error getStudentName: $e");
      return 'Error';
    }
  }

  Future<void> _showGradingDialog(
    String submissionId,
    Map<String, dynamic> currentSubmissionData,
  ) async {
    final nilaiController = TextEditingController(
      // --- PERBAIKAN: Konversi nilai (mungkin number) ke String ---
      text: (currentSubmissionData['nilai']?.toString()) ?? '',
    );
    final feedbackController = TextEditingController(
      // --- PERBAIKAN: Pastikan feedback adalah String ---
      text: (currentSubmissionData['feedback'] as String?) ?? '',
    );

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Beri Nilai dan Feedback'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextFormField(
                  // Ubah ke TextFormField
                  controller: nilaiController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Nilai (0-100)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nilai tidak boleh kosong';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  // Ubah ke TextFormField
                  controller: feedbackController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Catatan / Feedback (Opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Simpan'),
              onPressed: () async {
                // Validasi nilai sebelum menyimpan
                final int? nilai = int.tryParse(nilaiController.text);
                if (nilai == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nilai harus berupa angka.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return; // Jangan tutup dialog
                }

                try {
                  await FirebaseFirestore.instance
                      .collection('tugas')
                      .doc(widget.taskId)
                      .collection('pengumpulan')
                      .doc(submissionId)
                      .update({
                        'nilai': nilai, // Simpan sebagai angka
                        'feedback': feedbackController.text.trim(),
                      });
                  if (!mounted) return;
                  Navigator.of(context).pop(); // Tutup dialog setelah berhasil
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gagal menyimpan: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pengumpulan: ${widget.taskTitle}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // BAGIAN DAFTAR PENGUMPULAN SISWA
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tugas')
                  .doc(widget.taskId)
                  .collection('pengumpulan')
                  .orderBy('dikumpulkanPada', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Text(
                        'Belum ada siswa yang mengumpulkan tugas ini.',
                      ),
                    ),
                  );
                }

                return Column(
                  children: snapshot.data!.docs.map((submissionDoc) {
                    var submissionData =
                        submissionDoc.data() as Map<String, dynamic>;
                    DateTime dikumpulkanPada =
                        (submissionData['dikumpulkanPada'] as Timestamp? ??
                                Timestamp.now()) // Fallback
                            .toDate();
                    String formattedDate = DateFormat(
                      'd MMM yyyy, HH:mm',
                      'id_ID',
                    ).format(dikumpulkanPada);

                    // --- PERBAIKAN: Ambil data dengan aman ---
                    final String siswaUid =
                        submissionData['siswaUid'] as String? ??
                        submissionData['userId'] as String? ??
                        '';
                    final String fileUrl =
                        (submissionData['fileUrl'] as String?) ?? '';
                    final dynamic nilai =
                        submissionData['nilai']; // Bisa null, bisa number
                    // --- AKHIR PERBAIKAN ---

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const Icon(
                          Icons.person_outline,
                          size: 40,
                          color: Colors.grey,
                        ),
                        title: FutureBuilder<String>(
                          future: _getStudentName(
                            siswaUid,
                          ), // Gunakan siswaUid yang aman
                          builder: (context, nameSnapshot) {
                            if (nameSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Text(
                                'Memuat nama...',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              );
                            }
                            return Text(
                              nameSnapshot.data ?? 'Siswa Anonim',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          },
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mengumpulkan pada: $formattedDate'),
                            if (nilai != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Nilai: $nilai',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.link, // Ganti ikon menjadi link
                                color: fileUrl.isNotEmpty
                                    ? Colors.blue
                                    : Colors.grey, // Warna beda jika ada link
                              ),
                              tooltip: 'Lihat Link Jawaban',
                              onPressed: () => _launchUrl(
                                fileUrl,
                              ), // Gunakan fileUrl yang aman
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.rate_review_outlined, // Ganti ikon
                                color: Colors.orange,
                              ),
                              tooltip: 'Beri Nilai',
                              onPressed: () => _showGradingDialog(
                                submissionDoc.id,
                                submissionData,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const Divider(height: 48, thickness: 1),
            CommentSection(documentId: widget.taskId, collectionPath: 'tugas'),
          ],
        ),
      ),
    );
  }
}
