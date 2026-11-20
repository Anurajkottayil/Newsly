import '../core/constants/api_endpoints.dart';
import '../core/constants/app_constants.dart';
import '../core/errors/api_exception.dart';
import '../core/network/api_client.dart';
import '../models/report_model.dart';

/// Abstract contract for report operations to ensure testability and separation of concerns.
abstract class ReportRepository {
  Future<PaginatedReports> getReports({
    int limit = AppConstants.defaultPageSize,
    int offset = AppConstants.initialOffset,
    String? search,
  });

  Future<Report> getReportById(int id);
}

/// Concrete implementation of [ReportRepository] using [ApiClient].
class ReportRepositoryImpl implements ReportRepository {
  final ApiClient _apiClient;

  ReportRepositoryImpl({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  @override
  Future<PaginatedReports> getReports({
    int limit = AppConstants.defaultPageSize,
    int offset = AppConstants.initialOffset,
    String? search,
  }) async {
    final queryParameters = <String, dynamic>{'limit': limit, 'offset': offset};

    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    final data = await _apiClient.get(
      ApiEndpoints.reports,
      queryParameters: queryParameters,
    );

    if (data is Map) {
      return PaginatedReports.fromJson(Map<String, dynamic>.from(data));
    }

    throw const ApiException(
      message: 'Invalid response format received from server.',
      type: ApiExceptionType.unknown,
    );
  }

  @override
  Future<Report> getReportById(int id) async {
    if (id <= 0) {
      throw const ApiException(
        message: 'Invalid report ID provided. ID must be greater than zero.',
        type: ApiExceptionType.badRequest,
      );
    }

    final data = await _apiClient.get(ApiEndpoints.reportDetails(id));

    if (data is Map) {
      return Report.fromJson(Map<String, dynamic>.from(data));
    }

    throw const ApiException(
      message: 'Invalid response format received from server.',
      type: ApiExceptionType.unknown,
    );
  }
}
