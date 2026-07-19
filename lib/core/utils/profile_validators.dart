/// Why a field failed validation, as a localizable code.
///
/// [ProfileValidators] is a static utility without [BuildContext], so each
/// method returns a code and the screen maps it to [AppLocalizations] via
/// `ProfileValidatorErrorL10n`. Keeping English prose in the returned string
/// is what exposed owners to untranslated messages; the code path prevents
/// new regressions the same way [PasswordError] did for passwords.
enum ProfileValidatorError {
  nameRequired,
  nameTooShort,
  nameTooLong,
  emailRequired,
  emailInvalid,
  phoneInvalid,
  ibanLength,
  ibanFormat,
  swiftLength,
  swiftFormat,
}

/// Validation utilities for user profile fields
class ProfileValidators {
  ProfileValidators._();

  // ========== INTERNAL ==========

  /// English text for the legacy [String?] API.
  ///
  /// Kept ONLY for backward-compatibility. Screens should call the
  /// [ProfileValidatorError?]-returning twin and map via
  /// `ProfileValidatorErrorL10n` — see `profile_validator_error_l10n.dart`.
  static String _englishFor(ProfileValidatorError e) => switch (e) {
    ProfileValidatorError.nameRequired => 'Name is required',
    ProfileValidatorError.nameTooShort => 'Name must be at least 2 characters',
    ProfileValidatorError.nameTooLong => 'Name must be less than 80 characters',
    ProfileValidatorError.emailRequired => 'Email is required',
    ProfileValidatorError.emailInvalid => 'Please enter a valid email address',
    ProfileValidatorError.phoneInvalid => 'Please enter a valid phone number',
    ProfileValidatorError.ibanLength => 'IBAN must be 15-34 characters',
    ProfileValidatorError.ibanFormat => 'Invalid IBAN format',
    ProfileValidatorError.swiftLength =>
      'SWIFT code must be 8 or 11 characters',
    ProfileValidatorError.swiftFormat =>
      'SWIFT code can only contain letters and numbers',
  };

  // ========== NAME VALIDATION ==========

  /// Localizable code twin of [validateName]. Screens use this and map via
  /// `AppLocalizations.profileValidatorErrorText(code)`.
  static ProfileValidatorError? nameError(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ProfileValidatorError.nameRequired;
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) return ProfileValidatorError.nameTooShort;
    if (trimmed.length > 80) return ProfileValidatorError.nameTooLong;
    return null;
  }

  /// Validate display name (2-80 characters)
  ///
  /// Returns an English string for legacy call sites (form fields that don't
  /// yet have a [BuildContext]). New code should use [nameError] + l10n.
  static String? validateName(String? value) {
    final e = nameError(value);
    return e == null ? null : _englishFor(e);
  }

  // ========== EMAIL VALIDATION ==========

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Localizable code twin of [validateEmail].
  static ProfileValidatorError? emailError(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ProfileValidatorError.emailRequired;
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return ProfileValidatorError.emailInvalid;
    }
    return null;
  }

  /// Validate email (RFC 5322 compliant).
  ///
  /// Returns English prose for legacy call sites. New code uses [emailError]
  /// + `AppLocalizations.profileValidatorErrorText`.
  static String? validateEmail(String? value) {
    final e = emailError(value);
    return e == null ? null : _englishFor(e);
  }

  // ========== PHONE VALIDATION ==========

  static final RegExp _phoneRegex = RegExp(r'^\+?[0-9]{6,15}$');

  /// Localizable code twin of [validatePhone].
  ///
  /// Returns null when phone is empty (phone is optional).
  static ProfileValidatorError? phoneError(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-\(\)\.]+'), '');
    if (!_phoneRegex.hasMatch(cleaned)) {
      return ProfileValidatorError.phoneInvalid;
    }
    return null;
  }

  /// Validate phone number (flexible format).
  /// Accepts: +385911234567, 0911234567, 091-123-4567, (091) 123 4567
  ///
  /// Returns English prose for legacy call sites. New code uses [phoneError]
  /// + `AppLocalizations.profileValidatorErrorText`.
  static String? validatePhone(String? value) {
    final e = phoneError(value);
    return e == null ? null : _englishFor(e);
  }

  // ========== ADDRESS VALIDATION ==========

  /// Validate address field (2-120 characters)
  static String? validateAddressField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return null; // Address fields are optional
    }

    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return '$fieldName must be at least 2 characters';
    }

    if (trimmed.length > 120) {
      return '$fieldName must be less than 120 characters';
    }

    return null;
  }

  /// Validate postal code (alphanumeric, 2-20 characters)
  static String? validatePostalCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }

    final trimmed = value.trim();
    if (trimmed.length < 2 || trimmed.length > 20) {
      return 'Postal code must be 2-20 characters';
    }

    // Allow alphanumeric and spaces/dashes
    final postalRegex = RegExp(r'^[a-zA-Z0-9\s-]+$');
    if (!postalRegex.hasMatch(trimmed)) {
      return 'Invalid postal code format';
    }

    return null;
  }

  // ========== WEBSITE VALIDATION ==========

  /// Validate website URL
  static String? validateWebsite(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }

    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );

    if (!urlRegex.hasMatch(value.trim())) {
      return 'Please enter a valid URL (starting with http:// or https://)';
    }

    return null;
  }

  // ========== TAX/VAT VALIDATION ==========

  /// Validate Tax ID (alphanumeric, 5-20 characters)
  static String? validateTaxId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }

    final trimmed = value.trim();
    if (trimmed.length < 5 || trimmed.length > 20) {
      return 'Tax ID must be 5-20 characters';
    }

    // Alphanumeric only
    final taxIdRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!taxIdRegex.hasMatch(trimmed)) {
      return 'Tax ID can only contain letters and numbers';
    }

    return null;
  }

  /// Validate VAT ID (alphanumeric, 5-20 characters)
  static String? validateVatId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }

    final trimmed = value.trim();
    if (trimmed.length < 5 || trimmed.length > 20) {
      return 'VAT ID must be 5-20 characters';
    }

    // Alphanumeric only (some countries use letters)
    final vatIdRegex = RegExp(r'^[a-zA-Z0-9]+$');
    if (!vatIdRegex.hasMatch(trimmed)) {
      return 'VAT ID can only contain letters and numbers';
    }

    return null;
  }

  // ========== IBAN VALIDATION ==========

  static final RegExp _ibanRegex = RegExp(r'^[A-Z]{2}[0-9A-Z]+$');

  /// Localizable code twin of [validateIban].
  ///
  /// Returns null when value is empty (IBAN is optional).
  static ProfileValidatorError? ibanError(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final trimmed = value.replaceAll(' ', '').toUpperCase();
    if (trimmed.length < 15 || trimmed.length > 34) {
      return ProfileValidatorError.ibanLength;
    }
    if (!_ibanRegex.hasMatch(trimmed)) return ProfileValidatorError.ibanFormat;
    return null;
  }

  /// Validate IBAN (simplified — alphanumeric, 15–34 characters).
  ///
  /// Returns English prose for legacy call sites. New code uses [ibanError]
  /// + `AppLocalizations.profileValidatorErrorText`.
  static String? validateIban(String? value) {
    final e = ibanError(value);
    return e == null ? null : _englishFor(e);
  }

  // ========== SWIFT/BIC VALIDATION ==========

  static final RegExp _swiftRegex = RegExp(r'^[A-Z0-9]+$');

  /// Localizable code twin of [validateSwift].
  ///
  /// Returns null when value is empty (SWIFT is optional).
  static ProfileValidatorError? swiftError(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final trimmed = value.replaceAll(' ', '').toUpperCase();
    if (trimmed.length != 8 && trimmed.length != 11) {
      return ProfileValidatorError.swiftLength;
    }
    if (!_swiftRegex.hasMatch(trimmed)) {
      return ProfileValidatorError.swiftFormat;
    }
    return null;
  }

  /// Validate SWIFT/BIC code (8 or 11 alphanumeric characters).
  ///
  /// Returns English prose for legacy call sites. New code uses [swiftError]
  /// + `AppLocalizations.profileValidatorErrorText`.
  static String? validateSwift(String? value) {
    final e = swiftError(value);
    return e == null ? null : _englishFor(e);
  }
}
