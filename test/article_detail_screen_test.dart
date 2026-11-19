import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newsly/core/constants/app_strings.dart';
import 'package:newsly/core/errors/api_exception.dart';
import 'package:newsly/core/theme/app_theme.dart';
import 'package:newsly/models/article_model.dart';
import 'package:newsly/repositories/article_repository.dart';
import 'package:newsly/shared/widgets/app_button.dart';
import 'package:newsly/shared/widgets/article_card.dart';
import 'package:newsly/viewmodels/article_view_model.dart';
import 'package:newsly/views/screens/article_detail_screen.dart';
import 'package:provider/provider.dart';

class MockDetailArticleRepository implements ArticleRepository {
  List<Article> articlesToReturn;
  String? nextUrl;
  bool shouldThrow;
  int callCount = 0;
  int? lastOffset;
  String? lastSearch;

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
    callCount++;
    lastOffset = offset;
    lastSearch = search;
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

void main() {
  final sampleArticle1 = Article(
    id: 101,
    title: 'Alexander wears modified helmet in road races',
    authors: const [Author(name: 'Test Author')],
    url: 'https://example.com/alexander-helmet',
    imageUrl: 'https://example.com/helmet.jpg',
    newsSite: 'CNN Indonesia',
    summary:
        'As a tech department, we are usually pretty good at spotting tech that is out of the ordinary. During time trials we are used to seeing aero innovation.',
    publishedAt: DateTime(2023, 2, 27, 10, 0),
    featured: true,
  );

  final sampleArticle2 = Article(
    id: 102,
    title: 'Second Article: Falcon Heavy Launch Preps',
    authors: const [Author(name: 'Space Guy')],
    url: 'https://example.com/falcon-heavy',
    imageUrl: 'https://example.com/falcon.jpg',
    newsSite: 'SpaceX',
    summary: 'The Falcon Heavy is undergoing final pad tests.',
    publishedAt: DateTime(2023, 2, 28, 11, 0),
  );

  final sampleArticle3 = Article(
    id: 103,
    title: 'Third Article: Artemis Moon Base Updates',
    authors: const [Author(name: 'NASA Team')],
    url: 'https://example.com/artemis-moon',
    imageUrl: 'https://example.com/moon.jpg',
    newsSite: 'NASA',
    summary: 'NASA announces progress on the Artemis pressurized rover.',
    publishedAt: DateTime(2023, 3, 1, 9, 0),
  );

  Widget createStandaloneWidget({
    required Article article,
    ThemeData? theme,
    VoidCallback? onBack,
  }) {
    return MaterialApp(
      theme: theme ?? AppTheme.lightTheme,
      home: ArticleDetailScreen(article: article, onBack: onBack),
    );
  }

  Widget createPagerWidget({
    required ArticleViewModel viewModel,
    int? initialArticleId,
    int? initialIndex,
    VoidCallback? onBack,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ArticleViewModel>.value(value: viewModel),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: ArticleDetailScreen(
          initialArticleId: initialArticleId,
          initialIndex: initialIndex,
          onBack: onBack,
        ),
      ),
    );
  }

  group('ArticleDetailScreen Standalone UI Tests (Phase 4.2 Compatibility)', () {
    testWidgets('Detail screen renders article title', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createStandaloneWidget(article: sampleArticle1));
      await tester.pump();

      expect(
        find.text('Alexander wears modified helmet in road races'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Source and news site are displayed in hero and content panel without unverified badge',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createStandaloneWidget(article: sampleArticle1),
        );
        await tester.pump();

        expect(find.text('CNN Indonesia'), findsNWidgets(2));
        expect(find.byIcon(Icons.verified_rounded), findsNothing);
      },
    );

    testWidgets('Summary content is displayed with proper typography', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createStandaloneWidget(article: sampleArticle1));
      await tester.pump();

      expect(
        find.textContaining('As a tech department, we are usually pretty good'),
        findsOneWidget,
      );
    });

    testWidgets('Published date and Trending metadata are displayed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createStandaloneWidget(article: sampleArticle1));
      await tester.pump();

      expect(
        find.text('${AppStrings.trending} • Feb 27, 2023'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Null publication date displays Date unavailable fallback on detail screen',
      (WidgetTester tester) async {
        final articleWithNullDate = Article(
          id: 106,
          title: 'Article With Null Date',
          authors: const [Author(name: 'Author')],
          url: 'https://example.com/null-date',
          imageUrl: '',
          newsSite: 'SpaceNews',
          summary: 'Testing null date fallback on detail screen.',
          publishedAt: null,
        );

        await tester.pumpWidget(
          createStandaloneWidget(article: articleWithNullDate),
        );
        await tester.pump();

        expect(
          find.text('SpaceNews • ${AppStrings.dateUnavailable}'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'ArticleCard displays Date unavailable fallback when date is null',
      (WidgetTester tester) async {
        final articleWithNullDate = Article(
          id: 107,
          title: 'ArticleCard With Null Date',
          authors: const [Author(name: 'Author')],
          url: 'https://example.com/null-date-card',
          imageUrl: '',
          newsSite: 'NASA',
          summary: 'Testing ArticleCard null date.',
          publishedAt: null,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ArticleCard.fromArticle(article: articleWithNullDate),
            ),
          ),
        );
        await tester.pump();

        expect(find.text(AppStrings.dateUnavailable), findsOneWidget);
      },
    );

    testWidgets('Missing image is handled gracefully with fallback icon', (
      WidgetTester tester,
    ) async {
      final articleWithoutImage = Article(
        id: 104,
        title: 'Article Without Image',
        authors: const [],
        url: 'https://example.com/no-image',
        imageUrl: '',
        newsSite: 'SpaceX',
        summary: 'Rocket launch succeeded without a preview photo.',
        publishedAt: DateTime(2023, 3, 1),
      );

      await tester.pumpWidget(
        createStandaloneWidget(article: articleWithoutImage),
      );
      await tester.pump();

      expect(find.byIcon(Icons.newspaper_rounded), findsOneWidget);
      expect(find.text('Article Without Image'), findsOneWidget);
    });

    testWidgets(
      'Missing summary or empty source are handled with fallback text',
      (WidgetTester tester) async {
        final articleWithEmptyFields = Article(
          id: 105,
          title: '',
          authors: const [],
          url: '',
          imageUrl: '',
          newsSite: '',
          summary: '',
          publishedAt: DateTime(2023, 4, 1),
        );

        await tester.pumpWidget(
          createStandaloneWidget(article: articleWithEmptyFields),
        );
        await tester.pump();

        expect(find.text(AppStrings.appName), findsOneWidget);
        expect(
          find.text('No summary available for this article.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Read full article AppButton is displayed and accessible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createStandaloneWidget(article: sampleArticle1));
      await tester.pump();

      expect(find.byType(AppButton), findsOneWidget);
      expect(find.text(AppStrings.readFullArticle), findsOneWidget);
    });

    testWidgets('Floating back button invokes onBack callback', (
      WidgetTester tester,
    ) async {
      bool backTapped = false;
      await tester.pumpWidget(
        createStandaloneWidget(
          article: sampleArticle1,
          onBack: () {
            backTapped = true;
          },
        ),
      );
      await tester.pump();

      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pump();

      expect(backTapped, isTrue);
    });

    testWidgets('Renders properly in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        createStandaloneWidget(
          article: sampleArticle1,
          theme: AppTheme.darkTheme,
        ),
      );
      await tester.pump();

      expect(
        find.text('Alexander wears modified helmet in road races'),
        findsOneWidget,
      );
      expect(find.text('CNN Indonesia'), findsNWidgets(2));
      expect(find.text(AppStrings.readFullArticle), findsOneWidget);
    });
  });

  group('ArticleDetailScreen Book-Style Swipe Navigation & Pagination', () {
    testWidgets(
      'Required Gesture Tests: 1->2 (left), 2->3 (left), 3->2 (right), 2->1 (right)',
      (WidgetTester tester) async {
        final mockRepo = MockDetailArticleRepository(
          articlesToReturn: [sampleArticle1, sampleArticle2, sampleArticle3],
        );
        final viewModel = ArticleViewModel(mockRepo);
        await viewModel.fetchArticles();

        await tester.pumpWidget(
          createPagerWidget(viewModel: viewModel, initialIndex: 0),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Start at Article 1
        expect(find.text(sampleArticle1.title), findsOneWidget);
        expect(find.text(sampleArticle2.title), findsNothing);
        expect(find.text(sampleArticle3.title), findsNothing);

        // 1. Start at Article 1, drag from right to left (dx < 0) -> verify Article 2 appears
        await tester.drag(find.byType(PageView), const Offset(-500, 0));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text(sampleArticle2.title), findsOneWidget);

        // 2. From Article 2, drag from right to left (dx < 0) -> verify Article 3 appears
        await tester.drag(find.byType(PageView), const Offset(-500, 0));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text(sampleArticle3.title), findsOneWidget);

        // 3. From Article 3, drag from left to right (dx > 0) -> verify Article 2 appears
        await tester.drag(find.byType(PageView), const Offset(500, 0));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text(sampleArticle2.title), findsOneWidget);

        // 4. From Article 2, drag from left to right (dx > 0) -> verify Article 1 appears
        await tester.drag(find.byType(PageView), const Offset(500, 0));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        expect(find.text(sampleArticle1.title), findsOneWidget);
      },
    );

    testWidgets(
      'Boundary behavior: first article clamps on right swipe, last article clamps on left swipe',
      (WidgetTester tester) async {
        final mockRepo = MockDetailArticleRepository(
          articlesToReturn: [sampleArticle1, sampleArticle2],
        );
        final viewModel = ArticleViewModel(mockRepo);
        await viewModel.fetchArticles();

        await tester.pumpWidget(
          createPagerWidget(viewModel: viewModel, initialIndex: 0),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Start at first article (Article 1)
        expect(find.text(sampleArticle1.title), findsOneWidget);

        // Drag RIGHT (dx > 0) at first article -> Article 1 remains
        await tester.drag(find.byType(PageView), const Offset(400, 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump();

        expect(find.text(sampleArticle1.title), findsOneWidget);

        // Advance to last article (Article 2) via swipe LEFT (dx < 0)
        await tester.drag(find.byType(PageView), const Offset(-400, 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump();

        expect(find.text(sampleArticle2.title), findsOneWidget);

        // Drag LEFT (dx < 0) at last article when hasMore is false -> Article 2 remains
        await tester.drag(find.byType(PageView), const Offset(-400, 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump();

        expect(find.text(sampleArticle2.title), findsOneWidget);
      },
    );

    testWidgets(
      'Index synchronization: preserves current article by ID and handles list changes safely',
      (WidgetTester tester) async {
        final mockRepo = MockDetailArticleRepository(
          articlesToReturn: [sampleArticle1, sampleArticle2, sampleArticle3],
        );
        final viewModel = ArticleViewModel(mockRepo);
        await viewModel.fetchArticles();

        await tester.pumpWidget(
          createPagerWidget(viewModel: viewModel, initialArticleId: 102),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Initially Article 2 is visible
        expect(find.text(sampleArticle2.title), findsOneWidget);

        // Simulate search filter update where Article 2 is moved or remaining
        mockRepo.articlesToReturn = [sampleArticle2, sampleArticle3];
        await viewModel.fetchArticles(search: 'Falcon');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Article 2 should still be displayed because its ID (102) was matched
        expect(find.text(sampleArticle2.title), findsOneWidget);
      },
    );

    testWidgets('Last loaded article triggers pagination when more data exists', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockDetailArticleRepository(
        articlesToReturn: [sampleArticle1, sampleArticle2],
        nextUrl:
            'https://api.spaceflightnewsapi.net/v4/articles/?limit=10&offset=2',
      );
      final viewModel = ArticleViewModel(mockRepo);
      await viewModel.fetchArticles();
      expect(mockRepo.callCount, 1);

      await tester.pumpWidget(
        createPagerWidget(viewModel: viewModel, initialIndex: 0),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Swipe LEFT to reach last loaded article (index 1)
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();

      // Expect pagination loadMore() was triggered automatically
      expect(mockRepo.callCount, 2);
      expect(mockRepo.lastOffset, 2);
    });

    testWidgets('Opening the last loaded article directly triggers pagination', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockDetailArticleRepository(
        articlesToReturn: [sampleArticle1, sampleArticle2],
        nextUrl:
            'https://api.spaceflightnewsapi.net/v4/articles/?limit=10&offset=2',
      );
      final viewModel = ArticleViewModel(mockRepo);
      await viewModel.fetchArticles();
      expect(mockRepo.callCount, 1);

      // Open directly on index 1 (the last loaded article)
      await tester.pumpWidget(
        createPagerWidget(viewModel: viewModel, initialIndex: 1),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text(sampleArticle2.title), findsOneWidget);
      // Proactive pagination is triggered
      expect(mockRepo.callCount, 2);
      expect(mockRepo.lastOffset, 2);
    });

    testWidgets(
      'Pagination failure displays error and retry action in detail pager',
      (WidgetTester tester) async {
        final mockRepo = MockDetailArticleRepository(
          articlesToReturn: [sampleArticle1, sampleArticle2],
          nextUrl:
              'https://api.spaceflightnewsapi.net/v4/articles/?limit=10&offset=2',
        );
        final viewModel = ArticleViewModel(mockRepo);
        await viewModel.fetchArticles();

        // Make subsequent pagination call fail
        mockRepo.shouldThrow = true;

        await tester.pumpWidget(
          createPagerWidget(viewModel: viewModel, initialIndex: 0),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Advance to article 2 via fling LEFT
        await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        // Allow post-frame callback and async repository call to complete
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Now paginationError is set and page 2 (error page) exists in PageView
        // Advance into pagination error page via fling LEFT
        await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));

        // Error view and retry button should be present
        expect(find.text('Pagination network failure'), findsOneWidget);
        expect(find.text(AppStrings.retry), findsOneWidget);

        // Fix mock repository and tap retry
        mockRepo.shouldThrow = false;
        mockRepo.articlesToReturn = [sampleArticle3];

        await tester.tap(find.text(AppStrings.retry));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump(const Duration(seconds: 1));

        // Newly loaded article 3 is now visible!
        expect(find.text(sampleArticle3.title), findsOneWidget);
      },
    );

    testWidgets('Search query remains preserved during pagination', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockDetailArticleRepository(
        articlesToReturn: [sampleArticle1, sampleArticle2],
        nextUrl:
            'https://api.spaceflightnewsapi.net/v4/articles/?limit=10&offset=2&search=NASA',
      );
      final viewModel = ArticleViewModel(mockRepo);
      await viewModel.fetchArticles(search: 'NASA');
      expect(mockRepo.lastSearch, 'NASA');

      await tester.pumpWidget(
        createPagerWidget(viewModel: viewModel, initialIndex: 1),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Pagination should carry the search query
      expect(mockRepo.lastSearch, 'NASA');
    });

    testWidgets('Initial article is selected reliably by unique article ID', (
      WidgetTester tester,
    ) async {
      final mockRepo = MockDetailArticleRepository(
        articlesToReturn: [sampleArticle1, sampleArticle2, sampleArticle3],
      );
      final viewModel = ArticleViewModel(mockRepo);
      await viewModel.fetchArticles();

      // Pass sampleArticle2 ID (102)
      await tester.pumpWidget(
        createPagerWidget(viewModel: viewModel, initialArticleId: 102),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Expect sampleArticle2 is initially presented
      expect(find.text(sampleArticle2.title), findsOneWidget);
    });
  });
}
