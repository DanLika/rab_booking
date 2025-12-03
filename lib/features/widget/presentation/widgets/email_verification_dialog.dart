import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../core/services/logging_service.dart';
import '../../../../../shared/utils/ui/snackbar_helper.dart';

/// Email Verification Dialog
///
/// Displays a 6-digit code input for email verification
/// Integrates with Firebase Cloud Functions for OTP verification
class EmailVerificationDialog extends StatefulWidget {
  final String email;
  final WidgetColorScheme colors;

  const EmailVerificationDialog({
    super.key,
    required this.email,
    required this.colors,
  });

  @override
  State<EmailVerificationDialog> createState() =>
      _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<EmailVerificationDialog> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isVerifying = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  String? _errorMessage;

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
      LoggingService.logOperation(
        '[EmailVerification] Sending code to ${widget.email}',
      );

      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('sendEmailVerificationCode');

      await callable.call({'email': widget.email});

      LoggingService.logSuccess('[EmailVerification] Code sent successfully');

      if (mounted) {
        SnackBarHelper.showSuccess(
          context: context,
          message: 'Verification code sent! Check your inbox.',
        );

        // Start 60-second cooldown
        setState(() {
          _resendCooldown = 60;
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
          _errorMessage = e.message ?? 'Failed to send verification code';
        });
      }
    } catch (e) {
      await LoggingService.logError('[EmailVerification] Unexpected error', e);

      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to send code: $e';
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

    try {
      LoggingService.logOperation('[EmailVerification] Verifying code');

      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('verifyEmailCode');

      final result = await callable.call({
        'email': widget.email,
        'code': _codeController.text.trim(),
      });

      final data = result.data as Map<String, dynamic>;

      if (data['verified'] == true) {
        LoggingService.logSuccess('[EmailVerification] Email verified!');

        if (mounted) {
          // Close dialog and return success
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception('Verification failed');
      }
    } on FirebaseFunctionsException catch (e) {
      await LoggingService.logError(
        '[EmailVerification] Verification failed',
        e,
      );

      if (mounted) {
        setState(() {
          _errorMessage = e.message ?? 'Invalid verification code';
        });
      }
    } catch (e) {
      await LoggingService.logError('[EmailVerification] Unexpected error', e);

      if (mounted) {
        setState(() {
          _errorMessage = 'Verification failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: widget.colors.backgroundCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450),
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.verified_user,
                    color: widget.colors.primary,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Verify Email',
                      style: GoogleFonts.inter(
                        fontSize: 24,
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
                  color: widget.colors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.colors.borderDefault),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      color: widget.colors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.email,
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
                'Enter the 6-digit code sent to your email',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: widget.colors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Code input
              TextFormField(
                controller: _codeController,
                autofocus: true,
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoMono(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: widget.colors.textPrimary,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  hintText: '000000',
                  hintStyle: GoogleFonts.robotoMono(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    color: widget.colors.textDisabled,
                  ),
                  filled: true,
                  fillColor: widget.colors.backgroundPrimary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: widget.colors.borderDefault,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: widget.colors.borderDefault,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: widget.colors.primary,
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: widget.colors.error,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the code';
                  }
                  if (value.length != 6) {
                    return 'Code must be 6 digits';
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

              // Error message
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.colors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.colors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: widget.colors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: widget.colors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_errorMessage != null) const SizedBox(height: 16),

              // Verify button
              SizedBox(
                height: 42, // Reduced by 3px from 45px
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verifyCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.colors.primary,
                    foregroundColor: widget.colors.backgroundCard,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 35,
                    ), // Increased horizontal padding for wider button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 42),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          'Verify Email',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Resend button
              TextButton(
                onPressed: _resendCooldown > 0 || _isResending
                    ? null
                    : _sendVerificationCode,
                child: _isResending
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.colors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sending...',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: widget.colors.textSecondary,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        _resendCooldown > 0
                            ? 'Resend code in ${_resendCooldown}s'
                            : 'Didn\'t receive code? Resend',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: _resendCooldown > 0
                              ? widget.colors.textDisabled
                              : widget.colors.primary,
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
                    Icon(
                      Icons.info_outline,
                      color: widget.colors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Code expires in 10 minutes. Check spam folder if not received.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: widget.colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
