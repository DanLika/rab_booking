import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/services/logging_service.dart';

const _tag = '[EmailVerification]';

/// Response model for email verification status check.
///
/// Returned by [EmailVerificationService.checkStatus] with detailed
/// information about email verification state.
@immutable
class EmailVerificationStatus {
  /// Is email verified and not expired?
  final bool verified;

  /// Does verification document exist in Firestore?
  final bool exists;

  /// Is verification expired (past TTL)?
  final bool expired;

  /// How many minutes remaining until expiry (0 if expired).
  final int remainingMinutes;

  /// ISO timestamp when email was verified (null if not verified).
  final String? verifiedAt;

  /// Session ID for tracking (from backend).
  final String? sessionId;

  const EmailVerificationStatus({
    required this.verified,
    required this.exists,
    required this.expired,
    required this.remainingMinutes,
    this.verifiedAt,
    this.sessionId,
  });

  /// Parse response from Cloud Function.
  factory EmailVerificationStatus.fromJson(Map<String, dynamic> json) {
    return EmailVerificationStatus(
      verified: json['verified'] as bool? ?? false,
      exists: json['exists'] as bool? ?? false,
      expired: json['expired'] as bool? ?? false,
      remainingMinutes: json['remainingMinutes'] as int? ?? 0,
      verifiedAt: json['verifiedAt'] as String?,
      sessionId: json['sessionId'] as String?,
    );
  }

  /// Whether email is verified and NOT expired.
  ///
  /// Use this for quick boolean check before proceeding with booking.
  bool get isValid => verified && !expired;

  /// User-friendly status message for UI display.
  String get statusMessage {
    if (isValid) return 'Email verified ✓ (expires in $remainingMinutes min)';
    if (expired) return 'Verification expired. Please verify again.';
    if (exists) return 'Verification pending.';
    return 'Email not verified.';
  }

  @override
  String toString() =>
      'EmailVerificationStatus('
      'verified: $verified, '
      'expired: $expired, '
      'remainingMinutes: $remainingMinutes, '
      'sessionId: $sessionId)';
}

/// Service for email verification operations
///
/// Provides client wrappers for Cloud Functions:
/// - checkStatus: Check verification status without sending code
/// - sendCode: Send 6-digit verification code via email
/// - verifyCode: Verify code entered by user
///
/// Usage:
/// ```dart
/// // Check if email is already verified
/// final status = await EmailVerificationService.checkStatus('user@example.com');
/// if (status.isValid) {
///   // Skip verification dialog
/// }
///
/// // Send verification code
/// await EmailVerificationService.sendCode('user@example.com');
///
/// // Verify code
/// final verified = await EmailVerificationService.verifyCode('user@example.com', '123456');
/// ```
class EmailVerificationService {
  static final _functions = FirebaseFunctions.instance;

  /// Check email verification status without sending a new code
  ///
  /// Returns [EmailVerificationStatus] with current verification state.
  /// Throws [FirebaseFunctionsException] on error.
  ///
  /// This is a READ-ONLY operation - it does NOT modify Firestore state.
  /// Safe to call multiple times.
  ///
  /// Example:
  /// ```dart
  /// final status = await EmailVerificationService.checkStatus('user@example.com');
  /// if (status.isValid) {
  ///   print('Email verified! Valid for ${status.remainingMinutes} more minutes');
  /// }
  /// ```
  static Future<EmailVerificationStatus> checkStatus(String email) async {
    try {
      LoggingService.logOperation('$_tag Checking status for: $email');

      final callable = _functions.httpsCallable('checkEmailVerificationStatus');
      final result = await callable.call({'email': email});

      final data = result.data as Map<String, dynamic>;
      final status = EmailVerificationStatus.fromJson(data);

      LoggingService.logSuccess(
        '$_tag Status: verified=${status.verified}, '
        'expired=${status.expired}, remaining=${status.remainingMinutes}min',
      );

      return status;
    } on FirebaseFunctionsException catch (e) {
      unawaited(LoggingService.logError('$_tag Functions error: ${e.code}', e));
      rethrow;
    } catch (e) {
      unawaited(LoggingService.logError('$_tag Unexpected error', e));
      rethrow;
    }
  }

  /// Send email verification code to user
  ///
  /// Generates 6-digit code and sends via Resend email service.
  /// Returns true if code was sent successfully.
  ///
  /// Rate limiting (enforced by backend):
  /// - Max 5 codes per email per day
  /// - Min 60 seconds between sends
  ///
  /// Example:
  /// ```dart
  /// final sent = await EmailVerificationService.sendCode('user@example.com');
  /// if (sent) {
  ///   showSnackbar('Verification code sent! Check your inbox.');
  /// }
  /// ```
  static Future<bool> sendCode(String email) async {
    try {
      LoggingService.logOperation('$_tag Sending code to: $email');

      final callable = _functions.httpsCallable('sendEmailVerificationCode');
      await callable.call({'email': email});

      LoggingService.logSuccess('$_tag Code sent');
      return true;
    } on FirebaseFunctionsException catch (e) {
      unawaited(LoggingService.logError('$_tag Failed to send: ${e.code}', e));
      return false;
    } catch (e) {
      unawaited(LoggingService.logError('$_tag Failed to send code', e));
      return false;
    }
  }

  /// Verify email code entered by user
  ///
  /// Returns true if code is valid and email is now verified.
  /// Max 3 attempts allowed (enforced by backend).
  ///
  /// Example:
  /// ```dart
  /// final verified = await EmailVerificationService.verifyCode(
  ///   'user@example.com',
  ///   '123456',
  /// );
  /// if (verified) {
  ///   // Proceed with booking
  /// }
  /// ```
  static Future<bool> verifyCode(String email, String code) async {
    try {
      LoggingService.logOperation('$_tag Verifying code');

      final callable = _functions.httpsCallable('verifyEmailCode');
      final result = await callable.call({'email': email, 'code': code});

      final data = result.data as Map<String, dynamic>;
      final verified = data['verified'] as bool? ?? false;

      if (verified) {
        LoggingService.logSuccess('$_tag Verified!');
      }

      return verified;
    } on FirebaseFunctionsException catch (e) {
      unawaited(LoggingService.logError('$_tag Verify failed: ${e.code}', e));
      return false;
    } catch (e) {
      unawaited(LoggingService.logError('$_tag Verification failed', e));
      return false;
    }
  }
}
