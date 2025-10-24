import 'package:freezed_annotation/freezed_annotation.dart';

part 'validation_result.freezed.dart';
part 'validation_result.g.dart';

/// Validation result for booking operations
@freezed
class ValidationResult with _$ValidationResult {
  const factory ValidationResult({
    required bool isValid,
    String? errorMessage,
    String? warningMessage,
    @Default({}) Map<String, dynamic> metadata,
  }) = _ValidationResult;

  factory ValidationResult.fromJson(Map<String, dynamic> json) =>
      _$ValidationResultFromJson(json);

  /// Create a success result
  factory ValidationResult.success({String? message}) {
    return ValidationResult(
      isValid: true,
      warningMessage: message,
    );
  }

  /// Create an error result
  factory ValidationResult.error(String message, {Map<String, dynamic>? metadata}) {
    return ValidationResult(
      isValid: false,
      errorMessage: message,
      metadata: metadata ?? {},
    );
  }

  /// Create a warning result (valid but with warning)
  factory ValidationResult.warning(String message) {
    return ValidationResult(
      isValid: true,
      warningMessage: message,
    );
  }
}

/// Extension methods for validation result
extension ValidationResultX on ValidationResult {
  /// Check if has error
  bool get hasError => !isValid && errorMessage != null;

  /// Check if has warning
  bool get hasWarning => isValid && warningMessage != null;

  /// Get display message (error or warning)
  String? get message => errorMessage ?? warningMessage;
}

/// Booking settings for validation
@freezed
class BookingSettings with _$BookingSettings {
  const factory BookingSettings({
    /// Minimum days in advance to book
    @Default(1) int minAdvanceDays,

    /// Maximum days in advance to book
    @Default(365) int maxAdvanceDays,

    /// Minimum nights per booking
    @Default(1) int minNights,

    /// Maximum nights per booking
    @Default(30) int maxNights,

    /// Allow same-day turnover
    @Default(false) bool allowSameDayTurnover,

    /// Check-in time (hour)
    @Default(15) int checkInHour,

    /// Check-out time (hour)
    @Default(10) int checkOutHour,

    /// Minimum hours between turnover
    @Default(2) int minTurnoverHours,

    /// Property time zone
    @Default('Europe/Zagreb') String timeZone,

    /// Allow bookings starting today
    @Default(false) bool allowSameDayBooking,

    /// Require minimum gap after last booking
    @Default(0) int minGapDays,
  }) = _BookingSettings;

  factory BookingSettings.fromJson(Map<String, dynamic> json) =>
      _$BookingSettingsFromJson(json);
}

/// Exception for booking conflicts
class BookingConflictException implements Exception {
  final String message;
  final Map<String, dynamic>? conflictDetails;

  BookingConflictException(
    this.message, {
    this.conflictDetails,
  });

  @override
  String toString() => message;
}

/// Exception for validation errors
class ValidationException implements Exception {
  final String message;
  final ValidationResult result;

  ValidationException(
    this.message, {
    required this.result,
  });

  @override
  String toString() => message;
}
