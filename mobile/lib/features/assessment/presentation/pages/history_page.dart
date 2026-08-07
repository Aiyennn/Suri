import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_nav_bar.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/entities/assessment_history.dart';
import '../providers/assessments_history_provider.dart';

/// History screen — shows all past wound assessment records.
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assessmentsHistoryProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(assessmentsHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Navbar ─────────────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: AppNavBar(),
            ),

            // ── Body content ──────────────────────────────────────────────
            Expanded(child: _buildBody(historyState)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AssessmentsHistoryState state) {
    return switch (state) {
      AssessmentsHistoryInitial() => const SizedBox.shrink(),
      AssessmentsHistoryLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
      AssessmentsHistoryError(:final message) => _ErrorState(
          message: message,
          onRetry: () =>
              ref.read(assessmentsHistoryProvider.notifier).refresh(),
        ),
      AssessmentsHistoryLoaded(:final items, :final total) =>
        items.isEmpty ? _EmptyState() : _LoadedState(items: items, total: total),
    };
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('No History Yet', style: AppTextStyles.headingMd),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your completed assessments will appear here.',
            style: AppTextStyles.bodyMd,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          PrimaryButton(
            label: AppStrings.startAssessment,
            trailingIcon: Icons.arrow_forward,
            onPressed: () => context.push(RoutePaths.patientDetails),
          ),
        ],
      ),
    );
  }
}

// ── Error state ─────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              size: 36,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Unable to Load', style: AppTextStyles.headingMd),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Check your connection and try again.',
            style: AppTextStyles.bodyMd,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxxl),
          PrimaryButton(
            label: 'Try Again',
            trailingIcon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

// ── Loaded state ─────────────────────────────────────────────────────────────

class _LoadedState extends ConsumerWidget {
  final List<AssessmentHistoryItem> items;
  final int total;

  const _LoadedState({required this.items, required this.total});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () =>
          ref.read(assessmentsHistoryProvider.notifier).refresh(),
      child: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Assessment History',
                            style: AppTextStyles.headingLg),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '$total session${total == 1 ? '' : 's'} on record',
                          style: AppTextStyles.bodyMd,
                        ),
                      ],
                    ),
                  ),
                  _NewAssessmentButton(),
                ],
              ),
            ),
          ),

          // List
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.sm,
            ),
            sliver: SliverList.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, i) =>
                  _AssessmentCard(item: items[i]),
            ),
          ),

          const SliverPadding(
            padding: EdgeInsets.only(bottom: AppSpacing.xxl),
          ),
        ],
      ),
    );
  }
}

class _NewAssessmentButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RoutePaths.patientDetails),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 16, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'New',
              style: AppTextStyles.labelMd.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Assessment card ─────────────────────────────────────────────────────────

class _AssessmentCard extends StatelessWidget {
  final AssessmentHistoryItem item;

  const _AssessmentCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final riskColor = _riskColor(item.riskLevel);
    final riskBg = _riskBgColor(item.riskLevel);
    final dateStr = _formatDate(item.createdAt.toLocal());

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: date + risk badge
            Row(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 14,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(dateStr, style: AppTextStyles.caption),
                const Spacer(),
                if (item.riskLevel != null)
                  _RiskBadge(
                    label: item.riskLevel!,
                    color: riskColor,
                    bgColor: riskBg,
                  ),
                if (item.emergency == true) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_rounded,
                            size: 10, color: AppColors.error),
                        const SizedBox(width: 3),
                        Text(
                          'Emergency',
                          style: AppTextStyles.labelSm.copyWith(
                            color: AppColors.error,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Wound type + score row
            Row(
              children: [
                if (item.woundType != null)
                  _InfoChip(
                    icon: Icons.healing_outlined,
                    label: _capitalize(item.woundType!),
                  ),
                if (item.woundType != null)
                  const SizedBox(width: AppSpacing.sm),
                if (item.riskScore != null)
                  _InfoChip(
                    icon: Icons.speed_outlined,
                    label: 'Score ${item.riskScore}',
                  ),
                const Spacer(),
                Row(
                  children: [
                    Icon(Icons.image_outlined,
                        size: 14, color: AppColors.textTertiary),
                    const SizedBox(width: 3),
                    Text(
                      '${item.imageCount} photo${item.imageCount == 1 ? '' : 's'}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Patient info row
            Row(
              children: [
                _PatientInfoPill(
                  icon: Icons.person_outline,
                  label:
                      '${item.patientAge}y \u2022 ${_capitalize(item.patientSex)}',
                ),
                const SizedBox(width: AppSpacing.sm),
                _PatientInfoPill(
                  icon: Icons.timer_outlined,
                  label: item.duration,
                ),
              ],
            ),

            // Symptoms
            if (item.symptoms.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: item.symptoms
                    .take(4)
                    .map((s) => _SymptomChip(label: s))
                    .toList()
                  ..addAll(
                    item.symptoms.length > 4
                        ? [
                            _SymptomChip(
                              label: '+${item.symptoms.length - 4} more',
                              muted: true,
                            )
                          ]
                        : [],
                  ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Color _riskColor(String? level) {
    return switch (level?.toLowerCase()) {
      'low' => AppColors.success,
      'moderate' => AppColors.warning,
      'high' => AppColors.urgencyMedium,
      'critical' => AppColors.error,
      _ => AppColors.textTertiary,
    };
  }

  static Color _riskBgColor(String? level) {
    return switch (level?.toLowerCase()) {
      'low' => AppColors.successLight,
      'moderate' => AppColors.warningLight,
      'high' => const Color(0xFFFFEDD5),
      'critical' => AppColors.errorLight,
      _ => AppColors.background,
    };
  }

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  static String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} \u2022 $hour:$minute $ampm';
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _RiskBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bgColor;

  const _RiskBadge({
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: AppColors.primary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientInfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PatientInfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textTertiary),
        const SizedBox(width: 3),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _SymptomChip extends StatelessWidget {
  final String label;
  final bool muted;

  const _SymptomChip({required this.label, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: muted ? AppColors.background : AppColors.chipBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSm.copyWith(
          color: muted ? AppColors.textTertiary : AppColors.chipText,
          fontSize: 10,
        ),
      ),
    );
  }
}
