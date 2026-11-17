import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';

/// Reusable centered loading indicator with optional status message.
class AppLoader extends StatelessWidget {
  final String? message;
  final double strokeWidth;
  final Color? color;

  const AppLoader({
    super.key,
    this.message,
    this.strokeWidth = 3.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: strokeWidth,
              valueColor: color != null
                  ? AlwaysStoppedAnimation<Color>(color!)
                  : null,
            ),
            if (message != null) ...[
              const SizedBox(height: AppDimensions.space16),
              Text(
                message ?? AppStrings.loadingGeneral,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
