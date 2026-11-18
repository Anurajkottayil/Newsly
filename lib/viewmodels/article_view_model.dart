import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../core/errors/api_exception.dart';
import '../models/article_model.dart';
import '../repositories/article_repository.dart';

/// Enum defining the current UI state of a ViewModel.
enum ViewState { initial, loading, loaded, empty, error }

/// ViewModel for managing Article state, pagination, and data retrieval.
class ArticleViewModel extends ChangeNotifier {
  final ArticleRepository _articleRepository;

  ArticleViewModel(this._articleRepository);

  ViewState _state = ViewState.initial;
  List<Article> _articles = [];
  String? _errorMessage;
  int _totalCount = 0;
  int _currentOffset = AppConstants.initialOffset;
  bool _isLoadingMore = false;
  bool _hasMore = false;
  String? _paginationError;
  String? _searchQuery;
  bool _disposed = false;

  // Getters
  ViewState get state => _state;
  List<Article> get articles => List.unmodifiable(_articles);
  String? get errorMessage => _errorMessage;
  String? get paginationError => _paginationError;
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

  /// Fetches articles from the repository.
  ///
  /// Set [refresh] to true to reset pagination and reload the initial list.
  /// Prevents concurrent in-flight requests.
  Future<void> fetchArticles({bool refresh = false, String? search}) async {
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
    _paginationError = null;
    notifyListeners();

    try {
      final response = await _articleRepository.getArticles(
        limit: AppConstants.defaultPageSize,
        offset: _currentOffset,
        search: _searchQuery,
      );

      if (_disposed) return;

      _totalCount = response.count;
      _hasMore = response.next != null && response.results.isNotEmpty;

      // Prevent duplicate records via ID tracking
      final seenIds = <int>{};
      final deduplicated = <Article>[];
      for (final article in response.results) {
        if (seenIds.add(article.id)) {
          deduplicated.add(article);
        }
      }
      _articles = deduplicated;

      if (_articles.isEmpty) {
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

  /// Loads the next page of articles and appends unique items to [_articles].
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
    _paginationError = null;
    notifyListeners();

    try {
      final nextOffset = _articles.length;
      final response = await _articleRepository.getArticles(
        limit: AppConstants.defaultPageSize,
        offset: nextOffset,
        search: _searchQuery,
      );

      if (_disposed) return;

      _totalCount = response.count;
      _currentOffset = nextOffset;
      _hasMore = response.next != null && response.results.isNotEmpty;

      // Prevent duplicate records when appending
      final existingIds = _articles.map((a) => a.id).toSet();
      final newItems = response.results
          .where((item) => !existingIds.contains(item.id))
          .toList();
      _articles.addAll(newItems);

      _state = _articles.isEmpty ? ViewState.empty : ViewState.loaded;
    } on ApiException catch (e) {
      if (_disposed) return;
      _paginationError = e.message;
    } catch (e) {
      if (_disposed) return;
      _paginationError = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Retries loading the next page of articles if a previous loadMore failed.
  Future<void> retryLoadMore() => loadMore();

  /// Clears the active search filter and reloads the default list.
  Future<void> clearSearch() async {
    if (_searchQuery == null && _state != ViewState.error) return;
    _searchQuery = null;
    await fetchArticles(refresh: true);
  }
}
