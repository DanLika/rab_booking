import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router_owner.dart';
import '../../../../core/constants/breakpoints.dart';
import '../../../../core/design/bb_redesign_tokens.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/redesign.dart';

/// Email verification screen — refactored onto Bb* redesign primitives (Phase 2 R4-C).
///
/// Visual layer rebuilt with [BbLogo], [BbButton] + mail-icon state-mark disc
/// on a glass card with `BbRedesignTokens.softBg` backdrop — matches the
/// auth-family pattern established by [ForgotPasswordScreen] (PR #622) and
/// [EnhancedLoginScreen] (PR #613). Both dialogs (resend-password,
/// change-email) run on [_BbFormDialog] + [BbInput] (audit/124 follow-up —
/// last legacy Material widgets in the auth family removed).
///
/// FROZEN / preserved logic:
///  - `sendEmailVerification` via `enhancedAuthProvider`
///  - Auto verification-poll `_refreshTimer` (3s)
///  - Initial 60s `_startInitialCooldown` (Firebase rate limit guard)
///  - Resend `_startCooldown` (60s post-send)
///  - Auto-redirect on verified → `OwnerRoutes.overview`
///  - Email-change dialog flow (`_showResendPasswordDialog`, `_showChangeEmailDialog`)
///  - `firebase_auth`, network-error suppression, app-lifecycle re-check
class EmailVerificationScreen extends ConsumerStatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  ConsumerState<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState
    extends ConsumerState<EmailVerificationScreen>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  bool _hasShownNetworkError = false; // Prevent repeated error snackbars

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Auto-check verification status every 3 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _checkVerificationStatus();
    });

    // Start with initial cooldown to prevent immediate resend after registration
    // Email was already sent during registration, so user must wait before resending
    _startInitialCooldown();
  }

  /// Start initial 60-second cooldown when screen opens
  /// Firebase Auth has an internal rate limit (~60s) on sendEmailVerification()
  /// Since email is already sent during registration, we must wait before allowing resend
  void _startInitialCooldown() {
    _resendCooldown = 60;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown == 0) {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reset error flag when returning to app - network may have been restored
      _hasShownNetworkError = false;
      _checkVerificationStatus();
    }
  }

  Future<void> _checkVerificationStatus() async {
    try {
      await ref
          .read(enhancedAuthProvider.notifier)
          .refreshEmailVerificationStatus();

      // Reset error flag on success
      _hasShownNetworkError = false;

      final authState = ref.read(enhancedAuthProvider);
      if (!authState.requiresEmailVerification && mounted) {
        // Email verified! Cancel timers BEFORE navigating to prevent
        // overlapping calls from showing errors after redirect
        _refreshTimer?.cancel();
        _cooldownTimer?.cancel();
        context.go(OwnerRoutes.overview);
      }
    } catch (e) {
      // If email is already verified in Firebase Auth, the error is from a
      // race condition (e.g., overlapping resumed + timer calls where one
      // succeeded but the other failed on token refresh). Silently ignore.
      final authState = ref.read(enhancedAuthProvider);
      if (authState.firebaseUser?.emailVerified == true) return;

      // Only show network error ONCE to avoid spamming user every 3 seconds
      // Permission-denied errors (e.g., Firestore token refresh race condition)
      // are silently retried - they usually resolve on next attempt
      final errorString = e.toString().toLowerCase();
      final isNetworkError =
          errorString.contains('network') ||
          errorString.contains('socket') ||
          errorString.contains('timeout') ||
          errorString.contains('connection');

      if (isNetworkError && !_hasShownNetworkError && mounted) {
        _hasShownNetworkError = true;
        ErrorDisplayUtils.showErrorSnackBar(
          context,
          AppLocalizations.of(context).errorNetworkFailed,
        );
      }
      // For non-network errors (permission-denied, etc.), silently retry
      // The timer will try again in 3 seconds
    }
  }

  Future<void> _resendVerificationEmail() async {
    if (_resendCooldown > 0) return;

    final authState = ref.read(enhancedAuthProvider);
    final firebaseEmail = authState.firebaseUser?.email;
    final firestoreEmail = authState.userModel?.email;

    // If emails differ, user has a pending email change
    // Need to show password dialog because verifyBeforeUpdateEmail requires recent auth
    if (firestoreEmail != null &&
        firebaseEmail != null &&
        firestoreEmail.toLowerCase() != firebaseEmail.toLowerCase()) {
      await _showResendPasswordDialog(firestoreEmail);
      return;
    }

    setState(() => _isResending = true);

    try {
      // Normal case: send verification to current Firebase Auth email
      await ref.read(enhancedAuthProvider.notifier).sendEmailVerification();

      if (mounted) {
        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          AppLocalizations.of(context).authVerifyEmailSuccess,
          duration: const Duration(seconds: 3),
        );
        _startCooldown();
      }
    } catch (e) {
      if (mounted) {
        final errorString = e.toString().toLowerCase();

        if (errorString.contains('too-many-requests')) {
          // Firebase rate limit hit - start cooldown so user knows when to retry
          _startCooldown();
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            AppLocalizations.of(context).authErrorTooManyRequests,
          );
        } else if (errorString.contains('network') ||
            errorString.contains('socket') ||
            errorString.contains('timeout') ||
            errorString.contains('connection')) {
          // Network error - show user-friendly message
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            AppLocalizations.of(context).errorNetworkFailed,
          );
        } else {
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            '${AppLocalizations.of(context).error}: $e',
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  /// Show password dialog for resending email change verification
  /// Required because verifyBeforeUpdateEmail is a sensitive operation
  Future<void> _showResendPasswordDialog(String newEmail) async {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    try {
      return await showDialog(
        context: context,
        builder: (dialogContext) {
          final l10n = AppLocalizations.of(dialogContext);
          return Form(
            key: formKey,
            child: _BbFormDialog(
              title: l10n.authResendVerificationEmail,
              intro: l10n.authPasswordHelper,
              fields: [
                BbInput(
                  key: const ValueKey('resend_verification_password'),
                  controller: passwordController,
                  label: l10n.authPasswordLabel,
                  iconLeft: 'lock',
                  obscureText: true,
                  size: BbInputSize.lg,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.passwordRequired;
                    }
                    return null;
                  },
                ),
              ],
              secondary: BbDialogAction(
                label: l10n.cancel,
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              primary: BbDialogAction(
                label: l10n.submit,
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final navigator = Navigator.of(dialogContext);
                  navigator.pop();

                  setState(() => _isResending = true);

                  try {
                    // Re-authenticate and resend verification
                    await ref
                        .read(enhancedAuthProvider.notifier)
                        .updateEmail(
                          newEmail: newEmail,
                          currentPassword: passwordController.text,
                        );

                    if (mounted) {
                      ErrorDisplayUtils.showSuccessSnackBar(
                        context,
                        l10n.authVerifyEmailSuccess,
                        duration: const Duration(seconds: 3),
                      );
                      _startCooldown();
                    }
                  } catch (e) {
                    if (mounted) {
                      ErrorDisplayUtils.showErrorSnackBar(context, e);
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isResending = false);
                    }
                  }
                },
              ),
            ),
          );
        },
      );
    } finally {
      passwordController.dispose();
    }
  }

  /// Start 60 second cooldown after sending verification email
  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() {
      _resendCooldown = 60;
    });

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown == 0) {
          timer.cancel();
        }
      });
    });
  }

  /// Show dialog to change email address (Phase 3 feature)
  Future<void> _showChangeEmailDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    try {
      return await showDialog(
        context: context,
        builder: (dialogContext) {
          final l10n = AppLocalizations.of(dialogContext);
          final c = BBColor.of(dialogContext);
          return Form(
            key: formKey,
            child: _BbFormDialog(
              title: l10n.authChangeEmailTitle,
              intro: l10n.authChangeEmailDesc,
              fields: [
                BbInput(
                  key: const ValueKey('change_email_new_email'),
                  controller: emailController,
                  label: l10n.authNewEmailLabel,
                  iconLeft: 'mail',
                  size: BbInputSize.lg,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.emailRequired;
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return l10n.validEmailRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: BBSpace.sm),
                BbInput(
                  key: const ValueKey('change_email_password'),
                  controller: passwordController,
                  label: l10n.authPasswordLabel,
                  iconLeft: 'lock',
                  obscureText: true,
                  helper: l10n.authPasswordHelper,
                  size: BbInputSize.lg,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.passwordRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Logout-warning tip — same token recipe as the screen's
                // info-tip block (surfaceVariant chip on the dialog surface).
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.surfaceVariant,
                    borderRadius: BBRadius.smAll,
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 20,
                        color: c.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l10n.authLogoutHint,
                          style: BBType.caption(
                            dialogContext,
                          ).copyWith(color: c.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              secondary: BbDialogAction(
                label: l10n.cancel,
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
              primary: BbDialogAction(
                label: l10n.authChangeEmail,
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  final navigator = Navigator.of(dialogContext);
                  navigator.pop();

                  try {
                    // Re-authenticate and update email via provider
                    await ref
                        .read(enhancedAuthProvider.notifier)
                        .updateEmail(
                          newEmail: emailController.text.trim(),
                          currentPassword: passwordController.text,
                        );

                    if (mounted) {
                      ErrorDisplayUtils.showSuccessSnackBar(
                        context,
                        l10n.authUpdateEmailSuccess,
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ErrorDisplayUtils.showErrorSnackBar(context, e);
                    }
                  }
                },
              ),
            ),
          );
        },
      );
    } finally {
      emailController.dispose();
      passwordController.dispose();
    }
  }

  Future<void> _signOutAndReturnToLogin() async {
    try {
      await ref.read(enhancedAuthProvider.notifier).signOut();
    } catch (_) {
      // Ignore sign out errors
    }
    if (mounted) {
      context.go(OwnerRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(enhancedAuthProvider);
    final email =
        authState.userModel?.email ??
        authState.firebaseUser?.email ??
        'your email';
    final l10n = AppLocalizations.of(context);
    final rd = BbRedesignTokens.of(context);
    final c = BBColor.of(context);
    final isCompact = Breakpoints.isCompactMobile(context);
    final isSmallHeight = MediaQuery.of(context).size.height < 700;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: rd.softBg),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 16 : 24,
              vertical: 24,
            ),
            child: Center(
              child: _buildGlassCard(
                context,
                rd,
                c,
                l10n,
                email,
                isCompact,
                isSmallHeight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Glass card surface (BackdropFilter + glassBg/glassBorder tokens) —
  /// mirrors [ForgotPasswordScreen._buildGlassCard].
  Widget _buildGlassCard(
    BuildContext context,
    BbRedesignTokens rd,
    BBColorSet c,
    AppLocalizations l10n,
    String email,
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
          child: _buildContent(c, l10n, email, isCompact, isSmallHeight),
        ),
      ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: card,
    );
  }

  Widget _buildContent(
    BBColorSet c,
    AppLocalizations l10n,
    String email,
    bool isCompact,
    bool isSmallHeight,
  ) {
    final logoSize = isSmallHeight ? 48.0 : (isCompact ? 52.0 : 56.0);
    final discSize = isSmallHeight ? 56.0 : 64.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Auth-family branding — BbLogo
        Center(child: BbLogo(size: logoSize, useGradient: false)),
        SizedBox(height: isSmallHeight ? 12 : 16),

        // 2. Mail-icon state-mark disc (primary tint)
        Center(
          child: Container(
            width: discSize,
            height: discSize,
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.mark_email_unread_outlined,
              size: discSize * 0.5,
              color: c.primary,
            ),
          ),
        ),
        SizedBox(height: isSmallHeight ? 14 : 18),

        // 3. h1 title
        Text(
          l10n.authCheckInbox,
          style: BBType.h1(context).copyWith(color: c.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),

        // 4. body subtitle
        Text(
          l10n.authEmailVerificationSentTo,
          style: BBType.body(
            context,
          ).copyWith(color: c.textSecondary, height: 1.55),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // 5. Email chip
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: c.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: c.border),
            ),
            child: Text(
              email,
              style: BBType.body(
                context,
              ).copyWith(color: c.textPrimary, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        SizedBox(height: isSmallHeight ? 18 : 24),

        // 6. Info tip — click-link + arrival hint
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BBRadius.smAll,
            border: Border.all(color: c.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: c.primary, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.authClickLinkToVerify,
                      style: BBType.label(
                        context,
                      ).copyWith(color: c.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.authEmailArrivalHint,
                      style: BBType.caption(
                        context,
                      ).copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: isSmallHeight ? 18 : 24),

        // 7. Resend button (primary, full-width)
        BbButton(
          key: const ValueKey('email_verification_resend'),
          label: l10n.authResendVerificationEmail,
          iconLeft: 'send',
          size: BbButtonSize.lg,
          fullWidth: true,
          loading: _isResending,
          disabled: _resendCooldown > 0,
          onPressed: _resendVerificationEmail,
        ),

        // 8. Cooldown countdown — BBType.bodyNum (tabular)
        if (_resendCooldown > 0) ...[
          const SizedBox(height: 10),
          Center(
            child: Text(
              l10n.authResendInSeconds(_resendCooldown),
              style: BBType.bodyNum(
                context,
              ).copyWith(color: c.textTertiary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
        SizedBox(height: isSmallHeight ? 12 : 16),

        // 9. Wrong-email — tertiary
        Center(
          child: BbButton(
            key: const ValueKey('email_verification_change_email'),
            label: l10n.authWrongEmail,
            variant: BbButtonVariant.tertiary,
            onPressed: _showChangeEmailDialog,
          ),
        ),
        const SizedBox(height: 2),

        // 10. Back to login — tertiary
        Center(
          child: BbButton(
            key: const ValueKey('email_verification_back_to_login'),
            label: l10n.authBackToLogin,
            iconLeft: 'arrow_back',
            variant: BbButtonVariant.tertiary,
            onPressed: _signOutAndReturnToLogin,
          ),
        ),
      ],
    );
  }
}

/// Premium form-dialog shell — replicates [BbDialog]'s visual recipe
/// (surface / BBRadius.lg / BBShadow.modal / h2-body type ramp / BbButton
/// action row) but hosts widget [fields] between intro and actions, which
/// [BbDialog] can't (its `body` is String-only). Inlined per the R5
/// inlined-helper precedent; wrap in a [Form] to use BbInput validators.
class _BbFormDialog extends StatelessWidget {
  const _BbFormDialog({
    required this.title,
    required this.intro,
    required this.fields,
    required this.primary,
    required this.secondary,
  });

  final String title;
  final String intro;
  final List<Widget> fields;
  final BbDialogAction primary;
  final BbDialogAction secondary;

  @override
  Widget build(BuildContext context) {
    final BBColorSet c = BBColor.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(BBSpace.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BBRadius.lgAll,
            boxShadow: BBShadow.modal(context),
          ),
          padding: const EdgeInsets.all(BBSpace.md),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(title, style: BBType.h2(context)),
                const SizedBox(height: BBSpace.xs),
                Text(
                  intro,
                  style: BBType.body(context).copyWith(color: c.textSecondary),
                ),
                const SizedBox(height: BBSpace.sm),
                ...fields,
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    BbButton(
                      label: secondary.label,
                      variant: BbButtonVariant.tertiary,
                      onPressed: secondary.onPressed,
                    ),
                    const SizedBox(width: BBSpace.xs),
                    BbButton(
                      label: primary.label,
                      onPressed: primary.onPressed,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
