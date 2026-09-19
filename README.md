# 📚 Aplikasi E-Learning SMK

Platform pembelajaran digital berbasis mobile untuk Sekolah Menengah Kejuruan (SMK), memfasilitasi interaksi guru dan siswa secara real-time — mulai dari distribusi materi, pengumpulan tugas, hingga notifikasi dan diskusi.

Dibangun dengan **Flutter** (cross-platform Android/iOS/Web) dan **Firebase** sebagai backend, mendukung skala hingga 1000+ pengguna.

---

## ✨ Fitur Utama

### Untuk Siswa
- Login menggunakan NISN & password, dengan aktivasi akun di penggunaan pertama
- Dashboard beranda: statistik tugas aktif, materi terbaru, dan pengumuman
- Akses materi pembelajaran yang dikelompokkan per mata pelajaran
- Pengumpulan tugas dengan tenggat waktu, lengkap dengan status nilai
- Notifikasi real-time (in-app & push) untuk pengumuman dan tugas baru
- Diskusi/komentar real-time pada materi dan tugas
- Tema terang/gelap yang bisa diubah sendiri

### Untuk Guru
- Dashboard ringkasan pengumuman dan aktivitas kelas
- Upload, edit, dan hapus materi (dibatasi sesuai kelas yang diampu)
- Membuat, mengedit, dan menilai tugas siswa
- Membuat pengumuman untuk satu atau beberapa kelas sekaligus
- Melihat dan menilai daftar pengumpulan tugas siswa beserta komentar

---

## 🛠️ Teknologi

| Kategori | Teknologi |
|---|---|
| Frontend | Flutter (Dart) — Material Design 3 |
| Backend | Firebase (Firestore, Authentication, Cloud Messaging, Storage) |
| Realtime | `StreamBuilder` untuk update data langsung dari Firestore |
| Push Notification | Firebase Cloud Messaging + Cloud Functions (Node.js) |
| Server Tambahan | Node.js push-server (deploy di Railway) |
| Penyimpanan Lokal | SharedPreferences (preferensi tema) |
| Integrasi Eksternal | Google Drive (link materi), URL launcher |

---

## 📁 Struktur Proyek

```
lib/
├── main.dart                  # Entry point aplikasi, inisialisasi Firebase & tema
├── auth_gate.dart              # Routing otomatis berdasarkan role (guru/siswa)
├── firebase_options.dart       # Konfigurasi Firebase
├── models/                     # Model data (User, Materi)
├── screens/                    # 24 halaman UI (dashboard, materi, tugas, dll.)
├── services/                   # Auth service & notification service
└── widgets/                    # Komponen UI reusable (card, comment section, dll.)

functions/        # Firebase Cloud Functions (trigger push notification)
push-server/      # Server Node.js untuk pengiriman notifikasi manual
dataconnect/      # Skema Firebase Data Connect (GraphQL)
```

---

## 🚀 Menjalankan Proyek

### Prasyarat
- Flutter SDK `^3.9.2`
- Akun Firebase dengan project yang sudah dikonfigurasi

### Langkah instalasi
```bash
git clone https://github.com/XEONONE/aplikasi_e_learning_smk.git
cd aplikasi_e_learning_smk
flutter pub get
flutter run
```

Pastikan `firebase_options.dart` sudah sesuai dengan konfigurasi project Firebase kamu sendiri (jalankan `flutterfire configure` jika belum ada).

---

## ✅ Pengujian

- Unit test: cakupan ±92% (auth service dan model data)
- Integration test: ±95%
- User Acceptance Testing (UAT): skor SUS 82.5 — menunjukkan tingkat usability yang tinggi

---

## 👥 Tim Pengembang

Dikembangkan sebagai proyek Praktik Kerja Lapangan (PKL) — Program Studi Informatika, Universitas Bina Sarana Informatika.

---

## 📄 Lisensi

Proyek ini dibuat untuk keperluan akademik (tugas PKL) dan bersifat privat/non-komersial kecuali dinyatakan lain oleh pemilik libary.
