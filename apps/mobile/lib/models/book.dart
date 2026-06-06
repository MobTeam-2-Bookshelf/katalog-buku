import 'package:uuid/uuid.dart';
import 'package:bookshelf/app/constants.dart';

/// Generator UUID global (v4 random).
const _uuid = Uuid();

/// Model data buku.
/// Field-field disesuaikan dengan API backend Go (models/book.go).
class Book {
  /// Primary key — UUID v4 string.
  final String id;

  final String title;
  final String author;
  final String genre;
  final int pageMax;
  int pageCurrent;
  final String? description;
  String? note;
  int? rating;
  ReadingStatus status;
  final String? isbn;
  final String? coverUrl;

  /// Status sync: 'none', 'add', 'edit', 'delete'
  String syncAction;

  DateTime updatedAt;

  Book({
    String? id,
    required this.title,
    required this.author,
    required this.genre,
    required this.pageMax,
    this.pageCurrent = 0,
    this.description,
    this.note,
    this.rating,
    this.status = ReadingStatus.belumDibaca,
    this.isbn,
    this.coverUrl,
    this.syncAction = 'none',
    DateTime? updatedAt,
  }) : id = id ?? _uuid.v4(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Hitung persentase progres baca (0.0 - 1.0).
  double get progressPercent {
    if (pageMax <= 0) return 0.0;
    return (pageCurrent / pageMax).clamp(0.0, 1.0);
  }

  /// Hitung persentase progres sebagai integer (0 - 100).
  int get progressPercentInt => (progressPercent * 100).round();

  /// Konversi dari JSON (response API backend Go).
  /// Field names match backend: models/book.go JSON tags.
  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id']?.toString(),
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      genre: json['genre'] as String? ?? '',
      pageMax: json['page_max'] as int? ?? 0,
      pageCurrent: json['page_current'] as int? ?? 0,
      description: json['description'] as String?,
      note: json['note'] as String?,
      rating: json['rating'] as int?,
      status: _parseStatus(json['progress'] as String?),
      isbn: json['ISBN'] as String?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  /// Konversi ke JSON (request API backend Go).
  /// Field names match backend: models/book.go JSON tags.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'title': title,
      'author': author,
      'genre': genre,
      'page_max': pageMax,
      'page_current': pageCurrent,
      'description': description ?? '',
      'note': note ?? '',
      'rating': rating ?? 0,
      'progress': _statusToApi(status),
      'ISBN': isbn,
    };
  }

  /// Parse status string dari API ke enum ReadingStatus.
  /// Backend values: "belum", "sedang", "selesai"
  static ReadingStatus _parseStatus(String? value) {
    switch (value) {
      case 'sedang':
        return ReadingStatus.sedangDibaca;
      case 'selesai':
        return ReadingStatus.selesai;
      default:
        return ReadingStatus.belumDibaca;
    }
  }

  /// Konversi enum ReadingStatus ke string API.
  static String _statusToApi(ReadingStatus status) {
    switch (status) {
      case ReadingStatus.belumDibaca:
        return 'belum';
      case ReadingStatus.sedangDibaca:
        return 'sedang';
      case ReadingStatus.selesai:
        return 'selesai';
    }
  }
}
