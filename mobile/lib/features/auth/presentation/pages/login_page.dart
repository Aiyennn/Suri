import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';

/// Login page — first screen unauthenticated users see.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMessage = null);

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email and password.');
      return;
    }

    await ref.read(authProvider.notifier).login(
          email: email,
          password: password,
        );

    // Navigation is handled by the GoRouter redirect — no context.go needed.
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    // Show backend error messages.
    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthError) {
        setState(() => _errorMessage = next.message);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xxl),

              // ── Header ─────────────────────────────────────────────────
              _buildHeader(),
              const SizedBox(height: AppSpacing.xxl),

              // ── Form ───────────────────────────────────────────────────
              _buildForm(),
              const SizedBox(height: AppSpacing.lg),

              // ── Error banner ───────────────────────────────────────────
              if (_errorMessage != null) _buildErrorBanner(),
              const SizedBox(height: AppSpacing.lg),

              // ── Sign in button ─────────────────────────────────────────
              PrimaryButton(
                label: AppStrings.signIn,
                trailingIcon: Icons.arrow_forward_rounded,
                isLoading: isLoading,
                onPressed: isLoading ? null : _submit,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // ── Register link ──────────────────────────────────────────
              _buildRegisterLink(),
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
        // App logo / icon
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: const Icon(
            Icons.medical_services_rounded,
            color: AppColors.textOnPrimary,
            size: 28,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(AppStrings.welcomeBack, style: AppTextStyles.headingLg),
        const SizedBox(height: AppSpacing.xs),
        Text(AppStrings.loginSubtitle, style: AppTextStyles.bodyMd),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Email
        Text(AppStrings.emailLabel, style: AppTextStyles.labelLg),
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
        Text(AppStrings.passwordLabel, style: AppTextStyles.labelLg),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
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

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(AppStrings.noAccount, style: AppTextStyles.bodyMd),
        TextButton(
          onPressed: () => context.push(RoutePaths.register),
          child: Text(
            AppStrings.signUp,
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
