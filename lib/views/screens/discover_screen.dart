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
import '../widgets/responsive_layout.dart';

/// Discover / News List screen implementing the exact UI design from the project specification.
///
/// Features:
/// - Dark navy Discover heading and subtitle on a clean white background.
/// - Rounded light-gray search bar with search icon, clear button, and filter icon.
/// - Debounced search querying title and summary via the Spaceflight News API.
/// - Horizontally scrollable category chips with bright blue selected state.
/// - Compact news cards with rounded thumbnail on left, title & metadata on right.
/// - Pull-to-refresh and infinite scroll pagination with loading & retry footers.
/// - Full tablet / iPad responsiveness.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounceTimer;

  // Visual category chips mapped to verified content filters
  final List<String> _categories = const [
    'All',
    'SpaceX',
    'NASA',
    'ESA',
    'SpaceNews',
    'Science',
  ];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = context.read<ArticleViewModel>();
      if (viewModel.articles.isEmpty && !viewModel.isLoading) {
        viewModel.fetchArticles();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Trigger pagination when reaching within 200px of the bottom
    if (currentScroll >= maxScroll - 200) {
      context.read<ArticleViewModel>().loadMore();
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(AppConstants.searchDebounceDuration, () {
      if (!mounted) return;
      final trimmed = query.trim();
      setState(() {
        _selectedCategory = trimmed.isEmpty ? 'All' : '';
      });
      context.read<ArticleViewModel>().fetchArticles(
        search: trimmed,
        refresh: true,
      );
    });
  }

  void _onCategorySelected(String category) {
    if (_selectedCategory == category) return;

    setState(() {
      _selectedCategory = category;
      _searchController.text = category == 'All' ? '' : category;
    });

    _debounceTimer?.cancel();
    final viewModel = context.read<ArticleViewModel>();
    if (category == 'All') {
      viewModel.clearSearch();
    } else {
      viewModel.fetchArticles(search: category, refresh: true);
    }
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _selectedCategory = 'All';
    });
    context.read<ArticleViewModel>().clearSearch();
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
          maxWidth: 760, // Optimal reading container for tablets/iPads
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

              // 4. Horizontal Category Chips
              _buildCategoryChips(context, isDark),

              const SizedBox(height: AppDimensions.space12),

              // 5. News List / State Views
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
      child: Container(
        height: 48,
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
                onPressed: _clearSearch,
              ),
            Padding(
              padding: const EdgeInsets.only(right: AppDimensions.space16),
              child: Icon(Icons.tune_rounded, color: iconColor, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips(BuildContext context, bool isDark) {
    return SizedBox(
      height: 38,
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

          return GestureDetector(
            onTap: () => _onCategorySelected(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space16,
                vertical: AppDimensions.space8,
              ),
              decoration: BoxDecoration(
                color: isSelected ? selectedBg : unselectedBg,
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              alignment: Alignment.center,
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : unselectedText,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
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

    // 4. Loaded Articles List
    return RefreshIndicator(
      onRefresh: () => viewModel.fetchArticles(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space20,
          vertical: AppDimensions.space8,
        ),
        // Item count includes articles plus pagination footer if applicable
        itemCount:
            viewModel.articles.length +
            (viewModel.isLoadingMore || viewModel.paginationError != null
                ? 1
                : 0),
        itemBuilder: (context, index) {
          // Pagination footer
          if (index == viewModel.articles.length) {
            if (viewModel.paginationError != null) {
              return _buildPaginationErrorFooter(viewModel, isDark);
            }
            return _buildPaginationLoadingFooter(isDark);
          }

          final article = viewModel.articles[index];
          return ArticleCard.fromArticle(
            article: article,
            onTap: () {
              // Reserved for Phase 4: Article Detail Navigation
            },
          );
        },
      ),
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

  Widget _buildPaginationErrorFooter(ArticleViewModel viewModel, bool isDark) {
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
