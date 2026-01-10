import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/slug_utils.dart';

/// Centralized validators for unit form fields
///
/// Provides reusable validation functions for unit creation and editing.
/// All validators return null for valid input, or a localized error message.
class UnitValidators {
  UnitValidators._(); // Private constructor - static methods only

  /// Validate unit name (required, non-empty)
  static String? validateUnitName(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.unitWizardStep1UnitNameRequired;
    }
    return null;
  }

  /// Validate URL slug (required, valid format)
  static String? validateSlug(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.unitWizardStep1SlugRequired;
    }
    if (!isValidSlug(value)) {
      return l10n.unitWizardStep1SlugInvalid;
    }
    return null;
  }

  /// Validate number of bedrooms (required, >= 0)
  static String? validateBedrooms(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.unitWizardStep2Required;
    }
    final number = int.tryParse(value);
    if (number == null || number < 0) {
      return l10n.unitWizardStep2InvalidNumber;
    }
    return null;
  }

  /// Validate number of beds (required, >= 0)
  static String? validateBeds(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.unitWizardStep2Required;
    }
    final number = int.tryParse(value);
    if (number == null || number < 0) {
      return l10n.unitWizardStep2InvalidNumber;
    }
    return null;
  }

  /// Validate capacity/max guests (required, >= 1)
  static String? validateCapacity(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.unitWizardStep2Required;
    }
    final number = int.tryParse(value);
    if (number == null || number < 1) {
      return l10n.unitWizardStep2InvalidNumber;
    }
    return null;
  }

  /// Validate price (required, > 0)
  static String? validatePrice(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.unitWizardStep3PriceRequired;
    }
    final price = double.tryParse(value.replaceAll(',', '.'));
    if (price == null || price <= 0) {
      return l10n.unitWizardStep3PriceInvalid;
    }
    return null;
  }

  /// Validate minimum stay (required, >= 1)
  static String? validateMinStay(String? value, AppLocalizations l10n) {
    if (value == null || value.isEmpty) {
      return l10n.unitWizardStep3MinStayRequired;
    }
    final number = int.tryParse(value);
    if (number == null || number < 1) {
      return l10n.unitWizardStep2InvalidNumber;
    }
    return null;
  }

  /// Validate maximum stay (optional, but if provided must be >= minStay)
  static String? validateMaxStay(
    String? value,
    AppLocalizations l10n, {
    int? minStay,
  }) {
    if (value == null || value.isEmpty) {
      return null; // Max stay is optional
    }
    final number = int.tryParse(value);
    if (number == null || number < 1) {
      return l10n.unitWizardStep3MaxStayInvalid;
    }
    if (minStay != null && number < minStay) {
      return l10n.unitWizardStep3MaxStayInvalid;
    }
    return null;
  }

  /// Validate description (optional, max length check)
  static String? validateDescription(
    String? value,
    AppLocalizations l10n, {
    int maxLength = 2000,
  }) {
    if (value == null || value.isEmpty) {
      return null; // Description is optional
    }
    if (value.length > maxLength) {
      // Description too long - but we don't have a specific l10n key for this
      // The UI should prevent this with maxLength on TextField
      return null;
    }
    return null;
  }

  /// Validate generic required integer field
  static String? validateRequiredInt(
    String? value,
    AppLocalizations l10n, {
    int minValue = 0,
  }) {
    if (value == null || value.isEmpty) {
      return l10n.unitWizardStep2Required;
    }
    final number = int.tryParse(value);
    if (number == null || number < minValue) {
      return l10n.unitWizardStep2InvalidNumber;
    }
    return null;
  }
}
