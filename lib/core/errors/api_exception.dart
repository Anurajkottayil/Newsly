import 'package:dio/dio.dart';
import '../constants/app_strings.dart';

/// Categories of API exceptions to allow clear handling in the UI layer.
enum ApiExceptionType {
  network,
  timeout,
  badRequest,
  unauthorized,
  notFound,
  server,
  cancelled,
  unknown,
}

/// Strongly-typed exception class representing network and API failures.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiExceptionType type;
  final dynamic originalError;

  const ApiException({
    required this.message,
    this.statusCode,
    this.type = ApiExceptionType.unknown,
    this.originalError,
  });

  /// Factory constructor to map a [DioException] to an [ApiException].
  factory ApiException.fromDioException(DioException dioException) {
    switch (dioException.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: AppStrings.timeoutError,
          statusCode: dioException.response?.statusCode,
          type: ApiExceptionType.timeout,
          originalError: dioException,
        );

      case DioExceptionType.connectionError:
        return ApiException(
          message: AppStrings.networkError,
          statusCode: dioException.response?.statusCode,
          type: ApiExceptionType.network,
          originalError: dioException,
        );

      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request was cancelled.',
          statusCode: dioException.response?.statusCode,
          type: ApiExceptionType.cancelled,
          originalError: dioException,
        );

      case DioExceptionType.badResponse:
        final statusCode = dioException.response?.statusCode;
        return _handleBadResponse(statusCode, dioException);

      case DioExceptionType.badCertificate:
        return ApiException(
          message: 'Certificate verification failed.',
          statusCode: dioException.response?.statusCode,
          type: ApiExceptionType.network,
          originalError: dioException,
        );

      case DioExceptionType.unknown:
      default:
        return ApiException(
          message: AppStrings.genericError,
          statusCode: dioException.response?.statusCode,
          type: ApiExceptionType.unknown,
          originalError: dioException,
        );
    }
  }

  static ApiException _handleBadResponse(
    int? statusCode,
    DioException dioException,
  ) {
    String message = AppStrings.genericError;
    ApiExceptionType type = ApiExceptionType.unknown;

    if (statusCode != null) {
      if (statusCode == 400) {
        message =
            _extractErrorMessage(dioException.response?.data) ??
            'Invalid request. Please check your parameters.';
        type = ApiExceptionType.badRequest;
      } else if (statusCode == 401 || statusCode == 403) {
        message = AppStrings.unauthorizedError;
        type = ApiExceptionType.unauthorized;
      } else if (statusCode == 404) {
        message = AppStrings.notFoundError;
        type = ApiExceptionType.notFound;
      } else if (statusCode >= 500 && statusCode < 600) {
        message = AppStrings.serverError;
        type = ApiExceptionType.server;
      } else {
        message =
            _extractErrorMessage(dioException.response?.data) ??
            'Received unexpected status code: $statusCode';
      }
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      type: type,
      originalError: dioException,
    );
  }

  static String? _extractErrorMessage(dynamic data) {
    if (data is Map) {
      if (data.containsKey('detail') && data['detail'] != null) {
        return data['detail'].toString();
      }
      if (data.containsKey('message') && data['message'] != null) {
        return data['message'].toString();
      }
    }
    return null;
  }

  @override
  String toString() =>
      'ApiException(message: $message, statusCode: $statusCode, type: $type)';
}
