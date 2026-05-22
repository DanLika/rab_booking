import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';

import '../../../../core/services/logging_service.dart';
import '../models/availability_window.dart';

/// Wrapper around the `getUnitAvailability` callable Cloud Function.
///
/// Replaces the public-read `collectionGroup('ical_events')` query that the
/// widget used to issue against Firestore directly (SF-023). The CF runs the
/// equivalent server-side query via the Admin SDK, strips PII, and returns
/// `AvailabilityWindow[]`.
///
/// The CF is deployed to `europe-west1`. Per `.claude/rules/cloud-functions.md`
/// callers MUST use `FirebaseFunctions.instanceFor(region: 'europe-west1')` —
/// the default instance hits `us-central1` and would return `not-found`.
class FirebaseAvailabilityRepository {
  FirebaseAvailabilityRepository({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instanceFor(region: _region);

  static const _region = 'europe-west1';
  static const _callableName = 'getUnitAvailability';
  static const _defaultPollInterval = Duration(seconds: 30);
  static const _retryBackoff = Duration(seconds: 10);

  final FirebaseFunctions _functions;

  HttpsCallable get _callable => _functions.httpsCallable(
    _callableName,
    options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
  );

  /// One-shot fetch — used by [AvailabilityChecker] at booking submit time.
  Future<List<AvailabilityWindow>> fetchAvailability({
    required String propertyId,
    required String unitId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final result = await _callable.call(<String, dynamic>{
        'propertyId': propertyId,
        'unitId': unitId,
        'startDate': start.toUtc().toIso8601String(),
        'endDate': end.toUtc().toIso8601String(),
      });
      final data = (result.data as Map?)?.cast<String, dynamic>() ?? const {};
      final raw = (data['windows'] as List?) ?? const [];
      return raw
          .whereType<Map>()
          .map((m) => AvailabilityWindow.fromJson(m.cast<String, dynamic>()))
          .toList(growable: false);
    } on FirebaseFunctionsException catch (e, st) {
      await LoggingService.logError(
        '[AvailabilityRepo] fetchAvailability failed: ${e.code}',
        e,
        st,
      );
      rethrow;
    }
  }

  /// Polling stream — used by the calendar repository.
  ///
  /// Emits a fresh snapshot on every successful poll. On error (rate limit,
  /// network) the stream waits [_retryBackoff] and retries — never throws to
  /// the listener, so the calendar fails open (no overlay) rather than crashing.
  Stream<List<AvailabilityWindow>> streamAvailability({
    required String propertyId,
    required String unitId,
    required DateTime start,
    required DateTime end,
    Duration pollInterval = _defaultPollInterval,
  }) async* {
    while (true) {
      try {
        final windows = await fetchAvailability(
          propertyId: propertyId,
          unitId: unitId,
          start: start,
          end: end,
        );
        yield windows;
        await Future<void>.delayed(pollInterval);
      } on FirebaseFunctionsException {
        yield const [];
        await Future<void>.delayed(_retryBackoff);
      } catch (e, st) {
        await LoggingService.logError(
          '[AvailabilityRepo] streamAvailability unexpected error',
          e,
          st,
        );
        yield const [];
        await Future<void>.delayed(_retryBackoff);
      }
    }
  }
}
