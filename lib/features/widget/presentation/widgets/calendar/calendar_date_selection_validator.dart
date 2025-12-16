import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/calendar_date_status.dart';
import '../../../utils/date_normalizer.dart';
import '../../l10n/widget_translations.dart';
import '../../../../../shared/utils/ui/snackbar_helper.dart';

/// Validation result with optional error message.
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult.valid() : isValid = true, errorMessage = null;
  const ValidationResult.invalid(this.errorMessage) : isValid = false;
}

/// Shared validation logic for calendar date selection.
///
/// Used by both YearCalendarWidget and MonthCalendarWidget to avoid
/// ~150 lines of duplicated validation code.
///
/// Usage:
/// ```dart
/// final validator = CalendarDateSelectionValidator(context: context, ref: ref);
/// final result = validator.validateDateSelection(
///   date: date,
///   dateInfo: dateInfo,
///   rangeStart: _rangeStart,
///   rangeEnd: _rangeEnd,
/// );
/// if (!result.isValid) {
///   SnackBarHelper.showError(context: context, message: result.errorMessage!);
///   return;
/// }
/// ```
class CalendarDateSelectionValidator {
  final BuildContext context;
  final WidgetRef ref;

  const CalendarDateSelectionValidator({
    required this.context,
    required this.ref,
  });

  /// Duration for error snackbar display
  static const _errorSnackbarDuration = Duration(seconds: 3);

  /// Validates if a past date was selected.
  /// Returns invalid if date status is disabled (past).
  ValidationResult validatePastDate(DateStatus status) {
    if (status == DateStatus.disabled) {
      return ValidationResult.invalid(
        WidgetTranslations.of(context, ref).errorCannotSelectPastDates,
      );
    }
    return const ValidationResult.valid();
  }

  /// Validates advance booking window (minDaysAdvance, maxDaysAdvance).
  /// Only applies when selecting check-in date.
  ValidationResult validateAdvanceBooking({
    required DateTime date,
    required int? minDaysAdvance,
    required int? maxDaysAdvance,
    required bool isSelectingCheckIn,
  }) {
    if (!isSelectingCheckIn) return const ValidationResult.valid();

    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final daysInAdvance = date.difference(todayNormalized).inDays;

    final t = WidgetTranslations.of(context, ref);

    // Check minDaysAdvance
    if (minDaysAdvance != null && daysInAdvance < minDaysAdvance) {
      return ValidationResult.invalid(t.errorMinDaysAdvance(minDaysAdvance));
    }

    // Check maxDaysAdvance
    if (maxDaysAdvance != null && daysInAdvance > maxDaysAdvance) {
      return ValidationResult.invalid(t.errorMaxDaysAdvance(maxDaysAdvance));
    }

    return const ValidationResult.valid();
  }

  /// Validates blockCheckIn/blockCheckOut restrictions.
  ValidationResult validateCheckInOutRestrictions({
    required bool blockCheckIn,
    required bool blockCheckOut,
    required bool isSelectingCheckIn,
    required bool isSelectingCheckOut,
  }) {
    final t = WidgetTranslations.of(context, ref);

    if (isSelectingCheckIn && blockCheckIn) {
      return ValidationResult.invalid(t.errorCheckInNotAllowed);
    }

    if (isSelectingCheckOut && blockCheckOut) {
      return ValidationResult.invalid(t.errorCheckOutNotAllowed);
    }

    return const ValidationResult.valid();
  }

  /// Checks if date can be selected for check-in.
  /// Allows: available, partialCheckOut (checkout day of previous booking)
  bool canSelectForCheckIn(DateStatus status) {
    return status == DateStatus.available ||
        status == DateStatus.partialCheckOut;
  }

  /// Checks if date can be selected for check-out.
  /// Allows: available, partialCheckIn (checkin day of next booking)
  bool canSelectForCheckOut(DateStatus status) {
    return status == DateStatus.available ||
        status == DateStatus.partialCheckIn;
  }

  /// Validates if date can be selected based on status.
  /// Returns appropriate error message if not selectable.
  ValidationResult validateDateSelectable({
    required DateStatus status,
    required bool isSelectingCheckIn,
    required bool isSelectingCheckOut,
  }) {
    final t = WidgetTranslations.of(context, ref);

    if (isSelectingCheckIn && !canSelectForCheckIn(status)) {
      return ValidationResult.invalid(t.errorDateNotAvailableCheckIn);
    }

    if (isSelectingCheckOut && !canSelectForCheckOut(status)) {
      return ValidationResult.invalid(t.errorDateNotAvailableCheckOut);
    }

    return const ValidationResult.valid();
  }

  /// Validates global minimum nights requirement.
  ValidationResult validateMinNights({
    required int selectedNights,
    required int minNights,
  }) {
    if (selectedNights < minNights) {
      return ValidationResult.invalid(
        WidgetTranslations.of(
          context,
          ref,
        ).errorMinNights(minNights, selectedNights),
      );
    }
    return const ValidationResult.valid();
  }

  /// Validates per-date minNightsOnArrival requirement.
  ValidationResult validateMinNightsOnArrival({
    required int selectedNights,
    required int? minNightsOnArrival,
  }) {
    if (minNightsOnArrival != null &&
        minNightsOnArrival > 0 &&
        selectedNights < minNightsOnArrival) {
      return ValidationResult.invalid(
        WidgetTranslations.of(
          context,
          ref,
        ).errorMinNightsOnArrival(minNightsOnArrival, selectedNights),
      );
    }
    return const ValidationResult.valid();
  }

  /// Validates per-date maxNightsOnArrival requirement.
  ValidationResult validateMaxNightsOnArrival({
    required int selectedNights,
    required int? maxNightsOnArrival,
  }) {
    if (maxNightsOnArrival != null &&
        maxNightsOnArrival > 0 &&
        selectedNights > maxNightsOnArrival) {
      return ValidationResult.invalid(
        WidgetTranslations.of(
          context,
          ref,
        ).errorMaxNightsOnArrival(maxNightsOnArrival, selectedNights),
      );
    }
    return const ValidationResult.valid();
  }

  /// Determines if we're selecting check-in or check-out.
  ({bool isSelectingCheckIn, bool isSelectingCheckOut}) getSelectionMode({
    required DateTime? rangeStart,
    required DateTime? rangeEnd,
  }) {
    final isSelectingCheckIn = rangeStart == null || rangeEnd != null;
    final isSelectingCheckOut = rangeStart != null && rangeEnd == null;
    return (
      isSelectingCheckIn: isSelectingCheckIn,
      isSelectingCheckOut: isSelectingCheckOut,
    );
  }

  /// Full pre-selection validation (before setting range).
  /// Validates: past date, advance booking, check-in/out restrictions, selectability.
  ValidationResult validatePreSelection({
    required DateTime date,
    required CalendarDateInfo dateInfo,
    required DateTime? rangeStart,
    required DateTime? rangeEnd,
  }) {
    // Get selection mode
    final mode = getSelectionMode(rangeStart: rangeStart, rangeEnd: rangeEnd);

    // 1. Block past dates
    var result = validatePastDate(dateInfo.status);
    if (!result.isValid) return result;

    // 2. Validate advance booking (only for check-in)
    result = validateAdvanceBooking(
      date: date,
      minDaysAdvance: dateInfo.minDaysAdvance,
      maxDaysAdvance: dateInfo.maxDaysAdvance,
      isSelectingCheckIn: mode.isSelectingCheckIn,
    );
    if (!result.isValid) return result;

    // 3. Validate check-in/out restrictions
    result = validateCheckInOutRestrictions(
      blockCheckIn: dateInfo.blockCheckIn,
      blockCheckOut: dateInfo.blockCheckOut,
      isSelectingCheckIn: mode.isSelectingCheckIn,
      isSelectingCheckOut: mode.isSelectingCheckOut,
    );
    if (!result.isValid) return result;

    // 4. Validate date is selectable
    result = validateDateSelectable(
      status: dateInfo.status,
      isSelectingCheckIn: mode.isSelectingCheckIn,
      isSelectingCheckOut: mode.isSelectingCheckOut,
    );
    if (!result.isValid) return result;

    return const ValidationResult.valid();
  }

  /// Full range validation (after determining start/end).
  /// Validates: minNights, minNightsOnArrival, maxNightsOnArrival.
  ValidationResult validateRange({
    required DateTime start,
    required DateTime end,
    required int minNights,
    required CalendarDateInfo? checkInDateInfo,
  }) {
    // Bug #1 Fix: Use DateNormalizer for consistent date calculation
    final selectedNights = DateNormalizer.nightsBetween(start, end);

    // 1. Validate minNightsOnArrival (per-date, takes priority)
    if (checkInDateInfo != null) {
      var result = validateMinNightsOnArrival(
        selectedNights: selectedNights,
        minNightsOnArrival: checkInDateInfo.minNightsOnArrival,
      );
      if (!result.isValid) return result;

      // 2. Validate maxNightsOnArrival (per-date)
      result = validateMaxNightsOnArrival(
        selectedNights: selectedNights,
        maxNightsOnArrival: checkInDateInfo.maxNightsOnArrival,
      );
      if (!result.isValid) return result;
    }

    // 3. Fallback to global minNights (only if no per-date minNightsOnArrival)
    final minNightsOnArrival = checkInDateInfo?.minNightsOnArrival;
    if (minNightsOnArrival == null || minNightsOnArrival == 0) {
      final result = validateMinNights(
        selectedNights: selectedNights,
        minNights: minNights,
      );
      if (!result.isValid) return result;
    }

    return const ValidationResult.valid();
  }

  /// Shows error snackbar for invalid result.
  void showError(ValidationResult result) {
    if (!result.isValid && result.errorMessage != null) {
      SnackBarHelper.showError(
        context: context,
        message: result.errorMessage!,
        duration: _errorSnackbarDuration,
      );
    }
  }
}
