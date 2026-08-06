import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Hero section with gradient background, medical illustration, and HIPAA badge.
class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryLight,
            AppColors.surface,
            AppColors.primarySurface,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          // Medical illustration via CustomPainter
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CustomPaint(
                painter: _MedicalIllustrationPainter(),
              ),
            ),
          ),
          // HIPAA badge overlay
        ],
      ),
    );
  }
}

/// Draws an abstract medical/DNA-themed illustration.
class _MedicalIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw DNA double helix
    _drawDnaHelix(canvas, size, paint);

    // Draw circuit-like medical connections
    _drawCircuitLines(canvas, size, paint);

    // Draw hexagonal molecules
    _drawHexagons(canvas, size, paint);

    // Draw floating dots
    _drawFloatingDots(canvas, size);
  }

  void _drawDnaHelix(Canvas canvas, Size size, Paint paint) {
    final helixPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.15)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path1 = Path();
    final path2 = Path();

    for (double t = 0; t < size.height; t += 2) {
      final x1 = size.width * 0.35 + sin(t * 0.04) * 30;
      final x2 = size.width * 0.35 - sin(t * 0.04) * 30;
      if (t == 0) {
        path1.moveTo(x1, t);
        path2.moveTo(x2, t);
      } else {
        path1.lineTo(x1, t);
        path2.lineTo(x2, t);
      }
    }

    canvas.drawPath(path1, helixPaint);
    canvas.drawPath(path2, helixPaint..color = AppColors.info.withValues(alpha: 0.1));

    // Rungs between helices
    final rungPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (double t = 10; t < size.height; t += 20) {
      final x1 = size.width * 0.35 + sin(t * 0.04) * 30;
      final x2 = size.width * 0.35 - sin(t * 0.04) * 30;
      canvas.drawLine(Offset(x1, t), Offset(x2, t), rungPaint);
    }
  }

  void _drawCircuitLines(Canvas canvas, Size size, Paint paint) {
    final linePaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.06)
      ..strokeWidth = 1;

    // Horizontal grid lines
    for (double y = 30; y < size.height; y += 40) {
      canvas.drawLine(
        Offset(size.width * 0.6, y),
        Offset(size.width, y),
        linePaint,
      );
    }

    // Vertical connectors
    for (double x = size.width * 0.65; x < size.width; x += 35) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        linePaint..color = AppColors.info.withValues(alpha: 0.04),
      );
    }
  }

  void _drawHexagons(Canvas canvas, Size size, Paint paint) {
    final hexPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.1)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    _drawHexagon(canvas, Offset(size.width * 0.7, size.height * 0.3), 18, hexPaint);
    _drawHexagon(canvas, Offset(size.width * 0.85, size.height * 0.5), 14, hexPaint);
    _drawHexagon(canvas, Offset(size.width * 0.6, size.height * 0.7), 12, hexPaint);
  }

  void _drawHexagon(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (pi / 3) * i - pi / 6;
      final point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawFloatingDots(Canvas canvas, Size size) {
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final rng = Random(42); // Fixed seed for deterministic output

    for (int i = 0; i < 15; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final radius = 1.5 + rng.nextDouble() * 2;
      dotPaint.color = (i % 2 == 0)
          ? AppColors.primary.withValues(alpha: 0.1 + rng.nextDouble() * 0.1)
          : AppColors.info.withValues(alpha: 0.08 + rng.nextDouble() * 0.08);
      canvas.drawCircle(Offset(x, y), radius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
