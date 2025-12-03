import 'package:flutter/material.dart';
import '../../../domain/models/calendar_date_status.dart';
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
/// final validator = CalendarDateSelectionValidator(context: context);
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

  const CalendarDateSelectionValidator({required this.context});

  /// Validates if a past date was selected.
  /// Returns invalid if date status is disabled (past).
  ValidationResult validatePastDate(DateStatus status) {
    if (status == DateStatus.disabled) {
      return const ValidationResult.invalid('Cannot select past dates.');
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

    // Check minDaysAdvance
    if (minDaysAdvance != null && daysInAdvance < minDaysAdvance) {
      return ValidationResult.invalid(
        'This date requires booking at least $minDaysAdvance days in advance.',
      );
    }

    // Check maxDaysAdvance
    if (maxDaysAdvance != null && daysInAdvance > maxDaysAdvance) {
      return ValidationResult.invalid(
        'This date can only be booked up to $maxDaysAdvance days in advance.',
      );
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
    if (isSelectingCheckIn && blockCheckIn) {
      return const ValidationResult.invalid(
        'Check-in is not allowed on this date.',
      );
    }

    if (isSelectingCheckOut && blockCheckOut) {
      return const ValidationResult.invalid(
        'Check-out is not allowed on this date.',
      );
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
    if (isSelectingCheckIn && !canSelectForCheckIn(status)) {
      return const ValidationResult.invalid(
        'This date is not available for check-in. Please select an available date.',
      );
    }

    if (isSelectingCheckOut && !canSelectForCheckOut(status)) {
      return const ValidationResult.invalid(
        'This date is not available for check-out. Please select an available date.',
      );
    }

    return const ValidationResult.valid();
  }

  /// Validates global minimum nights requirement.
  ValidationResult validateMinNights({
    required int selectedNights,
    required int minNights,
  }) {
    if (selectedNights < minNights) {
      final nightWord = minNights == 1 ? 'night' : 'nights';
      final selectedWord = selectedNights == 1 ? 'night' : 'nights';
      return ValidationResult.invalid(
        'Minimum stay is $minNights $nightWord. You selected $selectedNights $selectedWord.',
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
      final nightWord = minNightsOnArrival == 1 ? 'night' : 'nights';
      final selectedWord = selectedNights == 1 ? 'night' : 'nights';
      return ValidationResult.invalid(
        'Minimum stay for this arrival date is $minNightsOnArrival $nightWord. You selected $selectedNights $selectedWord.',
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
      final nightWord = maxNightsOnArrival == 1 ? 'night' : 'nights';
      final selectedWord = selectedNights == 1 ? 'night' : 'nights';
      return ValidationResult.invalid(
        'Maximum stay for this arrival date is $maxNightsOnArrival $nightWord. You selected $selectedNights $selectedWord.',
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
    final selectedNights = end.difference(start).inDays;

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
        duration: const Duration(seconds: 3),
      );
    }
  }
}
