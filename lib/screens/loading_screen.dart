// lib/screens/loading_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:aplikasi_e_learning_smk/widgets/custom_loading_indicator.dart';

class LoadingScreen extends StatefulWidget {
  // Widget ini akan menerima halaman tujuan sebagai parameter
  final Widget destinationPage;

  const LoadingScreen({super.key, required this.destinationPage});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToDestination();
  }

  void _navigateToDestination() async {
    // Tunggu selama 2 detik
    await Future.delayed(const Duration(seconds: 2));

    // Setelah 2 detik, ganti halaman loading ini dengan halaman tujuan
    // Kita gunakan pushReplacement agar pengguna tidak bisa kembali ke halaman loading
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => widget.destinationPage),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Selama menunggu, tampilkan loading indicator di tengah layar
    return const Scaffold(
      body: Center(
        child: CustomLoadingIndicator(),
      ),
    );
  }
}