import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../models/article_model.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_empty_view.dart';
import '../../shared/widgets/app_loader.dart';
import '../../viewmodels/article_view_model.dart';
import '../widgets/responsive_layout.dart';

/// Article Detail Screen with Gmail-like swipe navigation and pagination.
///
/// Supports both:
/// 1. Provider-driven swipe navigation across [ArticleViewModel.articles].
/// 2. Standalone direct article presentation (for tests and isolated views).
class ArticleDetailScreen extends StatefulWidget {
  final Article? article;
  final int? initialArticleId;
  final int? initialIndex;
  final String? heroTag;
  final VoidCallback? onBack;

  const ArticleDetailScreen({
    super.key,
    this.article,
    this.initialArticleId,
    this.initialIndex,
    this.heroTag,
    this.onBack,
  });

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  int? _currentArticleId;
  bool _controllerInitialized = false;
  int? _lastRequestedOffset;
  List<Article>? _lastKnownArticles;

  @override
  void dispose() {
    if (_controllerInitialized) {
      _pageController.dispose();
    }
    super.dispose();
  }

  void _checkTriggerPagination(
    int index,
    int totalArticles,
    ArticleViewModel? viewModel,
  ) {
    if (viewModel == null || !mounted) return;
    if (index >= totalArticles - 1 &&
        viewModel.hasMore &&
        !viewModel.isLoadingMore &&
        viewModel.paginationError == null) {
      if (_lastRequestedOffset != totalArticles) {
        _lastRequestedOffset = totalArticles;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && viewModel.hasMore && !viewModel.isLoadingMore) {
            viewModel.loadMore();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ArticleViewModel? viewModel;
    try {
      viewModel = Provider.of<ArticleViewModel>(context, listen: true);
    } catch (_) {
      viewModel = null;
    }

    final articles = viewModel != null
        ? viewModel.articles
        : (widget.article != null ? [widget.article!] : const <Article>[]);

    final bool articlesListChanged =
        _lastKnownArticles == null || !listEquals(_lastKnownArticles, articles);
    _lastKnownArticles = articles;

    if (!_controllerInitialized) {
      int startIndex = 0;
      if (articles.isNotEmpty) {
        if (widget.initialArticleId != null) {
          final found = articles.indexWhere(
            (a) => a.id == widget.initialArticleId,
          );
          if (found != -1) {
            startIndex = found;
          } else if (widget.initialIndex != null) {
            startIndex = widget.initialIndex!.clamp(0, articles.length - 1);
          }
        } else if (widget.initialIndex != null) {
          startIndex = widget.initialIndex!.clamp(0, articles.length - 1);
        }
        _currentArticleId = articles[startIndex].id;
      }
      _currentIndex = startIndex;
      _pageController = PageController(initialPage: startIndex);
      _controllerInitialized = true;

      // Proactively trigger pagination if opening directly on the last loaded article
      _checkTriggerPagination(startIndex, articles.length, viewModel);
    } else if (articlesListChanged && articles.isNotEmpty) {
      // Synchronize index only if the underlying article list was actually updated
      if (_currentArticleId != null) {
        final foundIndex = articles.indexWhere(
          (a) => a.id == _currentArticleId,
        );
        if (foundIndex != -1) {
          if (foundIndex != _currentIndex) {
            _currentIndex = foundIndex;
            if (_pageController.hasClients &&
                _pageController.page?.round() != foundIndex) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _pageController.hasClients) {
                  _pageController.jumpToPage(foundIndex);
                }
              });
            }
          }
        } else {
          // Current article disappeared (e.g. search filter changed or article removed)
          final clampedIndex = _currentIndex.clamp(0, articles.length - 1);
          _currentIndex = clampedIndex;
          _currentArticleId = articles[clampedIndex].id;
          if (_pageController.hasClients &&
              _pageController.page?.round() != clampedIndex) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && _pageController.hasClients) {
                _pageController.jumpToPage(clampedIndex);
              }
            });
          }
        }
      } else {
        // User was waiting at the pagination slot; attach to newly arrived article
        final clampedIndex = _currentIndex.clamp(0, articles.length - 1);
        _currentIndex = clampedIndex;
        _currentArticleId = articles[clampedIndex].id;
        if (_pageController.hasClients &&
            _pageController.page?.round() != clampedIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _pageController.hasClients) {
              _pageController.jumpToPage(clampedIndex);
            }
          });
        }
      }
    }

    // Safe handling for empty article list
    if (articles.isEmpty) {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            tooltip: AppStrings.back,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
            onPressed: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: AppEmptyView(
          title: AppStrings.noArticlesTitle,
          message: AppStrings.noArticlesSubtitle,
          actionLabel: AppStrings.retry,
          onAction: () => viewModel?.fetchArticles(refresh: true),
        ),
      );
    }

    // Determine total pages in pager
    final bool hasPaginationFooter =
        viewModel != null &&
        (viewModel.hasMore ||
            viewModel.isLoadingMore ||
            viewModel.paginationError != null);
    final int itemCount = articles.length + (hasPaginationFooter ? 1 : 0);

    return PageView.builder(
      controller: _pageController,
      reverse: false, // Swipe LEFT -> Next (+1), Swipe RIGHT -> Previous (-1)
      itemCount: itemCount,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
          if (index < articles.length) {
            _currentArticleId = articles[index].id;
          } else {
            _currentArticleId = null;
          }
        });
        _checkTriggerPagination(index, articles.length, viewModel);
      },
      itemBuilder: (context, index) {
        final Widget pageChild;
        // Pagination state page at the end of the loaded list
        if (index == articles.length) {
          pageChild = _buildPaginationStatePage(context, viewModel!);
        } else {
          final article = articles[index];
          final heroTag = widget.heroTag != null && index == _currentIndex
              ? widget.heroTag
              : 'article_hero_${article.id}';

          pageChild = ArticleDetailContent(
            article: article,
            heroTag: heroTag,
            onBack: widget.onBack,
          );
        }

        return _BookPageTransition(
          controller: _pageController,
          index: index,
          child: pageChild,
        );
      },
    );
  }

  Widget _buildPaginationStatePage(
    BuildContext context,
    ArticleViewModel viewModel,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16,
                  vertical: AppDimensions.space8,
                ),
                child: Material(
                  color: Colors.black.withValues(alpha: 0.1),
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                    tooltip: AppStrings.back,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: viewModel.paginationError != null
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(AppDimensions.space24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 48,
                              color: AppColors.error,
                            ),
                            const SizedBox(height: AppDimensions.space16),
                            Text(
                              viewModel.paginationError ??
                                  AppStrings.genericError,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(height: AppDimensions.space20),
                            AppButton(
                              label: AppStrings.retry,
                              onPressed: viewModel.retryLoadMore,
                            ),
                          ],
                        ),
                      )
                    : const AppLoader(message: AppStrings.loadingArticles),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable presentation widget rendering the visual detail layout from Page 3 of the reference specification.
class ArticleDetailContent extends StatelessWidget {
  final Article article;
  final String? heroTag;
  final VoidCallback? onBack;

  const ArticleDetailContent({
    super.key,
    required this.article,
    this.heroTag,
    this.onBack,
  });

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return AppStrings.dateUnavailable;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[dateTime.month - 1];
    return '$month ${dateTime.day}, ${dateTime.year}';
  }

  String _formatMetadata() {
    final dateStr = article.publishedAt != null
        ? _formatDate(article.publishedAt)
        : AppStrings.dateUnavailable;
    if (article.featured) {
      return '${AppStrings.trending} • $dateStr';
    }
    final sourceName = article.newsSite.trim().isNotEmpty
        ? article.newsSite.trim()
        : AppStrings.appName;
    return '$sourceName • $dateStr';
  }

  Future<void> _launchArticleUrl(BuildContext context) async {
    final url = article.url.trim();
    if (url.isEmpty) {
      _showSnackBar(context, 'No URL available for this article.');
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      _showSnackBar(context, 'Invalid article link.');
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _showSnackBar(context, 'Could not open article link.');
      }
    } catch (_) {
      if (context.mounted) {
        _showSnackBar(context, 'Could not open article link.');
      }
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.sizeOf(context);
    final screenHeight = size.height;
    final isShortHeight = screenHeight < 500;
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    final minHeroHeight = isShortHeight
        ? (190.0 * textScale).clamp(180.0, 300.0)
        : (320.0 * textScale).clamp(320.0, 520.0);
    final maxHeroHeight = isShortHeight
        ? (280.0 * textScale).clamp(240.0, 380.0)
        : (440.0 * textScale).clamp(440.0, 600.0);
    final targetFraction = isShortHeight ? 0.60 : 0.44;
    final heroHeight = (screenHeight * targetFraction).clamp(
      minHeroHeight,
      maxHeroHeight,
    );

    final panelColor = isDark ? AppColors.cardDark : Colors.white;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: ResponsiveLayout(
        maxWidth: 760,
        mobile: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Upper Hero Section with Floating Controls & Text Overlay
              _buildHeroSection(
                context,
                heroHeight,
                isDark,
                panelColor,
                isShortHeight: isShortHeight,
              ),

              // 2. Main Content Panel
              Container(
                color: panelColor,
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.space20,
                  AppDimensions.space8,
                  AppDimensions.space20,
                  AppDimensions.space32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Publisher / Source Row
                    _buildPublisherRow(context, isDark),

                    const SizedBox(height: AppDimensions.space20),

                    // Article Summary
                    _buildSummaryContent(isDark),

                    const SizedBox(height: AppDimensions.space32),

                    // Read Full Article Button
                    AppButton(
                      label: AppStrings.readFullArticle,
                      width: double.infinity,
                      onPressed: () => _launchArticleUrl(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    double height,
    bool isDark,
    Color panelColor, {
    bool isShortHeight = false,
  }) {
    final effectiveTag = heroTag ?? 'article_hero_${article.id}';

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Hero Image
          Positioned.fill(
            child: Hero(
              tag: effectiveTag,
              child: SizedBox.expand(
                child: article.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: article.imageUrl,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        placeholder: (context, url) => Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: isDark
                              ? AppColors.shimmerBaseDark
                              : AppColors.shimmerBaseLight,
                          child: const Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            _buildImageFallback(isDark),
                      )
                    : _buildImageFallback(isDark),
              ),
            ),
          ),

          // Gradient Overlay Scrim
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.25),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.25, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // Floating Top Controls (Back, Bookmark, More)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimensions.space16,
                  vertical: isShortHeight
                      ? AppDimensions.space4
                      : AppDimensions.space8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Back button
                    _buildFloatingButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      tooltip: AppStrings.back,
                      onPressed: () {
                        if (onBack != null) {
                          onBack!();
                        } else if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),

                    // Bookmark and More actions
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildFloatingButton(
                          icon: Icons.bookmark_border_rounded,
                          tooltip: AppStrings.bookmarks,
                          onPressed: () {
                            // Visual control per reference specification
                          },
                        ),
                        _buildFloatingButton(
                          icon: Icons.more_horiz_rounded,
                          tooltip: AppStrings.moreOptions,
                          onPressed: () {
                            // Visual control per reference specification
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Article Info on Hero (Category, Title, Metadata)
          Positioned(
            left: AppDimensions.space20,
            right: AppDimensions.space20,
            bottom: isShortHeight
                ? AppDimensions.space16
                : AppDimensions.space24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Category Pill
                _buildCategoryPill(
                  article.newsSite.isNotEmpty ? article.newsSite : 'News',
                  isCompact: isShortHeight,
                ),

                SizedBox(
                  height: isShortHeight
                      ? AppDimensions.space6
                      : AppDimensions.space12,
                ),

                // Large Bold Headline
                Text(
                  article.title.isNotEmpty ? article.title : AppStrings.appName,
                  maxLines: isShortHeight ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isShortHeight ? 18 : 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.25,
                    letterSpacing: -0.4,
                  ),
                ),

                SizedBox(
                  height: isShortHeight
                      ? AppDimensions.space4
                      : AppDimensions.space8,
                ),

                // Metadata (Trending / Source • Date)
                Text(
                  _formatMetadata(),
                  style: TextStyle(
                    fontSize: isShortHeight ? 11 : 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.8),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),

          // Overlapping Rounded Sheet Header
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 20,
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDimensions.radiusXl),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    double iconSize = 18,
  }) {
    return IconButton(
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: iconSize),
      ),
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
    );
  }

  Widget _buildCategoryPill(String category, {bool isCompact = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? AppDimensions.space8 : AppDimensions.space12,
        vertical: isCompact ? AppDimensions.space4 : AppDimensions.space6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF2563EB), // Reference royal blue
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        category,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: isCompact ? 11 : 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildPublisherRow(BuildContext context, bool isDark) {
    final publisherName = article.newsSite.trim().isNotEmpty
        ? article.newsSite.trim()
        : 'Spaceflight News';
    final initial = publisherName.isNotEmpty
        ? publisherName[0].toUpperCase()
        : 'N';

    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;

    return Row(
      children: [
        // Publisher Avatar Badge
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFFDC2626), // CNN red-inspired accent from reference
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        const SizedBox(width: AppDimensions.space12),

        // Publisher Name
        Expanded(
          child: Text(
            publisherName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: primaryTextColor,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryContent(bool isDark) {
    final summaryText = article.summary.trim().isNotEmpty
        ? article.summary.trim()
        : 'No summary available for this article.';

    final textColor = isDark
        ? AppColors.textSecondaryDark
        : const Color(0xFF334155);

    return Text(
      summaryText,
      style: TextStyle(
        fontSize: 15,
        height: 1.65,
        fontWeight: FontWeight.w400,
        color: textColor,
        letterSpacing: -0.1,
      ),
    );
  }

  Widget _buildImageFallback(bool isDark) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: isDark
          ? AppColors.surfaceVariantDark
          : AppColors.surfaceVariantLight,
      child: Center(
        child: Icon(
          Icons.newspaper_rounded,
          size: 64,
          color: isDark
              ? AppColors.textTertiaryDark
              : AppColors.textTertiaryLight,
        ),
      ),
    );
  }
}

/// Book-style page transition providing depth and realistic page-turn physics.
///
/// - The outgoing page slightly scales down, translates with subtle parallax,
///   and is darkened by a soft scrim overlay.
/// - The incoming page glides over top with a soft spine shadow along its left edge.
/// - Hardware-composited with [Transform] and [Stack] over a cached child to maintain 60/120 fps.
class _BookPageTransition extends StatelessWidget {
  final PageController controller;
  final int index;
  final Widget child;

  const _BookPageTransition({
    required this.controller,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, staticChild) {
        double page = index.toDouble();
        if (controller.hasClients && controller.position.haveDimensions) {
          page = controller.page ?? controller.initialPage.toDouble();
        }
        final double delta = page - index;

        // When delta is between 0.001 and 1.0, this page is the outgoing page
        // (moving backward or being covered as the next page turns from the right).
        if (delta > 0.001 && delta <= 1.0) {
          final scale = 1.0 - (0.04 * delta);
          final translationX = delta * 30.0;
          final scrimOpacity = (0.25 * delta).clamp(0.0, 0.25);

          return Transform.translate(
            offset: Offset(translationX, 0),
            child: Transform.scale(
              scale: scale,
              child: Stack(
                children: [
                  staticChild!,
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.black.withValues(alpha: scrimOpacity),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (delta < -0.001 && delta >= -1.0) {
          // When delta is between -1.0 and 0.0, this page is the incoming page
          // (gliding over top from the right as user swipes left).
          // Render a soft book spine shadow along its left edge.
          final shadowOpacity = (-delta * 0.35).clamp(0.0, 0.35);

          return Stack(
            children: [
              staticChild!,
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 24,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: shadowOpacity),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        return staticChild!;
      },
      child: child,
    );
  }
}
