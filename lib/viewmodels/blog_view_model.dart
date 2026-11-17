import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../core/errors/api_exception.dart';
import '../models/blog_model.dart';
import '../repositories/blog_repository.dart';
import 'article_view_model.dart' show ViewState;

/// ViewModel for managing Blog state, pagination, and data retrieval.
class BlogViewModel extends ChangeNotifier {
  final BlogRepository _blogRepository;

  BlogViewModel(this._blogRepository);

  ViewState _state = ViewState.initial;
  List<Blog> _blogs = [];
  String? _errorMessage;
  int _totalCount = 0;
  int _currentOffset = AppConstants.initialOffset;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _searchQuery;
  bool _disposed = false;

  // Getters
  ViewState get state => _state;
  List<Blog> get blogs => List.unmodifiable(_blogs);
  String? get errorMessage => _errorMessage;
  int get totalCount => _totalCount;
  bool get isLoading => _state == ViewState.loading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasError => _state == ViewState.error;
  bool get isEmpty => _state == ViewState.empty;
  bool get hasMore => _hasMore;
  String? get searchQuery => _searchQuery;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  /// Fetches blogs from the repository.
  ///
  /// Set [refresh] to true to reset pagination and reload the initial list.
  /// Prevents concurrent in-flight requests.
  Future<void> fetchBlogs({bool refresh = false, String? search}) async {
    // Prevent duplicate in-flight fetch requests
    if (_state == ViewState.loading) return;

    if (refresh) {
      _currentOffset = AppConstants.initialOffset;
    }

    if (search != null) {
      final trimmed = search.trim();
      _searchQuery = trimmed.isEmpty ? null : trimmed;
      _currentOffset = AppConstants.initialOffset;
    }

    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _blogRepository.getBlogs(
        limit: AppConstants.defaultPageSize,
        offset: _currentOffset,
        search: _searchQuery,
      );

      if (_disposed) return;

      _totalCount = response.count;
      _hasMore = response.next != null && response.results.isNotEmpty;

      // Prevent duplicate records via ID tracking
      final seenIds = <int>{};
      final deduplicated = <Blog>[];
      for (final blog in response.results) {
        if (seenIds.add(blog.id)) {
          deduplicated.add(blog);
        }
      }
      _blogs = deduplicated;

      if (_blogs.isEmpty) {
        _state = ViewState.empty;
      } else {
        _state = ViewState.loaded;
      }
    } on ApiException catch (e) {
      if (_disposed) return;
      _errorMessage = e.message;
      _state = ViewState.error;
    } catch (e) {
      if (_disposed) return;
      _errorMessage = e.toString();
      _state = ViewState.error;
    } finally {
      notifyListeners();
    }
  }

  /// Loads the next page of blogs and appends unique items to [_blogs].
  ///
  /// Prevents concurrent pagination requests and prevents duplicate records.
  Future<void> loadMore() async {
    if (_isLoadingMore ||
        !_hasMore ||
        _state == ViewState.loading ||
        _state == ViewState.initial) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextOffset = _blogs.length;
      final response = await _blogRepository.getBlogs(
        limit: AppConstants.defaultPageSize,
        offset: nextOffset,
        search: _searchQuery,
      );

      if (_disposed) return;

      _totalCount = response.count;
      _currentOffset = nextOffset;
      _hasMore = response.next != null && response.results.isNotEmpty;

      // Prevent duplicate records when appending
      final existingIds = _blogs.map((b) => b.id).toSet();
      final newItems = response.results
          .where((item) => !existingIds.contains(item.id))
          .toList();
      _blogs.addAll(newItems);

      _state = _blogs.isEmpty ? ViewState.empty : ViewState.loaded;
    } on ApiException catch (e) {
      if (_disposed) return;
      _errorMessage = e.message;
    } catch (e) {
      if (_disposed) return;
      _errorMessage = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Clears the active search filter and reloads the default list.
  Future<void> clearSearch() async {
    if (_searchQuery == null && _state != ViewState.error) return;
    _searchQuery = null;
    await fetchBlogs(refresh: true);
  }
}
