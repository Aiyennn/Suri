import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// Single-select chip group (e.g., Male/Female/Other).
class ToggleSelector extends StatelessWidget {
  final List<String> options;
  final String? selectedValue;
  final ValueChanged<String> onSelected;

  const ToggleSelector({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((option) {
        final isSelected = option == selectedValue;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: option != options.last ? AppSpacing.sm : 0,
            ),
            child: GestureDetector(
              onTap: () => onSelected(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.cardBorder,
                  ),
                ),
                child: Center(
                  child: Text(
                    option,
                    style: AppTextStyles.labelMd.copyWith(
                      color: isSelected
                          ? AppColors.textOnPrimary
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
