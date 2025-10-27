import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../shared/models/user_model.dart';

/// Service for logging and managing security events
///
/// Implements BedBooking security audit requirements:
/// - Log all authentication events
/// - Track device information
/// - Detect suspicious activity
/// - Send notifications for important events
class SecurityEventsService {
  final FirebaseFirestore _firestore;

  SecurityEventsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Log a security event
  Future<void> logEvent({
    required String userId,
    required SecurityEventType type,
    String? deviceId,
    String? ipAddress,
    String? location,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final event = SecurityEvent(
        type: type,
        timestamp: DateTime.now(),
        deviceId: deviceId,
        ipAddress: ipAddress,
        location: location,
        metadata: metadata,
      );

      // Log to subcollection for full history
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('securityEvents')
          .add({
        'type': event.type.name,
        'timestamp': Timestamp.fromDate(event.timestamp),
        'deviceId': event.deviceId,
        'ipAddress': event.ipAddress,
        'location': event.location,
        'metadata': event.metadata,
      });

      // Update recent events in main user document (keep last 10)
      await _updateRecentEvents(userId, event);

      // Check for suspicious activity
      if (type == SecurityEventType.login) {
        await _checkSuspiciousLogin(userId, deviceId, location);
      }
    } catch (e) {
      // Don't throw - security logging should not break the app
      print('Failed to log security event: $e');
    }
  }

  /// Update recent security events in user document
  Future<void> _updateRecentEvents(String userId, SecurityEvent event) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) return;

      final data = userDoc.data() as Map<String, dynamic>;
      final List<dynamic> recentEvents = data['recentSecurityEvents'] ?? [];

      // Add new event and keep only last 10
      recentEvents.insert(0, {
        'type': event.type.name,
        'timestamp': Timestamp.fromDate(event.timestamp),
        'deviceId': event.deviceId,
        'ipAddress': event.ipAddress,
        'location': event.location,
        'metadata': event.metadata,
      });

      final limitedEvents = recentEvents.take(10).toList();

      await _firestore.collection('users').doc(userId).update({
        'recentSecurityEvents': limitedEvents,
      });
    } catch (e) {
      print('Failed to update recent events: $e');
    }
  }

  /// Check for suspicious login activity
  Future<void> _checkSuspiciousLogin(
    String userId,
    String? deviceId,
    String? location,
  ) async {
    try {
      // Get recent login events (last 24 hours)
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(hours: 24));

      final recentLogins = await _firestore
          .collection('users')
          .doc(userId)
          .collection('securityEvents')
          .where('type', isEqualTo: SecurityEventType.login.name)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(yesterday))
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      if (recentLogins.docs.isEmpty) return; // First login ever

      // Check for new device
      final previousDevices = recentLogins.docs
          .map((doc) => doc.data()['deviceId'] as String?)
          .where((id) => id != null)
          .toSet();

      final isNewDevice = deviceId != null && !previousDevices.contains(deviceId);

      // Check for new location
      final previousLocations = recentLogins.docs
          .map((doc) => doc.data()['location'] as String?)
          .where((loc) => loc != null)
          .toSet();

      final isNewLocation = location != null && !previousLocations.contains(location);

      // Log suspicious activity if detected
      if (isNewDevice || isNewLocation) {
        await logEvent(
          userId: userId,
          type: SecurityEventType.suspicious,
          deviceId: deviceId,
          location: location,
          metadata: {
            'reason': isNewDevice ? 'new_device' : 'new_location',
            'previousDevices': previousDevices.toList(),
            'previousLocations': previousLocations.toList(),
          },
        );

        // TODO: Send email notification
        // await _sendSuspiciousActivityEmail(userId, deviceId, location);
      }
    } catch (e) {
      print('Failed to check suspicious activity: $e');
    }
  }

  /// Log successful login
  Future<void> logLogin(User user, {String? deviceId, String? location}) async {
    await logEvent(
      userId: user.uid,
      type: SecurityEventType.login,
      deviceId: deviceId,
      location: location,
      metadata: {
        'email': user.email,
        'provider': user.providerData.first.providerId,
      },
    );
  }

  /// Log logout
  Future<void> logLogout(String userId, {String? deviceId}) async {
    await logEvent(
      userId: userId,
      type: SecurityEventType.logout,
      deviceId: deviceId,
    );
  }

  /// Log password change
  Future<void> logPasswordChange(String userId, {String? deviceId}) async {
    await logEvent(
      userId: userId,
      type: SecurityEventType.passwordChange,
      deviceId: deviceId,
    );
  }

  /// Log email verification
  Future<void> logEmailVerification(String userId) async {
    await logEvent(
      userId: userId,
      type: SecurityEventType.emailVerification,
    );
  }

  /// Get security events for user
  Future<List<SecurityEvent>> getSecurityEvents(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('securityEvents')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => SecurityEvent.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      print('Failed to get security events: $e');
      return [];
    }
  }

  /// Track device for session management
  Future<void> trackDevice(
    String userId, {
    required String deviceId,
    required String platform,
    String? fcmToken,
  }) async {
    try {
      final deviceInfo = DeviceInfo(
        deviceId: deviceId,
        platform: platform,
        fcmToken: fcmToken,
        lastSeenAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(deviceId)
          .set({
        'deviceId': deviceInfo.deviceId,
        'platform': deviceInfo.platform,
        'fcmToken': deviceInfo.fcmToken,
        'lastSeenAt': Timestamp.fromDate(deviceInfo.lastSeenAt),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Failed to track device: $e');
    }
  }

  /// Remove device (on logout)
  Future<void> removeDevice(String userId, String deviceId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .doc(deviceId)
          .delete();
    } catch (e) {
      print('Failed to remove device: $e');
    }
  }

  /// Get all devices for user
  Future<List<DeviceInfo>> getDevices(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('devices')
          .get();

      return snapshot.docs
          .map((doc) => DeviceInfo.fromJson(doc.data()))
          .toList();
    } catch (e) {
      print('Failed to get devices: $e');
      return [];
    }
  }
}
