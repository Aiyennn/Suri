import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Upload progress indicator with an animated linear progress bar,
/// animated dots, and a dynamic byte counter.
class UploadProgress extends StatefulWidget {
  /// Upload progress as a fraction in [0.0, 1.0].
  final double progress;

  /// Number of bytes uploaded so far.
  final int uploadedBytes;

  /// Total number of bytes to upload.
  final int totalBytes;

  const UploadProgress({
    super.key,
    required this.progress,
    required this.uploadedBytes,
    required this.totalBytes,
  });

  @override
  State<UploadProgress> createState() => _UploadProgressState();
}

class _UploadProgressState extends State<UploadProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  /// Format bytes into a human-readable string (e.g. "1.2 MB").
  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final percent = (widget.progress * 100).clamp(0, 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: animated dots + status + percentage
        Row(
          children: [
            // Animated dots
            AnimatedBuilder(
              animation: _dotController,
              builder: (context, _) {
                return Row(
                  children: List.generate(3, (index) {
                    final delay = index * 0.2;
                    final opacity = ((_dotController.value + delay) % 1.0);
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
              '$percent%',
              style: AppTextStyles.bodySm.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: widget.progress),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.primary),
              );
            },
          ),
        ),
        const SizedBox(height: 6),

        // Bottom row: byte counter
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '${_formatBytes(widget.uploadedBytes)} of ${_formatBytes(widget.totalBytes)} uploaded',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
