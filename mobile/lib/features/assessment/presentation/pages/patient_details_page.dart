import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/symptom.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../providers/assessment_provider.dart';

/// Patient Details page (Screen 2) — redesigned to match reference UI.
class PatientDetailsPage extends ConsumerStatefulWidget {
  const PatientDetailsPage({super.key});

  @override
  ConsumerState<PatientDetailsPage> createState() =>
      _PatientDetailsPageState();
}

class _PatientDetailsPageState extends ConsumerState<PatientDetailsPage> {
  final _ageController = TextEditingController();
  final _searchController = TextEditingController();
  bool _showSuggestions = false;

  @override
  void dispose() {
    _ageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Symptom> get _filteredSuggestions {
    final query = _searchController.text.toLowerCase();
    final selected = ref.read(assessmentProvider).patient.symptoms;
    return SymptomSuggestions.all
        .where((s) =>
            s.name.toLowerCase().contains(query) &&
            !selected.contains(s.name))
        .toList();
  }

  void _addSymptomFromSearch(String name) {
    ref.read(assessmentProvider.notifier).addSymptom(name);
    _searchController.clear();
    setState(() => _showSuggestions = false);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentProvider);
    final notifier = ref.read(assessmentProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppTopBar(
        title: AppStrings.appName,
        stepText: 'Step 1 of 3',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          // ── Step progress indicator ──────────────────────────────────────
          _StepProgressBar(currentStep: 1, totalSteps: 3),

          // ── Scrollable content ───────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back pill
                  _BackPill(onTap: () => context.pop()),
                  const SizedBox(height: AppSpacing.lg),

                  // Header
                  _SectionHeader(
                    icon: Icons.assignment_outlined,
                    title: "Let's get started",
                    subtitle:
                        'Please provide basic information to start your assessment.',
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // ── Age card ───────────────────────────────────────────
                  _FieldCard(
                    icon: Icons.calendar_today_outlined,
                    label: AppStrings.age,
                    child: _AgeInput(
                      controller: _ageController,
                      onChanged: (val) {
                        final age = int.tryParse(val);
                        if (age != null) notifier.updateAge(age);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Sex card ───────────────────────────────────────────
                  _FieldCard(
                    icon: Icons.person_outline_rounded,
                    label: 'Sex',
                    child: _SexSelector(
                      selectedValue: state.patient.sex,
                      onSelected: notifier.updateSex,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Symptoms card ──────────────────────────────────────
                  _FieldCard(
                    icon: Icons.search_rounded,
                    label: AppStrings.currentSymptoms,
                    trailing: Text(
                      AppStrings.multiSelect,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Search field
                        _SymptomSearchField(
                          controller: _searchController,
                          onChanged: (val) {
                            setState(() => _showSuggestions = val.isNotEmpty);
                          },
                          onTap: () {
                            if (_searchController.text.isNotEmpty) {
                              setState(() => _showSuggestions = true);
                            }
                          },
                        ),

                        // Suggestion dropdown
                        if (_showSuggestions &&
                            _filteredSuggestions.isNotEmpty)
                          _SuggestionDropdown(
                            suggestions: _filteredSuggestions,
                            onTap: _addSymptomFromSearch,
                          ),

                        // Selected chips
                        if (state.patient.symptoms.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: state.patient.symptoms
                                .map((s) => _SymptomChip(
                                      label: s,
                                      onRemove: () =>
                                          notifier.removeSymptom(s),
                                    ))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Duration card ──────────────────────────────────────
                  _FieldCard(
                    icon: Icons.access_time_outlined,
                    label: AppStrings.howLong,
                    labelColor: AppColors.primary,
                    child: _DurationGrid(
                      selectedValue: state.patient.duration,
                      onSelected: notifier.updateDuration,
                      options: const [
                        _DurationOption(
                          label: AppStrings.lessThan24h,
                          icon: Icons.timelapse_outlined,
                        ),
                        _DurationOption(
                          label: AppStrings.oneToThreeDays,
                          icon: Icons.calendar_month_outlined,
                        ),
                        _DurationOption(
                          label: AppStrings.oneWeek,
                          icon: Icons.date_range_outlined,
                        ),
                        _DurationOption(
                          label: AppStrings.moreThanOneWeek,
                          icon: Icons.calendar_today_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Medical History card ───────────────────────────────
                  _FieldCard(
                    icon: Icons.history_rounded,
                    label: AppStrings.medicalHistory,
                    child: _MedicalHistoryInput(
                      onChanged: notifier.updateMedicalHistory,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Privacy notice
                  _PrivacyNotice(),
                ],
              ),
            ),
          ),

          // ── Continue button (pinned) ─────────────────────────────────────
          _ContinueButton(
            onPressed: () => context.push(RoutePaths.uploadImages),
          ),
        ],
      ),
    );
  }
}

// ── Step progress bar ─────────────────────────────────────────────────────────

class _StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepProgressBar({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: List.generate(totalSteps, (i) {
          final active = i < currentStep;
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < totalSteps - 1 ? 6 : 0),
              height: 3,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : const Color(0xFFDDE3EF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Back pill ─────────────────────────────────────────────────────────────────

class _BackPill extends StatelessWidget {
  final VoidCallback onTap;
  const _BackPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(color: const Color(0xFFDDE3EF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chevron_left_rounded,
                size: 18, color: AppColors.primary),
            Text(
              'Back',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section header (icon + title + subtitle) ──────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Icon(icon, size: 22, color: AppColors.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Generic field card ────────────────────────────────────────────────────────

class _FieldCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? labelColor;
  final Widget? trailing;
  final Widget child;

  const _FieldCard({
    required this.icon,
    required this.label,
    this.labelColor,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card header row
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Icon(icon, size: 18, color: AppColors.primary),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: labelColor ?? AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

// ── Age input ─────────────────────────────────────────────────────────────────

class _AgeInput extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _AgeInput({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      style: GoogleFonts.inter(
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: AppStrings.enterAge,
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color: AppColors.textTertiary,
        ),
        filled: true,
        fillColor: const Color(0xFFF4F6FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: Color(0xFFDDE3EF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: Color(0xFFDDE3EF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}

// ── Sex selector ──────────────────────────────────────────────────────────────

class _SexSelector extends StatelessWidget {
  final String? selectedValue;
  final ValueChanged<String> onSelected;

  const _SexSelector({
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const options = [
      _SexOption(label: AppStrings.male, icon: Icons.male_rounded),
      _SexOption(label: AppStrings.female, icon: Icons.female_rounded),
    ];

    return Row(
      children: options.map((opt) {
        final isSelected = opt.label == selectedValue;
        final isLast = opt == options.last;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : AppSpacing.sm),
            child: GestureDetector(
              onTap: () => onSelected(opt.label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryLight : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : const Color(0xFFDDE3EF),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      opt.icon,
                      size: 18,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      opt.label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SexOption {
  final String label;
  final IconData icon;
  const _SexOption({required this.label, required this.icon});
}

// ── Symptom search field ──────────────────────────────────────────────────────

class _SymptomSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onTap;

  const _SymptomSearchField({
    required this.controller,
    required this.onChanged,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onTap: onTap,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search_rounded,
            size: 18, color: AppColors.textTertiary),
        hintText: AppStrings.searchSymptoms,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textTertiary,
        ),
        filled: true,
        fillColor: const Color(0xFFF4F6FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: Color(0xFFDDE3EF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: Color(0xFFDDE3EF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}

// ── Suggestion dropdown ───────────────────────────────────────────────────────

class _SuggestionDropdown extends StatelessWidget {
  final List<Symptom> suggestions;
  final ValueChanged<String> onTap;

  const _SuggestionDropdown({
    required this.suggestions,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      constraints: const BoxConstraints(maxHeight: 150),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: const Color(0xFFDDE3EF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListView(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        children: suggestions
            .map((s) => ListTile(
                  dense: true,
                  title: Text(s.name, style: AppTextStyles.bodyMd),
                  onTap: () => onTap(s.name),
                ))
            .toList(),
      ),
    );
  }
}

// ── Symptom chip ──────────────────────────────────────────────────────────────

class _SymptomChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _SymptomChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close_rounded,
                size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ── Duration grid ─────────────────────────────────────────────────────────────

class _DurationOption {
  final String label;
  final IconData icon;
  const _DurationOption({required this.label, required this.icon});
}

class _DurationGrid extends StatelessWidget {
  final List<_DurationOption> options;
  final String? selectedValue;
  final ValueChanged<String> onSelected;

  const _DurationGrid({
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      childAspectRatio: 3.0,
      children: options.map((opt) {
        final isSelected = opt.label == selectedValue;
        return GestureDetector(
          onTap: () => onSelected(opt.label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryLight : Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isSelected ? AppColors.primary : const Color(0xFFDDE3EF),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  opt.icon,
                  size: 16,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    opt.label,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Medical history input ─────────────────────────────────────────────────────

class _MedicalHistoryInput extends StatelessWidget {
  final ValueChanged<String> onChanged;
  const _MedicalHistoryInput({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      maxLines: 3,
      onChanged: onChanged,
      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'e.g. Diabetes, hypertension, allergies…',
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textTertiary,
        ),
        filled: true,
        fillColor: const Color(0xFFF4F6FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: Color(0xFFDDE3EF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: Color(0xFFDDE3EF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.md),
      ),
    );
  }
}

// ── Privacy notice ────────────────────────────────────────────────────────────

class _PrivacyNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded,
              size: 15, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              AppStrings.privacyNotice,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.primary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Continue button ───────────────────────────────────────────────────────────

class _ContinueButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _ContinueButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: const SizedBox.shrink(),
          label: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppStrings.continueText,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  size: 18, color: Colors.white),
            ],
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
        ),
      ),
    );
  }
}
