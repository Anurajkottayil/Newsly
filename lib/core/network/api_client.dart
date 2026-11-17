import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_endpoints.dart';
import '../constants/app_constants.dart';
import '../errors/api_exception.dart';

/// Centralized Dio-based HTTP client for the Newsly application.
///
/// Handles timeout configurations, interceptors for sanitized logging,
/// and mapping low-level network errors into strongly-typed [ApiException]s.
class ApiClient {
  late final Dio _dio;

  ApiClient({Dio? customDio}) {
    _dio =
        customDio ??
        Dio(
          BaseOptions(
            baseUrl: ApiEndpoints.baseUrl,
            connectTimeout: AppConstants.connectTimeout,
            receiveTimeout: AppConstants.receiveTimeout,
            sendTimeout: AppConstants.sendTimeout,
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            responseType: ResponseType.json,
          ),
        );

    _setupInterceptors();
  }

  Dio get dio => _dio;

  void _setupInterceptors() {
    // Interceptor that provides safe, sanitized logging during debug mode only.
    // Avoids exposing sensitive headers or credentials.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (kDebugMode) {
            debugPrint('[API Request] ${options.method} -> ${options.uri}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              '[API Response] [${response.statusCode}] <- ${response.requestOptions.uri}',
            );
          }
          handler.next(response);
        },
        onError: (DioException error, handler) {
          if (kDebugMode) {
            debugPrint(
              '[API Error] [${error.response?.statusCode}] ${error.type} for ${error.requestOptions.uri}',
            );
          }
          handler.next(error);
        },
      ),
    );
  }

  /// Performs a sanitized GET request to [endpoint].
  ///
  /// Throws [ApiException] on any failure.
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      );
      return response.data;
    } on DioException catch (dioError) {
      throw ApiException.fromDioException(dioError);
    } catch (error) {
      throw ApiException(
        message: error.toString(),
        type: ApiExceptionType.unknown,
        originalError: error,
      );
    }
  }
}
