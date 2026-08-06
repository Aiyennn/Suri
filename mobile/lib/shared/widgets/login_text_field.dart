import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

/// A premium text field designed for authentication screens.
///
/// Features:
/// - Animated focus ring (border colour transition)
/// - Inline validation message with animated fade-in
/// - Show / hide password toggle
/// - Autofill hint support
/// - Screen-reader friendly semantic labels
/// - Minimum 48 dp touch target for accessibility
class LoginTextField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final List<String>? autofillHints;
  final bool isPassword;
  final String? Function(String?)? validator;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onChanged;

  const LoginTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.isPassword = false,
    this.validator,
    this.onEditingComplete,
    this.onChanged,
  });

  @override
  State<LoginTextField> createState() => _LoginTextFieldState();
}

class _LoginTextFieldState extends State<LoginTextField>
    with SingleTickerProviderStateMixin {
  bool _obscureText = true;
  bool _isFocused = false;
  String? _errorText;

  late final AnimationController _focusAnimController;

  @override
  void initState() {
    super.initState();

    _focusAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    widget.focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    final focused = widget.focusNode.hasFocus;
    setState(() => _isFocused = focused);
    if (focused) {
      _focusAnimController.forward();
    } else {
      _focusAnimController.reverse();
      // Validate on blur.
      if (widget.validator != null) {
        setState(() {
          _errorText = widget.validator!(widget.controller.text);
        });
      }
    }
  }

  void _validate() {
    if (widget.validator != null) {
      setState(() {
        _errorText = widget.validator!(widget.controller.text);
      });
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    _focusAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasError = _errorText != null && _errorText!.isNotEmpty;

    // Resolve border colour based on state.
    final Color borderColor = hasError
        ? AppColors.error
        : _isFocused
            ? AppColors.primary
            : isDark
                ? AppColors.cardBorderDark
                : AppColors.cardBorder;

    final double borderWidth = _isFocused || hasError ? 1.5 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Field label ──────────────────────────────────────────────────
        Text(
          widget.label,
          style: AppTextStyles.labelLg.copyWith(
            color: isDark ? Colors.white.withValues(alpha: 0.87) : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // ── Animated border container ────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: borderColor, width: borderWidth),
            color: isDark ? AppColors.surfaceDark : AppColors.surface,
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: AppColors.shadowLight,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            obscureText: widget.isPassword && _obscureText,
            autofillHints: widget.autofillHints,
            autocorrect: false,
            enableSuggestions: !widget.isPassword,
            style: AppTextStyles.bodyLg.copyWith(
              color: isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.textPrimary,
              fontSize: 15,
            ),
            onChanged: (value) {
              widget.onChanged?.call(value);
              // Clear error as user types.
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
            onEditingComplete: () {
              _validate();
              widget.onEditingComplete?.call();
            },
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: AppTextStyles.bodyMd.copyWith(
                color: AppColors.textTertiary,
              ),
              // Suppress the default border since we draw our own.
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md + 2,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.sm),
                child: Icon(
                  widget.prefixIcon,
                  size: AppSpacing.iconMd,
                  color: _isFocused
                      ? AppColors.primary
                      : hasError
                          ? AppColors.error
                          : AppColors.textTertiary,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              suffixIcon: widget.isPassword
                  ? Semantics(
                      label: _obscureText ? 'Show password' : 'Hide password',
                      child: IconButton(
                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: AppSpacing.iconMd,
                          color: _isFocused
                              ? AppColors.primary
                              : AppColors.textTertiary,
                        ),
                        onPressed: () =>
                            setState(() => _obscureText = !_obscureText),
                        tooltip:
                            _obscureText ? 'Show password' : 'Hide password',
                      ),
                    )
                  : null,
            ),
          ),
        ),

        // ── Inline validation message ────────────────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.xs,
                    left: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 14,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _errorText!,
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
