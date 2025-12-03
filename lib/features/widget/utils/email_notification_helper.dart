import 'dart:async';

import '../../../shared/models/booking_model.dart';
import '../../../shared/models/unit_model.dart';
import '../../../core/services/email_notification_service.dart';
import '../domain/models/widget_settings.dart';

/// Helper class for sending booking-related email notifications.
///
/// Extracted from BookingWidgetScreen to reduce code duplication
/// and improve testability of email notification logic.
class EmailNotificationHelper {
  /// Send booking confirmation emails to guest and owner.
  ///
  /// This method handles both guest confirmation and owner notification emails
  /// based on the widget settings configuration.
  ///
  /// [booking] - The booking model with guest and booking details
  /// [requiresApproval] - Whether the booking requires owner approval
  /// [widgetSettings] - Widget configuration including email settings
  /// [unit] - The unit model for property name
  /// [paymentMethod] - Optional payment method used (stripe, bank_transfer, etc.)
  /// [paymentDeadline] - Optional payment deadline for bank transfers
  static void sendBookingEmails({
    required BookingModel booking,
    required bool requiresApproval,
    required WidgetSettings? widgetSettings,
    required UnitModel? unit,
    String? paymentMethod,
    String? paymentDeadline,
  }) {
    final emailConfig = widgetSettings?.emailConfig;
    if (emailConfig?.enabled != true || emailConfig?.isConfigured != true) {
      return;
    }

    final emailService = EmailNotificationService();
    final bookingReference = booking.id.substring(0, 8).toUpperCase();
    final propertyName = unit?.name ?? 'Vacation Rental';

    // Send guest confirmation email
    unawaited(
      emailService.sendBookingConfirmationEmail(
        booking: booking,
        emailConfig: widgetSettings!.emailConfig,
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

    // Send owner notification (if enabled)
    if (widgetSettings.emailConfig.sendOwnerNotification) {
      final ownerEmail = widgetSettings.emailConfig.fromEmail;
      if (ownerEmail != null) {
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
    }

    emailService.dispose();
  }
}
