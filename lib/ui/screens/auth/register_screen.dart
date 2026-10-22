import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:annuur_mobile/core/theme/app_theme.dart';
import 'package:annuur_mobile/data/repositories/auth_repository.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await AuthRepository.register(
        name: _nameController.text.trim(),
        whatsapp: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (!mounted) return;

      // Tampilkan dialog informasi peninjauan pengurus
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.hourglass_top_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Pendaftaran Diajukan'),
            ],
          ),
          content: Text(
            res['message'] ??
                'Data Anda telah diterima. Akun akan ditinjau dan diaktifkan oleh pengurus panti asuhan.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.pop(); // Kembali ke halaman Login
              },
              child: const Text('Kembali ke Halaman Masuk'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Daftar Donatur Tetap')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    _error!,
                    style: AppTextStyles.caption.copyWith(color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text('Nama Lengkap', style: AppTextStyles.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(hintText: 'Contoh: H. Ahmad Fauzi', prefixIcon: Icon(Icons.person_outline)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              Text('Nomor WhatsApp', style: AppTextStyles.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '081234567890', prefixIcon: Icon(Icons.phone_outlined)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Nomor WhatsApp wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              Text('Email Aktif', style: AppTextStyles.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'email@anda.com', prefixIcon: Icon(Icons.email_outlined)),
                validator: (v) => v == null || !v.contains('@') ? 'Format email tidak valid' : null,
              ),
              const SizedBox(height: 16),
              Text('Kata Sandi', style: AppTextStyles.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Minimal 8 karakter',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) => v == null || v.length < 8 ? 'Minimal 8 karakter' : null,
              ),
              const SizedBox(height: 16),
              Text('Konfirmasi Kata Sandi', style: AppTextStyles.labelLarge),
              const SizedBox(height: 6),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscurePassword,
                decoration: const InputDecoration(hintText: 'Ulangi kata sandi', prefixIcon: Icon(Icons.lock_reset)),
                validator: (v) => v != _passwordController.text ? 'Konfirmasi kata sandi tidak cocok' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Ajukan Pendaftaran'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
