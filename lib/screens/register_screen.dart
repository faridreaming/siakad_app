import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  bool _loading = false;

  final _namaCtrl = TextEditingController();
  final _nimCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _prodiCtrl = TextEditingController();
  String _angkatan = '2024';

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _authService.register(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        nama: _namaCtrl.text.trim(),
        nim: _nimCtrl.text.trim(),
        prodi: _prodiCtrl.text.trim(),
        angkatan: _angkatan,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registrasi gagal: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _field(_namaCtrl, 'Nama Lengkap', Icons.person_outlined),
              const SizedBox(height: 12),
              _field(_nimCtrl, 'NIM', Icons.badge_outlined),
              const SizedBox(height: 12),
              _field(_prodiCtrl, 'Program Studi', Icons.school_outlined),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _angkatan,
                decoration: const InputDecoration(
                  labelText: 'Angkatan',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                items: ['2021', '2022', '2023', '2024', '2025']
                    .map((y) => DropdownMenuItem(value: y, child: Text(y)))
                    .toList(),
                onChanged: (v) => setState(() => _angkatan = v!),
              ),
              const SizedBox(height: 12),
              _field(
                _emailCtrl,
                'Email',
                Icons.email_outlined,
                type: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outlined),
                ),
                validator: (v) => v!.length < 6 ? 'Min 6 karakter' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loading ? null : _register,
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Daftar Sekarang'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: (v) => v!.isEmpty ? '$label wajib diisi' : null,
    );
  }
}
