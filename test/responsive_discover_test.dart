import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newsly/core/constants/app_strings.dart';
import 'package:newsly/core/theme/app_theme.dart';
import 'package:newsly/models/article_model.dart';
import 'package:newsly/models/blog_model.dart';
import 'package:newsly/repositories/article_repository.dart';
import 'package:newsly/repositories/blog_repository.dart';
import 'package:newsly/shared/widgets/article_card.dart';
import 'package:newsly/viewmodels/article_view_model.dart';
import 'package:newsly/viewmodels/blog_view_model.dart';
import 'package:newsly/views/screens/article_detail_screen.dart';
import 'package:newsly/views/screens/blog_detail_screen.dart';
import 'package:newsly/views/screens/discover_screen.dart';
import 'package:provider/provider.dart';

class MockArticleRepo implements ArticleRepository {
  List<Article> articles;
  String? lastSearch;
  int callCount = 0;

  MockArticleRepo(this.articles);

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

class MockBlogRepo implements BlogRepository {
  List<Blog> blogs;
  String? lastSearch;
  int callCount = 0;

  MockBlogRepo(this.blogs);

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

Widget createTestApp({
  required ArticleRepository articleRepo,
  required BlogRepository blogRepo,
}) {
  return MultiProvider(
    providers: [
      Provider<ArticleRepository>.value(value: articleRepo),
      Provider<BlogRepository>.value(value: blogRepo),
      ChangeNotifierProvider(create: (_) => ArticleViewModel(articleRepo)),
      ChangeNotifierProvider(create: (_) => BlogViewModel(blogRepo)),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const DiscoverScreen(),
    ),
  );
}

void main() {
  final testArticles = [
    Article(
      id: 1,
      title: 'Article One: Artemis Moon Mission Scheduled',
      authors: const [Author(name: 'Reporter Alpha')],
      url: 'https://example.com/artemis',
      imageUrl: '',
      newsSite: 'NASA Spaceflight',
      summary: 'Summary of Artemis Moon Mission details.',
      publishedAt: DateTime(2026, 11, 18),
    ),
    Article(
      id: 2,
      title: 'Article Two: Starship Orbital Flight Preparation',
      authors: const [Author(name: 'Reporter Beta')],
      url: 'https://example.com/starship',
      imageUrl: '',
      newsSite: 'SpaceNews',
      summary: 'Summary of Starship orbital flight preparation.',
      publishedAt: DateTime(2026, 11, 17),
    ),
    Article(
      id: 3,
      title: 'Article Three: James Webb Discovers New Exoplanet',
      authors: const [Author(name: 'Reporter Gamma')],
      url: 'https://example.com/jwst',
      imageUrl: '',
      newsSite: 'Astronomy Now',
      summary: 'Summary of latest JWST exoplanet observation.',
      publishedAt: DateTime(2026, 11, 16),
    ),
    Article(
      id: 4,
      title: 'Article Four: European Space Agency Satellite Launch',
      authors: const [Author(name: 'Reporter Delta')],
      url: 'https://example.com/esa',
      imageUrl: '',
      newsSite: 'ESA Portal',
      summary: 'Summary of ESA satellite deployment in orbit.',
      publishedAt: DateTime(2026, 11, 15),
    ),
  ];

  final testBlogs = [
    Blog(
      id: 101,
      title: 'Blog One: Deep Space Exploration Perspectives',
      authors: const [Author(name: 'Blogger Alpha')],
      url: 'https://example.com/blog/101',
      imageUrl: '',
      newsSite: 'Planetary Society',
      summary: 'Personal thoughts on deep space voyages.',
      publishedAt: DateTime(2026, 11, 18),
    ),
    Blog(
      id: 102,
      title: 'Blog Two: Engineering the Next Generation Rover',
      authors: const [Author(name: 'Blogger Beta')],
      url: 'https://example.com/blog/102',
      imageUrl: '',
      newsSite: 'JPL Blog',
      summary: 'Robotics insights from rover engineers.',
      publishedAt: DateTime(2026, 11, 17),
    ),
  ];

  group('T024: Responsive Discover Screen Tests', () {
    testWidgets(
      '1. Phone width (390 logical pixels): renders single-column layout',
      (tester) async {
        tester.view.physicalSize = const Size(390 * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final articleRepo = MockArticleRepo(testArticles);
        final blogRepo = MockBlogRepo(testBlogs);

        await tester.pumpWidget(
          createTestApp(articleRepo: articleRepo, blogRepo: blogRepo),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final cards = find.byType(ArticleCard);
        expect(cards, findsNWidgets(4));

        final card0Pos = tester.getTopLeft(cards.at(0));
        final card1Pos = tester.getTopLeft(cards.at(1));
        final card2Pos = tester.getTopLeft(cards.at(2));

        // Single-column: all cards have identical horizontal offset (left column)
        expect(card0Pos.dx, equals(card1Pos.dx));
        expect(card1Pos.dx, equals(card2Pos.dx));

        // Cards are positioned vertically one below the other
        expect(card0Pos.dy, lessThan(card1Pos.dy));
        expect(card1Pos.dy, lessThan(card2Pos.dy));

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '2. Small tablet width (700 logical pixels): renders two-column layout',
      (tester) async {
        tester.view.physicalSize = const Size(700 * 2, 900 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final articleRepo = MockArticleRepo(testArticles);
        final blogRepo = MockBlogRepo(testBlogs);

        await tester.pumpWidget(
          createTestApp(articleRepo: articleRepo, blogRepo: blogRepo),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final cards = find.byType(ArticleCard);
        expect(cards, findsNWidgets(4));

        final card0Pos = tester.getTopLeft(cards.at(0));
        final card1Pos = tester.getTopLeft(cards.at(1));
        final card2Pos = tester.getTopLeft(cards.at(2));
        final card3Pos = tester.getTopLeft(cards.at(3));

        // Two-column layout: Row 0 contains Card 0 (left) and Card 1 (right)
        expect(card0Pos.dy, equals(card1Pos.dy));
        expect(card0Pos.dx, lessThan(card1Pos.dx));

        // Row 1 contains Card 2 (left) and Card 3 (right)
        expect(card2Pos.dy, equals(card3Pos.dy));
        expect(card2Pos.dx, lessThan(card3Pos.dx));

        // Row 1 is below Row 0
        expect(card0Pos.dy, lessThan(card2Pos.dy));

        // Left column alignment: Card 0 and Card 2 align vertically
        expect(card0Pos.dx, equals(card2Pos.dx));

        // Right column alignment: Card 1 and Card 3 align vertically
        expect(card1Pos.dx, equals(card3Pos.dx));

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '3. Large tablet width (1024 logical pixels): renders three-column responsive grid',
      (tester) async {
        tester.view.physicalSize = const Size(1024 * 2, 768 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final articleRepo = MockArticleRepo(testArticles);
        final blogRepo = MockBlogRepo(testBlogs);

        await tester.pumpWidget(
          createTestApp(articleRepo: articleRepo, blogRepo: blogRepo),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final cards = find.byType(ArticleCard);
        expect(cards, findsNWidgets(4));

        final card0Pos = tester.getTopLeft(cards.at(0));
        final card1Pos = tester.getTopLeft(cards.at(1));
        final card2Pos = tester.getTopLeft(cards.at(2));
        final card3Pos = tester.getTopLeft(cards.at(3));

        // Three-column layout: Row 0 contains Card 0, Card 1, and Card 2
        expect(card0Pos.dy, equals(card1Pos.dy));
        expect(card1Pos.dy, equals(card2Pos.dy));

        // Columns are placed left-to-right
        expect(card0Pos.dx, lessThan(card1Pos.dx));
        expect(card1Pos.dx, lessThan(card2Pos.dx));

        // Card 3 wraps to Row 1 in column 0
        expect(card3Pos.dy, greaterThan(card0Pos.dy));
        expect(card3Pos.dx, equals(card0Pos.dx));

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('4. Search and filter controls remain usable at tablet width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800 * 2, 900 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final articleRepo = MockArticleRepo(testArticles);
      final blogRepo = MockBlogRepo(testBlogs);

      await tester.pumpWidget(
        createTestApp(articleRepo: articleRepo, blogRepo: blogRepo),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify search input is constrained in width (max 600)
      final searchBar = find.byType(TextField);
      expect(searchBar, findsOneWidget);
      final searchWidth = tester.getSize(searchBar).width;
      expect(searchWidth, lessThanOrEqualTo(600.0));

      // Enter search query
      await tester.enterText(searchBar, 'Artemis');
      await tester.pump(const Duration(milliseconds: 600));

      expect(articleRepo.lastSearch, 'Artemis');

      // Tap category chip
      final spaceXChip = find.text('SpaceX');
      expect(spaceXChip, findsOneWidget);
      await tester.tap(spaceXChip);
      await tester.pump(const Duration(milliseconds: 600));

      expect(articleRepo.lastSearch, 'SpaceX');

      // Open content-type filter bottom sheet
      final filterButton = find.byKey(const ValueKey('search_filter_button'));
      expect(filterButton, findsOneWidget);
      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      // Verify bottom sheet title and options
      expect(find.text(AppStrings.exploreContent), findsOneWidget);
      expect(find.byKey(const ValueKey('filter_option_blogs')), findsOneWidget);

      // Switch to Blogs
      await tester.tap(find.byKey(const ValueKey('filter_option_blogs')));
      await tester.pumpAndSettle();

      // Blogs are rendered in 2 columns
      expect(find.text(testBlogs[0].title), findsOneWidget);
      expect(find.text(testBlogs[1].title), findsOneWidget);

      final blogCards = find.byType(ArticleCard);
      expect(blogCards, findsNWidgets(2));
      final blog0Pos = tester.getTopLeft(blogCards.at(0));
      final blog1Pos = tester.getTopLeft(blogCards.at(1));
      expect(blog0Pos.dy, equals(blog1Pos.dy));
      expect(blog0Pos.dx, lessThan(blog1Pos.dx));

      expect(tester.takeException(), isNull);
    });

    testWidgets('5. Article and Blog card navigation works in tablet grid', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(768 * 2, 1024 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final articleRepo = MockArticleRepo(testArticles);
      final blogRepo = MockBlogRepo(testBlogs);

      await tester.pumpWidget(
        createTestApp(articleRepo: articleRepo, blogRepo: blogRepo),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap the second article card (col 1 in row 0)
      await tester.tap(find.text(testArticles[1].title));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      // ArticleDetailScreen is open with second article
      expect(find.byType(ArticleDetailScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ArticleDetailScreen),
          matching: find.text(testArticles[1].title),
        ),
        findsOneWidget,
      );

      // Tap back to return to Discover
      final backButton = find.descendant(
        of: find.byType(ArticleDetailScreen),
        matching: find.byTooltip(AppStrings.back),
      );
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(ArticleDetailScreen), findsNothing);
      expect(find.byType(DiscoverScreen), findsOneWidget);

      // Switch to Blogs
      await tester.tap(find.byKey(const ValueKey('search_filter_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filter_option_blogs')));
      await tester.pumpAndSettle();

      // Tap the first blog card
      await tester.tap(find.text(testBlogs[0].title));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      // BlogDetailScreen is open with blog
      expect(find.byType(BlogDetailScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BlogDetailScreen),
          matching: find.text(testBlogs[0].title),
        ),
        findsOneWidget,
      );

      // Tap back to return to Discover
      final blogBackButton = find.descendant(
        of: find.byType(BlogDetailScreen),
        matching: find.byTooltip(AppStrings.back),
      );
      expect(blogBackButton, findsOneWidget);
      await tester.tap(blogBackButton);
      await tester.pumpAndSettle();

      expect(find.byType(BlogDetailScreen), findsNothing);
      expect(find.byType(DiscoverScreen), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '6. No horizontal or vertical RenderFlex overflow across various tablet widths',
      (tester) async {
        final widths = [600.0, 768.0, 900.0, 1024.0, 1200.0, 1400.0];

        final articleRepo = MockArticleRepo(testArticles);
        final blogRepo = MockBlogRepo(testBlogs);

        for (final width in widths) {
          tester.view.physicalSize = Size(width * 2, 800 * 2);
          tester.view.devicePixelRatio = 2.0;

          await tester.pumpWidget(
            createTestApp(articleRepo: articleRepo, blogRepo: blogRepo),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          expect(find.byType(DiscoverScreen), findsOneWidget);
          expect(find.byType(ArticleCard), findsNWidgets(4));
          expect(tester.takeException(), isNull);
        }

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );
  });
}
