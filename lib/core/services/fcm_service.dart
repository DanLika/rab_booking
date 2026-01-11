import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// FCM Push Notification Service
///
/// Handles Firebase Cloud Messaging for push notifications.
/// Token storage: users/{userId}/data/fcmTokens
class FcmService {
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
  final _foregroundMessageController = StreamController<RemoteMessage>.broadcast();

  /// Stream of booking IDs to navigate to
  Stream<String> get navigationStream => _navigationController.stream;

  /// Stream of foreground messages to show alerts for
  Stream<RemoteMessage> get foregroundMessageStream => _foregroundMessageController.stream;

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
      final settings = await _messagingInstance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get and save FCM token
        await _getAndSaveToken();

        // Listen for token refresh
        _messagingInstance.onTokenRefresh.listen(_onTokenRefresh);

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
      _currentToken = await _messagingInstance.getToken();
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

      final tokens = List<Map<String, dynamic>>.from(
        doc.data()?['tokens'] as List? ?? [],
      );
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
    final initialMessage = await _messagingInstance.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM] App opened from notification');
      _handleMessageTap(initialMessage);
    }
  }

  /// Handle incoming message (foreground)
  void _handleMessage(RemoteMessage message) {
    debugPrint('[FCM] Message: ${message.notification?.title}');

    // Emit to stream for UI to handle (e.g. show SnackBar)
    _foregroundMessageController.add(message);
  }

  /// Handle notification tap
  void _handleMessageTap(RemoteMessage message) {
    final data = message.data;
    final category = data['category'];
    final bookingId = data['bookingId'];

    debugPrint(
      '[FCM] Tapped notification - category: $category, bookingId: $bookingId',
    );

    if (bookingId != null) {
      // Emit to navigation stream for Router to handle
      _navigationController.add(bookingId);
    }
  }

  /// Get platform string
  /// Returns platform identifier, safe for web (checks kIsWeb before accessing Platform)
  String _getPlatform() {
    // CRITICAL: Check kIsWeb FIRST before any Platform access
    // Platform class from dart:io uses platform channels internally
    // which are not available on web and will cause errors
    if (kIsWeb) return 'web';

    // Only access Platform on non-web platforms
    try {
      if (Platform.isIOS) return 'ios';
      if (Platform.isAndroid) return 'android';
      if (Platform.isMacOS) return 'macos';
      if (Platform.isWindows) return 'windows';
      if (Platform.isLinux) return 'linux';
    } catch (e) {
      // Fallback if Platform access fails (shouldn't happen, but be safe)
      debugPrint('[FCM] Error detecting platform: $e');
      return 'unknown';
    }
    return 'unknown';
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (kIsWeb) return false;

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
