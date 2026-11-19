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

class MockPolishArticleRepo implements ArticleRepository {
  List<Article> articles;
  String? lastSearch;
  int callCount = 0;

  MockPolishArticleRepo(this.articles);

  @override
  Future<PaginatedArticles> getArticles({
    int limit = 10,
    int offset = 0,
    String? search,
  }) async {
    callCount++;
    lastSearch = search;
    return PaginatedArticles(
      count: articles.length,
      next: null,
      previous: null,
      results: articles,
    );
  }

  @override
  Future<Article> getArticleById(int id) async {
    return articles.firstWhere((a) => a.id == id);
  }
}

class MockPolishBlogRepo implements BlogRepository {
  List<Blog> blogs;
  String? lastSearch;
  int callCount = 0;

  MockPolishBlogRepo(this.blogs);

  @override
  Future<PaginatedBlogs> getBlogs({
    int limit = 10,
    int offset = 0,
    String? search,
  }) async {
    callCount++;
    lastSearch = search;
    return PaginatedBlogs(
      count: blogs.length,
      next: null,
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
  final sampleArticle = Article(
    id: 1,
    title: 'Polish and Feedback Verification Article',
    authors: const [Author(name: 'Senior QA Engineer')],
    url: 'https://example.com/polish-test',
    imageUrl: '', // Empty imageUrl avoids network loops in tests
    newsSite: 'NASA Space Science',
    summary: 'Testing category chips, hit areas, and accessibility feedback.',
    publishedAt: DateTime(2026, 11, 19, 10, 0),
    featured: true,
  );

  final sampleBlog = Blog(
    id: 101,
    title: 'Polish and Feedback Verification Blog Post',
    authors: const [Author(name: 'Lead Accessibility Specialist')],
    url: 'https://example.com/blog-polish',
    imageUrl: '', // Empty imageUrl avoids network loops in tests
    newsSite: 'Cosmic Science Blog',
    summary: 'Testing blog floating controls and interactive feedback.',
    publishedAt: DateTime(2026, 11, 19, 11, 0),
    featured: true,
  );

  Widget createDiscoverApp({
    required MockPolishArticleRepo articleRepo,
    required MockPolishBlogRepo blogRepo,
  }) {
    return MultiProvider(
      providers: [
        Provider<ArticleRepository>.value(value: articleRepo),
        Provider<BlogRepository>.value(value: blogRepo),
        ChangeNotifierProvider(
          create: (_) {
            final vm = ArticleViewModel(articleRepo);
            vm.fetchArticles();
            return vm;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final vm = BlogViewModel(blogRepo);
            vm.fetchBlogs();
            return vm;
          },
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const DiscoverScreen(),
      ),
    );
  }

  Widget createDetailApp({
    required Widget child,
    MockPolishArticleRepo? articleRepo,
    MockPolishBlogRepo? blogRepo,
  }) {
    final aRepo = articleRepo ?? MockPolishArticleRepo([sampleArticle]);
    final bRepo = blogRepo ?? MockPolishBlogRepo([sampleBlog]);
    return MultiProvider(
      providers: [
        Provider<ArticleRepository>.value(value: aRepo),
        Provider<BlogRepository>.value(value: bRepo),
        ChangeNotifierProvider(
          create: (_) {
            final vm = ArticleViewModel(aRepo);
            vm.fetchArticles();
            return vm;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final vm = BlogViewModel(bRepo);
            vm.fetchBlogs();
            return vm;
          },
        ),
      ],
      child: MaterialApp(theme: AppTheme.lightTheme, home: child),
    );
  }

  group('T031: UI Polish & Interaction Feedback Tests', () {
    // 1. Category chips respond to taps and preserve selection behavior
    testWidgets(
      '1. Category chips respond to taps and preserve selection behavior',
      (tester) async {
        final articleRepo = MockPolishArticleRepo([sampleArticle]);
        final blogRepo = MockPolishBlogRepo([sampleBlog]);

        await tester.pumpWidget(
          createDiscoverApp(articleRepo: articleRepo, blogRepo: blogRepo),
        );
        await tester.pumpAndSettle();

        // Initially 'All' is selected
        final allText = find.text('All');
        expect(allText, findsOneWidget);

        // Tap 'SpaceX' category chip
        final spaceXChip = find.text('SpaceX');
        expect(spaceXChip, findsOneWidget);
        await tester.tap(spaceXChip);
        await tester.pumpAndSettle();

        expect(articleRepo.lastSearch, 'SpaceX');

        // Tap 'All' category chip to clear
        await tester.tap(allText);
        await tester.pumpAndSettle();

        expect(articleRepo.lastSearch, isNull);
      },
    );

    // 2. Chip tap feedback uses a Material interaction mechanism
    testWidgets('2. Chip tap feedback uses Material InkWell with clipping', (
      tester,
    ) async {
      final articleRepo = MockPolishArticleRepo([sampleArticle]);
      final blogRepo = MockPolishBlogRepo([sampleBlog]);

      await tester.pumpWidget(
        createDiscoverApp(articleRepo: articleRepo, blogRepo: blogRepo),
      );
      await tester.pumpAndSettle();

      // Find the 'SpaceX' chip text
      final spaceXFinder = find.text('SpaceX');
      expect(spaceXFinder, findsOneWidget);

      // Verify it is ancestor-wrapped in an InkWell for Material touch feedback
      final inkWellFinder = find.ancestor(
        of: spaceXFinder,
        matching: find.byType(InkWell),
      );
      expect(inkWellFinder, findsOneWidget);

      // Verify the InkWell is inside a Material widget that clips anti-alias
      final materialFinder = find.ancestor(
        of: inkWellFinder,
        matching: find.byType(Material),
      );
      expect(materialFinder, findsWidgets);

      final materialWidget = tester.widget<Material>(materialFinder.first);
      expect(materialWidget.clipBehavior, Clip.antiAlias);

      // Verify accessibility semantics
      final semanticsFinder = find.ancestor(
        of: materialFinder,
        matching: find.byType(Semantics),
      );
      expect(semanticsFinder, findsWidgets);
    });

    // 3. Floating controls in ArticleDetailScreen expose at least 48x48 hit area
    testWidgets(
      '3. Floating controls in ArticleDetailScreen expose at least 48x48 hit area',
      (tester) async {
        await tester.pumpWidget(
          createDetailApp(child: ArticleDetailScreen(article: sampleArticle)),
        );
        await tester.pump();

        // Find Back button
        final backButtonFinder = find.widgetWithIcon(
          IconButton,
          Icons.arrow_back_ios_new_rounded,
        );
        expect(backButtonFinder, findsOneWidget);
        final backSize = tester.getSize(backButtonFinder);
        expect(backSize.width, greaterThanOrEqualTo(48.0));
        expect(backSize.height, greaterThanOrEqualTo(48.0));

        // Find Bookmark button
        final bookmarkButtonFinder = find.widgetWithIcon(
          IconButton,
          Icons.bookmark_border_rounded,
        );
        expect(bookmarkButtonFinder, findsOneWidget);
        final bookmarkSize = tester.getSize(bookmarkButtonFinder);
        expect(bookmarkSize.width, greaterThanOrEqualTo(48.0));
        expect(bookmarkSize.height, greaterThanOrEqualTo(48.0));

        // Find More button
        final moreButtonFinder = find.widgetWithIcon(
          IconButton,
          Icons.more_horiz_rounded,
        );
        expect(moreButtonFinder, findsOneWidget);
        final moreSize = tester.getSize(moreButtonFinder);
        expect(moreSize.width, greaterThanOrEqualTo(48.0));
        expect(moreSize.height, greaterThanOrEqualTo(48.0));

        // Verify visible circular background inside remains 40x40
        final visibleCircles = find.descendant(
          of: backButtonFinder,
          matching: find.byType(Container),
        );
        expect(visibleCircles, findsOneWidget);
        final circleSize = tester.getSize(visibleCircles);
        expect(circleSize.width, 40.0);
        expect(circleSize.height, 40.0);
      },
    );

    // 4. Floating controls in BlogDetailScreen expose at least 48x48 hit area
    testWidgets(
      '4. Floating controls in BlogDetailScreen expose at least 48x48 hit area',
      (tester) async {
        await tester.pumpWidget(
          createDetailApp(child: BlogDetailScreen(blog: sampleBlog)),
        );
        await tester.pump();

        // Find Back button
        final backFinder = find.widgetWithIcon(
          IconButton,
          Icons.arrow_back_ios_new_rounded,
        );
        expect(backFinder, findsOneWidget);
        final backSize = tester.getSize(backFinder);
        expect(backSize.width, greaterThanOrEqualTo(48.0));
        expect(backSize.height, greaterThanOrEqualTo(48.0));

        // Find Bookmark button
        final bookmarkFinder = find.widgetWithIcon(
          IconButton,
          Icons.bookmark_border_rounded,
        );
        expect(bookmarkFinder, findsOneWidget);
        final bookmarkSize = tester.getSize(bookmarkFinder);
        expect(bookmarkSize.width, greaterThanOrEqualTo(48.0));
        expect(bookmarkSize.height, greaterThanOrEqualTo(48.0));

        // Find More button
        final moreFinder = find.widgetWithIcon(
          IconButton,
          Icons.more_horiz_rounded,
        );
        expect(moreFinder, findsOneWidget);
        final moreSize = tester.getSize(moreFinder);
        expect(moreSize.width, greaterThanOrEqualTo(48.0));
        expect(moreSize.height, greaterThanOrEqualTo(48.0));

        // Verify visible circle inside is 40x40
        final visibleCircle = find.descendant(
          of: backFinder,
          matching: find.byType(Container),
        );
        expect(visibleCircle, findsOneWidget);
        final circleSize = tester.getSize(visibleCircle);
        expect(circleSize.width, 40.0);
        expect(circleSize.height, 40.0);
      },
    );

    // 5. Tooltips and semantic labels are present from AppStrings
    testWidgets('5. Tooltips and semantic labels are present from AppStrings', (
      tester,
    ) async {
      // Test ArticleDetailScreen tooltips
      await tester.pumpWidget(
        createDetailApp(child: ArticleDetailScreen(article: sampleArticle)),
      );
      await tester.pump();

      expect(find.byTooltip(AppStrings.back), findsOneWidget);
      expect(find.byTooltip(AppStrings.bookmarks), findsOneWidget);
      expect(find.byTooltip(AppStrings.moreOptions), findsOneWidget);

      // Test BlogDetailScreen tooltips
      await tester.pumpWidget(
        createDetailApp(child: BlogDetailScreen(blog: sampleBlog)),
      );
      await tester.pump();

      expect(find.byTooltip(AppStrings.back), findsOneWidget);
      expect(find.byTooltip(AppStrings.bookmarks), findsOneWidget);
      expect(find.byTooltip(AppStrings.moreOptions), findsOneWidget);
      expect(find.byTooltip(AppStrings.refresh), findsOneWidget);
    });

    // 6. No overlap or overflow at phone and landscape sizes
    testWidgets(
      '6. No overlap or overflow of floating controls across phone sizes',
      (tester) async {
        // Narrow phone portrait: 360 x 800
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createDetailApp(child: BlogDetailScreen(blog: sampleBlog)),
        );
        await tester.pump();

        final backRect = tester.getRect(
          find.widgetWithIcon(IconButton, Icons.arrow_back_ios_new_rounded),
        );
        final moreRect = tester.getRect(
          find.widgetWithIcon(IconButton, Icons.more_horiz_rounded),
        );

        // Verify Back and More buttons do not overlap horizontally
        expect(backRect.right, lessThan(moreRect.left));
        expect(tester.takeException(), isNull);

        // Phone landscape: 844 x 390
        tester.view.physicalSize = const Size(844, 390);
        await tester.pumpWidget(
          createDetailApp(child: ArticleDetailScreen(article: sampleArticle)),
        );
        await tester.pump();

        final landscapeBackRect = tester.getRect(
          find.widgetWithIcon(IconButton, Icons.arrow_back_ios_new_rounded),
        );
        final landscapeMoreRect = tester.getRect(
          find.widgetWithIcon(IconButton, Icons.more_horiz_rounded),
        );

        expect(landscapeBackRect.right, lessThan(landscapeMoreRect.left));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
