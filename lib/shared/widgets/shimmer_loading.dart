import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

/// Controller scope for synchronizing shimmer animations across multiple skeleton cards.
class _ShimmerScope extends InheritedWidget {
  final Animation<double> animation;
  final bool isDark;
  final Color baseColor;
  final Color highlightColor;
  final bool enabled;

  const _ShimmerScope({
    required this.animation,
    required this.isDark,
    required this.baseColor,
    required this.highlightColor,
    required this.enabled,
    required super.child,
  });

  static _ShimmerScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ShimmerScope>();
  }

  @override
  bool updateShouldNotify(_ShimmerScope oldWidget) {
    return animation != oldWidget.animation ||
        isDark != oldWidget.isDark ||
        baseColor != oldWidget.baseColor ||
        highlightColor != oldWidget.highlightColor ||
        enabled != oldWidget.enabled;
  }
}

/// A lightweight, premium shimmer gradient effect widget.
///
/// Sweeps a smooth, continuous highlight gradient across its child's opaque pixels.
/// Respects accessibility reduced-motion settings ([MediaQueryData.disableAnimations]).
class Shimmer extends StatefulWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;
  final bool enabled;
  final Animation<double>? controller;

  const Shimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
    this.enabled = true,
    this.controller,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  AnimationController? _internalController;

  Animation<double> get _activeAnimation =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = AnimationController(
        vsync: this,
        duration: widget.duration,
      );
      if (widget.enabled) {
        _internalController!.repeat();
      }
    }
  }

  @override
  void didUpdateWidget(Shimmer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == null && _internalController != null) {
      if (widget.enabled != oldWidget.enabled) {
        if (widget.enabled) {
          _internalController!.repeat();
        } else {
          _internalController!.stop();
        }
      }
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = _ShimmerScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final base =
        widget.baseColor ??
        scope?.baseColor ??
        (isDark ? AppColors.shimmerBaseDark : AppColors.shimmerBaseLight);

    final highlight =
        widget.highlightColor ??
        scope?.highlightColor ??
        (isDark
            ? AppColors.shimmerHighlightDark
            : AppColors.shimmerHighlightLight);

    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final isEnabled = widget.enabled && (scope?.enabled ?? true);

    if (!isEnabled || disableAnimations) {
      return widget.child;
    }

    final anim = scope?.animation ?? _activeAnimation;

    return AnimatedBuilder(
      animation: anim,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              colors: [base, highlight, base],
              stops: const [0.1, 0.5, 0.9],
              transform: _SlidingGradientTransform(slidePercent: anim.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double slidePercent;

  const _SlidingGradientTransform({required this.slidePercent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (slidePercent * 2.0 - 1.0),
      0.0,
      0.0,
    );
  }
}

/// A skeleton card widget matching the exact dimensions and layout of [ArticleCard].
///
/// Features:
/// - Rounded rectangular thumbnail placeholder on left (104x104, radius 16).
/// - Category/source placeholder bar.
/// - Two headline placeholder bars.
/// - Author avatar circle, author name, and date placeholders.
class ArticleCardSkeleton extends StatelessWidget {
  const ArticleCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBg = isDark ? AppColors.cardDark : AppColors.surfaceLight;
    // Opaque placeholder block color that will receive the shimmer gradient
    const blockColor = Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space6),
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.space8),
          child: Shimmer(
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Rounded Thumbnail Placeholder
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                    child: Container(
                      width: 104,
                      height: 104,
                      color: blockColor,
                    ),
                  ),
                  const SizedBox(width: AppDimensions.space12),

                  // Right: Content Column
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 104),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Source / Category Placeholder
                          Container(
                            width: 72,
                            height: 12,
                            decoration: BoxDecoration(
                              color: blockColor,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusXs,
                              ),
                            ),
                          ),

                          // Headline Lines Placeholder
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppDimensions.space4,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: blockColor,
                                    borderRadius: BorderRadius.circular(
                                      AppDimensions.radiusXs,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                FractionallySizedBox(
                                  widthFactor: 0.72,
                                  child: Container(
                                    height: 14,
                                    decoration: BoxDecoration(
                                      color: blockColor,
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusXs,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Metadata Row Placeholder (Avatar + Name + Dot + Date)
                          Row(
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  color: blockColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.space6),
                              Container(
                                width: 60,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: blockColor,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusXs,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppDimensions.space6),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: const BoxDecoration(
                                  color: blockColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppDimensions.space6),
                              Container(
                                width: 54,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: blockColor,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusXs,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A responsive, accessible skeleton loading feed for Articles and Blogs.
///
/// Drives all skeleton cards using a single shared [AnimationController].
/// Automatically adapts to single-column phone layout and multi-column tablet grid.
class ShimmerLoadingFeed extends StatefulWidget {
  final int itemCount;
  final String semanticLabel;
  final ScrollController? scrollController;

  const ShimmerLoadingFeed({
    super.key,
    this.itemCount = 6,
    required this.semanticLabel,
    this.scrollController,
  });

  @override
  State<ShimmerLoadingFeed> createState() => _ShimmerLoadingFeedState();
}

class _ShimmerLoadingFeedState extends State<ShimmerLoadingFeed>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sharedController;

  @override
  void initState() {
    super.initState();
    _sharedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _sharedController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark
        ? AppColors.shimmerBaseDark
        : AppColors.shimmerBaseLight;
    final highlightColor = isDark
        ? AppColors.shimmerHighlightDark
        : AppColors.shimmerHighlightLight;

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      liveRegion: true,
      child: Stack(
        children: [
          // Semantic accessibility text anchor (off-screen)
          Positioned(left: -9999, child: Text(widget.semanticLabel)),
          ExcludeSemantics(
            child: _ShimmerScope(
              animation: _sharedController,
              isDark: isDark,
              baseColor: baseColor,
              highlightColor: highlightColor,
              enabled: true,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = _getColumnCount(constraints.maxWidth);

                  if (columns <= 1) {
                    // Single-column phone layout
                    return ListView.builder(
                      key: const ValueKey('shimmer_feed_list'),
                      controller: widget.scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space20,
                        vertical: AppDimensions.space8,
                      ),
                      itemCount: widget.itemCount,
                      itemBuilder: (context, index) =>
                          const ArticleCardSkeleton(),
                    );
                  }

                  // Multi-column tablet/desktop grid layout
                  final rowCount = (widget.itemCount / columns).ceil();
                  return ListView.builder(
                    key: const ValueKey('shimmer_feed_grid'),
                    controller: widget.scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space20,
                      vertical: AppDimensions.space8,
                    ),
                    itemCount: rowCount,
                    itemBuilder: (context, rowIndex) {
                      final startIndex = rowIndex * columns;
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.space2,
                        ),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (int col = 0; col < columns; col++) ...[
                                if (col > 0)
                                  const SizedBox(width: AppDimensions.space16),
                                Expanded(
                                  child: (startIndex + col < widget.itemCount)
                                      ? const ArticleCardSkeleton()
                                      : const SizedBox.shrink(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
