import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../core/errors/api_exception.dart';
import '../../models/report_model.dart';
import '../../repositories/report_repository.dart';
import '../../services/share_service.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_empty_view.dart';
import '../../shared/widgets/app_error_view.dart';
import '../../shared/widgets/app_loader.dart';
import '../../viewmodels/bookmark_view_model.dart';
import '../../viewmodels/report_view_model.dart';
import '../widgets/detail_more_options_sheet.dart';

/// Report Detail Screen with book-style swipe navigation and pagination.
///
/// Features:
/// 1. Instant cache-first presentation from [ReportViewModel.reports].
/// 2. Standalone presentation and deep-link fetch by ID via [ReportRepository.getReportById].
/// 3. Refresh action that fetches fresh details by ID.
/// 4. Horizontal swipe navigation: Swipe RIGHT (dx > 0) -> Next; Swipe LEFT (dx < 0) -> Previous.
/// 5. Reactive end-of-list pagination with in-flight loader and retryable error state.
class ReportDetailScreen extends StatefulWidget {
  final Report? report;
  final int? initialReportId;
  final int? initialIndex;
  final String? heroTag;
  final VoidCallback? onBack;
  final ShareService? shareService;

  const ReportDetailScreen({
    super.key,
    this.report,
    this.initialReportId,
    this.initialIndex,
    this.heroTag,
    this.onBack,
    this.shareService,
  });

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  int? _currentReportId;
  bool _controllerInitialized = false;
  int? _lastRequestedOffset;
  List<Report>? _lastKnownReports;
  final Set<int> _localBookmarks = <int>{};

  // Direct ID fetch state (when opened without a cached report or list)
  Report? _directFetchedReport;
  bool _isLoadingDirect = false;
  String? _directFetchError;

  @override
  void initState() {
    super.initState();
    if (widget.report == null && widget.initialReportId != null) {
      _isLoadingDirect = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkDirectFetch();
      });
    }
  }

  void _checkDirectFetch() {
    if (!mounted) return;
    ReportViewModel? viewModel;
    try {
      viewModel = Provider.of<ReportViewModel>(context, listen: false);
    } catch (_) {
      viewModel = null;
    }

    if (viewModel != null && viewModel.reports.isNotEmpty) {
      final exists =
          viewModel.reports.any((r) => r.id == widget.initialReportId);
      if (exists) {
        setState(() {
          _isLoadingDirect = false;
        });
        return;
      }
    }

    _fetchReportById(widget.initialReportId!);
  }

  Future<void> _fetchReportById(int id) async {
    setState(() {
      _isLoadingDirect = true;
      _directFetchError = null;
    });

    try {
      final repository =
          Provider.of<ReportRepository>(context, listen: false);
      final report = await repository.getReportById(id);
      if (mounted) {
        setState(() {
          _directFetchedReport = report;
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
    } catch (_) {
      if (mounted) {
        setState(() {
          _directFetchError = AppStrings.genericError;
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
    int totalReports,
    ReportViewModel? viewModel,
  ) {
    if (viewModel == null || !mounted) return;
    if (index >= totalReports - 1 &&
        viewModel.hasMore &&
        !viewModel.isLoadingMore &&
        viewModel.paginationError == null) {
      if (_lastRequestedOffset != totalReports) {
        _lastRequestedOffset = totalReports;
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
    ReportViewModel? viewModel;
    try {
      viewModel = Provider.of<ReportViewModel>(context, listen: true);
    } catch (_) {
      viewModel = null;
    }

    BookmarkViewModel? bookmarkVm;
    try {
      bookmarkVm = Provider.of<BookmarkViewModel>(context, listen: true);
    } catch (_) {
      bookmarkVm = null;
    }

    final reports = (viewModel != null && viewModel.reports.isNotEmpty)
        ? viewModel.reports
        : (widget.report != null
            ? [widget.report!]
            : (_directFetchedReport != null ? [_directFetchedReport!] : <Report>[]));

    if (widget.report == null &&
        (viewModel == null || viewModel.reports.isEmpty) &&
        _directFetchedReport == null) {
      if (_isLoadingDirect) {
        return Scaffold(
          appBar: _buildSimpleAppBar(context),
          body: const Center(
            child: AppLoader(message: AppStrings.loadingDetails),
          ),
        );
      }

      if (_directFetchError != null) {
        return Scaffold(
          appBar: _buildSimpleAppBar(context),
          body: AppErrorView(
            message: _directFetchError!,
            onRetry: () => _fetchReportById(widget.initialReportId!),
          ),
        );
      }
    }

    final bool reportsListChanged =
        _lastKnownReports == null || !listEquals(_lastKnownReports, reports);
    _lastKnownReports = reports;

    if (!_controllerInitialized) {
      int startIndex = 0;
      if (reports.isNotEmpty) {
        if (widget.initialReportId != null) {
          final found =
              reports.indexWhere((r) => r.id == widget.initialReportId);
          if (found != -1) {
            startIndex = found;
          } else if (widget.initialIndex != null) {
            startIndex = widget.initialIndex!.clamp(0, reports.length - 1);
          }
        } else if (widget.initialIndex != null) {
          startIndex = widget.initialIndex!.clamp(0, reports.length - 1);
        }
        _currentReportId = reports[startIndex].id;
      }
      _currentIndex = startIndex;
      _pageController = PageController(initialPage: startIndex);
      _controllerInitialized = true;

      _checkTriggerPagination(startIndex, reports.length, viewModel);
    } else if (reportsListChanged && reports.isNotEmpty) {
      if (_currentReportId != null) {
        final foundIndex =
            reports.indexWhere((r) => r.id == _currentReportId);
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
          final clampedIndex = _currentIndex.clamp(0, reports.length - 1);
          _currentIndex = clampedIndex;
          _currentReportId = reports[clampedIndex].id;
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
        final clampedIndex = _currentIndex.clamp(0, reports.length - 1);
        _currentIndex = clampedIndex;
        _currentReportId = reports[clampedIndex].id;
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

    if (reports.isEmpty) {
      return Scaffold(
        appBar: _buildSimpleAppBar(context),
        body: AppEmptyView(
          title: AppStrings.noReportsTitle,
          message: AppStrings.noReportsSubtitle,
          actionLabel: AppStrings.retry,
          onAction: () => viewModel?.fetchReports(refresh: true),
        ),
      );
    }

    final bool hasPaginationFooter =
        viewModel != null &&
        (viewModel.hasMore ||
            viewModel.isLoadingMore ||
            viewModel.paginationError != null);
    final int itemCount = reports.length + (hasPaginationFooter ? 1 : 0);

    return PageView.builder(
      controller: _pageController,
      reverse: false,
      itemCount: itemCount,
      onPageChanged: (index) {
        setState(() {
          _currentIndex = index;
          if (index < reports.length) {
            _currentReportId = reports[index].id;
          } else {
            _currentReportId = null;
          }
        });
        _checkTriggerPagination(index, reports.length, viewModel);
      },
      itemBuilder: (context, index) {
        final Widget pageChild;
        if (index == reports.length) {
          pageChild = _buildPaginationStatePage(context, viewModel!);
        } else {
          final report = reports[index];
          final heroTag = widget.heroTag != null && index == _currentIndex
              ? widget.heroTag
              : 'report_hero_${report.id}';

          final isBookmarked = bookmarkVm != null
              ? bookmarkVm.isReportBookmarked(report.id)
              : _localBookmarks.contains(report.id);

          pageChild = ReportDetailContent(
            report: report,
            heroTag: heroTag,
            onBack: widget.onBack,
            onRefresh: () => _handleReportRefresh(report.id),
            isBookmarked: isBookmarked,
            shareService: widget.shareService,
            onToggleBookmark: () async {
              if (bookmarkVm != null) {
                return await bookmarkVm.toggleReportBookmark(report.id);
              } else {
                final wasSaved = _localBookmarks.contains(report.id);
                setState(() {
                  if (wasSaved) {
                    _localBookmarks.remove(report.id);
                  } else {
                    _localBookmarks.add(report.id);
                  }
                });
                return !wasSaved;
              }
            },
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

  Future<void> _handleReportRefresh(int reportId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repository =
          Provider.of<ReportRepository>(context, listen: false);
      final updated = await repository.getReportById(reportId);
      if (mounted) {
        setState(() {
          _directFetchedReport = updated;
        });
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Report refreshed'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Could not refresh report'),
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
    ReportViewModel viewModel,
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
                    : const AppLoader(message: AppStrings.loadingReports),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Presentation widget rendering the visual detail layout for Reports.
class ReportDetailContent extends StatelessWidget {
  final Report report;
  final String? heroTag;
  final VoidCallback? onBack;
  final VoidCallback? onRefresh;
  final bool? isBookmarked;
  final Future<bool> Function()? onToggleBookmark;
  final ShareService? shareService;

  const ReportDetailContent({
    super.key,
    required this.report,
    this.heroTag,
    this.onBack,
    this.onRefresh,
    this.isBookmarked,
    this.onToggleBookmark,
    this.shareService,
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
    final dateStr = _formatDate(report.publishedAt);
    final sourceName = report.newsSite.trim().isNotEmpty
        ? report.newsSite.trim()
        : AppStrings.appName;
    return '$sourceName • $dateStr';
  }

  Future<void> _launchReportUrl(BuildContext context) async {
    final url = report.url.trim();
    if (url.isEmpty) {
      _showSnackBar(context, 'No URL available for this report.');
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      _showSnackBar(context, 'Invalid report link.');
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _showSnackBar(context, 'Could not open report link.');
      }
    } catch (_) {
      if (context.mounted) {
        _showSnackBar(context, 'Could not open report link.');
      }
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onBookmarkTapped(
    BuildContext context,
    bool currentSavedState,
    BookmarkViewModel? bookmarkVm,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final bool isNowBookmarked;
    if (onToggleBookmark != null) {
      isNowBookmarked = await onToggleBookmark!();
    } else if (bookmarkVm != null) {
      isNowBookmarked = await bookmarkVm.toggleReportBookmark(report.id);
    } else {
      isNowBookmarked = !currentSavedState;
    }

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          isNowBookmarked
              ? AppStrings.bookmarkSaved
              : AppStrings.bookmarkRemoved,
        ),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onMoreOptionsTapped(BuildContext context) {
    showDetailMoreOptionsSheet(
      context: context,
      title: report.title,
      url: report.url,
      isReport: true,
      onOpenOriginal: () => _launchReportUrl(context),
      shareService: shareService ?? const ShareServiceImpl(),
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    BookmarkViewModel? bookmarkVm;
    try {
      bookmarkVm = Provider.of<BookmarkViewModel>(context, listen: true);
    } catch (_) {
      bookmarkVm = null;
    }
    final effectiveIsBookmarked = bookmarkVm != null
        ? bookmarkVm.isReportBookmarked(report.id)
        : (isBookmarked ?? false);

    final screenWidth = size.width;
    final isTablet = screenWidth >= AppDimensions.tabletBreakpoint;

    final minHeroHeight = isShortHeight
        ? (190.0 * textScale).clamp(180.0, 300.0)
        : isTablet
        ? (380.0 * textScale).clamp(380.0, 600.0)
        : (320.0 * textScale).clamp(320.0, 520.0);
    final maxHeroHeight = isShortHeight
        ? (280.0 * textScale).clamp(240.0, 380.0)
        : isTablet
        ? (560.0 * textScale).clamp(480.0, 680.0)
        : (440.0 * textScale).clamp(440.0, 600.0);
    final targetFraction = isShortHeight ? 0.60 : (isTablet ? 0.48 : 0.44);
    final heroHeight = (screenHeight * targetFraction).clamp(
      minHeroHeight,
      maxHeroHeight,
    );

    final contentMaxWidth = isTablet
        ? (screenWidth > AppDimensions.desktopBreakpoint
              ? AppDimensions.desktopBreakpoint
              : double.infinity)
        : double.infinity;

    final double hPadding;
    if (!isTablet) {
      hPadding = AppDimensions.space20;
    } else if (screenWidth <= 640) {
      hPadding = AppDimensions.space24;
    } else if (screenWidth <= 768) {
      hPadding = AppDimensions.space32;
    } else if (screenWidth <= 896) {
      hPadding = AppDimensions.space40;
    } else {
      final effectiveWidth = screenWidth > AppDimensions.desktopBreakpoint
          ? AppDimensions.desktopBreakpoint
          : screenWidth;
      hPadding = ((effectiveWidth - 760.0) / 2).clamp(
        AppDimensions.space48,
        140.0,
      );
    }

    final panelColor = isDark ? AppColors.surfaceDark : Colors.white;

    return Scaffold(
      backgroundColor: panelColor,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: contentMaxWidth),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Upper Hero Section
                _buildHeroSection(
                  context,
                  heroHeight,
                  isDark,
                  panelColor,
                  effectiveIsBookmarked,
                  bookmarkVm,
                  isShortHeight: isShortHeight,
                  horizontalPadding: hPadding,
                  isTablet: isTablet,
                ),

                // 2. Main Content Panel
                Container(
                  color: panelColor,
                  padding: EdgeInsets.fromLTRB(
                    hPadding,
                    AppDimensions.space8,
                    hPadding,
                    AppDimensions.space20 + bottomInset,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Publisher / Author Row
                      _buildPublisherRow(context, isDark),

                      const SizedBox(height: AppDimensions.space20),

                      // Report Summary
                      _buildSummaryContent(isDark),

                      const SizedBox(height: AppDimensions.space24),

                      // Read Full Report CTA Button
                      AppButton(
                        label: AppStrings.readFullReport,
                        width: double.infinity,
                        height: 50.0,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusMd,
                        ),
                        trailingIcon: const Icon(
                          Icons.open_in_new_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        onPressed: () => _launchReportUrl(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(
    BuildContext context,
    double height,
    bool isDark,
    Color panelColor,
    bool isBookmarked,
    BookmarkViewModel? bookmarkVm, {
    bool isShortHeight = false,
    double horizontalPadding = AppDimensions.space20,
    bool isTablet = false,
  }) {
    final effectiveTag = heroTag ?? 'report_hero_${report.id}';
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final heroCacheWidth =
        (MediaQuery.sizeOf(context).width.clamp(320.0, 1024.0) * dpr)
            .round()
            .clamp(600, 2048);

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
                child: report.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: report.imageUrl,
                        memCacheWidth: heroCacheWidth,
                        maxWidthDiskCache: 2048,
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
                  horizontal: isTablet
                      ? horizontalPadding
                      : AppDimensions.space16,
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
                          icon: isBookmarked
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          iconColor: isBookmarked
                              ? const Color(0xFFFBBF24)
                              : Colors.white,
                          tooltip: AppStrings.bookmarks,
                          iconSize: 18,
                          onPressed: () => _onBookmarkTapped(
                            context,
                            isBookmarked,
                            bookmarkVm,
                          ),
                        ),
                        _buildCircleIconButton(
                          icon: Icons.more_horiz_rounded,
                          tooltip: AppStrings.moreOptions,
                          iconSize: 18,
                          onPressed: () => _onMoreOptionsTapped(context),
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
            left: horizontalPadding,
            right: horizontalPadding,
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
                  report.title.isNotEmpty ? report.title : AppStrings.appName,
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
    final badgeLabel = report.newsSite.trim().isNotEmpty
        ? report.newsSite.trim()
        : AppStrings.reports;

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
        report.authors.isNotEmpty && report.authors.first.name.trim().isNotEmpty
            ? report.authors.first.name.trim()
            : (report.newsSite.trim().isNotEmpty
                ? report.newsSite.trim()
                : AppStrings.appName);

    final avatarInitial = displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : 'R';

    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFF0284C7),
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
    final summaryText = report.summary.trim().isNotEmpty
        ? report.summary.trim()
        : 'No summary available for this report.';

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
    Color iconColor = Colors.white,
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
        child: Icon(icon, size: iconSize, color: iconColor),
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
          Icons.assignment_outlined,
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
