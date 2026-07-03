import 'package:flutter/material.dart';

/// Centralized color palette for the Medical Triage app.
/// Extracted from UI screenshots.
abstract final class AppColors {
  // Primary
  static const Color primary = Color(0xFF1A56DB);
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFFE8F0FE);
  static const Color primarySurface = Color(0xFFF0F5FF);

  // Surfaces & Backgrounds
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF8FAFC);
  static const Color scaffoldBg = Color(0xFFF9FAFB);
  static const Color cardBorder = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // Text
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
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
  static const Color navInactive = Color(0xFF9CA3AF);
  static const Color navActive = Color(0xFF1A56DB);

  // Chip / Badge
  static const Color chipBg = Color(0xFFEFF6FF);
  static const Color chipSelectedBg = Color(0xFF1A56DB);
  static const Color chipText = Color(0xFF1E40AF);

  // Shadow
  static const Color shadowLight = Color(0x0A000000);
  static const Color shadowMedium = Color(0x14000000);
}
