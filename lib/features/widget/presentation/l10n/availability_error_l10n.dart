import 'package:intl/intl.dart';

import '../../data/helpers/availability_checker.dart';
import '../../domain/constants/widget_constants.dart';
import 'widget_translations.dart';

/// Turns an [AvailabilityCheckResult] into the message the guest should read.
///
/// The checker already reports WHY a range failed — `errorCode`, plus
/// `conflictDate` / `icalSource` — and `widget_translations.dart` already
/// carries a parameterised string for every one of those codes, in all four
/// languages. None of it was reachable: the calendars collapsed every outcome
/// into the generic "already booked" line.
///
/// That is not cosmetic. "Dolazak nije moguć na datum 20.8." tells a guest to
/// shift by a day; "already booked" tells them to give up on the range. #935
/// wired only [AvailabilityErrorCode.checkError]; this finishes the other five.
extension AvailabilityErrorL10n on WidgetTranslations {
  /// Guest-facing text for a failed availability check.
  ///
  /// Falls back to the generic booked line when a code arrives without the
  /// detail its string needs (e.g. a blocked-date result with no
  /// `conflictDate`) — a vague-but-true message beats a crash.
  String availabilityErrorText(AvailabilityCheckResult result) {
    final date = result.conflictDate;
    final formatted = date == null
        ? null
        : DateFormat.yMMMd(locale.toString()).format(date);

    switch (result.errorCode) {
      case AvailabilityErrorCode.checkError:
        // The check itself failed — never claim the dates are taken (#935).
        return errorAvailabilityCheck;
      case AvailabilityErrorCode.icalConflict:
        final source = result.icalSource;
        return source == null
            ? errorCannotSelectBookedDates
            : errorIcalConflict(source);
      case AvailabilityErrorCode.blockedDate:
        return formatted == null
            ? errorCannotSelectBookedDates
            : errorBlockedDate(formatted);
      case AvailabilityErrorCode.blockedCheckIn:
        return formatted == null
            ? errorCannotSelectBookedDates
            : errorBlockedCheckIn(formatted);
      case AvailabilityErrorCode.blockedCheckOut:
        return formatted == null
            ? errorCannotSelectBookedDates
            : errorBlockedCheckOut(formatted);
      case AvailabilityErrorCode.bookingConflict:
        return errorBookingConflict;
      case null:
        return errorCannotSelectBookedDates;
    }
  }
}
