import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newsly/core/constants/app_strings.dart';
import 'package:newsly/core/theme/app_theme.dart';
import 'package:newsly/models/article_model.dart';
import 'package:newsly/models/blog_model.dart';
import 'package:newsly/repositories/article_repository.dart';
import 'package:newsly/repositories/blog_repository.dart';
import 'package:newsly/viewmodels/article_view_model.dart';
import 'package:newsly/viewmodels/blog_view_model.dart';
import 'package:newsly/views/screens/article_detail_screen.dart';
import 'package:newsly/views/screens/blog_detail_screen.dart';
import 'package:newsly/views/screens/discover_screen.dart';
import 'package:provider/provider.dart';

class MockUxArticleRepository implements ArticleRepository {
  List<Article> articlesToReturn;

  MockUxArticleRepository({this.articlesToReturn = const []});

  @override
  Future<PaginatedArticles> getArticles({
    int limit = 10,
    int offset = 0,
    String? search,
  }) async {
    return PaginatedArticles(
      count: articlesToReturn.length,
      next: null,
      previous: null,
      results: articlesToReturn,
    );
  }

  @override
  Future<Article> getArticleById(int id) async {
    return articlesToReturn.firstWhere((a) => a.id == id);
  }
}

class MockUxBlogRepository implements BlogRepository {
  List<Blog> blogsToReturn;

  MockUxBlogRepository({this.blogsToReturn = const []});

  @override
  Future<PaginatedBlogs> getBlogs({
    int limit = 10,
    int offset = 0,
    String? search,
  }) async {
    return PaginatedBlogs(
      count: blogsToReturn.length,
      next: null,
      previous: null,
      results: blogsToReturn,
    );
  }

  @override
  Future<Blog> getBlogById(int id) async {
    return blogsToReturn.firstWhere((b) => b.id == id);
  }
}

Widget createDiscoverTestWidget({
  required ArticleRepository articleRepo,
  required BlogRepository blogRepo,
}) {
  return MultiProvider(
    providers: [
      Provider<ArticleRepository>.value(value: articleRepo),
      Provider<BlogRepository>.value(value: blogRepo),
      ChangeNotifierProvider<ArticleViewModel>(
        create: (_) => ArticleViewModel(articleRepo),
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

Widget createArticleDetailTestWidget({
  required Article article,
  required List<Article> allArticles,
  int initialIndex = 0,
}) {
  final repo = MockUxArticleRepository(articlesToReturn: allArticles);
  final blogRepo = MockUxBlogRepository();
  return MultiProvider(
    providers: [
      Provider<ArticleRepository>.value(value: repo),
      Provider<BlogRepository>.value(value: blogRepo),
      ChangeNotifierProvider<ArticleViewModel>(
        create: (_) {
          final vm = ArticleViewModel(repo);
          vm.fetchArticles();
          return vm;
        },
      ),
      ChangeNotifierProvider<BlogViewModel>(
        create: (_) => BlogViewModel(blogRepo),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: ArticleDetailScreen(article: article, initialIndex: initialIndex),
    ),
  );
}

Widget createBlogDetailTestWidget({
  required Blog blog,
  required List<Blog> allBlogs,
  int initialIndex = 0,
}) {
  final repo = MockUxArticleRepository();
  final blogRepo = MockUxBlogRepository(blogsToReturn: allBlogs);
  return MultiProvider(
    providers: [
      Provider<ArticleRepository>.value(value: repo),
      Provider<BlogRepository>.value(value: blogRepo),
      ChangeNotifierProvider<ArticleViewModel>(
        create: (_) => ArticleViewModel(repo),
      ),
      ChangeNotifierProvider<BlogViewModel>(
        create: (_) {
          final vm = BlogViewModel(blogRepo);
          vm.fetchBlogs();
          return vm;
        },
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: BlogDetailScreen(blog: blog, initialIndex: initialIndex),
    ),
  );
}

void main() {
  final sampleArticles = [
    Article(
      id: 1,
      title: 'Landscape 16:9 Article',
      authors: const [Author(name: 'Sarah Connor')],
      url: 'https://example.com/art1',
      imageUrl: 'https://example.com/landscape_16_9.jpg',
      newsSite: 'NASA Space Science',
      summary: 'Summary of 16:9 landscape aspect ratio article test.',
      publishedAt: DateTime(2025, 1, 10),
    ),
    Article(
      id: 2,
      title: 'Portrait 9:16 Article',
      authors: const [Author(name: 'John Connor')],
      url: 'https://example.com/art2',
      imageUrl: 'https://example.com/portrait_9_16.jpg',
      newsSite: 'Ars Technica',
      summary: 'Summary of 9:16 portrait aspect ratio article test.',
      publishedAt: DateTime(2025, 1, 11),
    ),
    Article(
      id: 3,
      title: 'Square 1:1 Article',
      authors: const [Author(name: 'Kyle Reese')],
      url: 'https://example.com/art3',
      imageUrl: 'https://example.com/square_1_1.jpg',
      newsSite: 'SpaceNews',
      summary: 'Summary of 1:1 square aspect ratio article test.',
      publishedAt: DateTime(2025, 1, 12),
    ),
    Article(
      id: 4,
      title: 'Missing Image Fallback Article',
      authors: const [Author(name: 'Miles Dyson')],
      url: 'https://example.com/art4',
      imageUrl: '',
      newsSite: 'Planetary Society',
      summary: 'Summary of missing image fallback article test.',
      publishedAt: DateTime(2025, 1, 13),
    ),
  ];

  final sampleBlogs = [
    Blog(
      id: 101,
      title: 'Landscape 16:9 Blog',
      authors: const [Author(name: 'Elena Vance')],
      url: 'https://example.com/blog1',
      imageUrl: 'https://example.com/landscape_16_9.jpg',
      newsSite: 'ESA Portal',
      summary: 'Summary of 16:9 landscape aspect ratio blog test.',
      publishedAt: DateTime(2025, 2, 10),
    ),
    Blog(
      id: 102,
      title: 'Portrait 9:16 Blog',
      authors: const [Author(name: 'Gordon Freeman')],
      url: 'https://example.com/blog2',
      imageUrl: 'https://example.com/portrait_9_16.jpg',
      newsSite: 'Black Mesa',
      summary: 'Summary of 9:16 portrait aspect ratio blog test.',
      publishedAt: DateTime(2025, 2, 11),
    ),
    Blog(
      id: 103,
      title: 'Square 1:1 Blog',
      authors: const [Author(name: 'Barney Calhoun')],
      url: 'https://example.com/blog3',
      imageUrl: 'https://example.com/square_1_1.jpg',
      newsSite: 'Aperture Science',
      summary: 'Summary of 1:1 square aspect ratio blog test.',
      publishedAt: DateTime(2025, 2, 12),
    ),
    Blog(
      id: 104,
      title: 'Missing Image Fallback Blog',
      authors: const [Author(name: 'Eli Vance')],
      url: 'https://example.com/blog4',
      imageUrl: '',
      newsSite: 'White Forest',
      summary: 'Summary of missing image fallback blog test.',
      publishedAt: DateTime(2025, 2, 13),
    ),
  ];

  group('UX Bug Fix 1: Filter Bottom Sheet Behavior & Sizing', () {
    testWidgets(
      'Filter bottom sheet naturally fits content without half-screen void',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final articleRepo = MockUxArticleRepository(
          articlesToReturn: sampleArticles,
        );
        final blogRepo = MockUxBlogRepository(blogsToReturn: sampleBlogs);

        await tester.pumpWidget(
          createDiscoverTestWidget(
            articleRepo: articleRepo,
            blogRepo: blogRepo,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Tap the filter button in search bar
        final filterButton = find.byKey(const ValueKey('search_filter_button'));
        expect(filterButton, findsOneWidget);
        await tester.tap(filterButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Verify bottom sheet content card is rendered
        final sheetCardFinder = find.byKey(
          const ValueKey('filter_sheet_content'),
        );
        expect(sheetCardFinder, findsOneWidget);

        final sheetSize = tester.getSize(sheetCardFinder);
        // Bottom sheet must naturally fit content:
        // Content height is ~210-250px, which is well below half-screen (844 / 2 = 422px)
        expect(sheetSize.height, lessThan(350));
        expect(sheetSize.height, greaterThan(150));

        // Title & options are positioned near the top of the sheet
        final titleFinder = find.text(AppStrings.exploreContent);
        expect(titleFinder, findsOneWidget);

        final sheetTop = tester.getTopLeft(sheetCardFinder).dy;
        final titleTop = tester.getTopLeft(titleFinder).dy;
        // Title should be within ~60px of sheet top (drag handle + top padding)
        expect(titleTop - sheetTop, lessThan(60));

        // Both options exist and are clearly visible
        final articlesOption = find.byKey(
          const ValueKey('filter_option_articles'),
        );
        final blogsOption = find.byKey(const ValueKey('filter_option_blogs'));
        expect(articlesOption, findsOneWidget);
        expect(blogsOption, findsOneWidget);

        // Verify selecting Blogs option switches feed and closes bottom sheet
        await tester.tap(blogsOption);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(find.byType(BottomSheet), findsNothing);
        expect(find.text('Landscape 16:9 Blog'), findsOneWidget);
      },
    );

    testWidgets(
      'Filter bottom sheet is constrained to maxWidth 500 on tablet',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1024 * 2.0, 768 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final articleRepo = MockUxArticleRepository(
          articlesToReturn: sampleArticles,
        );
        final blogRepo = MockUxBlogRepository(blogsToReturn: sampleBlogs);

        await tester.pumpWidget(
          createDiscoverTestWidget(
            articleRepo: articleRepo,
            blogRepo: blogRepo,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        await tester.tap(find.byKey(const ValueKey('search_filter_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        final sheetCardFinder = find.byKey(
          const ValueKey('filter_sheet_content'),
        );
        expect(sheetCardFinder, findsOneWidget);

        final sheetSize = tester.getSize(sheetCardFinder);
        expect(sheetSize.width, lessThanOrEqualTo(500));
      },
    );

    testWidgets(
      'Filter bottom sheet supports 2.0x text scaling without RenderFlex overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final articleRepo = MockUxArticleRepository(
          articlesToReturn: sampleArticles,
        );
        final blogRepo = MockUxBlogRepository(blogsToReturn: sampleBlogs);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: createDiscoverTestWidget(
              articleRepo: articleRepo,
              blogRepo: blogRepo,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        await tester.tap(find.byKey(const ValueKey('search_filter_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        expect(tester.takeException(), isNull);
        expect(find.byType(BottomSheet), findsOneWidget);
      },
    );
  });

  group('UX Bug Fix 2: Consistent Floating Controls & Hero Image Behavior', () {
    testWidgets(
      'ArticleDetailScreen: floating controls have identical coordinates across 4 image aspect ratios',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        Offset? initialBackPos;
        Offset? initialBookmarkPos;
        Offset? initialMorePos;

        for (int i = 0; i < sampleArticles.length; i++) {
          await tester.pumpWidget(
            createArticleDetailTestWidget(
              article: sampleArticles[i],
              allArticles: sampleArticles,
              initialIndex: i,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));

          final backBtn = find.byTooltip(AppStrings.back);
          final bookmarkBtn = find.byTooltip(AppStrings.bookmarks);
          final moreBtn = find.byTooltip(AppStrings.moreOptions);

          expect(backBtn, findsOneWidget);
          expect(bookmarkBtn, findsOneWidget);
          expect(moreBtn, findsOneWidget);

          final backPos = tester.getTopLeft(backBtn);
          final bookmarkPos = tester.getTopLeft(bookmarkBtn);
          final morePos = tester.getTopLeft(moreBtn);

          // Verify touch targets are at least 48x48
          final backSize = tester.getSize(backBtn);
          expect(backSize.width, greaterThanOrEqualTo(48.0));
          expect(backSize.height, greaterThanOrEqualTo(48.0));

          if (initialBackPos == null) {
            initialBackPos = backPos;
            initialBookmarkPos = bookmarkPos;
            initialMorePos = morePos;
          } else {
            // Floating controls must NOT shift when navigating between items with different image dimensions or missing images
            expect(backPos.dx, equals(initialBackPos.dx));
            expect(backPos.dy, equals(initialBackPos.dy));
            expect(bookmarkPos.dx, equals(initialBookmarkPos!.dx));
            expect(bookmarkPos.dy, equals(initialBookmarkPos.dy));
            expect(morePos.dx, equals(initialMorePos!.dx));
            expect(morePos.dy, equals(initialMorePos.dy));
          }
        }
      },
    );

    testWidgets(
      'BlogDetailScreen: floating controls have identical coordinates across 4 image aspect ratios',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        Offset? initialBackPos;
        Offset? initialBookmarkPos;
        Offset? initialMorePos;

        for (int i = 0; i < sampleBlogs.length; i++) {
          await tester.pumpWidget(
            createBlogDetailTestWidget(
              blog: sampleBlogs[i],
              allBlogs: sampleBlogs,
              initialIndex: i,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 200));

          final backBtn = find.byTooltip(AppStrings.back);
          final bookmarkBtn = find.byTooltip(AppStrings.bookmarks);
          final moreBtn = find.byTooltip(AppStrings.moreOptions);

          expect(backBtn, findsOneWidget);
          expect(bookmarkBtn, findsOneWidget);
          expect(moreBtn, findsOneWidget);

          final backPos = tester.getTopLeft(backBtn);
          final bookmarkPos = tester.getTopLeft(bookmarkBtn);
          final morePos = tester.getTopLeft(moreBtn);

          // Verify touch targets are at least 48x48
          final backSize = tester.getSize(backBtn);
          expect(backSize.width, greaterThanOrEqualTo(48.0));
          expect(backSize.height, greaterThanOrEqualTo(48.0));

          if (initialBackPos == null) {
            initialBackPos = backPos;
            initialBookmarkPos = bookmarkPos;
            initialMorePos = morePos;
          } else {
            // Floating controls must NOT shift between different image aspect ratios
            expect(backPos.dx, equals(initialBackPos.dx));
            expect(backPos.dy, equals(initialBackPos.dy));
            expect(bookmarkPos.dx, equals(initialBookmarkPos!.dx));
            expect(bookmarkPos.dy, equals(initialBookmarkPos.dy));
            expect(morePos.dx, equals(initialMorePos!.dx));
            expect(morePos.dy, equals(initialMorePos.dy));
          }
        }
      },
    );

    testWidgets(
      'Article and Blog detail screens have identical floating control offsets and touch targets',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Pump ArticleDetailScreen
        await tester.pumpWidget(
          createArticleDetailTestWidget(
            article: sampleArticles[0],
            allArticles: sampleArticles,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump();

        final articleBackPos = tester.getTopLeft(
          find.byTooltip(AppStrings.back),
        );
        final articleMorePos = tester.getTopLeft(
          find.byTooltip(AppStrings.moreOptions),
        );

        // Pump BlogDetailScreen
        await tester.pumpWidget(
          createBlogDetailTestWidget(
            blog: sampleBlogs[0],
            allBlogs: sampleBlogs,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump();

        final blogBackPos = tester.getTopLeft(find.byTooltip(AppStrings.back));
        final blogMorePos = tester.getTopLeft(
          find.byTooltip(AppStrings.moreOptions),
        );

        // Check alignment parity
        expect(blogBackPos.dx, equals(articleBackPos.dx));
        expect(blogBackPos.dy, equals(articleBackPos.dy));
        expect(blogMorePos.dx, equals(articleMorePos.dx));
        expect(blogMorePos.dy, equals(articleMorePos.dy));
      },
    );

    testWidgets(
      'Detail screen hero image container and controls in landscape mode do not overflow',
      (WidgetTester tester) async {
        // Landscape phone viewport (844 x 390)
        tester.view.physicalSize = const Size(844 * 2.0, 390 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createArticleDetailTestWidget(
            article: sampleArticles[0],
            allArticles: sampleArticles,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull);
        expect(find.byTooltip(AppStrings.back), findsOneWidget);
        expect(find.byTooltip(AppStrings.bookmarks), findsOneWidget);
        expect(find.byTooltip(AppStrings.moreOptions), findsOneWidget);
      },
    );

    testWidgets(
      'Book-style swipe navigation transitions between items smoothly',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(390 * 2.0, 844 * 2.0);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createArticleDetailTestWidget(
            article: sampleArticles[0],
            allArticles: sampleArticles,
            initialIndex: 0,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Landscape 16:9 Article'), findsOneWidget);

        // Swipe left to view next article
        await tester.drag(find.byType(PageView), const Offset(-400, 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Portrait 9:16 Article'), findsOneWidget);
      },
    );
  });
}
