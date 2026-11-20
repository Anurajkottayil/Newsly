import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../services/share_service.dart';

/// Shows a polished Material 3 bottom sheet providing actions for
/// Share, Copy Link, and Open in External Browser.
Future<void> showDetailMoreOptionsSheet({
  required BuildContext context,
  required String title,
  required String url,
  required bool isBlog,
  required Future<void> Function() onOpenOriginal,
  ShareService shareService = const ShareServiceImpl(),
}) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
  final textColor =
      isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
  final secondaryTextColor =
      isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
  final dividerColor = isDark ? AppColors.borderDark : AppColors.borderLight;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: surfaceColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppDimensions.radiusXl),
      ),
    ),
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.space12,
            horizontal: AppDimensions.space16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppDimensions.space16),
                  decoration: BoxDecoration(
                    color: dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Sheet Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space8,
                  vertical: AppDimensions.space4,
                ),
                child: Text(
                  AppStrings.moreOptions,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: secondaryTextColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.space8),

              // 1. Share Article / Blog
              _buildOptionTile(
                icon: Icons.share_rounded,
                title: isBlog ? AppStrings.shareBlog : AppStrings.shareArticle,
                textColor: textColor,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  shareService.share(title: title, url: url);
                },
              ),

              // 2. Copy Link
              _buildOptionTile(
                icon: Icons.link_rounded,
                title: AppStrings.copyLink,
                textColor: textColor,
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.of(sheetContext).pop();
                  final cleanUrl = url.trim();
                  if (cleanUrl.isEmpty) {
                    messenger.clearSnackBars();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(AppStrings.noUrlToCopy),
                        duration: Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  messenger.clearSnackBars();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text(AppStrings.linkCopied),
                      duration: Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  await Clipboard.setData(ClipboardData(text: cleanUrl));
                },
              ),

              // 3. Open Original Article / Blog
              _buildOptionTile(
                icon: Icons.open_in_new_rounded,
                title: isBlog
                    ? AppStrings.openOriginalBlog
                    : AppStrings.openOriginalArticle,
                textColor: textColor,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onOpenOriginal();
                },
              ),

              const SizedBox(height: AppDimensions.space8),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildOptionTile({
  required IconData icon,
  required String title,
  required Color textColor,
  required VoidCallback onTap,
}) {
  return ListTile(
    leading: Icon(icon, color: textColor, size: 22),
    title: Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppDimensions.space8,
      vertical: AppDimensions.space2,
    ),
    minVerticalPadding: 0,
    dense: false,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
    ),
    onTap: onTap,
  );
}
