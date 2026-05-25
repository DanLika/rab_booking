import '../../../shared/models/booking_model.dart';
import '../../../shared/models/unit_model.dart';
import '../domain/models/widget_settings.dart';

/// Helper class for sending booking-related email notifications.
///
/// Extracted from BookingWidgetScreen to reduce code duplication
/// and improve testability of email notification logic.
class EmailNotificationHelper {
  /// Send booking confirmation emails to guest and owner.
  ///
  /// DISABLED 2026-05-25 (vibe-security audit).
  ///
  /// This used to call the client-side `EmailNotificationService` with a
  /// per-property Resend API key read from the publicly-readable
  /// `widget_settings` doc — anyone could exfiltrate the key and impersonate
  /// the owner. Email delivery now runs entirely server-side: the
  /// `createBookingAtomic` Cloud Function sends guest + owner emails via the
  /// platform `RESEND_API_KEY` Firebase Secret. The notification-preferences
  /// gate has moved to that CF.
  ///
  /// Kept as a no-op so existing callers in `booking_widget_screen.dart` and
  /// test code remain valid. Remove after callers are cleaned up.
  static Future<void> sendBookingEmails({
    required BookingModel booking,
    required bool requiresApproval,
    required WidgetSettings? widgetSettings,
    required UnitModel? unit,
    required String ownerId,
    String? paymentMethod,
    String? paymentDeadline,
  }) async {
    // Intentionally empty — see doc above.
    return;
  }
}
