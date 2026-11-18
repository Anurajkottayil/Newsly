import 'package:flutter_test/flutter_test.dart';
import 'package:newsly/core/constants/app_strings.dart';
import 'package:newsly/main.dart';
import 'package:newsly/models/article_model.dart';
import 'package:newsly/repositories/article_repository.dart';

class MockArticleRepo implements ArticleRepository {
  @override
  Future<PaginatedArticles> getArticles({
    int limit = 10,
    int offset = 0,
    String? search,
  }) async {
    return const PaginatedArticles(
      count: 0,
      next: null,
      previous: null,
      results: [],
    );
  }

  @override
  Future<Article> getArticleById(int id) async {
    throw UnimplementedError();
  }
}

void main() {
  testWidgets('NewslyApp launches DiscoverScreen smoke test', (
    WidgetTester tester,
  ) async {
    // Build NewslyApp with injected mock repository
    await tester.pumpWidget(NewslyApp(articleRepository: MockArticleRepo()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Discover heading and subtitle are present.
    expect(find.text(AppStrings.discover), findsOneWidget);
    expect(find.text(AppStrings.discoverSubtitle), findsOneWidget);

    // Verify search hint is present.
    expect(find.text(AppStrings.searchHintDiscover), findsOneWidget);

    // Verify All category chip is present.
    expect(find.text('All'), findsOneWidget);
  });
}
