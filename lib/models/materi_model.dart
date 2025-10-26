// Lokasi: lib/models/materi_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class MateriModel {
  final String id;
  final String judul;
  final String deskripsi;
  final String fileUrl;
  final String? fileName;
  final Timestamp uploadedAt;
  final String mapel; // Menambahkan mapel, karena sepertinya penting
  final List<String>? kelas; // Menambahkan kelas

  MateriModel({
    required this.id,
    required this.judul,
    required this.deskripsi,
    required this.fileUrl,
    this.fileName,
    required this.uploadedAt,
    required this.mapel,
    this.kelas,
  });

  // Factory constructor untuk membuat instance dari Firestore document
  factory MateriModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Konversi 'kelas' dari List<dynamic> ke List<String>
    List<String>? listKelas;
    if (data['kelas'] != null) {
      listKelas = List<String>.from(data['kelas']);
    }

    return MateriModel(
      id: doc.id, // Menggunakan ID dokumen
      judul: data['judul'] ?? '',
      deskripsi: data['deskripsi'] ?? '',
      fileUrl: data['fileUrl'] ?? '',
      fileName: data['fileName'], // Bisa null
      uploadedAt: data['uploadedAt'] ?? Timestamp.now(),
      mapel: data['mapel'] ?? 'Umum',
      kelas: listKelas,
    );
  }
}