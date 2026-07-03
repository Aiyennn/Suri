import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Small colored pill badge (e.g., "Running...", score "78").
class StatusBadge extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;

  const StatusBadge({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
  });

  /// Factory for a "Running..." style badge.
  factory StatusBadge.running() {
    return const StatusBadge(
      text: 'Running...',
      backgroundColor: AppColors.primaryLight,
      textColor: AppColors.primary,
    );
  }

  /// Factory for a score badge.
  factory StatusBadge.score(int score) {
    Color bg;
    Color text;
    if (score >= 70) {
      bg = AppColors.errorLight;
      text = AppColors.error;
    } else if (score >= 40) {
      bg = AppColors.warningLight;
      text = AppColors.warning;
    } else {
      bg = AppColors.successLight;
      text = AppColors.success;
    }
    return StatusBadge(
      text: score.toString(),
      backgroundColor: bg,
      textColor: text,
      fontSize: 16,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize ?? 11,
          fontWeight: FontWeight.w600,
          color: textColor ?? AppColors.primary,
        ),
      ),
    );
  }
}
