import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'discover_screen.dart';

/// Dedicated Splash Screen for the Newsly Application.
///
/// Displays the custom Newsly brand icon centered on a neutral background
/// (white in light mode, deep navy in dark mode) for the specified duration
/// (defaulting to 3 seconds), then seamlessly navigates to [DiscoverScreen].
class SplashScreen extends StatefulWidget {
  final Duration duration;

  const SplashScreen({
    super.key,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(
      const AssetImage('assets/branding/newsly_splash_icon.png'),
      context,
    );
  }

  void _startTimer() {
    _timer = Timer(widget.duration, _navigateToDiscover);
  }

  void _navigateToDiscover() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const DiscoverScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Image.asset(
          'assets/branding/newsly_splash_icon.png',
          width: 100,
          height: 100,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          excludeFromSemantics: true,
        ),
      ),
    );
  }
}
