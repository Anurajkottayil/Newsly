import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:newsly/core/constants/app_colors.dart';
import 'package:newsly/core/constants/app_strings.dart';
import 'package:newsly/views/screens/discover_screen.dart';
import 'package:newsly/views/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'package:newsly/repositories/article_repository.dart';
import 'package:newsly/models/article_model.dart';
import 'package:newsly/viewmodels/article_view_model.dart';

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
  Widget createSplashScreenApp({
    ThemeMode themeMode = ThemeMode.light,
    Duration duration = const Duration(seconds: 3),
  }) {
    final mockRepo = MockArticleRepo();
    return MultiProvider(
      providers: [
        Provider<ArticleRepository>.value(value: mockRepo),
        ChangeNotifierProvider<ArticleViewModel>(
          create: (_) => ArticleViewModel(mockRepo),
        ),
      ],
      child: MaterialApp(
        themeMode: themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: SplashScreen(duration: duration),
      ),
    );
  }

  group('SplashScreen Widget Tests', () {
    testWidgets('renders splash icon with 100x100 dimensions and correct image asset', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createSplashScreenApp());

      final imageFinder = find.byType(Image);
      expect(imageFinder, findsOneWidget);

      final Image image = tester.widget<Image>(imageFinder);
      expect(image.width, equals(100));
      expect(image.height, equals(100));
      expect(image.fit, equals(BoxFit.contain));

      final AssetImage assetImage = image.image as AssetImage;
      expect(assetImage.assetName, equals('assets/branding/newsly_splash_icon.png'));
    });

    testWidgets('renders pure white background in light theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createSplashScreenApp(themeMode: ThemeMode.light));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(Colors.white));
    });

    testWidgets('renders navy background in dark theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createSplashScreenApp(themeMode: ThemeMode.dark));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, equals(AppColors.backgroundDark));
    });

    testWidgets('holds for 3 seconds and automatically navigates to DiscoverScreen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createSplashScreenApp(duration: const Duration(seconds: 3)),
      );

      // Initially at SplashScreen
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(DiscoverScreen), findsNothing);

      // After 1.5 seconds, still at SplashScreen
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(DiscoverScreen), findsNothing);

      // Pump to trigger navigation after full 3000ms
      await tester.pump(const Duration(milliseconds: 1500));
      // Pump transition animation
      await tester.pumpAndSettle();

      // Successfully transitioned to DiscoverScreen
      expect(find.byType(DiscoverScreen), findsOneWidget);
      expect(find.text(AppStrings.discover), findsOneWidget);
    });
  });
}
