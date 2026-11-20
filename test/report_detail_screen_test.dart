import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newsly/core/constants/app_strings.dart';
import 'package:newsly/core/errors/api_exception.dart';
import 'package:newsly/core/theme/app_theme.dart';
import 'package:newsly/models/report_model.dart';
import 'package:newsly/repositories/bookmark_repository.dart';
import 'package:newsly/repositories/report_repository.dart';
import 'package:newsly/shared/widgets/app_button.dart';
import 'package:newsly/shared/widgets/app_error_view.dart';
import 'package:newsly/shared/widgets/app_loader.dart';
import 'package:newsly/viewmodels/bookmark_view_model.dart';
import 'package:newsly/viewmodels/report_view_model.dart';
import 'package:newsly/views/screens/report_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockDetailReportRepository implements ReportRepository {
  List<Report> reportsToReturn;
  String? nextUrl;
  bool shouldThrow;
  bool shouldThrowOnGetById;
  int callCount = 0;
  int getByIdCallCount = 0;
  int? lastOffset;
  String? lastSearch;

  MockDetailReportRepository({
    this.reportsToReturn = const [],
    this.nextUrl,
    this.shouldThrow = false,
    this.shouldThrowOnGetById = false,
  });

  @override
  Future<PaginatedReports> getReports({
    int limit = 10,
    int offset = 0,
    String? search,
  }) async {
    callCount++;
    lastOffset = offset;
    lastSearch = search;
    if (shouldThrow) {
      throw const ApiException(
        message: 'Pagination network failure',
        type: ApiExceptionType.network,
      );
    }
    return PaginatedReports(
      count: reportsToReturn.length + (nextUrl != null ? 10 : 0),
      next: nextUrl,
      previous: null,
      results: reportsToReturn,
    );
  }

  @override
  Future<Report> getReportById(int id) async {
    getByIdCallCount++;
    if (shouldThrowOnGetById) {
      throw const ApiException(
        message: 'Failed to load report details',
        type: ApiExceptionType.network,
      );
    }
    return reportsToReturn.firstWhere((r) => r.id == id);
  }
}

void main() {
  final sampleReport1 = Report(
    id: 301,
    title: 'ISS Daily Summary Report - Expedition 70',
    authors: const [Author(name: 'NASA Ops')],
    url: 'https://example.com/report/301',
    imageUrl: 'https://example.com/iss_report.jpg',
    newsSite: 'ISS Operations',
    summary:
        'Expedition 70 crew conducted zero-gravity fluid physics investigations and station maintenance.',
    publishedAt: DateTime(2023, 4, 15, 12, 0),
  );

  final sampleReport2 = Report(
    id: 302,
    title: 'Commercial Crew Readiness Review',
    authors: const [Author(name: 'Safety Panel')],
    url: 'https://example.com/report/302',
    imageUrl: 'https://example.com/commercial_crew.jpg',
    newsSite: 'Aerospace Safety',
    summary: 'Assessment of commercial crew spacecraft hardware and landing operations.',
    publishedAt: DateTime(2023, 4, 16, 15, 30),
  );

  final sampleReport3 = Report(
    id: 303,
    title: 'Artemis Program Progress Report',
    authors: const [Author(name: 'GAO Team')],
    url: 'https://example.com/report/303',
    imageUrl: '', // Missing image test
    newsSite: 'GAO Space',
    summary: '', // Empty summary test
    publishedAt: null, // Null date test
  );

  Widget createStandaloneWidget({
    required Report report,
    ThemeData? theme,
    VoidCallback? onBack,
    BookmarkViewModel? bookmarkVm,
  }) {
    final app = MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      home: ReportDetailScreen(report: report, onBack: onBack),
    );
    if (bookmarkVm != null) {
      return ChangeNotifierProvider<BookmarkViewModel>.value(
        value: bookmarkVm,
        child: app,
      );
    }
    return app;
  }

  Widget createPagerWidget({
    required ReportViewModel viewModel,
    ReportRepository? repository,
    BookmarkViewModel? bookmarkVm,
    int? initialReportId,
    int? initialIndex,
    VoidCallback? onBack,
  }) {
    return MultiProvider(
      providers: [
        if (repository != null)
          Provider<ReportRepository>.value(value: repository),
        ChangeNotifierProvider<ReportViewModel>.value(value: viewModel),
        if (bookmarkVm != null)
          ChangeNotifierProvider<BookmarkViewModel>.value(value: bookmarkVm),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: ReportDetailScreen(
          initialReportId: initialReportId,
          initialIndex: initialIndex,
          onBack: onBack,
        ),
      ),
    );
  }

  group('ReportDetailScreen Standalone UI Tests', () {
    testWidgets('Detail screen renders report title, publisher, and summary', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createStandaloneWidget(report: sampleReport1));
      await tester.pump();

      expect(find.text('ISS Daily Summary Report - Expedition 70'), findsOneWidget);
      expect(find.text('ISS Operations'), findsOneWidget);
      expect(find.text('NASA Ops'), findsOneWidget);
      expect(
        find.text(
          'Expedition 70 crew conducted zero-gravity fluid physics investigations and station maintenance.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Read full report AppButton is displayed and accessible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createStandaloneWidget(report: sampleReport1));
      await tester.pump();

      expect(find.byType(AppButton), findsOneWidget);
      expect(find.text(AppStrings.readFullReport), findsOneWidget);
    });

    testWidgets('Floating back button invokes onBack callback', (
      WidgetTester tester,
    ) async {
      bool backTapped = false;
      await tester.pumpWidget(
        createStandaloneWidget(
          report: sampleReport1,
          onBack: () {
            backTapped = true;
          },
        ),
      );
      await tester.pump();

      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pump();

      expect(backTapped, isTrue);
    });

    testWidgets('Handles missing date, empty summary, and missing image gracefully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createStandaloneWidget(report: sampleReport3));
      await tester.pump();

      expect(find.text('Artemis Program Progress Report'), findsOneWidget);
      expect(find.text('GAO Space • Date unavailable'), findsOneWidget);
      expect(find.text('No summary available for this report.'), findsOneWidget);
      expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
    });

    testWidgets('Renders properly in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        createStandaloneWidget(report: sampleReport1, theme: AppTheme.darkTheme),
      );
      await tester.pump();

      expect(find.text('ISS Daily Summary Report - Expedition 70'), findsOneWidget);
      expect(find.text(AppStrings.readFullReport), findsOneWidget);
    });

    testWidgets('More options sheet displays Share, Copy Link, and Open in browser', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createStandaloneWidget(report: sampleReport1));
      await tester.pump();

      final moreButton = find.byTooltip(AppStrings.moreOptions);
      expect(moreButton, findsOneWidget);

      await tester.tap(moreButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(AppStrings.shareReport), findsOneWidget);
      expect(find.text(AppStrings.copyLink), findsOneWidget);
      expect(find.text(AppStrings.openOriginalReport), findsOneWidget);
    });

    testWidgets('Bookmark button toggles report bookmark state', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final repo = BookmarkRepositoryImpl();
      await repo.init();
      final bookmarkVm = BookmarkViewModel(repo);

      await tester.pumpWidget(
        createStandaloneWidget(report: sampleReport1, bookmarkVm: bookmarkVm),
      );
      await tester.pump();

      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
      expect(bookmarkVm.isReportBookmarked(sampleReport1.id), isFalse);

      await tester.tap(find.byTooltip(AppStrings.bookmarks));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
      expect(find.text(AppStrings.bookmarkSaved), findsOneWidget);
      expect(bookmarkVm.isReportBookmarked(sampleReport1.id), isTrue);

      await tester.tap(find.byTooltip(AppStrings.bookmarks));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
      expect(find.text(AppStrings.bookmarkRemoved), findsOneWidget);
      expect(bookmarkVm.isReportBookmarked(sampleReport1.id), isFalse);
    });
  });

  group('ReportDetailScreen Direct ID Fetch Tests', () {
    testWidgets('Direct ID fetch displays loader then renders fetched report', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockDetailReportRepository(reportsToReturn: [sampleReport1]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [Provider<ReportRepository>.value(value: mockRepo)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ReportDetailScreen(initialReportId: 301),
          ),
        ),
      );

      expect(find.byType(AppLoader), findsOneWidget);
      expect(find.text(AppStrings.loadingDetails), findsOneWidget);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AppLoader), findsNothing);
      expect(find.text('ISS Daily Summary Report - Expedition 70'), findsOneWidget);
      expect(find.text(AppStrings.readFullReport), findsOneWidget);
      expect(mockRepo.getByIdCallCount, 1);
    });

    testWidgets('Direct ID fetch failure displays AppErrorView with retry action', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockDetailReportRepository(
        reportsToReturn: [sampleReport1],
        shouldThrowOnGetById: true,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [Provider<ReportRepository>.value(value: mockRepo)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ReportDetailScreen(initialReportId: 301),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AppErrorView), findsOneWidget);
      expect(find.text('Failed to load report details'), findsOneWidget);

      mockRepo.shouldThrowOnGetById = false;
      await tester.tap(find.text(AppStrings.retry));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AppErrorView), findsNothing);
      expect(find.text('ISS Daily Summary Report - Expedition 70'), findsOneWidget);
      expect(mockRepo.getByIdCallCount, 2);
    });
  });

  group('ReportDetailScreen Book-Style Swipe Navigation & Pagination', () {
    testWidgets(
      'Swipe navigation transitions across reports in ViewModel feed',
      (WidgetTester tester) async {
        final mockRepo = MockDetailReportRepository(
          reportsToReturn: [sampleReport1, sampleReport2, sampleReport3],
        );
        final viewModel = ReportViewModel(mockRepo);
        await viewModel.fetchReports();

        await tester.pumpWidget(
          createPagerWidget(
            viewModel: viewModel,
            repository: mockRepo,
            initialIndex: 0,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text(sampleReport1.title), findsOneWidget);
        expect(find.text(sampleReport2.title), findsNothing);

        // Swipe left to Report 2
        await tester.drag(find.byType(PageView), const Offset(-500, 0));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text(sampleReport2.title), findsOneWidget);

        // Swipe right back to Report 1
        await tester.drag(find.byType(PageView), const Offset(500, 0));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text(sampleReport1.title), findsOneWidget);
      },
    );
  });
}
