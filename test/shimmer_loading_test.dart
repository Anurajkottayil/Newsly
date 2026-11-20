import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newsly/core/constants/app_constants.dart';
import 'package:newsly/core/constants/app_strings.dart';
import 'package:newsly/core/errors/api_exception.dart';
import 'package:newsly/core/theme/app_theme.dart';
import 'package:newsly/models/article_model.dart';
import 'package:newsly/models/blog_model.dart';
import 'package:newsly/repositories/article_repository.dart';
import 'package:newsly/repositories/blog_repository.dart';
import 'package:newsly/shared/widgets/app_error_view.dart';
import 'package:newsly/shared/widgets/article_card.dart';
import 'package:newsly/shared/widgets/shimmer_loading.dart';
import 'package:newsly/viewmodels/article_view_model.dart';
import 'package:newsly/viewmodels/blog_view_model.dart';
import 'package:newsly/views/screens/discover_screen.dart';
import 'package:provider/provider.dart';

class MockShimmerArticleRepo implements ArticleRepository {
  List<Article> articles;
  Completer<PaginatedArticles>? completer;
  Completer<PaginatedArticles>? paginationCompleter;
  bool shouldThrow;
  String? lastSearch;
  int? lastOffset;
  String? nextUrl;

  MockShimmerArticleRepo({
    this.articles = const [],
    this.completer,
    this.paginationCompleter,
    this.shouldThrow = false,
    this.nextUrl,
  });

  @override
  Future<PaginatedArticles> getArticles({
    int limit = 10,
    int offset = 0,
    String? search,
  }) async {
    lastSearch = search;
    lastOffset = offset;
    if (offset > 0 &&
        paginationCompleter != null &&
        !paginationCompleter!.isCompleted) {
      return paginationCompleter!.future;
    }
    if (completer != null && !completer!.isCompleted) {
      return completer!.future;
    }
    if (shouldThrow) {
      throw const ApiException(
        message: 'Network connection failed',
        type: ApiExceptionType.network,
      );
    }
    return PaginatedArticles(
      count: articles.length + 10,
      next: nextUrl ?? (articles.length > offset + limit ? 'next_url' : null),
      previous: null,
      results: articles,
    );
  }

  @override
  Future<Article> getArticleById(int id) async {
    return articles.firstWhere((a) => a.id == id);
  }
}

class MockShimmerBlogRepo implements BlogRepository {
  List<Blog> blogs;
  Completer<PaginatedBlogs>? completer;
  bool shouldThrow;
  String? lastSearch;
  int? lastOffset;

  MockShimmerBlogRepo({
    this.blogs = const [],
    this.completer,
    this.shouldThrow = false,
  });

  @override
  Future<PaginatedBlogs> getBlogs({
    int limit = 10,
    int offset = 0,
    String? search,
  }) async {
    lastSearch = search;
    lastOffset = offset;
    if (completer != null && !completer!.isCompleted) {
      return completer!.future;
    }
    if (shouldThrow) {
      throw const ApiException(
        message: 'Network connection failed',
        type: ApiExceptionType.network,
      );
    }
    return PaginatedBlogs(
      count: blogs.length,
      next: blogs.length > offset + limit ? 'next_url' : null,
      previous: null,
      results: blogs,
    );
  }

  @override
  Future<Blog> getBlogById(int id) async {
    return blogs.firstWhere((b) => b.id == id);
  }
}

void main() {
  final sampleArticles = [
    Article(
      id: 1,
      title: 'Starship Orbital Flight Test Success',
      authors: const [Author(name: 'Space Reporter')],
      url: 'https://example.com/starship',
      imageUrl: '',
      newsSite: 'SpaceNews',
      summary: 'Starship achieved successful orbital insertion.',
      publishedAt: DateTime(2026, 11, 19),
    ),
    Article(
      id: 2,
      title: 'James Webb Telescope Discovers Exoplanet',
      authors: const [Author(name: 'Science Editor')],
      url: 'https://example.com/jwst',
      imageUrl: '',
      newsSite: 'NASA',
      summary: 'A new terrestrial exoplanet has been confirmed.',
      publishedAt: DateTime(2026, 11, 18),
    ),
  ];

  final sampleBlogs = [
    Blog(
      id: 101,
      title: 'Cosmic Horizons Blog Post',
      authors: const [Author(name: 'Lead Blogger')],
      url: 'https://example.com/blog-101',
      imageUrl: '',
      newsSite: 'Cosmic Blog',
      summary: 'Deep space exploration analysis.',
      publishedAt: DateTime(2026, 11, 19),
    ),
  ];

  Widget buildTestApp({
    required MockShimmerArticleRepo articleRepo,
    required MockShimmerBlogRepo blogRepo,
    ThemeData? theme,
  }) {
    return MultiProvider(
      providers: [
        Provider<ArticleRepository>.value(value: articleRepo),
        Provider<BlogRepository>.value(value: blogRepo),
        ChangeNotifierProvider(create: (_) => ArticleViewModel(articleRepo)),
        ChangeNotifierProvider(create: (_) => BlogViewModel(blogRepo)),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        home: const DiscoverScreen(),
      ),
    );
  }

  group('T039 / UX Improvement: Shimmer Loading Feed Tests', () {
    // 1. Initial Articles loading displays skeleton cards
    testWidgets('1. Initial Articles loading displays skeleton cards', (
      tester,
    ) async {
      final completer = Completer<PaginatedArticles>();
      final articleRepo = MockShimmerArticleRepo(completer: completer);
      final blogRepo = MockShimmerBlogRepo();

      await tester.pumpWidget(
        buildTestApp(articleRepo: articleRepo, blogRepo: blogRepo),
      );
      await tester.pump(); // First frame

      expect(find.byType(ShimmerLoadingFeed), findsOneWidget);
      expect(find.byType(ArticleCardSkeleton), findsWidgets);
      expect(find.text(AppStrings.loadingArticles), findsOneWidget);

      // Clean completion
      completer.complete(
        const PaginatedArticles(
          count: 0,
          next: null,
          previous: null,
          results: [],
        ),
      );
      await tester.pumpAndSettle();
    });

    // 2. Initial Blogs loading displays skeleton cards
    testWidgets('2. Initial Blogs loading displays skeleton cards', (
      tester,
    ) async {
      final blogCompleter = Completer<PaginatedBlogs>();
      final articleRepo = MockShimmerArticleRepo(articles: sampleArticles);
      final blogRepo = MockShimmerBlogRepo(completer: blogCompleter);

      await tester.pumpWidget(
        buildTestApp(articleRepo: articleRepo, blogRepo: blogRepo),
      );
      await tester.pumpAndSettle();

      // Switch to Blogs
      await tester.tap(find.byKey(const ValueKey('search_filter_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filter_option_blogs')));
      await tester.pump();

      expect(find.byType(ShimmerLoadingFeed), findsOneWidget);
      expect(find.byType(ArticleCardSkeleton), findsWidgets);
      expect(find.text(AppStrings.loadingBlogs), findsOneWidget);

      // Clean completion
      blogCompleter.complete(
        const PaginatedBlogs(count: 0, next: null, previous: null, results: []),
      );
      await tester.pumpAndSettle();
    });

    // 3. Search request displays shimmer while loading
    testWidgets('3. Search request displays shimmer while loading', (
      tester,
    ) async {
      final searchCompleter = Completer<PaginatedArticles>();
      final articleRepo = MockShimmerArticleRepo(articles: sampleArticles);
      final blogRepo = MockShimmerBlogRepo();

      await tester.pumpWidget(
        buildTestApp(articleRepo: articleRepo, blogRepo: blogRepo),
      );
      await tester.pumpAndSettle();

      // Initial articles visible
      expect(find.byType(ArticleCard), findsNWidgets(2));

      // Hook up in-flight search completer
      articleRepo.completer = searchCompleter;

      // Enter search keyword
      await tester.enterText(find.byType(TextField), 'SpaceX');
      await tester.pump(); // Text entered

      // Fast-forward past debounce
      await tester.pump(AppConstants.searchDebounceDuration);

      // Verify shimmer is displayed and old cards are hidden during search
      expect(find.byType(ShimmerLoadingFeed), findsOneWidget);
      expect(find.byType(ArticleCardSkeleton), findsWidgets);
      expect(find.byType(ArticleCard), findsNothing);

      // Complete search request
      searchCompleter.complete(
        PaginatedArticles(
          count: 1,
          next: null,
          previous: null,
          results: [sampleArticles.first],
        ),
      );
      await tester.pumpAndSettle();

      // Verify cards reappear
      expect(find.byType(ShimmerLoadingFeed), findsNothing);
      expect(find.byType(ArticleCard), findsOneWidget);
    });

    // 4. Category change displays shimmer while loading
    testWidgets('4. Category change displays shimmer while loading', (
      tester,
    ) async {
      final categoryCompleter = Completer<PaginatedArticles>();
      final articleRepo = MockShimmerArticleRepo(articles: sampleArticles);
      final blogRepo = MockShimmerBlogRepo();

      await tester.pumpWidget(
        buildTestApp(articleRepo: articleRepo, blogRepo: blogRepo),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ArticleCard), findsNWidgets(2));

      // Set completer for next category call
      articleRepo.completer = categoryCompleter;

      // Tap 'NASA' category chip
      await tester.tap(find.widgetWithText(InkWell, 'NASA').first);
      await tester.pump();

      // Shimmer should be displayed immediately
      expect(find.byType(ShimmerLoadingFeed), findsOneWidget);
      expect(find.byType(ArticleCardSkeleton), findsWidgets);
      expect(find.byType(ArticleCard), findsNothing);

      // Complete category call
      categoryCompleter.complete(
        PaginatedArticles(
          count: 1,
          next: null,
          previous: null,
          results: [sampleArticles.last],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ShimmerLoadingFeed), findsNothing);
      expect(find.byType(ArticleCard), findsOneWidget);
    });

    // 5. Switching feeds displays cached content where available
    testWidgets('5. Switching feeds displays cached content where available', (
      tester,
    ) async {
      final articleRepo = MockShimmerArticleRepo(articles: sampleArticles);
      final blogRepo = MockShimmerBlogRepo(blogs: sampleBlogs);

      await tester.pumpWidget(
        buildTestApp(articleRepo: articleRepo, blogRepo: blogRepo),
      );
      await tester.pumpAndSettle();

      // 1. Initially Articles are loaded
      expect(find.byType(ArticleCard), findsNWidgets(2));

      // 2. Switch to Blogs
      await tester.tap(find.byKey(const ValueKey('search_filter_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filter_option_blogs')));
      await tester.pumpAndSettle();

      // Blogs loaded
      expect(find.text('Cosmic Horizons Blog Post'), findsOneWidget);

      // 3. Switch back to Articles
      await tester.tap(find.byKey(const ValueKey('search_filter_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filter_option_articles')));
      await tester.pump();

      // Should display cached articles immediately with no shimmer
      expect(find.byType(ShimmerLoadingFeed), findsNothing);
      expect(find.byType(ArticleCard), findsNWidgets(2));
    });

    // 6. Switching to an unloaded feed displays shimmer
    testWidgets('6. Switching to an unloaded feed displays shimmer', (
      tester,
    ) async {
      final blogCompleter = Completer<PaginatedBlogs>();
      final articleRepo = MockShimmerArticleRepo(articles: sampleArticles);
      final blogRepo = MockShimmerBlogRepo(completer: blogCompleter);

      await tester.pumpWidget(
        buildTestApp(articleRepo: articleRepo, blogRepo: blogRepo),
      );
      await tester.pumpAndSettle();

      // Switch to Blogs which is currently in-flight
      await tester.tap(find.byKey(const ValueKey('search_filter_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filter_option_blogs')));
      await tester.pump();

      expect(find.byType(ShimmerLoadingFeed), findsOneWidget);
      expect(find.byType(ArticleCardSkeleton), findsWidgets);

      blogCompleter.complete(
        PaginatedBlogs(
          count: 1,
          next: null,
          previous: null,
          results: sampleBlogs,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ShimmerLoadingFeed), findsNothing);
    });

    // 7. Successful API response replaces shimmer with actual cards
    testWidgets(
      '7. Successful API response replaces shimmer with actual cards',
      (tester) async {
        final completer = Completer<PaginatedArticles>();
        final articleRepo = MockShimmerArticleRepo(completer: completer);
        final blogRepo = MockShimmerBlogRepo();

        await tester.pumpWidget(
          buildTestApp(articleRepo: articleRepo, blogRepo: blogRepo),
        );
        await tester.pump();

        expect(find.byType(ShimmerLoadingFeed), findsOneWidget);
        expect(find.byType(ArticleCard), findsNothing);

        completer.complete(
          PaginatedArticles(
            count: 2,
            next: null,
            previous: null,
            results: sampleArticles,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ShimmerLoadingFeed), findsNothing);
        expect(find.byType(ArticleCard), findsNWidgets(2));
      },
    );

    // 8. Failed initial request displays the existing error/retry state rather than shimmer indefinitely
    testWidgets(
      '8. Failed initial request displays error/retry state rather than shimmer indefinitely',
      (tester) async {
        final articleRepo = MockShimmerArticleRepo(shouldThrow: true);
        final blogRepo = MockShimmerBlogRepo();

        await tester.pumpWidget(
          buildTestApp(articleRepo: articleRepo, blogRepo: blogRepo),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ShimmerLoadingFeed), findsNothing);
        expect(find.byType(AppErrorView), findsOneWidget);
        expect(find.text(AppStrings.retry), findsOneWidget);
      },
    );

    // 9. Failed search handles errors correctly
    testWidgets('9. Failed search handles errors correctly', (tester) async {
      final searchCompleter = Completer<PaginatedArticles>();
      final articleRepo = MockShimmerArticleRepo(articles: sampleArticles);
      final blogRepo = MockShimmerBlogRepo();

      await tester.pumpWidget(
        buildTestApp(articleRepo: articleRepo, blogRepo: blogRepo),
      );
      await tester.pumpAndSettle();

      articleRepo.completer = searchCompleter;

      await tester.enterText(find.byType(TextField), 'FailingQuery');
      await tester.pump(AppConstants.searchDebounceDuration);

      expect(find.byType(ShimmerLoadingFeed), findsOneWidget);

      // Complete with error
      searchCompleter.completeError(
        const ApiException(
          message: 'Server error on search',
          type: ApiExceptionType.server,
        ),
      );
      await tester.pumpAndSettle();

      // Shimmer should not hang indefinitely
      expect(find.byType(ShimmerLoadingFeed), findsNothing);
    });

    // 10. Pull-to-refresh preserves existing cards
    testWidgets('10. Pull-to-refresh preserves existing cards', (tester) async {
      final refreshCompleter = Completer<PaginatedArticles>();
      final articleRepo = MockShimmerArticleRepo(articles: sampleArticles);
      final blogRepo = MockShimmerBlogRepo();

      await tester.pumpWidget(
        buildTestApp(articleRepo: articleRepo, blogRepo: blogRepo),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ArticleCard), findsNWidgets(2));

      articleRepo.completer = refreshCompleter;

      // Trigger pull to refresh by flinging/dragging down
      await tester.fling(
        find.byKey(const PageStorageKey('articles_feed_list')),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // With refresh in-flight, existing cards remain visible, no shimmer
      expect(find.byType(ArticleCard), findsNWidgets(2));
      expect(find.byType(ShimmerLoadingFeed), findsNothing);

      // Complete refresh
      refreshCompleter.complete(
        PaginatedArticles(
          count: 2,
          next: null,
          previous: null,
          results: sampleArticles,
        ),
      );
      await tester.pumpAndSettle();
    });

    // 11. Pagination preserves existing cards and footer behavior
    testWidgets('11. Pagination preserves existing cards and footer behavior', (
      tester,
    ) async {
      final manyArticles = List.generate(
        10,
        (i) => Article(
          id: i + 1,
          title: 'Article $i',
          authors: const [],
          url: 'https://example.com/$i',
          imageUrl: '',
          newsSite: 'SpaceNews',
          summary: 'Summary $i',
          publishedAt: DateTime(2026, 11, 19),
        ),
      );

      final paginationCompleter = Completer<PaginatedArticles>();
      final articleRepo = MockShimmerArticleRepo(
        articles: manyArticles,
        nextUrl: 'https://example.com/next_page',
        paginationCompleter: paginationCompleter,
      );
      final blogRepo = MockShimmerBlogRepo();

      await tester.pumpWidget(
        buildTestApp(articleRepo: articleRepo, blogRepo: blogRepo),
      );
      await tester.pumpAndSettle();

      // Scroll near bottom to trigger loadMore
      await tester.drag(
        find.byKey(const PageStorageKey('articles_feed_list')),
        const Offset(0, -1000),
      );
      await tester.pump();

      // Existing cards remain, no full-list shimmer, pagination footer appears
      expect(find.byType(ShimmerLoadingFeed), findsNothing);
      expect(find.byType(ArticleCard), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      paginationCompleter.complete(
        PaginatedArticles(
          count: 10,
          next: null,
          previous: null,
          results: manyArticles,
        ),
      );
      await tester.pumpAndSettle();
    });

    // 12. No shimmer remains after a request completes
    testWidgets('12. No shimmer remains after a request completes', (
      tester,
    ) async {
      final articleRepo = MockShimmerArticleRepo(articles: sampleArticles);
      final blogRepo = MockShimmerBlogRepo();

      await tester.pumpWidget(
        buildTestApp(articleRepo: articleRepo, blogRepo: blogRepo),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ShimmerLoadingFeed), findsNothing);
      expect(find.byType(ArticleCardSkeleton), findsNothing);
    });

    // 13. Dark theme renders without errors
    testWidgets('13. Dark theme renders without errors', (tester) async {
      final completer = Completer<PaginatedArticles>();
      final articleRepo = MockShimmerArticleRepo(completer: completer);
      final blogRepo = MockShimmerBlogRepo();

      await tester.pumpWidget(
        buildTestApp(
          articleRepo: articleRepo,
          blogRepo: blogRepo,
          theme: AppTheme.darkTheme,
        ),
      );
      await tester.pump();

      expect(find.byType(ShimmerLoadingFeed), findsOneWidget);
      expect(tester.takeException(), isNull);

      completer.complete(
        const PaginatedArticles(
          count: 0,
          next: null,
          previous: null,
          results: [],
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    // 14. Tablet layout renders skeletons without overflow
    testWidgets('14. Tablet layout renders skeletons without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final completer = Completer<PaginatedArticles>();
      final articleRepo = MockShimmerArticleRepo(completer: completer);
      final blogRepo = MockShimmerBlogRepo();

      await tester.pumpWidget(
        buildTestApp(articleRepo: articleRepo, blogRepo: blogRepo),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('shimmer_feed_grid')), findsOneWidget);
      expect(find.byType(ArticleCardSkeleton), findsWidgets);
      expect(tester.takeException(), isNull);

      completer.complete(
        const PaginatedArticles(
          count: 0,
          next: null,
          previous: null,
          results: [],
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
