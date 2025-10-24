// lib/screens/task_detail_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_e_learning_smk/services/auth_service.dart'; // Tetap diperlukan jika Anda panggil AuthService
// import 'package:aplikasi_e_learning_smk/widgets/comment_section.dart'; // Hapus jika tidak dipakai
import 'package:aplikasi_e_learning_smk/widgets/custom_loading_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart'; // <-- IMPORT YANG DITAMBAHKAN

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  final Map<String, dynamic> taskData;

  const TaskDetailScreen({
    super.key,
    required this.taskId,
    required this.taskData,
  });

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  // Sekarang User dan FirebaseAuth dikenali
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _linkController = TextEditingController();

  bool _isUploading = false;
  bool _isLoadingSubmission = true;
  Map<String, dynamic>? _submissionData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSubmissionData();
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubmissionData() async {
    if (currentUser == null) {
      setState(() {
        _isLoadingSubmission = false;
        _errorMessage = 'User tidak ditemukan.';
      });
      return;
    }
    try {
      final docRef = FirebaseFirestore.instance
          .collection('tugas')
          .doc(widget.taskId)
          .collection('pengumpulan')
          .doc(currentUser!.uid); // Gunakan UID user saat ini
      final docSnapshot = await docRef.get();
      if (docSnapshot.exists) {
        setState(() {
          _submissionData = docSnapshot.data();
          // Isi controller dengan link yang sudah dikumpulkan (jika ada)
          if (_submissionData?['fileUrl'] != null) {
            _linkController.text = _submissionData!['fileUrl'];
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memuat data pengumpulan: $e';
      });
      print('Error fetching submission: $e');
    } finally {
      setState(() {
        _isLoadingSubmission = false;
      });
    }
  }

  Future<void> _submitPengumpulan() async {
    if (currentUser == null) return;

    if (_linkController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan link Google Drive jawaban Anda.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final docRef = FirebaseFirestore.instance
          .collection('tugas')
          .doc(widget.taskId)
          .collection('pengumpulan')
          .doc(currentUser!.uid); // Gunakan UID user saat ini

      Map<String, dynamic> dataToSave = {
        'userId': currentUser!.uid, // Simpan juga userId jika perlu
        'dikumpulkanPada': Timestamp.now(),
        'fileUrl': _linkController.text.trim(),
        'fileName': 'Link Google Drive', // Nama file statis
      };

      await docRef.set(dataToSave, SetOptions(merge: true));

      setState(() {
        // Tidak perlu reset controller link jika ingin tetap terlihat
        _fetchSubmissionData(); // Refresh data
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tugas berhasil dikumpulkan!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error submitting task: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengumpulkan tugas: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _launchURL(String? urlString) async {
    if (urlString == null || urlString.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Link/URL tidak valid.')));
      return;
    }
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat membuka link: $urlString')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final String judul = widget.taskData['judul'] ?? 'Tanpa Judul';
    final String mapel = widget.taskData['mataPelajaran'] ?? 'Mapel';
    final String deskripsi =
        widget.taskData['deskripsi'] ?? 'Tidak ada deskripsi.';
    final Timestamp tenggatTimestamp =
        widget.taskData['tenggatWaktu'] as Timestamp? ?? Timestamp.now();
    final DateTime tenggatWaktu = tenggatTimestamp.toDate();
    final String formattedTenggat = DateFormat(
      'EEEE, dd MMM yyyy, HH:mm',
      'id_ID',
    ).format(tenggatWaktu);
    final String? lampiranUrl = widget.taskData['lampiranUrl'];

    final bool sudahDikumpulkan = _submissionData != null;
    final bool sudahDinilai = _submissionData?['nilai'] != null;
    final dynamic nilai = _submissionData?['nilai'];
    final String? feedbackGuru = _submissionData?['feedback'];
    final Timestamp? dikumpulkanPadaTs = _submissionData?['dikumpulkanPada'];
    final String? submittedFileUrl = _submissionData?['fileUrl'];

    final bool isOverdue = tenggatWaktu.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(judul),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 1,
      ),
      body: _isLoadingSubmission
          ? const Center(child: CustomLoadingIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Tugas
                  Card(
                    elevation: 2,
                    margin: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mapel,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            judul,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_filled,
                                size: 16,
                                color: isOverdue
                                    ? Colors.red.shade700
                                    : Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Tenggat: $formattedTenggat ${isOverdue ? "(Terlewat)" : ""}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isOverdue
                                      ? Colors.red.shade700
                                      : Colors.grey[700],
                                  fontWeight: isOverdue
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Text(
                            'Deskripsi Tugas:',
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(deskripsi, style: theme.textTheme.bodyMedium),
                          if (lampiranUrl != null &&
                              lampiranUrl.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              'Lampiran Link:',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _launchURL(lampiranUrl),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.link,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        lampiranUrl,
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          decoration: TextDecoration.underline,
                                          decorationColor:
                                              theme.colorScheme.primary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Status Pengumpulan
                  Text(
                    'Status Pengumpulan',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: theme.cardColor.withOpacity(0.8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Status:',
                                style: theme.textTheme.bodyMedium,
                              ),
                              Text(
                                sudahDikumpulkan
                                    ? (sudahDinilai
                                          ? 'Sudah Dinilai'
                                          : 'Sudah Dikumpulkan')
                                    : 'Belum Dikumpulkan',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: sudahDikumpulkan
                                      ? (sudahDinilai
                                            ? Colors.green.shade700
                                            : Colors.blue.shade700)
                                      : Colors.orange.shade700,
                                ),
                              ),
                            ],
                          ),
                          if (dikumpulkanPadaTs != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Dikumpulkan:',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy, HH:mm',
                                    'id_ID',
                                  ).format(dikumpulkanPadaTs.toDate()),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                          if (sudahDinilai) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Nilai:',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Text(
                                  nilai?.toString() ?? '-',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: (nilai is num && nilai >= 75)
                                        ? Colors.green.shade700
                                        : Colors.orange.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          // Tampilkan Link yang dikumpulkan
                          if (submittedFileUrl != null &&
                              submittedFileUrl.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Link Terkirim:',
                              style: theme.textTheme.bodyMedium,
                            ),
                            InkWell(
                              onTap: () => _launchURL(submittedFileUrl),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.link,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        submittedFileUrl,
                                        style: TextStyle(
                                          color: theme.colorScheme.primary,
                                          decoration: TextDecoration.underline,
                                          decorationColor:
                                              theme.colorScheme.primary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          // Feedback Guru
                          if (feedbackGuru != null &&
                              feedbackGuru.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Feedback Guru:',
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface.withOpacity(
                                  0.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Text(
                                feedbackGuru,
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bagian Input Pengumpulan (jika belum dinilai)
                  if (!sudahDinilai) ...[
                    Text(
                      sudahDikumpulkan ? 'Edit Pengumpulan' : 'Kumpulkan Tugas',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isOverdue && !sudahDikumpulkan)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Tenggat waktu sudah lewat.',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),

                    // Input Link Google Drive
                    TextFormField(
                      controller: _linkController,
                      decoration: InputDecoration(
                        hintText: 'Masukkan link Google Drive...',
                        labelText: 'Link Google Drive Jawaban',
                        prefixIcon: const Icon(Icons.link),
                        border: const OutlineInputBorder(),
                        filled: true, // Tambahkan background
                        fillColor: theme.inputDecorationTheme.fillColor
                            ?.withAlpha(128), // Warna background
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      keyboardType: TextInputType.url,
                      // Validasi sederhana untuk memastikan link tidak kosong (jika diperlukan)
                      // validator: (value) => (value == null || value.trim().isEmpty) ? 'Link tidak boleh kosong' : null,
                    ),

                    const SizedBox(height: 20),
                    _isUploading
                        ? const Center(child: CustomLoadingIndicator())
                        : ElevatedButton.icon(
                            icon: Icon(
                              sudahDikumpulkan
                                  ? Icons.cloud_sync_outlined
                                  : Icons.cloud_upload_outlined,
                            ),
                            label: Text(
                              sudahDikumpulkan ? 'Update Link' : 'Kirim Tugas',
                            ),
                            // Nonaktifkan tombol jika sudah overdue DAN belum mengumpulkan
                            onPressed: (isOverdue && !sudahDikumpulkan)
                                ? null
                                : _submitPengumpulan,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                  ] else ...[
                    // Tampilkan pesan jika sudah dinilai
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Text(
                          'Tugas ini sudah dinilai.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
