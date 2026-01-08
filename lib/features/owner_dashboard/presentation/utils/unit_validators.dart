import '../../../../l10n/app_localizations.dart';

class UnitValidators {
  UnitValidators._();

  static String? validateUnitName(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.unitFormUnitNameRequired;
    }
    if (value.trim().length < 3) {
      return l10n.unitFormNameMinLength;
    }
    if (value.trim().length > 100) {
      return l10n.unitFormNameMaxLength;
    }
    return null;
  }

  static String? validateBeds(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.unitFormRequired;
    }
    final num = int.tryParse(value);
    if (num == null || num < 1 || num > 16) {
      return l10n.unitFormRange1to16;
    }
    return null;
  }

  static String? validatePrice(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.unitFormRequired;
    }
    final num = double.tryParse(value);
    if (num == null || num <= 0) {
      return l10n.unitFormInvalidAmount;
    }
    return null;
  }

  static String? validateCapacity(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.unitFormRequired;
    }
    final num = int.tryParse(value);
    if (num == null || num < 1) {
      return l10n.unitFormMin1;
    }
    return null;
  }

  static String? validateDescription(String? value, AppLocalizations l10n) {
    if (value != null && value.trim().length > 5000) {
      return l10n.unitFormDescriptionMaxLength;
    }
    return null;
  }
}
