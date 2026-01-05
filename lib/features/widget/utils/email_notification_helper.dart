import 'dart:async';

import '../../../shared/models/booking_model.dart';
import '../../../shared/models/unit_model.dart';
import '../../../core/services/email_notification_service.dart';
import '../../../shared/repositories/user_profile_repository.dart';
import '../domain/models/widget_settings.dart';

/// Helper class for sending booking-related email notifications.
///
/// Extracted from BookingWidgetScreen to reduce code duplication
/// and improve testability of email notification logic.
class EmailNotificationHelper {
  /// Check if owner should receive email notification for a specific category
  /// Returns true if email should be sent, false otherwise
  /// Defaults to true (opt-out approach) if preferences not found
  static Future<bool> _shouldSendOwnerEmail({
    required String ownerId,
    required String category, // 'bookings' or 'payments'
    required bool forceIfCritical, // true for pending bookings
  }) async {
    // CRITICAL EVENTS: Override preferences
    if (forceIfCritical) {
      return true;
    }

    try {
      final repository = UserProfileRepository();
      final preferences = await repository.getNotificationPreferences(ownerId);

      // If no preferences found, default to sending (opt-out approach)
      if (preferences == null) {
        return true;
      }

      // Check master switch
      if (!preferences.masterEnabled) {
        return false;
      }

      // Check category-specific email preference
      final shouldSend = switch (category) {
        'bookings' => preferences.categories.bookings.email,
        'payments' => preferences.categories.payments.email,
        _ => true, // Default to true for unknown categories
      };

      return shouldSend;
    } catch (e) {
      // FALLBACK: If preference check fails, SEND email anyway (safer)
      // Better to send an email owner doesn't want than miss a critical notification
      return true;
    }
  }

  /// Send booking confirmation emails to guest and owner.
  ///
  /// This method handles both guest confirmation and owner notification emails
  /// based on the widget settings configuration.
  ///
  /// [booking] - The booking model with guest and booking details
  /// [requiresApproval] - Whether the booking requires owner approval
  /// [widgetSettings] - Widget configuration including email settings
  /// [unit] - The unit model for property name
  /// [ownerId] - Owner user ID for checking notification preferences
  /// [paymentMethod] - Optional payment method used (stripe, bank_transfer, etc.)
  /// [paymentDeadline] - Optional payment deadline for bank transfers
  static Future<void> sendBookingEmails({
    required BookingModel booking,
    required bool requiresApproval,
    required WidgetSettings? widgetSettings,
    required UnitModel? unit,
    required String ownerId,
    String? paymentMethod,
    String? paymentDeadline,
  }) async {
    final emailConfig = widgetSettings?.emailConfig;
    if (emailConfig?.enabled != true || emailConfig?.isConfigured != true) {
      return;
    }

    // Defensive check: ensure widgetSettings is not null before accessing properties
    if (widgetSettings == null || emailConfig == null) {
      return;
    }

    final emailService = EmailNotificationService();
    final bookingReference = booking.id.substring(0, 8).toUpperCase();
    final propertyName = unit?.name ?? 'Vacation Rental';

    // Send guest confirmation email
    unawaited(
      emailService.sendBookingConfirmationEmail(
        booking: booking,
        emailConfig: emailConfig,
        propertyName: propertyName,
        bookingReference: bookingReference,
        paymentDeadline: paymentDeadline,
        paymentMethod: paymentMethod,
        bankTransferConfig: widgetSettings.bankTransferConfig,
        allowGuestCancellation: widgetSettings.allowGuestCancellation,
        cancellationDeadlineHours: widgetSettings.cancellationDeadlineHours,
        ownerEmail: widgetSettings.contactOptions.emailAddress,
        ownerPhone: widgetSettings.contactOptions.phoneNumber,
        customLogoUrl: widgetSettings.themeOptions?.customLogoUrl,
      ),
    );

    // Send owner notification (if enabled in widget settings AND preferences allow)
    if (widgetSettings.emailConfig.sendOwnerNotification) {
      final ownerEmail = widgetSettings.emailConfig.fromEmail;
      if (ownerEmail != null) {
        // Check notification preferences before sending
        final shouldSend = await _shouldSendOwnerEmail(
          ownerId: ownerId,
          category: 'bookings',
          forceIfCritical: requiresApproval, // Force send for pending bookings
        );

        if (shouldSend) {
          unawaited(
            emailService.sendOwnerNotificationEmail(
              booking: booking,
              emailConfig: widgetSettings.emailConfig,
              propertyName: propertyName,
              bookingReference: bookingReference,
              ownerEmail: ownerEmail,
              requiresApproval: requiresApproval,
              customLogoUrl: widgetSettings.themeOptions?.customLogoUrl,
            ),
          );
        }
        // If shouldSend is false, silently skip (owner opted out)
      }
    }

    emailService.dispose();
  }
}
