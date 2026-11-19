import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/api_exception.dart';
import '../../models/blog_model.dart';
import '../../repositories/blog_repository.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_empty_view.dart';
import '../../shared/widgets/app_error_view.dart';
import '../../shared/widgets/app_loader.dart';
import '../../viewmodels/blog_view_model.dart';
import '../widgets/responsive_layout.dart';

/// Blog Detail Screen with Gmail-like swipe navigation and pagination.
///
/// Features:
/// 1. Instant cache-first presentation from [BlogViewModel.blogs].
/// 2. Standalone presentation and deep-link fetch by ID via [BlogRepository.getBlogById].
/// 3. Refresh action that fetches fresh details by ID.
/// 4. Horizontal swipe navigation: Swipe RIGHT (dx > 0) -> Next; Swipe LEFT (dx < 0) -> Previous.
/// 5. Reactive end-of-list pagination with in-flight loader and retryable error state.
class BlogDetailScreen extends StatefulWidget {
  final Blog? blog;
  final int? initialBlogId;
  final int? initialIndex;
  final String? heroTag;
  final VoidCallback? onBack;

  const BlogDetailScreen({
    super.key,
    this.blog,
    this.initialBlogId,
    this.initialIndex,
    this.heroTag,
    this.onBack,
  });

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  int? _currentBlogId;
  bool _controllerInitialized = false;
  int? _lastRequestedOffset;
  List<Blog>? _lastKnownBlogs;

  // Direct ID fetch state (when opened without a cached blog or list)
  Blog? _directFetchedBlog;
  bool _isLoadingDirect = false;
  String? _directFetchError;

  @override
  void initState() {
    super.initState();
    // If opened with only an ID and no cached blog passed, check if direct fetch is needed
    if (widget.blog == null && widget.initialBlogId != null) {
      _isLoadingDirect = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkDirectFetch();
      });
    }
  }

  void _checkDirectFetch() {
    if (!mounted) return;
    BlogViewModel? viewModel;
    try {
      viewModel = Provider.of<BlogViewModel>(context, listen: false);
    } catch (_) {
      viewModel = null;
    }

    // If blog is already in ViewModel, no need for initial network call
    if (viewModel != null && viewModel.blogs.isNotEmpty) {
      final exists = viewModel.blogs.any((b) => b.id == widget.initialBlogId);
      if (exists) {
        setState(() {
          _isLoadingDirect = false;
        });
        return;
      }
    }

    _fetchBlogById(widget.initialBlogId!);
  }

  Future<void> _fetchBlogById(int id) async {
    setState(() {
      _isLoadingDirect = true;
      _directFetchError = null;
    });

    try {
      final repository = Provider.of<BlogRepository>(context, listen: false);
      final fetched = await repository.getBlogById(id);
      if (mounted) {
        setState(() {
          _directFetchedBlog = fetched;
          _isLoadingDirect = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _directFetchError = e.message;
          _isLoadingDirect = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _directFetchError = e.toString();
          _isLoadingDirect = false;
        });
      }
    }
  }

  @override
  void dispose() {
    if (_controllerInitialized) {
      _pageController.dispose();
    }
    super.dispose();
  }

  void _checkTriggerPagination(
    int index,
    int totalBlogs,
    BlogViewModel? viewModel,
  ) {
    if (viewModel == null || !mounted) return;
    if (index >= totalBlogs - 1 &&
        viewModel.hasMore &&
        !viewModel.isLoadingMore &&
        viewModel.paginationError == null) {
      if (_lastRequestedOffset != totalBlogs) {
        _lastRequestedOffset = totalBlogs;
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
    BlogViewModel? viewModel;
    try {
      viewModel = Provider.of<BlogViewModel>(context, listen: true);
    } catch (_) {
      viewModel = null;
    }

    final blogs = viewModel != null
        ? viewModel.blogs
        : (widget.blog != null
              ? [widget.blog!]
              : (_directFetchedBlog != null
                    ? [_directFetchedBlog!]
                    : const <Blog>[]));

    // Handle direct fetch states when no blogs are in memory
    if (blogs.isEmpty && widget.initialBlogId != null) {
      if (_isLoadingDirect) {
        return Scaffold(
          appBar: _buildSimpleAppBar(context),
          body: const AppLoader(message: AppStrings.loadingDetails),
        );
      }
      if (_directFetchError != null) {
        return Scaffold(
          appBar: _buildSimpleAppBar(context),
          body: AppErrorView(
            message: _directFetchError!,
            onRetry: () => _fetchBlogById(widget.initialBlogId!),
          ),
        );
      }
    }

    final bool blogsListChanged =
        _lastKnownBlogs == null || !listEquals(_lastKnownBlogs, blogs);
    _lastKnownBlogs = blogs;

    if (!_controllerInitialized) {
      int startIndex = 0;
      if (blogs.isNotEmpty) {
        if (widget.initialBlogId != null) {
          final found = blogs.indexWhere((b) => b.id == widget.initialBlogId);
          if (found != -1) {
            startIndex = found;
          } else if (widget.initialIndex != null) {
            startIndex = widget.initialIndex!.clamp(0, blogs.length - 1);
          }
        } else if (widget.initialIndex != null) {
          startIndex = widget.initialIndex!.clamp(0, blogs.length - 1);
        }
        _currentBlogId = blogs[startIndex].id;
      }
      _currentIndex = startIndex;
      _pageController = PageController(initialPage: startIndex);
      _controllerInitialized = true;

      _checkTriggerPagination(startIndex, blogs.length, viewModel);
    } else if (blogsListChanged && blogs.isNotEmpty) {
      if (_currentBlogId != null) {
        final foundIndex = blogs.indexWhere((b) => b.id == _currentBlogId);
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
          final clampedIndex = _currentIndex.clamp(0, blogs.length - 1);
          _currentIndex = clampedIndex;
          _currentBlogId = blogs[clampedIndex].id;
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
        final clampedIndex = _currentIndex.clamp(0, blogs.length - 1);
        _currentIndex = clampedIndex;
        _currentBlogId = blogs[clampedIndex].id;
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

    if (blogs.isEmpty) {
      return Scaffold(
        appBar: _buildSimpleAppBar(context),
        body: AppEmptyView(
          title: AppStrings.noBlogsTitle,
          message: AppStrings.noBlogsSubtitle,
          actionLabel: AppStrings.retry,
          onAction: () => viewModel?.fetchBlogs(refresh: true),
        ),
      );
    }

    final bool hasPaginationFooter =
        viewModel != null &&
        (viewModel.hasMore ||
            viewModel.isLoadingMore ||
            viewModel.paginationError != null);
    final int itemCount = blogs.length + (hasPaginationFooter ? 1 : 0);

    return PageView.builder(
      controller: _pageController,
      reverse: false, // Swipe LEFT -> Next (+1), Swipe RIGHT -> Previous (-1)
      itemCount: itemCount,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
          if (index < blogs.length) {
            _currentBlogId = blogs[index].id;
          } else {
            _currentBlogId = null;
          }
        });
        _checkTriggerPagination(index, blogs.length, viewModel);
      },
      itemBuilder: (context, index) {
        final Widget pageChild;
        if (index == blogs.length) {
          pageChild = _buildPaginationStatePage(context, viewModel!);
        } else {
          final blog = blogs[index];
          final heroTag = widget.heroTag != null && index == _currentIndex
              ? widget.heroTag
              : 'blog_hero_${blog.id}';

          pageChild = BlogDetailContent(
            blog: blog,
            heroTag: heroTag,
            onBack: widget.onBack,
            onRefresh: () => _handleBlogRefresh(blog.id),
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

  Future<void> _handleBlogRefresh(int blogId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repository = Provider.of<BlogRepository>(context, listen: false);
      final updated = await repository.getBlogById(blogId);
      if (mounted) {
        setState(() {
          _directFetchedBlog = updated;
        });
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Blog post refreshed'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Could not refresh blog post'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  PreferredSizeWidget _buildSimpleAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return AppBar(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        tooltip: AppStrings.back,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        onPressed: () {
          if (widget.onBack != null) {
            widget.onBack!();
          } else if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Widget _buildPaginationStatePage(
    BuildContext context,
    BlogViewModel viewModel,
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
                    : const AppLoader(message: AppStrings.loadingBlogs),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Presentation widget rendering the visual detail layout for Blogs,
/// matching Page 3 of the reference specification.
class BlogDetailContent extends StatelessWidget {
  final Blog blog;
  final String? heroTag;
  final VoidCallback? onBack;
  final VoidCallback? onRefresh;

  const BlogDetailContent({
    super.key,
    required this.blog,
    this.heroTag,
    this.onBack,
    this.onRefresh,
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
    final dateStr = _formatDate(blog.publishedAt);
    if (blog.featured) {
      return '${AppStrings.trending} • $dateStr';
    }
    final sourceName = blog.newsSite.trim().isNotEmpty
        ? blog.newsSite.trim()
        : AppStrings.appName;
    return '$sourceName • $dateStr';
  }

  Future<void> _launchBlogUrl(BuildContext context) async {
    final url = blog.url.trim();
    if (url.isEmpty) {
      _showSnackBar(context, 'No URL available for this blog post.');
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      _showSnackBar(context, 'Invalid blog link.');
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _showSnackBar(context, 'Could not open blog link.');
      }
    } catch (_) {
      if (context.mounted) {
        _showSnackBar(context, 'Could not open blog link.');
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
              // 1. Upper Hero Section
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
                    // Publisher / Author Row
                    _buildPublisherRow(context, isDark),

                    const SizedBox(height: AppDimensions.space20),

                    // Blog Summary
                    _buildSummaryContent(isDark),

                    const SizedBox(height: AppDimensions.space32),

                    // Read Full Blog Post Button
                    AppButton(
                      label: AppStrings.readFullBlogPost,
                      width: double.infinity,
                      onPressed: () => _launchBlogUrl(context),
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
    final effectiveTag = heroTag ?? 'blog_hero_${blog.id}';

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
                child: blog.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: blog.imageUrl,
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

          // Floating Top Controls
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
                    _buildCircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      tooltip: AppStrings.back,
                      iconSize: 18,
                      onPressed: () {
                        if (onBack != null) {
                          onBack!();
                        } else if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (onRefresh != null)
                          _buildCircleIconButton(
                            icon: Icons.refresh_rounded,
                            tooltip: AppStrings.refresh,
                            iconSize: 18,
                            onPressed: onRefresh!,
                          ),
                        _buildCircleIconButton(
                          icon: Icons.bookmark_border_rounded,
                          tooltip: AppStrings.bookmarks,
                          iconSize: 18,
                          onPressed: () {
                            _showSnackBar(context, 'Bookmark saved');
                          },
                        ),
                        _buildCircleIconButton(
                          icon: Icons.more_horiz_rounded,
                          tooltip: AppStrings.moreOptions,
                          iconSize: 18,
                          onPressed: () {
                            _showSnackBar(context, 'Sharing: ${blog.title}');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Content Overlay
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
                _buildCategoryBadge(isCompact: isShortHeight),
                SizedBox(
                  height: isShortHeight
                      ? AppDimensions.space6
                      : AppDimensions.space10,
                ),
                Text(
                  blog.title.isNotEmpty ? blog.title : AppStrings.appName,
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
                      : AppDimensions.space10,
                ),
                Text(
                  _formatMetadata(),
                  style: TextStyle(
                    fontSize: isShortHeight ? 11 : 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),

          // Curved Bottom Sheet Transition Notch
          Positioned(
            left: 0,
            right: 0,
            bottom: -1,
            child: Container(
              height: AppDimensions.radiusXl,
              decoration: BoxDecoration(
                color: panelColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.radiusXl),
                  topRight: Radius.circular(AppDimensions.radiusXl),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge({bool isCompact = false}) {
    final badgeLabel = blog.newsSite.trim().isNotEmpty
        ? blog.newsSite.trim()
        : AppStrings.blogs;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? AppDimensions.space8 : AppDimensions.space12,
        vertical: isCompact ? AppDimensions.space4 : AppDimensions.space6,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        badgeLabel,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildPublisherRow(BuildContext context, bool isDark) {
    final displayName =
        blog.authors.isNotEmpty && blog.authors.first.name.trim().isNotEmpty
        ? blog.authors.first.name.trim()
        : (blog.newsSite.trim().isNotEmpty
              ? blog.newsSite.trim()
              : AppStrings.appName);

    final avatarInitial = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'B';

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFFD32F2F),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            avatarInitial,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.space10),
        Expanded(
          child: Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryContent(bool isDark) {
    final summaryText = blog.summary.trim().isNotEmpty
        ? blog.summary.trim()
        : 'No summary available for this blog post.';

    return Text(
      summaryText,
      style: TextStyle(
        fontSize: 15,
        height: 1.6,
        fontWeight: FontWeight.w400,
        color: isDark ? AppColors.textSecondaryDark : const Color(0xFF334155),
        letterSpacing: -0.1,
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required String tooltip,
    required double iconSize,
    required VoidCallback onPressed,
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
        child: Icon(icon, size: iconSize, color: Colors.white),
      ),
      tooltip: tooltip,
      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
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
