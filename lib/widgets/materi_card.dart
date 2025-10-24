// Lokasi: lib/widgets/materi_card.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MateriCard extends StatelessWidget {
  final String judul;
  final String deskripsi;
  final String? fileUrl;
  final String guruNama; // Tambahkan ini jika ada
  final String tanggalUpload; // Tambahkan ini jika ada
  final bool isGuruView;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const MateriCard({
    super.key,
    required this.judul,
    required this.deskripsi,
    this.fileUrl,
    required this.guruNama, // Wajib diisi
    required this.tanggalUpload, // Wajib diisi
    this.isGuruView = false,
    this.onEdit,
    this.onDelete,
  });

  Future<void> _launchUrl(BuildContext context) async {
    if (fileUrl != null && fileUrl!.isNotEmpty) {
      final Uri url = Uri.parse(fileUrl!);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tidak bisa membuka link $url')),
          );
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Tidak ada link materi.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Ambil tema

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 6.0,
      ), // Beri margin
      // Style card (elevation, shape, color) diambil dari tema
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0, // Tambah padding vertikal
        ),
        leading: Icon(
          Icons.description_outlined,
          color: theme.colorScheme.secondary, // Warna ikon sekunder
        ),
        title: Text(
          judul,
          // Gunakan style dari tema (warna otomatis)
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Padding(
          // Beri padding atas untuk subtitle
          padding: const EdgeInsets.only(top: 4.0),
          child: Column(
            // Gunakan Column untuk guru & tanggal
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$guruNama • $tanggalUpload', // Tampilkan guru & tanggal
                // Gunakan style bodySmall dari tema (redup)
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                ),
              ),
              const SizedBox(
                height: 4,
              ), // Jarak antara guru/tanggal dan deskripsi
              Text(
                deskripsi,
                // Gunakan style bodyMedium dari tema (redup)
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        trailing: isGuruView
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: theme.colorScheme.secondary,
                      ),
                      tooltip: 'Edit Materi',
                      onPressed: onEdit,
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: theme.colorScheme.error,
                      ),
                      tooltip: 'Hapus Materi',
                      onPressed: onDelete,
                    ),
                ],
              )
            : (fileUrl != null && fileUrl!.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.download_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      tooltip: 'Download Materi',
                      onPressed: () => _launchUrl(context),
                    )
                  : null),
        onTap: (fileUrl != null && fileUrl!.isNotEmpty && !isGuruView)
            ? () => _launchUrl(context)
            : null, // Aksi tap hanya jika ada URL & bukan guru
      ),
    );
  }
}
