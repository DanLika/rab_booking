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
import '../../../../core/utils/profile_validator_error_l10n.dart';
import '../../../../core/utils/profile_validators.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/redesign.dart';
import '../../../../shared/widgets/universal_loader.dart';

/// Forgot password screen — refactored onto Bb* redesign primitives (Phase 2B).
///
/// Visual layer built with [BbIcon], [BbInput], [BbButton] + glass card on
/// auth `softBg` (pale lavender wash) — matches the auth-family pattern
/// established by [EnhancedLoginScreen] (PR #613 + cleanup #618).
///
/// First consumer of Phase 1.1 native [BbInput.validator] (PR #616). The
/// validator is passed directly; no per-input `FormField<String>` wrap.
///
/// Header follows handoff `recovery.jsx` `RecCard`: a centered tinted
/// icon-tile (`lock_reset` primary → request, `mark_email_read` success →
/// sent) + title + sub, replacing the logo used by login/register.
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
  // Recovery icon-tile (handoff `recovery.jsx` RecCard): 64×64 rounded-18
  // tinted square holding a 32px Material Symbol.
  static const double _kIconTileSize = 64;
  static const double _kIconTileRadius = 18;
  static const double _kIconTileGlyph = 32;
  // Tint alphas from `design_handoff/source/tokens.css` (--bb-primary-tint-bg
  // 0.06 light, --bb-success-tint 0.12 light). Composed off the semantic
  // color so both themes stay in family.
  static const double _kPrimaryTintAlpha = 0.06;
  static const double _kSuccessTintAlpha = 0.12;

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
      borderRadius: BBRadius.xlAll,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: rd.glassBg,
            border: Border.all(color: rd.glassBorder),
            borderRadius: BBRadius.xlAll,
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
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildIconTile(c, icon: 'lock_reset', tone: c.primary),
          SizedBox(height: isSmallHeight ? 12 : (isCompact ? 14 : 18)),
          Text(
            l10n.authResetPassword,
            style: BBType.h1(context).copyWith(color: c.textPrimary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.authResetPasswordDesc,
            style: BBType.body(
              context,
            ).copyWith(color: c.textSecondary, height: 1.55),
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
            validator: (v) {
              final e = ProfileValidators.emailError(v);
              return e == null ? null : l10n.profileValidatorErrorText(e);
            },
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
          SizedBox(height: isSmallHeight ? 14 : (isCompact ? 18 : 22)),
          _buildBackLink(c, l10n),
        ],
      ),
    );
  }

  /// Tinted icon-tile header (handoff `recovery.jsx` RecCard): 64×64 rounded
  /// square, tinted background off [tone], holding a 32px Material Symbol.
  Widget _buildIconTile(
    BBColorSet c, {
    required String icon,
    required Color tone,
  }) {
    final tintAlpha = tone == c.success
        ? _kSuccessTintAlpha
        : _kPrimaryTintAlpha;
    return Center(
      child: Container(
        width: _kIconTileSize,
        height: _kIconTileSize,
        decoration: BoxDecoration(
          color: tone.withValues(alpha: tintAlpha),
          borderRadius: BorderRadius.circular(_kIconTileRadius),
        ),
        alignment: Alignment.center,
        child: BbIcon(name: icon, size: _kIconTileGlyph, color: tone),
      ),
    );
  }

  /// Compact "back to login" link (handoff `RecBackLink`): inline
  /// arrow_back + label in primary, centered — not a full-width button.
  Widget _buildBackLink(BBColorSet c, AppLocalizations l10n) {
    return Center(
      child: TextButton(
        key: const ValueKey('forgot_password_back_to_login'),
        onPressed: () => context.go('/login'),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          minimumSize: const Size(0, 44),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            BbIcon(name: 'arrow_back', size: 16, color: c.primary),
            const SizedBox(width: 6),
            Text(
              l10n.authBackToLogin,
              style: BBType.caption(
                context,
              ).copyWith(color: c.primary, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  /// Success view (handoff `recovery.jsx` SentCard): success-tinted
  /// `mark_email_read` icon-tile + "check your email" title + the submitted
  /// address, then a primary "return to login" + a "resend" affordance.
  ///
  /// Security mask: shown identically for every submission regardless of
  /// whether the email exists (Firebase enumeration-resistant).
  Widget _buildSuccessView(BBColorSet c, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildIconTile(c, icon: 'mark_email_read', tone: c.success),
        const SizedBox(height: 18),
        Text(
          l10n.authEmailSent,
          style: BBType.h1(context).copyWith(color: c.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          // Inline `_emailController.text` reflects what the user submitted.
          '${l10n.authResetEmailSentTo} ${_emailController.text}',
          style: BBType.body(
            context,
          ).copyWith(color: c.textSecondary, height: 1.55),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        BbButton(
          key: const ValueKey('forgot_password_return_to_login'),
          label: l10n.authReturnToLogin,
          iconLeft: 'arrow_forward',
          size: BbButtonSize.lg,
          fullWidth: true,
          onPressed: () => context.go('/login'),
        ),
        const SizedBox(height: 12),
        Center(
          child: BbButton(
            key: const ValueKey('forgot_password_resend'),
            label: l10n.authResendEmail,
            variant: BbButtonVariant.tertiary,
            onPressed: () => setState(() => _emailSent = false),
          ),
        ),
      ],
    );
  }
}
