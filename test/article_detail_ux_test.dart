import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newsly/core/constants/app_colors.dart';
import 'package:newsly/core/constants/app_strings.dart';
import 'package:newsly/core/theme/app_theme.dart';
import 'package:newsly/models/article_model.dart';
import 'package:newsly/models/blog_model.dart';
import 'package:newsly/repositories/article_repository.dart';
import 'package:newsly/repositories/blog_repository.dart';
import 'package:newsly/repositories/bookmark_repository.dart';
import 'package:newsly/services/share_service.dart';
import 'package:newsly/shared/widgets/app_button.dart';
import 'package:newsly/viewmodels/article_view_model.dart';
import 'package:newsly/viewmodels/blog_view_model.dart';
import 'package:newsly/viewmodels/bookmark_view_model.dart';
import 'package:newsly/views/screens/article_detail_screen.dart';
import 'package:newsly/views/screens/blog_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockShareService implements ShareService {
  String? lastTitle;
  String? lastUrl;
  int shareCallCount = 0;

  @override
  Future<void> share({required String title, required String url}) async {
    lastTitle = title;
    lastUrl = url;
    shareCallCount++;
  }
}

class FakeArticleRepository implements ArticleRepository {
  final List<Article> articles;
  FakeArticleRepository({this.articles = const []});

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

class FakeBlogRepository implements BlogRepository {
  final List<Blog> blogs;
  FakeBlogRepository({this.blogs = const []});

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
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleArticle1 = Article(
    id: 1,
    title: 'NASA Artemis Lunar Test Success',
    authors: const [Author(name: 'Jane Doe')],
    url: 'https://example.com/artemis',
    imageUrl: 'https://example.com/artemis.jpg',
    newsSite: 'NASA',
    summary:
        'NASA has completed critical cryogenic testing for the Space Launch System.',
    publishedAt: DateTime(2026, 11, 19),
    featured: true,
  );

  final sampleArticle2 = Article(
    id: 2,
    title: 'SpaceX Starship Orbital Launch',
    authors: const [Author(name: 'John Smith')],
    url: 'https://example.com/starship',
    imageUrl: 'https://example.com/starship.jpg',
    newsSite: 'SpaceX',
    summary:
        'Starship successfully reached orbit and performed a controlled splashdown.',
    publishedAt: DateTime(2026, 11, 18),
  );

  final sampleBlog1 = Blog(
    id: 1, // Same ID as sampleArticle1 to test ID collision prevention
    title: 'Astronomy Blog: Observing Jupiter Moons',
    authors: const [Author(name: 'Star Gazer')],
    url: 'https://example.com/jupiter-blog',
    imageUrl: 'https://example.com/jupiter.jpg',
    newsSite: 'Astronomy Hub',
    summary:
        'How to observe the four Galilean moons using an entry-level telescope.',
    publishedAt: DateTime(2026, 11, 19),
  );

  Widget buildArticleDetailApp({
    required Article article,
    BookmarkViewModel? bookmarkVm,
    ShareService? shareService,
    ThemeData? theme,
    List<Article>? pagerArticles,
  }) {
    final articleRepo =
        FakeArticleRepository(articles: pagerArticles ?? [article]);
    final articleVm = ArticleViewModel(articleRepo);
    if (pagerArticles != null) {
      articleVm.fetchArticles();
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ArticleViewModel>.value(value: articleVm),
        if (bookmarkVm != null)
          ChangeNotifierProvider<BookmarkViewModel>.value(value: bookmarkVm),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        home: ArticleDetailScreen(
          article: article,
          shareService: shareService,
        ),
      ),
    );
  }

  Widget buildBlogDetailApp({
    required Blog blog,
    BookmarkViewModel? bookmarkVm,
    ShareService? shareService,
    ThemeData? theme,
  }) {
    final blogRepo = FakeBlogRepository(blogs: [blog]);
    final blogVm = BlogViewModel(blogRepo);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BlogViewModel>.value(value: blogVm),
        if (bookmarkVm != null)
          ChangeNotifierProvider<BookmarkViewModel>.value(value: bookmarkVm),
      ],
      child: MaterialApp(
        theme: theme ?? AppTheme.lightTheme,
        home: BlogDetailScreen(
          blog: blog,
          shareService: shareService,
        ),
      ),
    );
  }

  group('Phase 2 — Read Full Article CTA Redesign', () {
    testWidgets('CTA button renders with external-link icon and comfortable touch target', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildArticleDetailApp(article: sampleArticle1),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final ctaFinder = find.widgetWithText(
        AppButton,
        AppStrings.readFullArticle,
      );
      expect(ctaFinder, findsOneWidget);

      final iconFinder = find.descendant(
        of: ctaFinder,
        matching: find.byIcon(Icons.open_in_new_rounded),
      );
      expect(iconFinder, findsOneWidget);

      final size = tester.getSize(ctaFinder);
      expect(size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('Missing or invalid URL displays graceful SnackBar feedback', (
      tester,
    ) async {
      final invalidArticle = Article(
        id: 99,
        title: 'Article With Invalid URL',
        authors: const [],
        url: 'invalid-url-scheme',
        imageUrl: '',
        newsSite: 'NASA',
        summary: 'Testing invalid URL launch.',
        publishedAt: DateTime(2026, 11, 19),
      );

      await tester.pumpWidget(
        buildArticleDetailApp(article: invalidArticle),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text(AppStrings.readFullArticle));
      await tester.pump();

      expect(find.text('Invalid article link.'), findsOneWidget);
    });

    testWidgets('Empty URL displays no URL available SnackBar feedback', (
      tester,
    ) async {
      final emptyUrlArticle = Article(
        id: 98,
        title: 'Article With Empty URL',
        authors: const [],
        url: '',
        imageUrl: '',
        newsSite: 'NASA',
        summary: 'Testing empty URL launch.',
        publishedAt: DateTime(2026, 11, 19),
      );

      await tester.pumpWidget(
        buildArticleDetailApp(article: emptyUrlArticle),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text(AppStrings.readFullArticle));
      await tester.pump();

      expect(find.text('No URL available for this article.'), findsOneWidget);
    });
  });

  group('Phase 3 — Dark Mode & Bottom Safe Area', () {
    testWidgets('Scaffold and content panel use matching surface color in dark mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildArticleDetailApp(
          article: sampleArticle1,
          theme: AppTheme.darkTheme,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, equals(AppColors.surfaceDark));

      final ctaFinder = find.widgetWithText(
        AppButton,
        AppStrings.readFullArticle,
      );
      expect(ctaFinder, findsOneWidget);
    });

    testWidgets('Renders properly in landscape and tablet widths without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildArticleDetailApp(article: sampleArticle1),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(sampleArticle1.title), findsOneWidget);
      expect(find.text(AppStrings.readFullArticle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders at 2.0x text scaling without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: buildArticleDetailApp(article: sampleArticle1),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(sampleArticle1.title), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Phase 4 — Functional Bookmark Feature', () {
    testWidgets('Initial unbookmarked state displays outline icon', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final repo = BookmarkRepositoryImpl();
      await repo.init();
      final bookmarkVm = BookmarkViewModel(repo);

      await tester.pumpWidget(
        buildArticleDetailApp(
          article: sampleArticle1,
          bookmarkVm: bookmarkVm,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_rounded), findsNothing);
    });

    testWidgets('Tapping bookmark saves article and tapping again unsaves it', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final repo = BookmarkRepositoryImpl();
      await repo.init();
      final bookmarkVm = BookmarkViewModel(repo);

      await tester.pumpWidget(
        buildArticleDetailApp(
          article: sampleArticle1,
          bookmarkVm: bookmarkVm,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap to save
      await tester.tap(find.byTooltip(AppStrings.bookmarks));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
      expect(find.text(AppStrings.bookmarkSaved), findsOneWidget);
      expect(bookmarkVm.isArticleBookmarked(sampleArticle1.id), isTrue);

      await tester.pump(const Duration(seconds: 4)); // Clear SnackBar

      // Tap to remove
      await tester.tap(find.byTooltip(AppStrings.bookmarks));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
      expect(find.text(AppStrings.bookmarkRemoved), findsOneWidget);
      expect(bookmarkVm.isArticleBookmarked(sampleArticle1.id), isFalse);
    });

    testWidgets('Article and Blog IDs are stored independently without collision', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final repo = BookmarkRepositoryImpl();
      await repo.init();
      final bookmarkVm = BookmarkViewModel(repo);

      // Save article 1
      await bookmarkVm.toggleArticleBookmark(sampleArticle1.id);

      expect(bookmarkVm.isArticleBookmarked(sampleArticle1.id), isTrue);
      // Blog with same ID 1 must NOT be bookmarked
      expect(bookmarkVm.isBlogBookmarked(sampleBlog1.id), isFalse);

      // Now save Blog 1
      await bookmarkVm.toggleBlogBookmark(sampleBlog1.id);
      expect(bookmarkVm.isBlogBookmarked(sampleBlog1.id), isTrue);
      expect(bookmarkVm.isArticleBookmarked(sampleArticle1.id), isTrue);

      // Unsave article 1
      await bookmarkVm.toggleArticleBookmark(sampleArticle1.id);
      expect(bookmarkVm.isArticleBookmarked(sampleArticle1.id), isFalse);
      expect(bookmarkVm.isBlogBookmarked(sampleBlog1.id), isTrue);
    });

    testWidgets('Article, Blog, and Report bookmark states are completely independent and do not collide', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final repo = BookmarkRepositoryImpl();
      await repo.init();
      final bookmarkVm = BookmarkViewModel(repo);

      const id = 10;
      await bookmarkVm.toggleArticleBookmark(id);
      expect(bookmarkVm.isArticleBookmarked(id), isTrue);
      expect(bookmarkVm.isBlogBookmarked(id), isFalse);
      expect(bookmarkVm.isReportBookmarked(id), isFalse);

      await bookmarkVm.toggleReportBookmark(id);
      expect(bookmarkVm.isArticleBookmarked(id), isTrue);
      expect(bookmarkVm.isBlogBookmarked(id), isFalse);
      expect(bookmarkVm.isReportBookmarked(id), isTrue);

      await bookmarkVm.toggleBlogBookmark(id);
      expect(bookmarkVm.isArticleBookmarked(id), isTrue);
      expect(bookmarkVm.isBlogBookmarked(id), isTrue);
      expect(bookmarkVm.isReportBookmarked(id), isTrue);

      // Verify persistence across restart for all three
      final restartRepo = BookmarkRepositoryImpl();
      await restartRepo.init();
      expect(restartRepo.isArticleBookmarked(id), isTrue);
      expect(restartRepo.isBlogBookmarked(id), isTrue);
      expect(restartRepo.isReportBookmarked(id), isTrue);
      expect(restartRepo.bookmarkedArticleIds, contains(id));
      expect(restartRepo.bookmarkedBlogIds, contains(id));
      expect(restartRepo.bookmarkedReportIds, contains(id));
    });

    testWidgets('Bookmark persistence survives repository re-initialization (app restart)', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final repo1 = BookmarkRepositoryImpl();
      await repo1.init();
      await repo1.toggleArticleBookmark(sampleArticle1.id);
      expect(repo1.isArticleBookmarked(sampleArticle1.id), isTrue);

      // Simulate app restart with a fresh repository instance reading same SharedPreferences
      final repo2 = BookmarkRepositoryImpl();
      await repo2.init();
      expect(repo2.isArticleBookmarked(sampleArticle1.id), isTrue);
      expect(repo2.bookmarkedArticleIds, contains(sampleArticle1.id));
    });

    testWidgets('Swipe navigation preserves distinct bookmark state per article', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final repo = BookmarkRepositoryImpl();
      await repo.init();
      final bookmarkVm = BookmarkViewModel(repo);
      await bookmarkVm.toggleArticleBookmark(sampleArticle1.id);

      final articleRepo = FakeArticleRepository(
        articles: [sampleArticle1, sampleArticle2],
      );
      final articleVm = ArticleViewModel(articleRepo);
      await articleVm.fetchArticles();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ArticleViewModel>.value(value: articleVm),
            ChangeNotifierProvider<BookmarkViewModel>.value(value: bookmarkVm),
          ],
          child: const MaterialApp(
            home: ArticleDetailScreen(initialIndex: 0),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Page 1 (Article 1) is bookmarked
      expect(find.text(sampleArticle1.title), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);

      // Swipe left to Article 2
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Page 2 (Article 2) is unbookmarked
      expect(find.text(sampleArticle2.title), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_rounded), findsNothing);
    });
  });

  group('Phase 5 & 6 — More Options & Blog Detail Consistency', () {
    testWidgets('Three-dot button opens More Options bottom sheet with functional actions', (
      tester,
    ) async {
      final mockShare = MockShareService();
      await tester.pumpWidget(
        buildArticleDetailApp(
          article: sampleArticle1,
          shareService: mockShare,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap three-dot more options button
      await tester.tap(find.byTooltip(AppStrings.moreOptions));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(AppStrings.shareArticle), findsOneWidget);
      expect(find.text(AppStrings.copyLink), findsOneWidget);
      expect(find.text(AppStrings.openOriginalArticle), findsOneWidget);

      // Tap Share
      await tester.tap(find.text(AppStrings.shareArticle));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(mockShare.shareCallCount, 1);
      expect(mockShare.lastTitle, sampleArticle1.title);
      expect(mockShare.lastUrl, sampleArticle1.url);
    });

    testWidgets('Copy link action copies article URL and shows confirmation SnackBar', (
      tester,
    ) async {
      String? copiedData;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            copiedData = (methodCall.arguments as Map)['text'] as String?;
            return null;
          }
          if (methodCall.method == 'Clipboard.getData') {
            return {'text': copiedData};
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      await tester.pumpWidget(
        buildArticleDetailApp(article: sampleArticle1),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byTooltip(AppStrings.moreOptions));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text(AppStrings.copyLink));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(AppStrings.linkCopied), findsOneWidget);
      expect(copiedData, sampleArticle1.url);
    });

    testWidgets('BlogDetailScreen features identical functional CTA, bookmarks, and options', (
      tester,
    ) async {
      final mockShare = MockShareService();
      SharedPreferences.setMockInitialValues({});
      final repo = BookmarkRepositoryImpl();
      await repo.init();
      final bookmarkVm = BookmarkViewModel(repo);

      await tester.pumpWidget(
        buildBlogDetailApp(
          blog: sampleBlog1,
          bookmarkVm: bookmarkVm,
          shareService: mockShare,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Check Blog CTA
      final ctaFinder = find.widgetWithText(
        AppButton,
        AppStrings.readFullBlogPost,
      );
      expect(ctaFinder, findsOneWidget);
      expect(
        find.descendant(
          of: ctaFinder,
          matching: find.byIcon(Icons.open_in_new_rounded),
        ),
        findsOneWidget,
      );

      // Check Blog Bookmark
      expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
      await tester.tap(find.byTooltip(AppStrings.bookmarks));
      await tester.pump();
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
      expect(bookmarkVm.isBlogBookmarked(sampleBlog1.id), isTrue);

      await tester.pump(const Duration(seconds: 4));

      // Check Blog More Options
      await tester.tap(find.byTooltip(AppStrings.moreOptions));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(AppStrings.shareBlog), findsOneWidget);
      expect(find.text(AppStrings.copyLink), findsOneWidget);
      expect(find.text(AppStrings.openOriginalBlog), findsOneWidget);

      await tester.tap(find.text(AppStrings.shareBlog));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(mockShare.shareCallCount, 1);
      expect(mockShare.lastTitle, sampleBlog1.title);
      expect(mockShare.lastUrl, sampleBlog1.url);
    });
  });
}
