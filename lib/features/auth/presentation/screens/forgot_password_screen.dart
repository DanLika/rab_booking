import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/breakpoints.dart';
import '../../../../core/design/bb_redesign_tokens.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/keyboard_dismiss_fix_approach1.dart';
import '../../../../core/utils/profile_validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/redesign.dart';
import '../../../../shared/widgets/universal_loader.dart';

/// Forgot password screen — refactored onto Bb* redesign primitives (Phase 2B).
///
/// Visual layer rebuilt with [BbLogo], [BbInput], [BbButton], [BbEmptyState] +
/// glass card on auth `softBg` (pale lavender wash) — matches the auth-family
/// pattern established by [EnhancedLoginScreen] (PR #613 + cleanup #618).
///
/// First consumer of Phase 1.1 native [BbInput.validator] (PR #616). The
/// validator is passed directly; no per-input `FormField<String>` wrap.
///
/// FROZEN / preserved logic:
///  - `sendPasswordResetEmail` via `enhancedAuthProvider.resetPassword`
///  - Security mask: same response regardless of whether email exists
///    (Firebase enumeration-resistant behaviour preserved)
///  - Form-key validation (BbInput's native `validator:` — Phase 1.1)
///  - [AndroidKeyboardDismissFixApproach1] mixin (per .claude/rules/keyboard-fix.md)
///  - `resizeToAvoidBottomInset: true`
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with AndroidKeyboardDismissFixApproach1<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    final l10n = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) {
      ErrorDisplayUtils.showErrorSnackBar(context, l10n.authErrorInvalidEmail);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(enhancedAuthProvider.notifier)
          .resetPassword(_emailController.text.trim());

      // SECURITY: Firebase sendPasswordResetEmail already returns success
      // regardless of whether email exists (prevents user enumeration).
      // We mirror that — same success view shown for every submission.
      if (mounted) {
        setState(() {
          _emailSent = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorDisplayUtils.showErrorSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rd = BbRedesignTokens.of(context);
    final c = BBColor.of(context);
    final isCompact = Breakpoints.isCompactMobile(context);
    final isSmallHeight = MediaQuery.of(context).size.height < 700;

    // PRISTUP 1 (keyboard-fix.md): resizeToAvoidBottomInset: true + mixin
    return KeyedSubtree(
      key: ValueKey('forgot_password_screen_$keyboardFixRebuildKey'),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          alignment:
              Alignment.topLeft, // Explicit to avoid TextDirection null check
          children: [
            // Soft auth backdrop (`BbRedesignTokens.softBg`) — pale lavender
            // wash matching the auth-family convention established by Login
            // (PR #613 fixup that swapped heroGradient → softBg).
            Container(
              decoration: BoxDecoration(gradient: rd.softBg),
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final mediaQuery = MediaQuery.maybeOf(context);
                    final keyboardHeight =
                        (mediaQuery?.viewInsets.bottom ?? 0.0).clamp(
                          0.0,
                          double.infinity,
                        );
                    final isKeyboardOpen = keyboardHeight > 0;

                    double minHeight;
                    if (isKeyboardOpen &&
                        constraints.maxHeight.isFinite &&
                        constraints.maxHeight > 0) {
                      final calculated = constraints.maxHeight - keyboardHeight;
                      minHeight = calculated.clamp(0.0, constraints.maxHeight);
                    } else {
                      minHeight = constraints.maxHeight.isFinite
                          ? constraints.maxHeight
                          : 0.0;
                    }
                    minHeight = minHeight.isFinite ? minHeight : 0.0;

                    return GestureDetector(
                      onTap: () => FocusScope.of(context).unfocus(),
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.only(
                          left: isCompact ? 16 : 24,
                          right: isCompact ? 16 : 24,
                          top: 24,
                          bottom: 24,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: minHeight),
                          child: Center(
                            child: _buildGlassCard(
                              context,
                              rd,
                              c,
                              l10n,
                              isCompact,
                              isSmallHeight,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_isLoading)
              UniversalLoader.forAuth(message: l10n.authSendResetLink),
          ],
        ),
      ),
    );
  }

  /// Glass card surface (BackdropFilter + glassBg/glassBorder tokens).
  /// `ClipRRect` wraps the blur so the radius clips correctly.
  Widget _buildGlassCard(
    BuildContext context,
    BbRedesignTokens rd,
    BBColorSet c,
    AppLocalizations l10n,
    bool isCompact,
    bool isSmallHeight,
  ) {
    final cardPadding = isSmallHeight
        ? const EdgeInsets.all(BBSpace.sm)
        : EdgeInsets.all(isCompact ? BBSpace.md : 36);

    final card = ClipRRect(
      borderRadius: BBRadius.lgAll,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: rd.glassBg,
            border: Border.all(color: rd.glassBorder),
            borderRadius: BBRadius.lgAll,
            boxShadow: rd.panelShadow,
          ),
          padding: cardPadding,
          child: _emailSent
              ? _buildSuccessView(c, l10n)
              : _buildFormView(c, l10n, isCompact, isSmallHeight),
        ),
      ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: card,
    );
  }

  Widget _buildFormView(
    BBColorSet c,
    AppLocalizations l10n,
    bool isCompact,
    bool isSmallHeight,
  ) {
    final logoSize = isSmallHeight ? 56.0 : (isCompact ? 60.0 : 64.0);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: BbLogo(size: logoSize, useGradient: false)),
          SizedBox(height: isSmallHeight ? 12 : (isCompact ? 14 : 16)),
          Text(
            l10n.authResetPassword,
            style: BBType.h1(context).copyWith(color: c.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            l10n.authResetPasswordDesc,
            style: BBType.body(context).copyWith(color: c.textSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallHeight ? 20 : (isCompact ? 24 : 28)),
          // Phase 1.1 native `validator:` — NO `FormField<String>` wrap.
          // Validator runs against live controller text via BbInput's
          // internal FormField (audit/103 §3).
          BbInput(
            key: const ValueKey('forgot_password_email'),
            controller: _emailController,
            label: l10n.email,
            iconLeft: 'mail',
            placeholder: 'ime@primjer.hr',
            size: BbInputSize.lg,
            keyboardType: TextInputType.emailAddress,
            validator: ProfileValidators.validateEmail,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          SizedBox(height: isSmallHeight ? 16 : (isCompact ? 20 : 24)),
          BbButton(
            key: const ValueKey('forgot_password_submit'),
            label: l10n.authSendResetLink,
            iconLeft: 'send',
            size: BbButtonSize.lg,
            fullWidth: true,
            loading: _isLoading,
            onPressed: _handleResetPassword,
          ),
          SizedBox(height: isSmallHeight ? 12 : (isCompact ? 16 : 18)),
          Center(
            child: BbButton(
              key: const ValueKey('forgot_password_back_to_login'),
              label: l10n.authBackToLogin,
              iconLeft: 'arrow_back',
              variant: BbButtonVariant.tertiary,
              onPressed: () => context.go('/login'),
            ),
          ),
        ],
      ),
    );
  }

  /// Success view — `BbEmptyState` with check_circle icon.
  /// Security mask: shown identically for every submission regardless of
  /// whether the email exists (Firebase enumeration-resistant).
  Widget _buildSuccessView(BBColorSet c, AppLocalizations l10n) {
    return BbEmptyState(
      icon: 'check_circle',
      title: l10n.authEmailSent,
      // Composite body: "We've sent password reset instructions to: <email>".
      // Inline `_emailController.text` reflects what the user submitted.
      body: '${l10n.authResetEmailSentTo} ${_emailController.text}',
      primary: BbEmptyStateAction(
        label: l10n.authReturnToLogin,
        iconLeft: 'arrow_forward',
        onPressed: () => context.go('/login'),
      ),
      secondary: BbEmptyStateAction(
        label: l10n.authResendEmail,
        onPressed: () => setState(() => _emailSent = false),
      ),
      compact: true,
    );
  }
}
