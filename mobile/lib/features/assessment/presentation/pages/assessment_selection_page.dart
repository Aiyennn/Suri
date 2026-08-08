import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_top_bar.dart';

/// Assessment Selection page.
///
/// Shown when the user taps "Start Assessment" from any entry point.
/// Lets the user choose which type of assessment to begin before
/// proceeding to the Patient Details step.
class AssessmentSelectionPage extends StatelessWidget {
  const AssessmentSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppTopBar(
        title: 'Assessment',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Hero header ──────────────────────────────────────────────
              Stack(
                children: [
                  // Decorative background blob
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFDEEAFF), Color(0xFFF0F4FF)],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxl,
                      AppSpacing.xxl,
                      AppSpacing.xxl,
                      AppSpacing.xxxl,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title + subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'What would you\nlike to assess\ntoday?',
                                style: GoogleFonts.inter(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Select a category to begin your\nguided health check.',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Decorative clipboard illustration
                        _ClipboardIllustration(),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Assessment cards ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                child: Column(
                  children: [
                    _AssessmentCard(
                      icon: _SkinIcon(),
                      title: 'Skin Condition\nAssessment',
                      subtitle: 'Check for rashes, moles,\nor skin changes.',
                      titleColor: AppColors.primary,
                      accentColor: const Color(0xFF3B82F6),
                      onTap: () => context.push(RoutePaths.patientDetails),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AssessmentCard(
                      icon: _WoundIcon(),
                      title: 'Wound Assessment',
                      subtitle: 'Track healing progress or\nevaluate a new injury.',
                      titleColor: const Color(0xFF16A34A),
                      accentColor: const Color(0xFF16A34A),
                      onTap: () => context.push(RoutePaths.patientDetails),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AssessmentCard(
                      icon: _SymptomIcon(),
                      title: 'Symptom Assessment',
                      subtitle: 'Analyze general symptoms\nlike fever, pain, or cough.',
                      titleColor: const Color(0xFF7C3AED),
                      accentColor: const Color(0xFF7C3AED),
                      onTap: () => context.push(RoutePaths.patientDetails),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Assessment card ───────────────────────────────────────────────────────────

class _AssessmentCard extends StatefulWidget {
  final Widget icon;
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color accentColor;
  final VoidCallback onTap;

  const _AssessmentCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_AssessmentCard> createState() => _AssessmentCardState();
}

class _AssessmentCardState extends State<_AssessmentCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: [
              BoxShadow(
                color: widget.accentColor.withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Colored icon container
              widget.icon,
              const SizedBox(width: AppSpacing.lg),

              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: widget.titleColor,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron button
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: widget.accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Clipboard illustration (top right) ───────────────────────────────────────

class _ClipboardIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 100,
      child: Stack(
        children: [
          // Clipboard base
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 60,
              height: 75,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(10, 20, 10, 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  4,
                  (i) => Row(
                    children: [
                      Icon(Icons.check_rounded,
                          size: 9, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: i < 3
                                ? AppColors.primaryLight
                                : const Color(0xFFDDE3EF),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Clipboard clip
          Positioned(
            top: 10,
            right: 20,
            child: Container(
              width: 20,
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          // Decorative leaf dot
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Color(0xFF6EE7B7),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skin condition icon ───────────────────────────────────────────────────────

class _SkinIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Skin patch background
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFECDD3),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          // Magnifier
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(Icons.search_rounded, size: 14, color: Colors.white),
            ),
          ),
          // Small dot on skin patch
          Positioned(
            left: 16,
            top: 20,
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: Color(0xFFFF6B6B),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Wound icon ────────────────────────────────────────────────────────────────

class _WoundIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Center(
        child: Transform.rotate(
          angle: -0.6,
          child: Container(
            width: 38,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF86EFAC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF4ADE80), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _BandaidDot(),
                _BandaidCenter(),
                _BandaidDot(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BandaidDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFF4ADE80).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class _BandaidCenter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: const BoxDecoration(
        color: Color(0xFF86EFAC),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(Icons.add_rounded, size: 10, color: Color(0xFF16A34A)),
      ),
    );
  }
}

// ── Symptom icon ──────────────────────────────────────────────────────────────

class _SymptomIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F3FF),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Thermometer body
          Container(
            width: 14,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFDDD6FE),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF8B5CF6), width: 1.5),
            ),
          ),
          // Thermometer bulb
          Positioned(
            bottom: 12,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFF7C3AED),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Heart icon overlay
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F3FF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDDD6FE)),
              ),
              child: const Icon(Icons.favorite_rounded,
                  size: 10, color: Color(0xFF7C3AED)),
            ),
          ),
        ],
      ),
    );
  }
}
