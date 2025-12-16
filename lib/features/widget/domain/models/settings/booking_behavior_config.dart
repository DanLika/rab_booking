import '../../constants/widget_constants.dart';

/// Booking behavior configuration.
///
/// Groups settings related to how bookings are handled:
/// - Owner approval requirements
/// - Guest cancellation policies
/// - Minimum/maximum stay requirements
/// - Weekend day definitions
///
/// ## Usage
/// ```dart
/// final config = BookingBehaviorConfig(
///   requireOwnerApproval: true,
///   minNights: 2,
///   weekendDays: [5, 6], // Friday-Saturday
/// );
/// ```
class BookingBehaviorConfig {
  /// If true, all bookings start as 'pending' and require owner approval.
  /// If false, bookings are auto-confirmed (for Stripe instant payment).
  final bool requireOwnerApproval;

  /// If true, guests can request cancellation through the widget.
  final bool allowGuestCancellation;

  /// Hours before check-in when cancellation is no longer allowed.
  /// null = no deadline (can cancel anytime).
  final int? cancellationDeadlineHours;

  /// Minimum nights required for a booking.
  final int minNights;

  /// Maximum nights allowed for a booking.
  /// null or 0 = no maximum limit.
  final int? maxNights;

  /// Days considered as weekend for pricing purposes.
  /// Uses ISO weekday format: 1=Monday, 7=Sunday.
  /// Default: [6, 7] (Saturday, Sunday)
  final List<int> weekendDays;

  /// Minimum days in advance required for booking.
  /// 0 = same-day booking allowed.
  final int minDaysAdvance;

  /// Maximum days in advance allowed for booking.
  /// 0 = no limit.
  final int maxDaysAdvance;

  const BookingBehaviorConfig({
    this.requireOwnerApproval = false,
    this.allowGuestCancellation = true,
    this.cancellationDeadlineHours = 48,
    this.minNights = WidgetConstants.defaultMinStayNights,
    this.maxNights,
    this.weekendDays = WidgetConstants.defaultWeekendDays,
    this.minDaysAdvance = WidgetConstants.defaultMinDaysAdvance,
    this.maxDaysAdvance = WidgetConstants.defaultMaxDaysAdvance,
  });

  /// Create from Firestore map data.
  ///
  /// Handles explicit null values correctly:
  /// - If key exists with null value → uses null (explicit null in Firestore)
  /// - If key doesn't exist → uses default value
  factory BookingBehaviorConfig.fromMap(Map<String, dynamic> map) {
    return BookingBehaviorConfig(
      requireOwnerApproval: map['require_owner_approval'] ?? false,
      allowGuestCancellation: map['allow_guest_cancellation'] ?? true,
      // Handle explicit null: if key exists use its value (even if null),
      // otherwise use default
      cancellationDeadlineHours: map.containsKey('cancellation_deadline_hours')
          ? map['cancellation_deadline_hours'] as int?
          : 48,
      minNights: (map['min_nights'] ?? WidgetConstants.defaultMinStayNights)
          .clamp(1, 365) as int,
      maxNights: map['max_nights'],
      weekendDays:
          (map['weekend_days'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          WidgetConstants.defaultWeekendDays,
      // Clamp to valid range to prevent negative values
      minDaysAdvance:
          (map['min_days_advance'] ?? WidgetConstants.defaultMinDaysAdvance)
              .clamp(0, 365) as int,
      maxDaysAdvance:
          (map['max_days_advance'] ?? WidgetConstants.defaultMaxDaysAdvance)
              .clamp(0, 730) as int,
    );
  }

  /// Convert to Firestore map.
  Map<String, dynamic> toMap() {
    return {
      'require_owner_approval': requireOwnerApproval,
      'allow_guest_cancellation': allowGuestCancellation,
      'cancellation_deadline_hours': cancellationDeadlineHours,
      'min_nights': minNights,
      'max_nights': maxNights,
      'weekend_days': weekendDays,
      'min_days_advance': minDaysAdvance,
      'max_days_advance': maxDaysAdvance,
    };
  }

  /// Check if the configuration itself is valid.
  ///
  /// Returns false if:
  /// - minDaysAdvance is negative
  /// - maxDaysAdvance is negative
  /// - minNights is less than 1
  /// - maxNights is set but less than minNights
  bool get isValidConfig {
    if (minDaysAdvance < 0) return false;
    if (maxDaysAdvance < 0) return false;
    if (minNights < 1) return false;
    if (maxNights != null && maxNights! > 0 && maxNights! < minNights) {
      return false;
    }
    return true;
  }

  /// Check if a booking duration is valid.
  bool isValidDuration(int nights) {
    if (nights < minNights) return false;
    final max = maxNights;
    return max == null || max <= 0 || nights <= max;
  }

  /// Check if a date is considered a weekend day.
  bool isWeekend(DateTime date) {
    return weekendDays.contains(date.weekday);
  }

  /// Check if booking can be made for a given advance notice.
  bool isValidAdvanceNotice(int daysInAdvance) {
    if (daysInAdvance < minDaysAdvance) return false;
    if (maxDaysAdvance > 0 && daysInAdvance > maxDaysAdvance) return false;
    return true;
  }

  /// Check if cancellation is still allowed based on check-in date.
  bool canCancelForCheckIn(DateTime checkIn) {
    if (!allowGuestCancellation) return false;
    if (cancellationDeadlineHours == null) return true;

    final now = DateTime.now();
    final deadline = checkIn.subtract(
      Duration(hours: cancellationDeadlineHours!),
    );
    return now.isBefore(deadline);
  }

  BookingBehaviorConfig copyWith({
    bool? requireOwnerApproval,
    bool? allowGuestCancellation,
    int? cancellationDeadlineHours,
    int? minNights,
    int? maxNights,
    List<int>? weekendDays,
    int? minDaysAdvance,
    int? maxDaysAdvance,
  }) {
    return BookingBehaviorConfig(
      requireOwnerApproval: requireOwnerApproval ?? this.requireOwnerApproval,
      allowGuestCancellation:
          allowGuestCancellation ?? this.allowGuestCancellation,
      cancellationDeadlineHours:
          cancellationDeadlineHours ?? this.cancellationDeadlineHours,
      minNights: minNights ?? this.minNights,
      maxNights: maxNights ?? this.maxNights,
      weekendDays: weekendDays ?? this.weekendDays,
      minDaysAdvance: minDaysAdvance ?? this.minDaysAdvance,
      maxDaysAdvance: maxDaysAdvance ?? this.maxDaysAdvance,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BookingBehaviorConfig) return false;
    return requireOwnerApproval == other.requireOwnerApproval &&
        allowGuestCancellation == other.allowGuestCancellation &&
        cancellationDeadlineHours == other.cancellationDeadlineHours &&
        minNights == other.minNights &&
        maxNights == other.maxNights &&
        _listEquals(weekendDays, other.weekendDays) &&
        minDaysAdvance == other.minDaysAdvance &&
        maxDaysAdvance == other.maxDaysAdvance;
  }

  @override
  int get hashCode => Object.hash(
    requireOwnerApproval,
    allowGuestCancellation,
    cancellationDeadlineHours,
    minNights,
    maxNights,
    Object.hashAll(weekendDays),
    minDaysAdvance,
    maxDaysAdvance,
  );

  @override
  String toString() =>
      'BookingBehaviorConfig(minNights: $minNights, maxNights: $maxNights, '
      'requireOwnerApproval: $requireOwnerApproval)';

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
