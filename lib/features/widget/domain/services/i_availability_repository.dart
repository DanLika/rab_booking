import '../../data/models/availability_window.dart';

/// Abstract repository for fetching PII-stripped availability windows.
///
/// Production implementation calls the `getUnitAvailability` Cloud Function
/// (SF-023). Tests inject a fake that returns canned [AvailabilityWindow]s,
/// avoiding Firebase init in the test process.
abstract class IAvailabilityRepository {
  Future<List<AvailabilityWindow>> fetchAvailability({
    required String propertyId,
    required String unitId,
    required DateTime start,
    required DateTime end,
  });
}
