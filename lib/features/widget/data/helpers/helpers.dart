/// Widget data layer helper classes.
///
/// This barrel file exports helper classes that extract complex logic
/// from the main repositories for better separation of concerns.
///
/// ## Available Helpers
///
/// - [AvailabilityChecker] - Checks availability against bookings, iCal, blocked dates
/// - [BookingPriceCalculator] - Calculates prices using price hierarchy
/// - [CalendarDataBuilder] - Builds calendar maps from parsed data
///
/// ## Usage
/// ```dart
/// import 'package:rab_booking/features/widget/data/helpers/helpers.dart';
///
/// final checker = AvailabilityChecker(firestore);
/// final calculator = BookingPriceCalculator(firestore: firestore);
/// final builder = CalendarDataBuilder();
/// ```
library;

export 'availability_checker.dart';
export 'booking_price_calculator.dart';
export 'calendar_data_builder.dart';
