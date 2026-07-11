import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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
/// Only the "Wound" category is enabled for upload; all others are
/// shown but disabled per the product requirement.
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
                  Text(
                    'Upload a clear photo of the wound for AI analysis. '
                    'High-quality lighting improves accuracy.',
                    style: AppTextStyles.bodyMd,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Category grid – only Wound is enabled
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.1,
                    children: [
                      // ── Skin (disabled) ──────────────────────────────────
                      const ImageCategoryCard(
                        label: AppStrings.skin,
                        icon: Icons.front_hand_outlined,
                        imageCount: 0,
                        disabled: true,
                      ),

                      // ── Throat (disabled) ────────────────────────────────
                      const ImageCategoryCard(
                        label: AppStrings.throat,
                        icon: Icons.air_outlined,
                        imageCount: 0,
                        badgeColor: AppColors.primary,
                        disabled: true,
                      ),

                      // ── Eye (disabled) ───────────────────────────────────
                      const ImageCategoryCard(
                        label: AppStrings.eye,
                        icon: Icons.visibility_outlined,
                        imageCount: 0,
                        disabled: true,
                      ),

                      // ── Wound (ENABLED) ──────────────────────────────────
                      ImageCategoryCard(
                        label: AppStrings.wound,
                        icon: Icons.healing_outlined,
                        imageCount:
                            state.categoryImageCounts['wound'] ?? 0,
                        badgeColor: AppColors.error,
                        onUpload: () =>
                            _pickImage(notifier, ImageSource.gallery),
                        onCamera: () =>
                            _pickImage(notifier, ImageSource.camera),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Upload progress (show when there are images)
                  if (state.uploadedImagePaths.isNotEmpty) ...[
                    UploadProgress(
                      progress: state.uploadProgress,
                      uploadedBytes: state.uploadedBytes,
                      totalBytes: state.totalBytes,
                    ),
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
                              padding: const EdgeInsets.only(
                                  right: AppSpacing.sm),
                              child: ImagePreviewTile(
                                imagePath: entry.value,
                                onRemove: () =>
                                    notifier.removeImage(entry.key),
                              ),
                            );
                          }),
                          AddImageTile(
                            onTap: () =>
                                _pickImage(notifier, ImageSource.gallery),
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
              onPressed: state.uploadedImagePaths.isEmpty
                  ? null
                  : () => context.push(RoutePaths.analyzing),
            ),
          ),
        ],
      ),
    );
  }

  /// Open the device gallery or camera and store the selected image path.
  Future<void> _pickImage(
      AssessmentNotifier notifier, ImageSource source) async {
    final picker = ImagePicker();
    final XFile? picked =
        await picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      notifier.addImage(picked.path, 'wound');
    }
  }
}
