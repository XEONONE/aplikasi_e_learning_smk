// lib/widgets/materi_detail_sheet.dart

import 'package:flutter/material.dart';

class MateriDetailSheet extends StatelessWidget {
  final Map<String, dynamic> materiData;

  const MateriDetailSheet({super.key, required this.materiData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // TODO: Implementasi logika untuk mendapatkan nama guru dari UID
    final String guruName = "Bpk. Ahmad Fauzi"; // Placeholder

    // Gunakan SafeArea untuk bagian atas (notch)
    // dan Padding untuk konten
    return SafeArea(
      top: true,
      bottom: false, // Biarkan modal sheet yang mengatur padding bawah
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // Penting agar sheet tidak memenuhi layar
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              materiData['judul'] ?? 'Judul Materi Tidak Tersedia',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Oleh: $guruName',
              style: theme.textTheme.titleSmall?.copyWith(
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              materiData['deskripsi'] ?? 'Deskripsi materi tidak tersedia.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[300],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Tutup sheet
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Tutup'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implementasi logika unduh materi
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mengunduh materi...')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.download, size: 20),
                        SizedBox(width: 8),
                        Text('Unduh'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Padding untuk keyboard jika muncul
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}
