import 'package:flutter/material.dart';
import 'package:bookshelf/app/theme.dart';
import 'package:bookshelf/views/auth/register_page.dart';
import 'package:bookshelf/views/auth/widgets/auth_text_field.dart';
import 'package:bookshelf/services/api_service.dart';
import 'package:bookshelf/services/auth_service.dart';
import 'package:bookshelf/services/isar_db_service.dart';
import 'package:bookshelf/views/home/home_page.dart';

/// Halaman Login (Selamat Datang).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  final _apiService = ApiService();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handler tombol "Masuk" — panggil API login + simpan JWT.
  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final username = _usernameController.text.trim();
      final token = await _apiService.login(username, _passwordController.text);

      // Simpan session JWT + username
      await AuthService.saveSession(token, username);

      // Fetch books dari server & simpan ke IsarDB (Offline caching awal)
      try {
        final books = await _apiService.getBooks(token);
        await IsarDbService().saveBooks(books, username);
      } catch (_) {
        // Abaikan jika gagal (bisa diambil nanti di HomePage)
      }

      if (!mounted) return;

      // Navigasi ke HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomePage(username: username, token: token),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Login gagal: ${_getErrorMessage(e)}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Ambil pesan error yang user-friendly.
  String _getErrorMessage(dynamic error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('username')) return 'Username salah';
    if (msg.contains('password')) return 'Password salah';
    if (msg.contains('unauthorized')) return 'Username atau password salah';
    return 'Terjadi kesalahan, coba lagi';
  }

  /// Navigasi ke halaman Register
  void _navigateToRegister() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RegisterPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // Logo & nama aplikasi
                _buildHeader(),
                const SizedBox(height: 32),

                // Judul & subtitle
                Text(
                  'Selamat datang!',
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Silakan masuk untuk mengakses koleksi buku '
                  'dan pantau progres bacaan Anda.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),

                // Indikator status koneksi (placeholder)
                _buildConnectionIndicator(),
                const SizedBox(height: 32),

                // Form fields
                _buildUsernameField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                const SizedBox(height: 32),

                // Tombol Masuk
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Masuk'),
                ),
                const SizedBox(height: 24),

                // Link ke halaman Register
                _buildRegisterLink(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Header: ikon buku + nama aplikasi
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFFE53935),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.menu_book_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Bookshelf',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  /// Indikator koneksi — sesuai desain ada badge "Anda sedang offline/online".
  Widget _buildConnectionIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.offline.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.offline),
          const SizedBox(width: 6),
          Text(
            'Anda sedang offline',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.offline,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Field Username
  Widget _buildUsernameField() {
    return AuthTextField(
      controller: _usernameController,
      hintText: 'Masukkan username',
      labelText: 'Username',
      prefixIcon: Icons.person_outline,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Username wajib diisi';
        }
        return null;
      },
    );
  }

  /// Field Password dengan toggle show/hide
  Widget _buildPasswordField() {
    return AuthTextField(
      controller: _passwordController,
      hintText: 'Masukkan password',
      labelText: 'Password',
      prefixIcon: Icons.lock_outline,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_off : Icons.visibility,
          size: 22,
        ),
        onPressed: () {
          setState(() {
            _obscurePassword = !_obscurePassword;
          });
        },
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Password wajib diisi';
        }
        return null;
      },
    );
  }

  /// Link navigasi ke halaman Register
  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Belum punya akun? ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        GestureDetector(
          onTap: _navigateToRegister,
          child: Text(
            'Daftar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
