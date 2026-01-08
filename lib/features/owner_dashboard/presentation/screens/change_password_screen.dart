import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/async_utils.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/keyboard_dismiss_fix_approach1.dart';
import '../../../../core/utils/password_validator.dart';
import '../../../../core/services/logging_service.dart';
import '../../../auth/presentation/widgets/auth_background.dart';
import '../../../auth/presentation/widgets/glass_card.dart';
import '../../../auth/presentation/widgets/premium_input_field.dart';
import '../../../auth/presentation/widgets/gradient_auth_button.dart';
import '../../../../core/theme/app_colors.dart';

/// Change Password Screen
///
/// Uses [AndroidKeyboardDismissFixApproach1] mixin to handle the Android Chrome
/// keyboard dismiss bug (Flutter issue #175074).
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
  List<String> _missingRequirements = [];

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
    final l10n = AppLocalizations.of(context);
    final result = PasswordValidator.validate(_newPasswordController.text, l10n);
    setState(() {
      _passwordStrength = result.strength;
      _missingRequirements = result.missingRequirements;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isCompact = MediaQuery.of(context).size.width < 400;

    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Handle browser back button on Chrome Android
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/owner/profile');
          }
        }
      },
      child: KeyedSubtree(
        key: ValueKey('change_password_screen_$keyboardFixRebuildKey'),
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          body: AuthBackground(
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
                    padding: EdgeInsets.only(
                      left: isCompact ? 16 : 24,
                      right: isCompact ? 16 : 24,
                      top: 24,
                      bottom: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minHeight),
                      child: Center(
                        child: GlassCard(
                          maxWidth: 500,
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Back Button
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: IconButton(
                                    onPressed: () {
                                      if (context.canPop()) {
                                        context.pop();
                                      } else {
                                        context.go('/owner/profile');
                                      }
                                    },
                                    icon: const Icon(Icons.arrow_back),
                                    tooltip: l10n.back,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Lock Icon
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.primary,
                                        AppColors.primaryDark,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withAlpha(
                                          (0.3 * 255).toInt(),
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.lock_reset,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Title
                                Text(
                                  l10n.changePassword,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 28,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),

                                // Subtitle
                                Text(
                                  l10n.enterCurrentAndNewPassword,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                        fontSize: 15,
                                      ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 32),

                                // Current Password
                                PremiumInputField(
                                  controller: _currentPasswordController,
                                  labelText: l10n.currentPassword,
                                  prefixIcon: Icons.lock_outline,
                                  obscureText: _obscureCurrentPassword,
                                  suffixIcon: IconButton(
                                    // SF-017: Add tooltip for accessibility
                                    tooltip: _obscureCurrentPassword
                                        ? l10n.showPassword
                                        : l10n.hidePassword,
                                    icon: Icon(
                                      _obscureCurrentPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
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
                                      return l10n.pleaseEnterCurrentPassword;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),

                                // New Password
                                PremiumInputField(
                                  controller: _newPasswordController,
                                  labelText: l10n.newPassword,
                                  prefixIcon: Icons.lock,
                                  obscureText: _obscureNewPassword,
                                  suffixIcon: IconButton(
                                    // SF-017: Add tooltip for accessibility
                                    tooltip: _obscureNewPassword
                                        ? l10n.showPassword
                                        : l10n.hidePassword,
                                    icon: Icon(
                                      _obscureNewPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
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
                                      return l10n.passwordsMustBeDifferent;
                                    }
                                    return PasswordValidator.validateSimple(
                                      value,
                                      l10n,
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Password Strength Indicator
                                if (_newPasswordController.text.isNotEmpty)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                              child: LinearProgressIndicator(
                                                value:
                                                    _passwordStrength ==
                                                        PasswordStrength.weak
                                                    ? 0.33
                                                    : _passwordStrength ==
                                                          PasswordStrength
                                                              .medium
                                                    ? 0.66
                                                    : 1.0,
                                                backgroundColor:
                                                    Theme.of(
                                                          context,
                                                        ).brightness ==
                                                        Brightness.dark
                                                    ? AppColors.borderDark
                                                    : AppColors.borderLight,
                                                color:
                                                    _passwordStrength ==
                                                        PasswordStrength.weak
                                                    ? AppColors.error
                                                    : _passwordStrength ==
                                                          PasswordStrength
                                                              .medium
                                                    ? AppColors.warning
                                                    : AppColors.success,
                                                minHeight: 6,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  (_passwordStrength ==
                                                              PasswordStrength
                                                                  .weak
                                                          ? AppColors.error
                                                          : _passwordStrength ==
                                                                PasswordStrength
                                                                    .medium
                                                          ? AppColors.warning
                                                          : AppColors.success)
                                                      .withAlpha(
                                                        (0.1 * 255).toInt(),
                                                      ),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _passwordStrength ==
                                                      PasswordStrength.weak
                                                  ? l10n.weakPassword
                                                  : _passwordStrength ==
                                                        PasswordStrength.medium
                                                  ? l10n.mediumPassword
                                                  : l10n.strongPassword,
                                              style: TextStyle(
                                                color:
                                                    _passwordStrength ==
                                                        PasswordStrength.weak
                                                    ? AppColors.error
                                                    : _passwordStrength ==
                                                          PasswordStrength
                                                              .medium
                                                    ? AppColors.warning
                                                    : AppColors.success,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_missingRequirements.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        ...(_missingRequirements.map(
                                          (req) => Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.close,
                                                  size: 14,
                                                  color: AppColors.error,
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  req,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    color: AppColors.error,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        )),
                                      ],
                                    ],
                                  ),
                                const SizedBox(height: 20),

                                // Confirm Password
                                PremiumInputField(
                                  controller: _confirmPasswordController,
                                  labelText: l10n.confirmNewPassword,
                                  prefixIcon: Icons.lock_open,
                                  obscureText: _obscureConfirmPassword,
                                  suffixIcon: IconButton(
                                    // SF-017: Add tooltip for accessibility
                                    tooltip: _obscureConfirmPassword
                                        ? l10n.showPassword
                                        : l10n.hidePassword,
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                  validator: (value) {
                                    return PasswordValidator.validateConfirmPassword(
                                      _newPasswordController.text,
                                      value,
                                      l10n,
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),

                                // Info message
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha(
                                      (0.1 * 255).toInt(),
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppColors.primary.withAlpha(
                                        (0.3 * 255).toInt(),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        size: 18,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          l10n.youWillStayLoggedIn,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Change Password Button
                                GradientAuthButton(
                                  text: l10n.changePassword,
                                  onPressed: _isLoading
                                      ? null
                                      : _changePassword,
                                  isLoading: _isLoading,
                                  icon: Icons.check_circle_outline,
                                ),
                                const SizedBox(height: 16),

                                // Cancel Button
                                TextButton(
                                  onPressed: () {
                                    if (context.canPop()) {
                                      context.pop();
                                    } else {
                                      context.go('/owner/profile');
                                    }
                                  },
                                  child: Text(
                                    l10n.cancel,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
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
