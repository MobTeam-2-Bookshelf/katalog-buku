import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:bookshelf/models/book.dart';

/// Service untuk komunikasi dengan backend API.
/// Base URL: http://103.23.198.215/api/v1
class ApiService {
  static const String _baseUrl = 'http://103.23.198.215/api/v1';
  // static const String _baseUrl = 'http://localhost/api/v1';

  final Dio _dio;

  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      );

  /// Login — POST /user/login
  /// Returns JWT token string.
  Future<String> login(String username, String password) async {
    try {
      debugPrint('=== REQUEST LOGIN ===');
      debugPrint('URL: $_baseUrl/user/login');
      debugPrint('Body: {"Username": "$username", "Password": "..."}');

      final response = await _dio.post(
        '/user/login',
        data: {'Username': username, 'Password': password},
      );

      debugPrint('=== RESPONSE LOGIN ===');
      // WARNING: Perintah dibawah menampilkan token user
      // debugPrint(
      //   response.data.toString(),
      // ); // Ini cara melihat output API sukses
      return response.data['token'] as String;
    } on DioException catch (e) {
      debugPrint('=== ERROR LOGIN ===');
      debugPrint('Error Message: $e');
      debugPrint('Status Code: ${e.response?.statusCode}');
      debugPrint(
        'Response Data: ${e.response?.data}',
      ); // Ini cara melihat pesan error dari API
      rethrow;
    }
  }

  /// Register — POST /user/register
  /// Returns user data map.
  Future<Map<String, dynamic>> register(
    String username,
    String password,
  ) async {
    final response = await _dio.post(
      '/user/register',
      data: {'Username': username, 'Password': password},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Get books — GET /books
  /// Returns list of Book from server.
  Future<List<Book>> getBooks(String token) async {
    final response = await _dio.get(
      '/books',
      options: Options(headers: {'Authorization': token}),
    );
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((json) => Book.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Add books — POST /books
  /// Sends array of books to server.
  Future<void> addBooks(String token, List<Book> books) async {
    await _dio.post(
      '/books',
      data: books.map((b) => b.toJson()).toList(),
      options: Options(headers: {'Authorization': token}),
    );
  }

  /// Edit books — PUT /books
  /// Sends array of updated books to server.
  Future<void> editBooks(String token, List<Book> books) async {
    await _dio.put(
      '/books',
      data: books.map((b) => b.toJson()).toList(),
      options: Options(headers: {'Authorization': token}),
    );
  }

  /// Delete books — POST /books/delete
  /// Sends array of book UUIDs to delete.
  Future<void> deleteBooks(String token, List<String> bookIds) async {
    await _dio.post(
      '/books/delete',
      data: bookIds,
      options: Options(headers: {'Authorization': token}),
    );
  }
}
