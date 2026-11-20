import 'package:shared_preferences/shared_preferences.dart';

/// Repository interface for persisting and managing user bookmarks.
abstract class BookmarkRepository {
  Future<void> init();
  bool isArticleBookmarked(int id);
  bool isBlogBookmarked(int id);
  bool isReportBookmarked(int id);
  Future<bool> toggleArticleBookmark(int id);
  Future<bool> toggleBlogBookmark(int id);
  Future<bool> toggleReportBookmark(int id);
  Set<int> get bookmarkedArticleIds;
  Set<int> get bookmarkedBlogIds;
  Set<int> get bookmarkedReportIds;
}

/// SharedPreferences-backed implementation of [BookmarkRepository].
///
/// Stores bookmarks using distinct type keys to prevent ID collisions
/// between articles, blogs, and reports.
class BookmarkRepositoryImpl implements BookmarkRepository {
  static const String _articlesKey = 'newsly_bookmarked_articles';
  static const String _blogsKey = 'newsly_bookmarked_blogs';
  static const String _reportsKey = 'newsly_bookmarked_reports';

  final SharedPreferences? _prefsInstance;
  SharedPreferences? _prefs;

  final Set<int> _articleIds = <int>{};
  final Set<int> _blogIds = <int>{};
  final Set<int> _reportIds = <int>{};
  bool _initialized = false;

  BookmarkRepositoryImpl({SharedPreferences? preferences})
    : _prefsInstance = preferences;

  @override
  Future<void> init() async {
    if (_initialized) return;
    try {
      _prefs = _prefsInstance ?? await SharedPreferences.getInstance();
      final savedArticles = _prefs?.getStringList(_articlesKey) ?? <String>[];
      for (final str in savedArticles) {
        final id = int.tryParse(str);
        if (id != null) _articleIds.add(id);
      }

      final savedBlogs = _prefs?.getStringList(_blogsKey) ?? <String>[];
      for (final str in savedBlogs) {
        final id = int.tryParse(str);
        if (id != null) _blogIds.add(id);
      }

      final savedReports = _prefs?.getStringList(_reportsKey) ?? <String>[];
      for (final str in savedReports) {
        final id = int.tryParse(str);
        if (id != null) _reportIds.add(id);
      }
    } catch (_) {
      // Fallback gracefully to in-memory storage if preferences fails
    }
    _initialized = true;
  }

  @override
  bool isArticleBookmarked(int id) {
    return _articleIds.contains(id);
  }

  @override
  bool isBlogBookmarked(int id) {
    return _blogIds.contains(id);
  }

  @override
  bool isReportBookmarked(int id) {
    return _reportIds.contains(id);
  }

  @override
  Future<bool> toggleArticleBookmark(int id) async {
    if (!_initialized) await init();
    final isSaved = _articleIds.contains(id);
    if (isSaved) {
      _articleIds.remove(id);
    } else {
      _articleIds.add(id);
    }
    await _persistArticles();
    return !isSaved;
  }

  @override
  Future<bool> toggleBlogBookmark(int id) async {
    if (!_initialized) await init();
    final isSaved = _blogIds.contains(id);
    if (isSaved) {
      _blogIds.remove(id);
    } else {
      _blogIds.add(id);
    }
    await _persistBlogs();
    return !isSaved;
  }

  @override
  Future<bool> toggleReportBookmark(int id) async {
    if (!_initialized) await init();
    final isSaved = _reportIds.contains(id);
    if (isSaved) {
      _reportIds.remove(id);
    } else {
      _reportIds.add(id);
    }
    await _persistReports();
    return !isSaved;
  }

  Future<void> _persistArticles() async {
    try {
      final list = _articleIds.map((id) => id.toString()).toList();
      await _prefs?.setStringList(_articlesKey, list);
    } catch (_) {}
  }

  Future<void> _persistBlogs() async {
    try {
      final list = _blogIds.map((id) => id.toString()).toList();
      await _prefs?.setStringList(_blogsKey, list);
    } catch (_) {}
  }

  Future<void> _persistReports() async {
    try {
      final list = _reportIds.map((id) => id.toString()).toList();
      await _prefs?.setStringList(_reportsKey, list);
    } catch (_) {}
  }

  @override
  Set<int> get bookmarkedArticleIds => Set.unmodifiable(_articleIds);

  @override
  Set<int> get bookmarkedBlogIds => Set.unmodifiable(_blogIds);

  @override
  Set<int> get bookmarkedReportIds => Set.unmodifiable(_reportIds);
}
