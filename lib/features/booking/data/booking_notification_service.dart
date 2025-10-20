import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'booking_notification_service.g.dart';

/// Service for sending booking-related notifications via Supabase Edge Functions
@riverpod
BookingNotificationService bookingNotificationService(Ref ref) {
  return BookingNotificationService(Supabase.instance.client);
}

class BookingNotificationService {
  final SupabaseClient _supabase;

  BookingNotificationService(this._supabase);

  /// Send booking confirmation email to guest
  ///
  /// Calls Supabase Edge Function: send-booking-confirmation
  /// This should be called immediately after a booking is successfully created
  ///
  /// Returns true if email was sent successfully, false otherwise
  Future<bool> sendBookingConfirmation(String bookingId) async {
    try {
      final response = await _supabase.functions.invoke(
        'send-booking-confirmation',
        body: {'bookingId': bookingId},
      );

      if (response.status == 200) {
        final data = response.data as Map<String, dynamic>?;
        final success = data?['success'] as bool? ?? false;

        if (success) {
          debugPrint('✅ Booking confirmation email sent for booking: $bookingId');
          return true;
        } else {
          debugPrint('⚠️ Email send response was not successful: ${data?['message']}');
          return false;
        }
      } else {
        debugPrint('❌ Failed to send booking confirmation email: ${response.status}');
        debugPrint('Response data: ${response.data}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Error sending booking confirmation email: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Send booking cancellation email to guest
  ///
  /// Implementation pending: Requires cancellation Edge Function deployment
  /// This will call the 'send-booking-cancellation' Edge Function
  Future<bool> sendBookingCancellation(String bookingId) async {
    // Implementation pending - Edge Function not yet deployed
    debugPrint('⚠️ Booking cancellation email not implemented yet');
    return false;
  }

  /// Send booking reminder email (24h before check-in)
  ///
  /// Implementation pending: Requires reminder Edge Function deployment
  /// This will call the 'send-booking-reminder' Edge Function
  Future<bool> sendBookingReminder(String bookingId) async {
    // Implementation pending - Edge Function not yet deployed
    debugPrint('⚠️ Booking reminder email not implemented yet');
    return false;
  }
}
