import 'package:flutter/material.dart';
import 'package:bookshelf/app/theme.dart';
import 'package:bookshelf/services/api_service.dart';
import 'package:bookshelf/services/auth_service.dart';
import 'package:bookshelf/views/auth/login_page.dart';

/// Halaman Profil & Sinkronisasi.
/// Menampilkan avatar user, status online/offline, info sync terakhir,
/// dan tombol sinkronisasi data ke server.
class ProfilePage extends StatefulWidget {
  final String username;
  final String token;

  const ProfilePage({super.key, this.username = 'User', required this.token});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isSyncing = false;
  String? _lastSyncTime;
  final _apiService = ApiService();

  /// Sinkronisasi data ke server (fetch ulang buku dari server).
  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);

    try {
      // Fetch buku dari server untuk memastikan data ter-sync
      await _apiService.getBooks(widget.token);

      if (!mounted) return;

      final now = DateTime.now();
      final formatted =
          '${now.day} ${_monthName(now.month)} ${now.year}, '
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}';

      setState(() {
        _lastSyncTime = formatted;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sinkronisasi berhasil!'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sinkronisasi gagal. Periksa koneksi internet.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  /// Logout — hapus session dan kembali ke LoginPage.
  Future<void> _handleLogout() async {
    await AuthService.clearSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  /// Nama bulan Indonesia.
  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Bookshelf'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              // TODO: edit profil
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Avatar besar
              Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 56),
              ),
              const SizedBox(height: 20),

              // Nama user
              Text(
                'Halo, ${widget.username}!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),

              // Badge offline
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.offline.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 16,
                      color: AppColors.offline,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Anda sedang offline',
                      style: TextStyle(color: AppColors.offline, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Info sync terakhir
              Text(
                _lastSyncTime != null
                    ? 'Terakhir Sinkronisasi: $_lastSyncTime'
                    : 'Belum pernah sinkronisasi',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              // Tombol sinkronisasi
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSyncing ? null : _handleSync,
                  icon: _isSyncing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.sync_rounded),
                  label: Text(
                    _isSyncing
                        ? 'Menyinkronkan...'
                        : 'Sinkronisasi Data ke Server',
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tombol logout
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Keluar'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
