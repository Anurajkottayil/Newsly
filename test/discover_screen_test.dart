import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newsly/core/constants/app_strings.dart';
import 'package:newsly/core/errors/api_exception.dart';
import 'package:newsly/core/theme/app_theme.dart';
import 'package:newsly/models/article_model.dart';
import 'package:newsly/models/blog_model.dart';
import 'package:newsly/repositories/article_repository.dart';
import 'package:newsly/repositories/blog_repository.dart';
import 'package:newsly/shared/widgets/app_empty_view.dart';
import 'package:newsly/shared/widgets/app_error_view.dart';
import 'package:newsly/shared/widgets/app_loader.dart';
import 'package:newsly/shared/widgets/article_card.dart';
import 'package:newsly/viewmodels/article_view_model.dart';
import 'package:newsly/viewmodels/blog_view_model.dart';
import 'package:newsly/views/screens/discover_screen.dart';
import 'package:newsly/views/screens/article_detail_screen.dart';
import 'package:newsly/views/screens/blog_detail_screen.dart';
import 'package:provider/provider.dart';

/// Test mock implementation of [ArticleRepository] for UI state tests.
class MockArticleRepository implements ArticleRepository {
  List<Article> articlesToReturn;
  String? nextUrl;
  bool shouldThrow;
  String errorMessage;
  int callCount = 0;
  String? lastSearch;
  int? lastOffset;
  Completer<PaginatedArticles>? completer;
  Completer<PaginatedArticles>? paginationCompleter;
  bool shouldThrowOnPagination = false;
  List<Article>? paginationArticlesToReturn;
  String paginationErrorMessage = 'Pagination network failure';
  bool emptyForSearch = false;

  MockArticleRepository({
    this.articlesToReturn = const [],
    this.nextUrl,
    this.shouldThrow = false,
    this.errorMessage = 'Network error',
    this.completer,
  });

  @override
  Future<PaginatedArticles> getArticles({
    int limit = 10,
    int offset = 0,
    String? search,
  }) async {
    callCount++;
    lastOffset = offset;
    lastSearch = search;

    if (offset > 0) {
      if (paginationCompleter != null) {
        return paginationCompleter!.future;
      }
      if (shouldThrowOnPagination) {
        throw ApiException(
          message: paginationErrorMessage,
          type: ApiExceptionType.network,
        );
      }
      final items = paginationArticlesToReturn ?? articlesToReturn;
      return PaginatedArticles(
        count: articlesToReturn.length + items.length,
        next: null,
        previous: null,
        results: items,
      );
    }

    if (completer != null) {
      return completer!.future;
    }

    if (shouldThrow) {
      throw ApiException(message: errorMessage, type: ApiExceptionType.network);
    }

    if (emptyForSearch && search != null && search.isNotEmpty) {
      return const PaginatedArticles(
        count: 0,
        next: null,
        previous: null,
        results: [],
      );
    }

    return PaginatedArticles(
      count: articlesToReturn.length + (nextUrl != null ? 10 : 0),
      next: nextUrl,
      previous: null,
      results: articlesToReturn,
    );
  }

  @override
  Future<Article> getArticleById(int id) async {
    return articlesToReturn.firstWhere((a) => a.id == id);
  }
}

/// Test mock implementation of [BlogRepository] for UI state tests.
class MockBlogRepository implements BlogRepository {
  List<Blog> blogsToReturn;
  String? nextUrl;
  bool shouldThrow;
  String errorMessage;
  int callCount = 0;
  String? lastSearch;
  int? lastOffset;
  Completer<PaginatedBlogs>? completer;
  Completer<PaginatedBlogs>? paginationCompleter;
  bool shouldThrowOnPagination = false;
  List<Blog>? paginationBlogsToReturn;
  String paginationErrorMessage = 'Pagination network failure';
  bool emptyForSearch = false;

  MockBlogRepository({
    this.blogsToReturn = const [],
    this.nextUrl,
    this.shouldThrow = false,
    this.errorMessage = 'Network error',
    this.completer,
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

    if (offset > 0) {
      if (paginationCompleter != null) {
        return paginationCompleter!.future;
      }
      if (shouldThrowOnPagination) {
        throw ApiException(
          message: paginationErrorMessage,
          type: ApiExceptionType.network,
        );
      }
      final items = paginationBlogsToReturn ?? blogsToReturn;
      return PaginatedBlogs(
        count: blogsToReturn.length + items.length,
        next: null,
        previous: null,
        results: items,
      );
    }

    if (completer != null) {
      return completer!.future;
    }

    if (shouldThrow) {
      throw ApiException(message: errorMessage, type: ApiExceptionType.network);
    }

    if (emptyForSearch && search != null && search.isNotEmpty) {
      return const PaginatedBlogs(
        count: 0,
        next: null,
        previous: null,
        results: [],
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
    return blogsToReturn.firstWhere((b) => b.id == id);
  }
}

Widget createTestWidget({
  required ArticleRepository repository,
  BlogRepository? blogRepository,
}) {
  final blogRepo = blogRepository ?? MockBlogRepository();
  return MultiProvider(
    providers: [
      Provider<ArticleRepository>.value(value: repository),
      Provider<BlogRepository>.value(value: blogRepo),
      ChangeNotifierProvider<ArticleViewModel>(
        create: (_) => ArticleViewModel(repository),
      ),
      ChangeNotifierProvider<BlogViewModel>(
        create: (_) => BlogViewModel(blogRepo),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const DiscoverScreen(),
    ),
  );
}

void main() {
  final sampleArticles = [
    Article(
      id: 1,
      title: 'What Training Do Volleyball Players Need?',
      authors: const [Author(name: 'McKindney')],
      url: 'https://example.com/volleyball',
      imageUrl: '',
      newsSite: 'Sports',
      summary: 'Volleyball players require strength, agility, and endurance.',
      publishedAt: DateTime(2023, 2, 27),
    ),
    Article(
      id: 2,
      title: 'Secondary school places: When do parents find out?',
      authors: const [Author(name: 'Rosemary')],
      url: 'https://example.com/school',
      imageUrl: '', // missing image test
      newsSite: 'Education',
      summary: 'Parents across the country are awaiting admission letters.',
      publishedAt: DateTime(2023, 2, 28),
    ),
  ];

  group('DiscoverScreen Functional & UI Tests', () {
    testWidgets('Displays AppLoader when initial request is in-flight', (
      WidgetTester tester,
    ) async {
      final completer = Completer<PaginatedArticles>();
      final mockRepo = MockArticleRepository(completer: completer);

      await tester.pumpWidget(createTestWidget(repository: mockRepo));
      await tester.pump(); // Render first frame

      expect(find.byType(AppLoader), findsOneWidget);
      expect(find.text(AppStrings.loadingArticles), findsOneWidget);

      // Complete to avoid leaking pending futures
      completer.complete(
        const PaginatedArticles(
          count: 0,
          next: null,
          previous: null,
          results: [],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets(
      'Displays articles successfully with ArticleCard layout matching reference',
      (WidgetTester tester) async {
        final mockRepo = MockArticleRepository(
          articlesToReturn: sampleArticles,
        );

        await tester.pumpWidget(createTestWidget(repository: mockRepo));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Heading and Subtitle
        expect(find.text(AppStrings.discover), findsOneWidget);
        expect(find.text(AppStrings.discoverSubtitle), findsOneWidget);

        // Search hint and category chips
        expect(find.text('Search'), findsOneWidget);
        expect(find.text('All'), findsOneWidget);

        // Article Cards
        expect(find.byType(ArticleCard), findsNWidgets(2));
        expect(
          find.text('What Training Do Volleyball Players Need?'),
          findsOneWidget,
        );
        expect(find.text('Sports'), findsOneWidget);
        expect(find.text('McKindney'), findsOneWidget);
        expect(find.text('Feb 27, 2023'), findsOneWidget);

        // Missing image fallback
        expect(
          find.text('Secondary school places: When do parents find out?'),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.newspaper_rounded), findsNWidgets(2));
      },
    );

    testWidgets('Displays AppEmptyView when article feed is empty', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockArticleRepository(articlesToReturn: []);

      await tester.pumpWidget(createTestWidget(repository: mockRepo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AppEmptyView), findsOneWidget);
      expect(find.text(AppStrings.noArticlesTitle), findsOneWidget);
    });

    testWidgets('Displays AppErrorView and retries on failure', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockArticleRepository(
        shouldThrow: true,
        errorMessage: 'Connection timed out',
      );

      await tester.pumpWidget(createTestWidget(repository: mockRepo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AppErrorView), findsOneWidget);
      expect(find.text('Connection timed out'), findsOneWidget);
      expect(find.text(AppStrings.retry), findsOneWidget);
      expect(mockRepo.callCount, 1);

      // Now fix repo and tap retry
      mockRepo.shouldThrow = false;
      mockRepo.articlesToReturn = sampleArticles;

      await tester.tap(find.text(AppStrings.retry));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockRepo.callCount, 2);
      expect(find.byType(AppErrorView), findsNothing);
      expect(find.byType(ArticleCard), findsNWidgets(2));
    });

    testWidgets('Search input debounces and dispatches query', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockArticleRepository(articlesToReturn: sampleArticles);

      await tester.pumpWidget(createTestWidget(repository: mockRepo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockRepo.callCount, 1);

      // Enter search query
      await tester.enterText(find.byType(TextField), 'SpaceX');
      await tester.pump(const Duration(milliseconds: 200));

      // Before debounce duration: repository has NOT been called again
      expect(mockRepo.callCount, 1);

      // Advance past debounce duration (500ms)
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockRepo.callCount, 2);
      expect(mockRepo.lastSearch, 'SpaceX');
    });

    testWidgets('Clearing search reloads default article feed', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockArticleRepository(articlesToReturn: sampleArticles);

      await tester.pumpWidget(createTestWidget(repository: mockRepo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter search query
      await tester.enterText(find.byType(TextField), 'NASA');
      await tester.pump(const Duration(milliseconds: 550));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockRepo.lastSearch, 'NASA');

      // Tap clear icon in search bar
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockRepo.lastSearch, isNull);
    });

    testWidgets('Tapping category chip triggers filtered search', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockArticleRepository(articlesToReturn: sampleArticles);

      await tester.pumpWidget(createTestWidget(repository: mockRepo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap 'SpaceX' chip
      await tester.tap(find.text('SpaceX'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockRepo.lastSearch, 'SpaceX');

      // Tap 'All' chip
      await tester.tap(find.text('All'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockRepo.lastSearch, isNull);
    });

    testWidgets('Pull to refresh triggers refresh on ViewModel', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockArticleRepository(articlesToReturn: sampleArticles);

      await tester.pumpWidget(createTestWidget(repository: mockRepo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockRepo.callCount, 1);

      // Perform pull-to-refresh
      await tester.drag(find.byType(ListView).last, const Offset(0, 300));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockRepo.callCount, 2);
      expect(mockRepo.lastOffset, 0);
    });

    testWidgets('Scrolling near bottom triggers pagination loadMore', (
      WidgetTester tester,
    ) async {
      // 10 items so list is scrollable
      final tenArticles = List.generate(
        10,
        (i) => Article(
          id: i + 1,
          title: 'Article Headline $i',
          authors: const [Author(name: 'Author')],
          url: 'https://example.com/$i',
          imageUrl: '',
          newsSite: 'Source',
          summary: 'Summary $i',
          publishedAt: DateTime(2023, 2, 27),
        ),
      );

      final mockRepo = MockArticleRepository(
        articlesToReturn: tenArticles,
        nextUrl:
            'https://api.spaceflightnewsapi.net/v4/articles/?limit=10&offset=10',
      );

      await tester.pumpWidget(createTestWidget(repository: mockRepo));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockRepo.callCount, 1);

      // Scroll down list to trigger pagination listener
      await tester.drag(find.byType(ListView).last, const Offset(0, -1000));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockRepo.callCount, 2);
      expect(mockRepo.lastOffset, 10);
    });

    testWidgets(
      'Tapping an article card opens ArticleDetailScreen and back returns to Discover',
      (WidgetTester tester) async {
        final mockRepo = MockArticleRepository(
          articlesToReturn: sampleArticles,
        );

        await tester.pumpWidget(createTestWidget(repository: mockRepo));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Tap the first article card
        await tester.tap(
          find.text('What Training Do Volleyball Players Need?'),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump();

        // Expect ArticleDetailScreen is open and showing the article
        expect(find.byType(ArticleDetailScreen), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(ArticleDetailScreen),
            matching: find.text('What Training Do Volleyball Players Need?'),
          ),
          findsOneWidget,
        );
        expect(find.text(AppStrings.readFullArticle), findsOneWidget);

        // Tap the back button on ArticleDetailScreen
        await tester.tap(
          find.descendant(
            of: find.byType(ArticleDetailScreen),
            matching: find.byTooltip(AppStrings.back),
          ),
        );
        await tester.pumpAndSettle();

        // Back on Discover screen and articles are preserved
        expect(find.byType(ArticleDetailScreen), findsNothing);
        expect(find.text(AppStrings.discover), findsOneWidget);
        expect(find.byType(ArticleCard), findsNWidgets(2));
      },
    );

    testWidgets(
      'Articles / Blogs toggle switches feeds and preserves loaded state',
      (WidgetTester tester) async {
        final sampleBlogs = [
          Blog(
            id: 201,
            title: 'Sample Spaceflight Blog Post',
            authors: const [Author(name: 'Blogger')],
            url: 'https://example.com/blog/201',
            imageUrl: '',
            newsSite: 'NASA Blog',
            summary: 'Summary of blog post.',
            publishedAt: DateTime(2023, 3, 1),
            featured: true,
          ),
        ];

        final mockArticleRepo = MockArticleRepository(
          articlesToReturn: sampleArticles,
        );
        final mockBlogRepo = MockBlogRepository(blogsToReturn: sampleBlogs);

        await tester.pumpWidget(
          createTestWidget(
            repository: mockArticleRepo,
            blogRepository: mockBlogRepo,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Articles are showing
        expect(find.byType(ArticleCard), findsNWidgets(2));
        expect(
          find.text('What Training Do Volleyball Players Need?'),
          findsOneWidget,
        );
        expect(mockBlogRepo.callCount, 0);

        // Verify segmented tab selector is removed
        expect(find.byKey(const ValueKey('blogs_tab')), findsNothing);
        expect(find.byKey(const ValueKey('articles_tab')), findsNothing);

        // Open filter bottom sheet
        await tester.tap(find.byKey(const ValueKey('search_filter_button')));
        await tester.pumpAndSettle();

        expect(find.text(AppStrings.exploreContent), findsOneWidget);
        expect(
          find.byKey(const ValueKey('filter_option_blogs')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('filter_option_articles')),
          findsOneWidget,
        );

        // Tap Blogs option
        await tester.tap(find.byKey(const ValueKey('filter_option_blogs')));
        await tester.pumpAndSettle();

        // Verify blog is fetched and displayed with metadata & placeholder
        expect(mockBlogRepo.callCount, 1);
        expect(find.text('Sample Spaceflight Blog Post'), findsOneWidget);
        expect(find.text('NASA Blog'), findsOneWidget);
        expect(find.text('Blogger'), findsOneWidget);
        expect(find.text('Mar 1, 2023'), findsOneWidget);
        expect(find.byIcon(Icons.newspaper_rounded), findsOneWidget);

        // Open filter bottom sheet again to switch back to Articles
        await tester.tap(find.byKey(const ValueKey('search_filter_button')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('filter_option_articles')));
        await tester.pumpAndSettle();

        // Articles are immediately visible without re-fetching
        expect(
          find.text('What Training Do Volleyball Players Need?'),
          findsOneWidget,
        );
        expect(mockArticleRepo.callCount, 1);
      },
    );

    testWidgets(
      'Tapping a blog card opens BlogDetailScreen and back returns to Discover',
      (WidgetTester tester) async {
        final sampleBlogs = [
          Blog(
            id: 201,
            title: 'Sample Spaceflight Blog Post',
            authors: const [Author(name: 'Blogger')],
            url: 'https://example.com/blog/201',
            imageUrl: '',
            newsSite: 'NASA Blog',
            summary: 'Summary of blog post.',
            publishedAt: DateTime(2023, 3, 1),
            featured: true,
          ),
        ];

        final mockArticleRepo = MockArticleRepository(
          articlesToReturn: sampleArticles,
        );
        final mockBlogRepo = MockBlogRepository(blogsToReturn: sampleBlogs);

        await tester.pumpWidget(
          createTestWidget(
            repository: mockArticleRepo,
            blogRepository: mockBlogRepo,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Switch to Blogs via filter sheet
        await tester.tap(find.byKey(const ValueKey('search_filter_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('filter_option_blogs')));
        await tester.pumpAndSettle();

        // Tap the blog card
        await tester.tap(find.text('Sample Spaceflight Blog Post'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump();

        // BlogDetailScreen is opened
        expect(find.byType(BlogDetailScreen), findsOneWidget);
        expect(find.text(AppStrings.readFullBlogPost), findsOneWidget);

        // Tap back button
        await tester.tap(
          find.descendant(
            of: find.byType(BlogDetailScreen),
            matching: find.byTooltip(AppStrings.back),
          ),
        );
        await tester.pumpAndSettle();

        // Back on Discover screen, still on Blogs tab
        expect(find.byType(BlogDetailScreen), findsNothing);
        expect(find.text('Sample Spaceflight Blog Post'), findsOneWidget);
      },
    );

    testWidgets(
      'Pull-to-refresh failure on articles feed preserves visible feed and displays non-blocking SnackBar',
      (WidgetTester tester) async {
        final mockArticleRepo = MockArticleRepository(
          articlesToReturn: sampleArticles,
        );

        await tester.pumpWidget(createTestWidget(repository: mockArticleRepo));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Initial articles are loaded and displayed
        expect(
          find.text('What Training Do Volleyball Players Need?'),
          findsOneWidget,
        );
        expect(find.byType(AppErrorView), findsNothing);

        // Configure repository to throw on subsequent refresh
        mockArticleRepo.shouldThrow = true;
        mockArticleRepo.errorMessage = 'Network error during pull-to-refresh';

        // Trigger pull-to-refresh
        await tester.fling(
          find.byType(RefreshIndicator),
          const Offset(0.0, 300.0),
          1000.0,
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // 1. Existing feed items must remain visible (not replaced by AppErrorView)
        expect(
          find.text('What Training Do Volleyball Players Need?'),
          findsOneWidget,
        );
        expect(find.byType(AppErrorView), findsNothing);

        // 2. Non-blocking floating SnackBar is displayed with error message
        expect(
          find.text('Network error during pull-to-refresh'),
          findsOneWidget,
        );
        expect(find.byType(SnackBar), findsOneWidget);
      },
    );

    testWidgets(
      'Pull-to-refresh failure on blogs feed preserves visible feed and displays non-blocking SnackBar',
      (WidgetTester tester) async {
        final sampleBlogs = [
          Blog(
            id: 201,
            title: 'Sample Spaceflight Blog Post',
            authors: const [Author(name: 'Blogger')],
            url: 'https://example.com/blog/201',
            imageUrl: '',
            newsSite: 'NASA Blog',
            summary: 'Summary of blog post.',
            publishedAt: DateTime(2023, 3, 1),
            featured: true,
          ),
        ];

        final mockArticleRepo = MockArticleRepository(
          articlesToReturn: sampleArticles,
        );
        final mockBlogRepo = MockBlogRepository(blogsToReturn: sampleBlogs);

        await tester.pumpWidget(
          createTestWidget(
            repository: mockArticleRepo,
            blogRepository: mockBlogRepo,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Switch to Blogs tab
        await tester.tap(find.byKey(const ValueKey('search_filter_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('filter_option_blogs')));
        await tester.pumpAndSettle();

        expect(find.text('Sample Spaceflight Blog Post'), findsOneWidget);
        expect(find.byType(AppErrorView), findsNothing);

        // Configure blog repo to throw on subsequent refresh
        mockBlogRepo.shouldThrow = true;
        mockBlogRepo.errorMessage = 'Network error during blog refresh';

        // Trigger pull-to-refresh
        await tester.fling(
          find.byType(RefreshIndicator),
          const Offset(0.0, 300.0),
          1000.0,
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Feed is preserved, no full-page error, SnackBar displayed
        expect(find.text('Sample Spaceflight Blog Post'), findsOneWidget);
        expect(find.byType(AppErrorView), findsNothing);
        expect(find.text('Network error during blog refresh'), findsOneWidget);
        expect(find.byType(SnackBar), findsOneWidget);
      },
    );

    testWidgets('Displays AppLoader when initial Blog request is in-flight', (
      WidgetTester tester,
    ) async {
      final blogCompleter = Completer<PaginatedBlogs>();
      final mockBlogRepo = MockBlogRepository(completer: blogCompleter);
      final mockArticleRepo = MockArticleRepository(
        articlesToReturn: sampleArticles,
      );

      await tester.pumpWidget(
        createTestWidget(
          repository: mockArticleRepo,
          blogRepository: mockBlogRepo,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to Blogs via filter sheet
      await tester.tap(find.byKey(const ValueKey('search_filter_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filter_option_blogs')));
      await tester.pump(); // Render initial loading frame

      expect(find.byType(AppLoader), findsOneWidget);
      expect(find.text(AppStrings.loadingBlogs), findsOneWidget);

      // Complete to avoid pending timer/future leaks
      blogCompleter.complete(
        const PaginatedBlogs(count: 0, next: null, previous: null, results: []),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('Displays AppEmptyView when Blog feed is empty', (
      WidgetTester tester,
    ) async {
      final mockBlogRepo = MockBlogRepository(blogsToReturn: []);
      final mockArticleRepo = MockArticleRepository(
        articlesToReturn: sampleArticles,
      );

      await tester.pumpWidget(
        createTestWidget(
          repository: mockArticleRepo,
          blogRepository: mockBlogRepo,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to Blogs via filter sheet
      await tester.tap(find.byKey(const ValueKey('search_filter_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filter_option_blogs')));
      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyView), findsOneWidget);
      expect(find.text(AppStrings.noBlogsTitle), findsOneWidget);
      expect(find.text(AppStrings.noBlogsSubtitle), findsOneWidget);
    });

    testWidgets(
      'Displays AppErrorView on Blog feed failure and retries on failure',
      (WidgetTester tester) async {
        final sampleBlogs = [
          Blog(
            id: 201,
            title: 'Sample Spaceflight Blog Post',
            authors: const [Author(name: 'Blogger')],
            url: 'https://example.com/blog/201',
            imageUrl: '',
            newsSite: 'NASA Blog',
            summary: 'Summary of blog post.',
            publishedAt: DateTime(2023, 3, 1),
            featured: true,
          ),
        ];

        final mockBlogRepo = MockBlogRepository(
          shouldThrow: true,
          errorMessage: 'Failed to load blogs',
        );
        final mockArticleRepo = MockArticleRepository(
          articlesToReturn: sampleArticles,
        );

        await tester.pumpWidget(
          createTestWidget(
            repository: mockArticleRepo,
            blogRepository: mockBlogRepo,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Switch to Blogs via filter sheet
        await tester.tap(find.byKey(const ValueKey('search_filter_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('filter_option_blogs')));
        await tester.pumpAndSettle();

        expect(find.byType(AppErrorView), findsOneWidget);
        expect(find.text('Failed to load blogs'), findsOneWidget);
        expect(find.text(AppStrings.retry), findsOneWidget);
        expect(mockBlogRepo.callCount, 1);

        // Fix repo and tap retry
        mockBlogRepo.shouldThrow = false;
        mockBlogRepo.blogsToReturn = sampleBlogs;

        await tester.tap(find.text(AppStrings.retry));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(mockBlogRepo.callCount, 2);
        expect(find.byType(AppErrorView), findsNothing);
        expect(find.text('Sample Spaceflight Blog Post'), findsOneWidget);
      },
    );

    testWidgets(
      'Article feed displays pagination loading indicator and error tile with functional retry',
      (WidgetTester tester) async {
        final sixArticles = List.generate(
          6,
          (i) => Article(
            id: i + 1,
            title: 'Article Headline $i',
            authors: const [Author(name: 'Author')],
            url: 'https://example.com/$i',
            imageUrl: '',
            newsSite: 'Source',
            summary: 'Summary $i',
            publishedAt: DateTime(2023, 2, 27),
          ),
        );
        final article7 = Article(
          id: 7,
          title: 'Article Headline 7',
          authors: const [Author(name: 'Author')],
          url: 'https://example.com/7',
          imageUrl: '',
          newsSite: 'Source',
          summary: 'Summary 7',
          publishedAt: DateTime(2023, 2, 27),
        );

        final paginationCompleter = Completer<PaginatedArticles>();
        final mockRepo = MockArticleRepository(
          articlesToReturn: sixArticles,
          nextUrl:
              'https://api.spaceflightnewsapi.net/v4/articles/?limit=10&offset=6',
        );
        mockRepo.paginationCompleter = paginationCompleter;

        await tester.pumpWidget(createTestWidget(repository: mockRepo));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Scroll to trigger pagination
        await tester.drag(find.byType(ListView).last, const Offset(0, -500));
        await tester.pump();

        // 1. Pagination loading indicator visible in footer
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // 2. Complete pagination with error
        paginationCompleter.completeError(
          ApiException(
            message: 'Article pagination error',
            type: ApiExceptionType.network,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Error message and retry button in pagination tile
        expect(find.text('Article pagination error'), findsOneWidget);
        expect(
          find.widgetWithText(TextButton, AppStrings.retry),
          findsOneWidget,
        );

        // 3. Ensure retry button is visible, tap retry, and verify successful recovery
        await tester.ensureVisible(
          find.widgetWithText(TextButton, AppStrings.retry),
        );
        await tester.pumpAndSettle();

        mockRepo.paginationCompleter = null;
        mockRepo.shouldThrowOnPagination = false;
        mockRepo.paginationArticlesToReturn = [article7];

        await tester.tap(find.widgetWithText(TextButton, AppStrings.retry));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.scrollUntilVisible(
          find.text('Article Headline 7'),
          100,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();

        expect(find.text('Article Headline 7'), findsOneWidget);
        expect(find.text('Article pagination error'), findsNothing);
      },
    );

    testWidgets(
      'Blog feed displays pagination loading indicator and error tile with functional retry',
      (WidgetTester tester) async {
        final sixBlogs = List.generate(
          6,
          (i) => Blog(
            id: 200 + i,
            title: 'Blog Headline $i',
            authors: const [Author(name: 'Author')],
            url: 'https://example.com/blog/$i',
            imageUrl: '',
            newsSite: 'Source',
            summary: 'Summary $i',
            publishedAt: DateTime(2023, 2, 27),
          ),
        );
        final blog7 = Blog(
          id: 207,
          title: 'Blog Headline 7',
          authors: const [Author(name: 'Author')],
          url: 'https://example.com/blog/207',
          imageUrl: '',
          newsSite: 'Source',
          summary: 'Summary 7',
          publishedAt: DateTime(2023, 2, 27),
        );

        final paginationCompleter = Completer<PaginatedBlogs>();
        final mockBlogRepo = MockBlogRepository(
          blogsToReturn: sixBlogs,
          nextUrl:
              'https://api.spaceflightnewsapi.net/v4/blogs/?limit=10&offset=6',
        );
        mockBlogRepo.paginationCompleter = paginationCompleter;
        final mockArticleRepo = MockArticleRepository(
          articlesToReturn: sampleArticles,
        );

        await tester.pumpWidget(
          createTestWidget(
            repository: mockArticleRepo,
            blogRepository: mockBlogRepo,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Switch to Blogs via filter sheet
        await tester.tap(find.byKey(const ValueKey('search_filter_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('filter_option_blogs')));
        await tester.pumpAndSettle();

        // Scroll to trigger pagination
        await tester.drag(find.byType(ListView).last, const Offset(0, -500));
        await tester.pump();

        // 1. Pagination loading indicator visible in footer
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // 2. Complete pagination with error
        paginationCompleter.completeError(
          ApiException(
            message: 'Blog pagination error',
            type: ApiExceptionType.network,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Error message and retry button in pagination tile
        expect(find.text('Blog pagination error'), findsOneWidget);
        expect(
          find.widgetWithText(TextButton, AppStrings.retry),
          findsOneWidget,
        );

        // 3. Ensure retry button is visible, tap retry, and verify recovery
        await tester.ensureVisible(
          find.widgetWithText(TextButton, AppStrings.retry),
        );
        await tester.pumpAndSettle();

        mockBlogRepo.paginationCompleter = null;
        mockBlogRepo.shouldThrowOnPagination = false;
        mockBlogRepo.paginationBlogsToReturn = [blog7];

        await tester.tap(find.widgetWithText(TextButton, AppStrings.retry));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.scrollUntilVisible(
          find.text('Blog Headline 7'),
          100,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.pumpAndSettle();

        expect(find.text('Blog Headline 7'), findsOneWidget);
        expect(find.text('Blog pagination error'), findsNothing);
      },
    );

    testWidgets(
      'Searching articles with no results displays empty search view and retry action clears query',
      (WidgetTester tester) async {
        final mockRepo = MockArticleRepository(
          articlesToReturn: sampleArticles,
        );
        mockRepo.emptyForSearch = true;

        await tester.pumpWidget(createTestWidget(repository: mockRepo));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(ArticleCard), findsNWidgets(2));

        // Enter non-matching search query
        await tester.enterText(find.byType(TextField), 'NonExistentArticle');
        await tester.pump(const Duration(milliseconds: 550));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(AppEmptyView), findsOneWidget);
        expect(find.text(AppStrings.noSearchResultsTitle), findsOneWidget);
        expect(find.text(AppStrings.noSearchResultsSubtitle), findsOneWidget);
        expect(find.text(AppStrings.retry), findsOneWidget);

        // Tapping retry clears query and restores default feed
        mockRepo.emptyForSearch = false;
        await tester.tap(find.text(AppStrings.retry));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(ArticleCard), findsNWidgets(2));
        expect(mockRepo.lastSearch, isNull);
      },
    );

    testWidgets(
      'Searching blogs with no results displays empty search view and retry action clears query',
      (WidgetTester tester) async {
        final sampleBlogs = [
          Blog(
            id: 201,
            title: 'Sample Spaceflight Blog Post',
            authors: const [Author(name: 'Blogger')],
            url: 'https://example.com/blog/201',
            imageUrl: '',
            newsSite: 'NASA Blog',
            summary: 'Summary of blog post.',
            publishedAt: DateTime(2023, 3, 1),
            featured: true,
          ),
        ];

        final mockArticleRepo = MockArticleRepository(
          articlesToReturn: sampleArticles,
        );
        final mockBlogRepo = MockBlogRepository(blogsToReturn: sampleBlogs);
        mockBlogRepo.emptyForSearch = true;

        await tester.pumpWidget(
          createTestWidget(
            repository: mockArticleRepo,
            blogRepository: mockBlogRepo,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Switch to Blogs tab
        await tester.tap(find.byKey(const ValueKey('search_filter_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('filter_option_blogs')));
        await tester.pumpAndSettle();

        expect(find.text('Sample Spaceflight Blog Post'), findsOneWidget);

        // Search for non-matching blog query
        await tester.enterText(find.byType(TextField), 'NonExistentBlog');
        await tester.pump(const Duration(milliseconds: 550));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(AppEmptyView), findsOneWidget);
        expect(find.text(AppStrings.noSearchResultsTitle), findsOneWidget);
        expect(find.text(AppStrings.noSearchResultsSubtitle), findsOneWidget);
        expect(find.text(AppStrings.retry), findsOneWidget);

        // Tapping retry clears query and restores default feed
        mockBlogRepo.emptyForSearch = false;
        await tester.tap(find.text(AppStrings.retry));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Sample Spaceflight Blog Post'), findsOneWidget);
        expect(mockBlogRepo.lastSearch, isNull);
      },
    );

    testWidgets('Blog feed search input debounces and dispatches query', (
      WidgetTester tester,
    ) async {
      final sampleBlogs = [
        Blog(
          id: 201,
          title: 'Sample Spaceflight Blog Post',
          authors: const [Author(name: 'Blogger')],
          url: 'https://example.com/blog/201',
          imageUrl: '',
          newsSite: 'NASA Blog',
          summary: 'Summary of blog post.',
          publishedAt: DateTime(2023, 3, 1),
          featured: true,
        ),
      ];

      final mockArticleRepo = MockArticleRepository(
        articlesToReturn: sampleArticles,
      );
      final mockBlogRepo = MockBlogRepository(blogsToReturn: sampleBlogs);

      await tester.pumpWidget(
        createTestWidget(
          repository: mockArticleRepo,
          blogRepository: mockBlogRepo,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to Blogs
      await tester.tap(find.byKey(const ValueKey('search_filter_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filter_option_blogs')));
      await tester.pumpAndSettle();

      expect(mockBlogRepo.callCount, 1);

      // Enter search query
      await tester.enterText(find.byType(TextField), 'Starship');
      await tester.pump(const Duration(milliseconds: 200));

      // Before debounce duration: repository has NOT been called again
      expect(mockBlogRepo.callCount, 1);

      // Advance past debounce duration (500ms)
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockBlogRepo.callCount, 2);
      expect(mockBlogRepo.lastSearch, 'Starship');
    });

    testWidgets(
      'Scrolling Blog feed near bottom triggers pagination loadMore',
      (WidgetTester tester) async {
        final tenBlogs = List.generate(
          10,
          (i) => Blog(
            id: 200 + i,
            title: 'Blog Headline $i',
            authors: const [Author(name: 'Author')],
            url: 'https://example.com/blog/$i',
            imageUrl: '',
            newsSite: 'Source',
            summary: 'Summary $i',
            publishedAt: DateTime(2023, 2, 27),
          ),
        );

        final mockArticleRepo = MockArticleRepository(
          articlesToReturn: sampleArticles,
        );
        final mockBlogRepo = MockBlogRepository(
          blogsToReturn: tenBlogs,
          nextUrl:
              'https://api.spaceflightnewsapi.net/v4/blogs/?limit=10&offset=10',
        );

        await tester.pumpWidget(
          createTestWidget(
            repository: mockArticleRepo,
            blogRepository: mockBlogRepo,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Switch to Blogs
        await tester.tap(find.byKey(const ValueKey('search_filter_button')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('filter_option_blogs')));
        await tester.pumpAndSettle();

        expect(mockBlogRepo.callCount, 1);

        // Scroll down list to trigger pagination listener
        await tester.drag(find.byType(ListView).last, const Offset(0, -1000));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(mockBlogRepo.callCount, 2);
        expect(mockBlogRepo.lastOffset, 10);
      },
    );
  });
}
