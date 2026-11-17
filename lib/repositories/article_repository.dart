import '../core/constants/api_endpoints.dart';
import '../core/constants/app_constants.dart';
import '../core/errors/api_exception.dart';
import '../core/network/api_client.dart';
import '../models/article_model.dart';

/// Abstract contract for article operations to ensure testability and separation of concerns.
abstract class ArticleRepository {
  Future<PaginatedArticles> getArticles({
    int limit = AppConstants.defaultPageSize,
    int offset = AppConstants.initialOffset,
    String? search,
  });

  Future<Article> getArticleById(int id);
}

/// Concrete implementation of [ArticleRepository] using [ApiClient].
class ArticleRepositoryImpl implements ArticleRepository {
  final ApiClient _apiClient;

  ArticleRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  @override
  Future<PaginatedArticles> getArticles({
    int limit = AppConstants.defaultPageSize,
    int offset = AppConstants.initialOffset,
    String? search,
  }) async {
    final queryParameters = <String, dynamic>{'limit': limit, 'offset': offset};

    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    final data = await _apiClient.get(
      ApiEndpoints.articles,
      queryParameters: queryParameters,
    );

    if (data is Map) {
      return PaginatedArticles.fromJson(Map<String, dynamic>.from(data));
    }

    throw const ApiException(
      message: 'Invalid response format received from server.',
      type: ApiExceptionType.unknown,
    );
  }

  @override
  Future<Article> getArticleById(int id) async {
    final data = await _apiClient.get(ApiEndpoints.articleDetails(id));

    if (data is Map) {
      return Article.fromJson(Map<String, dynamic>.from(data));
    }

    throw const ApiException(
      message: 'Invalid response format received from server.',
      type: ApiExceptionType.unknown,
    );
  }
}
