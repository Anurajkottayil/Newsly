import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';

enum AppButtonVariant { primary, secondary, outlined, text }

/// Reusable application button supporting primary, secondary, outlined, and text variants,
/// with built-in loading and icon support.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppDimensions.buttonHeight,
  });

  const AppButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppDimensions.buttonHeight,
  }) : variant = AppButtonVariant.outlined;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = AppDimensions.buttonHeightSmall,
  }) : variant = AppButtonVariant.text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final effectiveOnPressed = isLoading ? null : onPressed;

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: AppDimensions.iconSizeMedium,
            height: AppDimensions.iconSizeMedium,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(
                variant == AppButtonVariant.outlined ||
                        variant == AppButtonVariant.text
                    ? colorScheme.primary
                    : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.space8),
        ] else if (icon != null) ...[
          icon!,
          const SizedBox(width: AppDimensions.space8),
        ],
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ],
    );

    Widget button;
    switch (variant) {
      case AppButtonVariant.primary:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            minimumSize: Size(width ?? 0, height),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
          ),
          child: content,
        );
        break;

      case AppButtonVariant.secondary:
        button = ElevatedButton(
          onPressed: effectiveOnPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.secondary,
            foregroundColor: colorScheme.onSecondary,
            minimumSize: Size(width ?? 0, height),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
          ),
          child: content,
        );
        break;

      case AppButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: effectiveOnPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.primary,
            side: BorderSide(color: colorScheme.primary, width: 1.5),
            minimumSize: Size(width ?? 0, height),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space16,
            ),

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
          ),
          child: content,
        );
        break;

      case AppButtonVariant.text:
        button = TextButton(
          onPressed: effectiveOnPressed,
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.primary,
            minimumSize: Size(width ?? 0, height),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
          ),
          child: content,
        );
        break;
    }

    if (width != null) {
      return SizedBox(width: width, child: button);
    }
    return button;
  }
}
