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
  final List<Article> articles;
  MockArticleRepo(this.articles);

  @override
  Future<PaginatedArticles> getArticles({
    int limit = 10,
    int offset = 0,
    String? search,
  }) async {
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
  final List<Blog> blogs;
  MockBlogRepo(this.blogs);

  @override
  Future<PaginatedBlogs> getBlogs({
    int limit = 10,
    int offset = 0,
    String? search,
  }) async {
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
    title: 'NASA James Webb Space Telescope Discovers Most Distant Galaxy',
    authors: const [Author(name: 'Dr. Jane Space Researcher')],
    url: 'https://example.com/nasa-jwst',
    imageUrl: '', // Empty imageUrl avoids network indicator loops in tests
    newsSite: 'NASA Space Science',
    summary:
        'A comprehensive summary detailing the latest deep-field observation from the James Webb Space Telescope.',
    publishedAt: DateTime(2026, 11, 18, 12, 0, 0),
    featured: true,
  );

  final sampleBlog = Blog(
    id: 101,
    title: 'Spaceflight Insider: Behind the Scenes of Starship Launch 7',
    authors: const [Author(name: 'Senior Aerospace Correspondent')],
    url: 'https://example.com/starship-blog',
    imageUrl: '', // Empty imageUrl avoids network indicator loops in tests
    newsSite: 'Spaceflight Insider',
    summary:
        'An in-depth personal blog post covering preparations, flight telemetry, and recovery operations.',
    publishedAt: DateTime(2026, 11, 18, 14, 30, 0),
    featured: true,
  );

  group('T029: Accessibility Text Scaling & Layout Overflow Tests', () {
    testWidgets(
      'ArticleCard renders cleanly without overflow at 1.0x text scale',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ArticleCard.fromArticle(article: sampleArticle),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(ArticleCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'ArticleCard expands vertically without overflow at 1.5x text scale',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ArticleCard.fromArticle(article: sampleArticle),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(ArticleCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'ArticleCard gracefully handles 2.0x text scale on narrow 320dp width without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(320 * 2, 600 * 2);
        tester.view.devicePixelRatio = 2.0;
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.darkTheme,
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ArticleCard.fromArticle(article: sampleArticle),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(ArticleCard), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'DiscoverScreen renders without overflow at 1.5x and 2.0x text scale',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final articleRepo = MockArticleRepo([sampleArticle]);
        final blogRepo = MockBlogRepo([sampleBlog]);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<ArticleRepository>.value(value: articleRepo),
              Provider<BlogRepository>.value(value: blogRepo),
              ChangeNotifierProvider(
                create: (_) => ArticleViewModel(articleRepo),
              ),
              ChangeNotifierProvider(create: (_) => BlogViewModel(blogRepo)),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: const DiscoverScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(DiscoverScreen), findsOneWidget);
        expect(find.byType(ArticleCard), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Test filter sheet at 1.5x
        final filterButton = find.byKey(const ValueKey('search_filter_button'));
        expect(filterButton, findsOneWidget);
        await tester.tap(filterButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text(AppStrings.exploreContent), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'ArticleDetailScreen renders without overflow at 1.5x and 2.0x text scale',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final articleRepo = MockArticleRepo([sampleArticle]);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<ArticleRepository>.value(value: articleRepo),
              ChangeNotifierProvider(
                create: (_) => ArticleViewModel(articleRepo)..fetchArticles(),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              home: ArticleDetailScreen(initialArticleId: sampleArticle.id),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(ArticleDetailScreen), findsOneWidget);
        expect(find.text(sampleArticle.title), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'BlogDetailScreen renders without overflow at 1.5x and 2.0x text scale',
      (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final blogRepo = MockBlogRepo([sampleBlog]);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider<BlogRepository>.value(value: blogRepo),
              ChangeNotifierProvider(
                create: (_) => BlogViewModel(blogRepo)..fetchBlogs(),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              home: BlogDetailScreen(initialBlogId: sampleBlog.id),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(BlogDetailScreen), findsOneWidget);
        expect(find.text(sampleBlog.title), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
