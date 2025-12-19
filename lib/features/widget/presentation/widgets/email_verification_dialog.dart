import 'dart:async';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../core/exceptions/app_exceptions.dart';
import '../../../../../core/services/logging_service.dart';
import '../l10n/widget_translations.dart';

/// Email Verification Dialog
///
/// Displays a 6-digit code input for email verification
/// Integrates with Firebase Cloud Functions for OTP verification
class EmailVerificationDialog extends ConsumerStatefulWidget {
  final String email;
  final WidgetColorScheme colors;

  const EmailVerificationDialog({super.key, required this.email, required this.colors});

  @override
  ConsumerState<EmailVerificationDialog> createState() => _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends ConsumerState<EmailVerificationDialog> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    // Auto-send code on dialog open
    _sendVerificationCode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      LoggingService.logOperation('[EmailVerification] Sending code to ${widget.email}');

      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendEmailVerificationCode');

      await callable.call({'email': widget.email});

      LoggingService.logSuccess('[EmailVerification] Code sent successfully');

      if (mounted) {
        // Show success message inside dialog instead of Snackbar to avoid z-index issues
        final successText = WidgetTranslations.of(context, ref).verificationCodeSent;
        setState(() {
          _successMessage = successText;
          _resendCooldown = 60;
        });

        // Clear success message after 3 seconds
        Timer(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _successMessage = null;
            });
          }
        });

        _cooldownTimer?.cancel();
        _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _resendCooldown--;
              if (_resendCooldown == 0) {
                timer.cancel();
              }
            });
          } else {
            timer.cancel();
          }
        });
      }
    } on FirebaseFunctionsException catch (e) {
      await LoggingService.logError('[EmailVerification] Functions error', e);

      if (mounted) {
        setState(() {
          _errorMessage = e.message ?? WidgetTranslations.of(context, ref).emailVerificationFailedToSend;
        });
      }
    } catch (e) {
      await LoggingService.logError('[EmailVerification] Unexpected error', e);

      if (mounted) {
        setState(() {
          _errorMessage = '${WidgetTranslations.of(context, ref).emailVerificationFailedToSend}: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    bool verificationSuccessful = false;

    try {
      LoggingService.logOperation('[EmailVerification] Verifying code');

      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('verifyEmailCode');

      final result = await callable.call({'email': widget.email, 'code': _codeController.text.trim()});

      final data = result.data as Map<String, dynamic>;

      if (data['verified'] == true) {
        LoggingService.logSuccess('[EmailVerification] Email verified!');
        verificationSuccessful = true;

        if (mounted) {
          // Close dialog and return success immediately
          Navigator.of(context).pop(true);
          return; // Exit early to skip finally block
        }
      } else {
        throw BookingException('Email verification failed', code: 'booking/verification-failed');
      }
    } on FirebaseFunctionsException catch (e) {
      await LoggingService.logError('[EmailVerification] Verification failed', e);

      if (mounted) {
        setState(() {
          _errorMessage = e.message ?? WidgetTranslations.of(context, ref).emailVerificationInvalidCode;
        });
      }
    } catch (e) {
      await LoggingService.logError('[EmailVerification] Unexpected error', e);

      if (mounted) {
        setState(() {
          _errorMessage = '${WidgetTranslations.of(context, ref).emailVerificationFailed}: $e';
        });
      }
    } finally {
      // Only reset _isVerifying if verification was not successful
      // (if successful, dialog is already closed)
      if (mounted && !verificationSuccessful) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive padding and max width
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogPadding = screenWidth < 600 ? 16.0 : 32.0;
    final maxWidth = screenWidth < 600 ? screenWidth * 0.95 : 500.0;

    // Responsive font sizes
    final titleFontSize = screenWidth < 600 ? 20.0 : 24.0;
    final codeFontSize = screenWidth < 600 ? 24.0 : 32.0;

    return Dialog(
      backgroundColor: widget.colors.backgroundCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: EdgeInsets.all(dialogPadding),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Icon(Icons.verified_user, color: widget.colors.primary, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        WidgetTranslations.of(context, ref).verifyEmail,
                        style: GoogleFonts.inter(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: widget.colors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: widget.colors.textSecondary),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Email display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.colors.backgroundTertiary,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: widget.colors.borderDefault),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.email_outlined, color: widget.colors.textSecondary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AutoSizeText(
                          widget.email,
                          maxLines: 1,
                          minFontSize: 10,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: widget.colors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Instructions
                Text(
                  WidgetTranslations.of(context, ref).emailVerificationEnterCode,
                  style: GoogleFonts.inter(fontSize: 14, color: widget.colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Code input
                TextFormField(
                  controller: _codeController,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.robotoMono(
                    fontSize: codeFontSize,
                    fontWeight: FontWeight.bold,
                    letterSpacing: screenWidth < 600 ? 4 : 8,
                    color: widget.colors.textPrimary,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                  decoration: InputDecoration(
                    hintText: '000000',
                    hintStyle: GoogleFonts.robotoMono(
                      fontSize: codeFontSize,
                      fontWeight: FontWeight.bold,
                      letterSpacing: screenWidth < 600 ? 4 : 8,
                      color: widget.colors.textDisabled,
                    ),
                    filled: true,
                    fillColor: widget.colors.backgroundPrimary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: widget.colors.borderDefault, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: widget.colors.borderDefault, width: 2),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: widget.colors.primary, width: 2),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: widget.colors.error, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return WidgetTranslations.of(context, ref).emailVerificationPleaseEnterCode;
                    }
                    if (value.length != 6) {
                      return WidgetTranslations.of(context, ref).emailVerificationCodeMustBe6Digits;
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // Clear error when typing
                    if (_errorMessage != null) {
                      setState(() {
                        _errorMessage = null;
                      });
                    }

                    // Auto-submit when 6 digits entered
                    if (value.length == 6 && !_isVerifying) {
                      _verifyCode();
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Success message
                if (_successMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: widget.colors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: widget.colors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: GoogleFonts.inter(fontSize: 14, color: widget.colors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_successMessage != null) const SizedBox(height: 16),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: widget.colors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: widget.colors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: widget.colors.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(fontSize: 14, color: widget.colors.error),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_errorMessage != null) const SizedBox(height: 16),

                // Verify button
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.colors.primary,
                      foregroundColor: widget.colors.backgroundCard,
                      disabledBackgroundColor: widget.colors.primary,
                      disabledForegroundColor: widget.colors.backgroundCard,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 35),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                      minimumSize: const Size(double.infinity, 44),
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            WidgetTranslations.of(context, ref).verifyEmail,
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Resend button
                TextButton(
                  onPressed: _resendCooldown > 0 || _isResending ? null : _sendVerificationCode,
                  child: _isResending
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(widget.colors.primary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              WidgetTranslations.of(context, ref).emailVerificationSending,
                              style: GoogleFonts.inter(fontSize: 14, color: widget.colors.textSecondary),
                            ),
                          ],
                        )
                      : Text(
                          _resendCooldown > 0
                              ? WidgetTranslations.of(context, ref).emailVerificationResendIn(_resendCooldown)
                              : WidgetTranslations.of(context, ref).emailVerificationDidntReceive,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: _resendCooldown > 0 ? widget.colors.textDisabled : widget.colors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),

                const SizedBox(height: 8),

                // Info text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.colors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: widget.colors.primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          WidgetTranslations.of(context, ref).verificationCodeExpiresInfo,
                          style: GoogleFonts.inter(fontSize: 12, color: widget.colors.textSecondary),
                        ),
                      ),
                    ],
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
