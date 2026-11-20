import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newsly/core/constants/api_endpoints.dart';
import 'package:newsly/core/constants/app_constants.dart';
import 'package:newsly/core/errors/api_exception.dart';
import 'package:newsly/core/network/api_client.dart';
import 'package:newsly/models/report_model.dart';
import 'package:newsly/repositories/report_repository.dart';

/// Controllable fake [ApiClient] for repository unit testing.
class FakeApiClient extends ApiClient {
  dynamic responseData;
  ApiException? exceptionToThrow;
  String? lastEndpoint;
  Map<String, dynamic>? lastQueryParams;
  int callCount = 0;

  FakeApiClient({this.responseData, this.exceptionToThrow});

  @override
  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    callCount++;
    lastEndpoint = endpoint;
    lastQueryParams = queryParameters;

    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return responseData;
  }
}

void main() {
  group('ReportRepositoryImpl Unit Tests', () {
    final sampleReportJson = {
      'id': 101,
      'title': 'NASA ISS Operations Summary',
      'authors': [
        {'name': 'Flight Control', 'socials': null},
      ],
      'url': 'https://blogs.nasa.gov/stationreport/101',
      'image_url': 'https://images.nasa.gov/101.jpg',
      'news_site': 'NASA',
      'summary': 'Daily orbital status briefing.',
      'published_at': '2026-11-20T12:00:00Z',
      'updated_at': '2026-11-20T13:00:00Z',
    };

    final samplePaginatedJson = {
      'count': 1,
      'next': null,
      'previous': null,
      'results': [sampleReportJson],
    };

    test('1. Successful paginated Reports response', () async {
      final fakeClient = FakeApiClient(responseData: samplePaginatedJson);
      final repository = ReportRepositoryImpl(apiClient: fakeClient);

      final result = await repository.getReports();

      expect(result, isA<PaginatedReports>());
      expect(result.count, 1);
      expect(result.results.length, 1);
      expect(result.results.first.id, 101);
      expect(result.results.first.title, 'NASA ISS Operations Summary');
    });

    test('2. Correct collection endpoint', () async {
      final fakeClient = FakeApiClient(responseData: samplePaginatedJson);
      final repository = ReportRepositoryImpl(apiClient: fakeClient);

      await repository.getReports();

      expect(fakeClient.lastEndpoint, ApiEndpoints.reports);
      expect(fakeClient.lastEndpoint, '/reports/');
    });

    test('3. Correct limit, offset, and search query parameters', () async {
      final fakeClient = FakeApiClient(responseData: samplePaginatedJson);
      final repository = ReportRepositoryImpl(apiClient: fakeClient);

      await repository.getReports(limit: 25, offset: 50, search: 'ISS');

      expect(fakeClient.lastQueryParams?['limit'], 25);
      expect(fakeClient.lastQueryParams?['offset'], 50);
      expect(fakeClient.lastQueryParams?['search'], 'ISS');
    });

    test('4. Optional query parameters are omitted when not supplied or empty', () async {
      final fakeClient = FakeApiClient(responseData: samplePaginatedJson);
      final repository = ReportRepositoryImpl(apiClient: fakeClient);

      // Default call: search omitted
      await repository.getReports();
      expect(fakeClient.lastQueryParams?['limit'], AppConstants.defaultPageSize);
      expect(fakeClient.lastQueryParams?['offset'], AppConstants.initialOffset);
      expect(fakeClient.lastQueryParams?.containsKey('search'), isFalse);

      // Null search: search omitted
      await repository.getReports(search: null);
      expect(fakeClient.lastQueryParams?.containsKey('search'), isFalse);

      // Empty search: search omitted
      await repository.getReports(search: '');
      expect(fakeClient.lastQueryParams?.containsKey('search'), isFalse);

      // Whitespace search: search omitted
      await repository.getReports(search: '   ');
      expect(fakeClient.lastQueryParams?.containsKey('search'), isFalse);
    });

    test('5. Successful report detail response', () async {
      final fakeClient = FakeApiClient(responseData: sampleReportJson);
      final repository = ReportRepositoryImpl(apiClient: fakeClient);

      final result = await repository.getReportById(101);

      expect(result, isA<Report>());
      expect(result.id, 101);
      expect(result.title, 'NASA ISS Operations Summary');
      expect(result.newsSite, 'NASA');
      expect(result.summary, 'Daily orbital status briefing.');
    });

    test('6. Correct report detail URL and ID', () async {
      final fakeClient = FakeApiClient(responseData: sampleReportJson);
      final repository = ReportRepositoryImpl(apiClient: fakeClient);

      await repository.getReportById(101);

      expect(fakeClient.lastEndpoint, ApiEndpoints.reportDetails(101));
      expect(fakeClient.lastEndpoint, '/reports/101/');
      expect(fakeClient.lastQueryParams, isNull);
    });

    test('7. API/network error mapping propagates ApiException', () async {
      final fakeClient = FakeApiClient(
        exceptionToThrow: const ApiException(
          message: 'Connection timed out.',
          type: ApiExceptionType.timeout,
          statusCode: 408,
        ),
      );
      final repository = ReportRepositoryImpl(apiClient: fakeClient);

      expect(
        () => repository.getReports(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.type, 'type', ApiExceptionType.timeout)
              .having((e) => e.statusCode, 'statusCode', 408)
              .having((e) => e.message, 'message', 'Connection timed out.'),
        ),
      );

      expect(
        () => repository.getReportById(101),
        throwsA(
          isA<ApiException>()
              .having((e) => e.type, 'type', ApiExceptionType.timeout)
              .having((e) => e.statusCode, 'statusCode', 408),
        ),
      );
    });

    test('8. Invalid detail ID is rejected safely before network call', () async {
      final fakeClient = FakeApiClient(responseData: sampleReportJson);
      final repository = ReportRepositoryImpl(apiClient: fakeClient);

      final invalidIds = [0, -1, -99];
      for (final invalidId in invalidIds) {
        expect(
          () => repository.getReportById(invalidId),
          throwsA(
            isA<ApiException>()
                .having((e) => e.type, 'type', ApiExceptionType.badRequest)
                .having((e) => e.message, 'message', contains('Invalid report ID')),
          ),
        );
      }
      expect(fakeClient.callCount, 0); // Network call was never made
    });

    test('9. Malformed response handling on getReports and getReportById', () async {
      final fakeClient = FakeApiClient();
      final repository = ReportRepositoryImpl(apiClient: fakeClient);

      final malformedPayloads = [null, '', <dynamic>[], 123, true, 'not json'];
      for (final payload in malformedPayloads) {
        fakeClient.responseData = payload;

        expect(
          () => repository.getReports(),
          throwsA(
            isA<ApiException>()
                .having((e) => e.type, 'type', ApiExceptionType.unknown)
                .having(
                  (e) => e.message,
                  'message',
                  'Invalid response format received from server.',
                ),
          ),
        );

        expect(
          () => repository.getReportById(101),
          throwsA(
            isA<ApiException>()
                .having((e) => e.type, 'type', ApiExceptionType.unknown)
                .having(
                  (e) => e.message,
                  'message',
                  'Invalid response format received from server.',
                ),
          ),
        );
      }
    });
  });
}
