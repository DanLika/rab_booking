import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/repositories/firebase_availability_repository.dart';

part 'owner_gate_status_provider.g.dart';

/// Result of the one-shot SF-079 owner-status gate probe.
///
/// The widget's normal availability stream
/// (`FirebaseAvailabilityRepository.streamAvailability`) catches every
/// `FirebaseFunctionsException` and yields `const []` so the calendar
/// fails OPEN (no blocks visible) rather than crashing on flaky networks.
/// That fail-open is correct for the calendar surface, but it hides the
/// SF-079 trial-gate signal which is permanent until the owner re-activates.
///
/// This enum captures that one-shot probe so the booking screen can surface
/// a localized "unavailable for new bookings" banner above the calendar AND
/// disable the booking CTA.
enum OwnerGateStatus {
  /// CF returned 200 (or non-gate error). Calendar + booking flow proceed
  /// normally.
  passing,

  /// CF returned `failed-precondition` — unit's owner is in
  /// `trial_expired` / `suspended` / off-spec accountStatus per SF-079.
  blocked,

  /// CF errored with a transient code (`unavailable`, `deadline-exceeded`,
  /// network). Treat as `passing` for banner purposes — we MUST NOT
  /// false-positive the gate on flaky networks and surface "unavailable
  /// for new bookings" to a guest of a healthy property.
  unknown,
}

/// One-shot SF-079 owner-status gate probe scoped to a `(propertyId, unitId)`
/// pair. Calls `getUnitAvailability` with a 1-day window once at widget
/// mount and discriminates `failed-precondition` from transient errors.
///
/// Riverpod caches per family arguments, so a calendar re-render does not
/// re-probe the CF; the value is sticky for the widget session.
@riverpod
Future<OwnerGateStatus> ownerGateStatus(
  Ref ref,
  String propertyId,
  String unitId,
) async {
  if (propertyId.isEmpty || unitId.isEmpty) {
    return OwnerGateStatus.unknown;
  }
  final repo = FirebaseAvailabilityRepository();
  final today = DateTime.now().toUtc();
  final tomorrow = today.add(const Duration(days: 1));
  try {
    await repo.fetchAvailability(
      propertyId: propertyId,
      unitId: unitId,
      start: today,
      end: tomorrow,
    );
    return OwnerGateStatus.passing;
  } on FirebaseFunctionsException catch (e) {
    if (e.code == 'failed-precondition') {
      return OwnerGateStatus.blocked;
    }
    return OwnerGateStatus.unknown;
  } catch (_) {
    return OwnerGateStatus.unknown;
  }
}
