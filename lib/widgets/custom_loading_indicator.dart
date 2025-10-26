// lib/widgets/custom_loading_indicator.dart

import 'package:flutter/material.dart';

class CustomLoadingIndicator extends StatefulWidget {
  final Color color;
  final double strokeWidth;
  final Duration duration;

  const CustomLoadingIndicator({
    super.key,
    this.color = Colors.deepPurple,
    this.strokeWidth = 4.0,
    this.duration = const Duration(seconds: 2), // Durasi default 2 detik
  });

  @override
  State<CustomLoadingIndicator> createState() => _CustomLoadingIndicatorState();
}

// Gunakan "with SingleTickerProviderStateMixin" untuk mengontrol animasi
class _CustomLoadingIndicatorState extends State<CustomLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller animasi dengan durasi dari widget
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..forward(); // Langsung jalankan animasi dari awal
  }

  @override
  void dispose() {
    _controller.dispose(); // Hentikan controller saat widget tidak digunakan
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      // AnimatedBuilder akan 'mendengarkan' perubahan dari controller
      // dan membangun ulang widget setiap kali nilainya berubah
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SizedBox(
            width: 40,
            height: 40,
            // CircularProgressIndicator dengan 'value' akan menunjukkan progress
            // dari 0.0 (0%) hingga 1.0 (100%)
            child: CircularProgressIndicator(
              value: _controller.value,
              valueColor: AlwaysStoppedAnimation<Color>(widget.color),
              strokeWidth: widget.strokeWidth,
            ),
          );
        },
      ),
    );
  }
}