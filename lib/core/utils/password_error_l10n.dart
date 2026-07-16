import '../../l10n/app_localizations.dart';
import 'password_validator.dart';

/// Maps [PasswordError] codes to localized text.
///
/// [PasswordValidator] is a pure static utility with no `BuildContext`, so it
/// returns codes rather than prose. This is the single place those codes become
/// words — keeping the validator testable without a widget tree, and keeping
/// Croatian owners from reading English on the register / change-password /
/// login forms.
extension PasswordErrorL10n on AppLocalizations {
  /// Sentence form — for a field's error text.
  String passwordErrorText(PasswordError e) => switch (e) {
    PasswordError.required => passwordRequired,
    PasswordError.tooShort => passwordTooShort,
    PasswordError.tooLong => passwordTooLong,
    PasswordError.tooCommon => passwordTooCommon,
    PasswordError.noUppercase => passwordNeedsUppercase,
    PasswordError.noLowercase => passwordNeedsLowercase,
    PasswordError.noDigit => passwordNeedsDigit,
    PasswordError.noSpecial => passwordNeedsSpecial,
    PasswordError.repeating => passwordNoRepeating,
    PasswordError.sequential => passwordNoSequential,
    PasswordError.confirmRequired => passwordConfirmRequired,
    PasswordError.mismatch => passwordsDoNotMatch,
  };

  /// Checklist form — for the strength meter's "still missing" list, where
  /// [PasswordError.tooShort] reads as a requirement rather than a complaint.
  String passwordRequirementText(PasswordError e) => switch (e) {
    PasswordError.tooShort => passwordMinChars,
    _ => passwordErrorText(e),
  };
}
