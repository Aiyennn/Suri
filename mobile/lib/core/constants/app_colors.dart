import 'package:flutter/material.dart';

/// Centralized color palette for the Suri app.
abstract final class AppColors {
  // Primary — #2563EB blue
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFFEFF6FF);
  static const Color primarySurface = Color(0xFFEFF6FF);

  // Secondary — #14B8A6 teal (used for gradient end)
  static const Color secondary = Color(0xFF14B8A6);
  static const Color secondaryLight = Color(0xFFCCFBF1);

  // Surfaces & Backgrounds
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color scaffoldBg = Color(0xFFF8FAFC);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Dark-mode surfaces
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color scaffoldBgDark = Color(0xFF0F172A);
  static const Color cardBorderDark = Color(0xFF334155);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Urgency gradient
  static const Color urgencyHigh = Color(0xFFEF4444);
  static const Color urgencyMedium = Color(0xFFF97316);
  static const Color urgencyLow = Color(0xFF22C55E);

  // Bottom nav
  static const Color navInactive = Color(0xFF94A3B8);
  static const Color navActive = Color(0xFF2563EB);

  // Chip / Badge
  static const Color chipBg = Color(0xFFEFF6FF);
  static const Color chipSelectedBg = Color(0xFF2563EB);
  static const Color chipText = Color(0xFF1D4ED8);

  // Login gradient
  static const List<Color> loginButtonGradient = [primary, secondary];

  // Shadow
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowMedium = Color(0x14000000);
}
