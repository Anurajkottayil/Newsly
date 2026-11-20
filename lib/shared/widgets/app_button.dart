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
  final Widget? trailingIcon;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.width,
    this.height = AppDimensions.buttonHeight,
    this.borderRadius,
  });

  const AppButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.width,
    this.height = AppDimensions.buttonHeight,
    this.borderRadius,
  }) : variant = AppButtonVariant.outlined;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.width,
    this.height = AppDimensions.buttonHeightSmall,
    this.borderRadius,
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
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: AppDimensions.space8),
          trailingIcon!,
        ],
      ],
    );

    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(AppDimensions.radiusSm);

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
            shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
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
            shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
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
            shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
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
            shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
          ),
          child: content,
        );
        break;
    }

    if (width != null) {
      if (width == double.infinity) {
        return SizedBox(width: width, child: button);
      }
      return ConstrainedBox(
        constraints: BoxConstraints(minWidth: width!),
        child: button,
      );
    }
    return button;
  }
}
