import 'package:freezed_annotation/freezed_annotation.dart';
import '../../core/utils/timestamp_converter.dart';

part 'daily_price_model.freezed.dart';
part 'daily_price_model.g.dart';

/// Daily Price model (specific price for each date)
///
/// Fields that are saved AND used by the booking widget:
/// - price: Base price for this date
/// - available: Block entire day (false = closed/blocked)
/// - blockCheckIn: Prevent check-in on this date
/// - blockCheckOut: Prevent check-out on this date
/// - weekendPrice: Override price for weekend days
/// - minNightsOnArrival: Minimum nights if arriving on this date
/// - maxNightsOnArrival: Maximum nights if arriving on this date
/// - minDaysAdvance: Minimum days in advance to book
/// - maxDaysAdvance: Maximum days in advance to book
@freezed
class DailyPriceModel with _$DailyPriceModel {
  const factory DailyPriceModel({
    /// Daily Price ID (UUID)
    required String id,

    /// Unit ID
    @JsonKey(name: 'unit_id') required String unitId,

    /// Date
    @TimestampConverter() required DateTime date,

    /// Base price for this date
    required double price,

    /// Is this date available for booking? (false = closed/blocked)
    @Default(true) bool available,

    // === AVAILABILITY RESTRICTIONS ===

    /// Block check-in (guests cannot START their stay on this date)
    @JsonKey(name: 'block_checkin') @Default(false) bool blockCheckIn,

    /// Block check-out (guests cannot END their stay on this date)
    @JsonKey(name: 'block_checkout') @Default(false) bool blockCheckOut,

    // === LENGTH OF STAY RESTRICTIONS ===

    /// Minimum nights required if arriving on this date
    @JsonKey(name: 'min_nights_on_arrival') int? minNightsOnArrival,

    /// Maximum nights allowed if arriving on this date
    @JsonKey(name: 'max_nights_on_arrival') int? maxNightsOnArrival,

    // === PRICE PERSONALIZATION ===

    /// Weekend price override for this date
    @JsonKey(name: 'weekend_price') double? weekendPrice,

    // === ADVANCE BOOKING WINDOW ===

    /// Minimum days in advance required to book this date
    @JsonKey(name: 'min_days_advance') int? minDaysAdvance,

    /// Maximum days in advance allowed to book this date
    @JsonKey(name: 'max_days_advance') int? maxDaysAdvance,

    // === TIMESTAMPS ===

    /// Created at timestamp
    @TimestampConverter()
    @JsonKey(name: 'created_at')
    required DateTime createdAt,

    /// Updated at timestamp
    @NullableTimestampConverter()
    @JsonKey(name: 'updated_at')
    DateTime? updatedAt,
  }) = _DailyPriceModel;

  const DailyPriceModel._();

  /// Create from JSON
  factory DailyPriceModel.fromJson(Map<String, dynamic> json) =>
      _$DailyPriceModelFromJson(json);

  /// Get formatted price
  String get formattedPrice => '€${price.toStringAsFixed(2)}';

  /// Get formatted date (e.g., "Jan 15, 2024")
  String get formattedDate {
    final months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final month = months[date.month];
    return '$month ${date.day}, ${date.year}';
  }

  /// Get day of week
  String get dayOfWeek {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  /// Check if date is in the past
  bool get isPast {
    return date.isBefore(DateTime.now());
  }

  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is in the future
  bool get isFuture {
    return date.isAfter(DateTime.now()) && !isToday;
  }

  /// Check if date is a weekend using default days (Saturday=6 or Sunday=7)
  bool get isWeekend {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  /// Check if date is a weekend using custom weekend days
  /// [weekendDays] - list of weekday numbers (1=Mon, 2=Tue, ..., 5=Fri, 6=Sat, 7=Sun)
  /// Default: [5, 6] (Friday, Saturday nights for hotel pricing)
  bool isWeekendDay(List<int>? weekendDays) {
    final effectiveWeekendDays =
        weekendDays ?? const [5, 6]; // Default: Fri, Sat nights
    return effectiveWeekendDays.contains(date.weekday);
  }

  /// Get effective price for this date
  ///
  /// Returns [weekendPrice] if set and date is a weekend day,
  /// otherwise returns [price].
  ///
  /// [weekendDays] - optional custom weekend days (1=Mon...7=Sun). Default: [6,7]
  double getEffectivePrice({List<int>? weekendDays}) {
    // Apply weekend price if set and date is a weekend
    if (weekendPrice != null && isWeekendDay(weekendDays)) {
      return weekendPrice!;
    }
    return price;
  }

  /// Check if date can be used as check-in
  bool canCheckIn() {
    return available && !blockCheckIn;
  }

  /// Check if date can be used as check-out
  bool canCheckOut() {
    return available && !blockCheckOut;
  }

  /// Create bulk daily prices for a date range
  static List<DailyPriceModel> createBulk({
    required String unitId,
    required DateTime startDate,
    required DateTime endDate,
    required double price,
    bool? available,
    bool? blockCheckIn,
    bool? blockCheckOut,
    int? minNightsOnArrival,
    int? maxNightsOnArrival,
    double? weekendPrice,
    int? minDaysAdvance,
    int? maxDaysAdvance,
  }) {
    final List<DailyPriceModel> prices = [];
    DateTime currentDate = startDate;

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
      prices.add(
        DailyPriceModel(
          id: '', // Will be generated by database
          unitId: unitId,
          date: currentDate,
          price: price,
          available: available ?? true,
          blockCheckIn: blockCheckIn ?? false,
          blockCheckOut: blockCheckOut ?? false,
          minNightsOnArrival: minNightsOnArrival,
          maxNightsOnArrival: maxNightsOnArrival,
          weekendPrice: weekendPrice,
          minDaysAdvance: minDaysAdvance,
          maxDaysAdvance: maxDaysAdvance,
          createdAt: DateTime.now().toUtc(),
        ),
      );
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return prices;
  }
}
