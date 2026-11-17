/// Centralized API endpoint configurations for the Spaceflight News API (v4).
class ApiEndpoints {
  ApiEndpoints._();

  /// Spaceflight News API (v4) Base URL.
  static const String baseUrl = 'https://api.spaceflightnewsapi.net/v4';

  /// Articles collection endpoint.
  static const String articles = '/articles/';

  /// Article details endpoint by [id].
  static String articleDetails(int id) => '/articles/$id/';

  /// Blogs collection endpoint.
  static const String blogs = '/blogs/';

  /// Blog details endpoint by [id].
  static String blogDetails(int id) => '/blogs/$id/';
}
