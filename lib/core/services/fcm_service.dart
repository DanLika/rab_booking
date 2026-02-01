import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../services/logging_service.dart';

/// FCM Push Notification Service
///
/// Handles Firebase Cloud Messaging for push notifications.
/// Token storage: users/{userId}/data/fcmTokens (Map format)
///
/// Web Push: Requires VAPID key from Firebase Console
/// (Project Settings → Cloud Messaging → Web Push certificates)
class FcmService {
  // VAPID key for web push notifications
  // From Firebase Console: Project Settings → Cloud Messaging → Web Push certificates
  static const String _vapidKey =
      'BJ34pleaflOU2jRZNOSkKt1K_-DXsepYhUlCwSrmQfX8HrlTqr5d2HTH6UODaZiwkvideADX_yTcCpLOTNwkIzM';
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  // Lazy initialization: only create FirebaseMessaging instance when needed (not on web)
  // This prevents platform channel access during app initialization on web
  FirebaseMessaging? _messaging;
  FirebaseMessaging get _messagingInstance {
    _messaging ??= FirebaseMessaging.instance;
    return _messaging!;
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream controllers for UI integration
  final _navigationController = StreamController<String>.broadcast();
  final _foregroundMessageController =
      StreamController<RemoteMessage>.broadcast();

  /// Stream of booking IDs to navigate to
  Stream<String> get navigationStream => _navigationController.stream;

  /// Stream of foreground messages to show alerts for
  Stream<RemoteMessage> get foregroundMessageStream =>
      _foregroundMessageController.stream;

  bool _initialized = false;
  String? _currentToken;

  /// Initialize FCM service
  /// Call this after Firebase initialization and user login
  Future<void> initialize() async {
    if (_initialized) return;

    // Check if VAPID key is configured for web
    if (kIsWeb && _vapidKey == 'YOUR_VAPID_KEY_HERE') {
      debugPrint('[FCM] Web push: VAPID key not configured');
      return;
    }

    try {
      // Request permission (iOS and Web require this)
      final settings = await _messagingInstance.requestPermission();

      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get APNS token first on iOS (not needed for web)
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
          final apnsToken = await _messagingInstance.getAPNSToken();
          debugPrint('[FCM] APNS Token: $apnsToken');
        }

        // Get and save FCM token
        await _getAndSaveToken();

        // Listen for token refresh
        _messagingInstance.onTokenRefresh.listen(_onTokenRefresh);

        // Configure message handling (foreground messages on web handled by service worker)
        _configureMessageHandling();

        _initialized = true;
        debugPrint(
          '[FCM] Service initialized successfully (platform: ${_getPlatform()})',
        );
      } else {
        // Log permission denial to Sentry for tracking
        debugPrint('[FCM] Permission denied');
        await LoggingService.logWarningToSentry(
          'FCM permission denied by user',
          data: {
            'platform': _getPlatform(),
            'authorization_status': settings.authorizationStatus.name,
          },
        );
      }
    } catch (e, stackTrace) {
      debugPrint('[FCM] Error initializing: $e');
      // Log to Sentry - this is critical because it means NO push notifications will work
      await LoggingService.logError('FCM initialization failed', e, stackTrace);
    }
  }

  /// Configure message handling
  void _configureMessageHandling() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground message received: ${message.messageId}');
      _handleMessage(message);
    });

    // Handle background message tap (app was in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Message opened app: ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Check if app was opened from terminated state via notification
    _messagingInstance.getInitialMessage().then((initialMessage) {
      if (initialMessage != null) {
        debugPrint('[FCM] App opened from notification');
        _handleNotificationTap(initialMessage);
      }
    });
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    try {
      // Web requires VAPID key for token generation
      if (kIsWeb) {
        _currentToken = await _messagingInstance.getToken(vapidKey: _vapidKey);
      } else {
        _currentToken = await _messagingInstance.getToken();
      }
      return _currentToken;
    } catch (e, stackTrace) {
      debugPrint('[FCM] Error getting token: $e');
      // Log to Sentry - token retrieval failure is critical
      await LoggingService.logError(
        'FCM failed to get device token',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// Save FCM token to Firestore
  Future<void> _getAndSaveToken() async {
    final token = await getToken();
    if (token == null) return;

    await _saveTokenToFirestore(token);
  }

  /// Handle token refresh
  Future<void> _onTokenRefresh(String token) async {
    debugPrint('[FCM] Token refreshed');
    _currentToken = token;
    await _saveTokenToFirestore(token);
  }

  /// Save token to Firestore (Map structure)
  Future<void> _saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('[FCM] No user logged in, skipping token save');
      // This is expected if user logs out during initialization
      return;
    }

    try {
      final platform = _getPlatform();

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('data')
          .doc('fcmTokens')
          .set({
            token: {
              'token': token,
              'platform': platform,
              'createdAt': FieldValue.serverTimestamp(),
              'lastSeen': FieldValue.serverTimestamp(),
            },
          }, SetOptions(merge: true));

      debugPrint('[FCM] Token saved for $platform');
    } catch (e, stackTrace) {
      debugPrint('[FCM] Error saving token: $e');
      // Log to Sentry - Firestore write failure prevents notifications
      await LoggingService.logError(
        'FCM failed to save token to Firestore',
        e,
        stackTrace,
      );
    }
  }

  /// Remove token when user logs out
  Future<void> removeToken() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || _currentToken == null) return;

    try {
      final tokensRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('data')
          .doc('fcmTokens');

      // Remove the specific token entry using FieldValue.delete()
      await tokensRef.update({'$_currentToken': FieldValue.delete()});

      debugPrint('[FCM] Token removed on logout');
      _currentToken = null; // Clear current token after removal
    } catch (e) {
      debugPrint('[FCM] Error removing token: $e');
    }
  }

  /// Handle incoming message (foreground)
  void _handleMessage(RemoteMessage message) {
    debugPrint('[FCM] Message: ${message.notification?.title}');

    // Emit to stream for UI to handle (e.g. show SnackBar)
    _foregroundMessageController.add(message);
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    final data = message.data;
    final bookingId = data['bookingId'] as String?;
    final category = data['category'] as String?;

    debugPrint(
      '[FCM] Tapped notification - category: $category, bookingId: $bookingId',
    );

    if (bookingId != null) {
      // Emit to navigation stream for Router to handle
      _navigationController.add(bookingId);
    }
  }

  /// Get platform string
  String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }

  /// Check if permissions granted
  Future<bool> isPermissionGranted() async {
    final settings = await _messagingInstance.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }

  /// Dispose streams
  void dispose() {
    _navigationController.close();
    _foregroundMessageController.close();
  }
}

/// Global FCM service instance
final fcmService = FcmService();
