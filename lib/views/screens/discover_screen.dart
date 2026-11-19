import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../shared/widgets/app_empty_view.dart';
import '../../shared/widgets/app_error_view.dart';
import '../../shared/widgets/app_loader.dart';
import '../../shared/widgets/article_card.dart';
import '../../viewmodels/article_view_model.dart';
import '../../viewmodels/blog_view_model.dart';
import '../widgets/responsive_layout.dart';
import 'article_detail_screen.dart';
import 'blog_detail_screen.dart';

enum _ContentType { articles, blogs }

/// Discover / News & Blogs List screen implementing the exact UI design from the project specification.
///
/// Features:
/// - Dark navy Discover heading and subtitle on a clean white background.
/// - Explore content bottom sheet filter for switching between Articles and Blogs.
/// - Rounded light-gray search bar with search icon, clear button, and filter icon.
/// - Debounced search querying title and summary via the Spaceflight News API.
/// - Horizontally scrollable category chips with bright blue selected state.
/// - Compact news cards with rounded thumbnail on left, title & metadata on right.
/// - Pull-to-refresh and infinite scroll pagination with loading & retry footers.
/// - Independent scroll, search, and category state preservation across tabs.
/// - Full tablet / iPad responsiveness.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _articleScrollController = ScrollController();
  final ScrollController _blogScrollController = ScrollController();
  Timer? _debounceTimer;

  _ContentType _contentType = _ContentType.articles;

  // Visual category chips mapped to verified content filters
  final List<String> _categories = const [
    'All',
    'SpaceX',
    'NASA',
    'ESA',
    'SpaceNews',
    'Science',
  ];

  String _articleSelectedCategory = 'All';
  String _blogSelectedCategory = 'All';
  String? _articleSearchQuery;
  String? _blogSearchQuery;

  String get _selectedCategory => _contentType == _ContentType.articles
      ? _articleSelectedCategory
      : _blogSelectedCategory;

  @override
  void initState() {
    super.initState();
    _articleScrollController.addListener(_onArticleScroll);
    _blogScrollController.addListener(_onBlogScroll);

    // Initial load for articles
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final articleVm = Provider.of<ArticleViewModel?>(context, listen: false);
      if (articleVm != null &&
          articleVm.articles.isEmpty &&
          !articleVm.isLoading) {
        articleVm.fetchArticles();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _articleScrollController.dispose();
    _blogScrollController.dispose();
    super.dispose();
  }

  void _onArticleScroll() {
    if (!_articleScrollController.hasClients) return;
    final maxScroll = _articleScrollController.position.maxScrollExtent;
    final currentScroll = _articleScrollController.position.pixels;

    // Trigger pagination when reaching within 200px of the bottom
    if (currentScroll >= maxScroll - 200) {
      final articleVm = Provider.of<ArticleViewModel?>(context, listen: false);
      articleVm?.loadMore();
    }
  }

  void _onBlogScroll() {
    if (!_blogScrollController.hasClients) return;
    final maxScroll = _blogScrollController.position.maxScrollExtent;
    final currentScroll = _blogScrollController.position.pixels;

    // Trigger pagination when reaching within 200px of the bottom
    if (currentScroll >= maxScroll - 200) {
      final blogVm = Provider.of<BlogViewModel?>(context, listen: false);
      blogVm?.loadMore();
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(AppConstants.searchDebounceDuration, () {
      if (!mounted) return;
      final trimmed = query.trim();
      if (_contentType == _ContentType.articles) {
        setState(() {
          _articleSearchQuery = trimmed.isEmpty ? null : trimmed;
          _articleSelectedCategory = trimmed.isEmpty ? 'All' : '';
        });
        final articleVm = Provider.of<ArticleViewModel?>(
          context,
          listen: false,
        );
        articleVm?.fetchArticles(search: trimmed, refresh: true);
      } else {
        setState(() {
          _blogSearchQuery = trimmed.isEmpty ? null : trimmed;
          _blogSelectedCategory = trimmed.isEmpty ? 'All' : '';
        });
        final blogVm = Provider.of<BlogViewModel?>(context, listen: false);
        blogVm?.fetchBlogs(search: trimmed, refresh: true);
      }
    });
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;

    if (_contentType == _ContentType.articles) {
      setState(() {
        _articleSelectedCategory = category;
        _articleSearchQuery = category == 'All' ? null : category;
        _searchController.text = category == 'All' ? '' : category;
      });

      _debounceTimer?.cancel();
      final viewModel = Provider.of<ArticleViewModel?>(context, listen: false);
      if (viewModel != null) {
        if (category == 'All') {
          viewModel.clearSearch();
        } else {
          viewModel.fetchArticles(search: category, refresh: true);
        }
      }
    } else {
      setState(() {
        _blogSelectedCategory = category;
        _blogSearchQuery = category == 'All' ? null : category;
        _searchController.text = category == 'All' ? '' : category;
      });

      _debounceTimer?.cancel();
      final blogVm = Provider.of<BlogViewModel?>(context, listen: false);
      if (blogVm != null) {
        if (category == 'All') {
          blogVm.clearSearch();
        } else {
          blogVm.fetchBlogs(search: category, refresh: true);
        }
      }
    }
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();

    if (_contentType == _ContentType.articles) {
      setState(() {
        _articleSelectedCategory = 'All';
        _articleSearchQuery = null;
      });
      final articleVm = Provider.of<ArticleViewModel?>(context, listen: false);
      articleVm?.clearSearch();
    } else {
      setState(() {
        _blogSelectedCategory = 'All';
        _blogSearchQuery = null;
      });
      final blogVm = Provider.of<BlogViewModel?>(context, listen: false);
      blogVm?.clearSearch();
    }
  }

  void _onContentTypeChanged(_ContentType type) {
    if (_contentType == type) return;

    _debounceTimer?.cancel();
    setState(() {
      _contentType = type;
      if (type == _ContentType.articles) {
        _searchController.text =
            _articleSearchQuery ??
            (_articleSelectedCategory == 'All' ? '' : _articleSelectedCategory);
      } else {
        _searchController.text =
            _blogSearchQuery ??
            (_blogSelectedCategory == 'All' ? '' : _blogSelectedCategory);
      }
    });

    if (type == _ContentType.blogs) {
      final blogVm = Provider.of<BlogViewModel?>(context, listen: false);
      if (blogVm != null && blogVm.blogs.isEmpty && !blogVm.isLoading) {
        blogVm.fetchBlogs();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: ResponsiveLayout(
          maxWidth: AppDimensions.maxContentWidth,
          mobile: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Bar with Back Icon
              _buildTopBar(context, isDark),

              // 2. Discover Title & Subtitle
              _buildHeader(context, isDark),

              const SizedBox(height: AppDimensions.space16),

              // 3. Search Bar
              _buildSearchBar(context, isDark),

              const SizedBox(height: AppDimensions.space16),

              // 5. Horizontal Category Chips
              _buildCategoryChips(context, isDark),

              const SizedBox(height: AppDimensions.space12),

              // 6. News List / State Views
              Expanded(child: _buildBody(context, isDark)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppDimensions.space12,
        top: AppDimensions.space8,
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        tooltip: AppStrings.back,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final titleColor = isDark
        ? AppColors.textPrimaryDark
        : const Color(0xFF0F172A);
    final subtitleColor = isDark
        ? AppColors.textSecondaryDark
        : const Color(0xFF94A3B8);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.discover,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: titleColor,
              letterSpacing: -0.5,
              height: 1.15,
            ),
          ),
          const SizedBox(height: AppDimensions.space4),
          Text(
            AppStrings.discoverSubtitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    final searchBgColor = isDark
        ? AppColors.surfaceVariantDark
        : const Color(0xFFF1F5F9);
    final hintColor = isDark
        ? AppColors.textTertiaryDark
        : const Color(0xFF94A3B8);
    final iconColor = isDark
        ? AppColors.textSecondaryDark
        : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(vertical: AppDimensions.space4),
            decoration: BoxDecoration(
              color: searchBgColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Row(
              children: [
                const SizedBox(width: AppDimensions.space16),
                Icon(Icons.search_rounded, color: hintColor, size: 22),
                const SizedBox(width: AppDimensions.space8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    decoration: InputDecoration(
                      hintText: AppStrings.searchHintDiscover,
                      hintStyle: TextStyle(
                        color: hintColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: hintColor,
                    splashRadius: 18,
                    tooltip: AppStrings.clear,
                    onPressed: _clearSearch,
                  ),
                IconButton(
                  key: const ValueKey('search_filter_button'),
                  icon: const Icon(Icons.tune_rounded, size: 20),
                  color: iconColor,
                  splashRadius: 20,
                  padding: const EdgeInsets.only(right: AppDimensions.space12),
                  tooltip: AppStrings.filter,
                  onPressed: () => _showContentTypeFilterSheet(context, isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showContentTypeFilterSheet(BuildContext context, bool isDark) {
    final sheetBg = isDark ? AppColors.surfaceDark : Colors.white;
    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final activeColor = isDark
        ? AppColors.primaryLight
        : const Color(0xFF2563EB);
    final handleColor = isDark
        ? AppColors.surfaceVariantDark
        : const Color(0xFFE2E8F0);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      builder: (sheetContext) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Material(
              key: const ValueKey('filter_sheet_content'),
              color: sheetBg,
              elevation: 4,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusXl),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.space20,
                      AppDimensions.space12,
                      AppDimensions.space20,
                      AppDimensions.space20,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Drag handle
                        Center(
                          child: Container(
                            width: 36,
                            height: 4,
                            decoration: BoxDecoration(
                              color: handleColor,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusFull,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space16),
                        // Title
                        Text(
                          AppStrings.exploreContent,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: AppDimensions.space16),
                        // Articles option
                        _buildContentTypeOption(
                          context: sheetContext,
                          key: const ValueKey('filter_option_articles'),
                          title: AppStrings.articles,
                          icon: Icons.article_outlined,
                          isSelected: _contentType == _ContentType.articles,
                          activeColor: activeColor,
                          primaryTextColor: primaryTextColor,
                          secondaryTextColor: secondaryTextColor,
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _onContentTypeChanged(_ContentType.articles);
                          },
                        ),
                        const SizedBox(height: AppDimensions.space8),
                        // Blogs option
                        _buildContentTypeOption(
                          context: sheetContext,
                          key: const ValueKey('filter_option_blogs'),
                          title: AppStrings.blogs,
                          icon: Icons.rss_feed_rounded,
                          isSelected: _contentType == _ContentType.blogs,
                          activeColor: activeColor,
                          primaryTextColor: primaryTextColor,
                          secondaryTextColor: secondaryTextColor,
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _onContentTypeChanged(_ContentType.blogs);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildContentTypeOption({
    required BuildContext context,
    required Key key,
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedBg = isDark
        ? activeColor.withValues(alpha: 0.15)
        : activeColor.withValues(alpha: 0.08);

    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: isSelected
              ? Border.all(color: activeColor.withValues(alpha: 0.3), width: 1)
              : Border.all(color: Colors.transparent, width: 1),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? activeColor : secondaryTextColor,
            ),
            const SizedBox(width: AppDimensions.space12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? activeColor : primaryTextColor,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, size: 20, color: activeColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context, bool isDark) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final chipsHeight = (38.0 * textScale).clamp(38.0, 56.0);
    return SizedBox(
      height: chipsHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space20),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppDimensions.space8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          final selectedBg = isDark
              ? AppColors.primaryLight
              : const Color(0xFF2563EB);
          final unselectedBg = isDark
              ? AppColors.surfaceVariantDark
              : const Color(0xFFF1F5F9);
          final unselectedText = isDark
              ? AppColors.textSecondaryDark
              : const Color(0xFF64748B);

          return Semantics(
            button: true,
            selected: isSelected,
            child: Material(
              color: isSelected ? selectedBg : unselectedBg,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _onCategorySelected(category),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                splashColor: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : Colors.black.withValues(alpha: 0.08)),
                highlightColor: isSelected
                    ? Colors.white.withValues(alpha: 0.15)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04)),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space16,
                    vertical: AppDimensions.space8,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected ? Colors.white : unselectedText,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  int _getColumnCount(double width) {
    if (width < AppDimensions.tabletBreakpoint) {
      return 1;
    } else if (width < 900.0) {
      return 2;
    } else {
      return 3;
    }
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    if (_contentType == _ContentType.articles) {
      return _buildArticleBody(context, isDark);
    } else {
      return _buildBlogBody(context, isDark);
    }
  }

  Widget _buildArticleBody(BuildContext context, bool isDark) {
    final viewModel = context.watch<ArticleViewModel>();

    // 1. Initial Loading State
    if (viewModel.isLoading && viewModel.articles.isEmpty) {
      return const AppLoader(message: AppStrings.loadingArticles);
    }

    // 2. Full-Screen Error State
    if (viewModel.hasError && viewModel.articles.isEmpty) {
      return AppErrorView(
        message: viewModel.errorMessage ?? AppStrings.genericError,
        onRetry: () => viewModel.fetchArticles(refresh: true),
      );
    }

    // 3. Empty State (No Articles / No Search Results)
    if (viewModel.isEmpty) {
      final isSearching =
          viewModel.searchQuery != null && viewModel.searchQuery!.isNotEmpty;
      return AppEmptyView(
        title: isSearching
            ? AppStrings.noSearchResultsTitle
            : AppStrings.noArticlesTitle,
        message: isSearching
            ? AppStrings.noSearchResultsSubtitle
            : AppStrings.noArticlesSubtitle,
        actionLabel: AppStrings.retry,
        onAction: _clearSearch,
      );
    }

    // 4. Loaded Articles Feed (Responsive: Single-Column List or Multi-Column Grid)
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _getColumnCount(constraints.maxWidth);
        return RefreshIndicator(
          onRefresh: () => _onRefreshArticles(viewModel),
          child: _buildArticleFeedList(context, viewModel, columns, isDark),
        );
      },
    );
  }

  Widget _buildArticleFeedList(
    BuildContext context,
    ArticleViewModel viewModel,
    int columns,
    bool isDark,
  ) {
    if (columns <= 1) {
      // Single-column phone layout
      return ListView.builder(
        key: const PageStorageKey('articles_feed_list'),
        controller: _articleScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space20,
          vertical: AppDimensions.space8,
        ),
        itemCount:
            viewModel.articles.length +
            (viewModel.isLoadingMore || viewModel.paginationError != null
                ? 1
                : 0),
        itemBuilder: (context, index) {
          if (index == viewModel.articles.length) {
            if (viewModel.paginationError != null) {
              return _buildArticlePaginationErrorFooter(viewModel, isDark);
            }
            return _buildPaginationLoadingFooter(isDark);
          }

          final article = viewModel.articles[index];
          return ArticleCard.fromArticle(
            article: article,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ArticleDetailScreen(
                    initialArticleId: article.id,
                    initialIndex: index,
                  ),
                ),
              );
            },
          );
        },
      );
    }

    // Multi-column tablet/desktop grid layout
    final articles = viewModel.articles;
    final rowCount = (articles.length / columns).ceil();
    final hasFooter =
        viewModel.isLoadingMore || viewModel.paginationError != null;
    final totalCount = rowCount + (hasFooter ? 1 : 0);

    return ListView.builder(
      key: const PageStorageKey('articles_feed_list'),
      controller: _articleScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space20,
        vertical: AppDimensions.space8,
      ),
      itemCount: totalCount,
      itemBuilder: (context, rowIndex) {
        // Full-width pagination footer
        if (rowIndex == rowCount) {
          if (viewModel.paginationError != null) {
            return _buildArticlePaginationErrorFooter(viewModel, isDark);
          }
          return _buildPaginationLoadingFooter(isDark);
        }

        final startIndex = rowIndex * columns;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.space2),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int col = 0; col < columns; col++) ...[
                  if (col > 0) const SizedBox(width: AppDimensions.space16),
                  Expanded(
                    child: (startIndex + col < articles.length)
                        ? Builder(
                            builder: (context) {
                              final itemIndex = startIndex + col;
                              final article = articles[itemIndex];
                              return ArticleCard.fromArticle(
                                article: article,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ArticleDetailScreen(
                                        initialArticleId: article.id,
                                        initialIndex: itemIndex,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBlogBody(BuildContext context, bool isDark) {
    final viewModel = context.watch<BlogViewModel>();

    // 1. Initial Loading State
    if (viewModel.isLoading && viewModel.blogs.isEmpty) {
      return const AppLoader(message: AppStrings.loadingBlogs);
    }

    // 2. Full-Screen Error State
    if (viewModel.hasError && viewModel.blogs.isEmpty) {
      return AppErrorView(
        message: viewModel.errorMessage ?? AppStrings.genericError,
        onRetry: () => viewModel.fetchBlogs(refresh: true),
      );
    }

    // 3. Empty State (No Blogs / No Search Results)
    if (viewModel.isEmpty) {
      final isSearching =
          viewModel.searchQuery != null && viewModel.searchQuery!.isNotEmpty;
      return AppEmptyView(
        title: isSearching
            ? AppStrings.noSearchResultsTitle
            : AppStrings.noBlogsTitle,
        message: isSearching
            ? AppStrings.noSearchResultsSubtitle
            : AppStrings.noBlogsSubtitle,
        actionLabel: AppStrings.retry,
        onAction: _clearSearch,
      );
    }

    // 4. Loaded Blogs Feed (Responsive: Single-Column List or Multi-Column Grid)
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _getColumnCount(constraints.maxWidth);
        return RefreshIndicator(
          onRefresh: () => _onRefreshBlogs(viewModel),
          child: _buildBlogFeedList(context, viewModel, columns, isDark),
        );
      },
    );
  }

  Future<void> _onRefreshArticles(ArticleViewModel viewModel) async {
    await viewModel.fetchArticles(refresh: true);
    if (!mounted) return;
    if (viewModel.errorMessage != null && viewModel.articles.isNotEmpty) {
      _showSnackBar(context, viewModel.errorMessage!);
    }
  }

  Future<void> _onRefreshBlogs(BlogViewModel viewModel) async {
    await viewModel.fetchBlogs(refresh: true);
    if (!mounted) return;
    if (viewModel.errorMessage != null && viewModel.blogs.isNotEmpty) {
      _showSnackBar(context, viewModel.errorMessage!);
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildBlogFeedList(
    BuildContext context,
    BlogViewModel viewModel,
    int columns,
    bool isDark,
  ) {
    if (columns <= 1) {
      // Single-column phone layout
      return ListView.builder(
        key: const PageStorageKey('blogs_feed_list'),
        controller: _blogScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space20,
          vertical: AppDimensions.space8,
        ),
        itemCount:
            viewModel.blogs.length +
            (viewModel.isLoadingMore || viewModel.paginationError != null
                ? 1
                : 0),
        itemBuilder: (context, index) {
          if (index == viewModel.blogs.length) {
            if (viewModel.paginationError != null) {
              return _buildBlogPaginationErrorFooter(viewModel, isDark);
            }
            return _buildPaginationLoadingFooter(isDark);
          }

          final blog = viewModel.blogs[index];
          return ArticleCard.fromBlog(
            blog: blog,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlogDetailScreen(
                    initialBlogId: blog.id,
                    initialIndex: index,
                  ),
                ),
              );
            },
          );
        },
      );
    }

    // Multi-column tablet/desktop grid layout
    final blogs = viewModel.blogs;
    final rowCount = (blogs.length / columns).ceil();
    final hasFooter =
        viewModel.isLoadingMore || viewModel.paginationError != null;
    final totalCount = rowCount + (hasFooter ? 1 : 0);

    return ListView.builder(
      key: const PageStorageKey('blogs_feed_list'),
      controller: _blogScrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space20,
        vertical: AppDimensions.space8,
      ),
      itemCount: totalCount,
      itemBuilder: (context, rowIndex) {
        if (rowIndex == rowCount) {
          if (viewModel.paginationError != null) {
            return _buildBlogPaginationErrorFooter(viewModel, isDark);
          }
          return _buildPaginationLoadingFooter(isDark);
        }

        final startIndex = rowIndex * columns;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppDimensions.space2),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (int col = 0; col < columns; col++) ...[
                  if (col > 0) const SizedBox(width: AppDimensions.space16),
                  Expanded(
                    child: (startIndex + col < blogs.length)
                        ? Builder(
                            builder: (context) {
                              final itemIndex = startIndex + col;
                              final blog = blogs[itemIndex];
                              return ArticleCard.fromBlog(
                                blog: blog,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BlogDetailScreen(
                                        initialBlogId: blog.id,
                                        initialIndex: itemIndex,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaginationLoadingFooter(bool isDark) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppDimensions.space16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildArticlePaginationErrorFooter(
    ArticleViewModel viewModel,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space16),
      child: Column(
        children: [
          Text(
            viewModel.paginationError ?? AppStrings.genericError,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.error),
          ),
          const SizedBox(height: AppDimensions.space8),
          TextButton.icon(
            onPressed: viewModel.retryLoadMore,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text(
              AppStrings.retry,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlogPaginationErrorFooter(BlogViewModel viewModel, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space16),
      child: Column(
        children: [
          Text(
            viewModel.paginationError ?? AppStrings.genericError,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.error),
          ),
          const SizedBox(height: AppDimensions.space8),
          TextButton.icon(
            onPressed: viewModel.retryLoadMore,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text(
              AppStrings.retry,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
