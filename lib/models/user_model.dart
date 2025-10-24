class UserModel {
  final String uid;
  final String id;
  final String nama;
  final String email;
  final String role;
  final String? kelas; // Untuk siswa
  final List<String>? mengajarKelas; // BARU: Untuk guru

  UserModel({
    required this.uid,
    required this.id,
    required this.nama,
    required this.email,
    required this.role,
    this.kelas,
    this.mengajarKelas, // BARU
  });

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      id: data['id'] ?? '',
      nama: data['nama'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? '',
      kelas: data['kelas'],
      // BARU: Konversi dari List<dynamic> ke List<String>
      mengajarKelas: data['mengajarKelas'] != null
          ? List<String>.from(data['mengajarKelas'])
          : null,
    );
  }
}