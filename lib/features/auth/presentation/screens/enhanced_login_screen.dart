import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/utils/profile_validators.dart';
import '../widgets/auth_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/auth_logo_icon.dart';
import '../widgets/premium_input_field.dart';
import '../widgets/gradient_auth_button.dart';

/// Enhanced Login Screen with Premium Design
class EnhancedLoginScreen extends ConsumerStatefulWidget {
  const EnhancedLoginScreen({super.key});

  @override
  ConsumerState<EnhancedLoginScreen> createState() => _EnhancedLoginScreenState();
}

class _EnhancedLoginScreenState extends ConsumerState<EnhancedLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(enhancedAuthProvider.notifier).signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            rememberMe: _rememberMe,
          );

      // Login successful - router will handle navigation automatically
      if (mounted) {
        final authState = ref.read(enhancedAuthProvider);

        // Check if email verification required
        if (authState.requiresEmailVerification) {
          context.go(OwnerRoutes.emailVerification);
          return;
        }

        // Success - show welcome message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Welcome back, ${authState.userModel?.firstName ?? "User"}!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      // Always reset loading state
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(enhancedAuthProvider.notifier).signInWithGoogle();
      // Navigation handled by router based on auth state
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(enhancedAuthProvider.notifier).signInWithApple();
      // Navigation handled by router based on auth state
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Apple Sign-In failed: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _handleAnonymousSignIn() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(enhancedAuthProvider.notifier).signInAnonymously();
      // Navigation handled by router based on auth state
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Anonymous Sign-In failed: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Animated Logo - adapts to dark mode
                    Center(
                      child: AuthLogoIcon(
                        size: 100,
                        isWhite: Theme.of(context).brightness == Brightness.dark,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'Owner Login',
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
                      'Manage your properties and bookings',
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
                    const SizedBox(height: 20),

                    // Password field
                    PremiumInputField(
                      controller: _passwordController,
                      labelText: 'Password',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xFF718096),
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Remember me & Forgot password
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _rememberMe = !_rememberMe),
                            child: Row(
                              children: [
                                SizedBox(
                                  height: 48,
                                  width: 48,
                                  child: Center(
                                    child: SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) => setState(() => _rememberMe = value!),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        activeColor: const Color(0xFF6B4CE6),
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  'Remember me',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontSize: 14,
                                        color: const Color(0xFF4A5568),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        ),
                        TextButton(
                          onPressed: () => context.push(OwnerRoutes.forgotPassword),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot password?',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 14,
                                  color: const Color(0xFF6B4CE6),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Login Button
                    GradientAuthButton(
                      text: 'Log In',
                      onPressed: _handleLogin,
                      isLoading: _isLoading,
                      icon: Icons.login_rounded,
                    ),
                    const SizedBox(height: 24),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or continue with',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF718096),
                                  fontSize: 13,
                                ),
                          ),
                        ),
                        const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Social Login Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _SocialLoginButton(
                            customIcon: const _GoogleIcon(),
                            label: 'Google',
                            onPressed: _handleGoogleSignIn,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SocialLoginButton(
                            icon: Icons.apple,
                            label: 'Apple',
                            onPressed: _handleAppleSignIn,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Anonymous Login Button (Demo)
                    _SocialLoginButton(
                      icon: Icons.preview,
                      label: 'Preview Demo (Anonymous)',
                      onPressed: _handleAnonymousSignIn,
                    ),
                    const SizedBox(height: 32),

                    // Register Link
                    Center(
                      child: TextButton(
                        onPressed: () => context.go(OwnerRoutes.register),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        ),
                        child: RichText(
                          text: TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                  color: const Color(0xFF4A5568),
                                ),
                            children: const [
                              TextSpan(text: "Don't have an account? "),
                              TextSpan(
                                text: 'Create Account',
                                style: TextStyle(
                                  color: Color(0xFF6B4CE6),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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

class _SocialLoginButton extends StatefulWidget {
  final IconData? icon;
  final Widget? customIcon;
  final String label;
  final VoidCallback onPressed;

  const _SocialLoginButton({
    this.icon,
    this.customIcon,
    required this.label,
    required this.onPressed,
  }) : assert(icon != null || customIcon != null, 'Either icon or customIcon must be provided');

  @override
  State<_SocialLoginButton> createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends State<_SocialLoginButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered ? const Color(0xFF6B4CE6) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          color: _isHovered
              ? const Color(0xFF6B4CE6).withAlpha((0.05 * 255).toInt())
              : Colors.white.withAlpha((0.5 * 255).toInt()),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.customIcon != null)
                    widget.customIcon!
                  else
                    Icon(
                      widget.icon!,
                      size: 22,
                      color: _isHovered ? const Color(0xFF6B4CE6) : const Color(0xFF4A5568),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isHovered ? const Color(0xFF6B4CE6) : const Color(0xFF4A5568),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Google "G" Icon with proper brand colors
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

/// Paints colorful Google "G" logo
class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width * 0.45;
    final innerRadius = size.width * 0.30;
    final strokeWidth = outerRadius - innerRadius;

    // Draw the arcs from top going clockwise

    // 1. Blue arc (top to right) - 90 degrees
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: (outerRadius + innerRadius) / 2),
      -1.5708, // -90 degrees (top)
      1.5708, // Sweep 90 degrees
      false,
      bluePaint,
    );

    // 2. Green arc (right to bottom) - 63 degrees
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: (outerRadius + innerRadius) / 2),
      0.0, // 0 degrees (right)
      1.1, // ~63 degrees
      false,
      greenPaint,
    );

    // 3. Yellow arc (bottom to left) - 90 degrees
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: (outerRadius + innerRadius) / 2),
      1.5708, // 90 degrees (bottom)
      1.5708, // 90 degrees sweep
      false,
      yellowPaint,
    );

    // 4. Red arc (left to almost top) - 90 degrees
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: (outerRadius + innerRadius) / 2),
      3.1416, // 180 degrees (left)
      1.37, // ~78 degrees (leaving gap at top)
      false,
      redPaint,
    );

    // 5. Blue horizontal bar (the "G" crossbar)
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;

    final barWidth = outerRadius * 0.85;
    final barHeight = strokeWidth * 0.6;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx + barWidth / 4, center.dy),
          width: barWidth,
          height: barHeight,
        ),
        Radius.circular(barHeight / 2),
      ),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
