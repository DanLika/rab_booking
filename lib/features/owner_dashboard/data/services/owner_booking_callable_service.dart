import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/async_utils.dart';
import '../../../../shared/providers/repository_providers.dart';

/// Thin wrapper around the owner-side booking callables introduced in
/// audit/26 PR-A. Routes manual create + edit + drag-drop move + move-to-unit
/// through Cloud Functions so concurrent owner writes can't bypass the
/// overlap check (the way bare client `.add()` / `.update()` did) and so
/// SF-026 Zagreb-civil-day normalization applies uniformly.
class OwnerBookingCallableService {
  OwnerBookingCallableService(this._functions);

  final FirebaseFunctions _functions;

  /// Calls `createOwnerBookingAtomic`. Returns the server-generated booking id
  /// + reference + nights so the caller can drop them straight into UI state.
  ///
  /// `propertyId` is `String?` to match the underlying `BookingModel` field.
  /// The CF rejects missing values with `invalid-argument`.
  Future<({String bookingId, String bookingReference, int nights})>
  createBooking({
    required String unitId,
    required String? propertyId,
    required DateTime checkIn,
    required DateTime checkOut,
    required String guestName,
    required String guestEmail,
    String? guestPhone,
    required int guestCount,
    required double totalPrice,
    required String paymentMethod,
    String? status,
    String? notes,
    bool allowOverlap = false,
  }) async {
    final callable = _functions.httpsCallable('createOwnerBookingAtomic');
    final result = await callable
        .call(<String, dynamic>{
          'unitId': unitId,
          'propertyId': propertyId,
          'checkIn': checkIn.toUtc().toIso8601String(),
          'checkOut': checkOut.toUtc().toIso8601String(),
          'guestName': guestName,
          'guestEmail': guestEmail,
          'guestPhone': guestPhone,
          'guestCount': guestCount,
          'totalPrice': totalPrice,
          'paymentMethod': paymentMethod,
          if (status != null) 'status': status,
          'notes': notes,
          'allowOverlap': allowOverlap,
        })
        .withCloudFunctionTimeout('createOwnerBookingAtomic');

    final data = Map<String, dynamic>.from(result.data as Map);
    return (
      bookingId: data['bookingId'] as String,
      bookingReference: data['bookingReference'] as String,
      nights: (data['nights'] as num).toInt(),
    );
  }

  /// Calls `updateBookingAtomic`. Pass `targetPropertyId` + `targetUnitId` to
  /// move the booking to a different unit; pass only the fields the owner is
  /// changing (others are left untouched on the server).
  ///
  /// `propertyId` is `String?` to match `BookingModel.propertyId`. The CF
  /// rejects missing values with `invalid-argument`.
  Future<void> updateBooking({
    required String bookingId,
    required String? propertyId,
    required String unitId,
    String? targetPropertyId,
    String? targetUnitId,
    DateTime? checkIn,
    DateTime? checkOut,
    int? guestCount,
    double? totalPrice,
    String? notes,
    bool clearNotes = false,
    String? status,
    bool allowOverlap = false,
  }) async {
    final callable = _functions.httpsCallable('updateBookingAtomic');
    final payload = <String, dynamic>{
      'bookingId': bookingId,
      'propertyId': propertyId,
      'unitId': unitId,
      if (targetPropertyId != null) 'targetPropertyId': targetPropertyId,
      if (targetUnitId != null) 'targetUnitId': targetUnitId,
      if (checkIn != null) 'checkIn': checkIn.toUtc().toIso8601String(),
      if (checkOut != null) 'checkOut': checkOut.toUtc().toIso8601String(),
      if (guestCount != null) 'guestCount': guestCount,
      if (totalPrice != null) 'totalPrice': totalPrice,
      if (clearNotes) 'notes': null,
      if (!clearNotes && notes != null) 'notes': notes,
      if (status != null) 'status': status,
      'allowOverlap': allowOverlap,
    };
    await callable
        .call(payload)
        .withCloudFunctionTimeout('updateBookingAtomic');
  }
}

final ownerBookingCallableServiceProvider =
    Provider<OwnerBookingCallableService>((ref) {
      final functions = ref.watch(firebaseFunctionsProvider);
      return OwnerBookingCallableService(functions);
    });
