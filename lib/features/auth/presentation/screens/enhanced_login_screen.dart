import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/utils/profile_validators.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/auth_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/auth_logo_icon.dart';
import '../widgets/premium_input_field.dart';
import '../widgets/gradient_auth_button.dart';

/// Enhanced Login Screen with Premium Design
class EnhancedLoginScreen extends ConsumerStatefulWidget {
  const EnhancedLoginScreen({super.key});

  @override
  ConsumerState<EnhancedLoginScreen> createState() =>
      _EnhancedLoginScreenState();
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
      await ref
          .read(enhancedAuthProvider.notifier)
          .signInWithEmail(
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
            content: Text(
              'Welcome back, ${authState.userModel?.firstName ?? "User"}!',
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Animated Logo - adapts to dark mode
                        Center(
                          child: AuthLogoIcon(
                            isWhite:
                                Theme.of(context).brightness == Brightness.dark,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title
                        Text(
                          'Owner Login',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Subtitle
                        Text(
                          'Manage your properties and bookings',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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
                        const SizedBox(height: 16),

                        // Password field
                        PremiumInputField(
                          controller: _passwordController,
                          labelText: 'Password',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
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
                                onTap: () =>
                                    setState(() => _rememberMe = !_rememberMe),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: _rememberMe,
                                        onChanged: (value) => setState(
                                          () => _rememberMe = value!,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        activeColor: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Remember me',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  context.push(OwnerRoutes.forgotPassword),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Forgot password?',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
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
                            Expanded(
                              child: Divider(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'or continue with',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
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
                                customIcon: const _AppleIcon(),
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
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                            ),
                            child: RichText(
                              text: TextSpan(
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(fontSize: 14),
                                children: [
                                  const TextSpan(
                                    text: "Don't have an account? ",
                                  ),
                                  TextSpan(
                                    text: 'Create Account',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
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
  }) : assert(
         icon != null || customIcon != null,
         'Either icon or customIcon must be provided',
       );

  @override
  State<_SocialLoginButton> createState() => _SocialLoginButtonState();
}

class _SocialLoginButtonState extends State<_SocialLoginButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: 1.5,
          ),
          color: _isHovered
              ? theme.colorScheme.primary.withAlpha((0.08 * 255).toInt())
              : theme.colorScheme.surfaceContainerHighest.withAlpha(
                  (0.3 * 255).toInt(),
                ),
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
                      widget.icon,
                      size: 22,
                      color: _isHovered
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isHovered
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
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
      child: CustomPaint(painter: _GoogleLogoPainter()),
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

/// Custom Apple icon widget
class _AppleIcon extends StatelessWidget {
  const _AppleIcon();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(
        painter: _AppleLogoPainter(color: theme.colorScheme.onSurface),
      ),
    );
  }
}

/// Paints Apple logo silhouette
class _AppleLogoPainter extends CustomPainter {
  final Color color;

  const _AppleLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Use theme-aware color for dark mode compatibility
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Scale factor
    final scale = size.width / 24;

    // Apple body (simplified apple shape with bite)
    final centerX = size.width / 2;
    final centerY = size.height / 2 + 1 * scale;

    // Main apple body
    path.moveTo(centerX, centerY - 7 * scale);

    // Right side curve
    path.cubicTo(
      centerX + 6 * scale,
      centerY - 7 * scale,
      centerX + 8 * scale,
      centerY - 4 * scale,
      centerX + 8 * scale,
      centerY + 2 * scale,
    );

    // Bottom right
    path.cubicTo(
      centerX + 8 * scale,
      centerY + 6 * scale,
      centerX + 5 * scale,
      centerY + 8 * scale,
      centerX,
      centerY + 8 * scale,
    );

    // Bottom left
    path.cubicTo(
      centerX - 5 * scale,
      centerY + 8 * scale,
      centerX - 8 * scale,
      centerY + 6 * scale,
      centerX - 8 * scale,
      centerY + 2 * scale,
    );

    // Left side curve
    path.cubicTo(
      centerX - 8 * scale,
      centerY - 4 * scale,
      centerX - 6 * scale,
      centerY - 7 * scale,
      centerX,
      centerY - 7 * scale,
    );

    path.close();

    // Bite (small circle cutout on the right side)
    final bitePath = Path();
    bitePath.addOval(
      Rect.fromCircle(
        center: Offset(centerX + 5 * scale, centerY - 3 * scale),
        radius: 2.5 * scale,
      ),
    );

    // Subtract bite from apple
    final applePath = Path.combine(PathOperation.difference, path, bitePath);

    canvas.drawPath(applePath, paint);

    // Leaf on top
    final leafPath = Path();
    leafPath.moveTo(centerX + 1 * scale, centerY - 7 * scale);
    leafPath.cubicTo(
      centerX + 2 * scale,
      centerY - 9 * scale,
      centerX + 4 * scale,
      centerY - 10 * scale,
      centerX + 5 * scale,
      centerY - 10 * scale,
    );
    leafPath.cubicTo(
      centerX + 4 * scale,
      centerY - 9.5 * scale,
      centerX + 3 * scale,
      centerY - 8.5 * scale,
      centerX + 1 * scale,
      centerY - 7 * scale,
    );
    leafPath.close();

    canvas.drawPath(leafPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
