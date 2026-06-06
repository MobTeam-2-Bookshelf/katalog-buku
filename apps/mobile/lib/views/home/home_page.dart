import 'package:flutter/material.dart';
import 'package:bookshelf/app/theme.dart';
import 'package:bookshelf/app/constants.dart';
import 'package:bookshelf/models/book.dart';
import 'package:bookshelf/services/api_service.dart';
import 'package:bookshelf/services/isar_db_service.dart';
import 'package:bookshelf/views/home/widgets/book_search_bar.dart';
import 'package:bookshelf/views/home/widgets/status_filter_chips.dart';
import 'package:bookshelf/views/home/widgets/book_card.dart';
import 'package:bookshelf/views/book/book_detail_page.dart';
import 'package:bookshelf/views/book/add_book_page.dart';
import 'package:bookshelf/views/book/widgets/add_book_method_dialog.dart';
import 'package:bookshelf/views/profile/profile_page.dart';
import 'package:bookshelf/views/scanner/scan_barcode_page.dart';

/// Halaman utama, Penyimpanan Koleksi Buku.
/// Menampilkan daftar buku user dengan search, filter status, dan FAB tambah.
class HomePage extends StatefulWidget {
  final String username;
  final String token;
  final String userId;

  const HomePage({
    super.key,
    this.username = 'User',
    required this.token,
    this.userId = '',
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// Filter status yang aktif: 0=Semua, 1=Sedang Dibaca, 2=Selesai.
  int _selectedFilter = 0;

  /// Query pencarian.
  String _searchQuery = '';

  /// Daftar buku dari API.
  List<Book> _books = [];

  /// Loading state.
  bool _isLoading = true;

  /// Error message.
  String? _error;

  final _apiService = ApiService();
  final _dbService = IsarDbService();

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  /// Fetch buku — offline-first:
  /// 1. Load dari IsarDB lokal (instant)
  /// 2. Fetch dari API di background
  /// 3. Simpan hasil API ke IsarDB
  Future<void> _fetchBooks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // 1. Load dari database lokal dulu (instant)
    try {
      final localBooks = await _dbService.getAllBooks();
      if (localBooks.isNotEmpty && mounted) {
        setState(() {
          _books = localBooks;
          _isLoading = false;
        });
      }
    } catch (_) {
      // Database lokal gagal, lanjut ke API
    }

    // 2. Fetch dari API di background
    try {
      final apiBooks = await _apiService.getBooks(widget.token);
      if (!mounted) return;

      // 3. Simpan ke IsarDB lokal
      final userId = widget.userId.isNotEmpty ? widget.userId : widget.username;
      await _dbService.saveBooks(apiBooks, userId);

      setState(() {
        _books = apiBooks;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      // Jika sudah ada data lokal, jangan tampilkan error
      if (_books.isEmpty) {
        setState(() {
          _error = 'Gagal memuat buku. Pastikan koneksi internet aktif.';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Daftar buku yang sudah difilter & dicari.
  List<Book> get _filteredBooks {
    var result = _books;

    // Filter berdasarkan status
    if (_selectedFilter == 1) {
      result = result
          .where((b) => b.status == ReadingStatus.sedangDibaca)
          .toList();
    } else if (_selectedFilter == 2) {
      result = result.where((b) => b.status == ReadingStatus.selesai).toList();
    }

    // Filter berdasarkan search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((b) {
        return b.title.toLowerCase().contains(query) ||
            b.author.toLowerCase().contains(query);
      }).toList();
    }

    return result;
  }

  /// Tampilkan dialog pilih metode tambah buku.
  void _showAddBookDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddBookMethodDialog(
        onManualTap: () {
          Navigator.pop(context);
          _navigateToAddBook();
        },
        onScanTap: () {
          Navigator.pop(context);
          _navigateToScanISBN();
        },
      ),
    );
  }

  /// Navigasi ke halaman tambah buku (manual).
  void _navigateToAddBook() async {
    final result = await Navigator.push<Book>(
      context,
      MaterialPageRoute(builder: (_) => const AddBookPage()),
    );

    // Tambahkan buku baru ke list, simpan ke IsarDB, dan sync ke server
    if (result != null) {
      setState(() => _books.add(result));

      // Simpan ke IsarDB lokal dengan status 'add'
      result.syncAction = 'add';
      final userId = widget.userId.isNotEmpty ? widget.userId : widget.username;
      await _dbService.saveBook(result, userId);

      // Sync ke server
      try {
        await _apiService.addBooks(widget.token, [result]);
        await _dbService.markAsSynced(result.id);
      } catch (_) {
        // Buku sudah tersimpan lokal, sync nanti via Profile
      }
    }
  }

  /// Navigasi ke halaman scan barcode ISBN.
  void _navigateToScanISBN() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanBarcodePage()),
    );
    // Refresh setelah kembali dari scanner flow
    _fetchBooks();
  }

  /// Navigasi ke halaman detail buku.
  void _navigateToDetail(Book book) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailPage(
          book: book,
          token: widget.token,
          userId: widget.userId,
        ),
      ),
    );

    // Refresh list jika ada perubahan dari detail
    if (result == true) {
      _fetchBooks();
    }
  }

  /// Navigasi ke halaman profil & sinkronisasi.
  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          username: widget.username,
          token: widget.token,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Header: avatar + greeting + profil
              _buildHeader(),
              const SizedBox(height: 20),

              // Search bar
              BookSearchBar(
                onChanged: (query) {
                  setState(() => _searchQuery = query);
                },
              ),
              const SizedBox(height: 16),

              // Label "Pilih Status Baca Bukumu"
              Text(
                'Pilih Status Baca Bukumu',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),

              // Filter chips
              StatusFilterChips(
                selectedIndex: _selectedFilter,
                onSelected: (index) {
                  setState(() => _selectedFilter = index);
                },
              ),
              const SizedBox(height: 16),

              // Daftar buku
              Expanded(child: _buildBookList()),
            ],
          ),
        ),
      ),

      // FAB tambah buku
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBookDialog,
        backgroundColor: AppColors.accent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  /// Header: avatar user, greeting, dan tombol profil.
  Widget _buildHeader() {
    return Row(
      children: [
        // Avatar user
        GestureDetector(
          onTap: _navigateToProfile,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0xFFE53935),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(width: 12),

        // Greeting & status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Halo, ${widget.username}!',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 14,
                    color: AppColors.offline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Anda sedang offline',
                    style: TextStyle(color: AppColors.offline, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// List buku menggunakan ListView.builder untuk efisiensi.
  Widget _buildBookList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: AppColors.divider),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _fetchBooks,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    final books = _filteredBooks;

    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_rounded, size: 64, color: AppColors.divider),
            const SizedBox(height: 16),
            Text(
              'Belum ada buku',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Tekan tombol + untuk menambah buku baru',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchBooks,
      child: ListView.builder(
        itemCount: books.length,
        itemBuilder: (context, index) {
          return BookCard(
            book: books[index],
            onTap: () => _navigateToDetail(books[index]),
          );
        },
      ),
    );
  }
}
