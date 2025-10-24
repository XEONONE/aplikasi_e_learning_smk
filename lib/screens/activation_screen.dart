import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/custom_loading_indicator.dart';

class ActivationScreen extends StatefulWidget {
  const ActivationScreen({super.key});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nipNisnController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isVerified = false;
  String _userName = '';
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  Future<void> _verifyNipNisn() async {
    if (_nipNisnController.text.isEmpty) return;
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 3));

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_nipNisnController.text.trim())
          .get();

      if (!mounted) return;

      String errorMessage = '';
      bool isSuccess = false;

      if (!userDoc.exists) {
        errorMessage = 'NIP/NISN tidak terdaftar.';
      } else {
        final data = userDoc.data() as Map<String, dynamic>;
        if (data['uid'] != null && data['uid'] != '') {
          errorMessage = 'Akun ini sudah aktif. Silakan login.';
        } else {
          isSuccess = true;
          setState(() {
            _isVerified = true;
            _userName = data['nama'] ?? '[Nama tidak ditemukan]';
          });
        }
      }

      if (!isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Terjadi error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _activateAccount() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      await Future.delayed(const Duration(seconds: 3));

      String result = await _authService.activateAccount(
        nipNisn: _nipNisnController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      final isSuccess = result == 'Sukses';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isSuccess ? 'Aktivasi berhasil! Silakan login.' : result,
          ),
          backgroundColor: isSuccess ? Colors.green : Colors.red,
        ),
      );

      if (isSuccess) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _nipNisnController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Aktivasi Akun',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade900, Colors.black],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  // ## PERBAIKAN: Gunakan withAlpha ##
                  color: Colors.black.withAlpha((255 * 0.4).round()),
                  // ## AKHIR PERBAIKAN ##
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.purple.shade700, width: 1),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!_isVerified) ...[
                        const Text(
                          'Masukkan NIP atau NISN Anda untuk memulai proses aktivasi.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nipNisnController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'NIP / NISN',
                            labelStyle: TextStyle(color: Colors.grey.shade400),
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _isLoading
                            ? const CustomLoadingIndicator(color: Colors.white)
                            : ElevatedButton(
                                onPressed: _verifyNipNisn,
                                child: const Text('VERIFIKASI'),
                              ),
                      ],
                      if (_isVerified) ...[
                        Text(
                          'Akun untuk "$_userName" ditemukan. Silakan buat password baru Anda.',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Password Baru',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Password minimal harus 6 karakter.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_isConfirmPasswordVisible,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Konfirmasi Password',
                             prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isConfirmPasswordVisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () => setState(
                                () => _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Password tidak cocok.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        _isLoading
                            ? const CustomLoadingIndicator(color: Colors.white)
                            : ElevatedButton(
                                onPressed: _activateAccount,
                                child: const Text('AKTIFKAN AKUN'),
                              ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}