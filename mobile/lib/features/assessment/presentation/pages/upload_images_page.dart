import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../../../shared/widgets/hipaa_badge.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/assessment_provider.dart';
import '../widgets/image_category_card.dart';
import '../widgets/image_preview_tile.dart';
import '../widgets/upload_progress.dart';

/// Upload Medical Images page (Screen 3).
class UploadImagesPage extends ConsumerWidget {
  const UploadImagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(assessmentProvider);
    final notifier = ref.read(assessmentProvider.notifier);

    return Scaffold(
      appBar: AppTopBar(
        title: AppStrings.appName,
        stepText: 'Step 2 of 3',
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
                  Text(AppStrings.uploadMedicalImages,
                      style: AppTextStyles.headingLg),
                  const SizedBox(height: AppSpacing.xs),
                  Text(AppStrings.uploadSubtitle,
                      style: AppTextStyles.bodyMd),
                  const SizedBox(height: AppSpacing.xxl),

                  // Category grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.1,
                    children: [
                      ImageCategoryCard(
                        label: AppStrings.skin,
                        icon: Icons.front_hand_outlined,
                        imageCount:
                            state.categoryImageCounts['skin'] ?? 0,
                        onUpload: () => _simulateImagePick(
                            notifier, 'skin'),
                        onCamera: () => _simulateImagePick(
                            notifier, 'skin'),
                      ),
                      ImageCategoryCard(
                        label: AppStrings.throat,
                        icon: Icons.air_outlined,
                        imageCount:
                            state.categoryImageCounts['throat'] ?? 0,
                        badgeColor: AppColors.primary,
                        onUpload: () => _simulateImagePick(
                            notifier, 'throat'),
                        onCamera: () => _simulateImagePick(
                            notifier, 'throat'),
                      ),
                      ImageCategoryCard(
                        label: AppStrings.eye,
                        icon: Icons.visibility_outlined,
                        imageCount:
                            state.categoryImageCounts['eye'] ?? 0,
                        onUpload: () =>
                            _simulateImagePick(notifier, 'eye'),
                        onCamera: () =>
                            _simulateImagePick(notifier, 'eye'),
                      ),
                      ImageCategoryCard(
                        label: AppStrings.wound,
                        icon: Icons.healing_outlined,
                        imageCount:
                            state.categoryImageCounts['wound'] ?? 0,
                        badgeColor: AppColors.error,
                        onUpload: () => _simulateImagePick(
                            notifier, 'wound'),
                        onCamera: () => _simulateImagePick(
                            notifier, 'wound'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Upload progress (show when there are images)
                  if (state.uploadedImagePaths.isNotEmpty) ...[
                    const UploadProgress(uploadedMb: 3, totalMb: 5),
                    const SizedBox(height: AppSpacing.xl),

                    // Preview section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppStrings.preview,
                            style: AppTextStyles.headingSm),
                        GestureDetector(
                          onTap: () => notifier.clearAllImages(),
                          child: Text(
                            AppStrings.clearAll,
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      height: 80,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ...state.uploadedImagePaths
                              .asMap()
                              .entries
                              .map((entry) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(right: AppSpacing.sm),
                              child: ImagePreviewTile(
                                imagePath: entry.value,
                                onRemove: () =>
                                    notifier.removeImage(entry.key),
                              ),
                            );
                          }),
                          AddImageTile(
                            onTap: () =>
                                _simulateImagePick(notifier, 'skin'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // HIPAA badge
                  const HipaaBadge(compact: true),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),

          // Analyze button
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
              label: AppStrings.analyzeHealthRisk,
              trailingIcon: Icons.search,
              onPressed: () => context.push(RoutePaths.analyzing),
            ),
          ),
        ],
      ),
    );
  }

  /// Simulate picking an image (mock data).
  void _simulateImagePick(
      AssessmentNotifier notifier, String category) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    notifier.addImage('mock_image_$id', category);
  }
}
