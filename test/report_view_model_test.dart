import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:newsly/core/constants/app_constants.dart';
import 'package:newsly/core/errors/api_exception.dart';
import 'package:newsly/models/report_model.dart';
import 'package:newsly/repositories/report_repository.dart';
import 'package:newsly/viewmodels/report_view_model.dart';

/// Controllable Fake [ReportRepository] for testing ViewModel state transitions.
class FakeReportRepository implements ReportRepository {
  PaginatedReports? paginatedResponse;
  Report? detailResponse;
  Exception? exceptionToThrow;
  int callCount = 0;
  String? lastSearch;
  int? lastLimit;
  int? lastOffset;
  Future<PaginatedReports> Function(int limit, int offset, String? search)?
  onGetReports;

  FakeReportRepository({
    this.paginatedResponse,
    this.detailResponse,
    this.exceptionToThrow,
    this.onGetReports,
  });

  @override
  Future<PaginatedReports> getReports({
    int limit = AppConstants.defaultPageSize,
    int offset = AppConstants.initialOffset,
    String? search,
  }) async {
    callCount++;
    lastLimit = limit;
    lastOffset = offset;
    lastSearch = search;

    if (onGetReports != null) {
      return await onGetReports!(limit, offset, search);
    }
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return paginatedResponse ??
        const PaginatedReports(
          count: 0,
          next: null,
          previous: null,
          results: [],
        );
  }

  @override
  Future<Report> getReportById(int id) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return detailResponse!;
  }
}

Report createMockReport(int id, {String title = 'Report'}) {
  return Report(
    id: id,
    title: '$title $id',
    authors: const [],
    url: 'https://example.com/$id',
    imageUrl: 'https://example.com/img/$id.jpg',
    newsSite: 'NASA',
    summary: 'Summary $id',
    publishedAt: DateTime.utc(2026, 11, 20),
    updatedAt: DateTime.utc(2026, 11, 20),
  );
}

void main() {
  group('ReportViewModel Comprehensive Tests', () {
    test('1. Initial Reports loading sets ViewState.loading then loaded', () async {
      final repository = FakeReportRepository(
        paginatedResponse: PaginatedReports(
          count: 1,
          next: null,
          previous: null,
          results: [createMockReport(1)],
        ),
      );
      final viewModel = ReportViewModel(repository);

      expect(viewModel.state, ViewState.initial);
      expect(viewModel.isLoading, isFalse);

      final future = viewModel.fetchReports();
      expect(viewModel.isLoading, isTrue);
      expect(viewModel.state, ViewState.loading);

      await future;
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.state, ViewState.loaded);
      expect(viewModel.reports.length, 1);
    });

    test('2. Successful loading with multiple reports', () async {
      final reports = List.generate(5, (i) => createMockReport(i + 1));
      final repository = FakeReportRepository(
        paginatedResponse: PaginatedReports(
          count: 5,
          next: 'https://api.spaceflightnewsapi.net/v4/reports/?offset=5',
          previous: null,
          results: reports,
        ),
      );
      final viewModel = ReportViewModel(repository);

      await viewModel.fetchReports();

      expect(viewModel.state, ViewState.loaded);
      expect(viewModel.reports.length, 5);
      expect(viewModel.totalCount, 5);
      expect(viewModel.hasMore, isTrue);
      expect(viewModel.errorMessage, isNull);
    });

    test('3. Empty Reports response sets ViewState.empty', () async {
      final repository = FakeReportRepository(
        paginatedResponse: const PaginatedReports(
          count: 0,
          next: null,
          previous: null,
          results: [],
        ),
      );
      final viewModel = ReportViewModel(repository);

      await viewModel.fetchReports();

      expect(viewModel.state, ViewState.empty);
      expect(viewModel.isEmpty, isTrue);
      expect(viewModel.reports, isEmpty);
      expect(viewModel.totalCount, 0);
      expect(viewModel.hasMore, isFalse);
    });

    test('4. Initial API failure sets ViewState.error and error message', () async {
      final repository = FakeReportRepository(
        exceptionToThrow: const ApiException(
          message: 'Server error occurred.',
          type: ApiExceptionType.server,
          statusCode: 500,
        ),
      );
      final viewModel = ReportViewModel(repository);

      await viewModel.fetchReports();

      expect(viewModel.state, ViewState.error);
      expect(viewModel.hasError, isTrue);
      expect(viewModel.errorMessage, 'Server error occurred.');
      expect(viewModel.reports, isEmpty);
      expect(viewModel.isLoading, isFalse);
    });

    test('5. Pagination appends reports and advances offset', () async {
      final page1 = [createMockReport(1), createMockReport(2)];
      final page2 = [createMockReport(3), createMockReport(4)];

      final repository = FakeReportRepository(
        onGetReports: (limit, offset, search) async {
          if (offset == 0) {
            return PaginatedReports(
              count: 4,
              next: 'https://api.spaceflightnewsapi.net/v4/reports/?offset=2',
              previous: null,
              results: page1,
            );
          } else {
            return PaginatedReports(
              count: 4,
              next: null,
              previous: 'https://api.spaceflightnewsapi.net/v4/reports/?offset=0',
              results: page2,
            );
          }
        },
      );
      final viewModel = ReportViewModel(repository);

      await viewModel.fetchReports();
      expect(viewModel.reports.map((r) => r.id).toList(), [1, 2]);
      expect(viewModel.hasMore, isTrue);

      await viewModel.loadMore();
      expect(viewModel.reports.map((r) => r.id).toList(), [1, 2, 3, 4]);
      expect(viewModel.hasMore, isFalse);
      expect(viewModel.isLoadingMore, isFalse);
    });

    test('6. Duplicate IDs are not added during pagination', () async {
      final page1 = [createMockReport(1), createMockReport(2)];
      final page2 = [createMockReport(2), createMockReport(3)]; // duplicate ID 2

      final repository = FakeReportRepository(
        onGetReports: (limit, offset, search) async {
          if (offset == 0) {
            return PaginatedReports(
              count: 3,
              next: 'https://next',
              previous: null,
              results: page1,
            );
          } else {
            return PaginatedReports(
              count: 3,
              next: null,
              previous: null,
              results: page2,
            );
          }
        },
      );
      final viewModel = ReportViewModel(repository);

      await viewModel.fetchReports();
      await viewModel.loadMore();

      expect(viewModel.reports.map((r) => r.id).toList(), [1, 2, 3]);
      expect(viewModel.reports.length, 3);
    });

    test('7. Repeated pagination calls do not cause duplicate requests', () async {
      final completer = Completer<PaginatedReports>();
      final repository = FakeReportRepository(
        onGetReports: (limit, offset, search) async {
          if (offset == 0) {
            return PaginatedReports(
              count: 10,
              next: 'https://next',
              previous: null,
              results: [createMockReport(1)],
            );
          }
          return completer.future;
        },
      );
      final viewModel = ReportViewModel(repository);

      await viewModel.fetchReports();
      expect(repository.callCount, 1);

      // Trigger loadMore multiple times concurrently
      final f1 = viewModel.loadMore();
      final f2 = viewModel.loadMore();
      final f3 = viewModel.loadMore();

      expect(viewModel.isLoadingMore, isTrue);
      expect(repository.callCount, 2); // only 1 additional call made

      completer.complete(
        PaginatedReports(
          count: 10,
          next: null,
          previous: null,
          results: [createMockReport(2)],
        ),
      );
      await Future.wait([f1, f2, f3]);

      expect(repository.callCount, 2);
      expect(viewModel.reports.length, 2);
    });

    test('8. No more pages are requested when hasMore is false', () async {
      final repository = FakeReportRepository(
        paginatedResponse: PaginatedReports(
          count: 1,
          next: null,
          previous: null,
          results: [createMockReport(1)],
        ),
      );
      final viewModel = ReportViewModel(repository);

      await viewModel.fetchReports();
      expect(viewModel.hasMore, isFalse);

      await viewModel.loadMore();
      expect(repository.callCount, 1); // Not called again
    });

    test('9. Search debouncing delays execution until timer fires', () async {
      final repository = FakeReportRepository(
        paginatedResponse: PaginatedReports(
          count: 1,
          next: null,
          previous: null,
          results: [createMockReport(10)],
        ),
      );
      final viewModel = ReportViewModel(repository);

      viewModel.searchDebounced(
        'NASA',
        debounceDuration: const Duration(milliseconds: 50),
      );

      // Before timer fires, no call made
      expect(repository.callCount, 0);

      // Wait for debounce timer to fire
      await Future.delayed(const Duration(milliseconds: 70));

      expect(repository.callCount, 1);
      expect(repository.lastSearch, 'NASA');
    });

    test('10. Search resets pagination to offset 0', () async {
      final repository = FakeReportRepository(
        onGetReports: (limit, offset, search) async {
          return PaginatedReports(
            count: 5,
            next: offset == 0 ? 'https://next' : null,
            previous: null,
            results: [createMockReport(offset + 1)],
          );
        },
      );
      final viewModel = ReportViewModel(repository);

      await viewModel.fetchReports();
      await viewModel.loadMore();
      expect(viewModel.currentOffset, 1);

      // New search resets offset
      await viewModel.fetchReports(search: 'ISS', refresh: true);
      expect(viewModel.currentOffset, 0);
      expect(repository.lastSearch, 'ISS');
    });

    test('11. Older in-flight response cannot overwrite a newer response', () async {
      final completerPage2 = Completer<PaginatedReports>();

      final repository = FakeReportRepository(
        onGetReports: (limit, offset, search) async {
          if (offset == 0) {
            return PaginatedReports(
              count: 10,
              next: 'https://api.spaceflightnewsapi.net/v4/reports/?offset=1',
              previous: null,
              results: [createMockReport(1, title: 'Original Page 1')],
            );
          }
          return completerPage2.future;
        },
      );
      final viewModel = ReportViewModel(repository);

      // Initial fetch loads Page 1
      await viewModel.fetchReports();
      expect(viewModel.reports.map((r) => r.id).toList(), [1]);

      // Start loadMore (remains in flight)
      final loadMoreFuture = viewModel.loadMore();
      expect(viewModel.isLoadingMore, isTrue);

      // Newer search/refresh arrives while loadMore is still in flight
      repository.onGetReports = (limit, offset, search) async {
        return PaginatedReports(
          count: 1,
          next: null,
          previous: null,
          results: [createMockReport(999, title: 'Refreshed 999')],
        );
      };
      await viewModel.fetchReports(refresh: true, search: 'SpaceX');
      expect(viewModel.reports.map((r) => r.id).toList(), [999]);
      expect(viewModel.searchQuery, 'SpaceX');

      // Obsolete loadMore response resolves later with contradictory old data
      completerPage2.complete(
        PaginatedReports(
          count: 50,
          next: null,
          previous: null,
          results: [createMockReport(2, title: 'Old Page 2 Report')],
        ),
      );
      await loadMoreFuture;

      // Obsolete response was rejected: feed still contains only refreshed 999
      expect(viewModel.reports.map((r) => r.id).toList(), [999]);
      expect(viewModel.totalCount, 1);
      expect(viewModel.isLoadingMore, isFalse);
    });

    test('12. Refresh resets pagination to offset 0', () async {
      final repository = FakeReportRepository(
        onGetReports: (limit, offset, search) async {
          return PaginatedReports(
            count: 10,
            next: 'https://next',
            previous: null,
            results: [createMockReport(offset + 1)],
          );
        },
      );
      final viewModel = ReportViewModel(repository);

      await viewModel.fetchReports();
      await viewModel.loadMore();
      expect(viewModel.reports.length, 2);

      await viewModel.fetchReports(refresh: true);
      expect(viewModel.currentOffset, 0);
      expect(repository.lastOffset, 0);
    });

    test('13. Refresh failure preserves existing data and sets errorMessage', () async {
      bool shouldFail = false;
      final repository = FakeReportRepository(
        onGetReports: (limit, offset, search) async {
          if (shouldFail) {
            throw const ApiException(
              message: 'Network drop during refresh.',
              type: ApiExceptionType.network,
            );
          }
          return PaginatedReports(
            count: 2,
            next: null,
            previous: null,
            results: [createMockReport(1), createMockReport(2)],
          );
        },
      );
      final viewModel = ReportViewModel(repository);

      await viewModel.fetchReports();
      expect(viewModel.reports.length, 2);
      expect(viewModel.state, ViewState.loaded);

      // Trigger failing refresh
      shouldFail = true;
      await viewModel.fetchReports(refresh: true);

      // Existing reports preserved, state remains loaded with errorMessage set
      expect(viewModel.reports.length, 2);
      expect(viewModel.state, ViewState.loaded);
      expect(viewModel.errorMessage, 'Network drop during refresh.');
    });

    test('14. Pagination failure preserves existing reports and sets paginationError', () async {
      final repository = FakeReportRepository(
        onGetReports: (limit, offset, search) async {
          if (offset == 0) {
            return PaginatedReports(
              count: 4,
              next: 'https://next',
              previous: null,
              results: [createMockReport(1), createMockReport(2)],
            );
          }
          throw const ApiException(
            message: 'Timeout fetching next page.',
            type: ApiExceptionType.timeout,
          );
        },
      );
      final viewModel = ReportViewModel(repository);

      await viewModel.fetchReports();
      expect(viewModel.reports.length, 2);

      await viewModel.loadMore();
      expect(viewModel.reports.length, 2); // preserved
      expect(viewModel.paginationError, 'Timeout fetching next page.');
      expect(viewModel.isLoadingMore, isFalse);
    });

    test('15. Loading flags reset after failures', () async {
      final repository = FakeReportRepository(
        exceptionToThrow: const ApiException(
          message: 'Generic failure',
          type: ApiExceptionType.unknown,
        ),
      );
      final viewModel = ReportViewModel(repository);

      await viewModel.fetchReports();
      expect(viewModel.isLoading, isFalse);
      expect(viewModel.isLoadingMore, isFalse);
    });

    test('16. Prefetch triggers loadMore at the established threshold', () async {
      final reports = List.generate(10, (i) => createMockReport(i + 1));
      final repository = FakeReportRepository(
        onGetReports: (limit, offset, search) async {
          if (offset == 0) {
            return PaginatedReports(
              count: 20,
              next: 'https://next',
              previous: null,
              results: reports,
            );
          }
          return PaginatedReports(
            count: 20,
            next: null,
            previous: null,
            results: [createMockReport(11)],
          );
        },
      );
      final viewModel = ReportViewModel(repository);

      await viewModel.fetchReports();
      expect(repository.callCount, 1);

      // Index 2 is not near end (threshold 3, length 10 -> index >= 7 triggers)
      await viewModel.prefetchIfNeeded(2, threshold: 3);
      expect(repository.callCount, 1);

      // Index 8 is >= 7, triggers prefetch
      await viewModel.prefetchIfNeeded(8, threshold: 3);
      expect(repository.callCount, 2);
      expect(viewModel.reports.length, 11);
    });

    test('17. Duplicate prefetch requests are prevented', () async {
      final completer = Completer<PaginatedReports>();
      final repository = FakeReportRepository(
        onGetReports: (limit, offset, search) async {
          if (offset == 0) {
            return PaginatedReports(
              count: 10,
              next: 'https://next',
              previous: null,
              results: List.generate(5, (i) => createMockReport(i + 1)),
            );
          }
          return completer.future;
        },
      );
      final viewModel = ReportViewModel(repository);

      await viewModel.fetchReports();
      expect(repository.callCount, 1);

      // First prefetch triggers
      final f1 = viewModel.prefetchIfNeeded(4, threshold: 2);
      expect(viewModel.isLoadingMore, isTrue);

      // Second prefetch while first in flight is ignored
      final f2 = viewModel.prefetchIfNeeded(4, threshold: 2);
      expect(repository.callCount, 2);

      completer.complete(
        const PaginatedReports(count: 10, next: null, previous: null, results: []),
      );
      await Future.wait([f1, f2]);
      expect(repository.callCount, 2);
    });

    test('18. Prefetch failure does not incorrectly replace visible feed state', () async {
      final repository = FakeReportRepository(
        onGetReports: (limit, offset, search) async {
          if (offset == 0) {
            return PaginatedReports(
              count: 5,
              next: 'https://next',
              previous: null,
              results: [createMockReport(1), createMockReport(2)],
            );
          }
          throw const ApiException(
            message: 'Prefetch network error.',
            type: ApiExceptionType.network,
          );
        },
      );
      final viewModel = ReportViewModel(repository);

      await viewModel.fetchReports();
      expect(viewModel.state, ViewState.loaded);

      await viewModel.prefetchIfNeeded(1, threshold: 2);
      // State remains loaded, error captured in paginationError
      expect(viewModel.state, ViewState.loaded);
      expect(viewModel.hasError, isFalse);
      expect(viewModel.paginationError, 'Prefetch network error.');
    });

    test('19. Disposal invalidates pending requests and cancels debounce work', () async {
      final repository = FakeReportRepository(
        paginatedResponse: PaginatedReports(
          count: 1,
          next: null,
          previous: null,
          results: [createMockReport(1)],
        ),
      );
      final viewModel = ReportViewModel(repository);

      viewModel.searchDebounced(
        'NASA',
        debounceDuration: const Duration(milliseconds: 100),
      );

      // Dispose immediately
      viewModel.dispose();

      // Wait past debounce duration
      await Future.delayed(const Duration(milliseconds: 120));

      // Callback should never have run
      expect(repository.callCount, 0);
    });
  });
}
