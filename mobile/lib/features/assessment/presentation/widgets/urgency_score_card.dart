import 'dart:math';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Urgency score card with score ring and level text.
class UrgencyScoreCard extends StatelessWidget {
  final int score;
  final String title;
  final String description;

  const UrgencyScoreCard({
    super.key,
    required this.score,
    required this.title,
    required this.description,
  });

  Color get _urgencyColor {
    if (score >= 70) return AppColors.urgencyHigh;
    if (score >= 40) return AppColors.urgencyMedium;
    return AppColors.urgencyLow;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row: urgency label + score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _urgencyColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _urgencyColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'URGENCY LEVEL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _urgencyColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              // Score ring
              SizedBox(
                width: 52,
                height: 52,
                child: CustomPaint(
                  painter: _ScoreRingPainter(
                    score: score,
                    color: _urgencyColor,
                  ),
                  child: Center(
                    child: Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _urgencyColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Title
          Align(
            alignment: Alignment.centerLeft,
            child: Text(title, style: AppTextStyles.headingMd),
          ),
          const SizedBox(height: AppSpacing.md),

          // Description
          Text(description, style: AppTextStyles.bodyMd),
        ],
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final int score;
  final Color color;

  _ScoreRingPainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    // Background circle
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final sweepAngle = (score / 100) * 2 * pi;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter oldDelegate) =>
      oldDelegate.score != score;
}
