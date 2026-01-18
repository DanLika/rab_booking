import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../../shared/models/booking_model.dart';

part 'overbooking_conflict.freezed.dart';
part 'overbooking_conflict.g.dart';

/// Overbooking conflict model representing a detected conflict between two bookings
@freezed
class OverbookingConflict with _$OverbookingConflict {
  const factory OverbookingConflict({
    /// Unique conflict ID (generated from booking IDs)
    required String id,

    /// Unit ID where conflict occurs
    required String unitId,

    /// Unit name for display
    required String unitName,

    /// First booking in conflict
    required BookingModel booking1,

    /// Guest name for first booking (for UI benefit)
    String? guest1Name,

    /// Second booking in conflict
    required BookingModel booking2,

    /// Guest name for second booking (for UI benefit)
    String? guest2Name,

    /// List of dates where conflict occurs
    required List<DateTime> conflictDates,

    /// When conflict was detected
    required DateTime detectedAt,

    /// Whether conflict has been resolved
    @Default(false) bool isResolved,
  }) = _OverbookingConflict;

  factory OverbookingConflict.fromJson(Map<String, dynamic> json) =>
      _$OverbookingConflictFromJson(json);
}
