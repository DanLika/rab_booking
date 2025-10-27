import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/enums.dart';
import '../../shared/models/booking_model.dart';

/// Service for managing bookings in Firestore
///
/// This service creates and manages bookings before payment processing
class BookingService {
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();

  BookingService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

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
  /// - [paymentOption]: 'deposit' (20%) or 'full' (100%)
  /// - [paymentMethod]: 'stripe' or 'bank_transfer'
  /// - [notes]: Special requests/notes (optional)
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
    required String paymentOption, // 'deposit' or 'full'
    required String paymentMethod, // 'stripe' or 'bank_transfer'
    String? notes,
  }) async {
    try {
      debugPrint('🔵 [BookingService] Creating booking...');
      debugPrint('   Unit: $unitId');
      debugPrint('   Guest: $guestName ($guestEmail)');
      debugPrint('   Dates: $checkIn to $checkOut');
      debugPrint('   Total: €$totalPrice');
      debugPrint('   Payment: $paymentOption via $paymentMethod');

      // Generate booking ID and reference
      final bookingId = _uuid.v4();
      final bookingReference = _generateBookingReference();

      // Calculate deposit amount (20% or 100%)
      final depositAmount = paymentOption == 'deposit'
          ? totalPrice * 0.2
          : totalPrice;

      // Determine initial status
      final status = paymentMethod == 'bank_transfer'
          ? BookingStatus.pending // Pending payment confirmation
          : BookingStatus.pending; // Pending Stripe payment

      // Create booking model
      final booking = BookingModel(
        id: bookingId,
        unitId: unitId,
        ownerId: ownerId,
        guestName: guestName,
        guestEmail: guestEmail,
        guestPhone: guestPhone,
        checkIn: checkIn,
        checkOut: checkOut,
        status: status,
        totalPrice: totalPrice,
        paidAmount: 0, // Not paid yet
        advanceAmount: depositAmount,
        paymentMethod: paymentMethod,
        paymentStatus: 'pending',
        source: 'widget',
        guestCount: guestCount,
        notes: notes,
        createdAt: DateTime.now(),
      );

      // Save to Firestore with additional fields needed by Cloud Functions
      final docRef = _firestore.collection('bookings').doc(bookingId);
      final bookingData = {
        ...booking.toJson(),
        'booking_reference': bookingReference, // Required by Stripe Cloud Function
        'property_id': propertyId, // Required by Stripe Cloud Function
        'deposit_amount': depositAmount, // Required by Stripe Cloud Function
      };

      await docRef.set(bookingData);

      debugPrint('✅ [BookingService] Booking created: $bookingReference (ID: $bookingId)');
      debugPrint('   Deposit amount: €${depositAmount.toStringAsFixed(2)}');

      return booking;
    } catch (e) {
      debugPrint('❌ [BookingService] Error creating booking: $e');
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

      return BookingModel.fromJson({
        'id': doc.id,
        ...doc.data()!,
      });
    } catch (e) {
      debugPrint('❌ [BookingService] Error fetching booking: $e');
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
      debugPrint('❌ [BookingService] Error fetching booking by reference: $e');
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

      debugPrint('✅ [BookingService] Booking $bookingId status updated to $status');
    } catch (e) {
      debugPrint('❌ [BookingService] Error updating booking status: $e');
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

      debugPrint('✅ [BookingService] Booking $bookingId cancelled');
    } catch (e) {
      debugPrint('❌ [BookingService] Error cancelling booking: $e');
      throw BookingServiceException('Failed to cancel booking: $e');
    }
  }

  /// Generate unique booking reference
  ///
  /// Format: BK-YYYYMMDD-XXXX
  /// Example: BK-20250127-3456
  String _generateBookingReference() {
    final now = DateTime.now();
    final dateStr = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';

    // Generate 4-digit random number based on timestamp
    final random = (now.millisecond * 1000 + now.second)
        .toString()
        .padLeft(4, '0')
        .substring(0, 4);

    return 'BK-$dateStr-$random';
  }
}

/// Custom exception for booking service errors
class BookingServiceException implements Exception {
  final String message;

  BookingServiceException(this.message);

  @override
  String toString() => 'BookingServiceException: $message';
}
