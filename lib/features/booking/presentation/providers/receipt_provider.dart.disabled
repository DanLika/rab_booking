import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/property_model.dart';
import '../../../property/domain/models/property_unit.dart';
import '../../data/services/receipt_generator_service.dart';
import '../../data/services/receipt_storage_service.dart';
import '../../domain/models/refund_policy.dart';

part 'receipt_provider.g.dart';

/// Provider for ReceiptGeneratorService
@riverpod
ReceiptGeneratorService receiptGeneratorService(ReceiptGeneratorServiceRef ref) {
  return ReceiptGeneratorService();
}

/// Provider for ReceiptStorageService
@riverpod
ReceiptStorageService receiptStorageService(ReceiptStorageServiceRef ref) {
  return ReceiptStorageService(
    supabase: Supabase.instance.client,
  );
}

/// Provider for generating and uploading receipt
///
/// This orchestrates the entire receipt generation flow:
/// 1. Generate PDF using ReceiptGeneratorService
/// 2. Upload to Supabase Storage
/// 3. Send email via Edge Function
/// 4. Update booking state
@riverpod
class ReceiptProcessor extends _$ReceiptProcessor {
  @override
  AsyncValue<ReceiptResult?> build() {
    return const AsyncValue.data(null);
  }

  /// Generate receipt, upload to storage, and send email
  Future<ReceiptResult> processReceipt({
    required BookingModel booking,
    required PropertyModel property,
    required PropertyUnit unit,
    required String guestFirstName,
    required String guestLastName,
    required String guestEmail,
    required String guestPhone,
    required double basePrice,
    required double serviceFee,
    required double cleaningFee,
    required double taxRate,
    required double taxAmount,
    required bool isFullPayment,
    RefundPolicy? refundPolicy,
    String? specialRequests,
  }) async {
    state = const AsyncValue.loading();

    try {
      // 1. Generate PDF
      final generatorService = ref.read(receiptGeneratorServiceProvider);
      final pdfBytes = await generatorService.generateReceipt(
        booking: booking,
        property: property,
        unit: unit,
        guestFirstName: guestFirstName,
        guestLastName: guestLastName,
        guestEmail: guestEmail,
        guestPhone: guestPhone,
        basePrice: basePrice,
        serviceFee: serviceFee,
        cleaningFee: cleaningFee,
        taxRate: taxRate,
        taxAmount: taxAmount,
        isFullPayment: isFullPayment,
        refundPolicy: refundPolicy,
        specialRequests: specialRequests,
      );

      // 2. Upload to Supabase Storage
      final storageService = ref.read(receiptStorageServiceProvider);
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final receiptUrl = await storageService.uploadReceipt(
        userId: currentUser.id,
        bookingId: booking.id,
        pdfBytes: pdfBytes,
      );

      // 3. Send email via Edge Function
      await _sendReceiptEmail(
        booking: booking,
        property: property,
        unit: unit,
        guestFirstName: guestFirstName,
        guestLastName: guestLastName,
        guestEmail: guestEmail,
        basePrice: basePrice,
        serviceFee: serviceFee,
        cleaningFee: cleaningFee,
        taxAmount: taxAmount,
        isFullPayment: isFullPayment,
        receiptUrl: receiptUrl,
      );

      final result = ReceiptResult(
        pdfBytes: pdfBytes,
        receiptUrl: receiptUrl,
        emailSent: true,
      );

      state = AsyncValue.data(result);
      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Send receipt email via Edge Function
  Future<void> _sendReceiptEmail({
    required BookingModel booking,
    required PropertyModel property,
    required PropertyUnit unit,
    required String guestFirstName,
    required String guestLastName,
    required String guestEmail,
    required double basePrice,
    required double serviceFee,
    required double cleaningFee,
    required double taxAmount,
    required bool isFullPayment,
    required String receiptUrl,
  }) async {
    final supabase = Supabase.instance.client;

    final dateFormatter = DateFormat('MMM dd, yyyy');

    final response = await supabase.functions.invoke(
      'send-receipt-email',
      body: {
        'bookingId': booking.id,
        'guestEmail': guestEmail,
        'guestFirstName': guestFirstName,
        'guestLastName': guestLastName,
        'propertyName': property.name,
        'unitName': unit.name,
        'checkInDate': dateFormatter.format(booking.checkIn),
        'checkOutDate': dateFormatter.format(booking.checkOut),
        'nights': booking.numberOfNights,
        'guests': booking.guestCount,
        'totalAmount': booking.totalPrice,
        'paidAmount': booking.paidAmount,
        'remainingAmount': booking.remainingBalance,
        'isFullPayment': isFullPayment,
        'receiptNumber': booking.id.substring(booking.id.length - 8).toUpperCase(),
        'receiptPdfUrl': receiptUrl,
      },
    );

    if (response.status != 200) {
      throw Exception('Failed to send receipt email: ${response.data}');
    }
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }
}

/// Result of receipt processing
class ReceiptResult {
  final Uint8List pdfBytes;
  final String receiptUrl;
  final bool emailSent;

  const ReceiptResult({
    required this.pdfBytes,
    required this.receiptUrl,
    required this.emailSent,
  });
}

/// Provider to download receipt locally
@riverpod
class ReceiptDownloader extends _$ReceiptDownloader {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  /// Download receipt PDF from storage
  Future<Uint8List> downloadReceipt({
    required String bookingId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final storageService = ref.read(receiptStorageServiceProvider);
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final pdfBytes = await storageService.downloadReceipt(
        userId: currentUser.id,
        bookingId: bookingId,
      );

      state = const AsyncValue.data(null);
      return pdfBytes;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}
