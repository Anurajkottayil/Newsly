import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/article_model.dart';
import '../../models/blog_model.dart';

/// Highly reusable news card widget used for displaying both [Article] and [Blog] items.
///
/// Features responsive image caching with [CachedNetworkImage], placeholder shimmer,
/// source badge, featured tag, and standardized typography.
class ArticleCard extends StatelessWidget {
  final int id;
  final String title;
  final String imageUrl;
  final String newsSite;
  final String summary;
  final DateTime publishedAt;
  final bool featured;
  final VoidCallback? onTap;

  const ArticleCard({
    super.key,
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.newsSite,
    required this.summary,
    required this.publishedAt,
    this.featured = false,
    this.onTap,
  });

  /// Factory adapter for creating an [ArticleCard] directly from an [Article] model.
  factory ArticleCard.fromArticle({
    Key? key,
    required Article article,
    VoidCallback? onTap,
  }) {
    return ArticleCard(
      key: key ?? ValueKey('article_${article.id}'),
      id: article.id,
      title: article.title,
      imageUrl: article.imageUrl,
      newsSite: article.newsSite,
      summary: article.summary,
      publishedAt: article.publishedAt,
      featured: article.featured,
      onTap: onTap,
    );
  }

  /// Factory adapter for creating an [ArticleCard] directly from a [Blog] model.
  factory ArticleCard.fromBlog({
    Key? key,
    required Blog blog,
    VoidCallback? onTap,
  }) {
    return ArticleCard(
      key: key ?? ValueKey('blog_${blog.id}'),
      id: blog.id,
      title: blog.title,
      imageUrl: blog.imageUrl,
      newsSite: blog.newsSite,
      summary: blog.summary,
      publishedAt: blog.publishedAt,
      featured: false,
      onTap: onTap,
    );
  }

  String _formatDate(DateTime dateTime) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with badges
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: isDark
                                ? AppColors.shimmerBaseDark
                                : AppColors.shimmerBaseLight,
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: isDark
                                ? AppColors.surfaceVariantDark
                                : AppColors.surfaceVariantLight,
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 40,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: isDark
                              ? AppColors.surfaceVariantDark
                              : AppColors.surfaceVariantLight,
                          child: Icon(
                            Icons.newspaper_rounded,
                            size: 40,
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
                          ),
                        ),
                ),
                // Featured Tag
                if (featured)
                  Positioned(
                    top: AppDimensions.space8,
                    left: AppDimensions.space8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space8,
                        vertical: AppDimensions.space4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusXs,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'FEATURED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Text Content Section
            Padding(
              padding: const EdgeInsets.all(AppDimensions.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta Info (Source & Date)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space8,
                          vertical: AppDimensions.space2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusXs,
                          ),
                        ),
                        child: Text(
                          newsSite,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(publishedAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space8),

                  // Title
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space6),

                  // Summary
                  if (summary.isNotEmpty)
                    Text(
                      summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
