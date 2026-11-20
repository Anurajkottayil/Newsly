import 'package:flutter/foundation.dart';
import '../repositories/bookmark_repository.dart';

/// ViewModel managing reactive bookmark state for Articles and Blogs.
///
/// Adheres to Provider + ChangeNotifier MVVM architecture.
class BookmarkViewModel extends ChangeNotifier {
  final BookmarkRepository _repository;
  bool _isReady = false;

  BookmarkViewModel(this._repository) {
    _initialize();
  }

  bool get isReady => _isReady;

  Future<void> _initialize() async {
    await _repository.init();
    _isReady = true;
    notifyListeners();
  }

  bool isArticleBookmarked(int id) => _repository.isArticleBookmarked(id);

  bool isBlogBookmarked(int id) => _repository.isBlogBookmarked(id);

  bool isReportBookmarked(int id) => _repository.isReportBookmarked(id);

  Future<bool> toggleArticleBookmark(int id) async {
    final result = await _repository.toggleArticleBookmark(id);
    notifyListeners();
    return result;
  }

  Future<bool> toggleBlogBookmark(int id) async {
    final result = await _repository.toggleBlogBookmark(id);
    notifyListeners();
    return result;
  }

  Future<bool> toggleReportBookmark(int id) async {
    final result = await _repository.toggleReportBookmark(id);
    notifyListeners();
    return result;
  }
}

