import '../../../../l10n/app_localizations.dart';

/// Validators for bank account details form.
class BankDetailsValidators {
  /// Validates IBAN format.
  ///
  /// - Must not be empty.
  /// - Must follow basic IBAN structure (country code, check digits, account number).
  static String? validateIban(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.bankAccountIbanRequired;
    }

    // Basic IBAN validation regex (country code + check digits + alphanumeric chars)
    // This is a general format check, not a checksum validation.
    final ibanRegex = RegExp(r'^[A-Z]{2}[0-9]{2}[a-zA-Z0-9]{11,30}$');
    if (!ibanRegex.hasMatch(value.replaceAll(' ', '').toUpperCase())) {
      return l10n.bankAccountInvalidIban;
    }
    return null;
  }

  /// Validates SWIFT/BIC format.
  ///
  /// - Must not be empty.
  /// - Must be 8 or 11 characters long and follow SWIFT structure.
  static String? validateSwift(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.bankAccountSwiftRequired;
    }

    // SWIFT/BIC validation regex (8 or 11 characters)
    final swiftRegex = RegExp(r'^[A-Z]{6}[A-Z0-9]{2}([A-Z0-9]{3})?$');
    if (!swiftRegex.hasMatch(value.trim().toUpperCase())) {
      return l10n.bankAccountInvalidSwift;
    }
    return null;
  }
}
