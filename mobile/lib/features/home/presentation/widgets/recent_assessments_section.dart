import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../assessment/domain/entities/assessment_history.dart';
import '../../../assessment/presentation/providers/assessments_history_provider.dart';

/// "Recent Assessments" section shown on the home page.
class RecentAssessmentsSection extends ConsumerStatefulWidget {
  final VoidCallback onViewAll;

  const RecentAssessmentsSection({super.key, required this.onViewAll});

  @override
  ConsumerState<RecentAssessmentsSection> createState() =>
      _RecentAssessmentsSectionState();
}

class _RecentAssessmentsSectionState
    extends ConsumerState<RecentAssessmentsSection> {
  @override
  void initState() {
    super.initState();
    // Load assessments when this section first appears.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assessmentsHistoryProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentsHistoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ─────────────────────────────────────────────
        Row(
          children: [
            Text(
              'Recent Assessments',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: widget.onViewAll,
              child: Row(
                children: [
                  Text(
                    'View all',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppColors.primary),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // ── Content ────────────────────────────────────────────────────
        if (state.isLoading && !state.hasData)
          const _LoadingState()
        else if (state.hasError && !state.hasData)
          _ErrorState(message: state.error ?? 'Unable to load assessments')
        else if (state.isEmpty)
          const _EmptyState()
        else if (state.hasData)
          _AssessmentList(items: state.items.take(3).toList())
        else
          const SizedBox.shrink(),
      ],
    );
  }
}

// ── List ──────────────────────────────────────────────────────────────────────

class _AssessmentList extends StatelessWidget {
  final List<AssessmentHistoryItem> items;

  const _AssessmentList({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items
          .map((item) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _AssessmentTile(item: item),
              ))
          .toList(),
    );
  }
}

// ── Tile ──────────────────────────────────────────────────────────────────────

class _AssessmentTile extends StatelessWidget {
  final AssessmentHistoryItem item;

  const _AssessmentTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final riskLevel = (item.riskLevel ?? '').toLowerCase();
    final (badgeColor, badgeTextColor, badgeBg) = _riskColors(riskLevel);
    final title = _title(item);
    final subtitle = _subtitle(item);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Category icon ──────────────────────────────────────────
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _iconBg(riskLevel),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_icon(item), size: 24, color: _iconColor(riskLevel)),
          ),
          const SizedBox(width: AppSpacing.md),

          // ── Title + badge + date ───────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _riskLabel(riskLevel),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badgeTextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          // ── View button ────────────────────────────────────────────
          TextButton.icon(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Text(
              'View',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            label: const Icon(Icons.arrow_forward_rounded,
                size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  String _title(AssessmentHistoryItem item) {
    if (item.woundType != null && item.woundType!.isNotEmpty) {
      return _capitalize(item.woundType!);
    }
    if (item.symptoms.isNotEmpty) return _capitalize(item.symptoms.first);
    return 'Assessment';
  }

  String _subtitle(AssessmentHistoryItem item) {
    final now = DateTime.now();
    final diff = now.difference(item.createdAt);
    if (diff.inDays == 0) return 'Updated today';
    if (diff.inDays == 1) return 'Updated yesterday';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final m = months[item.createdAt.month - 1];
    return 'Updated $m ${item.createdAt.day}';
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _riskLabel(String level) {
    return switch (level) {
      'high' => 'HIGH RISK',
      'moderate' || 'medium' => 'MODERATE RISK',
      'low' => 'LOW RISK',
      _ => level.toUpperCase(),
    };
  }

  (Color, Color, Color) _riskColors(String level) {
    return switch (level) {
      'high' => (
          AppColors.error,
          AppColors.error,
          AppColors.errorLight,
        ),
      'moderate' || 'medium' => (
          AppColors.warning,
          AppColors.warning,
          AppColors.warningLight,
        ),
      'low' => (
          AppColors.success,
          AppColors.success,
          AppColors.successLight,
        ),
      _ => (
          AppColors.textTertiary,
          AppColors.textSecondary,
          AppColors.divider,
        ),
    };
  }

  Color _iconBg(String level) {
    return switch (level) {
      'high' => AppColors.errorLight,
      'moderate' || 'medium' => AppColors.warningLight,
      'low' => AppColors.successLight,
      _ => AppColors.primaryLight,
    };
  }

  Color _iconColor(String level) {
    return switch (level) {
      'high' => AppColors.error,
      'moderate' || 'medium' => AppColors.warning,
      'low' => AppColors.success,
      _ => AppColors.primary,
    };
  }

  IconData _icon(AssessmentHistoryItem item) {
    final wt = (item.woundType ?? '').toLowerCase();
    if (wt.contains('burn')) return Icons.local_fire_department_rounded;
    if (wt.contains('wound') || wt.contains('cut')) return Icons.healing_rounded;
    if (item.symptoms.any((s) => s.toLowerCase().contains('allerg'))) {
      return Icons.nature_rounded;
    }
    return Icons.medical_services_rounded;
  }
}

// ── States ────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: [
            Icon(Icons.history_edu_rounded,
                size: 48, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No assessments yet',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Could not load assessments',
        style: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
