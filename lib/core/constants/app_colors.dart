import 'package:flutter/material.dart';

/// Centralized color palette for the Newsly application.
///
/// Provides light and dark mode color definitions adhering to Material Design 3.
class AppColors {
  AppColors._();

  // Brand / Primary Colors
  static const Color primary = Color(0xFF1E40AF); // Deep Indigo
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1E3A8A);

  // Secondary / Accent Colors
  static const Color secondary = Color(0xFF0EA5E9); // Sky Blue
  static const Color secondaryLight = Color(0xFF38BDF8);
  static const Color secondaryDark = Color(0xFF0284C7);

  // Light Theme Colors
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);

  // Dark Theme Colors
  static const Color backgroundDark = Color(0xFF0F172A); // Slate 900
  static const Color surfaceDark = Color(0xFF1E293B); // Slate 800
  static const Color surfaceVariantDark = Color(0xFF334155); // Slate 700
  static const Color cardDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF334155);

  // Text Colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textTertiaryLight = Color(0xFF94A3B8);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFF64748B);

  // Feedback Colors
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);

  // Shimmer & Placeholder Colors
  static const Color shimmerBaseLight = Color(0xFFE2E8F0);
  static const Color shimmerHighlightLight = Color(0xFFF1F5F9);
  static const Color shimmerBaseDark = Color(0xFF334155);
  static const Color shimmerHighlightDark = Color(0xFF475569);
}
