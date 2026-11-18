import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../models/article_model.dart';
import '../../models/blog_model.dart';

/// Reusable news card widget matching the reference List Screen design.
///
/// Features a compact horizontal layout:
/// - Rounded rectangular thumbnail on the left (with CachedNetworkImage).
/// - Category/source, bold headline title, and author/date metadata on the right.
/// Reusable across both Articles and Blogs views.
class ArticleCard extends StatelessWidget {
  final int id;
  final String title;
  final String imageUrl;
  final String newsSite;
  final String summary;
  final DateTime? publishedAt;
  final String? authorName;
  final bool featured;
  final VoidCallback? onTap;

  const ArticleCard({
    super.key,
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.newsSite,
    required this.summary,
    this.publishedAt,
    this.authorName,
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
      authorName: article.authors.isNotEmpty
          ? article.authors.first.name
          : null,
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
      authorName: blog.authors.isNotEmpty ? blog.authors.first.name : null,
      featured: blog.featured,
      onTap: onTap,
    );
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return 'Date unavailable';
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
    final isDark = theme.brightness == Brightness.dark;

    final primaryTextColor = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final tertiaryTextColor = isDark
        ? AppColors.textTertiaryDark
        : AppColors.textTertiaryLight;

    final displayName = (authorName != null && authorName!.trim().isNotEmpty)
        ? authorName!.trim()
        : newsSite;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space6),
      child: Material(
        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Rounded Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
                  child: SizedBox(
                    width: 104,
                    height: 104,
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
                                  width: 20,
                                  height: 20,
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
                                size: 28,
                                color: tertiaryTextColor,
                              ),
                            ),
                          )
                        : Container(
                            color: isDark
                                ? AppColors.surfaceVariantDark
                                : AppColors.surfaceVariantLight,
                            child: Icon(
                              Icons.newspaper_rounded,
                              size: 28,
                              color: tertiaryTextColor,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: AppDimensions.space12),

                // Right: Content Column
                Expanded(
                  child: SizedBox(
                    height: 104,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Category / Source
                        Text(
                          newsSite,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: tertiaryTextColor,
                            letterSpacing: -0.2,
                          ),
                        ),

                        // Title (bold, max 2 lines)
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                            height: 1.25,
                            letterSpacing: -0.3,
                          ),
                        ),

                        // Metadata Row: Avatar + Author + Dot + Date
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 9,
                              backgroundColor: isDark
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : AppColors.primaryLight.withValues(
                                      alpha: 0.2,
                                    ),
                              child: Text(
                                displayName.isNotEmpty
                                    ? displayName[0].toUpperCase()
                                    : 'N',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.space6),
                            Flexible(
                              child: Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ),
                            Text(
                              ' • ',
                              style: TextStyle(
                                fontSize: 12,
                                color: tertiaryTextColor,
                              ),
                            ),
                            Text(
                              _formatDate(publishedAt),
                              style: TextStyle(
                                fontSize: 11,
                                color: tertiaryTextColor,
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
    );
  }
}
