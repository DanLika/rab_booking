import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/router_owner.dart';
import '../../../../core/constants/breakpoints.dart';
import '../../../../core/design/bb_redesign_tokens.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/utils/keyboard_dismiss_fix_approach1.dart';
import '../../../../core/utils/password_error_l10n.dart';
import '../../../../core/utils/password_validator.dart';
import '../../../../core/utils/profile_validators.dart';
import '../../../../shared/utils/validators/input_sanitizer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/redesign.dart';
import '../../../../shared/widgets/universal_loader.dart';
import '../widgets/profile_image_picker.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';

/// Enhanced Registration Screen — refactored onto Bb* redesign primitives
/// (Phase 2B, sibling of [EnhancedLoginScreen] post-#618 + ForgotPassword #622).
///
/// Visual layer rebuilt with [BbLogo], [BbInput], [BbButton] + glass card on
/// auth `softBg` (pale lavender wash). Auth-family chrome consistent with the
/// design handoff (`design_handoff/source/register.jsx`).
///
/// Second consumer of Phase 1.1 native [BbInput.validator] (PR #616) — first
/// MULTI-field stress test of the foundation. Five inputs (name / email /
/// phone / password / confirm) each pass their own validator; cross-field
/// confirm-password rule reads the live `_passwordController.text`.
///
/// FROZEN / preserved logic:
///  - `enhancedAuthProvider.registerWithEmail` invocation (Firebase Auth
///    `createUserWithEmailAndPassword` chain + display-name update +
///    profile image upload).
///  - Email verification gate (`requiresEmailVerification` →
///    `OwnerRoutes.emailVerification`).
///  - Display-name digit-strip preservation logic (per audit/35 / CLAUDE.md
///    auth.md): `InputSanitizer.sanitizeName` keeps digits in `sanitizeName`.
///  - Server-side email error surfacing (`_emailErrorFromServer` overrides
///    client validator output via [BbInput]'s explicit `error:` param —
///    audit/103 §3 "Explicit `widget.error` always wins over validator").
///  - `_canAttemptSubmit` UX gating (button disabled until all required
///    fields non-empty + both legal checkboxes checked).
///  - `_formKey` validation, [AndroidKeyboardDismissFixApproach1] mixin,
///    `resizeToAvoidBottomInset: true`.
///  - [AuthFeatureFlags]-style gating: register screen has no social
///    sign-in row in current implementation (handoff shows it; not
///    surfaced here — preserved as-is).
///  - Legal links (`Navigator.push` to PrivacyPolicyScreen / TermsConditionsScreen).
class EnhancedRegisterScreen extends ConsumerStatefulWidget {
  const EnhancedRegisterScreen({super.key});

  @override
  ConsumerState<EnhancedRegisterScreen> createState() =>
      _EnhancedRegisterScreenState();
}

class _EnhancedRegisterScreenState extends ConsumerState<EnhancedRegisterScreen>
    with AndroidKeyboardDismissFixApproach1<EnhancedRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _acceptedTerms = false;
  bool _acceptedPrivacy = false;
  bool _newsletterOptIn = false;
  // UX FIX: Button enabled when fields are non-empty and checkboxes checked.
  // Validation errors are shown AFTER clicking submit (or on user interaction
  // via `AutovalidateMode.onUserInteraction`), not while typing the first time.
  bool _canAttemptSubmit = false;
  String? _emailErrorFromServer;

  Uint8List? _profileImageBytes;
  String? _profileImageName;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_clearServerError);

    // Listen to all fields to update button state (enabled when non-empty)
    _fullNameController.addListener(_updateCanAttemptSubmit);
    _emailController.addListener(_updateCanAttemptSubmit);
    _passwordController.addListener(_updateCanAttemptSubmit);
    _confirmPasswordController.addListener(_updateCanAttemptSubmit);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _clearServerError() {
    if (_emailErrorFromServer != null) {
      setState(() => _emailErrorFromServer = null);
    }
  }

  /// UX FIX: Check if user CAN attempt to submit (fields non-empty + checkboxes)
  /// This doesn't validate content - validation happens on submit click.
  void _updateCanAttemptSubmit() {
    final hasName = _fullNameController.text.trim().isNotEmpty;
    final hasEmail = _emailController.text.trim().isNotEmpty;
    final hasPassword = _passwordController.text.isNotEmpty;
    final hasConfirm = _confirmPasswordController.text.isNotEmpty;

    final newState =
        hasName &&
        hasEmail &&
        hasPassword &&
        hasConfirm &&
        _acceptedTerms &&
        _acceptedPrivacy;

    if (_canAttemptSubmit != newState) {
      setState(() => _canAttemptSubmit = newState);
    }
  }

  Future<void> _handleRegister() async {
    final l10n = AppLocalizations.of(context);

    // Trigger validation - errors will show in input fields via BbInput's
    // native validator path (Phase 1.1).
    if (!_formKey.currentState!.validate()) {
      ErrorDisplayUtils.showErrorSnackBar(context, l10n.pleaseFixErrors);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final (firstName, lastName) = _parseFullName(_fullNameController.text);

      // SECURITY: Sanitize all inputs before sending to backend.
      // sanitizeName intentionally PRESERVES digits (audit/35 / CLAUDE.md
      // auth.md PR #470 closure — digits in display names are allowed).
      final sanitizedEmail =
          InputSanitizer.sanitizeEmail(_emailController.text.trim()) ??
          _emailController.text.trim();
      final sanitizedFirstName =
          InputSanitizer.sanitizeName(firstName) ?? firstName;
      final sanitizedLastName =
          InputSanitizer.sanitizeName(lastName) ?? lastName;
      final sanitizedPhone = _phoneController.text.trim().isNotEmpty
          ? (InputSanitizer.sanitizePhone(_phoneController.text.trim()) ??
                _phoneController.text.trim())
          : null;

      await ref
          .read(enhancedAuthProvider.notifier)
          .registerWithEmail(
            email: sanitizedEmail,
            password: _passwordController
                .text, // Password doesn't need sanitization (Firebase Auth handles it)
            firstName: sanitizedFirstName,
            lastName: sanitizedLastName,
            phone: sanitizedPhone,
            acceptedTerms: _acceptedTerms,
            acceptedPrivacy: _acceptedPrivacy,
            newsletterOptIn: _newsletterOptIn,
            profileImageBytes: _profileImageBytes,
            profileImageName: _profileImageName,
          );

      if (!mounted) return;

      final authState = ref.read(enhancedAuthProvider);

      if (authState.error != null) {
        setState(() => _isLoading = false);
        ErrorDisplayUtils.showErrorSnackBar(context, authState.error);
        return;
      }

      if (authState.requiresEmailVerification) {
        // Keep loader visible during navigation (widget will dispose naturally)
        context.go(OwnerRoutes.emailVerification);
        return;
      }

      // Registration successful without email verification - navigate to dashboard
      // Keep loader visible during navigation (widget will dispose naturally)
      context.go(OwnerRoutes.overview);
    } catch (e) {
      if (!mounted) return;

      final authState = ref.read(enhancedAuthProvider);
      final errorMessage = authState.error ?? e.toString();

      if (_isEmailError(errorMessage)) {
        setState(() {
          _emailErrorFromServer =
              errorMessage.contains('already exists') ||
                  errorMessage.contains('email-already-in-use')
              ? l10n.errorEmailInUse
              : l10n.authErrorInvalidEmail;
          _isLoading = false;
        });
        // BbInput's `error:` param surfaces the server message; calling
        // validate() also re-triggers per-input validator path.
        _formKey.currentState!.validate();
      } else {
        setState(() => _isLoading = false);
        // Handle coded rate limit message with seconds (from RateLimitService)
        if (errorMessage.startsWith('RATE_LIMIT_LOCKOUT:')) {
          final secondsStr = errorMessage.split(':')[1];
          final seconds = int.tryParse(secondsStr) ?? 60;
          ErrorDisplayUtils.showErrorSnackBar(
            context,
            l10n.authErrorRateLimitWait(seconds),
          );
        } else {
          ErrorDisplayUtils.showErrorSnackBar(context, errorMessage);
        }
      }
    }
  }

  (String, String) _parseFullName(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    return (firstName, lastName);
  }

  bool _isEmailError(String message) {
    const emailErrorPatterns = [
      'already exists',
      'email-already-in-use',
      'Invalid email',
    ];
    return emailErrorPatterns.any(message.contains);
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
      key: ValueKey('register_screen_$keyboardFixRebuildKey'),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          alignment:
              Alignment.topLeft, // Explicit to avoid TextDirection null check
          children: [
            // Soft auth backdrop (`BbRedesignTokens.softBg`) — pale lavender
            // wash matching the auth-family convention established by Login
            // (PR #613/#618) + Forgot Password (PR #622).
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

                    return SingleChildScrollView(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.only(
                        left: isCompact ? 12 : 20,
                        right: isCompact ? 12 : 20,
                        top: isSmallHeight ? 12 : (isCompact ? 16 : 20),
                        bottom: isSmallHeight ? 12 : (isCompact ? 16 : 20),
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: minHeight),
                        // Handoff register.jsx desktop split (≥1200):
                        // register-flavored brand pitch panel left, 560px
                        // register card right. Narrower widths keep the
                        // centered card (mirror of login PR #732 split).
                        child: constraints.maxWidth >= 1200
                            // No stretch: the scroll view gives unbounded
                            // height, so the pitch panel pins its own viewport
                            // height and the card centers on it.
                            ? Row(
                                children: [
                                  Expanded(
                                    child: _RegisterPitchPanel(
                                      viewportHeight: minHeight,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 560,
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
                                ],
                              )
                            : Center(
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
                    );
                  },
                ),
              ),
            ),
            if (_isLoading)
              UniversalLoader.forAuth(message: 'Creating your account...'),
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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(c, l10n, isCompact, isSmallHeight),
                SizedBox(height: isSmallHeight ? 16 : (isCompact ? 20 : 24)),
                _buildFormFields(c, l10n, isCompact, isSmallHeight),
                SizedBox(height: isSmallHeight ? 8 : (isCompact ? 12 : 14)),
                _buildCheckboxes(c, l10n),
                SizedBox(height: isSmallHeight ? 16 : (isCompact ? 20 : 24)),
                BbButton(
                  key: const ValueKey('register_submit'),
                  label: l10n.authCreateAccount,
                  iconLeft: 'person_add',
                  size: BbButtonSize.lg,
                  fullWidth: true,
                  loading: _isLoading,
                  onPressed: _canAttemptSubmit ? _handleRegister : null,
                ),
                SizedBox(height: isCompact ? 16 : 20),
                _buildLoginLink(c, l10n),
              ],
            ),
          ),
        ),
      ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: card,
    );
  }

  Widget _buildHeader(
    BBColorSet c,
    AppLocalizations l10n,
    bool isCompact,
    bool isSmallHeight,
  ) {
    final logoSize = isSmallHeight ? 50.0 : (isCompact ? 56.0 : 64.0);
    final avatarSize = isSmallHeight ? 70.0 : (isCompact ? 80.0 : 90.0);

    return Column(
      children: [
        BbLogo(size: logoSize),
        SizedBox(height: isSmallHeight ? 12 : (isCompact ? 16 : 24)),
        ProfileImagePicker(
          size: avatarSize,
          initials: _fullNameController.text.trim().isNotEmpty
              ? _fullNameController.text.trim().substring(0, 1).toUpperCase()
              : null,
          onImageSelected: (bytes, name) {
            setState(() {
              _profileImageBytes = bytes;
              _profileImageName = name;
            });
          },
        ),
        SizedBox(height: isSmallHeight ? 12 : (isCompact ? 16 : 20)),
        Text(
          l10n.authCreateAccount,
          style: BBType.h1(context).copyWith(color: c.textPrimary),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          l10n.authStartManaging,
          style: BBType.body(context).copyWith(color: c.textSecondary),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildFormFields(
    BBColorSet c,
    AppLocalizations l10n,
    bool isCompact,
    bool isSmallHeight,
  ) {
    final fieldSpacing = SizedBox(
      height: isSmallHeight ? 8 : (isCompact ? 12 : 14),
    );

    return Column(
      children: [
        // Name — Phase 1.1 native `validator:` (audit/103 §3).
        BbInput(
          key: const ValueKey('register_name'),
          controller: _fullNameController,
          label: l10n.authFullName,
          iconLeft: 'person',
          size: BbInputSize.lg,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.authEnterFullName;
            }
            final parts = value
                .trim()
                .split(RegExp(r'\s+'))
                .where((p) => p.isNotEmpty)
                .toList();
            if (parts.length < 2) {
              return l10n.authEnterFirstLastName;
            }
            return null;
          },
        ),
        fieldSpacing,
        // Email — server-side error takes precedence over validator output
        // via BbInput's explicit `error:` param (audit/103 §3 "Explicit
        // `widget.error` always wins over validator output").
        BbInput(
          key: const ValueKey('register_email'),
          controller: _emailController,
          label: l10n.email,
          iconLeft: 'mail',
          size: BbInputSize.lg,
          keyboardType: TextInputType.emailAddress,
          error: _emailErrorFromServer,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: ProfileValidators.validateEmail,
        ),
        fieldSpacing,
        // Phone — optional field; validator allows empty (per ProfileValidators).
        BbInput(
          key: const ValueKey('register_phone'),
          controller: _phoneController,
          label: l10n.authPhone,
          iconLeft: 'phone',
          size: BbInputSize.lg,
          keyboardType: TextInputType.phone,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: ProfileValidators.validatePhone,
        ),
        fieldSpacing,
        // Password — trailingAction holds the visibility-toggle IconButton
        // (stateful Widget, per BbInput contract).
        BbInput(
          key: const ValueKey('register_password'),
          controller: _passwordController,
          label: l10n.password,
          iconLeft: 'lock',
          size: BbInputSize.lg,
          obscureText: _obscurePassword,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          trailingAction: Tooltip(
            message: _obscurePassword ? l10n.showPassword : l10n.hidePassword,
            child: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: c.textSecondary,
                size: 20,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
          ),
          validator: PasswordValidator.validateMinimumLength,
        ),
        fieldSpacing,
        // Confirm password — cross-field validator reads live
        // `_passwordController.text` (audit/103 §3: validator runs against
        // live controller.text rather than cached state.value).
        BbInput(
          key: const ValueKey('register_confirm'),
          controller: _confirmPasswordController,
          label: l10n.authConfirmPassword,
          iconLeft: 'lock',
          size: BbInputSize.lg,
          obscureText: _obscureConfirmPassword,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          trailingAction: Tooltip(
            message: _obscureConfirmPassword
                ? l10n.showPassword
                : l10n.hidePassword,
            child: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: c.textSecondary,
                size: 20,
              ),
              onPressed: () {
                HapticFeedback.mediumImpact();
                setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                );
              },
            ),
          ),
          validator: (value) {
            final e = PasswordValidator.confirmPasswordError(
              _passwordController.text,
              value,
            );
            return e == null ? null : l10n.passwordErrorText(e);
          },
        ),
      ],
    );
  }

  Widget _buildCheckboxes(BBColorSet c, AppLocalizations l10n) {
    // NOTE: No native BbCheckbox primitive exists in the redesign barrel
    // (audit/103 §3 — checkboxes are not in the Phase 1 inventory). Keep
    // the existing Material `Checkbox` widget; recolor with `c.primary`
    // from the redesign token set so the visual still matches the family.
    return Column(
      children: [
        _buildLegalCheckbox(
          value: _acceptedTerms,
          onChanged: (value) {
            setState(() => _acceptedTerms = value!);
            _updateCanAttemptSubmit();
          },
          linkText: l10n.authTermsConditions,
          prefixText: l10n.authAcceptTerms,
          onLinkTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
          ),
          c: c,
          checkboxKey: const ValueKey('register_tos_checkbox'),
        ),
        const SizedBox(height: 6),
        _buildLegalCheckbox(
          value: _acceptedPrivacy,
          onChanged: (value) {
            setState(() => _acceptedPrivacy = value!);
            _updateCanAttemptSubmit();
          },
          linkText: l10n.authPrivacyPolicy,
          prefixText: l10n.authAcceptTerms,
          onLinkTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
          ),
          c: c,
          checkboxKey: const ValueKey('register_privacy_checkbox'),
        ),
        const SizedBox(height: 6),
        _buildCheckboxRow(
          value: _newsletterOptIn,
          onChanged: (value) => setState(() => _newsletterOptIn = value!),
          c: c,
          child: Text(
            l10n.authNewsletterOptIn,
            style: BBType.caption(context).copyWith(color: c.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildLegalCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String linkText,
    required String prefixText,
    required VoidCallback onLinkTap,
    required BBColorSet c,
    Key? checkboxKey,
  }) {
    return _buildCheckboxRow(
      value: value,
      onChanged: onChanged,
      checkboxKey: checkboxKey,
      c: c,
      child: RichText(
        text: TextSpan(
          style: BBType.caption(context).copyWith(color: c.textSecondary),
          children: [
            TextSpan(text: prefixText),
            TextSpan(
              text: linkText,
              style: TextStyle(
                color: c.primary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()..onTap = onLinkTap,
            ),
            const TextSpan(text: ' *'),
          ],
        ),
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildCheckboxRow({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Widget child,
    required BBColorSet c,
    Key? checkboxKey,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 22,
          width: 22,
          child: Checkbox(
            key: checkboxKey,
            value: value,
            onChanged: onChanged,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            activeColor: c.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(padding: const EdgeInsets.only(top: 2), child: child),
        ),
      ],
    );
  }

  Widget _buildLoginLink(BBColorSet c, AppLocalizations l10n) {
    return Center(
      child: BbButton(
        key: const ValueKey('register_login_link'),
        label: '${l10n.authHaveAccount} ${l10n.login}',
        variant: BbButtonVariant.tertiary,
        onPressed: () => context.go(OwnerRoutes.login),
      ),
    );
  }
}

/// Desktop register brand/pitch panel (handoff `register.jsx` RegBrandPanel —
/// "Desktop left brand panel (mirror of login, register-flavored)"): logo +
/// wordmark top, pitch block (eyebrow/headline/copy + trial checklist) middle,
/// stats row bottom. Copy is handoff-spec HR onboarding marketing. Sibling of
/// login's `_LoginPitchPanel`; the register variant trades login's in-block
/// stats + legal footer for the onboarding checklist + a bottom stats row, per
/// register.jsx.
class _RegisterPitchPanel extends StatelessWidget {
  final double viewportHeight;

  const _RegisterPitchPanel({required this.viewportHeight});

  static const _checklist = <String>[
    '14 dana Pro besplatno',
    'Bez kartice pri registraciji',
    'Otkažite bilo kada',
  ];

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);

    // The surrounding scroll view has unbounded height — pin the panel to the
    // viewport so spaceBetween can park logo top / stats bottom.
    return SizedBox(
      height: viewportHeight > 0 ? viewportHeight : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(80, 64, 80, 64),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const BbLogo(size: 40),
                const SizedBox(width: 12),
                Text(
                  'BookBed',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.44,
                    color: c.textPrimary,
                  ),
                ),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'OWNER APLIKACIJA',
                    style: BBType.eyebrow(context).copyWith(color: c.primary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Počnite upravljati\nu nekoliko minuta.',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.44,
                      height: 1.1,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Dodajte jedinice, povežite kanale i primajte rezervacije '
                    'izravno na svoju stranicu — bez provizije po rezervaciji '
                    'na Pro planu.',
                    style: BBType.bodyLg(
                      context,
                    ).copyWith(color: c.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < _checklist.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        Row(
                          children: [
                            BbIcon(name: 'check_circle', color: c.success),
                            const SizedBox(width: 10),
                            Flexible(
                              child: Text(
                                _checklist[i],
                                style: BBType.body(
                                  context,
                                ).copyWith(color: c.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Wrap(
              spacing: 24,
              runSpacing: 16,
              children: [
                _PitchStat(value: '45+', label: 'aktivnih vlasnika'),
                _PitchStat(value: '12k', label: 'rezervacija godišnje'),
                _PitchStat(value: '99.9%', label: 'uptime'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Pitch stat (handoff PitchStat): tabular value in primary + caption label.
/// Mirror of login's `_PitchStat` (file-private, so redeclared here).
class _PitchStat extends StatelessWidget {
  final String value;
  final String label;

  const _PitchStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = BBColor.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.56,
            color: c.primary,
            fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: BBType.caption(context).copyWith(color: c.textSecondary),
        ),
      ],
    );
  }
}
