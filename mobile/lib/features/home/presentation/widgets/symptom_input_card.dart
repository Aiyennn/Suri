import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../data/chatbot_repository.dart';
import '../../models/chatbot_response.dart';

// ── Intent constants ──────────────────────────────────────────────────────────

const _intentWound = 'wound_assessment';
const _intentSkin = 'skin_assessment';
const _intentSymptom = 'symptom_assessment';
const _intentClarify = 'needs_clarification';
// general_conversation → no CTA needed

// ── Data model ────────────────────────────────────────────────────────────────

enum _MessageRole { user, ai }

class _ChatMessage {
  final _MessageRole role;
  final String text;

  /// Non-null when the AI message should include an assessment CTA.
  /// Value is one of the _intent* constants.
  final String? assessmentIntent;

  const _ChatMessage({
    required this.role,
    required this.text,
    this.assessmentIntent,
  });
}

// ── Main widget ───────────────────────────────────────────────────────────────

/// Chat-style input card backed by the Gemini chatbot API.
///
/// Displays a scrollable conversation log above the text input.
/// When Gemini identifies a specific assessment intent, the AI message
/// includes a styled action button that calls [onAssessmentSelected].
class SymptomInputCard extends StatefulWidget {
  /// Called when the user taps an assessment CTA button.
  /// [text] is the user's original message.
  final void Function(String text) onSend;

  /// The authenticated user's JWT token — required for API calls.
  final String token;

  const SymptomInputCard({
    super.key,
    required this.onSend,
    required this.token,
  });

  @override
  State<SymptomInputCard> createState() => _SymptomInputCardState();
}

class _SymptomInputCardState extends State<SymptomInputCard> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  final _repo = ChatbotRepository();

  bool _hasText = false;
  bool _isTyping = false;
  String? _sessionId;

  final List<_ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isTyping) return;
    _controller.clear();
    _focusNode.unfocus();

    setState(() {
      _messages.add(_ChatMessage(role: _MessageRole.user, text: text));
      _isTyping = true;
    });
    _scrollToBottom();

    try {
      final ChatbotResponse response = await _repo.sendMessage(
        message: text,
        sessionId: _sessionId,
        token: widget.token,
      );

      _sessionId = response.sessionId;

      // Determine whether this intent warrants a CTA
      final String? intent = _ctaIntent(response.intent);

      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          role: _MessageRole.ai,
          text: response.reply,
          assessmentIntent: intent,
        ));
      });
    } on ChatbotException catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(
          role: _MessageRole.ai,
          text: "I'm sorry, I couldn't process that right now. ${e.message}",
        ));
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _messages.add(const _ChatMessage(
          role: _MessageRole.ai,
          text:
              "I'm having trouble connecting right now. Please check your network and try again.",
        ));
      });
    }

    _scrollToBottom();
  }

  /// Returns the intent string if a CTA should be shown, or null for
  /// general_conversation / needs_clarification (no button).
  String? _ctaIntent(String intent) {
    switch (intent) {
      case _intentWound:
      case _intentSkin:
      case _intentSymptom:
        return intent;
      default:
        return null;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C63FF), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 17),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Describe your symptoms',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // ── Chat messages ─────────────────────────────────────────────────
          if (_messages.isNotEmpty || _isTyping) ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.xs,
                ),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isTyping && index == _messages.length) {
                    return const _TypingIndicator();
                  }
                  final msg = _messages[index];
                  return _MessageBubble(
                    message: msg,
                    onAssessmentTap: () => widget.onSend(msg.text),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
          ],

          // ── Input row ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSend(),
                    maxLines: 4,
                    minLines: 1,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Ask a question or describe how you\'re feeling...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textTertiary,
                        height: 1.5,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                        horizontal: AppSpacing.sm,
                      ),
                      isDense: true,
                    ),
                    cursorColor: AppColors.primary,
                    cursorWidth: 1.8,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                GestureDetector(
                  onTap: _handleSend,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: (_hasText && !_isTyping)
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: (_hasText && !_isTyping)
                          ? [
                              BoxShadow(
                                color:
                                    AppColors.primary.withValues(alpha: 0.28),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: const Icon(
                      Icons.arrow_upward_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Privacy footer ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm, horizontal: AppSpacing.lg),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFFFF),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppSpacing.radiusXl),
                bottomRight: Radius.circular(AppSpacing.radiusXl),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined,
                    size: 12, color: AppColors.textTertiary),
                const SizedBox(width: 5),
                Text(
                  'Your conversations are private and secure',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatefulWidget {
  final _ChatMessage message;
  final VoidCallback onAssessmentTap;

  const _MessageBubble({
    required this.message,
    required this.onAssessmentTap,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == _MessageRole.user;
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                _AiAvatar(),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(
                child: Column(
                  crossAxisAlignment: isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm + 2),
                      decoration: BoxDecoration(
                        gradient: isUser
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF4F46E5),
                                  Color(0xFF2563EB),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isUser ? null : const Color(0xFFF1F5FF),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isUser ? 16 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.message.text,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          color: isUser ? Colors.white : AppColors.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),

                    // Assessment CTA button — shown only for specific intents
                    if (!isUser &&
                        widget.message.assessmentIntent != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _AssessmentCta(
                        intent: widget.message.assessmentIntent!,
                        onTap: widget.onAssessmentTap,
                      ),
                    ],
                  ],
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: AppSpacing.xs),
                _UserAvatar(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Assessment CTA — adapts label/icon/color by intent ────────────────────────

class _AssessmentCta extends StatefulWidget {
  final String intent;
  final VoidCallback onTap;

  const _AssessmentCta({required this.intent, required this.onTap});

  @override
  State<_AssessmentCta> createState() => _AssessmentCtaState();
}

class _AssessmentCtaState extends State<_AssessmentCta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.forward();
  void _onTapUp(TapUpDetails _) {
    _ctrl.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _ctrl.reverse();

  // ── Intent → visual config ────────────────────────────────────────────────

  List<Color> get _gradient {
    switch (widget.intent) {
      case _intentWound:
        return [const Color(0xFF16A34A), const Color(0xFF059669)];
      case _intentSkin:
        return [const Color(0xFF3B82F6), const Color(0xFF2563EB)];
      case _intentSymptom:
      default:
        return [const Color(0xFF7C3AED), const Color(0xFF6C63FF)];
    }
  }

  IconData get _icon {
    switch (widget.intent) {
      case _intentWound:
        return Icons.healing_rounded;
      case _intentSkin:
        return Icons.face_retouching_natural_rounded;
      case _intentSymptom:
      default:
        return Icons.monitor_heart_outlined;
    }
  }

  String get _label {
    switch (widget.intent) {
      case _intentWound:
        return 'Start Wound Assessment';
      case _intentSkin:
        return 'Start Skin Assessment';
      case _intentSymptom:
      default:
        return 'Start Symptom Assessment';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.sm + 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            boxShadow: [
              BoxShadow(
                color: _gradient.first.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_icon, color: Colors.white, size: 16),
              const SizedBox(width: 7),
              Text(
                _label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Avatars ───────────────────────────────────────────────────────────────────

class _AiAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.auto_awesome_rounded,
          color: Colors.white, size: 14),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E7FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.person_rounded,
          color: Color(0xFF4F46E5), size: 16),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          _AiAvatar(),
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5FF),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) => Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (i) {
                  final progress =
                      (_ctrl.value - i * 0.25).clamp(0.0, 1.0);
                  final bounce = math.sin(progress * math.pi);
                  return Transform.translate(
                    offset: Offset(0, -4 * bounce),
                    child: Container(
                      margin:
                          const EdgeInsets.symmetric(horizontal: 2.5),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
