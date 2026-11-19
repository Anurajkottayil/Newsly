import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';

/// Responsive wrapper that applies appropriate horizontal constraints and padding
/// for phones, tablets, and iPads.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final double maxWidth;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.maxWidth = AppDimensions.maxContentWidth,
  });

  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= AppDimensions.tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= AppDimensions.desktopBreakpoint;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    Widget child =
        (screenWidth >= AppDimensions.tabletBreakpoint && tablet != null)
        ? tablet!
        : mobile;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
