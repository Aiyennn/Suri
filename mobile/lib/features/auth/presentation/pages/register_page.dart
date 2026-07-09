import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

/// Registration page — lets new users create an account.
class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  // Optional fields
  String? _selectedSex;
  final _medicalHistoryController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _medicalHistoryController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Full name, email, and password are required.');
      return;
    }

    if (password.length < 8) {
      setState(
          () => _errorMessage = 'Password must be at least 8 characters.');
      return;
    }

    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    await ref.read(authProvider.notifier).register(
          email: email,
          password: password,
          fullName: fullName,
          sex: _selectedSex,
          medicalHistory: _medicalHistoryController.text.trim().isEmpty
              ? null
              : _medicalHistoryController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthError) {
        setState(() => _errorMessage = next.message);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────
              _buildHeader(),
              const SizedBox(height: AppSpacing.xxl),

              // ── Required fields ────────────────────────────────────────
              _buildRequiredSection(),
              const SizedBox(height: AppSpacing.lg),

              // ── Optional fields ────────────────────────────────────────
              _buildOptionalSection(),
              const SizedBox(height: AppSpacing.lg),

              // ── Error banner ───────────────────────────────────────────
              if (_errorMessage != null) _buildErrorBanner(),
              const SizedBox(height: AppSpacing.lg),

              // ── Create account button ──────────────────────────────────
              PrimaryButton(
                label: AppStrings.createAccount,
                trailingIcon: Icons.arrow_forward_rounded,
                isLoading: isLoading,
                onPressed: isLoading ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── Login link ─────────────────────────────────────────────
              _buildLoginLink(),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.createAccountTitle, style: AppTextStyles.headingLg),
        const SizedBox(height: AppSpacing.xs),
        Text(AppStrings.registerSubtitle, style: AppTextStyles.bodyMd),
      ],
    );
  }

  Widget _buildRequiredSection() {
    return _SectionCard(
      children: [
        // Full name
        _FieldLabel(AppStrings.fullNameLabel),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _fullNameController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: AppStrings.fullNameHint,
            prefixIcon: const Icon(Icons.person_outline_rounded,
                color: AppColors.textTertiary, size: 20),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Email
        _FieldLabel(AppStrings.emailLabel),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: AppStrings.emailHint,
            prefixIcon: const Icon(Icons.email_outlined,
                color: AppColors.textTertiary, size: 20),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Password
        _FieldLabel(AppStrings.passwordLabel),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: AppStrings.passwordHint,
            prefixIcon: const Icon(Icons.lock_outlined,
                color: AppColors.textTertiary, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textTertiary,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Confirm password
        _FieldLabel(AppStrings.confirmPasswordLabel),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirm,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: AppStrings.confirmPasswordHint,
            prefixIcon: const Icon(Icons.lock_outlined,
                color: AppColors.textTertiary, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textTertiary,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionalSection() {
    return _SectionCard(
      children: [
        Row(
          children: [
            const Icon(Icons.person_2_outlined,
                color: AppColors.textSecondary, size: 18),
            const SizedBox(width: AppSpacing.xs),
            Text(AppStrings.optionalInfo,
                style: AppTextStyles.labelLg.copyWith(
                  color: AppColors.textSecondary,
                )),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // Sex selector
        _FieldLabel(AppStrings.sexAtBirth),
        const SizedBox(height: AppSpacing.sm),
        _SexSelector(
          selected: _selectedSex,
          onSelected: (v) => setState(() => _selectedSex = v),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Medical history
        _FieldLabel(AppStrings.medicalHistory),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _medicalHistoryController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g. Diabetes, hypertension, allergies…',
            hintStyle:
                AppTextStyles.bodyMd.copyWith(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide: const BorderSide(color: AppColors.cardBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.md),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(AppStrings.haveAccount, style: AppTextStyles.bodyMd),
        TextButton(
          onPressed: () => context.pop(),
          child: Text(
            AppStrings.signIn,
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Private helper widgets ─────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTextStyles.labelLg);
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _SexSelector extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _SexSelector({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    const options = [AppStrings.male, AppStrings.female, AppStrings.other];
    return Row(
      children: options.map((opt) {
        final isSelected = selected == opt;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: opt != options.last ? AppSpacing.sm : 0,
            ),
            child: GestureDetector(
              onTap: () => onSelected(isSelected ? null : opt),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.chipSelectedBg
                      : AppColors.chipBg,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.cardBorder,
                  ),
                ),
                child: Text(
                  opt,
                  style: AppTextStyles.bodySm.copyWith(
                    color: isSelected
                        ? AppColors.textOnPrimary
                        : AppColors.chipText,
                    fontWeight: FontWeight.w600,
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
