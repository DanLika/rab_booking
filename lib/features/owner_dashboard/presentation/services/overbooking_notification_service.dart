import '../../domain/models/overbooking_conflict.dart';

/// Placeholder service for future overbooking notification features
/// 
/// This service provides a foundation for future notification implementations:
/// - Email notifications to owners
/// - Push notifications
/// - Firestore notifications
/// 
/// Currently not implemented in MVP, but structure is ready for future expansion.
abstract class OverbookingNotificationService {
  /// Send email notification about overbooking conflict
  Future<void> sendEmailNotification(OverbookingConflict conflict);

  /// Send push notification about overbooking conflict
  Future<void> sendPushNotification(OverbookingConflict conflict);

  /// Create Firestore notification about overbooking conflict
  Future<void> createFirestoreNotification(OverbookingConflict conflict);
}

/// Default implementation (placeholder)
/// 
/// All methods are currently no-ops, ready for future implementation.
class OverbookingNotificationServiceImpl implements OverbookingNotificationService {
  @override
  Future<void> sendEmailNotification(OverbookingConflict conflict) async {
    // TODO: Implement email notification in future
    // This would send an email to the owner about the conflict
  }

  @override
  Future<void> sendPushNotification(OverbookingConflict conflict) async {
    // TODO: Implement push notification in future
    // This would send a push notification to the owner's device
  }

  @override
  Future<void> createFirestoreNotification(OverbookingConflict conflict) async {
    // TODO: Implement Firestore notification in future
    // This would create a notification document in Firestore
  }
}


