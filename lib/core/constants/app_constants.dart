/// General shared application constants.
class AppConstants {
  AppConstants._();

  // Pagination Defaults
  static const int defaultPageSize = 10;
  static const int initialOffset = 0;

  // Search Configuration
  static const Duration searchDebounceDuration = Duration(milliseconds: 500);

  // Network Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);
}
