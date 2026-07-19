import '../../l10n/app_localizations.dart';
import 'profile_validators.dart';

/// Maps [ProfileValidatorError] codes to localized text.
///
/// [ProfileValidators] is a pure static utility with no [BuildContext], so it
/// returns codes rather than prose. This is the single place those codes become
/// words — keeping the validator testable without a widget tree, and keeping
/// owners from reading English on Croatian / other-locale profile and bank-
/// account forms.
///
/// Usage at call sites (replaces the tearoff with a localized lambda):
/// ```dart
/// validator: (v) {
///   final e = ProfileValidators.emailError(v);
///   return e == null ? null : l10n.profileValidatorErrorText(e);
/// },
/// ```
extension ProfileValidatorErrorL10n on AppLocalizations {
  /// Sentence form — for a field's error text.
  String profileValidatorErrorText(ProfileValidatorError e) => switch (e) {
    ProfileValidatorError.nameRequired => profileNameRequired,
    ProfileValidatorError.nameTooShort => profileNameTooShort,
    ProfileValidatorError.nameTooLong => profileNameTooLong,
    ProfileValidatorError.emailRequired => emailRequired,
    ProfileValidatorError.emailInvalid => profileEmailInvalid,
    ProfileValidatorError.phoneInvalid => profilePhoneInvalid,
    ProfileValidatorError.ibanLength => profileIbanLength,
    ProfileValidatorError.ibanFormat => profileIbanFormat,
    ProfileValidatorError.swiftLength => profileSwiftLength,
    ProfileValidatorError.swiftFormat => profileSwiftFormat,
  };
}
