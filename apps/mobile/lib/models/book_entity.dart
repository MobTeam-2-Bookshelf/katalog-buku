import 'package:isar/isar.dart';

// Untuk generate: dart run build_runner build
part 'book_entity.g.dart';

/// Entity IsarDB untuk tabel Books.
/// Schema di-mirror dari backend Go: internal/database/models.go
@collection
class BookEntity {
  /// Isar auto-increment id (internal).
  Id isarId = Isar.autoIncrement;

  /// UUID v4 string — primary key dari backend.
  @Index(unique: true)
  late String id;

  /// User ID — foreign key ke tabel users.
  @Index()
  late String userId;

  late DateTime updatedAt;
  late String title;
  String? author;
  String? genre;
  int? pageMax;
  int? pageCurrent;
  String? description;
  String? note;
  int? rating;

  /// Status progress: "belum", "sedang", "selesai"
  String? progress;

  String? isbn;

  /// Status sync yang pending: 'none', 'add', 'edit', 'delete'
  String syncAction = 'none';
}

/// Entity IsarDB untuk tabel Users.
/// Schema di-mirror dari backend Go: internal/database/models.go
@collection
class UserEntity {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String id;

  late DateTime createdAt;

  @Index(unique: true)
  late String username;

  late String passwordHash;
}
