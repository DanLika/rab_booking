import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../core/utils/async_utils.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/keyboard_dismiss_fix_approach1.dart';
import '../../../../core/utils/password_error_l10n.dart';
import '../../../../core/utils/password_validator.dart';
import '../../../../core/services/logging_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/redesign.dart';

/// Change Password Screen — redesigned onto Bb* foundation
/// (PR redesign/r2c-change-password). Settings-family layout: bare
/// Scaffold + BbCard form panel + BbInput(validator:) (Phase 1.1 native
/// form integration) + BbButton submit. Parent owner Scaffold/drawer/
/// app-bar swap deferred to shell-swap PR per audit/103.
///
/// Uses [AndroidKeyboardDismissFixApproach1] mixin to handle the Android
/// Chrome keyboard dismiss bug (Flutter issue #175074).
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen>
    with AndroidKeyboardDismissFixApproach1<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  PasswordStrength _passwordStrength = PasswordStrength.weak;
  List<PasswordError> _missingRequirements = [];

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final result = PasswordValidator.validate(_newPasswordController.text);
    setState(() {
      _passwordStrength = result.strength;
      // Store CODES, not the validator's English prose — localized at render.
      _missingRequirements = result.missingCodes;
    });
  }

  Future<void> _changePassword() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) {
      ErrorDisplayUtils.showErrorSnackBar(
        context,
        Exception(l10n.widgetPleaseCheckFormErrors),
        userMessage: l10n.widgetPleaseCheckFormErrors,
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    final newPassword = _newPasswordController.text;

    try {
      // SECURITY: Check password history (Cloud Function)
      // Prevents users from reusing recent passwords
      try {
        final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
        final checkHistoryCallable = functions.httpsCallable(
          'checkPasswordHistory',
        );
        await checkHistoryCallable
            .call({'password': newPassword})
            .withCloudFunctionTimeout('checkPasswordHistory');
      } on FirebaseFunctionsException catch (e) {
        if (e.code == 'failed-precondition') {
          // Password was recently used
          if (mounted) {
            setState(() => _isLoading = false);
            ErrorDisplayUtils.showErrorSnackBar(
              context,
              e,
              userMessage: e.message ?? l10n.passwordsMustBeDifferent,
            );
          }
          return;
        }
        // Continue if check fails (fail-open for availability)
        LoggingService.log(
          'Password history check failed, continuing: ${e.message}',
          tag: 'AUTH_WARNING',
        );
      }

      // Re-authenticate user first
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      // SECURITY: Save new password to history (non-blocking)
      try {
        final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
        final saveHistoryCallable = functions.httpsCallable(
          'savePasswordToHistory',
        );
        await saveHistoryCallable
            .call({'password': newPassword})
            .withCloudFunctionTimeout('savePasswordToHistory');
      } catch (e) {
        // Don't block password change if history save fails
        LoggingService.log(
          'Password history save failed: $e',
          tag: 'AUTH_WARNING',
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);

        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          l10n.passwordChangedSuccessfully,
        );

        // Use canPop check - page may be accessed directly via URL
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/owner/profile');
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message = l10n.currentPasswordIncorrect;
          break;
        case 'weak-password':
          message = l10n.invalidPassword;
          break;
        case 'requires-recent-login':
          message = l10n.recentLoginRequired;
          break;
        default:
          // SECURITY FIX SF-012: Prevent info leakage - don't expose e.message
          message = l10n.passwordChangeError;
      }

      if (mounted) {
        setState(() => _isLoading = false);

        ErrorDisplayUtils.showErrorSnackBar(context, e, userMessage: message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: l10n.passwordChangeError,
        );
      }
    }
  }

  void _exit() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/owner/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = BBColor.of(context);

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Handle browser back button on Chrome Android
          _exit();
        }
      },
      child: KeyedSubtree(
        key: ValueKey('change_password_screen_$keyboardFixRebuildKey'),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: c.bg,
          body: Container(
            decoration: BoxDecoration(
              gradient: context.gradients.pageBackground,
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Get keyboard height to adjust padding dynamically (with null safety)
                  final mediaQuery = MediaQuery.maybeOf(context);
                  final keyboardHeight = (mediaQuery?.viewInsets.bottom ?? 0.0)
                      .clamp(0.0, double.infinity);
                  final isKeyboardOpen = keyboardHeight > 0;

                  // Calculate minHeight safely - ensure it's always finite and valid
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
                  // Ensure minHeight is always finite (never infinity)
                  minHeight = minHeight.isFinite ? minHeight : 0.0;

                  return SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(BBSpace.md),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minHeight),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 680),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Back row
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: IconButton(
                                    onPressed: _exit,
                                    icon: const Icon(Icons.arrow_back),
                                    tooltip: l10n.back,
                                  ),
                                ),
                                const SizedBox(height: BBSpace.xs),

                                // Form panel
                                BbCard(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Premium eyebrow + icon header — settings.jsx
                                      // §246 ChangePasswordContent layered identity.
                                      Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: c.primary.withValues(
                                                alpha: 0.10,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    BBRadius.sm,
                                                  ),
                                            ),
                                            alignment: Alignment.center,
                                            child: BbIcon(
                                              name: 'lock_reset',
                                              size: 22,
                                              color: c.primary,
                                            ),
                                          ),
                                          const SizedBox(width: BBSpace.sm),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  l10n.changePasswordSecurityEyebrow,
                                                  style: BBType.eyebrow(
                                                    context,
                                                  ).copyWith(color: c.primary),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  l10n.changePassword,
                                                  style: BBType.h3(context)
                                                      .copyWith(
                                                        color: c.textPrimary,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: BBSpace.sm),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: BBSpace.md,
                                        ),
                                        child: Text(
                                          l10n.enterCurrentAndNewPassword,
                                          style: BBType.body(
                                            context,
                                          ).copyWith(color: c.textSecondary),
                                        ),
                                      ),

                                      // Current password — Phase 1.1 native validator
                                      BbInput(
                                        controller: _currentPasswordController,
                                        label: l10n.currentPassword,
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [
                                          AutofillHints.password,
                                        ],
                                        iconLeft: 'lock',
                                        obscureText: _obscureCurrentPassword,
                                        size: BbInputSize.lg,
                                        autovalidateMode:
                                            AutovalidateMode.onUserInteraction,
                                        trailingAction: IconButton(
                                          // SF-017: Add tooltip for accessibility
                                          tooltip: _obscureCurrentPassword
                                              ? l10n.showPassword
                                              : l10n.hidePassword,
                                          icon: Icon(
                                            _obscureCurrentPassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: c.textTertiary,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscureCurrentPassword =
                                                  !_obscureCurrentPassword;
                                            });
                                          },
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return l10n
                                                .pleaseEnterCurrentPassword;
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: BBSpace.md),

                                      // New password — Phase 1.1 native validator
                                      BbInput(
                                        controller: _newPasswordController,
                                        label: l10n.newPassword,
                                        textInputAction: TextInputAction.next,
                                        autofillHints: const [
                                          AutofillHints.newPassword,
                                        ],
                                        iconLeft: 'lock',
                                        obscureText: _obscureNewPassword,
                                        size: BbInputSize.lg,
                                        autovalidateMode:
                                            AutovalidateMode.onUserInteraction,
                                        trailingAction: IconButton(
                                          tooltip: _obscureNewPassword
                                              ? l10n.showPassword
                                              : l10n.hidePassword,
                                          icon: Icon(
                                            _obscureNewPassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: c.textTertiary,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscureNewPassword =
                                                  !_obscureNewPassword;
                                            });
                                          },
                                        ),
                                        validator: (value) {
                                          if (value ==
                                              _currentPasswordController.text) {
                                            return l10n
                                                .passwordsMustBeDifferent;
                                          }
                                          final e = PasswordValidator.validate(
                                            value,
                                          ).errorCode;
                                          return e == null
                                              ? null
                                              : l10n.passwordErrorText(e);
                                        },
                                      ),

                                      // Password strength meter (kept inline,
                                      // dynamic — can't live in BbInput.helper).
                                      // liveRegion: announces the new strength
                                      // label whenever the level changes.
                                      if (_newPasswordController
                                          .text
                                          .isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: BBSpace.xs,
                                          ),
                                          child: Semantics(
                                            liveRegion: true,
                                            child: _PasswordStrengthMeter(
                                              strength: _passwordStrength,
                                              missingRequirements:
                                                  _missingRequirements,
                                              l10n: l10n,
                                              c: c,
                                            ),
                                          ),
                                        ),
                                      const SizedBox(height: BBSpace.md),

                                      // Confirm new password — cross-field validator
                                      BbInput(
                                        controller: _confirmPasswordController,
                                        label: l10n.confirmNewPassword,
                                        textInputAction: TextInputAction.done,
                                        autofillHints: const [
                                          AutofillHints.newPassword,
                                        ],
                                        iconLeft: 'lock_open',
                                        obscureText: _obscureConfirmPassword,
                                        size: BbInputSize.lg,
                                        autovalidateMode:
                                            AutovalidateMode.onUserInteraction,
                                        trailingAction: IconButton(
                                          tooltip: _obscureConfirmPassword
                                              ? l10n.showPassword
                                              : l10n.hidePassword,
                                          icon: Icon(
                                            _obscureConfirmPassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: c.textTertiary,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscureConfirmPassword =
                                                  !_obscureConfirmPassword;
                                            });
                                          },
                                        ),
                                        validator: (value) {
                                          final e =
                                              PasswordValidator.confirmPasswordError(
                                                _newPasswordController.text,
                                                value,
                                              );
                                          return e == null
                                              ? null
                                              : l10n.passwordErrorText(e);
                                        },
                                      ),
                                      const SizedBox(height: BBSpace.md),

                                      // Info banner (info accent left)
                                      BbCard(
                                        variant: BbCardVariant.accentLeft,
                                        accentTone: BbCardAccentTone.info,
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.info_outline,
                                              size: 18,
                                              color: c.info,
                                            ),
                                            const SizedBox(width: BBSpace.xs),
                                            Expanded(
                                              child: Text(
                                                l10n.youWillStayLoggedIn,
                                                style: BBType.caption(context)
                                                    .copyWith(
                                                      color: c.textSecondary,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: BBSpace.md),

                                      // TODO(B4b): wire `revokeAllRefreshTokens`
                                      //   CF (eu-west1) behind a "Odjavi me sa
                                      //   svih ostalih uređaja" toggle row.
                                      //   settings.jsx §267 spec. CF exists at
                                      //   functions/src/revokeTokens.ts. Skipped
                                      //   from B4a to avoid touching shared l10n
                                      //   files (screens-only ownership rule).

                                      // Submit
                                      BbButton(
                                        label: l10n.changePassword,
                                        size: BbButtonSize.lg,
                                        fullWidth: true,
                                        iconLeft: 'lock_reset',
                                        loading: _isLoading,
                                        onPressed: _isLoading
                                            ? null
                                            : _changePassword,
                                      ),
                                      const SizedBox(height: BBSpace.xs),

                                      // Cancel
                                      BbButton(
                                        label: l10n.cancel,
                                        variant: BbButtonVariant.tertiary,
                                        fullWidth: true,
                                        onPressed: _exit,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Password strength meter — segmented bar + label + missing-requirements list.
/// Pulled out for clarity; consumes redesign tokens via [BBColor] / [BBType].
class _PasswordStrengthMeter extends StatelessWidget {
  const _PasswordStrengthMeter({
    required this.strength,
    required this.missingRequirements,
    required this.l10n,
    required this.c,
  });

  final PasswordStrength strength;
  final List<PasswordError> missingRequirements;
  final AppLocalizations l10n;
  final BBColorSet c;

  @override
  Widget build(BuildContext context) {
    final tone = strength == PasswordStrength.weak
        ? c.error
        : strength == PasswordStrength.medium
        ? c.warning
        : c.success;
    final label = strength == PasswordStrength.weak
        ? l10n.weakPassword
        : strength == PasswordStrength.medium
        ? l10n.mediumPassword
        : l10n.strongPassword;
    final fraction = strength == PasswordStrength.weak
        ? 0.33
        : strength == PasswordStrength.medium
        ? 0.66
        : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction,
                  backgroundColor: c.border,
                  color: tone,
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: BBSpace.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                label,
                style: BBType.caption(
                  context,
                ).copyWith(color: tone, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        if (missingRequirements.isNotEmpty) ...[
          const SizedBox(height: BBSpace.xs),
          ...missingRequirements.map(
            (req) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(Icons.close, size: 14, color: c.error),
                  const SizedBox(width: 6),
                  Text(
                    l10n.passwordRequirementText(req),
                    style: BBType.caption(context).copyWith(color: c.error),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
