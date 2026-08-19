import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../providers/assessment_provider.dart';

/// Upload Supporting Images page (Step 2 of 3).
///
/// Single unified upload area — replaces the old four-category grid.
/// Users can pick images from gallery or camera.  Previews show below
/// the drop zone with individual remove buttons.
class UploadImagesPage extends ConsumerStatefulWidget {
  const UploadImagesPage({super.key});

  @override
  ConsumerState<UploadImagesPage> createState() => _UploadImagesPageState();
}

class _UploadImagesPageState extends ConsumerState<UploadImagesPage> {
  bool _dropHover = false; // visual feedback for drag hover

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final List<XFile> picked = await picker.pickMultiImage(imageQuality: 85);
    if (!mounted) return;
    for (final file in picked) {
      ref.read(assessmentProvider.notifier).addImage(file.path, 'general');
    }
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final XFile? picked =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (!mounted || picked == null) return;
    ref.read(assessmentProvider.notifier).addImage(picked.path, 'general');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(assessmentProvider);
    final images = state.uploadedImagePaths;
    final notifier = ref.read(assessmentProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppTopBar(
        title: 'Suri',
        stepText: 'Step 2 of 3',
        showBack: true,
        onBack: () => context.pop(),
      ),
      body: Column(
        children: [
          // ── Step progress bar ──────────────────────────────────────────
          _StepBar(current: 2),

          // ── Scrollable body ────────────────────────────────────────────
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
                  // ── Hero header ──────────────────────────────────────
                  _HeroHeader(),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Drop zone ────────────────────────────────────────
                  _DropZone(
                    isHovered: _dropHover,
                    onBrowseTap: _pickFromGallery,
                    onCameraTap: _pickFromCamera,
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // ── Image previews ───────────────────────────────────
                  if (images.isNotEmpty) ...[
                    _PreviewHeader(
                      count: images.length,
                      onClearAll: notifier.clearAllImages,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ImageGrid(
                      paths: images,
                      onRemove: (i) => notifier.removeImage(i),
                      onAdd: _pickFromGallery,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],

                  // ── Tips card ────────────────────────────────────────
                  _TipsCard(),
                ],
              ),
            ),
          ),

          // ── Pinned bottom bar ──────────────────────────────────────────
          _BottomBar(
            canContinue: images.isNotEmpty,
            onBack: () => context.pop(),
            onContinue: () => context.push(RoutePaths.analyzing),
          ),
        ],
      ),
    );
  }
}

// ── Step progress bar ─────────────────────────────────────────────────────────

class _StepBar extends StatelessWidget {
  final int current;
  const _StepBar({required this.current});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      child: Row(
        children: List.generate(3, (i) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
              height: 3,
              decoration: BoxDecoration(
                color: i < current ? AppColors.primary : const Color(0xFFDDE3EF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Hero header ───────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Cloud upload illustration
        _CloudIllustration(),
        const SizedBox(width: AppSpacing.lg),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upload Supporting\nImages',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Add clear images to help us provide you with the most accurate assessment.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Cloud illustration ────────────────────────────────────────────────────────

class _CloudIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Back photo frame (rotated)
          Positioned(
            top: 0,
            right: 0,
            child: Transform.rotate(
              angle: 0.3,
              child: Container(
                width: 38,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E7FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.image_outlined,
                    size: 18, color: Color(0xFF818CF8)),
              ),
            ),
          ),
          // Front photo frame (slight opposite tilt)
          Positioned(
            top: 8,
            left: 0,
            child: Transform.rotate(
              angle: -0.2,
              child: Container(
                width: 38,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFC7D2FE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.image_rounded,
                    size: 18, color: Color(0xFF6366F1)),
              ),
            ),
          ),
          // Cloud with up-arrow
          Positioned(
            bottom: 0,
            left: 14,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.cloud_upload_outlined,
                  size: 24, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Drop zone ─────────────────────────────────────────────────────────────────

class _DropZone extends StatelessWidget {
  final bool isHovered;
  final VoidCallback onBrowseTap;
  final VoidCallback onCameraTap;

  const _DropZone({
    required this.isHovered,
    required this.onBrowseTap,
    required this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.xxxl,
        horizontal: AppSpacing.xxl,
      ),
      decoration: BoxDecoration(
        color: isHovered
            ? AppColors.primaryLight
            : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isHovered
              ? AppColors.primary
              : const Color(0xFFD0D5E8),
          width: 1.5,
          // Dashed border simulated via the decoration below
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Upload icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.cloud_upload_outlined,
              size: 28,
              color: const Color(0xFF7C7CF8),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text(
            'Drag and drop images here',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'or',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Browse Files button
          GestureDetector(
            onTap: onBrowseTap,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_library_outlined,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Browse Files',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Format + size note
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'JPG, PNG, HEIC  up to 10MB each',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(width: 4),
              Tooltip(
                message:
                    'High-quality, well-lit photos improve AI analysis accuracy.',
                child: Icon(Icons.info_outline_rounded,
                    size: 13, color: AppColors.textTertiary),
              ),
            ],
          ),

          // Camera shortcut
          const SizedBox(height: AppSpacing.md),
          GestureDetector(
            onTap: onCameraTap,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt_outlined,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 5),
                Text(
                  'Take a photo instead',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Preview header ────────────────────────────────────────────────────────────

class _PreviewHeader extends StatelessWidget {
  final int count;
  final VoidCallback onClearAll;

  const _PreviewHeader({required this.count, required this.onClearAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Uploaded Images',
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onClearAll,
          child: Text(
            'Clear all',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Image preview grid ────────────────────────────────────────────────────────

class _ImageGrid extends StatelessWidget {
  final List<String> paths;
  final ValueChanged<int> onRemove;
  final VoidCallback onAdd;

  const _ImageGrid({
    required this.paths,
    required this.onRemove,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1,
      ),
      itemCount: paths.length + 1, // +1 for Add tile
      itemBuilder: (context, i) {
        if (i == paths.length) {
          // Add more tile
          return GestureDetector(
            onTap: onAdd,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                    color: const Color(0xFFD0D5E8), width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 24, color: AppColors.primary),
                  const SizedBox(height: 4),
                  Text(
                    'Add more',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Image tile
        return _ImageTile(path: paths[i], onRemove: () => onRemove(i));
      },
    );
  }
}

// ── Single image preview tile ─────────────────────────────────────────────────

class _ImageTile extends StatelessWidget {
  final String path;
  final VoidCallback onRemove;

  const _ImageTile({required this.path, required this.onRemove});

  Widget _buildImage() {
    if (kIsWeb ||
        path.startsWith('http://') ||
        path.startsWith('https://') ||
        path.startsWith('blob:')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.primaryLight,
          child: const Icon(Icons.broken_image_outlined,
              color: AppColors.primary),
        ),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.primaryLight,
        child: const Icon(Icons.broken_image_outlined,
            color: AppColors.primary),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image
        ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: _buildImage(),
        ),
        // Remove button
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded,
                  size: 13, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Tips card ─────────────────────────────────────────────────────────────────

class _TipsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const tips = [
      'Use good lighting — avoid shadows or glare',
      'Keep the camera steady and close to the area',
      'Include surrounding healthy tissue for context',
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: const Color(0xFFD0D5E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline_rounded,
                  size: 16, color: Color(0xFFF59E0B)),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Photo Tips for Best Results',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...tips.map((t) => Padding(
                padding: const EdgeInsets.only(top: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.textTertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        t,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ── Bottom navigation bar ─────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final bool canContinue;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const _BottomBar({
    required this.canContinue,
    required this.onBack,
    required this.onContinue,
  });

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
      child: Row(
        children: [
          // Back pill
          GestureDetector(
            onTap: onBack,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6FB),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(color: const Color(0xFFDDE3EF)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back_rounded,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Back',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Continue button
          Expanded(
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: canContinue ? 1.0 : 0.45,
              child: GestureDetector(
                onTap: canContinue ? onContinue : null,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusFull),
                    boxShadow: canContinue
                        ? [
                            BoxShadow(
                              color:
                                  AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Analyze Now',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded,
                          size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
