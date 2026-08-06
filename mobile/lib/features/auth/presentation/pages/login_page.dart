import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../providers/auth_provider.dart';

// ── Screen-level design tokens ───────────────────────────────────────────────

/// Pale sky-blue page background.
const _kBgColor = Color(0xFFD4EBF8);

/// Dark navy used for the "Login" card heading and input text.
const _kCardHeadingColor = Color(0xFF1A237E);

/// Blue-grey used for field labels.
const _kFieldLabelColor = Color(0xFF607D8B);

/// Very-light blue fill for text fields.
const _kFieldFillColor = Color(0xFFEEF4FB);

/// Deep blue for the Login button.
const _kLoginBtnColor = Color(0xFF1A3A8C);

/// Muted blue-grey for the "Your medical companion" subtitle and footer text.
const _kSubtitleColor = Color(0xFF546E7A);



// ── Page ─────────────────────────────────────────────────────────────────────

/// Production-ready login screen for Suri — AI-powered medical companion.
///
/// Layout (top → bottom):
///   ┌────────────────────────────────────┐
///   │  Wave background  +  logo/name    │  fixed-height header
///   ├────────────────────────────────────┤
///   │           White card              │
///   │  Login heading                    │
///   │  Email field                      │
///   │  Password field                   │
///   │  Forgot Password?                 │
///   │  [icon]  [icon]  [icon]           │
///   │  ──────── Login button ─────────  │
///   │  Don't have an account? Sign Up   │
///   └────────────────────────────────────┘
///
/// Callback stubs ready to connect without touching the UI layer:
///   [_onLogin], [_onForgotPassword], [_onSignUp]
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  // ── Form ──────────────────────────────────────────────────────────────────
  final _formKey             = GlobalKey<FormState>();
  final _emailController     = TextEditingController();
  final _passwordController  = TextEditingController();
  final _emailFocus          = FocusNode();
  final _passwordFocus       = FocusNode();

  bool    _obscurePassword = true;
  bool    _isFormValid     = false;
  String? _errorMessage;

  // ── Entry animation ───────────────────────────────────────────────────────
  late final AnimationController _entryController;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  // ── Validators ────────────────────────────────────────────────────────────

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email address is required.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required.';
    if (v.length < 8) return 'Password must be at least 8 characters.';
    return null;
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
    ));

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _entryController.forward(),
    );

    _emailController.addListener(_checkFormValidity);
    _passwordController.addListener(_checkFormValidity);
  }

  void _checkFormValidity() {
    final valid = _validateEmail(_emailController.text) == null &&
        _validatePassword(_passwordController.text) == null;
    if (valid != _isFormValid) setState(() => _isFormValid = valid);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _emailController
      ..removeListener(_checkFormValidity)
      ..dispose();
    _passwordController
      ..removeListener(_checkFormValidity)
      ..dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ── Callbacks ─────────────────────────────────────────────────────────────

  Future<void> _onLogin() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _errorMessage = null);
    await ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    // GoRouter redirect guard handles navigation on success.
  }

  void _onForgotPassword() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Password reset flow coming soon.'),
        backgroundColor: AppColors.surfaceDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
    );
  }

  void _onSignUp() => context.push(RoutePaths.register);

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthError) setState(() => _errorMessage = next.message);
    });

    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: _kBgColor,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusScope.of(context).unfocus(),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: AutofillGroup(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      // ── Wave header ────────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: topPadding + 270,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(painter: _WavePainter()),
                            ),
                            Positioned(
                              top: topPadding + 14,
                              left: 0,
                              right: 0,
                              child: const _SuriLogoSection(),
                            ),
                          ],
                        ),
                      ),

                      // ── Login card ─────────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        child: _LoginCard(
                          emailController:    _emailController,
                          passwordController: _passwordController,
                          emailFocus:         _emailFocus,
                          passwordFocus:      _passwordFocus,
                          obscurePassword:    _obscurePassword,
                          isFormValid:        _isFormValid,
                          isLoading:          isLoading,
                          errorMessage:       _errorMessage,
                          onTogglePassword:   () => setState(() =>
                              _obscurePassword = !_obscurePassword),
                          onLogin:            _isFormValid && !isLoading
                              ? _onLogin
                              : null,
                          onForgotPassword:   _onForgotPassword,
                          onSignUp:           _onSignUp,
                          onDismissError:     () =>
                              setState(() => _errorMessage = null),
                          validateEmail:      _validateEmail,
                          validatePassword:   _validatePassword,
                          onEmailComplete:    () => FocusScope.of(context)
                              .requestFocus(_passwordFocus),
                          onPasswordComplete: _isFormValid ? _onLogin : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Wave background ───────────────────────────────────────────────────────────

/// Draws two overlapping white ribbon shapes on the light-blue header.
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    void fill(Color color, Path path) => canvas.drawPath(
          path,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );

    // Back wave — wider blob covering the upper-right quadrant.
    fill(
      Colors.white.withValues(alpha: 0.38),
      Path()
        ..moveTo(w * 0.50, 0)
        ..lineTo(w, 0)
        ..lineTo(w, h * 0.55)
        ..cubicTo(
            w * 0.75, h * 0.72, w * 0.45, h * 0.65, w * 0.30, h * 0.70)
        ..cubicTo(
            w * 0.12, h * 0.76, 0, h * 0.62, 0, h * 0.46)
        ..cubicTo(
            0, h * 0.22, w * 0.22, h * 0.08, w * 0.50, h * 0.05)
        ..close(),
    );

    // Front wave — tighter horizontal ribbon across the top.
    fill(
      Colors.white.withValues(alpha: 0.60),
      Path()
        ..moveTo(0, 0)
        ..lineTo(w, 0)
        ..lineTo(w, h * 0.22)
        ..cubicTo(
            w * 0.72, h * 0.38, w * 0.45, h * 0.28, w * 0.30, h * 0.34)
        ..cubicTo(
            w * 0.14, h * 0.40, 0, h * 0.30, 0, h * 0.20)
        ..close(),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Logo + wordmark section ───────────────────────────────────────────────────

class _SuriLogoSection extends StatelessWidget {
  const _SuriLogoSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Suri logo asset
        Image.asset(
          'assets/images/suri_logo.png',
          width: 150,
          height: 150,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const _FallbackLogo(),
        ),
        const SizedBox(height: 8),

        // Tagline
        Text(
          'Your medical companion',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: _kSubtitleColor,
          ),
        ),
      ],
    );
  }
}

/// Gradient circle shown when the logo asset cannot be loaded.
class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.loginButtonGradient,
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.medical_services_rounded,
        color: Colors.white,
        size: 56,
      ),
    );
  }
}

// ── Login card ────────────────────────────────────────────────────────────────

class _LoginCard extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final FocusNode emailFocus;
  final FocusNode passwordFocus;
  final bool obscurePassword;
  final bool isFormValid;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onTogglePassword;
  final VoidCallback? onLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onSignUp;
  final VoidCallback onDismissError;
  final FormFieldValidator<String> validateEmail;
  final FormFieldValidator<String> validatePassword;
  final VoidCallback onEmailComplete;
  final VoidCallback? onPasswordComplete;

  const _LoginCard({
    required this.emailController,
    required this.passwordController,
    required this.emailFocus,
    required this.passwordFocus,
    required this.obscurePassword,
    required this.isFormValid,
    required this.isLoading,
    required this.errorMessage,
    required this.onTogglePassword,
    required this.onLogin,
    required this.onForgotPassword,
    required this.onSignUp,
    required this.onDismissError,
    required this.validateEmail,
    required this.validatePassword,
    required this.onEmailComplete,
    required this.onPasswordComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF90CAF9).withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Heading ──────────────────────────────────────────────────
          Text(
            'Login',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: _kCardHeadingColor,
            ),
          ),
          const SizedBox(height: 20),

          // ── Email ────────────────────────────────────────────────────
          const _FieldLabel('Email'),
          const SizedBox(height: 8),
          _CardTextField(
            controller:       emailController,
            focusNode:        emailFocus,
            hintText:         'Enter your email',
            keyboardType:     TextInputType.emailAddress,
            textInputAction:  TextInputAction.next,
            autofillHints:    const [AutofillHints.email],
            validator:        validateEmail,
            onEditingComplete: onEmailComplete,
          ),
          const SizedBox(height: 16),

          // ── Password ─────────────────────────────────────────────────
          const _FieldLabel('Password'),
          const SizedBox(height: 8),
          _CardTextField(
            controller:       passwordController,
            focusNode:        passwordFocus,
            hintText:         'Enter your password',
            keyboardType:     TextInputType.visiblePassword,
            textInputAction:  TextInputAction.done,
            autofillHints:    const [AutofillHints.password],
            obscureText:      obscurePassword,
            validator:        validatePassword,
            onEditingComplete: onPasswordComplete,
            suffixIcon: IconButton(
              icon: Icon(
                obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: _kFieldLabelColor,
              ),
              onPressed: onTogglePassword,
              tooltip: obscurePassword ? 'Show password' : 'Hide password',
            ),
          ),

          // ── Forgot password ──────────────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onForgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                minimumSize: const Size(48, 44),
                padding: const EdgeInsets.only(left: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot Password?',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),



          // ── Error banner ─────────────────────────────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: errorMessage != null
                ? _ErrorBanner(
                    message:   errorMessage!,
                    onDismiss: onDismissError,
                  )
                : const SizedBox.shrink(),
          ),
          if (errorMessage != null) const SizedBox(height: 12),

          // ── Login button ─────────────────────────────────────────────
          _LoginButton(
            isLoading:  isLoading,
            isEnabled:  isFormValid && !isLoading,
            onPressed:  onLogin,
          ),
          const SizedBox(height: 20),

          // ── Sign Up footer ───────────────────────────────────────────
          _SignUpLink(onSignUp: onSignUp),
        ],
      ),
    );
  }
}

// ── Field label ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: _kFieldLabelColor,
      ),
    );
  }
}

// ── Card text field ───────────────────────────────────────────────────────────

/// Borderless, lightly-filled text field styled for the login card.
class _CardTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final List<String>? autofillHints;
  final bool obscureText;
  final FormFieldValidator<String>? validator;
  final VoidCallback? onEditingComplete;
  final Widget? suffixIcon;

  const _CardTextField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.keyboardType       = TextInputType.text,
    this.textInputAction    = TextInputAction.next,
    this.autofillHints,
    this.obscureText        = false,
    this.validator,
    this.onEditingComplete,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:        controller,
      focusNode:         focusNode,
      keyboardType:      keyboardType,
      textInputAction:   textInputAction,
      obscureText:       obscureText,
      autofillHints:     autofillHints,
      autocorrect:       false,
      enableSuggestions: !obscureText,
      validator:         validator,
      onEditingComplete: onEditingComplete,
      style: GoogleFonts.inter(fontSize: 15, color: _kCardHeadingColor),
      decoration: InputDecoration(
        hintText:  hintText,
        hintStyle: GoogleFonts.inter(
          fontSize: 15,
          color:    const Color(0xFFB0BEC5),
        ),
        filled:         true,
        fillColor:      _kFieldFillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical:   14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 12,
          color:    AppColors.error,
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}


// ── Login button ──────────────────────────────────────────────────────────────

/// Deep-blue pill button with a sparkle icon and a press-scale micro-animation.
class _LoginButton extends StatefulWidget {
  final bool isLoading;
  final bool isEnabled;
  final VoidCallback? onPressed;

  const _LoginButton({
    required this.isLoading,
    required this.isEnabled,
    required this.onPressed,
  });

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double>   _scaleAnim;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve:  Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.isEnabled) _scaleController.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _scaleController.reverse();
    if (widget.isEnabled) widget.onPressed?.call();
  }

  void _onTapCancel() => _scaleController.reverse();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button:  true,
      label:   'Login',
      enabled: widget.isEnabled,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: GestureDetector(
          onTapDown:   _onTapDown,
          onTapUp:     _onTapUp,
          onTapCancel: _onTapCancel,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 54,
            width:  double.infinity,
            decoration: BoxDecoration(
              color: widget.isEnabled
                  ? _kLoginBtnColor
                  : _kLoginBtnColor.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(100),
              boxShadow: widget.isEnabled
                  ? [
                      BoxShadow(
                        color: _kLoginBtnColor.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: widget.isLoading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      child: Center(
                        child: SizedBox(
                          width:  24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth:  2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Center(
                      key: const ValueKey('label'),
                      child: Text(
                        'Login',
                        style: GoogleFonts.inter(
                          fontSize:     17,
                          fontWeight:   FontWeight.w700,
                          color:        Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:        AppColors.errorLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size:  18,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color:    AppColors.error,
                  height:   1.5,
                ),
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.error,
                size:  18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sign-up footer ────────────────────────────────────────────────────────────

class _SignUpLink extends StatelessWidget {
  final VoidCallback onSignUp;
  const _SignUpLink({required this.onSignUp});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "Don't have an account? Tap Sign Up to create an account.",
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account?",
            style: GoogleFonts.inter(fontSize: 14, color: _kSubtitleColor),
          ),
          TextButton(
            onPressed: onSignUp,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize:     const Size(48, 44),
              padding:         const EdgeInsets.only(left: 4),
              tapTargetSize:   MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Sign Up',
              style: GoogleFonts.inter(
                fontSize:   14,
                fontWeight: FontWeight.w700,
                color:      AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
