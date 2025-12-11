import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// FCM Push Notification Service
///
/// Handles Firebase Cloud Messaging for push notifications.
/// Currently hidden from UI - will be activated with mobile app release.
///
/// Token storage: users/{userId}/data/fcmTokens
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _initialized = false;
  String? _currentToken;

  /// Initialize FCM service
  /// Call this after Firebase initialization and user login
  Future<void> initialize() async {
    if (_initialized) return;

    // Skip on web for now - will be enabled with proper web push setup
    if (kIsWeb) {
      debugPrint('[FCM] Web push notifications not yet configured');
      return;
    }

    try {
      // Request permission (iOS requires this)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get and save FCM token
        await _getAndSaveToken();

        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_onTokenRefresh);

        // Configure foreground message handling
        await _configureMessageHandling();

        _initialized = true;
        debugPrint('[FCM] Service initialized successfully');
      } else {
        debugPrint('[FCM] Permission denied');
      }
    } catch (e) {
      debugPrint('[FCM] Error initializing: $e');
    }
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    if (kIsWeb) return null;

    try {
      _currentToken = await _messaging.getToken();
      return _currentToken;
    } catch (e) {
      debugPrint('[FCM] Error getting token: $e');
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

  /// Save token to Firestore
  Future<void> _saveTokenToFirestore(String token) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      debugPrint('[FCM] No user logged in, skipping token save');
      return;
    }

    try {
      final platform = _getPlatform();
      final tokenData = {
        'token': token,
        'platform': platform,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final tokensRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('data')
          .doc('fcmTokens');

      // Get existing tokens
      final doc = await tokensRef.get();
      List<Map<String, dynamic>> tokens = [];

      if (doc.exists && doc.data()?['tokens'] != null) {
        tokens = List<Map<String, dynamic>>.from(doc.data()!['tokens'] as List);
        // Remove existing token for this platform
        tokens.removeWhere((t) => t['platform'] == platform);
      }

      // Add new token
      tokens.add(tokenData);

      // Save
      await tokensRef.set({
        'tokens': tokens,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[FCM] Token saved for platform: $platform');
    } catch (e) {
      debugPrint('[FCM] Error saving token: $e');
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

      final doc = await tokensRef.get();
      if (!doc.exists) return;

      final tokens =
          List<Map<String, dynamic>>.from(doc.data()?['tokens'] as List? ?? []);
      tokens.removeWhere((t) => t['token'] == _currentToken);

      await tokensRef.update({'tokens': tokens});
      debugPrint('[FCM] Token removed on logout');
    } catch (e) {
      debugPrint('[FCM] Error removing token: $e');
    }
  }

  /// Configure message handling
  Future<void> _configureMessageHandling() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground message received: ${message.messageId}');
      _handleMessage(message);
    });

    // Handle background message tap (app was in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Message opened app: ${message.messageId}');
      _handleMessageTap(message);
    });

    // Check if app was opened from terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM] App opened from notification');
      _handleMessageTap(initialMessage);
    }
  }

  /// Handle incoming message (foreground)
  void _handleMessage(RemoteMessage message) {
    // For now, just log - can show in-app notification later
    debugPrint('[FCM] Message: ${message.notification?.title}');
    debugPrint('[FCM] Body: ${message.notification?.body}');
    debugPrint('[FCM] Data: ${message.data}');
  }

  /// Handle notification tap
  void _handleMessageTap(RemoteMessage message) {
    final data = message.data;
    final category = data['category'];
    final bookingId = data['bookingId'];

    debugPrint('[FCM] Tapped notification - category: $category, bookingId: $bookingId');

    // Navigation will be handled by the app based on the data
    // Can emit events or use a callback here
  }

  /// Get platform string
  String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;

    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
  }
}

/// Global FCM service instance
final fcmService = FcmService();
