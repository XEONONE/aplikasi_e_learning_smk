// lib/screens/student_graded_tasks_screen.dart

import 'package:aplikasi_e_learning_smk/models/user_model.dart';
import 'package:aplikasi_e_learning_smk/screens/task_detail_screen.dart'; // Pastikan Anda punya screen ini
import 'package:aplikasi_e_learning_smk/services/auth_service.dart';
import 'package:aplikasi_e_learning_smk/widgets/custom_loading_indicator.dart'; // Pastikan Anda punya widget ini
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StudentGradedTasksScreen extends StatefulWidget {
  const StudentGradedTasksScreen({super.key});

  @override
  State<StudentGradedTasksScreen> createState() =>
      _StudentGradedTasksScreenState();
}

class _StudentGradedTasksScreenState extends State<StudentGradedTasksScreen> {
  int _selectedToggleIndex = 0; // 0: Aktif, 1: Selesai
  late Future<UserModel?> _userFuture;
  final AuthService _authService = AuthService();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'id_ID'; // Atur locale untuk format tanggal Indonesia
    if (currentUser != null) {
      _userFuture = _authService.getUserData(currentUser!.uid);
    } else {
      _userFuture = Future.value(null); // Handle jika user null
    }
  }

  // --- FUNGSI BARU UNTUK MEMPROSES TUGAS DENGAN DATA NILAI YANG DIAMBIL LANGSUNG ---
  Future<Map<String, List<Map<String, dynamic>>>> _processTasks(
    List<QueryDocumentSnapshot> taskDocs,
    String userId,
  ) async {
    List<Map<String, dynamic>> activeTasks = [];
    List<Map<String, dynamic>> completedTasks = [];
    final now = DateTime.now();

    for (var taskDoc in taskDocs) {
      final taskData = taskDoc.data() as Map<String, dynamic>;

      // --- PERBAIKAN INTI: AMBIL SUBMISSION SECARA LANGSUNG ---
      // Ini meniru cara kerja TaskDetailScreen yang berhasil
      final submissionRef = FirebaseFirestore.instance
          .collection('tugas')
          .doc(taskDoc.id)
          .collection('pengumpulan')
          .doc(userId); // Gunakan userId sebagai ID dokumen pengumpulan
      final submissionDoc = await submissionRef.get();
      final submissionData = submissionDoc
          .data(); // Bisa null jika tidak ada dokumen
      // --- AKHIR PERBAIKAN INTI ---

      final bool isGraded =
          submissionData != null && submissionData['nilai'] != null;

      final Timestamp tenggatTimestamp =
          taskData['tenggatWaktu'] as Timestamp? ?? Timestamp.now();
      final DateTime tenggatWaktu = tenggatTimestamp.toDate();
      final bool isOverdue = tenggatWaktu.isBefore(now);

      // Data ini akan kita gunakan untuk sorting dan building
      final taskEntry = {
        'taskDoc': taskDoc,
        'taskData': taskData,
        'submissionData': submissionData,
        'tenggat': tenggatWaktu, // Untuk sorting
        'eventDate':
            (submissionData?['dikumpulkanPada'] as Timestamp? ??
                    tenggatTimestamp)
                .toDate(), // Untuk sorting
      };

      // Logika sesuai permintaan Anda: Selesai = Sudah Dinilai ATAU Terlewat
      if (isGraded || isOverdue) {
        completedTasks.add(taskEntry);
      } else {
        activeTasks.add(taskEntry);
      }
    }

    // Urutkan tugas aktif (tenggat terdekat di atas)
    activeTasks.sort((a, b) {
      DateTime aTenggat = a['tenggat'] as DateTime;
      DateTime bTenggat = b['tenggat'] as DateTime;
      return aTenggat.compareTo(bTenggat);
    });

    // Urutkan tugas selesai (terbaru dinilai/terlewat di atas)
    completedTasks.sort((a, b) {
      DateTime aDate = a['eventDate'] as DateTime;
      DateTime bDate = b['eventDate'] as DateTime;
      return bDate.compareTo(aDate); // Descending
    });

    return {'active': activeTasks, 'completed': completedTasks};
  }

  // --- WIDGET KARTU TUGAS AKTIF ---
  Widget _buildActiveTaskCard(
    BuildContext context,
    String taskId,
    Map<String, dynamic> taskData,
  ) {
    final theme = Theme.of(context);
    final String judul = taskData['judul'] ?? 'Tanpa Judul';
    final String mapel = taskData['mataPelajaran'] ?? 'Mapel';
    final Timestamp tenggatTimestamp =
        taskData['tenggatWaktu'] as Timestamp? ?? Timestamp.now();
    final DateTime tenggatWaktu = tenggatTimestamp.toDate();
    final now = DateTime.now();
    final difference = tenggatWaktu.difference(now);

    String deadlineText;
    Color deadlineColor = Colors.orange.shade600; // Default

    // Logika menampilkan status tenggat
    if (difference.isNegative) {
      deadlineText = 'Terlewat';
      deadlineColor = theme.colorScheme.error;
    } else if (difference.inDays == 0 && tenggatWaktu.day == now.day) {
      deadlineText = 'Hari ini';
      deadlineColor = Colors.red.shade400; // Mendesak jika hari ini
    } else if (difference.inDays == 0 &&
        tenggatWaktu.day == now.add(const Duration(days: 1)).day) {
      deadlineText = 'Besok';
      deadlineColor = Colors.orange.shade600;
    } else if (difference.inDays >= 1) {
      deadlineText = '${difference.inDays} hari lagi';
      deadlineColor = Colors.green.shade600; // Tidak mendesak jika > 1 hari
    } else if (difference.inHours >= 1) {
      deadlineText = '${difference.inHours} jam lagi';
      deadlineColor = Colors.orange.shade600; // Cukup mendesak
    } else if (difference.inMinutes >= 1) {
      deadlineText = '${difference.inMinutes} menit lagi';
      deadlineColor = Colors.red.shade400; // Mendesak
    } else {
      deadlineText = 'Segera Berakhir';
      deadlineColor = theme.colorScheme.error; // Sangat mendesak
    }

    final String timeText = DateFormat('HH:mm').format(tenggatWaktu);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TaskDetailScreen(taskId: taskId, taskData: taskData),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mapel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    deadlineText,
                    style: TextStyle(
                      color: deadlineColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  // Hanya tampilkan jam jika tidak terlewat
                  if (!difference.isNegative) ...[
                    const SizedBox(height: 2),
                    Text(
                      timeText, // Menampilkan jam tenggat
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.7,
                        ),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET KARTU TUGAS SELESAI (SUDAH DINILAI ATAU TERLEWAT) ---
  Widget _buildGradedTaskCard(
    BuildContext context,
    String taskId,
    Map<String, dynamic> taskData,
    Map<String, dynamic>? submissionData, // Jadikan nullable
  ) {
    final theme = Theme.of(context);
    final String judul = taskData['judul'] ?? 'Tanpa Judul';
    final String mapel = taskData['mataPelajaran'] ?? 'Mapel';
    // Ambil nilai HANYA jika submissionData tidak null
    final nilai = submissionData?['nilai']; // Gunakan ?.

    // Ambil tanggal pengumpulan jika ada, jika tidak, gunakan tanggal tenggat sebagai fallback
    final Timestamp eventTimestamp =
        submissionData?['dikumpulkanPada'] as Timestamp? ?? // Gunakan ?.
        taskData['tenggatWaktu'] as Timestamp? ??
        Timestamp.now();
    final DateTime eventDate = eventTimestamp.toDate();
    // Format tanggal sesuai gambar: "dd Okt"
    final String formattedTanggal = DateFormat(
      'dd MMM',
      'id_ID',
    ).format(eventDate);

    // Tentukan warna background nilai dan teks nilai/status
    final Color nilaiBackgroundColor;
    final String nilaiText;

    if (nilai != null) {
      // Jika sudah ada nilai
      nilaiBackgroundColor = (nilai is num && nilai >= 75)
          ? Colors
                .green
                .shade600 // Hijau jika >= 75
          : Colors.orange.shade700; // Oranye jika < 75
      nilaiText = nilai.toString(); // Tampilkan nilai
    } else {
      // Jika belum ada nilai (kasus terlewat tapi belum dikumpul/dinilai)
      nilaiBackgroundColor = Colors.grey.shade600; // Warna abu-abu
      nilaiText = '-'; // Tampilkan strip
    }

    // Tentukan subtitle berdasarkan apakah sudah dinilai atau hanya terlewat
    final String subtitleText = nilai != null
        ? '$mapel - Dinilai pada $formattedTanggal' // Jika sudah dinilai
        : '$mapel - Terlewat'; // Jika hanya terlewat

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  TaskDetailScreen(taskId: taskId, taskData: taskData),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul, // Judul Tugas
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Subtitle: Menampilkan status (Dinilai/Terlewat)
                    Text(
                      subtitleText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(
                          0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Lingkaran untuk nilai atau status
              CircleAvatar(
                backgroundColor: nilaiBackgroundColor,
                radius: 22, // Sesuaikan ukuran jika perlu
                child: Text(
                  nilaiText, // Tampilkan nilai atau '-'
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
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

    if (currentUser == null) {
      return const Center(child: Text('Silakan login ulang.'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Tugas'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: false, // Judul rata kiri
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Aksi Pencarian
            },
            icon: Icon(
              Icons.search, // Icon kaca pembesar
              color: theme.iconTheme.color?.withOpacity(
                0.9,
              ), // Sedikit lebih jelas
            ),
            tooltip: 'Cari Tugas',
          ),
          IconButton(
            onPressed: () {
              // TODO: Aksi notifikasi
            },
            icon: Icon(
              Icons.notifications_outlined, // Icon lonceng
              color: theme.iconTheme.color?.withOpacity(
                0.9,
              ), // Sedikit lebih jelas
            ),
            tooltip: 'Notifikasi',
          ),
        ],
      ),
      body: FutureBuilder<UserModel?>(
        future: _userFuture,
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomLoadingIndicator());
          }
          if (!userSnapshot.hasData || userSnapshot.data == null) {
            return const Center(child: Text('Gagal memuat data siswa.'));
          }

          final userKelas = userSnapshot.data!.kelas;
          final userId = currentUser!.uid;

          return Column(
            children: [
              // --- BAGIAN TOGGLE (SESUAI GAMBAR) ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 16.0,
                ), // Tambah padding horizontal
                child: Container(
                  // Bungkus dengan Container untuk styling
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[300], // Warna background toggle
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: ToggleButtons(
                    isSelected: [
                      _selectedToggleIndex == 0,
                      _selectedToggleIndex == 1,
                    ],
                    onPressed: (index) {
                      setState(() {
                        _selectedToggleIndex = index;
                      });
                    },
                    borderRadius: BorderRadius.circular(8.0),
                    selectedBorderColor:
                        theme.colorScheme.primary, // Warna border saat terpilih
                    selectedColor:
                        theme.colorScheme.onPrimary, // Warna teks saat terpilih
                    fillColor:
                        theme.colorScheme.primary, // Warna fill saat terpilih
                    color: theme.textTheme.bodyLarge?.color?.withOpacity(
                      0.6,
                    ), // Warna teks saat tidak terpilih
                    borderColor: Colors.transparent, // Hilangkan border luar
                    renderBorder: false, // Hilangkan border antar tombol
                    constraints: const BoxConstraints(
                      minHeight: 38.0,
                      minWidth: 100.0,
                    ), // Atur ukuran minimum
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Aktif',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Selesai',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // --- AKHIR BAGIAN TOGGLE ---

              // --- BAGIAN LIST TUGAS ---
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('tugas')
                      .where('untukKelas', isEqualTo: userKelas)
                      .snapshots(),
                  builder: (context, taskSnapshot) {
                    if (taskSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CustomLoadingIndicator());
                    }
                    if (taskSnapshot.hasError) {
                      return const Center(
                        child: Text('Gagal memuat daftar tugas.'),
                      );
                    }
                    if (!taskSnapshot.hasData ||
                        taskSnapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'Belum ada tugas untuk kelas $userKelas.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      );
                    }

                    // --- PERUBAHAN: GUNAKAN FUTUREBUILDER UNTUK DATA NILAI ---
                    return FutureBuilder<
                      Map<String, List<Map<String, dynamic>>>
                    >(
                      future: _processTasks(taskSnapshot.data!.docs, userId),
                      builder: (context, processedSnapshot) {
                        if (processedSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(child: CustomLoadingIndicator());
                        }

                        if (processedSnapshot.hasError) {
                          print(
                            "Error processing tasks: ${processedSnapshot.error}",
                          );
                          return const Center(
                            child: Text('Gagal memproses data nilai tugas.'),
                          );
                        }

                        if (!processedSnapshot.hasData) {
                          return const Center(
                            child: Text('Tidak ada data tugas.'),
                          );
                        }

                        final activeTasks =
                            processedSnapshot.data!['active'] ?? [];
                        final completedTasks =
                            processedSnapshot.data!['completed'] ?? [];

                        final List<Map<String, dynamic>> tasksToShow =
                            _selectedToggleIndex == 0
                            ? activeTasks
                            : completedTasks;

                        if (tasksToShow.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                _selectedToggleIndex == 0
                                    ? 'Tidak ada tugas aktif.'
                                    : 'Tidak ada tugas yang sudah selesai.',
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          );
                        }

                        // --- PEMANGGILAN KARTU YANG DIPASTIKAN BENAR ---
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 8.0,
                          ),
                          itemCount: tasksToShow.length,
                          itemBuilder: (context, index) {
                            final taskEntry = tasksToShow[index];
                            final taskDoc =
                                taskEntry['taskDoc'] as QueryDocumentSnapshot;
                            final taskData =
                                taskEntry['taskData'] as Map<String, dynamic>;
                            final submissionData =
                                taskEntry['submissionData']
                                    as Map<String, dynamic>?;

                            if (_selectedToggleIndex == 0) {
                              // Tampilkan kartu tugas aktif
                              return _buildActiveTaskCard(
                                context,
                                taskDoc.id,
                                taskData,
                              );
                            } else {
                              // TAB SELESAI
                              return _buildGradedTaskCard(
                                context,
                                taskDoc.id,
                                taskData,
                                submissionData, // Kirim data dari map (bisa null)
                              );
                            }
                          },
                        );
                        // --- AKHIR PEMANGGILAN KARTU ---
                      },
                    );
                    // --- AKHIR PERUBAHAN FUTUREBUILDER ---
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
