import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnnouncementCard extends StatefulWidget {
  final DocumentSnapshot announcement;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isGuru;

  const AnnouncementCard({
    Key? key,
    required this.announcement,
    this.onEdit,
    this.onDelete,
    this.isGuru = false,
  }) : super(key: key);

  @override
  _AnnouncementCardState createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<AnnouncementCard> {
  bool _isExpanded = false;
  bool _isTextLong = false;
  late String _fullText;
  late String _shortText;
  final int _maxChars = 100; // Tentukan batas karakter untuk disingkat

  @override
  void initState() {
    super.initState();

    _fullText =
        (widget.announcement.data() as Map<String, dynamic>)['isi'] ??
        'Tidak ada isi';

    // Periksa apakah teks lebih panjang dari batas
    if (_fullText.length > _maxChars) {
      _isTextLong = true;
      _shortText = _fullText.substring(0, _maxChars) + '...';
    } else {
      _isTextLong = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data =
        widget.announcement.data() as Map<String, dynamic>;
    String title = data['judul'] ?? 'Tanpa Judul';
    Timestamp timestamp =
        data['dibuatPada'] ?? Timestamp.now(); // Perbaikan nama field
    String formattedDate = DateFormat(
      'dd MMM yyyy, HH:mm',
    ).format(timestamp.toDate());

    // --- TAMBAHAN LOGIKA UNTUK 'UNTUK KELAS' ---
    List<String> untukKelasList = [];
    final dataKelas = data['untukKelas'];

    if (dataKelas is String) {
      // Jika data lama (String), ubah jadi List
      untukKelasList = [dataKelas];
    } else if (dataKelas is List) {
      // Jika data baru (List), pastikan tipenya List<String>
      untukKelasList = List<String>.from(dataKelas.map((e) => e.toString()));
    } else {
      // Fallback
      untukKelasList = ['Tidak diketahui'];
    }
    String untukKelasText = untukKelasList.join(', ');
    // --- AKHIR TAMBAHAN LOGIKA ---

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 4), // Kurangi spasi sedikit
            // --- WIDGET 'UNTUK KELAS' YANG DITAMBAHKAN KEMBALI ---
            Text(
              'Untuk Kelas: $untukKelasText',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),

            // --- AKHIR WIDGET TAMBAHAN ---
            const SizedBox(height: 8),

            // Widget untuk menampilkan teks yang bisa diperluas
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isTextLong
                      ? (_isExpanded ? _fullText : _shortText)
                      : _fullText,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
                // Tampilkan tombol "Baca selengkapnya" only if text is long
                if (_isTextLong)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        _isExpanded ? 'Tutup' : 'Baca selengkapnya...',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                if (widget.isGuru)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.green),
                        onPressed: widget.onEdit,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: widget.onDelete,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
