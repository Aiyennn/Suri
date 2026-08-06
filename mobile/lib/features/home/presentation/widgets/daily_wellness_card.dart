import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_spacing.dart';

/// A daily wellness tip banner card.
class DailyWellnessCard extends StatelessWidget {
  const DailyWellnessCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3B5BDB),
            Color(0xFF4ECDC4),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B5BDB).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Star / tip icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.wb_sunny_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily wellness tip',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.4,
                    ),
                    children: const [
                      TextSpan(text: 'Stay hydrated '),
                      TextSpan(text: '💧'),
                      TextSpan(
                          text:
                              ' and take short walks to keep your energy up!'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Decorative plant illustration
          _PlantIllustration(),
        ],
      ),
    );
  }
}

/// Simple decorative illustration using custom painter (plant & brain motif).
class _PlantIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: CustomPaint(painter: _PlantPainter()),
    );
  }
}

class _PlantPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Bowl / cup shape
    paint.color = const Color(0xFF2E86AB).withValues(alpha: 0.9);
    final bowlPath = Path()
      ..moveTo(size.width * 0.2, size.height * 0.55)
      ..lineTo(size.width * 0.3, size.height * 0.9)
      ..lineTo(size.width * 0.7, size.height * 0.9)
      ..lineTo(size.width * 0.8, size.height * 0.55)
      ..close();
    canvas.drawPath(bowlPath, paint);

    // Oval head of figure
    paint.color = const Color(0xFF4ECDC4).withValues(alpha: 0.85);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.42),
        width: size.width * 0.45,
        height: size.height * 0.38,
      ),
      paint,
    );

    // Leaves
    paint.color = const Color(0xFF2ECC71).withValues(alpha: 0.9);
    _drawLeaf(canvas, size, 0.35, 0.18, -0.4, paint);
    _drawLeaf(canvas, size, 0.65, 0.15, 0.4, paint);
    _drawLeaf(canvas, size, 0.5, 0.08, 0.0, paint);

    // Small dots on the figure
    paint.color = Colors.white.withValues(alpha: 0.6);
    canvas.drawCircle(
        Offset(size.width * 0.42, size.height * 0.40), 2.5, paint);
    canvas.drawCircle(
        Offset(size.width * 0.58, size.height * 0.40), 2.5, paint);
  }

  void _drawLeaf(Canvas canvas, Size size, double cx, double cy,
      double angle, Paint paint) {
    canvas.save();
    canvas.translate(size.width * cx, size.height * cy);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(-8, -12, 0, -22)
      ..quadraticBezierTo(8, -12, 0, 0);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
