import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/utils/profile_validators.dart';
import '../widgets/auth_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/auth_logo_icon.dart';
import '../widgets/premium_input_field.dart';
import '../widgets/gradient_auth_button.dart';

/// Forgot password screen
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref
          .read(enhancedAuthProvider.notifier)
          .resetPassword(_emailController.text.trim());

      setState(() {
        _emailSent = true;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width < 400 ? 16 : 24
                ),
                child: GlassCard(
                  maxWidth: 460,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: animation,
                          child: child,
                        ),
                      );
                    },
                    child: _emailSent
                        ? _buildSuccessView(key: const ValueKey('success'))
                        : _buildFormView(key: const ValueKey('form')),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView({Key? key}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Animated Logo - adapts to dark mode
          Center(
            child: AuthLogoIcon(
              size: 90,
              isWhite: Theme.of(context).brightness == Brightness.dark,
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            'Reset Your Password',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: const Color(0xFF2D3748),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Subtitle
          Text(
            'Enter your email address and we\'ll send you instructions to reset your password.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF718096),
                  fontSize: 15,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Email field
          PremiumInputField(
            controller: _emailController,
            labelText: 'Email Address',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: ProfileValidators.validateEmail,
          ),
          const SizedBox(height: 32),

          // Send Reset Link Button
          GradientAuthButton(
            text: 'Send Reset Link',
            onPressed: _handleResetPassword,
            isLoading: _isLoading,
            icon: Icons.email_outlined,
          ),
          const SizedBox(height: 24),

          // Back to Login
          Center(
            child: TextButton(
              onPressed: () => context.go('/login'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.arrow_back,
                    size: 16,
                    color: Color(0xFF6B4CE6),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Back to Login',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B4CE6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView({Key? key}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Success Icon with gradient background
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF10B981), // Green
                  Color(0xFF059669),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withAlpha((0.3 * 255).toInt()),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 50,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Title
        Text(
          'Email Sent!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 28,
                color: const Color(0xFF2D3748),
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),

        // Subtitle
        Text(
          'We\'ve sent password reset instructions to:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF718096),
                fontSize: 15,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Email address
        Text(
          _emailController.text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF6B4CE6),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),

        // Return to Login Button
        GradientAuthButton(
          text: 'Return to Login',
          onPressed: () => context.go('/login'),
          isLoading: false,
          icon: Icons.arrow_forward,
        ),
        const SizedBox(height: 16),

        // Resend email option
        Center(
          child: TextButton(
            onPressed: () => setState(() => _emailSent = false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            ),
            child: const Text(
              'Didn\'t receive the email? Resend',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B4CE6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
