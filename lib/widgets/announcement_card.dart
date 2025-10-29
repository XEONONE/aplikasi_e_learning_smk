// lib/widgets/announcement_card.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_e_learning_smk/services/auth_service.dart';

class AnnouncementCard extends StatelessWidget {
  final String judul;
  final String isi;

  // ================== PERUBAHAN DI SINI ==================
  // Mengubah tipe data dari 'dynamic' menjadi 'List<String>'
  final List<String> untukKelas;
  // =======================================================

  final Timestamp dibuatPada;
  final String dibuatOlehUid;
  final bool isGuruView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AnnouncementCard({
    super.key,
    required this.judul,
    required this.isi,
    required this.untukKelas,
    required this.dibuatPada,
    required this.dibuatOlehUid,
    this.isGuruView = false,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = AuthService();
    final bool isOwner = authService.getCurrentUser()?.uid == dibuatOlehUid;

    // Format tanggal
    final String tanggalFormatted = DateFormat(
      'd MMMM y, HH:mm',
      'id_ID',
    ).format(dibuatPada.toDate());

    // ================== PERUBAHAN DI SINI ==================
    // Menggabungkan List menjadi satu String untuk ditampilkan
    final String targetKelas = untukKelas.join(', ');
    // =======================================================

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 2.0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Judul dan Tombol Aksi (jika guru)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    judul,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isGuruView && isOwner)
                  MenuAnchor(
                    builder:
                        (
                          BuildContext context,
                          MenuController controller,
                          Widget? child,
                        ) {
                          return IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.more_vert,
                              color: theme.iconTheme.color,
                            ),
                            onPressed: () {
                              if (controller.isOpen) {
                                controller.close();
                              } else {
                                controller.open();
                              }
                            },
                          );
                        },
                    menuChildren: <Widget>[
                      MenuItemButton(
                        leadingIcon: const Icon(Icons.edit_outlined),
                        onPressed: onEdit,
                        child: const Text('Ubah'),
                      ),
                      MenuItemButton(
                        leadingIcon: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                        ),
                        onPressed: onDelete,
                        child: Text(
                          'Hapus',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Isi Pengumuman
            Text(isi, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Divider(color: theme.dividerColor.withOpacity(0.5)),
            const SizedBox(height: 8),
            // Footer: Target Kelas dan Waktu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          // ================== PERUBAHAN DI SINI ==================
                          // Menampilkan string yang sudah digabung
                          'Untuk: $targetKelas',
                          // =======================================================
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  tanggalFormatted,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
