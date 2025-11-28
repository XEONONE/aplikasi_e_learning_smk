// lib/screens/student_home_screen.dart
import 'package:aplikasi_e_learning_smk/models/user_model.dart';
import 'package:aplikasi_e_learning_smk/services/auth_service.dart';
import 'package:aplikasi_e_learning_smk/widgets/announcement_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_e_learning_smk/widgets/custom_loading_indicator.dart';
import 'package:aplikasi_e_learning_smk/screens/student_materi_list_screen.dart';
// --- IMPORT BARU UNTUK NOTIFIKASI ---
import 'package:aplikasi_e_learning_smk/screens/notification_screen.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
// --- AKHIR IMPORT BARU ---

class StudentHomeScreen extends StatefulWidget {
  final String kelasId;
  const StudentHomeScreen({super.key, required this.kelasId});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final AuthService _authService = AuthService();
  late Future<UserModel?> _userFuture;

  // --- TAMBAHAN STATE UNTUK NOTIFIKASI ---
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  String? _userKelas;
  // --- AKHIR TAMBAHAN STATE ---

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchStudentData();
    _fetchUserKelas(); // Panggil fungsi untuk mengambil kelas
    Intl.defaultLocale = 'id_ID'; // Pastikan locale diatur untuk format tanggal
  }

  // --- MODIFIKASI FUNGSI INI ---
  Future<UserModel?> _fetchStudentData() async {
    String? studentId = _authService.getCurrentUser()?.uid;
    if (studentId != null) {
      UserModel? studentData = await _authService.getUserData(studentId);
      // Simpan kelas di state saat data didapat
      if (mounted && studentData != null) {
        setState(() {
          _userKelas = studentData.kelas;
        });
      }
      return studentData;
    }
    return null;
  }

  // --- FUNGSI BARU UNTUK FALLBACK JIKA _fetchStudentData GAGAL ---
  Future<void> _fetchUserKelas() async {
    if (_userKelas != null) return; // Sudah didapat dari _fetchStudentData
    if (_currentUser != null) {
      final userData = await _authService.getUserData(_currentUser.uid);
      if (mounted) {
        setState(() {
          _userKelas = userData?.kelas;
        });
      }
    }
  }
  // --- AKHIR FUNGSI BARU ---

  // --- WIDGET BARU UNTUK IKON NOTIFIKASI ---
  Widget _buildNotificationIcon() {
    // Tampilkan ikon biasa jika user atau kelas belum terload
    if (_currentUser == null || _userKelas == null) {
      return IconButton(
        icon: Icon(
          Icons.notifications_none_outlined,
          color: Theme.of(context).iconTheme.color,
        ),
        tooltip: 'Notifikasi',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationScreen()),
          );
        },
      );
    }

    // Gunakan StreamBuilder untuk mengecek notifikasi baru
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where(
            'targetAudience',
            arrayContainsAny: [
              _currentUser.uid,
              'kelas_${_userKelas!}',
              'all_users',
            ],
          )
          .where('isRead', isEqualTo: false) // Hanya cek yang belum dibaca
          .limit(1) // Cukup 1 saja untuk menunjukkan badge
          .snapshots(),
      builder: (context, snapshot) {
        bool hasNewNotification = false;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          hasNewNotification = true;
        }

        // Widget ikon dasar
        Widget iconButton = IconButton(
          icon: Icon(
            Icons.notifications_none_outlined,
            color: Theme.of(context).iconTheme.color,
          ),
          tooltip: 'Notifikasi',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationScreen(),
              ),
            );
          },
        );

        // Jika ada notifikasi baru, bungkus dengan Stack dan Badge
        if (hasNewNotification) {
          return Stack(
            alignment: Alignment.center,
            children: [
              iconButton,
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 1.5,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 10,
                    minHeight: 10,
                  ),
                ),
              ),
            ],
          );
        }

        // Kembalikan ikon biasa jika tidak ada notifikasi baru
        return iconButton;
      },
    );
  }
  // --- AKHIR WIDGET BARU ---

  @override
  Widget build(BuildContext context) {
    // --- PERUBAHAN UTAMA: TAMBAHKAN APPBAR ---
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Sembunyikan tombol back
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          // Judul bisa opsional
          'Beranda',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // --- GUNAKAN WIDGET BARU DI SINI ---
          _buildNotificationIcon(),
          // --- AKHIR PERUBAHAN APPBAR ---
          const SizedBox(width: 8), // Sedikit jarak
        ],
      ),
      body: FutureBuilder<UserModel?>(
        future: _userFuture,
        builder: (context, snapshot) {
          // ... (sisa kode FutureBuilder tetap sama) ...
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomLoadingIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            debugPrint(
              "Error fetching user data: ${snapshot.error}",
            ); // Ganti print
            return const Center(
              child: Text('Gagal memuat data siswa. Coba lagi nanti.'),
            );
          }

          final user = snapshot.data!;
          // Pastikan _userKelas di-update jika belum
          if (_userKelas == null && user.kelas != null) {
            _userKelas = user.kelas;
          }
          final userKelas = user.kelas; // Simpan kelas user

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.indigo,
                        const Color(
                          0xFF7C3AED,
                        ).withAlpha((255 * 0.8).round()), // Ganti withOpacity
                      ],
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(16.0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withAlpha(
                          (255 * 0.3).round(),
                        ), // Ganti withOpacity
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat Datang, ${user.nama}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kelas: ${userKelas ?? 'Belum ada kelas'}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Semangatmu hari ini adalah kunci kesuksesan di masa depan!',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Stats Grid (DINAMIS DENGAN PERBAIKAN)
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16.0,
                  mainAxisSpacing: 16.0,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  // PERBAIKAN OVERFLOW: Rasio diubah agar card lebih tinggi
                  childAspectRatio: 1.5,
                  children: [
                    // --- KARTU STAT MATERI (DINAMIS) ---
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('materi')
                          .where('untukKelas', isEqualTo: userKelas)
                          .snapshots(),
                      builder: (context, snapshot) {
                        String materiCount = '...';
                        if (snapshot.hasData) {
                          // ======================================================
                          // INI AKAN MENGHASILKAN "0" JIKA TIDAK ADA DOKUMEN
                          materiCount = snapshot.data!.docs.length.toString();
                          // ======================================================
                        } else if (snapshot.hasError) {
                          materiCount = 'Err';
                        }
                        return _buildStatCard(
                          'Total Materi',
                          materiCount, // Mengirim "0" (atau jumlah lain) ke fungsi build
                          Icons.book_outlined,
                          Colors.green.shade400,
                        );
                      },
                    ),
                    // --- KARTU STAT TUGAS (DINAMIS) ---
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('tugas')
                          .where('untukKelas', isEqualTo: userKelas)
                          .snapshots(),
                      builder: (context, snapshot) {
                        String tugasCount = '...';
                        if (snapshot.hasData) {
                          // ======================================================
                          // INI AKAN MENGHASILKAN "0" JIKA TIDAK ADA DOKUMEN
                          tugasCount = snapshot.data!.docs.length.toString();
                          // ======================================================
                        } else if (snapshot.hasError) {
                          tugasCount = 'Err';
                        }
                        return _buildStatCard(
                          'Total Tugas',
                          tugasCount, // Mengirim "0" (atau jumlah lain) ke fungsi build
                          Icons.assignment_outlined,
                          Colors.orange.shade400,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 32), // Tambah spasi
                // Mata Pelajaran Section (DINAMIS)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Mata Pelajaran',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const StudentMateriListScreen(),
                          ),
                        );
                      },
                      child: const Text('Lihat Semua'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSubjectSection(userKelas),
                const SizedBox(height: 32),

                // BAGIAN PENGUMUMAN
                Text(
                  'Pengumuman Terbaru',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildAnnouncementSection(
                  userKelas,
                ), // Panggil fungsi pengumuman
                const SizedBox(height: 80), // Jarak di akhir
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGET HELPER ---

  // ======================================================
  // ===== FUNGSI STAT CARD (YANG SUDAH 100% BENAR) ====
  // ======================================================
  Widget _buildStatCard(
    String title,
    String value, // <-- Variabel ini akan menerima "0"
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    final subtitleColor = theme.textTheme.bodySmall?.color?.withAlpha(
      (255 * 0.7).round(),
    ); // Ganti withOpacity

    return Card(
      color: theme.cardColor,
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        // PERBAIKAN OVERFLOW: Padding dikecilkan
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          // Ditambahkan untuk keamanan
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title, // Ini akan menampilkan "Total Materi"
                    // PERBAIKAN OVERFLOW: Font dikecilkan
                    style: TextStyle(fontSize: 13, color: subtitleColor),
                  ),
                  // PERBAIKAN OVERFLOW: Ikon dikecilkan
                  Icon(icon, size: 24, color: color),
                ],
              ),
              // PERBAIKAN OVERFLOW: Spasi dikurangi
              const SizedBox(height: 4),
              Text(
                // ==================================================
                value, // <-- INI YANG BENAR: Menampilkan variabel 'value'
                // ==================================================
                style: TextStyle(
                  // PERBAIKAN OVERFLOW: Font dikecilkan
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  // ============================================
  // ========= AKHIR FUNGSI STAT CARD ===========
  // ============================================

  Widget _buildSubjectCard(
    String subject,
    String progress,
    double? progressValue,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context); // Ambil theme
    return Card(
      color: theme.cardColor, // Gunakan cardColor
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withAlpha(
                  (255 * 0.1).round(),
                ), // Ganti withOpacity
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    style: TextStyle(
                      // Gunakan TextStyle eksplisit
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: theme
                          .textTheme
                          .bodyLarge
                          ?.color, // Warna teks dari theme
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    progress,
                    style: TextStyle(
                      fontSize: 12,
                      // Gunakan warna teks sekunder dari theme
                      color: theme.textTheme.bodySmall?.color?.withAlpha(
                        (255 * 0.7).round(),
                      ),
                    ),
                  ),
                  if (progressValue != null) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progressValue,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- METHOD BARU UNTUK BAGIAN MATA PELAJARAN (DINAMIS) ---
  Widget _buildSubjectSection(String? userKelas) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('materi')
          .where('untukKelas', isEqualTo: userKelas)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CustomLoadingIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text('Belum ada mata pelajaran.'),
            ),
          );
        }

        final subjects = <String>{};
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final subject = data['mataPelajaran'] as String?;
          if (subject != null && subject.isNotEmpty) {
            subjects.add(subject);
          }
        }

        if (subjects.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text('Belum ada mata pelajaran.'),
            ),
          );
        }

        final subjectStyles = {
          'Informatika': {
            'icon': Icons.laptop_chromebook_outlined,
            'color': Colors.blue.shade400,
          },
          'Matematika': {
            'icon': Icons.calculate_outlined,
            'color': Colors.teal.shade400,
          },
          'Fisika': {
            'icon': Icons.science_outlined,
            'color': Colors.purple.shade400,
          },
          'Default': {
            'icon': Icons.subject_outlined,
            'color': Colors.grey.shade400,
          },
        };

        const int maxSubjectsToShow = 3;
        final subjectsToShow = subjects.take(maxSubjectsToShow).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: subjectsToShow.length,
          itemBuilder: (context, index) {
            final subjectName = subjectsToShow[index];
            final style =
                subjectStyles[subjectName] ?? subjectStyles['Default']!;

            final moduleCount = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return (data['mataPelajaran'] as String?) == subjectName;
            }).length;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildSubjectCard(
                subjectName,
                '$moduleCount Modul',
                null,
                style['icon'] as IconData,
                style['color'] as Color,
              ),
            );
          },
        );
      },
    );
  }

  // --- METHOD BARU UNTUK BAGIAN PENGUMUMAN ---
  Widget _buildAnnouncementSection(String? userKelas) {
    final theme = Theme.of(context); // Ambil theme di sini
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pengumuman')
          // ================== PERUBAHAN QUERY UTAMA ==================
          .where(
            'untukKelas',
            // Gunakan arrayContainsAny
            arrayContainsAny: [userKelas ?? '', 'Semua Kelas'],
          )
          // =========================================================
          .orderBy('dibuatPada', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CustomLoadingIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'Belum ada pengumuman untuk kelas ${userKelas ?? 'Anda'}.',
              style: TextStyle(
                // Gunakan warna dari theme
                color: theme.textTheme.bodySmall?.color?.withAlpha(
                  (255 * 0.7).round(),
                ),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          debugPrint(
            "Error loading announcements: ${snapshot.error}",
          ); // Ganti print
          return const Center(
            child: Text(
              'Gagal memuat pengumuman.',
              style: TextStyle(color: Colors.red),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;

            Timestamp timestamp = data['dibuatPada'] ?? Timestamp.now();

            // ================== LOGIKA KONVERSI DATA ==================
            // Sama seperti di guru_home_screen
            List<String> untukKelasList;
            final dataKelas = data['untukKelas'];

            if (dataKelas is String) {
              // Jika data lama (String), ubah jadi List
              untukKelasList = [dataKelas];
            } else if (dataKelas is List) {
              // Jika data baru (List), pastikan tipenya List<String>
              untukKelasList = List<String>.from(
                dataKelas.map((e) => e.toString()),
              );
            } else {
              // Fallback
              untukKelasList = ['Tidak diketahui'];
            }
            // ==========================================================

            // ================== PERBAIKAN UTAMA DI SINI ==================
            // Mengganti pemanggilan lama dengan parameter 'announcement'
            return AnnouncementCard(announcement: doc);
            // ================== AKHIR PERBAIKAN ==================
          },
        );
      },
    );
  }
}
