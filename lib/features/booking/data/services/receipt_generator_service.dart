import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets' as pw;
import 'package:intl/intl.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/models/property_model.dart';
import '../../../property/domain/models/property_unit.dart';
import '../../domain/models/refund_policy.dart';

/// Receipt Generator Service
///
/// Generates professional PDF receipts for bookings.
/// Includes:
/// - Company branding and logo placeholder
/// - Guest and booking details
/// - Price breakdown with taxes
/// - Payment information (advance or full)
/// - Refund policy
/// - Footer with contact info
class ReceiptGeneratorService {
  /// Generate PDF receipt for a booking
  ///
  /// Returns [Uint8List] containing the PDF bytes, ready for:
  /// - Saving to Supabase Storage
  /// - Downloading to device
  /// - Attaching to email
  Future<Uint8List> generateReceipt({
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
    final pdf = pw.Document();

    // Date formatters
    final dateFormatter = DateFormat('dd MMM yyyy');
    final timeFormatter = DateFormat('HH:mm');

    // Receipt number (booking ID last 8 chars)
    final receiptNumber = booking.id.substring(booking.id.length - 8).toUpperCase();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [
            // Header with company branding
            _buildHeader(receiptNumber, booking.createdAt),
            pw.SizedBox(height: 30),

            // Divider
            pw.Divider(thickness: 2, color: PdfColors.grey300),
            pw.SizedBox(height: 20),

            // Guest Information
            _buildSectionTitle('Guest Information'),
            pw.SizedBox(height: 10),
            _buildGuestInfo(
              guestFirstName,
              guestLastName,
              guestEmail,
              guestPhone,
            ),
            pw.SizedBox(height: 20),

            // Booking Details
            _buildSectionTitle('Booking Details'),
            pw.SizedBox(height: 10),
            _buildBookingDetails(
              property: property,
              unit: unit,
              checkIn: booking.checkIn,
              checkOut: booking.checkOut,
              numberOfNights: booking.numberOfNights,
              guestCount: booking.guestCount,
              dateFormatter: dateFormatter,
            ),
            pw.SizedBox(height: 20),

            // Special Requests (if any)
            if (specialRequests != null && specialRequests.isNotEmpty) ...[
              _buildSectionTitle('Special Requests'),
              pw.SizedBox(height: 10),
              _buildSpecialRequests(specialRequests),
              pw.SizedBox(height: 20),
            ],

            // Price Breakdown
            _buildSectionTitle('Price Breakdown'),
            pw.SizedBox(height: 10),
            _buildPriceBreakdown(
              pricePerNight: basePrice / booking.numberOfNights / booking.guestCount,
              numberOfNights: booking.numberOfNights,
              numberOfGuests: booking.guestCount,
              basePrice: basePrice,
              serviceFee: serviceFee,
              cleaningFee: cleaningFee,
              taxRate: taxRate,
              taxAmount: taxAmount,
              totalPrice: booking.totalPrice,
            ),
            pw.SizedBox(height: 20),

            // Payment Information
            _buildSectionTitle('Payment Information'),
            pw.SizedBox(height: 10),
            _buildPaymentInfo(
              totalPrice: booking.totalPrice,
              paidAmount: booking.paidAmount,
              remainingBalance: booking.remainingBalance,
              isFullPayment: isFullPayment,
              paymentDate: booking.createdAt,
              dateFormatter: dateFormatter,
            ),
            pw.SizedBox(height: 20),

            // Refund Policy (if available)
            if (refundPolicy != null) ...[
              _buildSectionTitle('Refund Policy'),
              pw.SizedBox(height: 10),
              _buildRefundPolicy(refundPolicy, booking.checkIn),
              pw.SizedBox(height: 20),
            ],

            // Divider before footer
            pw.Divider(thickness: 1, color: PdfColors.grey300),
            pw.SizedBox(height: 15),

            // Footer
            _buildFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  /// Build header with company branding
  pw.Widget _buildHeader(String receiptNumber, DateTime issueDate) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Company Info
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Rab Booking',
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Island of Rab, Croatia',
              style: const pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
              ),
            ),
            pw.Text(
              'www.rabbooking.com',
              style: const pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
        // Receipt Info
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 8,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.Text(
                'PAYMENT RECEIPT',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue900,
                ),
              ),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Receipt #$receiptNumber',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              'Issued: ${DateFormat('dd MMM yyyy, HH:mm').format(issueDate)}',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build section title
  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 5),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.blue900,
            width: 2,
          ),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 14,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
      ),
    );
  }

  /// Build guest information
  pw.Widget _buildGuestInfo(
    String firstName,
    String lastName,
    String email,
    String phone,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Full Name', '$firstName $lastName'),
          pw.SizedBox(height: 8),
          _buildInfoRow('Email', email),
          pw.SizedBox(height: 8),
          _buildInfoRow('Phone', phone),
        ],
      ),
    );
  }

  /// Build booking details
  pw.Widget _buildBookingDetails({
    required PropertyModel property,
    required PropertyUnit unit,
    required DateTime checkIn,
    required DateTime checkOut,
    required int numberOfNights,
    required int guestCount,
    required DateFormat dateFormatter,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Property', property.name),
          pw.SizedBox(height: 8),
          _buildInfoRow('Unit', unit.name),
          pw.SizedBox(height: 8),
          _buildInfoRow('Location', property.address),
          pw.SizedBox(height: 8),
          pw.Divider(thickness: 1, color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          _buildInfoRow('Check-in', '${dateFormatter.format(checkIn)} (after 14:00)'),
          pw.SizedBox(height: 8),
          _buildInfoRow('Check-out', '${dateFormatter.format(checkOut)} (before 10:00)'),
          pw.SizedBox(height: 8),
          _buildInfoRow('Duration', '$numberOfNights night${numberOfNights > 1 ? 's' : ''}'),
          pw.SizedBox(height: 8),
          _buildInfoRow('Guests', '$guestCount guest${guestCount > 1 ? 's' : ''}'),
        ],
      ),
    );
  }

  /// Build special requests
  pw.Widget _buildSpecialRequests(String specialRequests) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.amber50,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(
          color: PdfColors.amber200,
          width: 1,
        ),
      ),
      child: pw.Text(
        specialRequests,
        style: const pw.TextStyle(
          fontSize: 11,
          color: PdfColors.grey800,
        ),
      ),
    );
  }

  /// Build price breakdown table
  pw.Widget _buildPriceBreakdown({
    required double pricePerNight,
    required int numberOfNights,
    required int numberOfGuests,
    required double basePrice,
    required double serviceFee,
    required double cleaningFee,
    required double taxRate,
    required double taxAmount,
    required double totalPrice,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        // Header row
        _buildTableRow(
          'Description',
          'Amount',
          isHeader: true,
        ),
        // Base price calculation
        _buildTableRow(
          '€${pricePerNight.toStringAsFixed(2)} × $numberOfNights night${numberOfNights > 1 ? 's' : ''} × $numberOfGuests guest${numberOfGuests > 1 ? 's' : ''}',
          '€${basePrice.toStringAsFixed(2)}',
        ),
        // Service fee
        if (serviceFee > 0)
          _buildTableRow(
            'Service Fee',
            '€${serviceFee.toStringAsFixed(2)}',
          ),
        // Cleaning fee
        if (cleaningFee > 0)
          _buildTableRow(
            'Cleaning Fee',
            '€${cleaningFee.toStringAsFixed(2)}',
          ),
        // Tax
        _buildTableRow(
          'Tax (${(taxRate * 100).toStringAsFixed(2)}%)',
          '€${taxAmount.toStringAsFixed(2)}',
        ),
        // Total row (highlighted)
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: PdfColors.blue900,
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Text(
                'Total Amount',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(10),
              child: pw.Text(
                '€${totalPrice.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                textAlign: pw.TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build payment information
  pw.Widget _buildPaymentInfo({
    required double totalPrice,
    required double paidAmount,
    required double remainingBalance,
    required bool isFullPayment,
    required DateTime paymentDate,
    required DateFormat dateFormatter,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(
          color: PdfColors.green200,
          width: 1,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Amount Paid',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '€${paidAmount.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green900,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Payment Date: ${dateFormatter.format(paymentDate)}',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          if (!isFullPayment) ...[
            pw.SizedBox(height: 8),
            pw.Divider(thickness: 1, color: PdfColors.green200),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Remaining Balance',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red900,
                  ),
                ),
                pw.Text(
                  '€${remainingBalance.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red900,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Text(
              'Due on or before check-in',
              style: const pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey700,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ] else ...[
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.green900,
                borderRadius: pw.BorderRadius.circular(3),
              ),
              child: pw.Text(
                'FULLY PAID',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build refund policy
  pw.Widget _buildRefundPolicy(RefundPolicy policy, DateTime checkInDate) {
    final daysUntilCheckIn = checkInDate.difference(DateTime.now()).inDays;
    final allTiers = RefundPolicies.standardPolicy();

    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Cancellation Policy',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          ...allTiers.map((tier) {
            final isCurrent = daysUntilCheckIn >= tier.daysBeforeCheckIn;
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 8,
                    height: 8,
                    decoration: pw.BoxDecoration(
                      color: isCurrent ? PdfColors.green : PdfColors.grey400,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Text(
                      '${tier.daysBeforeCheckIn}+ days: ${(tier.refundPercentage * 100).toInt()}% refund (${(tier.cancellationFeePercentage * 100).toInt()}% fee)',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: isCurrent ? PdfColors.black : PdfColors.grey600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.red50,
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: pw.Text(
              'Note: Cancellations within ${allTiers.last.daysBeforeCheckIn} days of check-in are non-refundable.',
              style: const pw.TextStyle(
                fontSize: 8,
                color: PdfColors.red900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build footer
  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Text(
          'Thank you for choosing Rab Booking!',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'For support or questions, contact us at:',
          style: const pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey700,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          'support@rabbooking.com | +385 51 123 456',
          style: const pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey700,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'This is an automatically generated receipt. No signature required.',
          style: const pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey500,
            fontStyle: pw.FontStyle.italic,
          ),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  /// Build info row (label + value)
  pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.black,
            ),
          ),
        ),
      ],
    );
  }

  /// Build table row
  pw.TableRow _buildTableRow(
    String label,
    String value, {
    bool isHeader = false,
  }) {
    return pw.TableRow(
      decoration: isHeader
          ? const pw.BoxDecoration(color: PdfColors.grey200)
          : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isHeader ? 11 : 10,
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(10),
          child: pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isHeader ? 11 : 10,
              fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }
}
