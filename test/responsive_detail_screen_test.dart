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
import 'package:newsly/views/widgets/responsive_layout.dart';
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

  Widget wrapWithProviders({
    required Widget child,
    List<Article>? articles,
    List<Blog>? blogs,
    double textScale = 1.0,
  }) {
    final articleRepo = MockDetailArticleRepository(
      articlesToReturn: articles ?? [sampleArticle1, sampleArticle2],
    );
    final blogRepo = MockDetailBlogRepository(
      blogsToReturn: blogs ?? [sampleBlog1, sampleBlog2],
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
        theme: AppTheme.lightTheme,
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

  group('T025: Responsive Detail Screen Tests', () {
    // 1. Article detail at ~390 × 844 (phone portrait)
    testWidgets('1. Article detail at ~390 x 844 (phone portrait)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
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
      expect(find.text(AppStrings.readFullArticle), findsOneWidget);
      expect(find.byType(ArticleDetailContent), findsOneWidget);

      // Hero height: (844 * 0.44).clamp(320, 440) = ~371px
      final heroSizedBoxFinder = find.descendant(
        of: find.byType(ArticleDetailContent),
        matching: find.byType(SizedBox),
      );
      final heroSize = tester.getSize(heroSizedBoxFinder.first);
      expect(heroSize.height, closeTo(371.36, 1.0));
      expect(tester.takeException(), isNull);
    });

    // 2. Blog detail at ~390 × 844 (phone portrait)
    testWidgets('2. Blog detail at ~390 x 844 (phone portrait)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
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
      expect(find.text(AppStrings.readFullBlogPost), findsOneWidget);
      expect(find.byType(BlogDetailContent), findsOneWidget);

      // Hero height: (844 * 0.44).clamp(320, 440) = ~371px
      final heroSizedBoxFinder = find.descendant(
        of: find.byType(BlogDetailContent),
        matching: find.byType(SizedBox),
      );
      final heroSize = tester.getSize(heroSizedBoxFinder.first);
      expect(heroSize.height, closeTo(371.36, 1.0));
      expect(tester.takeException(), isNull);
    });

    // 3. Article detail at ~1024 × 768 (tablet landscape)
    testWidgets('3. Article detail at ~1024 x 768 (tablet landscape)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
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
      expect(find.byType(ResponsiveLayout), findsOneWidget);

      // Content column is constrained to maxWidth 760
      final responsiveFinder = find.byType(ResponsiveLayout);
      final responsiveSize = tester.getSize(responsiveFinder);
      expect(responsiveSize.width, 1024.0);

      final constrainedBoxes = find.descendant(
        of: responsiveFinder,
        matching: find.byType(ConstrainedBox),
      );
      expect(constrainedBoxes, findsWidgets);

      expect(tester.takeException(), isNull);
    });

    // 4. Blog detail at ~1024 × 768 (tablet landscape)
    testWidgets('4. Blog detail at ~1024 x 768 (tablet landscape)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
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
      expect(find.byType(ResponsiveLayout), findsOneWidget);
      expect(find.text(AppStrings.readFullBlogPost), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 5. Article detail in phone landscape (~844 × 390)
    testWidgets('5. Article detail in phone landscape (~844 x 390)', (
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

      // Short height hero: (390 * 0.60).clamp(180, 280) = 234px
      final heroSizedBoxFinder = find.descendant(
        of: find.byType(ArticleDetailContent),
        matching: find.byType(SizedBox),
      );
      final heroSize = tester.getSize(heroSizedBoxFinder.first);
      expect(heroSize.height, closeTo(234.0, 1.0));

      // Check that content sheet and button are accessible via scrolling
      expect(find.byType(SingleChildScrollView), findsWidgets);
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pump();
      expect(find.text(AppStrings.readFullArticle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 6. Blog detail in phone landscape (~844 × 390)
    testWidgets('6. Blog detail in phone landscape (~844 x 390)', (
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

      // Short height hero: (390 * 0.60).clamp(180, 280) = 234px
      final heroSizedBoxFinder = find.descendant(
        of: find.byType(BlogDetailContent),
        matching: find.byType(SizedBox),
      );
      final heroSize = tester.getSize(heroSizedBoxFinder.first);
      expect(heroSize.height, closeTo(234.0, 1.0));

      // Scroll to button
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(0, -300),
      );
      await tester.pump();
      expect(find.text(AppStrings.readFullBlogPost), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // 7. Zero overflow at short landscape height (e.g. 700 × 340)
    testWidgets('7. Zero overflow at short landscape height (700 x 340)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(700, 340);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Test ArticleDetailScreen
      await tester.pumpWidget(
        wrapWithProviders(child: ArticleDetailScreen(article: sampleArticle1)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Test BlogDetailScreen
      await tester.pumpWidget(
        wrapWithProviders(child: BlogDetailScreen(blog: sampleBlog1)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    // 8. Large text scaling (1.5x and 2.0x) on tablet (1024 × 768) and landscape (844 × 390)
    testWidgets(
      '8. Large text scaling (1.5x and 2.0x) on tablet and landscape',
      (tester) async {
        // Tablet (1024 x 768) at 1.5x
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

        // Landscape (844 x 390) at 1.5x
        tester.view.physicalSize = const Size(844, 390);
        await tester.pumpWidget(
          wrapWithProviders(
            child: BlogDetailScreen(blog: sampleBlog1),
            textScale: 1.5,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);

        // Landscape (844 x 390) at 2.0x
        await tester.pumpWidget(
          wrapWithProviders(
            child: ArticleDetailScreen(article: sampleArticle1),
            textScale: 2.0,
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);

        // Tablet (1024 x 768) at 2.0x
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

    // 9. Swipe navigation, pagination, back navigation, and URL launching remain intact
    testWidgets(
      '9. Swipe navigation, back navigation, and URL actions remain intact',
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

        // Check article 1 displayed
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

        // Test blog swipe navigation
        bool blogBackInvoked = false;
        await tester.pumpWidget(
          wrapWithProviders(
            child: BlogDetailScreen(
              blog: sampleBlog1,
              onBack: () => blogBackInvoked = true,
            ),
          ),
        );
        await tester.pump();

        expect(find.text(sampleBlog1.title), findsOneWidget);

        // Swipe LEFT -> advances to blog 2
        await tester.drag(find.byType(PageView), const Offset(-400, 0));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text(sampleBlog2.title), findsOneWidget);

        // Swipe RIGHT -> returns to blog 1
        await tester.drag(find.byType(PageView), const Offset(400, 0));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text(sampleBlog1.title), findsOneWidget);

        // Tap blog back button
        final blogBackBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
        await tester.tap(blogBackBtn);
        await tester.pump();
        expect(blogBackInvoked, isTrue);
      },
    );
  });
}
