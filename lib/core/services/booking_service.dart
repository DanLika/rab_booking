import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../core/constants/enums.dart';
import '../../shared/models/booking_model.dart';
import 'logging_service.dart';

/// Service for managing bookings in Firestore.
///
/// This service creates and manages bookings before payment processing.
///
/// Usage:
/// ```dart
/// final service = BookingService();
///
/// // Create a booking
/// final result = await service.createBooking(
///   unitId: 'unit123',
///   propertyId: 'prop456',
///   ownerId: 'owner789',
///   checkIn: DateTime(2024, 7, 1),
///   checkOut: DateTime(2024, 7, 5),
///   guestName: 'John Doe',
///   guestEmail: 'john@example.com',
///   guestPhone: '+385123456789',
///   guestCount: 2,
///   totalPrice: 500.0,
///   paymentOption: 'full',
///   paymentMethod: 'bank_transfer',
/// );
///
/// // Handle result
/// if (result.isStripeValidation) {
///   // Proceed to Stripe checkout
/// } else {
///   // Booking created, show confirmation
///   print('Booking ID: ${result.booking!.id}');
/// }
/// ```
class BookingService {
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  BookingService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _functions = functions ?? FirebaseFunctions.instance;

  /// Create a new booking in Firestore
  ///
  /// IMPORTANT: For Stripe payments, this method does NOT create a booking!
  /// Instead, it validates availability and returns booking data for Stripe checkout.
  /// The actual booking is created by the Stripe webhook after payment succeeds.
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
  /// Returns: BookingResult containing either BookingModel (for non-Stripe)
  /// or booking data for Stripe checkout
  Future<BookingResult> createBooking({
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

      // Call atomic Cloud Function to prevent race conditions
      LoggingService.logDebug('   Calling createBookingAtomic Cloud Function...');

      // Prepare request data with validation
      final requestData = <String, dynamic>{
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
      };

      // Log request data for debugging (without sensitive info)
      LoggingService.logDebug('   Request data validation:');
      LoggingService.logDebug('     unitId: ${requestData['unitId']} (${requestData['unitId']?.runtimeType})');
      LoggingService.logDebug(
        '     propertyId: ${requestData['propertyId']} (${requestData['propertyId']?.runtimeType})',
      );
      LoggingService.logDebug('     ownerId: ${requestData['ownerId']} (${requestData['ownerId']?.runtimeType})');
      LoggingService.logDebug('     checkIn: ${requestData['checkIn']} (${requestData['checkIn']?.runtimeType})');
      LoggingService.logDebug('     checkOut: ${requestData['checkOut']} (${requestData['checkOut']?.runtimeType})');
      LoggingService.logDebug(
        '     guestName: ${requestData['guestName']?.toString().substring(0, (requestData['guestName']?.toString().length ?? 0).clamp(0, 20))} (${requestData['guestName']?.runtimeType})',
      );
      LoggingService.logDebug(
        '     guestEmail: ${requestData['guestEmail']?.toString().substring(0, (requestData['guestEmail']?.toString().indexOf('@') ?? 0).clamp(0, 20))} (${requestData['guestEmail']?.runtimeType})',
      );
      LoggingService.logDebug(
        '     guestPhone: ${requestData['guestPhone']?.toString().substring(0, (requestData['guestPhone']?.toString().length ?? 0).clamp(0, 10))} (${requestData['guestPhone']?.runtimeType})',
      );
      LoggingService.logDebug(
        '     guestCount: ${requestData['guestCount']} (${requestData['guestCount']?.runtimeType})',
      );
      LoggingService.logDebug(
        '     totalPrice: ${requestData['totalPrice']} (${requestData['totalPrice']?.runtimeType})',
      );
      LoggingService.logDebug(
        '     paymentOption: ${requestData['paymentOption']} (${requestData['paymentOption']?.runtimeType})',
      );
      LoggingService.logDebug(
        '     paymentMethod: ${requestData['paymentMethod']} (${requestData['paymentMethod']?.runtimeType})',
      );
      LoggingService.logDebug(
        '     requireOwnerApproval: ${requestData['requireOwnerApproval']} (${requestData['requireOwnerApproval']?.runtimeType})',
      );
      LoggingService.logDebug('     notes: ${requestData['notes'] != null ? 'present' : 'null'}');
      LoggingService.logDebug(
        '     taxLegalAccepted: ${requestData['taxLegalAccepted']} (${requestData['taxLegalAccepted']?.runtimeType})',
      );

      // Validate required fields before sending
      final missingFields = <String>[];
      if (requestData['unitId'] == null || (requestData['unitId'] as String).isEmpty) missingFields.add('unitId');
      if (requestData['propertyId'] == null || (requestData['propertyId'] as String).isEmpty)
        missingFields.add('propertyId');
      if (requestData['ownerId'] == null || (requestData['ownerId'] as String).isEmpty) missingFields.add('ownerId');
      if (requestData['checkIn'] == null || (requestData['checkIn'] as String).isEmpty) missingFields.add('checkIn');
      if (requestData['checkOut'] == null || (requestData['checkOut'] as String).isEmpty) missingFields.add('checkOut');
      if (requestData['guestName'] == null || (requestData['guestName'] as String).isEmpty)
        missingFields.add('guestName');
      if (requestData['guestEmail'] == null || (requestData['guestEmail'] as String).isEmpty)
        missingFields.add('guestEmail');
      if (requestData['totalPrice'] == null) missingFields.add('totalPrice');
      if (requestData['guestCount'] == null) missingFields.add('guestCount');
      if (requestData['paymentMethod'] == null || (requestData['paymentMethod'] as String).isEmpty)
        missingFields.add('paymentMethod');

      if (missingFields.isNotEmpty) {
        LoggingService.logError('Missing required fields before API call: ${missingFields.join(', ')}');
        throw Exception('Missing required booking fields: ${missingFields.join(', ')}');
      }

      final callable = _functions.httpsCallable('createBookingAtomic');
      final result = await callable.call<Map<String, dynamic>>(requestData);

      final responseData = result.data;

      // Check if this is a Stripe validation (no booking created yet)
      final isStripeValidation = responseData['isStripeValidation'] == true;

      if (isStripeValidation) {
        // For Stripe: Return validation result with booking data
        // No booking was created - webhook will create it after payment
        final bookingData = responseData['bookingData'] as Map<String, dynamic>;
        final depositAmount = (bookingData['depositAmount'] as num).toDouble();

        LoggingService.logSuccess('[BookingService] Stripe validation passed - proceeding to checkout');
        LoggingService.logDebug('   Deposit: €${depositAmount.toStringAsFixed(2)}');

        return BookingResult.stripeValidation(bookingData: bookingData, depositAmount: depositAmount);
      }

      // For non-Stripe: Booking was created, return BookingModel
      final createdBookingId = responseData['bookingId'] as String;
      final createdBookingRef = responseData['bookingReference'] as String;
      final createdDepositAmount = (responseData['depositAmount'] as num).toDouble();

      // Determine status based on payment method
      BookingStatus status;
      String paymentStatusValue;

      if (requireOwnerApproval || paymentMethod == 'none') {
        status = BookingStatus.pending;
        paymentStatusValue = 'not_required';
      } else {
        status = BookingStatus.pending;
        paymentStatusValue = 'pending';
      }

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

      LoggingService.logSuccess('[BookingService] Booking created: $createdBookingRef (ID: $createdBookingId)');

      return BookingResult.booking(booking);
    } on FirebaseFunctionsException catch (e) {
      // Log detailed error information
      await LoggingService.logError('[BookingService] Cloud Function error: ${e.code} - ${e.message}', e);
      LoggingService.logDebug('   Error code: ${e.code}');
      LoggingService.logDebug('   Error message: ${e.message}');
      LoggingService.logDebug('   Error details: ${e.details}');

      // Handle race condition - dates no longer available
      if (e.code == 'already-exists') {
        throw BookingConflictException(
          'The selected dates are no longer available. '
          'Another booking was made while you were completing your reservation. '
          'Please select different dates.',
        );
      }

      // Handle invalid-argument errors (missing fields, validation errors)
      if (e.code == 'invalid-argument') {
        throw BookingServiceException(
          'Invalid booking data: ${e.message}. Please check all required fields are filled correctly.',
        );
      }

      // Other Firebase Functions errors
      throw BookingServiceException('Failed to create booking: ${e.message}');
    } catch (e) {
      await LoggingService.logError('[BookingService] Error creating booking', e);
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
      await LoggingService.logError('[BookingService] Error fetching booking', e);
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

      return BookingModel.fromJson({'id': query.docs.first.id, ...query.docs.first.data()});
    } catch (e) {
      await LoggingService.logError('[BookingService] Error fetching booking by reference', e);
      throw BookingServiceException('Failed to fetch booking: $e');
    }
  }

  /// Update booking status
  Future<void> updateBookingStatus({required String bookingId, required BookingStatus status}) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status.toString().split('.').last,
        'updated_at': FieldValue.serverTimestamp(),
      });

      LoggingService.logSuccess('[BookingService] Booking $bookingId status updated to $status');
    } catch (e) {
      await LoggingService.logError('[BookingService] Error updating booking status', e);
      throw BookingServiceException('Failed to update booking status: $e');
    }
  }

  /// Cancel booking
  Future<void> cancelBooking({required String bookingId, required String reason, String? cancelledBy}) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': BookingStatus.cancelled.toString().split('.').last,
        'cancellation_reason': reason,
        'cancelled_at': FieldValue.serverTimestamp(),
        'cancelled_by': cancelledBy,
        'updated_at': FieldValue.serverTimestamp(),
      });

      LoggingService.logSuccess('[BookingService] Booking $bookingId cancelled');
    } catch (e) {
      await LoggingService.logError('[BookingService] Error cancelling booking', e);
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

/// Result of createBooking - either a created booking or Stripe validation data
class BookingResult {
  /// The created booking (for non-Stripe payments)
  final BookingModel? booking;

  /// Booking data for Stripe checkout (no booking created yet)
  final Map<String, dynamic>? stripeBookingData;

  /// Deposit amount for Stripe
  final double? depositAmount;

  /// Whether this is a Stripe validation result (no booking created)
  final bool isStripeValidation;

  BookingResult._({this.booking, this.stripeBookingData, this.depositAmount, required this.isStripeValidation});

  /// Create result for a created booking (non-Stripe)
  factory BookingResult.booking(BookingModel booking) {
    return BookingResult._(booking: booking, isStripeValidation: false);
  }

  /// Create result for Stripe validation (no booking created)
  factory BookingResult.stripeValidation({required Map<String, dynamic> bookingData, required double depositAmount}) {
    return BookingResult._(stripeBookingData: bookingData, depositAmount: depositAmount, isStripeValidation: true);
  }
}
