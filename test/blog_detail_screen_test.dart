import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newsly/core/constants/app_strings.dart';
import 'package:newsly/core/errors/api_exception.dart';
import 'package:newsly/core/theme/app_theme.dart';
import 'package:newsly/models/blog_model.dart';
import 'package:newsly/repositories/blog_repository.dart';
import 'package:newsly/shared/widgets/app_button.dart';
import 'package:newsly/shared/widgets/app_error_view.dart';
import 'package:newsly/shared/widgets/app_loader.dart';
import 'package:newsly/viewmodels/blog_view_model.dart';
import 'package:newsly/views/screens/blog_detail_screen.dart';
import 'package:provider/provider.dart';

class MockDetailBlogRepository implements BlogRepository {
  List<Blog> blogsToReturn;
  String? nextUrl;
  bool shouldThrow;
  bool shouldThrowOnGetById;
  int callCount = 0;
  int getByIdCallCount = 0;
  int? lastOffset;
  String? lastSearch;

  MockDetailBlogRepository({
    this.blogsToReturn = const [],
    this.nextUrl,
    this.shouldThrow = false,
    this.shouldThrowOnGetById = false,
  });

  @override
  Future<PaginatedBlogs> getBlogs({
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
    return PaginatedBlogs(
      count: blogsToReturn.length + (nextUrl != null ? 10 : 0),
      next: nextUrl,
      previous: null,
      results: blogsToReturn,
    );
  }

  @override
  Future<Blog> getBlogById(int id) async {
    getByIdCallCount++;
    if (shouldThrowOnGetById) {
      throw const ApiException(
        message: 'Failed to load blog details',
        type: ApiExceptionType.network,
      );
    }
    return blogsToReturn.firstWhere((b) => b.id == id);
  }
}

void main() {
  final sampleBlog1 = Blog(
    id: 201,
    title: 'James Webb Explores Deep Space',
    authors: const [Author(name: 'Jane Doe')],
    url: 'https://example.com/blog/201',
    imageUrl: 'https://example.com/jwst.jpg',
    newsSite: 'NASA Blog',
    summary:
        'James Webb Space Telescope observes the early universe with unmatched infrared precision.',
    publishedAt: DateTime(2023, 3, 10, 10, 0),
    featured: true,
  );

  final sampleBlog2 = Blog(
    id: 202,
    title: 'Starship Flight 5 Analysis',
    authors: const [Author(name: 'Elon Fan')],
    url: 'https://example.com/blog/202',
    imageUrl: 'https://example.com/starship.jpg',
    newsSite: 'SpaceX Blog',
    summary:
        'Catching the Super Heavy booster with mechanical launch tower arms.',
    publishedAt: DateTime(2023, 3, 11, 14, 0),
    featured: false,
  );

  final sampleBlog3 = Blog(
    id: 203,
    title: 'ESA Juice Mission Trajectory',
    authors: const [Author(name: 'ESA Team')],
    url: 'https://example.com/blog/203',
    imageUrl: 'https://example.com/juice.jpg',
    newsSite: 'ESA Blog',
    summary:
        'Juice completes its complex double gravity assist planetary flyby.',
    publishedAt: null, // Test nullable date
    featured: false,
  );

  Widget createStandaloneWidget({
    required Blog blog,
    ThemeData? theme,
    VoidCallback? onBack,
  }) {
    return MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      home: BlogDetailScreen(blog: blog, onBack: onBack),
    );
  }

  Widget createPagerWidget({
    required BlogViewModel viewModel,
    BlogRepository? repository,
    int? initialBlogId,
    int? initialIndex,
    VoidCallback? onBack,
  }) {
    return MultiProvider(
      providers: [
        if (repository != null)
          Provider<BlogRepository>.value(value: repository),
        ChangeNotifierProvider<BlogViewModel>.value(value: viewModel),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: BlogDetailScreen(
          initialBlogId: initialBlogId,
          initialIndex: initialIndex,
          onBack: onBack,
        ),
      ),
    );
  }

  group('BlogDetailScreen Standalone UI Tests', () {
    testWidgets('Detail screen renders blog title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createStandaloneWidget(blog: sampleBlog1));
      await tester.pump();

      expect(find.text('James Webb Explores Deep Space'), findsOneWidget);
    });

    testWidgets('Source and publisher are displayed without unverified badge', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createStandaloneWidget(blog: sampleBlog1));
      await tester.pump();

      expect(find.text('NASA Blog'), findsOneWidget);
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsNothing);
      expect(find.textContaining(AppStrings.trending), findsOneWidget);
    });

    testWidgets('Summary content is displayed with proper typography', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createStandaloneWidget(blog: sampleBlog1));
      await tester.pump();

      expect(
        find.text(
          'James Webb Space Telescope observes the early universe with unmatched infrared precision.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Read full blog post AppButton is displayed and accessible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createStandaloneWidget(blog: sampleBlog1));
      await tester.pump();

      expect(find.byType(AppButton), findsOneWidget);
      expect(find.text(AppStrings.readFullBlogPost), findsOneWidget);
    });

    testWidgets('Floating back button invokes onBack callback', (
      WidgetTester tester,
    ) async {
      bool backTapped = false;
      await tester.pumpWidget(
        createStandaloneWidget(
          blog: sampleBlog1,
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

    testWidgets('Renders null published date as Date unavailable', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createStandaloneWidget(blog: sampleBlog3));
      await tester.pump();

      expect(find.text('ESA Blog • Date unavailable'), findsOneWidget);
    });

    testWidgets('Renders properly in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        createStandaloneWidget(blog: sampleBlog1, theme: AppTheme.darkTheme),
      );
      await tester.pump();

      expect(find.text('James Webb Explores Deep Space'), findsOneWidget);
      expect(find.text('NASA Blog'), findsOneWidget);
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text(AppStrings.readFullBlogPost), findsOneWidget);
    });
  });

  group('BlogDetailScreen Direct ID Fetch Tests', () {
    testWidgets('Direct ID fetch displays loader then renders fetched blog', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockDetailBlogRepository(blogsToReturn: [sampleBlog1]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [Provider<BlogRepository>.value(value: mockRepo)],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const BlogDetailScreen(initialBlogId: 201),
          ),
        ),
      );

      // Verify loader on initial render
      expect(find.byType(AppLoader), findsOneWidget);
      expect(find.text(AppStrings.loadingDetails), findsOneWidget);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify fetched blog renders
      expect(find.byType(AppLoader), findsNothing);
      expect(find.text('James Webb Explores Deep Space'), findsOneWidget);
      expect(find.text(AppStrings.readFullBlogPost), findsOneWidget);
      expect(mockRepo.getByIdCallCount, 1);
    });

    testWidgets(
      'Direct ID fetch failure displays AppErrorView with retry action',
      (WidgetTester tester) async {
        final mockRepo = MockDetailBlogRepository(
          blogsToReturn: [sampleBlog1],
          shouldThrowOnGetById: true,
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [Provider<BlogRepository>.value(value: mockRepo)],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const BlogDetailScreen(initialBlogId: 201),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Error view displayed
        expect(find.byType(AppErrorView), findsOneWidget);
        expect(find.text('Failed to load blog details'), findsOneWidget);

        // Fix repo and retry
        mockRepo.shouldThrowOnGetById = false;
        await tester.tap(find.text(AppStrings.retry));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Blog loaded
        expect(find.byType(AppErrorView), findsNothing);
        expect(find.text('James Webb Explores Deep Space'), findsOneWidget);
        expect(mockRepo.getByIdCallCount, 2);
      },
    );
  });

  group('BlogDetailScreen Book-Style Swipe Navigation & Pagination', () {
    testWidgets(
      'Required Gesture Tests: 1->2 (left), 2->3 (left), 3->2 (right), 2->1 (right)',
      (WidgetTester tester) async {
        final mockRepo = MockDetailBlogRepository(
          blogsToReturn: [sampleBlog1, sampleBlog2, sampleBlog3],
        );
        final viewModel = BlogViewModel(mockRepo);
        await viewModel.fetchBlogs();

        await tester.pumpWidget(
          createPagerWidget(
            viewModel: viewModel,
            repository: mockRepo,
            initialIndex: 0,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Start at Blog 1
        expect(find.text(sampleBlog1.title), findsOneWidget);
        expect(find.text(sampleBlog2.title), findsNothing);
        expect(find.text(sampleBlog3.title), findsNothing);

        // 1. Start at Blog 1, drag from right to left (dx < 0) -> verify Blog 2 appears
        await tester.drag(find.byType(PageView), const Offset(-500, 0));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text(sampleBlog2.title), findsOneWidget);

        // 2. From Blog 2, drag from right to left (dx < 0) -> verify Blog 3 appears
        await tester.drag(find.byType(PageView), const Offset(-500, 0));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text(sampleBlog3.title), findsOneWidget);

        // 3. From Blog 3, drag from left to right (dx > 0) -> verify Blog 2 appears
        await tester.drag(find.byType(PageView), const Offset(500, 0));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text(sampleBlog2.title), findsOneWidget);

        // 4. From Blog 2, drag from left to right (dx > 0) -> verify Blog 1 appears
        await tester.drag(find.byType(PageView), const Offset(500, 0));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text(sampleBlog1.title), findsOneWidget);
      },
    );

    testWidgets(
      'Boundary behavior: first blog clamps on right swipe, last blog clamps on left swipe',
      (WidgetTester tester) async {
        final mockRepo = MockDetailBlogRepository(
          blogsToReturn: [sampleBlog1, sampleBlog2],
        );
        final viewModel = BlogViewModel(mockRepo);
        await viewModel.fetchBlogs();

        await tester.pumpWidget(
          createPagerWidget(
            viewModel: viewModel,
            repository: mockRepo,
            initialIndex: 0,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Start at first blog (Blog 1)
        expect(find.text(sampleBlog1.title), findsOneWidget);

        // Drag RIGHT (dx > 0) at first blog -> Blog 1 remains
        await tester.drag(find.byType(PageView), const Offset(400, 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text(sampleBlog1.title), findsOneWidget);

        // Advance to last blog (Blog 2) via swipe LEFT (dx < 0)
        await tester.drag(find.byType(PageView), const Offset(-500, 0));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text(sampleBlog2.title), findsOneWidget);

        // Drag LEFT (dx < 0) at last blog (hasMore is false) -> Blog 2 remains
        await tester.drag(find.byType(PageView), const Offset(-400, 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(find.text(sampleBlog2.title), findsOneWidget);
      },
    );

    testWidgets(
      'Pagination: swiping past last loaded blog triggers loadMore when more data exists',
      (WidgetTester tester) async {
        final mockRepo = MockDetailBlogRepository(
          blogsToReturn: [sampleBlog1, sampleBlog2],
          nextUrl:
              'https://api.spaceflightnewsapi.net/v4/blogs/?limit=2&offset=2',
        );
        final viewModel = BlogViewModel(mockRepo);
        await viewModel.fetchBlogs();

        await tester.pumpWidget(
          createPagerWidget(
            viewModel: viewModel,
            repository: mockRepo,
            initialIndex: 0,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(mockRepo.callCount, 1);

        // Append third blog to repo results for pagination response
        mockRepo.blogsToReturn = [sampleBlog1, sampleBlog2, sampleBlog3];
        mockRepo.nextUrl = null;

        // Swipe LEFT (dx < 0) to blog 2 (index 1 is the last loaded blog)
        await tester.drag(find.byType(PageView), const Offset(-500, 0));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Proactive pagination is triggered
        expect(mockRepo.callCount, 2);
        expect(mockRepo.lastOffset, 2);
      },
    );

    testWidgets(
      'Pagination failure displays error and retry action in detail pager',
      (WidgetTester tester) async {
        final mockRepo = MockDetailBlogRepository(
          blogsToReturn: [sampleBlog1, sampleBlog2],
          nextUrl:
              'https://api.spaceflightnewsapi.net/v4/blogs/?limit=2&offset=2',
        );
        final viewModel = BlogViewModel(mockRepo);
        await viewModel.fetchBlogs();
        expect(mockRepo.callCount, 1);

        // Fail subsequent requests
        mockRepo.shouldThrow = true;

        await tester.pumpWidget(
          createPagerWidget(
            viewModel: viewModel,
            repository: mockRepo,
            initialIndex: 0,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Swipe LEFT to index 1 (triggers pagination which fails)
        await tester.drag(find.byType(PageView), const Offset(-500, 0));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump();

        // Advance into pagination error page via swipe LEFT
        await tester.drag(find.byType(PageView), const Offset(-500, 0));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Expect pagination error view in pager
        expect(find.text('Pagination network failure'), findsOneWidget);
        expect(find.text(AppStrings.retry), findsOneWidget);

        // Fix repo and retry
        mockRepo.shouldThrow = false;
        mockRepo.blogsToReturn = [sampleBlog1, sampleBlog2, sampleBlog3];
        mockRepo.nextUrl = null;

        await tester.tap(find.text(AppStrings.retry));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Newly loaded blog appears
        expect(find.text(sampleBlog3.title), findsOneWidget);
      },
    );
  });
}
