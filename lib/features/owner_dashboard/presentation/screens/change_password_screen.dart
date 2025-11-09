import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/password_validator.dart';
import '../../../auth/presentation/widgets/auth_background.dart';
import '../../../auth/presentation/widgets/glass_card.dart';
import '../../../auth/presentation/widgets/premium_input_field.dart';
import '../../../auth/presentation/widgets/gradient_auth_button.dart';
import '../../../../core/theme/app_colors.dart';

/// Change Password Screen with Auth Style
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
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
    final result = PasswordValidator.validate(_newPasswordController.text);
    setState(() {
      _passwordStrength = result.strength;
      _missingRequirements = result.missingRequirements;
    });
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Re-authenticate user first
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(_newPasswordController.text);

      if (mounted) {
        setState(() => _isLoading = false);

        ErrorDisplayUtils.showSuccessSnackBar(
          context,
          'Password changed successfully',
        );

        context.pop();
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          message = 'Trenutna lozinka nije ispravna';
          break;
        case 'weak-password':
          message = 'Nova lozinka je preslaba';
          break;
        case 'requires-recent-login':
          message = 'Molimo odjavite se i ponovno se prijavite prije promjene lozinke';
          break;
        default:
          message = 'Greška pri promjeni lozinke: ${e.message}';
      }

      if (mounted) {
        setState(() => _isLoading = false);

        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: message,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        ErrorDisplayUtils.showErrorSnackBar(
          context,
          e,
          userMessage: 'Greška pri promjeni lozinke',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AuthBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width < 400 ? 16 : 24,
                vertical: 24,
              ),
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
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.arrow_back),
                            tooltip: 'Back',
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Lock Icon
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.primary,
                                AppColors.secondary,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withAlpha((0.3 * 255).toInt()),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.lock_reset,
                            size: 40,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          'Change Password',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                                color: AppColors.textPrimary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          'Enter your current password and choose a new one',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 15,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Current Password
                        PremiumInputField(
                          controller: _currentPasswordController,
                          labelText: 'Current Password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscureCurrentPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureCurrentPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureCurrentPassword = !_obscureCurrentPassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your current password';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // New Password
                        PremiumInputField(
                          controller: _newPasswordController,
                          labelText: 'New Password',
                          prefixIcon: Icons.lock,
                          obscureText: _obscureNewPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNewPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == _currentPasswordController.text) {
                              return 'New password must be different from current password';
                            }
                            return PasswordValidator.validateSimple(value);
                          },
                        ),
                        const SizedBox(height: 12),

                        // Password Strength Indicator
                        if (_newPasswordController.text.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: _passwordStrength == PasswordStrength.weak
                                            ? 0.33
                                            : _passwordStrength == PasswordStrength.medium
                                                ? 0.66
                                                : 1.0,
                                        backgroundColor: AppColors.borderLight,
                                        color: _passwordStrength == PasswordStrength.weak
                                            ? AppColors.error
                                            : _passwordStrength == PasswordStrength.medium
                                                ? AppColors.warning
                                                : AppColors.success,
                                        minHeight: 6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (_passwordStrength == PasswordStrength.weak
                                              ? AppColors.error
                                              : _passwordStrength == PasswordStrength.medium
                                                  ? AppColors.warning
                                                  : AppColors.success)
                                          .withAlpha((0.1 * 255).toInt()),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _passwordStrength == PasswordStrength.weak
                                          ? 'Weak'
                                          : _passwordStrength == PasswordStrength.medium
                                              ? 'Medium'
                                              : 'Strong',
                                      style: TextStyle(
                                        color: _passwordStrength == PasswordStrength.weak
                                            ? AppColors.error
                                            : _passwordStrength == PasswordStrength.medium
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
                                ...(_missingRequirements.map((req) => Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Row(
                                        children: [
                                          Icon(Icons.close,
                                              size: 14, color: AppColors.error),
                                          const SizedBox(width: 6),
                                          Text(
                                            req,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.error,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))),
                              ],
                            ],
                          ),
                        const SizedBox(height: 20),

                        // Confirm Password
                        PremiumInputField(
                          controller: _confirmPasswordController,
                          labelText: 'Confirm New Password',
                          prefixIcon: Icons.lock_open,
                          obscureText: _obscureConfirmPassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          validator: (value) {
                            return PasswordValidator.validateConfirmPassword(
                              _newPasswordController.text,
                              value,
                            );
                          },
                        ),
                        const SizedBox(height: 32),

                        // Change Password Button
                        GradientAuthButton(
                          text: 'Change Password',
                          onPressed: _isLoading ? null : _changePassword,
                          isLoading: _isLoading,
                          icon: Icons.check_circle_outline,
                        ),
                        const SizedBox(height: 16),

                        // Cancel Button
                        TextButton(
                          onPressed: () => context.pop(),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
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
          ),
        ),
      ),
    );
  }
}
