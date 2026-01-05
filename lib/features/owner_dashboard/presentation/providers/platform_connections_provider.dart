import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/utils/async_utils.dart';
import '../../domain/models/platform_connection.dart';
import '../../../../shared/providers/repository_providers.dart';

part 'platform_connections_provider.g.dart';

/// Stream provider for all platform connections for the current owner
@riverpod
Stream<List<PlatformConnection>> platformConnections(Ref ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    return Stream.value([]);
  }

  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('platform_connections')
      .where('owner_id', isEqualTo: userId)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map(PlatformConnection.fromFirestore).toList();
      });
}

/// Provider for platform connections for a specific unit
@riverpod
Stream<List<PlatformConnection>> platformConnectionsForUnit(
  Ref ref,
  String unitId,
) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    return Stream.value([]);
  }

  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('platform_connections')
      .where('owner_id', isEqualTo: userId)
      .where('unit_id', isEqualTo: unitId)
      .where('status', isEqualTo: 'active')
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map(PlatformConnection.fromFirestore).toList();
      });
}

/// Initiate Booking.com OAuth flow
@riverpod
Future<Map<String, dynamic>> connectBookingCom(
  Ref ref, {
  required String unitId,
  required String hotelId,
  required String roomTypeId,
}) async {
  final functions = FirebaseFunctions.instance;
  final callable = functions.httpsCallable('initiateBookingComOAuth');

  final result = await callable
      .call({'unitId': unitId, 'hotelId': hotelId, 'roomTypeId': roomTypeId})
      .withCloudFunctionTimeout('initiateBookingComOAuth');

  return result.data as Map<String, dynamic>;
}

/// Initiate Airbnb OAuth flow
@riverpod
Future<Map<String, dynamic>> connectAirbnb(
  Ref ref, {
  required String unitId,
  required String listingId,
}) async {
  final functions = FirebaseFunctions.instance;
  final callable = functions.httpsCallable('initiateAirbnbOAuth');

  final result = await callable
      .call({'unitId': unitId, 'listingId': listingId})
      .withCloudFunctionTimeout('initiateAirbnbOAuth');

  return result.data as Map<String, dynamic>;
}

/// Remove platform connection
@riverpod
Future<void> removePlatformConnection(Ref ref, String connectionId) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    throw Exception('User not authenticated');
  }

  final firestore = ref.watch(firestoreProvider);
  final connectionDoc = await firestore
      .collection('platform_connections')
      .doc(connectionId)
      .get();

  if (!connectionDoc.exists) {
    throw Exception('Connection not found');
  }

  final connectionData = connectionDoc.data()!;
  if (connectionData['owner_id'] != userId) {
    throw Exception('Unauthorized');
  }

  await connectionDoc.reference.delete();
}

/// Test platform connection
///
/// PLACEHOLDER: Returns true (always passes) until platform APIs are integrated.
/// Future implementation would:
/// 1. Fetch iCal feed from platform URL
/// 2. Validate feed format (ICS/iCalendar)
/// 3. Check for recent events/bookings
/// Priority: Low - iCal sync already validates on import
@riverpod
Future<bool> testPlatformConnection(Ref ref, String connectionId) async {
  // PLACEHOLDER: Connection test (Phase 2 feature)
  // Currently returns true as iCal sync validates feeds during import
  return true;
}
