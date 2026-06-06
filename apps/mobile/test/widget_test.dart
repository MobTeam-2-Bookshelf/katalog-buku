import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bookshelf/main.dart';

void main() {
  group('BookshelfApp - Smoke Tests', () {
    testWidgets('App renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(const BookshelfApp(isInitSuccess: true, isLoggedIn: false));
      // Verifikasi app berhasil di-render
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Login page shows correct elements', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const BookshelfApp(isInitSuccess: true, isLoggedIn: false));

      // Verifikasi elemen-elemen halaman Login
      expect(find.text('Bookshelf'), findsOneWidget);
      expect(find.text('Selamat datang!'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
      expect(find.text('Belum punya akun? '), findsOneWidget);
      expect(find.text('Daftar'), findsOneWidget);
    });

    testWidgets('Navigate from Login to Register', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const BookshelfApp(isInitSuccess: true, isLoggedIn: false));

      // Tap link "Daftar" untuk navigasi ke Register
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();

      // Verifikasi halaman Register muncul
      expect(find.text('Buat Akun Baru'), findsOneWidget);
      expect(find.text('Nama Lengkap'), findsOneWidget);
    });

    testWidgets('Navigate from Register back to Login', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const BookshelfApp(isInitSuccess: true, isLoggedIn: false));

      // Ke Register dulu
      await tester.tap(find.text('Daftar'));
      await tester.pumpAndSettle();

      // Tap link "Masuk" untuk kembali ke Login
      await tester.tap(find.text('Masuk'));
      await tester.pumpAndSettle();

      // Verifikasi kembali ke halaman Login
      expect(find.text('Selamat datang!'), findsOneWidget);
    });

    testWidgets('Login form validation shows errors on empty fields', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const BookshelfApp(isInitSuccess: true, isLoggedIn: false));

      // Tap tombol Masuk tanpa mengisi form
      await tester.tap(find.widgetWithText(ElevatedButton, 'Masuk'));
      await tester.pumpAndSettle();

      // Verifikasi pesan error muncul
      expect(find.text('Email atau username wajib diisi'), findsOneWidget);
      expect(find.text('Password wajib diisi'), findsOneWidget);
    });
  });
}
