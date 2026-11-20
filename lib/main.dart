import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_strings.dart';
import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'repositories/article_repository.dart';
import 'repositories/blog_repository.dart';
import 'repositories/bookmark_repository.dart';
import 'viewmodels/article_view_model.dart';
import 'viewmodels/blog_view_model.dart';
import 'viewmodels/bookmark_view_model.dart';
import 'views/screens/discover_screen.dart';
import 'views/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Warm up the splash icon immediately so it is decoded before or on the first frame
  const AssetImage('assets/branding/newsly_splash_icon.png')
      .resolve(ImageConfiguration.empty);
  runApp(const NewslyApp());
}

/// Root widget of the Newsly Application.
///
/// Sets up Dependency Injection via MultiProvider, initializes repositories and ViewModels,
/// and applies centralized light & dark theme configurations.
class NewslyApp extends StatefulWidget {
  final ApiClient? apiClient;
  final ArticleRepository? articleRepository;
  final BlogRepository? blogRepository;
  final BookmarkRepository? bookmarkRepository;
  final bool showSplash;
  final Duration splashDuration;

  const NewslyApp({
    super.key,
    this.apiClient,
    this.articleRepository,
    this.blogRepository,
    this.bookmarkRepository,
    this.showSplash = true,
    this.splashDuration = const Duration(seconds: 3),
  });

  @override
  State<NewslyApp> createState() => _NewslyAppState();
}

class _NewslyAppState extends State<NewslyApp> {
  final ValueNotifier<ThemeMode> _themeModeNotifier = ValueNotifier<ThemeMode>(
    ThemeMode.system,
  );

  @override
  void dispose() {
    _themeModeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core Network Client
        Provider<ApiClient>(create: (_) => widget.apiClient ?? ApiClient()),

        // Repositories
        ProxyProvider<ApiClient, ArticleRepository>(
          update: (_, apiClient, _) =>
              widget.articleRepository ??
              ArticleRepositoryImpl(apiClient: apiClient),
        ),
        ProxyProvider<ApiClient, BlogRepository>(
          update: (_, apiClient, _) =>
              widget.blogRepository ?? BlogRepositoryImpl(apiClient: apiClient),
        ),
        Provider<BookmarkRepository>(
          create: (_) =>
              widget.bookmarkRepository ?? BookmarkRepositoryImpl(),
        ),

        // ViewModels
        ChangeNotifierProxyProvider<ArticleRepository, ArticleViewModel>(
          create: (context) =>
              ArticleViewModel(context.read<ArticleRepository>()),
          update: (_, repository, previous) =>
              previous ?? ArticleViewModel(repository),
        ),
        ChangeNotifierProxyProvider<BlogRepository, BlogViewModel>(
          create: (context) => BlogViewModel(context.read<BlogRepository>()),
          update: (_, repository, previous) =>
              previous ?? BlogViewModel(repository),
        ),
        ChangeNotifierProxyProvider<BookmarkRepository, BookmarkViewModel>(
          create: (context) =>
              BookmarkViewModel(context.read<BookmarkRepository>()),
          update: (_, repository, previous) =>
              previous ?? BookmarkViewModel(repository),
        ),
      ],
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: _themeModeNotifier,
        builder: (context, themeMode, _) {
          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: widget.showSplash
                ? SplashScreen(duration: widget.splashDuration)
                : const DiscoverScreen(),
          );
        },
      ),
    );
  }
}
