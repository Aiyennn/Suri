import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Upload progress indicator with dots and text.
class UploadProgress extends StatefulWidget {
  final int uploadedMb;
  final int totalMb;

  const UploadProgress({
    super.key,
    required this.uploadedMb,
    required this.totalMb,
  });

  @override
  State<UploadProgress> createState() => _UploadProgressState();
}

class _UploadProgressState extends State<UploadProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Animated dots
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Row(
              children: List.generate(3, (index) {
                final delay = index * 0.2;
                final opacity = ((_controller.value + delay) % 1.0);
                return Padding(
                  padding: const EdgeInsets.only(right: 3),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: 0.3 + (opacity * 0.7),
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }),
            );
          },
        ),
        const SizedBox(width: 8),
        Text(
          'Uploading...',
          style: AppTextStyles.bodySm.copyWith(color: AppColors.primary),
        ),
        const Spacer(),
        Text(
          '${widget.uploadedMb} of ${widget.totalMb} MB uploaded',
          style: AppTextStyles.bodySm,
        ),
      ],
    );
  }
}
