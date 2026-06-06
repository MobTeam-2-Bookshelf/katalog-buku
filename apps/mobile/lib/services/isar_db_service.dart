import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bookshelf/models/book_entity.dart';
import 'package:bookshelf/models/book.dart';
import 'package:bookshelf/app/constants.dart';

/// Service untuk mengelola database lokal IsarDB.
/// Menyediakan CRUD operations untuk buku dan user,
/// serta konversi antara Isar entity dan model Book.
class IsarDbService {
  late Isar _isar;

  /// Singleton instance.
  static final IsarDbService _instance = IsarDbService._internal();
  factory IsarDbService() => _instance;
  IsarDbService._internal();

  /// Akses Isar instance (untuk keperluan lain jika diperlukan).
  Isar get isar => _isar;

  /// Inisialisasi database Isar.
  /// Harus dipanggil sekali di main.dart sebelum runApp.
  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open([
      BookEntitySchema,
      UserEntitySchema,
    ], directory: dir.path);
    debugPrint('[IsarDB] Database initialized at ${dir.path}');
  }

  // BOOK CRUD Operations

  /// Simpan satu buku ke database lokal.
  Future<void> saveBook(Book book, String userId) async {
    final entity = _bookToEntity(book, userId);

    await _isar.writeTxn(() async {
      // Cek apakah sudah ada berdasarkan UUID
      final existing = await _isar.bookEntitys
          .filter()
          .idEqualTo(book.id)
          .findFirst();

      if (existing != null) {
        entity.isarId = existing.isarId; // Preserve Isar internal id
      }

      await _isar.bookEntitys.put(entity);
    });
  }

  /// Simpan banyak buku sekaligus ke database lokal.
  Future<void> saveBooks(List<Book> books, String userId) async {
    final entities = books.map((b) => _bookToEntity(b, userId)).toList();
    final List<BookEntity> toSave = [];

    await _isar.writeTxn(() async {
      for (final entity in entities) {
        final existing = await _isar.bookEntitys
            .filter()
            .idEqualTo(entity.id)
            .findFirst();

        if (existing != null) {
          // Jangan timpa data lokal jika ada aksi sync yang tertunda (offline edits)
          if (existing.syncAction != 'none') {
            continue; // Skip buku ini, pertahankan versi lokal
          }
          entity.isarId = existing.isarId;
        }
        toSave.add(entity);
      }
      
      if (toSave.isNotEmpty) {
        await _isar.bookEntitys.putAll(toSave);
      }
    });
  }

  /// Ambil semua buku milik user tertentu dari database lokal.
  Future<List<Book>> getBooksByUserId(String userId) async {
    final entities = await _isar.bookEntitys
        .filter()
        .userIdEqualTo(userId)
        .and()
        .not()
        .syncActionEqualTo('delete')
        .findAll();

    return entities.map(_entityToBook).toList();
  }

  /// Ambil semua buku dari database lokal (tanpa filter user).
  Future<List<Book>> getAllBooks() async {
    final entities = await _isar.bookEntitys
        .filter()
        .not()
        .syncActionEqualTo('delete')
        .findAll();
    return entities.map(_entityToBook).toList();
  }

  /// Ambil satu buku berdasarkan UUID.
  Future<Book?> getBookById(String bookId) async {
    final entity = await _isar.bookEntitys
        .filter()
        .idEqualTo(bookId)
        .findFirst();

    return entity != null ? _entityToBook(entity) : null;
  }

  /// Hapus satu buku dari database lokal berdasarkan UUID.
  Future<void> deleteBook(String bookId) async {
    await _isar.writeTxn(() async {
      final entity = await _isar.bookEntitys
          .filter()
          .idEqualTo(bookId)
          .findFirst();

      if (entity != null) {
        await _isar.bookEntitys.delete(entity.isarId);
      }
    });
  }

  /// Ambil buku-buku yang butuh di-sync ke server (add, edit, delete).
  Future<List<Book>> getUnsyncedBooks() async {
    final entities = await _isar.bookEntitys
        .filter()
        .not()
        .syncActionEqualTo('none')
        .findAll();

    return entities.map(_entityToBook).toList();
  }

  /// Ambil buku berdasarkan aksi sync tertentu.
  Future<List<Book>> getBooksBySyncAction(String action) async {
    final entities = await _isar.bookEntitys
        .filter()
        .syncActionEqualTo(action)
        .findAll();

    return entities.map(_entityToBook).toList();
  }

  /// Update status sync buku.
  Future<void> updateSyncAction(String bookId, String action) async {
    await _isar.writeTxn(() async {
      final entity = await _isar.bookEntitys
          .filter()
          .idEqualTo(bookId)
          .findFirst();

      if (entity != null) {
        entity.syncAction = action;
        await _isar.bookEntitys.put(entity);
      }
    });
  }

  /// Tandai buku sebagai sudah di-sync (syncAction = 'none').
  Future<void> markAsSynced(String bookId) async {
    await updateSyncAction(bookId, 'none');
  }

  /// Tandai semua buku sebagai sudah di-sync (syncAction = 'none').
  Future<void> markAllAsSynced() async {
    await _isar.writeTxn(() async {
      final entities = await _isar.bookEntitys
          .filter()
          .not()
          .syncActionEqualTo('none')
          .findAll();

      for (final entity in entities) {
        // Jika action-nya 'delete', dan berhasil di-sync, maka hapus dari lokal
        if (entity.syncAction == 'delete') {
          await _isar.bookEntitys.delete(entity.isarId);
        } else {
          entity.syncAction = 'none';
          await _isar.bookEntitys.put(entity);
        }
      }
    });
  }

  /// Hapus semua data buku (untuk logout/clear cache).
  Future<void> clearAllBooks() async {
    await _isar.writeTxn(() async {
      await _isar.bookEntitys.clear();
    });
  }

  // ========================
  // USER CRUD Operations
  // ========================

  /// Simpan user ke cache lokal.
  Future<void> saveUser({
    required String id,
    required String username,
    required String passwordHash,
  }) async {
    final entity = UserEntity()
      ..id = id
      ..createdAt = DateTime.now()
      ..username = username
      ..passwordHash = passwordHash;

    await _isar.writeTxn(() async {
      final existing = await _isar.userEntitys
          .filter()
          .idEqualTo(id)
          .findFirst();

      if (existing != null) {
        entity.isarId = existing.isarId;
      }

      await _isar.userEntitys.put(entity);
    });
  }

  /// Ambil user berdasarkan username dari cache lokal.
  Future<UserEntity?> getUserByUsername(String username) async {
    return await _isar.userEntitys
        .filter()
        .usernameEqualTo(username)
        .findFirst();
  }

  /// Hapus semua data user (untuk logout).
  Future<void> clearAllUsers() async {
    await _isar.writeTxn(() async {
      await _isar.userEntitys.clear();
    });
  }

  // ========================
  // Konversi Helper
  // ========================

  /// Konversi model Book → Isar BookEntity.
  BookEntity _bookToEntity(Book book, String userId) {
    return BookEntity()
      ..id = book.id
      ..userId = userId
      ..updatedAt = book.updatedAt
      ..title = book.title
      ..author = book.author
      ..genre = book.genre
      ..pageMax = book.pageMax
      ..pageCurrent = book.pageCurrent
      ..description = book.description
      ..note = book.note
      ..rating = book.rating
      ..progress = _statusToString(book.status)
      ..isbn = book.isbn
      ..syncAction = book.syncAction;
  }

  /// Konversi Isar BookEntity → model Book.
  Book _entityToBook(BookEntity entity) {
    return Book(
      id: entity.id,
      title: entity.title,
      author: entity.author ?? '',
      genre: entity.genre ?? '',
      pageMax: entity.pageMax ?? 0,
      pageCurrent: entity.pageCurrent ?? 0,
      description: entity.description,
      note: entity.note,
      rating: entity.rating,
      status: _parseStatus(entity.progress),
      isbn: entity.isbn,
      syncAction: entity.syncAction,
      updatedAt: entity.updatedAt,
    );
  }

  /// Parse string progress ke ReadingStatus enum.
  ReadingStatus _parseStatus(String? value) {
    switch (value) {
      case 'sedang':
        return ReadingStatus.sedangDibaca;
      case 'selesai':
        return ReadingStatus.selesai;
      default:
        return ReadingStatus.belumDibaca;
    }
  }

  /// Konversi ReadingStatus enum ke string.
  String _statusToString(ReadingStatus status) {
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
