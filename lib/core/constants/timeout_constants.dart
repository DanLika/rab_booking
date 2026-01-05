/// Standardizirani timeout-ovi za async operacije
///
/// Korištenje:
/// ```dart
/// await someOperation().timeout(TimeoutConstants.firestoreQuery);
/// ```
///
/// Ili sa [FutureTimeoutExtension]:
/// ```dart
/// await someOperation().withFirestoreTimeout('operationName');
/// ```
class TimeoutConstants {
  TimeoutConstants._(); // Prevent instantiation

  /// Firestore query timeout (30 sekundi)
  /// Koristi za: get(), set(), update(), delete(), query snapshots
  static const Duration firestoreQuery = Duration(seconds: 30);

  /// HTTP request timeout (15 sekundi)
  /// Koristi za: REST API pozive, external services
  static const Duration httpRequest = Duration(seconds: 15);

  /// Cloud Function call timeout (60 sekundi)
  /// Koristi za: Firebase Cloud Functions (callable)
  static const Duration cloudFunction = Duration(seconds: 60);

  /// Real-time listener initial data timeout (10 sekundi)
  /// Koristi za: Firestore stream listeners - čekanje prvog snapshot-a
  static const Duration realtimeInitial = Duration(seconds: 10);

  /// File upload timeout (2 minute)
  /// Koristi za: Firebase Storage uploads
  static const Duration fileUpload = Duration(minutes: 2);

  /// Short operation timeout (5 sekundi)
  /// Koristi za: Brze operacije koje ne bi trebale trajati dugo
  static const Duration shortOperation = Duration(seconds: 5);

  /// Booking fetch timeout (10 sekundi)
  /// Koristi za: Single booking fetch operacije
  static const Duration bookingFetch = Duration(seconds: 10);

  /// List fetch timeout (20 sekundi)
  /// Koristi za: Fetching liste (bookings, properties, units)
  static const Duration listFetch = Duration(seconds: 20);
}
