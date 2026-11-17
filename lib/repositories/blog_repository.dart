import '../core/constants/api_endpoints.dart';
import '../core/constants/app_constants.dart';
import '../core/errors/api_exception.dart';
import '../core/network/api_client.dart';
import '../models/blog_model.dart';

/// Abstract contract for blog operations to ensure testability and separation of concerns.
abstract class BlogRepository {
  Future<PaginatedBlogs> getBlogs({
    int limit = AppConstants.defaultPageSize,
    int offset = AppConstants.initialOffset,
    String? search,
  });

  Future<Blog> getBlogById(int id);
}

/// Concrete implementation of [BlogRepository] using [ApiClient].
class BlogRepositoryImpl implements BlogRepository {
  final ApiClient _apiClient;

  BlogRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  @override
  Future<PaginatedBlogs> getBlogs({
    int limit = AppConstants.defaultPageSize,
    int offset = AppConstants.initialOffset,
    String? search,
  }) async {
    final queryParameters = <String, dynamic>{'limit': limit, 'offset': offset};

    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    final data = await _apiClient.get(
      ApiEndpoints.blogs,
      queryParameters: queryParameters,
    );

    if (data is Map) {
      return PaginatedBlogs.fromJson(Map<String, dynamic>.from(data));
    }

    throw const ApiException(
      message: 'Invalid response format received from server.',
      type: ApiExceptionType.unknown,
    );
  }

  @override
  Future<Blog> getBlogById(int id) async {
    final data = await _apiClient.get(ApiEndpoints.blogDetails(id));

    if (data is Map) {
      return Blog.fromJson(Map<String, dynamic>.from(data));
    }

    throw const ApiException(
      message: 'Invalid response format received from server.',
      type: ApiExceptionType.unknown,
    );
  }
}
