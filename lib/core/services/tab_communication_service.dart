import 'dart:async';

/// Message types for cross-tab communication
enum TabMessageType {
  /// Payment completed in another tab (Stripe checkout return)
  paymentComplete,

  /// Booking was cancelled in another tab
  bookingCancelled,

  /// Calendar should refresh (new booking, update, etc.)
  calendarRefresh,
}

/// Parsed message from cross-tab communication
class TabMessage {
  final TabMessageType type;
  final Map<String, String> params;
  final DateTime timestamp;

  TabMessage({required this.type, required this.params, DateTime? timestamp}) : timestamp = timestamp ?? DateTime.now();

  /// Parse message string into TabMessage
  /// Format: "type:key1=value1&key2=value2"
  /// Example: "payment_complete:bookingId=abc&ref=BK-123&email=guest@example.com"
  static TabMessage? parse(String message) {
    try {
      final colonIndex = message.indexOf(':');
      if (colonIndex == -1) return null;

      final typeStr = message.substring(0, colonIndex);
      final paramsStr = message.substring(colonIndex + 1);

      TabMessageType? type;
      switch (typeStr) {
        case 'payment_complete':
          type = TabMessageType.paymentComplete;
          break;
        case 'booking_cancelled':
          type = TabMessageType.bookingCancelled;
          break;
        case 'calendar_refresh':
          type = TabMessageType.calendarRefresh;
          break;
        default:
          return null;
      }

      final params = Uri.splitQueryString(paramsStr);
      return TabMessage(type: type, params: params);
    } catch (e) {
      return null;
    }
  }

  /// Serialize TabMessage to string
  String serialize() {
    String typeStr;
    switch (type) {
      case TabMessageType.paymentComplete:
        typeStr = 'payment_complete';
        break;
      case TabMessageType.bookingCancelled:
        typeStr = 'booking_cancelled';
        break;
      case TabMessageType.calendarRefresh:
        typeStr = 'calendar_refresh';
        break;
    }

    final paramsStr = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return '$typeStr:$paramsStr';
  }

  /// Get a parameter value
  String? get(String key) => params[key];

  /// Get bookingId (common param)
  String? get bookingId => params['bookingId'];

  /// Get booking reference (common param)
  String? get bookingRef => params['ref'];

  /// Get email (common param)
  String? get email => params['email'];

  /// Get sessionId (Stripe session ID for lookup)
  String? get sessionId => params['sessionId'];

  @override
  String toString() => 'TabMessage(type: $type, params: $params)';
}

/// Abstract interface for cross-tab communication service
///
/// This service enables communication between browser tabs using
/// BroadcastChannel API (with localStorage fallback for older browsers).
///
/// Usage:
/// ```dart
/// // Send message to other tabs
/// service.sendPaymentComplete(bookingId: 'abc', ref: 'BK-123', email: 'guest@example.com');
///
/// // Listen for messages from other tabs
/// service.messageStream.listen((message) {
///   if (message.type == TabMessageType.paymentComplete) {
///     final bookingId = message.bookingId;
///     // Handle payment completion...
///   }
/// });
/// ```
abstract class TabCommunicationService {
  /// Stream of parsed messages from other tabs
  Stream<TabMessage> get messageStream;

  /// Send a raw message to other tabs
  void send(String message);

  /// Send payment complete message to other tabs
  /// NOTE: Email is NOT included - booking is fetched by sessionId or bookingId
  /// [sessionId] - Stripe session ID (preferred for lookup, avoids collection group query bug)
  void sendPaymentComplete({required String bookingId, required String ref, String? sessionId}) {
    final message = TabMessage(
      type: TabMessageType.paymentComplete,
      params: {
        'bookingId': bookingId,
        'ref': ref,
        if (sessionId != null && sessionId.isNotEmpty) 'sessionId': sessionId,
      },
    );
    send(message.serialize());
  }

  /// Send booking cancelled message to other tabs
  void sendBookingCancelled({required String bookingId}) {
    final message = TabMessage(type: TabMessageType.bookingCancelled, params: {'bookingId': bookingId});
    send(message.serialize());
  }

  /// Send calendar refresh message to other tabs
  void sendCalendarRefresh({String? unitId}) {
    final message = TabMessage(type: TabMessageType.calendarRefresh, params: {if (unitId != null) 'unitId': unitId});
    send(message.serialize());
  }

  /// Check if the service is available (BroadcastChannel or fallback)
  bool get isAvailable;

  /// Dispose resources (close channel, cancel subscriptions)
  void dispose();
}

/// Stub implementation for non-web platforms (does nothing)
class TabCommunicationServiceStub implements TabCommunicationService {
  @override
  Stream<TabMessage> get messageStream => const Stream.empty();

  @override
  void send(String message) {
    // No-op on non-web platforms
  }

  @override
  void sendPaymentComplete({required String bookingId, required String ref, String? sessionId}) {
    // No-op
  }

  @override
  void sendBookingCancelled({required String bookingId}) {
    // No-op
  }

  @override
  void sendCalendarRefresh({String? unitId}) {
    // No-op
  }

  @override
  bool get isAvailable => false;

  @override
  void dispose() {
    // No-op
  }
}
