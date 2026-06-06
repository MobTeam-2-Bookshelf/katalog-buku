import 'package:flutter/material.dart';
import 'package:bookshelf/app/theme.dart';
import 'package:bookshelf/app/constants.dart';
import 'package:bookshelf/models/book.dart';
import 'package:bookshelf/services/api_service.dart';
import 'package:bookshelf/services/isar_db_service.dart';
import 'package:bookshelf/views/book/widgets/progress_bottom_sheet.dart';
import 'package:bookshelf/views/book/rating_review_page.dart';
import 'package:bookshelf/views/book/add_book_page.dart';

/// Halaman detail buku, menampilkan info lengkap buku.
/// Sesuai desain: cover, judul, penulis, rating, status, catatan,
/// tombol "Edit Progress", tombol "Beri Rating", dan edit metadata.
class BookDetailPage extends StatefulWidget {
  final Book book;
  final String token;
  final String userId;

  const BookDetailPage({
    super.key,
    required this.book,
    required this.token,
    this.userId = '',
  });

  @override
  State<BookDetailPage> createState() => _BookDetailPageState();
}

class _BookDetailPageState extends State<BookDetailPage> {
  /// Buku yang ditampilkan (mutable karena progress bisa di-update).
  late Book _book;
  bool _hasChanges = false;
  final _apiService = ApiService();
  final _dbService = IsarDbService();

  @override
  void initState() {
    super.initState();
    _book = widget.book;
  }

  /// Buka bottom sheet untuk edit progress/status.
  void _showProgressSheet() {
    ProgressBottomSheet.show(
      context: context,
      currentStatus: _book.status,
      currentPage: _book.pageCurrent,
      maxPage: _book.pageMax,
      onSave: (newStatus, newPageCurrent) {
        setState(() {
          _book.status = newStatus;
          _book.pageCurrent = newPageCurrent;
          _book.updatedAt = DateTime.now();
          _hasChanges = true;
        });

        // Sync perubahan ke server
        _syncBook();
      },
    );
  }

  /// Navigasi ke halaman Rating & Review.
  void _navigateToRatingReview() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => RatingReviewPage(book: _book),
      ),
    );

    if (result != null) {
      setState(() {
        _book.rating = result['rating'] as int;
        _book.note = result['note'] as String;
        _book.updatedAt = DateTime.now();
        _hasChanges = true;
      });

      // Sync perubahan ke server
      _syncBook();
    }
  }

  /// Navigasi ke halaman edit metadata buku.
  void _navigateToEditBook() async {
    final result = await Navigator.push<Book>(
      context,
      MaterialPageRoute(
        builder: (_) => AddBookPage(editBook: _book),
      ),
    );

    if (result != null) {
      setState(() {
        _book = result;
        _hasChanges = true;
      });

      // Sync perubahan ke server
      _syncBook();
    }
  }

  /// Sync perubahan buku ke server + simpan ke IsarDB lokal.
  Future<void> _syncBook() async {
    // Simpan ke database lokal dulu
    final userId = widget.userId.isNotEmpty ? widget.userId : 'local';
    
    // Jika belum pernah di-sync (masih 'add'), biarkan 'add' agar backend tau ini buku baru
    if (_book.syncAction != 'add') {
      _book.syncAction = 'edit';
    }
    
    await _dbService.saveBook(_book, userId);

    // Coba sync ke server langsung
    try {
      if (_book.syncAction == 'add') {
        await _apiService.addBooks(widget.token, [_book]);
      } else {
        await _apiService.editBooks(widget.token, [_book]);
      }
      _book.syncAction = 'none';
      await _dbService.markAsSynced(_book.id);
    } catch (_) {
      // Sync gagal, data lokal sudah ter-update, sync nanti via Profile
    }
  }

  /// Hapus buku
  Future<void> _deleteBook() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Buku'),
        content: const Text('Yakin ingin menghapus buku ini dari rak?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Simpan status delete di lokal
    _book.syncAction = 'delete';
    final userId = widget.userId.isNotEmpty ? widget.userId : 'local';
    await _dbService.saveBook(_book, userId);

    // Coba hapus di server
    try {
      await _apiService.deleteBooks(widget.token, [_book.id]);
      // Jika berhasil di server, baru benar-benar hapus dari lokal
      await _dbService.deleteBook(_book.id);
    } catch (_) {
      // Jika gagal, biarkan di lokal dengan status 'delete' untuk disinkronkan nanti
    }

    if (!mounted) return;
    Navigator.pop(context, true); // Kembali dengan flag perubahan true
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _hasChanges) {
          // Notify parent bahwa ada perubahan
          Navigator.of(context);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Detail Buku'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
          actions: [
            // Tombol hapus buku
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: _deleteBook,
            ),
            // Tombol edit metadata buku
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _navigateToEditBook,
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover buku (besar, full width)
              _buildCover(),
              const SizedBox(height: 20),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul
                    Text(
                      _book.title,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),

                    // Penulis
                    Text(
                      _book.author,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 4),

                    // Genre
                    Text(
                      _book.genre,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Rating + progress
                    _buildRatingAndProgress(),
                    const SizedBox(height: 20),

                    // Tombol Edit Progress
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showProgressSheet,
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text('Edit Progress'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tombol Beri Rating & Review
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _navigateToRatingReview,
                        icon: const Icon(Icons.star_border_rounded),
                        label: const Text('Beri Rating & Review'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accent,
                          side: const BorderSide(color: AppColors.accent),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Catatan untuk buku ini
                    _buildNoteSection(),
                    const SizedBox(height: 24),

                    // Info ISBN
                    if (_book.isbn != null && _book.isbn!.isNotEmpty)
                      _buildIsbnInfo(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Cover buku, container gradient teal full width.
  Widget _buildCover() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.menu_book_rounded, color: Colors.white, size: 64),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              _book.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Rating stars + status chip + progress bar.
  Widget _buildRatingAndProgress() {
    final rating = _book.rating ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rating stars
        Row(
          children: [
            ...List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                color: index < rating ? AppColors.accent : AppColors.divider,
                size: 22,
              );
            }),
            const SizedBox(width: 8),
            Text('$rating/5', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 12),

        // Status chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _statusColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _book.status.label,
            style: TextStyle(
              color: _statusColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Progress bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _book.progressPercent,
                  backgroundColor: AppColors.divider.withValues(alpha: 0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${_book.pageCurrent}/${_book.pageMax} hal',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }

  /// Section catatan/note buku.
  Widget _buildNoteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catatan untuk Buku ini',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
          ),
          child: Text(
            _book.note ?? 'Belum ada catatan untuk buku ini.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ),
      ],
    );
  }

  /// Info ISBN buku.
  Widget _buildIsbnInfo() {
    return Row(
      children: [
        const Icon(
          Icons.qr_code_2_rounded,
          size: 20,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: 8),
        Text(
          'ISBN: ${_book.isbn}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  /// Warna sesuai status.
  Color get _statusColor {
    switch (_book.status) {
      case ReadingStatus.belumDibaca:
        return AppColors.offline;
      case ReadingStatus.sedangDibaca:
        return AppColors.primary;
      case ReadingStatus.selesai:
        return AppColors.success;
    }
  }
}
