import 'package:flutter/material.dart';
import 'package:bookshelf/app/theme.dart';
import 'package:bookshelf/views/auth/login_page.dart';
import 'package:bookshelf/views/home/home_page.dart';
import 'package:bookshelf/services/isar_db_service.dart';
import 'package:bookshelf/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isInitSuccess = false;
  bool isLoggedIn = false;
  String? token;
  String? username;

  try {
    // Inisialisasi database lokal IsarDB
    await IsarDbService().init();

    // Cek sesi login
    isLoggedIn = await AuthService.isLoggedIn();
    token = await AuthService.getToken();
    username = await AuthService.getUsername();

    isInitSuccess = true;
  } catch (e) {
    debugPrint('Gagal inisialisasi aplikasi: $e');
  }

  runApp(BookshelfApp(
    isInitSuccess: isInitSuccess,
    isLoggedIn: isLoggedIn,
    token: token,
    username: username,
  ));
}

/// Root widget aplikasi Bookshelf.
/// Menggunakan Material 3 theme dengan color scheme teal.
class BookshelfApp extends StatelessWidget {
  final bool isInitSuccess;
  final bool isLoggedIn;
  final String? token;
  final String? username;

  const BookshelfApp({
    super.key,
    required this.isInitSuccess,
    required this.isLoggedIn,
    this.token,
    this.username,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bookshelf',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: !isInitSuccess
          ? Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Aplikasi mengalami kendala saat memuat data.',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Silakan bersihkan cache (Clear Data) aplikasi ini melalui Pengaturan HP Anda, lalu buka kembali.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : (isLoggedIn && token != null && username != null)
              ? HomePage(token: token!, username: username!)
              : const LoginPage(),
    );
  }
}
