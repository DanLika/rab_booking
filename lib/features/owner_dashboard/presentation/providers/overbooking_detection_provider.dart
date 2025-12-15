import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../core/constants/enums.dart';
import '../../utils/booking_overlap_detector.dart';
import '../providers/owner_calendar_provider.dart';
import '../../domain/models/overbooking_conflict.dart';
import '../../../../shared/providers/repository_providers.dart';

part 'overbooking_detection_provider.g.dart';

/// Helper function to get conflict dates between two bookings
List<DateTime> _getConflictDates(BookingModel booking1, BookingModel booking2) {
  final conflictDates = <DateTime>[];
  
  // Find the overlap range
  final overlapStart = booking1.checkIn.isAfter(booking2.checkIn) 
      ? booking1.checkIn 
      : booking2.checkIn;
  final overlapEnd = booking1.checkOut.isBefore(booking2.checkOut) 
      ? booking1.checkOut 
      : booking2.checkOut;
  
  // Generate list of dates in the overlap range
  var currentDate = DateTime(overlapStart.year, overlapStart.month, overlapStart.day);
  final endDate = DateTime(overlapEnd.year, overlapEnd.month, overlapEnd.day);
  
  while (currentDate.isBefore(endDate)) {
    conflictDates.add(currentDate);
    currentDate = currentDate.add(const Duration(days: 1));
  }
  
  return conflictDates;
}

/// Helper function to generate unique conflict ID from booking IDs
String _generateConflictId(BookingModel booking1, BookingModel booking2) {
  // Sort IDs to ensure same conflict always gets same ID
  final ids = [booking1.id, booking2.id]..sort();
  return '${ids[0]}_${ids[1]}';
}

/// Overbooking detection provider
/// Automatically detects conflicts between bookings in real-time
@riverpod
Stream<List<OverbookingConflict>> overbookingConflicts(Ref ref) async* {
  // Watch calendar bookings provider
  final bookingsAsync = ref.watch(calendarBookingsProvider);
  
  // Wait for bookings to load
  if (bookingsAsync.isLoading) {
    yield [];
    return;
  }
  
  if (bookingsAsync.hasError || bookingsAsync.value == null) {
    yield [];
    return;
  }
  
  final bookingsByUnit = bookingsAsync.value!;
  
  // Get units to get unit names
  final unitsAsync = ref.watch(allOwnerUnitsProvider);
  if (unitsAsync.isLoading || unitsAsync.value == null) {
    yield [];
    return;
  }
  
  final units = unitsAsync.value!;
  final unitMap = {for (var unit in units) unit.id: unit};
  
  // Detect conflicts
  final conflicts = <OverbookingConflict>[];
  final seenConflictIds = <String>{};
  
  // For each unit, check all booking pairs
  for (final entry in bookingsByUnit.entries) {
    final unitId = entry.key;
    final unitBookings = entry.value;
    final unit = unitMap[unitId];
    final unitName = unit?.name ?? 'Unknown Unit';
    
    // Filter to only active bookings (pending, confirmed)
    // Cancelled and completed bookings don't block dates
    final activeBookings = unitBookings.where((booking) {
      return booking.status != BookingStatus.cancelled &&
          booking.status != BookingStatus.completed;
    }).toList();
    
    // Check all pairs for overlaps
    for (int i = 0; i < activeBookings.length; i++) {
      for (int j = i + 1; j < activeBookings.length; j++) {
        final booking1 = activeBookings[i];
        final booking2 = activeBookings[j];
        
        // Check if bookings overlap
        if (BookingOverlapDetector.doBookingsOverlap(
          start1: booking1.checkIn,
          end1: booking1.checkOut,
          start2: booking2.checkIn,
          end2: booking2.checkOut,
        )) {
          // Generate unique conflict ID
          final conflictId = _generateConflictId(booking1, booking2);
          
          // Skip if we've already seen this conflict
          if (seenConflictIds.contains(conflictId)) {
            continue;
          }
          
          seenConflictIds.add(conflictId);
          
          // Get conflict dates
          final conflictDates = _getConflictDates(booking1, booking2);
          
          // Create conflict object
          final conflict = OverbookingConflict(
            id: conflictId,
            unitId: unitId,
            unitName: unitName,
            booking1: booking1,
            booking2: booking2,
            conflictDates: conflictDates,
            detectedAt: DateTime.now(),
          );
          
          conflicts.add(conflict);
        }
      }
    }
  }
  
  yield conflicts;
}

/// Helper provider to get conflict count
@riverpod
int overbookingConflictCount(Ref ref) {
  final conflictsAsync = ref.watch(overbookingConflictsProvider);
  return conflictsAsync.valueOrNull?.length ?? 0;
}

/// Helper provider to check if a booking is in conflict
@riverpod
bool isBookingInConflict(Ref ref, String bookingId) {
  final conflictsAsync = ref.watch(overbookingConflictsProvider);
  final conflicts = conflictsAsync.valueOrNull ?? [];
  
  return conflicts.any((conflict) =>
      conflict.booking1.id == bookingId || conflict.booking2.id == bookingId);
}

/// Helper provider to get conflicts for a specific unit
@riverpod
List<OverbookingConflict> conflictsForUnit(Ref ref, String unitId) {
  final conflictsAsync = ref.watch(overbookingConflictsProvider);
  final conflicts = conflictsAsync.valueOrNull ?? [];

  return conflicts.where((conflict) => conflict.unitId == unitId).toList();
}

/// Auto-resolution listener provider
/// Automatically rejects pending bookings when they conflict with confirmed bookings
@riverpod
class OverbookingAutoResolver extends _$OverbookingAutoResolver {
  final _resolvedConflictIds = <String>{};

  @override
  void build() {
    // Watch for conflicts
    ref.listen(overbookingConflictsProvider, (previous, next) {
      final conflicts = next.valueOrNull ?? [];
      _autoResolveConflicts(conflicts);
    });
  }

  /// Automatically resolve conflicts where one booking is pending and another is confirmed
  Future<void> _autoResolveConflicts(List<OverbookingConflict> conflicts) async {
    for (final conflict in conflicts) {
      // Skip if already resolved
      if (_resolvedConflictIds.contains(conflict.id)) {
        continue;
      }

      final booking1 = conflict.booking1;
      final booking2 = conflict.booking2;

      // Check if one is pending and other is confirmed
      final isPending1 = booking1.status == BookingStatus.pending;
      final isPending2 = booking2.status == BookingStatus.pending;
      final isConfirmed1 = booking1.status == BookingStatus.confirmed;
      final isConfirmed2 = booking2.status == BookingStatus.confirmed;

      BookingModel? bookingToReject;

      if (isPending1 && isConfirmed2) {
        // Reject booking1 (pending), keep booking2 (confirmed)
        bookingToReject = booking1;
      } else if (isPending2 && isConfirmed1) {
        // Reject booking2 (pending), keep booking1 (confirmed)
        bookingToReject = booking2;
      }

      // If we have a booking to reject, update its status
      if (bookingToReject != null) {
        try {
          final repository = ref.read(ownerBookingsRepositoryProvider);

          // Cancel the pending booking (auto-rejected due to overbooking)
          await repository.cancelBooking(
            bookingToReject.id,
            'Automatically cancelled due to overbooking conflict with confirmed booking',
          );

          // Mark this conflict as resolved
          _resolvedConflictIds.add(conflict.id);

          // Invalidate calendar provider to refresh UI
          ref.invalidate(calendarBookingsProvider);

          debugPrint('Auto-resolved conflict ${conflict.id}: Cancelled ${bookingToReject.id}');
        } catch (e) {
          debugPrint('Error auto-resolving conflict ${conflict.id}: $e');
        }
      }
    }
  }
}

