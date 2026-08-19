import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_nav_bar.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/entities/assessment_history.dart';
import '../providers/assessment_provider.dart';
import '../providers/assessments_history_provider.dart';

/// History screen - shows all past wound assessment records.
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
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: AppNavBar(),
            ),
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

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

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
            onPressed: () => context.push(RoutePaths.assessmentSelection),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Loaded state
// ---------------------------------------------------------------------------

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
            padding: EdgeInsets.only(bottom: 110),
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
      onTap: () => context.push(RoutePaths.assessmentSelection),
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

// ---------------------------------------------------------------------------
// Assessment card
// ---------------------------------------------------------------------------

class _AssessmentCard extends ConsumerWidget {
  final AssessmentHistoryItem item;

  const _AssessmentCard({required this.item});

  String get _assessmentType {
    if (item.woundType != null && item.woundType!.isNotEmpty) {
      final wt = item.woundType!.toLowerCase();
      if (wt.contains('skin') || wt.contains('rash') || wt.contains('mole')) {
        return 'Skin Condition Assessment';
      }
      return 'Wound Assessment';
    }
    return 'Symptom Assessment';
  }

  IconData get _assessmentIcon {
    final type = _assessmentType;
    if (type == 'Skin Condition Assessment') return Icons.front_hand_outlined;
    if (type == 'Wound Assessment') return Icons.healing_rounded;
    return Icons.monitor_heart_outlined;
  }

  Color _iconBgColor(Color risk) => risk.withValues(alpha: 0.12);

  Color get _riskColor {
    return switch (item.riskLevel?.toLowerCase()) {
      'low'      => AppColors.success,
      'moderate' => AppColors.warning,
      'high'     => AppColors.urgencyMedium,
      'critical' => AppColors.error,
      _          => AppColors.textTertiary,
    };
  }

  Color get _riskBg {
    return switch (item.riskLevel?.toLowerCase()) {
      'low'      => AppColors.successLight,
      'moderate' => AppColors.warningLight,
      'high'     => const Color(0xFFFFEDD5),
      'critical' => AppColors.errorLight,
      _          => AppColors.background,
    };
  }

  String get _dateStr {
    final dt = item.createdAt.toLocal();
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(dt.year, dt.month, dt.day);
    if (itemDay == today) return 'Updated today';
    if (itemDay == today.subtract(const Duration(days: 1))) return 'Updated yesterday';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String _formatTitle(String raw) =>
      raw.replaceAll('_', ' ').split(' ').map(_capitalize).join(' ');

  void _openResult(BuildContext context, WidgetRef ref) {
    ref.read(assessmentProvider.notifier).setHistoryResult(item);
    context.push(RoutePaths.results);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riskColor = _riskColor;
    final riskBgColor = _riskBg;
    final title = item.woundType != null
        ? _formatTitle(item.woundType!)
        : item.symptoms.isNotEmpty
            ? _capitalize(item.symptoms.first)
            : 'Assessment';

    return GestureDetector(
      onTap: () => _openResult(context, ref),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: const Color(0xFFEDF0F7)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _iconBgColor(riskColor),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(_assessmentIcon, size: 24, color: riskColor),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _assessmentType,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        if (item.riskLevel != null)
                          _RiskBadge(
                            label: '${item.riskLevel!.toUpperCase()} RISK',
                            color: riskColor,
                            bgColor: riskBgColor,
                          ),
                        if (item.riskScore != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          _InfoChip(
                            icon: Icons.speed_outlined,
                            label: 'Score ${item.riskScore}',
                          ),
                        ],
                        if (item.emergency == true) ...[
                          const SizedBox(width: AppSpacing.xs),
                          _InfoChip(
                            icon: Icons.warning_rounded,
                            label: 'Emergency',
                            color: AppColors.error,
                            bgColor: AppColors.errorLight,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            size: 13, color: AppColors.textTertiary),
                        const SizedBox(width: 3),
                        Text(
                          '${item.patientAge}y • ${_capitalize(item.patientSex)}',
                          style: AppTextStyles.caption,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Icon(Icons.timer_outlined,
                            size: 13, color: AppColors.textTertiary),
                        const SizedBox(width: 3),
                        Text(item.duration, style: AppTextStyles.caption),
                        if (item.imageCount > 0) ...[
                          const SizedBox(width: AppSpacing.md),
                          Icon(Icons.image_outlined,
                              size: 13, color: AppColors.textTertiary),
                          const SizedBox(width: 3),
                          Text(
                            '${item.imageCount} photo${item.imageCount == 1 ? '' : 's'}',
                            style: AppTextStyles.caption,
                          ),
                        ],
                      ],
                    ),
                    if (item.symptoms.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          ...item.symptoms.take(3).map((s) => _SymptomChip(label: s)),
                          if (item.symptoms.length > 3)
                            _SymptomChip(
                              label: '+${item.symptoms.length - 3} more',
                              muted: true,
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 12, color: AppColors.textTertiary),
                        const SizedBox(width: 3),
                        Text(_dateStr, style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                children: [
                  GestureDetector(
                    onTap: () => _openResult(context, ref),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 14, color: AppColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

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
  final Color? color;
  final Color? bgColor;

  const _InfoChip({
    required this.icon,
    required this.label,
    this.color,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? AppColors.primary;
    final bg = bgColor ?? AppColors.primarySurface;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.labelSm.copyWith(
              color: fg,
              fontSize: 11,
            ),
          ),
        ],
      ),
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
