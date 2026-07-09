  import 'package:flutter/material.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:go_router/go_router.dart';

  import '../../../../config/routes/app_router.dart';
  import '../../../../core/constants/app_colors.dart';
  import '../../../../core/constants/app_spacing.dart';
  import '../../../../core/constants/app_strings.dart';
  import '../../../../core/theme/app_text_styles.dart';
  import '../../../../shared/models/symptom.dart';
  import '../../../../shared/widgets/app_top_bar.dart';
  import '../../../../shared/widgets/info_banner.dart';
  import '../../../../shared/widgets/input_field.dart';
  import '../../../../shared/widgets/multi_chip_selector.dart';
  import '../../../../shared/widgets/primary_button.dart';
  import '../../../../shared/widgets/search_field.dart';
  import '../../../../shared/widgets/section_card.dart';
  import '../../../../shared/widgets/toggle_selector.dart';
  import '../providers/assessment_provider.dart';
  import '../widgets/duration_selector.dart';

  /// Patient Details page (Screen 2).
  class PatientDetailsPage extends ConsumerStatefulWidget {
    const PatientDetailsPage({super.key});

    @override
    ConsumerState<PatientDetailsPage> createState() => _PatientDetailsPageState();
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
        appBar: AppTopBar(
          title: AppStrings.appName,
          stepText: 'Step 1 of 3',
          showBack: true,
          onBack: () => context.pop(),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(AppStrings.patientDetails,
                        style: AppTextStyles.headingLg),
                    const SizedBox(height: AppSpacing.xs),
                    Text(AppStrings.patientDetailsSubtitle,
                        style: AppTextStyles.bodyMd),
                    const SizedBox(height: AppSpacing.xxl),

                    // Age section
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InputField(
                            label: AppStrings.age,
                            hintText: AppStrings.enterAge,
                            suffixText: AppStrings.years,
                            keyboardType: TextInputType.number,
                            controller: _ageController,
                            onChanged: (val) {
                              final age = int.tryParse(val);
                              if (age != null) notifier.updateAge(age);
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(AppStrings.sexAtBirth,
                              style: AppTextStyles.labelLg),
                          const SizedBox(height: AppSpacing.sm),
                          ToggleSelector(
                            options: const [
                              AppStrings.male,
                              AppStrings.female,
                              AppStrings.other,
                            ],
                            selectedValue: state.patient.sex,
                            onSelected: notifier.updateSex,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Symptoms section
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(AppStrings.currentSymptoms,
                                  style: AppTextStyles.labelLg),
                              Text(
                                AppStrings.multiSelect,
                                style: AppTextStyles.bodySm.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          // Search
                          SearchField(
                            hintText: AppStrings.searchSymptoms,
                            controller: _searchController,
                            onChanged: (val) {
                              setState(
                                  () => _showSuggestions = val.isNotEmpty);
                            },
                            onTap: () {
                              if (_searchController.text.isNotEmpty) {
                                setState(() => _showSuggestions = true);
                              }
                            },
                          ),

                          // Suggestions dropdown
                          if (_showSuggestions &&
                              _filteredSuggestions.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              constraints: const BoxConstraints(maxHeight: 150),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusSm),
                                border:
                                    Border.all(color: AppColors.cardBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadowMedium,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ListView(
                                shrinkWrap: true,
                                padding: EdgeInsets.zero,
                                children: _filteredSuggestions.map((s) {
                                  return ListTile(
                                    dense: true,
                                    title: Text(s.name,
                                        style: AppTextStyles.bodyMd),
                                    onTap: () =>
                                        _addSymptomFromSearch(s.name),
                                  );
                                }).toList(),
                              ),
                            ),

                          const SizedBox(height: AppSpacing.md),

                          // Selected chips
                          if (state.patient.symptoms.isNotEmpty)
                            MultiChipSelector(
                              selectedItems: state.patient.symptoms,
                              onRemove: notifier.removeSymptom,
                              onAdd: () {
                                // Focus the search field
                                FocusScope.of(context).nextFocus();
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Duration section
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.howLong,
                            style: AppTextStyles.labelLg.copyWith(
                              color: AppColors.primary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          DurationSelector(
                            options: const [
                              AppStrings.lessThan24h,
                              AppStrings.oneToThreeDays,
                              AppStrings.oneWeek,
                              AppStrings.moreThanOneWeek,
                            ],
                            selectedValue: state.patient.duration,
                            onSelected: notifier.updateDuration,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Medical History (text field)
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.history_rounded,
                                  color: AppColors.textSecondary, size: 18),
                              const SizedBox(width: AppSpacing.xs),
                              Text(AppStrings.medicalHistory,
                                  style: AppTextStyles.labelLg),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            maxLines: 3,
                            style: AppTextStyles.bodyMd,
                            decoration: InputDecoration(
                              hintText:
                                  'e.g. Diabetes, hypertension, allergies…',
                              hintStyle: AppTextStyles.bodyMd.copyWith(
                                color: AppColors.textTertiary,
                              ),
                              filled: true,
                              fillColor: AppColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusSm),
                                borderSide:
                                    BorderSide(color: AppColors.cardBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusSm),
                                borderSide:
                                    BorderSide(color: AppColors.cardBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusSm),
                                borderSide: BorderSide(
                                    color: AppColors.primary, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.all(AppSpacing.md),
                            ),
                            onChanged: notifier.updateMedicalHistory,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Privacy notice
                    const InfoBanner(text: AppStrings.privacyNotice),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),

            // Continue button (fixed at bottom)
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowMedium,
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: PrimaryButton(
                label: AppStrings.continueText,
                trailingIcon: Icons.arrow_forward,
                onPressed: () => context.push(RoutePaths.uploadImages),
              ),
            ),
          ],
        ),
      );
    }
  }
