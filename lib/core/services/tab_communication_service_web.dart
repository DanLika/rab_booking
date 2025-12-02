import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'logging_service.dart';
import 'tab_communication_service.dart';

/// Web implementation of TabCommunicationService using BroadcastChannel API
///
/// BroadcastChannel allows communication between browsing contexts (tabs, windows)
/// of the same origin. This is used to notify other tabs when payment is complete.
///
/// Fallback: If BroadcastChannel is not supported (Safari < 15.4), uses
/// localStorage events for communication.
class TabCommunicationServiceWeb implements TabCommunicationService {
  /// Channel name - namespaced to avoid conflicts with other apps
  static const String _channelName = 'rab-booking-stripe';

  /// localStorage key for fallback mechanism
  static const String _localStorageKey = 'rab-booking-tab-message';

  /// BroadcastChannel instance (null if not supported)
  html.BroadcastChannel? _channel;

  /// Stream controller for parsed messages
  final StreamController<TabMessage> _messageController =
      StreamController<TabMessage>.broadcast();

  /// Whether BroadcastChannel is supported
  bool _usesBroadcastChannel = false;

  /// Subscription for localStorage events (fallback)
  StreamSubscription? _storageSubscription;

  /// Last processed message timestamp (for deduplication)
  int _lastMessageTimestamp = 0;

  TabCommunicationServiceWeb() {
    _initialize();
  }

  void _initialize() {
    try {
      // Try to create BroadcastChannel
      _channel = html.BroadcastChannel(_channelName);
      _usesBroadcastChannel = true;

      // Listen for messages from other tabs
      _channel!.onMessage.listen((event) {
        _handleRawMessage(event.data?.toString() ?? '');
      });

      LoggingService.log(
        '[TabCommunication] Initialized with BroadcastChannel',
        tag: 'TAB_COMM',
      );
    } catch (e) {
      // BroadcastChannel not supported - use localStorage fallback
      _usesBroadcastChannel = false;
      _setupLocalStorageFallback();

      LoggingService.log(
        '[TabCommunication] BroadcastChannel not supported, using localStorage fallback',
        tag: 'TAB_COMM',
      );
    }
  }

  /// Setup localStorage fallback for browsers that don't support BroadcastChannel
  void _setupLocalStorageFallback() {
    // Listen for storage events (triggered when another tab modifies localStorage)
    _storageSubscription = html.window.onStorage.listen((event) {
      if (event.key == _localStorageKey && event.newValue != null) {
        _handleRawMessage(event.newValue!);
      }
    });
  }

  /// Handle raw message string from BroadcastChannel or localStorage
  void _handleRawMessage(String rawMessage) {
    if (rawMessage.isEmpty) return;

    // Extract timestamp and message (format: "timestamp|message")
    final parts = rawMessage.split('|');
    if (parts.length < 2) {
      // Old format without timestamp - just parse message
      final message = TabMessage.parse(rawMessage);
      if (message != null) {
        _messageController.add(message);
        LoggingService.log(
          '[TabCommunication] Received: ${message.type}',
          tag: 'TAB_COMM',
        );
      }
      return;
    }

    final timestamp = int.tryParse(parts[0]) ?? 0;
    final messageStr = parts.sublist(1).join('|'); // In case message contains |

    // Deduplicate - ignore if we've already processed this message
    if (timestamp <= _lastMessageTimestamp) {
      return;
    }
    _lastMessageTimestamp = timestamp;

    // Parse and emit message
    final message = TabMessage.parse(messageStr);
    if (message != null) {
      _messageController.add(message);
      LoggingService.log(
        '[TabCommunication] Received: ${message.type} (bookingId: ${message.bookingId})',
        tag: 'TAB_COMM',
      );
    }
  }

  @override
  Stream<TabMessage> get messageStream => _messageController.stream;

  @override
  void send(String message) {
    // Add timestamp for deduplication
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final messageWithTimestamp = '$timestamp|$message';

    if (_usesBroadcastChannel && _channel != null) {
      try {
        _channel!.postMessage(messageWithTimestamp);
        LoggingService.log(
          '[TabCommunication] Sent via BroadcastChannel: $message',
          tag: 'TAB_COMM',
        );
      } catch (e) {
        LoggingService.log(
          '[TabCommunication] Error sending via BroadcastChannel: $e',
          tag: 'TAB_COMM_ERROR',
        );
        // Try localStorage fallback
        _sendViaLocalStorage(messageWithTimestamp);
      }
    } else {
      _sendViaLocalStorage(messageWithTimestamp);
    }
  }

  /// Send message via localStorage (fallback mechanism)
  void _sendViaLocalStorage(String message) {
    try {
      // Set the message in localStorage
      html.window.localStorage[_localStorageKey] = message;

      // Immediately remove it (we just need the storage event to fire)
      // This also prevents stale messages from accumulating
      Future.delayed(const Duration(milliseconds: 100), () {
        html.window.localStorage.remove(_localStorageKey);
      });

      LoggingService.log(
        '[TabCommunication] Sent via localStorage: $message',
        tag: 'TAB_COMM',
      );
    } catch (e) {
      LoggingService.log(
        '[TabCommunication] Error sending via localStorage: $e',
        tag: 'TAB_COMM_ERROR',
      );
    }
  }

  @override
  void sendPaymentComplete({
    required String bookingId,
    required String ref,
    required String email,
  }) {
    final message = TabMessage(
      type: TabMessageType.paymentComplete,
      params: {
        'bookingId': bookingId,
        'ref': ref,
        'email': email,
      },
    );
    send(message.serialize());
  }

  @override
  void sendBookingCancelled({required String bookingId}) {
    final message = TabMessage(
      type: TabMessageType.bookingCancelled,
      params: {
        'bookingId': bookingId,
      },
    );
    send(message.serialize());
  }

  @override
  void sendCalendarRefresh({String? unitId}) {
    final message = TabMessage(
      type: TabMessageType.calendarRefresh,
      params: {
        if (unitId != null) 'unitId': unitId,
      },
    );
    send(message.serialize());
  }

  @override
  bool get isAvailable => true; // Always available (has fallback)

  @override
  void dispose() {
    _channel?.close();
    _channel = null;
    _storageSubscription?.cancel();
    _messageController.close();

    LoggingService.log(
      '[TabCommunication] Disposed',
      tag: 'TAB_COMM',
    );
  }
}
