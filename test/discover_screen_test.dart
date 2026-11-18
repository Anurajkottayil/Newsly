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

    if (completer != null) {
      return completer!.future;
    }

    if (shouldThrow) {
      throw ApiException(message: errorMessage, type: ApiExceptionType.network);
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

  MockBlogRepository({
    this.blogsToReturn = const [],
    this.nextUrl,
    this.shouldThrow = false,
    this.errorMessage = 'Network error',
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
      throw ApiException(message: errorMessage, type: ApiExceptionType.network);
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

      // Now fix repo and tap retry
      mockRepo.shouldThrow = false;
      mockRepo.articlesToReturn = sampleArticles;

      await tester.tap(find.text(AppStrings.retry));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

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

        // Verify blog is fetched and displayed
        expect(mockBlogRepo.callCount, 1);
        expect(find.text('Sample Spaceflight Blog Post'), findsOneWidget);

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
  });
}
