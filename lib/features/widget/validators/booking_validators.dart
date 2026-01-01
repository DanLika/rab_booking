import 'package:flutter/material.dart';
import 'package:rab_booking/l10n/app_localizations.dart';

/// Validators for booking form fields
class BookingValidators {
  /// Validate name field
  static String? validateName(String? value, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) {
      return l10n.validation_name_required;
    }
    if (value.trim().length < 2) {
      return l10n.validation_name_too_short;
    }
    return null;
  }

  /// Validate email field
  static String? validateEmail(String? value, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) {
      return l10n.validation_email_required;
    }

    final emailRegex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      caseSensitive: false,
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return l10n.validation_email_invalid;
    }

    return null;
  }

  /// Validate phone field
  static String? validatePhone(String? value, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) {
      return l10n.validation_phone_required;
    }

    // Remove spaces and special characters for validation
    final cleanedPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Check if it starts with + and has at least 8 digits
    if (cleanedPhone.startsWith('+') && cleanedPhone.length >= 9) {
      return null;
    }

    // Or check if it's a valid local format (at least 8 digits)
    if (cleanedPhone.length >= 8 && RegExp(r'^\d+$').hasMatch(cleanedPhone)) {
      return null;
    }

    return l10n.validation_phone_invalid;
  }

  /// Validate message (optional, but has character limit)
  static String? validateMessage(String? value, BuildContext context,
      {int maxLength = 255}) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.isEmpty) {
      return null; // Message is optional
    }

    if (value.length > maxLength) {
      return l10n.validation_notes_length(maxLength);
    }

    return null;
  }
}
