import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../core/constants/enums.dart';
import '../../shared/models/booking_model.dart';
import 'logging_service.dart';

/// Service for managing bookings in Firestore
///
/// This service creates and manages bookings before payment processing
class BookingService {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  BookingService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  /// Create a new booking in Firestore
  ///
  /// This should be called BEFORE initiating Stripe payment
  ///
  /// Parameters:
  /// - [unitId]: The unit being booked
  /// - [propertyId]: The property ID (for denormalization)
  /// - [ownerId]: The property owner ID (for denormalization)
  /// - [checkIn]: Check-in date
  /// - [checkOut]: Check-out date
  /// - [guestName]: Guest's full name
  /// - [guestEmail]: Guest's email
  /// - [guestPhone]: Guest's phone number
  /// - [guestCount]: Number of guests (adults + children)
  /// - [totalPrice]: Total price for the stay
  /// - [paymentOption]: 'deposit' (20%), 'full' (100%), or 'none' (no payment)
  /// - [paymentMethod]: 'stripe', 'bank_transfer', or 'none'
  /// - [requireOwnerApproval]: If true, booking starts as pending approval
  /// - [notes]: Special requests/notes (optional)
  /// - [taxLegalAccepted]: If guest accepted tax/legal disclaimer (for compliance)
  ///
  /// Returns: BookingModel with generated ID and booking reference
  Future<BookingModel> createBooking({
    required String unitId,
    required String propertyId,
    required String ownerId,
    required DateTime checkIn,
    required DateTime checkOut,
    required String guestName,
    required String guestEmail,
    required String guestPhone,
    required int guestCount,
    required double totalPrice,
    required String paymentOption, // 'deposit', 'full', or 'none'
    required String paymentMethod, // 'stripe', 'bank_transfer', or 'none'
    bool requireOwnerApproval = false,
    String? notes,
    bool? taxLegalAccepted,
  }) async {
    try {
      LoggingService.logOperation('[BookingService] Creating booking...');
      LoggingService.logDebug('   Unit: $unitId');
      LoggingService.logDebug('   Guest: $guestName ($guestEmail)');
      LoggingService.logDebug('   Dates: $checkIn to $checkOut');
      LoggingService.logDebug('   Total: €$totalPrice');
      LoggingService.logDebug('   Payment: $paymentOption via $paymentMethod');

      // Determine initial status based on widget mode and payment method
      BookingStatus status;
      String paymentStatusValue;

      if (requireOwnerApproval || paymentMethod == 'none') {
        // bookingPending mode or no payment - requires owner approval
        status = BookingStatus.pending;
        paymentStatusValue =
            'not_required'; // Payment not required for pending bookings
      } else if (paymentMethod == 'bank_transfer') {
        // Bank transfer - pending payment confirmation
        status = BookingStatus.pending;
        paymentStatusValue = 'pending';
      } else {
        // Stripe payment - pending Stripe checkout completion
        status = BookingStatus.pending;
        paymentStatusValue = 'pending';
      }

      // Call atomic Cloud Function to prevent race conditions
      LoggingService.logDebug('   Calling createBookingAtomic Cloud Function...');

      final callable = _functions.httpsCallable('createBookingAtomic');
      final result = await callable.call<Map<String, dynamic>>({
        'unitId': unitId,
        'propertyId': propertyId,
        'ownerId': ownerId,
        'checkIn': checkIn.toIso8601String(),
        'checkOut': checkOut.toIso8601String(),
        'guestName': guestName,
        'guestEmail': guestEmail,
        'guestPhone': guestPhone,
        'guestCount': guestCount,
        'totalPrice': totalPrice,
        'paymentOption': paymentOption,
        'paymentMethod': paymentMethod,
        'requireOwnerApproval': requireOwnerApproval,
        'notes': notes,
        'taxLegalAccepted': taxLegalAccepted,
      });

      // Extract booking ID and reference from Cloud Function response
      final responseData = result.data;
      final createdBookingId = responseData['bookingId'] as String;
      final createdBookingRef = responseData['bookingReference'] as String;
      final createdDepositAmount = (responseData['depositAmount'] as num).toDouble();

      // Create booking model with returned data
      final booking = BookingModel(
        id: createdBookingId,
        unitId: unitId,
        ownerId: ownerId,
        guestName: guestName,
        guestEmail: guestEmail,
        guestPhone: guestPhone,
        checkIn: checkIn,
        checkOut: checkOut,
        status: status,
        totalPrice: totalPrice,
        advanceAmount: createdDepositAmount,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatusValue,
        source: 'widget',
        guestCount: guestCount,
        notes: notes,
        taxLegalAccepted: taxLegalAccepted,
        createdAt: DateTime.now(),
      );

      LoggingService.logSuccess(
        '[BookingService] Booking created atomically: $createdBookingRef (ID: $createdBookingId)',
      );
      LoggingService.logDebug(
        '   Deposit amount: €${createdDepositAmount.toStringAsFixed(2)}',
      );

      return booking;
    } on FirebaseFunctionsException catch (e) {
      // Handle race condition - dates no longer available
      if (e.code == 'already-exists') {
        await LoggingService.logError(
          '[BookingService] Booking conflict - dates unavailable',
          e,
        );
        throw BookingConflictException(
          'The selected dates are no longer available. '
          'Another booking was made while you were completing your reservation. '
          'Please select different dates.',
        );
      }

      // Other Firebase Functions errors
      await LoggingService.logError(
        '[BookingService] Cloud Function error',
        e,
      );
      throw BookingServiceException('Failed to create booking: ${e.message}');
    } catch (e) {
      await LoggingService.logError(
        '[BookingService] Error creating booking',
        e,
      );
      throw BookingServiceException('Failed to create booking: $e');
    }
  }

  /// Get booking by ID
  Future<BookingModel?> getBookingById(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();

      if (!doc.exists) {
        return null;
      }

      return BookingModel.fromJson({'id': doc.id, ...doc.data()!});
    } catch (e) {
      await LoggingService.logError(
        '[BookingService] Error fetching booking',
        e,
      );
      throw BookingServiceException('Failed to fetch booking: $e');
    }
  }

  /// Get booking by reference
  Future<BookingModel?> getBookingByReference(String reference) async {
    try {
      final query = await _firestore
          .collection('bookings')
          .where('booking_reference', isEqualTo: reference)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      return BookingModel.fromJson({
        'id': query.docs.first.id,
        ...query.docs.first.data(),
      });
    } catch (e) {
      await LoggingService.logError(
        '[BookingService] Error fetching booking by reference',
        e,
      );
      throw BookingServiceException('Failed to fetch booking: $e');
    }
  }

  /// Update booking status
  Future<void> updateBookingStatus({
    required String bookingId,
    required BookingStatus status,
  }) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status.toString().split('.').last,
        'updated_at': FieldValue.serverTimestamp(),
      });

      LoggingService.logSuccess(
        '[BookingService] Booking $bookingId status updated to $status',
      );
    } catch (e) {
      await LoggingService.logError(
        '[BookingService] Error updating booking status',
        e,
      );
      throw BookingServiceException('Failed to update booking status: $e');
    }
  }

  /// Cancel booking
  Future<void> cancelBooking({
    required String bookingId,
    required String reason,
    String? cancelledBy,
  }) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.cancelled.toString().split('.').last,
        'cancellation_reason': reason,
        'cancelled_at': FieldValue.serverTimestamp(),
        'cancelled_by': cancelledBy,
        'updated_at': FieldValue.serverTimestamp(),
      });

      LoggingService.logSuccess(
        '[BookingService] Booking $bookingId cancelled',
      );
    } catch (e) {
      await LoggingService.logError(
        '[BookingService] Error cancelling booking',
        e,
      );
      throw BookingServiceException('Failed to cancel booking: $e');
    }
  }

}

/// Custom exception for booking service errors
class BookingServiceException implements Exception {
  final String message;

  BookingServiceException(this.message);

  @override
  String toString() => 'BookingServiceException: $message';
}

/// Exception thrown when booking dates are no longer available (race condition)
class BookingConflictException implements Exception {
  final String message;

  BookingConflictException(this.message);

  @override
  String toString() => 'BookingConflictException: $message';
}
