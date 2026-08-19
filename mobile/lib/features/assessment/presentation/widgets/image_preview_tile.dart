import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';

/// Thumbnail preview of an uploaded image with remove button.
class ImagePreviewTile extends StatelessWidget {
  final String imagePath;
  final VoidCallback? onRemove;

  const ImagePreviewTile({
    super.key,
    required this.imagePath,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            border: Border.all(color: AppColors.cardBorder),
            color: AppColors.primaryLight,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm - 1),
            child: _buildImage(),
          ),
        ),
        // Remove button
        if (onRemove != null)
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImage() {
    if (kIsWeb ||
        imagePath.startsWith('http://') ||
        imagePath.startsWith('https://') ||
        imagePath.startsWith('blob:')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        width: 72,
        height: 72,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.primaryLight,
          child: const Icon(
            Icons.broken_image_outlined,
            color: AppColors.primary,
            size: 28,
          ),
        ),
      );
    }
    // Check if the path is a file path
    final file = File(imagePath);
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        width: 72,
        height: 72,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.primaryLight,
          child: const Icon(
            Icons.broken_image_outlined,
            color: AppColors.primary,
            size: 28,
          ),
        ),
      );
    }
    // Placeholder for mock images
    return Container(
      color: AppColors.primaryLight,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.primary,
        size: 28,
      ),
    );
  }
}

/// "Add" tile for adding more images.
class AddImageTile extends StatelessWidget {
  final VoidCallback? onTap;

  const AddImageTile({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: AppColors.cardBorder,
            style: BorderStyle.solid,
          ),
          color: AppColors.background,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: AppColors.textTertiary,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              'Add',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
