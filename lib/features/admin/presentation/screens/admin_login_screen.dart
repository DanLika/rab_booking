import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/widgets/redesign.dart';

import '../../../../core/design/tokens.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../l10n/app_localizations.dart';

/// Admin login — design-fidelity reimplementation of
/// `design_handoff/source/admin-auth.jsx` (theme-light).
///
/// LIGHT card on the deep-purple admin gradient. The route in
/// `admin_providers.dart` wraps this screen in
/// `ThemeData.light + BbRedesignTokens.light` so primitives resolve to the
/// light palette regardless of the outer MaterialApp `themeMode`.
///
/// Internal-console copy is ENGLISH only (per JSX header comment); literals
/// for "BookBed", "ADMIN", "Remember this device" etc. are hardcoded rather
/// than added to ARB.
class AdminLoginScreen extends ConsumerStatefulWidget {
  final String? errorMessage;

  const AdminLoginScreen({super.key, this.errorMessage});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _isPasswordVisible = ValueNotifier<bool>(false);
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _rememberMe = true;
  String? _error;
  bool _notAdmin = false;

  @override
  void initState() {
    super.initState();
    _notAdmin = widget.errorMessage == 'not_admin';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_notAdmin && _error == null) {
      _error = AppLocalizations.of(context).adminAccessDenied;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _isPasswordVisible.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await ref
          .read(enhancedAuthProvider.notifier)
          .signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            rememberMe: _rememberMe,
          );
      await _completeAdminGate();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _sanitizeLoginError(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isGoogleLoading = true;
      _error = null;
    });
    try {
      await ref.read(enhancedAuthProvider.notifier).signInWithGoogle();
      await _completeAdminGate();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _sanitizeLoginError(e);
          _isGoogleLoading = false;
        });
      }
    }
  }

  Future<void> _completeAdminGate() async {
    final authState = ref.read(enhancedAuthProvider);
    if (!authState.isAuthenticated) {
      // User cancelled the Google picker, or sign-in returned without a user.
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isGoogleLoading = false;
        });
      }
      return;
    }
    if (!authState.isAdmin) {
      await ref.read(enhancedAuthProvider.notifier).signOut();
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context).adminAccessDenied;
          _isLoading = false;
          _isGoogleLoading = false;
        });
      }
      return;
    }
    if (mounted) context.go('/dashboard');
  }

  String _sanitizeLoginError(Object error) {
    String message = error.toString();
    final authMatch = RegExp(
      r'\[firebase_auth/[^\]]+\]\s*(.*)',
    ).firstMatch(message);
    if (authMatch != null && authMatch.group(1)!.isNotEmpty) {
      return authMatch.group(1)!;
    }
    message = message
        .replaceAll('Exception: ', '')
        .replaceAll(RegExp(r'^\[.*?\]\s*'), '')
        .trim();
    if (message.isEmpty || message.length > 200) {
      return AppLocalizations.of(context).adminLoginFailed;
    }
    return message;
  }

  Future<void> _showForgotPasswordDialog() async {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    final dialogFormKey = GlobalKey<FormState>();
    bool submitting = false;
    String? localError;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            Future<void> submit() async {
              if (!dialogFormKey.currentState!.validate()) return;
              setLocal(() {
                submitting = true;
                localError = null;
              });
              try {
                await ref
                    .read(enhancedAuthProvider.notifier)
                    .resetPassword(emailCtrl.text.trim());
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset email sent.')),
                  );
                }
              } catch (e) {
                setLocal(() {
                  submitting = false;
                  localError = _sanitizeLoginError(e);
                });
              }
            }

            return AlertDialog(
              title: const Text('Reset password'),
              content: Form(
                key: dialogFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Enter your work email. We will send a reset link.',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Work email',
                      style: BBType.label(ctx).copyWith(
                        height: 1.4,
                        letterSpacing: 0.13,
                        color: BBColor.of(ctx).textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    BbInput(
                      placeholder: 'you@bookbed.io',
                      controller: emailCtrl,
                      iconLeft: 'mail',
                      keyboardType: TextInputType.emailAddress,
                      error: localError,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: submitting ? null : submit,
                  child: submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send link'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = BBColor.of(context);
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 600;
    final showChromeMarks = size.width >= 600;

    return Scaffold(
      backgroundColor: const Color(0xFF241A52),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 1 — base diagonal gradient #241A52 → #36277A → #241A52.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF241A52),
                  Color(0xFF36277A),
                  Color(0xFF241A52),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
          // Layer 2 — radial purple highlight (top-right) over the linear.
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.6, -1.2),
                  radius: 0.9,
                  colors: [Color(0x598B6FFF), Color(0x008B6FFF)],
                  stops: [0.0, 0.6],
                ),
              ),
            ),
          ),
          // Layer 3 — grid pattern with radial mask.
          const Positioned.fill(
            child: IgnorePointer(child: _AdminGridPattern()),
          ),
          // Layer 4 — top-left console mark (desktop + tablet only).
          if (showChromeMarks)
            const Positioned(top: 28, left: 32, child: _AdminConsoleMark()),
          // Layer 5 — centered card.
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 20 : 48,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _formKey,
                  child: _LoginCard(
                    isMobile: isMobile,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _BrandRow(),
                        const SizedBox(height: 24),
                        Text(
                          l10n.adminWelcomeBack,
                          style: _h1Style(c.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.adminLoginSubtitle,
                          style: BBType.body(
                            context,
                          ).copyWith(color: c.textSecondary),
                        ),
                        const SizedBox(height: 24),
                        if (_error != null) ...[
                          _LightErrorBanner(message: _error!),
                          const SizedBox(height: 24),
                        ],
                        // Manual label + label:null on BbInput so we can apply
                        // tokens.css:236 .bb-label (13/500/1.4/0.01em). The
                        // primitive BBType.label currently ships height 1.5 /
                        // no letterSpacing — global token fix deferred to a
                        // separate owner-pass PR. copyWith preserves font
                        // family + fallback chain + features from the
                        // primitive; we override only the two drifted values
                        // plus colour. SizedBox(h:6) matches
                        // bb_input.dart:201 exactly so the field offset is
                        // identical to the primitive's internal layout.
                        Text(
                          l10n.adminEmailLabel,
                          style: BBType.label(context).copyWith(
                            height: 1.4,
                            letterSpacing: 0.13,
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        BbInput(
                          placeholder: l10n.adminEmailHint,
                          controller: _emailController,
                          iconLeft: 'mail',
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.adminEmailRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        Text(
                          l10n.adminPasswordLabel,
                          style: BBType.label(context).copyWith(
                            height: 1.4,
                            letterSpacing: 0.13,
                            color: c.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ValueListenableBuilder<bool>(
                          valueListenable: _isPasswordVisible,
                          builder: (context, isVisible, _) {
                            return BbInput(
                              placeholder: '••••••••',
                              controller: _passwordController,
                              iconLeft: 'lock',
                              obscureText: !isVisible,
                              trailingAction: _PasswordVisibilityToggle(
                                isVisible: isVisible,
                                color: c.textTertiary,
                                onPressed: () =>
                                    _isPasswordVisible.value = !isVisible,
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.adminPasswordRequired;
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _login(),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _RememberAndForgotRow(
                          rememberMe: _rememberMe,
                          onRememberChanged: (v) =>
                              setState(() => _rememberMe = v),
                          onForgotPressed: _showForgotPasswordDialog,
                        ),
                        const SizedBox(height: 20),
                        BbButton(
                          label: l10n.adminSignInButton,
                          iconLeft: 'login',
                          size: BbButtonSize.lg,
                          fullWidth: true,
                          loading: _isLoading,
                          onPressed: (_isLoading || _isGoogleLoading)
                              ? null
                              : _login,
                        ),
                        const SizedBox(height: 22),
                        const _OrDivider(),
                        const SizedBox(height: 16),
                        _GoogleSsoButton(
                          loading: _isGoogleLoading,
                          disabled: _isLoading,
                          onPressed: _signInWithGoogle,
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            'Authorized staff only. Activity is logged.',
                            style: BBType.caption(
                              context,
                            ).copyWith(color: c.textTertiary),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Layer 6 — bottom foot mark (desktop + tablet only).
          if (showChromeMarks)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: _AdminFootMark(),
            ),
        ],
      ),
    );
  }
}

// `.bb-h1` (24/700/1.2/-0.015em) approximation. Hardcoded TextStyle instead
// of BBType.h1 because BBType pulls google_fonts which we don't need here.
TextStyle _h1Style(Color color) => TextStyle(
  fontFamily: 'Inter',
  fontSize: 24,
  fontWeight: FontWeight.w700,
  height: 1.2,
  letterSpacing: -0.36,
  color: color,
);

/// Card chrome — white surface, radius 32, dual purple-aura shadow,
/// 5px top accent bar bleeding to edges (overflow clipped).
class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.child, required this.isMobile});

  final Widget child;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
        borderRadius: BorderRadius.all(Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Color(0x990A061E),
            offset: Offset(0, 32),
            blurRadius: 64,
            spreadRadius: -24,
          ),
          BoxShadow(
            color: Color(0x4D6B4CE6),
            offset: Offset(0, 8),
            blurRadius: 24,
            spreadRadius: -8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top accent bar — 5 px, brand-primary gradient.
            // Inline LinearGradient matches tokens.css:77 --bb-gradient-primary
            // end (#8B6FFF). BBGradient.brandPrimary still ships #7E5FEE for
            // owner; global token fix is deferred to a separate owner-pass PR
            // with design sign-off.
            Container(
              height: 5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6B4CE6), Color(0xFF8B6FFF)],
                ),
              ),
            ),
            Padding(padding: EdgeInsets.all(isMobile ? 24 : 36), child: child),
          ],
        ),
      ),
    );
  }
}

/// Inline brand row: [BbLogo 32][BookBed 18/700/-0.02em][ADMIN pill].
class _BrandRow extends StatelessWidget {
  const _BrandRow();

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BbLogo(),
        const SizedBox(width: 10),
        Text(
          'BookBed',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.36, // -0.02em × 18
            color: c.textPrimary,
            height: 1.2,
          ),
        ),
        const SizedBox(width: 10),
        const _AdminPill(),
      ],
    );
  }
}

class _AdminPill extends StatelessWidget {
  const _AdminPill();

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'ADMIN',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.0, // 0.1em × 10
          color: c.primary,
          height: 1.2,
        ),
      ),
    );
  }
}

class _RememberAndForgotRow extends StatelessWidget {
  const _RememberAndForgotRow({
    required this.rememberMe,
    required this.onRememberChanged,
    required this.onForgotPressed,
  });

  final bool rememberMe;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onForgotPressed;

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: _AdminCheck(
            value: rememberMe,
            // PR #652 binding preserved verbatim — admin-auth.jsx declares
            // ENGLISH only ("ENGLISH, internal-console tone" — JSX header).
            label: 'Remember this device',
            onChanged: onRememberChanged,
          ),
        ),
        TextButton(
          onPressed: onForgotPressed,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            minimumSize: const Size(0, 36),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Forgot password?',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.primary,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

/// 18 × 18 admin-auth-pattern checkbox — mirrors `admin-auth.jsx:18-24`
/// `AdminCheck` (login-only). Distinct from the design-system canonical
/// `BbCheckbox` (20 × 20, dialogs.jsx:99) which the rest of the app uses.
/// Local override only — `BbCheckbox` primitive is untouched.
class _AdminCheck extends StatelessWidget {
  const _AdminCheck({
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Semantics(
      checked: value,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(BBRadius.sm),
          child: ConstrainedBox(
            // a11y: keep the row at a 44 px touch target even when the box
            // itself shrinks to 18 px. Mirrors BbCheckbox's minHeight.
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: BBSpace.xs),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: BBMotion.adapt(context, BBMotion.fast),
                    curve: BBMotion.curve,
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: value ? c.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: c.primary, width: 1.5),
                    ),
                    child: AnimatedOpacity(
                      duration: BBMotion.adapt(context, BBMotion.fast),
                      opacity: value ? 1.0 : 0.0,
                      child: const BbIcon(
                        name: 'check',
                        size: 12,
                        color: Colors.white,
                        weight: 600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      // tokens.css:235 .bb-caption (12/400/1.5) + JSX
                      // AdminCheck override fontWeight: 500.
                      style: BBType.caption(context).copyWith(
                        fontWeight: FontWeight.w500,
                        color: c.textSecondary,
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
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    // tokens.css --bb-border-subtle (light) = #EDF2F7
    const subtle = Color(0xFFEDF2F7);
    return Row(
      children: [
        const Expanded(
          child: SizedBox(height: 1, child: ColoredBox(color: subtle)),
        ),
        const SizedBox(width: 12),
        Text(
          'or',
          style: BBType.caption(context).copyWith(color: c.textTertiary),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: SizedBox(height: 1, child: ColoredBox(color: subtle)),
        ),
      ],
    );
  }
}

/// Google Workspace SSO button — secondary surface, fullWidth, Google "G"
/// glyph + label. Wired to `enhancedAuthProvider.signInWithGoogle()`. Admin
/// claim gate runs post-flow (see `_completeAdminGate`).
///
/// "Workspace" in the label is design-canonical; the underlying flow does not
/// enforce a hosted-domain (`hd`) restriction — admin access is gated by the
/// `isAdmin` custom claim post sign-in, identical to the email-password flow.
class _GoogleSsoButton extends StatelessWidget {
  const _GoogleSsoButton({
    required this.loading,
    required this.disabled,
    required this.onPressed,
  });

  final bool loading;
  final bool disabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    final effectivelyDisabled = disabled || loading;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: effectivelyDisabled ? null : onPressed,
          borderRadius: BorderRadius.circular(BBRadius.sm),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(BBRadius.sm),
              border: Border.all(color: c.border),
            ),
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const _GoogleGlyph(size: 18),
                      const SizedBox(width: 10),
                      Text(
                        'Continue with Google Workspace',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// 4-color Google "G" glyph painted via CustomPaint — avoids depending on a
/// raster asset and keeps bundle minimal.
class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleGlyphPainter()),
    );
  }
}

class _GoogleGlyphPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2;
    final center = Offset(radius, radius);
    final strokeWidth = size.width * 0.22;
    final innerRadius = radius - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: innerRadius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    void arc(double startDeg, double sweepDeg, Color color) {
      paint.color = color;
      canvas.drawArc(
        rect,
        startDeg * 3.14159265 / 180,
        sweepDeg * 3.14159265 / 180,
        false,
        paint,
      );
    }

    arc(-30, 70, _blue);
    arc(40, 90, _green);
    arc(130, 80, _yellow);
    arc(210, 95, _red);

    // Short blue tab on the right side (Google logo "G" notch).
    final bar = Paint()
      ..color = _blue
      ..style = PaintingStyle.fill;
    final barRect = Rect.fromLTWH(
      center.dx,
      center.dy - strokeWidth / 2,
      radius - strokeWidth / 2,
      strokeWidth,
    );
    canvas.drawRect(barRect, bar);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PasswordVisibilityToggle extends StatelessWidget {
  final bool isVisible;
  final Color color;
  final VoidCallback onPressed;

  const _PasswordVisibilityToggle({
    required this.isVisible,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: color,
        size: 20,
      ),
      splashRadius: 18,
      tooltip: AppLocalizations.of(context).adminPasswordLabel,
      onPressed: onPressed,
    );
  }
}

/// Light-theme error banner: tinted error background, icon, message text.
class _LightErrorBanner extends StatelessWidget {
  const _LightErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.error.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(BBRadius.sm),
        border: Border.all(color: c.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: c.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: BBType.caption(
                context,
              ).copyWith(color: c.error, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

/// Top-left console mark: `admin_panel_settings` icon + "BookBed Admin Console"
/// label. Renders on the deep-purple background, not inside the card.
class _AdminConsoleMark extends StatelessWidget {
  const _AdminConsoleMark();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.admin_panel_settings_outlined,
          size: 20,
          color: Color(0xD9FFFFFF),
        ),
        SizedBox(width: 8),
        Text(
          'BookBed Admin Console',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.14, // 0.01em × 14
            color: Color(0xD9FFFFFF),
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

/// Bottom centered foot mark: "v2.4 · Internal tool · © YYYY BookBed Inc."
class _AdminFootMark extends StatelessWidget {
  const _AdminFootMark();

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;
    return Center(
      child: Text(
        'v2.4 · Internal tool · © $year BookBed Inc.',
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: Color(0x8CFFFFFF), // rgba(255,255,255,0.55)
          height: 1.2,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// 40×40 grid pattern with radial fade-out toward edges.
class _AdminGridPattern extends StatelessWidget {
  const _AdminGridPattern();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (Rect bounds) {
        return const RadialGradient(
          radius: 0.85,
          colors: [Color(0xFF000000), Color(0x00000000)],
          stops: [0.0, 0.75],
        ).createShader(bounds);
      },
      child: const Opacity(
        opacity: 0.5,
        child: CustomPaint(painter: _GridPainter()),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          const Color(0x0AFFFFFF) // rgba(255,255,255,0.04)
      ..strokeWidth = 1;
    const step = 40.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
