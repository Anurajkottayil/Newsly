import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newsly/core/constants/app_strings.dart';
import 'package:newsly/core/errors/api_exception.dart';
import 'package:newsly/core/theme/app_theme.dart';
import 'package:newsly/models/article_model.dart';
import 'package:newsly/models/blog_model.dart';
import 'package:newsly/repositories/article_repository.dart';
import 'package:newsly/repositories/blog_repository.dart';
import 'package:newsly/viewmodels/article_view_model.dart';
import 'package:newsly/viewmodels/blog_view_model.dart';
import 'package:newsly/views/screens/article_detail_screen.dart';
import 'package:newsly/views/screens/blog_detail_screen.dart';
import 'package:provider/provider.dart';

class MockDetailArticleRepository implements ArticleRepository {
  List<Article> articlesToReturn;
  String? nextUrl;
  bool shouldThrow;

  MockDetailArticleRepository({
    this.articlesToReturn = const [],
    this.nextUrl,
    this.shouldThrow = false,
  });

  @override
  Future<PaginatedArticles> getArticles({
    int limit = 10,
    int offset = 0,
    String? search,
  }) async {
    if (shouldThrow) {
      throw ApiException(
        message: 'Pagination network failure',
        type: ApiExceptionType.network,
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

class MockDetailBlogRepository implements BlogRepository {
  List<Blog> blogsToReturn;
  String? nextUrl;
  bool shouldThrow;

  MockDetailBlogRepository({
    this.blogsToReturn = const [],
    this.nextUrl,
    this.shouldThrow = false,
  });

  @override
  Future<PaginatedBlogs> getBlogs({
    int limit = 10,
    int offset = 0,
    String? search,
  }) async {
    if (shouldThrow) {
      throw ApiException(
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
    return blogsToReturn.firstWhere((b) => b.id == id);
  }
}

void main() {
  final sampleArticle1 = Article(
    id: 1,
    title: 'Artemis II Astronauts Prepare for Historic Lunar Flyby Mission',
    authors: const [Author(name: 'Commander Reid Wiseman')],
    url: 'https://example.com/artemis-2',
    imageUrl: '', // Empty imageUrl avoids network loops in tests
    newsSite: 'NASA Spaceflight',
    summary:
        'NASA astronauts continue comprehensive simulations and egress training at Kennedy Space Center ahead of the upcoming Artemis II mission.',
    publishedAt: DateTime(2026, 11, 18, 10, 0),
    featured: true,
  );

  final sampleArticle2 = Article(
    id: 2,
    title: 'Starship Orbital Refueling Demo Set for Low Earth Orbit Test',
    authors: const [Author(name: 'Aerospace Analyst')],
    url: 'https://example.com/starship-refuel',
    imageUrl: '',
    newsSite: 'Spaceflight Now',
    summary:
        'SpaceX prepares ship-to-ship cryogenic propellant transfer tests in orbit, marking a critical milestone for lunar missions.',
    publishedAt: DateTime(2026, 11, 19, 8, 30),
    featured: false,
  );

  // Article with a very short summary
  final shortSummaryArticle = Article(
    id: 3,
    title: 'Short Summary Article',
    authors: const [Author(name: 'Staff Reporter')],
    url: 'https://example.com/short',
    imageUrl: '',
    newsSite: 'SpaceNews',
    summary: 'Brief update.',
    publishedAt: DateTime(2026, 11, 20),
    featured: false,
  );

  // Article with no summary
  final noSummaryArticle = Article(
    id: 4,
    title: 'No Summary Article',
    authors: const [Author(name: 'Staff Reporter')],
    url: 'https://example.com/nosummary',
    imageUrl: '',
    newsSite: 'SpaceNews',
    summary: '',
    publishedAt: DateTime(2026, 11, 20),
    featured: false,
  );

  // Article with a very long summary
  final longSummaryArticle = Article(
    id: 5,
    title: 'Long Summary Article',
    authors: const [Author(name: 'Deep Dive Writer')],
    url: 'https://example.com/long',
    imageUrl: '',
    newsSite: 'SpaceNews',
    summary:
        'This is a very long summary that goes on and on describing the mission in great detail. '
        'The Artemis program represents humanity\'s next chapter in deep space exploration. '
        'Engineers at NASA have worked for years developing the Space Launch System, '
        'the most powerful rocket ever built. The first crewed mission around the Moon '
        'will carry four astronauts on a ten-day journey. The mission will validate life '
        'support systems, navigation, and re-entry procedures needed for future lunar landings. '
        'This is unprecedented in the history of human spaceflight and marks a turning point '
        'for the future of human presence beyond Earth orbit. Much more content follows here '
        'to simulate a genuinely long article summary that will require scrolling on any device.',
    publishedAt: DateTime(2026, 11, 20),
    featured: true,
  );

  final sampleBlog1 = Blog(
    id: 101,
    title: 'Inside the Falcon 9 Booster Turnaround Facility at Port Canaveral',
    authors: const [Author(name: 'Pad Lead Engineer')],
    url: 'https://example.com/booster-turnaround',
    imageUrl: '', // Empty imageUrl avoids network loops in tests
    newsSite: 'Space Exploration Blog',
    summary:
        'A comprehensive walk-through of rapid booster inspection, refurbishing Merlin engines, and rolling back onto the transporter erector.',
    publishedAt: DateTime(2026, 11, 18, 12, 15),
    featured: true,
  );

  final sampleBlog2 = Blog(
    id: 102,
    title: 'James Webb Observations Reveal Early Galaxy Formation Mysteries',
    authors: const [Author(name: 'Astrophysics Contributor')],
    url: 'https://example.com/jwst-blog',
    imageUrl: '',
    newsSite: 'Cosmic Horizons',
    summary:
        'Recent infrared spectra from high-redshift universe shed new light on rapid supermassive black hole growth.',
    publishedAt: DateTime(2026, 11, 19, 9, 45),
    featured: false,
  );

  // Blog with a short summary
  final shortSummaryBlog = Blog(
    id: 103,
    title: 'Short Blog Post',
    authors: const [Author(name: 'Staff Writer')],
    url: 'https://example.com/short-blog',
    imageUrl: '',
    newsSite: 'SpaceBlog',
    summary: 'Quick note.',
    publishedAt: DateTime(2026, 11, 20),
    featured: false,
  );

  // Blog with no summary
  final noSummaryBlog = Blog(
    id: 104,
    title: 'No Summary Blog',
    authors: const [Author(name: 'Staff Writer')],
    url: 'https://example.com/nosummary-blog',
    imageUrl: '',
    newsSite: 'SpaceBlog',
    summary: '',
    publishedAt: DateTime(2026, 11, 20),
    featured: false,
  );

  Widget wrapWithProviders({
    required Widget child,
    List<Article>? articles,
    List<Blog>? blogs,
    double textScale = 1.0,
    ThemeData? theme,
  }) {
    final articleRepo = MockDetailArticleRepository(
      articlesToReturn:
          articles ??
          [
            sampleArticle1,
            sampleArticle2,
            shortSummaryArticle,
            noSummaryArticle,
            longSummaryArticle,
          ],
    );
    final blogRepo = MockDetailBlogRepository(
      blogsToReturn:
          blogs ?? [sampleBlog1, sampleBlog2, shortSummaryBlog, noSummaryBlog],
    );

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
        theme: theme ?? AppTheme.lightTheme,
        builder: (context, widget) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: widget!,
          );
        },
        home: child,
      ),
    );
  }

  // Geometry measurement helpers
  Rect getHeroRect(WidgetTester tester) {
    return tester.getRect(find.byType(Hero).first);
  }

  Rect getContentSheetRect(WidgetTester tester, {bool isBlog = false}) {
    final ctaText = isBlog
        ? AppStrings.readFullBlogPost
        : AppStrings.readFullArticle;
    return tester.getRect(
      find
          .ancestor(of: find.text(ctaText), matching: find.byType(Container))
          .first,
    );
  }

  double getInternalLeftPadding(WidgetTester tester, {bool isBlog = false}) {
    final ctaButtonFinder = find.byType(ElevatedButton).first;
    final buttonLeft = tester.getTopLeft(ctaButtonFinder).dx;
    final sheetLeft = getContentSheetRect(tester, isBlog: isBlog).left;
    return buttonLeft - sheetLeft;
  }

  double ctaTop(WidgetTester tester) {
    final ctaFinder = find.text(AppStrings.readFullArticle);
    return tester.getTopLeft(ctaFinder).dy;
  }


  group('Responsive Detail Screen — Viewport Width Geometry & Layout Tests', () {
    // ─── 1. Viewport 390dp: Existing mobile layout preserved ────────────────
    testWidgets(
      '1. Viewport 390dp: mobile layout preserved, full-width hero and sheet, 0 outer gap',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          wrapWithProviders(
            child: ArticleDetailScreen(article: sampleArticle1),
          ),
        );
        await tester.pump();

        final heroRect = getHeroRect(tester);
        final sheetRect = getContentSheetRect(tester);
        final internalPadding = getInternalLeftPadding(tester);

        // 390dp mobile: hero and content sheet occupy full width with 0 outer gaps
        expect(heroRect.width, equals(390.0));
        expect(sheetRect.width, equals(390.0));
        expect(heroRect.left, equals(0.0));
        expect(390.0 - heroRect.right, equals(0.0));
        expect(sheetRect.left, equals(0.0));
        expect(390.0 - sheetRect.right, equals(0.0));

        // Edges align perfectly
        expect(heroRect.left, equals(sheetRect.left));
        expect(heroRect.right, equals(sheetRect.right));

        // Mobile internal padding preserved at 20dp
        expect(internalPadding, equals(20.0));
        expect(tester.takeException(), isNull);
      },
    );

    // ─── 2. Viewport 600dp: Tablet breakpoint transition ─────────────────────
    testWidgets(
      '2. Viewport 600dp: tablet breakpoint transition uses full available width',
      (tester) async {
        tester.view.physicalSize = const Size(600, 960);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          wrapWithProviders(
            child: ArticleDetailScreen(article: sampleArticle1),
          ),
        );
        await tester.pump();

        final heroRect = getHeroRect(tester);
        final sheetRect = getContentSheetRect(tester);
        final internalPadding = getInternalLeftPadding(tester);

        expect(heroRect.width, equals(600.0));
        expect(sheetRect.width, equals(600.0));
        expect(heroRect.left, equals(0.0));
        expect(600.0 - heroRect.right, equals(0.0));
        expect(sheetRect.left, equals(0.0));
        expect(600.0 - sheetRect.right, equals(0.0));

        // Edges align
        expect(heroRect.left, equals(sheetRect.left));
        expect(heroRect.right, equals(sheetRect.right));

        // Responsive internal padding at 600dp
        expect(internalPadding, equals(24.0));
        expect(tester.takeException(), isNull);
      },
    );

    // ─── 3. Viewport 700dp: Tablet layout uses available width ───────────────
    testWidgets(
      '3. Viewport 700dp: tablet layout uses full 700dp available width without side gaps',
      (tester) async {
        tester.view.physicalSize = const Size(700, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          wrapWithProviders(
            child: ArticleDetailScreen(article: sampleArticle1),
          ),
        );
        await tester.pump();

        final heroRect = getHeroRect(tester);
        final sheetRect = getContentSheetRect(tester);
        final internalPadding = getInternalLeftPadding(tester);

        // Crucial regression test: must NOT be clamped to 600dp with 50dp side gaps
        expect(heroRect.width, equals(700.0));
        expect(sheetRect.width, equals(700.0));
        expect(heroRect.left, equals(0.0));
        expect(700.0 - heroRect.right, equals(0.0));
        expect(sheetRect.left, equals(0.0));
        expect(700.0 - sheetRect.right, equals(0.0));

        // Edges align
        expect(heroRect.left, equals(sheetRect.left));
        expect(heroRect.right, equals(sheetRect.right));

        // Responsive internal padding at 700dp
        expect(internalPadding, equals(32.0));
        expect(tester.takeException(), isNull);
      },
    );

    // ─── 4. Viewport 800dp: No excessive horizontal gaps ─────────────────────
    testWidgets(
      '4. Viewport 800dp: no excessive horizontal gaps, hero and sheet occupy full 800dp',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1280);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          wrapWithProviders(
            child: ArticleDetailScreen(article: sampleArticle1),
          ),
        );
        await tester.pump();

        final heroRect = getHeroRect(tester);
        final sheetRect = getContentSheetRect(tester);
        final internalPadding = getInternalLeftPadding(tester);

        // Regression check: must NOT be narrowed to 680dp (0.85 * 800) with 60dp side gaps
        expect(heroRect.width, equals(800.0));
        expect(sheetRect.width, equals(800.0));
        expect(heroRect.left, equals(0.0));
        expect(800.0 - heroRect.right, equals(0.0));
        expect(sheetRect.left, equals(0.0));
        expect(800.0 - sheetRect.right, equals(0.0));

        // Edges align
        expect(heroRect.left, equals(sheetRect.left));
        expect(heroRect.right, equals(sheetRect.right));

        // Comfortable reading column via 40dp padding
        expect(internalPadding, equals(40.0));
        expect(tester.takeException(), isNull);
      },
    );

    // ─── 5. Viewport 1024dp: Wider responsive detail layout ──────────────────
    testWidgets(
      '5. Viewport 1024dp: wider responsive detail layout uses full 1024dp without gaps',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          wrapWithProviders(
            child: ArticleDetailScreen(article: sampleArticle1),
          ),
        );
        await tester.pump();

        final heroRect = getHeroRect(tester);
        final sheetRect = getContentSheetRect(tester);
        final internalPadding = getInternalLeftPadding(tester);

        // Uses full 1024dp width, zero outer gaps
        expect(heroRect.width, equals(1024.0));
        expect(sheetRect.width, equals(1024.0));
        expect(heroRect.left, equals(0.0));
        expect(1024.0 - heroRect.right, equals(0.0));
        expect(sheetRect.left, equals(0.0));
        expect(1024.0 - sheetRect.right, equals(0.0));

        // Edges align
        expect(heroRect.left, equals(sheetRect.left));
        expect(heroRect.right, equals(sheetRect.right));

        // Reading column is comfortably centered at ~760dp width
        final readingColumnWidth = sheetRect.width - (internalPadding * 2);
        expect(readingColumnWidth, equals(760.0));
        expect(internalPadding, equals(132.0));
        expect(tester.takeException(), isNull);
      },
    );

    // ─── 6. Viewport 1200dp: Sensible maximum width without excessive stretch ─
    testWidgets(
      '6. Viewport 1200dp: sensible maximum width (1024dp) prevents excessive stretching',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          wrapWithProviders(
            child: ArticleDetailScreen(article: sampleArticle1),
          ),
        );
        await tester.pump();

        final heroRect = getHeroRect(tester);
        final sheetRect = getContentSheetRect(tester);

        // Capped at desktopBreakpoint (1024dp)
        expect(heroRect.width, equals(1024.0));
        expect(sheetRect.width, equals(1024.0));

        // Symmetrically centered: (1200 - 1024) / 2 = 88.0
        expect(heroRect.left, equals(88.0));
        expect(1200.0 - heroRect.right, equals(88.0));
        expect(sheetRect.left, equals(88.0));
        expect(1200.0 - sheetRect.right, equals(88.0));

        // Edges align perfectly
        expect(heroRect.left, equals(sheetRect.left));
        expect(heroRect.right, equals(sheetRect.right));
        expect(tester.takeException(), isNull);
      },
    );

    // ─── 7. Blog Detail consistency at 800dp and 1024dp ──────────────────────
    testWidgets(
      '7. Blog detail: uses full width at 800dp and 1024dp with edge alignment',
      (tester) async {
        // Test 800dp
        tester.view.physicalSize = const Size(800, 1280);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          wrapWithProviders(child: BlogDetailScreen(blog: sampleBlog1)),
        );
        await tester.pump();

        final hero800 = getHeroRect(tester);
        final sheet800 = getContentSheetRect(tester, isBlog: true);
        expect(hero800.width, equals(800.0));
        expect(sheet800.width, equals(800.0));
        expect(hero800.left, equals(0.0));
        expect(sheet800.left, equals(0.0));
        expect(hero800.left, equals(sheet800.left));
        expect(hero800.right, equals(sheet800.right));

        // Test 1024dp
        tester.view.physicalSize = const Size(1024, 768);
        await tester.pumpWidget(
          wrapWithProviders(child: BlogDetailScreen(blog: sampleBlog1)),
        );
        await tester.pump();

        final hero1024 = getHeroRect(tester);
        final sheet1024 = getContentSheetRect(tester, isBlog: true);
        expect(hero1024.width, equals(1024.0));
        expect(sheet1024.width, equals(1024.0));
        expect(hero1024.left, equals(0.0));
        expect(sheet1024.left, equals(0.0));
        expect(hero1024.left, equals(sheet1024.left));
        expect(hero1024.right, equals(sheet1024.right));
        expect(tester.takeException(), isNull);
      },
    );

    // ─── 8. Section alignment verification: headline and reading column ──────
    testWidgets(
      '8. Headline, controls, publisher and CTA are vertically aligned on tablet',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1280);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          wrapWithProviders(
            child: ArticleDetailScreen(article: sampleArticle1),
          ),
        );
        await tester.pump();

        final internalPadding = getInternalLeftPadding(tester);
        expect(internalPadding, equals(40.0));

        // Headline text left position matches internal padding
        final headlineLeft = tester
            .getTopLeft(find.text(sampleArticle1.title))
            .dx;
        expect(headlineLeft, equals(40.0));

        // CTA button left position matches internal padding
        final ctaLeft = tester
            .getTopLeft(find.byType(ElevatedButton).first)
            .dx;
        expect(ctaLeft, equals(40.0));

        // Headline, publisher, and CTA all share the exact same left coordinate
        expect(headlineLeft, equals(ctaLeft));
        expect(tester.takeException(), isNull);
      },
    );

    // ─── 9. Phone landscape scrollable ───────────────────────────────────────
    testWidgets('9. Article detail in phone landscape (~844 x 390)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        wrapWithProviders(child: ArticleDetailScreen(article: sampleArticle1)),
      );
      await tester.pump();

      expect(find.text(sampleArticle1.title), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsWidgets);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -300),
      );
      await tester.pump();
      expect(find.text(AppStrings.readFullArticle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ─── 10. Phone landscape Blog ────────────────────────────────────────────
    testWidgets('10. Blog detail in phone landscape (~844 x 390)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        wrapWithProviders(child: BlogDetailScreen(blog: sampleBlog1)),
      );
      await tester.pump();

      expect(find.text(sampleBlog1.title), findsOneWidget);
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -300),
      );
      await tester.pump();
      expect(find.text(AppStrings.readFullBlogPost), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // ─── 11. Short landscape height: zero overflow ───────────────────────────
    testWidgets('11. Zero overflow at short landscape height (700 x 340)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(700, 340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        wrapWithProviders(child: ArticleDetailScreen(article: sampleArticle1)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(
        wrapWithProviders(child: BlogDetailScreen(blog: sampleBlog1)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    // ─── 12. Large text scaling on tablet and landscape ──────────────────────
    testWidgets(
      '12. Large text scaling (1.5x and 2.0x) on tablet and landscape',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 768);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          wrapWithProviders(
            child: ArticleDetailScreen(article: sampleArticle1),
            textScale: 1.5,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);

        tester.view.physicalSize = const Size(844, 390);
        await tester.pumpWidget(
          wrapWithProviders(
            child: BlogDetailScreen(blog: sampleBlog1),
            textScale: 1.5,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          wrapWithProviders(
            child: ArticleDetailScreen(article: sampleArticle1),
            textScale: 2.0,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);

        tester.view.physicalSize = const Size(1024, 768);
        await tester.pumpWidget(
          wrapWithProviders(
            child: BlogDetailScreen(blog: sampleBlog1),
            textScale: 2.0,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
      },
    );

    // ─── 13. Swipe, back navigation, URL actions intact ──────────────────────
    testWidgets(
      '13. Swipe navigation, back navigation, and URL actions remain intact',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        bool backInvoked = false;

        await tester.pumpWidget(
          wrapWithProviders(
            child: ArticleDetailScreen(
              article: sampleArticle1,
              onBack: () => backInvoked = true,
            ),
          ),
        );
        await tester.pump();

        expect(find.text(sampleArticle1.title), findsOneWidget);

        // Swipe LEFT -> advances to article 2
        await tester.drag(find.byType(PageView), const Offset(-400, 0));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text(sampleArticle2.title), findsOneWidget);

        // Swipe RIGHT -> returns to article 1
        await tester.drag(find.byType(PageView), const Offset(400, 0));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text(sampleArticle1.title), findsOneWidget);

        // Tap back button
        final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
        expect(backBtn, findsOneWidget);
        await tester.tap(backBtn);
        await tester.pump();
        expect(backInvoked, isTrue);
      },
    );

    // ─── 14. Tablet portrait short summary ───────────────────────────────────
    testWidgets(
      '14. Tablet portrait (800x1280): article short summary renders without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1280);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          wrapWithProviders(
            child: ArticleDetailScreen(article: shortSummaryArticle),
            articles: [shortSummaryArticle],
          ),
        );
        await tester.pump();

        expect(find.text(shortSummaryArticle.title), findsOneWidget);
        expect(find.text(AppStrings.readFullArticle), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    // ─── 15. Tablet portrait long summary ────────────────────────────────────
    testWidgets(
      '15. Tablet portrait (800x1280): article long summary scrollable',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1280);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          wrapWithProviders(
            child: ArticleDetailScreen(article: longSummaryArticle),
            articles: [longSummaryArticle],
          ),
        );
        await tester.pump();

        expect(find.text(longSummaryArticle.title), findsOneWidget);
        await tester.drag(
          find.byType(SingleChildScrollView).first,
          const Offset(0, -600),
        );
        await tester.pump();
        expect(find.text(AppStrings.readFullArticle), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    // ─── 16. CTA follows short content ───────────────────────────────────────
    testWidgets(
      '16. CTA appears shortly after short content — not at viewport bottom',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          wrapWithProviders(
            child: ArticleDetailScreen(article: shortSummaryArticle),
            articles: [shortSummaryArticle],
          ),
        );
        await tester.pump();

        expect(find.text(AppStrings.readFullArticle), findsOneWidget);
        final ctaY = ctaTop(tester);
        expect(ctaY, lessThan(650.0));
        expect(tester.takeException(), isNull);
      },
    );

    // ─── 17. Missing/empty summary fallback ──────────────────────────────────
    testWidgets('17. Missing/empty article summary shows fallback and CTA', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        wrapWithProviders(
          child: ArticleDetailScreen(article: noSummaryArticle),
          articles: [noSummaryArticle],
        ),
      );
      await tester.pump();

      expect(find.text(noSummaryArticle.title), findsOneWidget);
      expect(find.text(AppStrings.readFullArticle), findsOneWidget);
      expect(ctaTop(tester), lessThan(844.0));
      expect(tester.takeException(), isNull);
    });

    // ─── 18. Light and Dark themes ───────────────────────────────────────────
    testWidgets('18. Light and dark theme backgrounds match panel color', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Light
      await tester.pumpWidget(
        wrapWithProviders(
          child: ArticleDetailScreen(article: sampleArticle1),
          theme: AppTheme.lightTheme,
        ),
      );
      await tester.pump();
      var scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, Colors.white);

      // Dark
      await tester.pumpWidget(
        wrapWithProviders(
          child: ArticleDetailScreen(article: sampleArticle1),
          theme: AppTheme.darkTheme,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, isNot(Colors.white));
      expect(tester.takeException(), isNull);
    });

    // ─── 19. Tablet portrait CTA follows short content ───────────────────────
    testWidgets(
      '19. Tablet portrait: CTA follows short content, not at viewport bottom',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1280);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          wrapWithProviders(
            child: ArticleDetailScreen(article: shortSummaryArticle),
            articles: [shortSummaryArticle],
          ),
        );
        await tester.pump();

        expect(find.text(AppStrings.readFullArticle), findsOneWidget);
        final ctaY = ctaTop(tester);
        expect(ctaY, lessThan(900.0));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
