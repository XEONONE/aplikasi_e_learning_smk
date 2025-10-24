// lib/widgets/announcement_card.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnnouncementCard extends StatefulWidget {
  final String judul;
  final String isi;
  final Timestamp dibuatPada;
  final String dibuatOlehUid;
  final String untukKelas;

  const AnnouncementCard({
    super.key,
    required this.judul,
    required this.isi,
    required this.dibuatPada,
    required this.dibuatOlehUid,
    required this.untukKelas,
  });

  @override
  State<AnnouncementCard> createState() => _AnnouncementCardState();
}

class _AnnouncementCardState extends State<AnnouncementCard> {
  late Future<String> _authorNameFuture;

  @override
  void initState() {
    super.initState();
    _authorNameFuture = _getAuthorName(widget.dibuatOlehUid);
  }

  Future<String> _getAuthorName(String uid) async {
    try {
      var userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        return userDoc.data()?['nama'] ?? 'Admin';
      } else {
        var userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: uid)
            .limit(1)
            .get();
        if (userQuery.docs.isNotEmpty) {
          return userQuery.docs.first.data()['nama'] ?? 'Admin';
        }
      }
      return 'Admin';
    } catch (e) {
      print('Error getting author name: $e');
      return 'Admin';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Tentukan warna teks subtitle berdasarkan tema
    final subtitleColor = theme.textTheme.bodySmall?.color?.withOpacity(0.7);

    String formattedDate = DateFormat(
      'd MMMM yyyy, HH:mm',
      'id_ID',
    ).format(widget.dibuatPada.toDate());

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      // Style Card diambil dari tema
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.judul,
              // --- PERBAIKAN: Ambil warna dari tema ---
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                // color: Colors.white, <-- HAPUS
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<String>(
              future: _authorNameFuture,
              builder: (context, snapshot) {
                String authorName =
                    snapshot.connectionState == ConnectionState.done &&
                        snapshot.hasData
                    ? snapshot.data!
                    : 'Memuat...';
                return Text(
                  'Oleh: $authorName • $formattedDate',
                  // --- PERBAIKAN: Gunakan subtitleColor ---
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: subtitleColor,
                    // color: Colors.grey[400], <-- HAPUS
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              'Untuk: ${widget.untukKelas}',
              // --- PERBAIKAN: Gunakan subtitleColor ---
              style: theme.textTheme.bodySmall?.copyWith(
                color: subtitleColor,
                // color: Colors.grey[400], <-- HAPUS
              ),
            ),
            const Divider(height: 24),
            Text(
              widget.isi,
              // --- PERBAIKAN: Ambil warna dari tema ---
              style: theme.textTheme.bodyMedium?.copyWith(
                // color: Colors.grey[300], <-- HAPUS
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
