import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../shared/models/booking_model.dart';
import '../../features/widget/domain/models/widget_settings.dart';
import 'logging_service.dart';

/// Service for sending email notifications using Resend API
///
/// This service handles:
/// - Booking confirmation emails (pre-payment)
/// - Payment receipt emails (post-payment)
/// - Owner notification emails
/// - Email verification (optional)
class EmailNotificationService {
  final http.Client _httpClient;

  EmailNotificationService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  /// Send booking confirmation email to guest
  ///
  /// This is sent after booking is created but before payment
  Future<void> sendBookingConfirmationEmail({
    required BookingModel booking,
    required EmailNotificationConfig emailConfig,
    required String propertyName,
    required String bookingReference,
    String? paymentDeadline,
    String? paymentMethod,
    BankTransferConfig? bankTransferConfig,
    bool allowGuestCancellation = false,
    int? cancellationDeadlineHours,
    String? ownerEmail,
    String? ownerPhone,
    String? customLogoUrl,
  }) async {
    try {
      if (!emailConfig.enabled || !emailConfig.sendBookingConfirmation) {
        LoggingService.logDebug(
          '[EmailNotificationService] Booking confirmation email disabled in settings',
        );
        return;
      }

      if (!emailConfig.isConfigured) {
        LoggingService.logWarning(
          '[EmailNotificationService] Email config incomplete - skipping booking confirmation',
        );
        return;
      }

      LoggingService.logOperation(
        '[EmailNotificationService] Sending booking confirmation email...',
      );

      final subject = 'Potvrda rezervacije - $propertyName';
      final html = _generateBookingConfirmationHtml(
        booking: booking,
        propertyName: propertyName,
        bookingReference: bookingReference,
        paymentDeadline: paymentDeadline,
        paymentMethod: paymentMethod,
        bankTransferConfig: bankTransferConfig,
        allowGuestCancellation: allowGuestCancellation,
        cancellationDeadlineHours: cancellationDeadlineHours,
        ownerEmail: ownerEmail,
        ownerPhone: ownerPhone,
        customLogoUrl: customLogoUrl,
      );

      await _sendEmail(
        to: booking.guestEmail!,
        subject: subject,
        html: html,
        fromEmail: emailConfig.fromEmail!,
        fromName: emailConfig.fromName ?? propertyName,
        apiKey: emailConfig.resendApiKey!,
      );

      LoggingService.logSuccess(
        '[EmailNotificationService] Booking confirmation sent to ${booking.guestEmail}',
      );
    } catch (e) {
      await LoggingService.logError(
        '[EmailNotificationService] Failed to send booking confirmation',
        e,
      );
      // Don't throw - email failure shouldn't block booking
    }
  }

  /// Send payment receipt email to guest
  ///
  /// This is sent after payment is confirmed
  Future<void> sendPaymentReceiptEmail({
    required BookingModel booking,
    required EmailNotificationConfig emailConfig,
    required String propertyName,
    required String bookingReference,
    required double paidAmount,
    required String paymentMethod,
    String? customLogoUrl,
  }) async {
    try {
      if (!emailConfig.enabled || !emailConfig.sendPaymentReceipt) {
        LoggingService.logDebug(
          '[EmailNotificationService] Payment receipt email disabled in settings',
        );
        return;
      }

      if (!emailConfig.isConfigured) {
        LoggingService.logWarning(
          '[EmailNotificationService] Email config incomplete - skipping payment receipt',
        );
        return;
      }

      LoggingService.logOperation(
        '[EmailNotificationService] Sending payment receipt email...',
      );

      final subject = 'Potvrda plaćanja - $propertyName';
      final html = _generatePaymentReceiptHtml(
        booking: booking,
        propertyName: propertyName,
        bookingReference: bookingReference,
        paidAmount: paidAmount,
        paymentMethod: paymentMethod,
        customLogoUrl: customLogoUrl,
      );

      await _sendEmail(
        to: booking.guestEmail!,
        subject: subject,
        html: html,
        fromEmail: emailConfig.fromEmail!,
        fromName: emailConfig.fromName ?? propertyName,
        apiKey: emailConfig.resendApiKey!,
      );

      LoggingService.logSuccess(
        '[EmailNotificationService] Payment receipt sent to ${booking.guestEmail}',
      );
    } catch (e) {
      await LoggingService.logError(
        '[EmailNotificationService] Failed to send payment receipt',
        e,
      );
      // Don't throw - email failure shouldn't block booking
    }
  }

  /// Send new booking notification to owner
  ///
  /// This notifies the owner when a new booking is created
  Future<void> sendOwnerNotificationEmail({
    required BookingModel booking,
    required EmailNotificationConfig emailConfig,
    required String propertyName,
    required String bookingReference,
    required String ownerEmail,
    bool requiresApproval = false,
    String? customLogoUrl,
  }) async {
    try {
      if (!emailConfig.enabled || !emailConfig.sendOwnerNotification) {
        LoggingService.logDebug(
          '[EmailNotificationService] Owner notification email disabled in settings',
        );
        return;
      }

      if (!emailConfig.isConfigured) {
        LoggingService.logWarning(
          '[EmailNotificationService] Email config incomplete - skipping owner notification',
        );
        return;
      }

      LoggingService.logOperation(
        '[EmailNotificationService] Sending owner notification email...',
      );

      final subject = requiresApproval
          ? 'Nova rezervacija zahteva potvrdu - $propertyName'
          : 'Nova rezervacija - $propertyName';

      final html = _generateOwnerNotificationHtml(
        booking: booking,
        propertyName: propertyName,
        bookingReference: bookingReference,
        requiresApproval: requiresApproval,
        customLogoUrl: customLogoUrl,
      );

      await _sendEmail(
        to: ownerEmail,
        subject: subject,
        html: html,
        fromEmail: emailConfig.fromEmail!,
        fromName: emailConfig.fromName ?? propertyName,
        apiKey: emailConfig.resendApiKey!,
      );

      LoggingService.logSuccess(
        '[EmailNotificationService] Owner notification sent to $ownerEmail',
      );
    } catch (e) {
      await LoggingService.logError(
        '[EmailNotificationService] Failed to send owner notification',
        e,
      );
      // Don't throw - email failure shouldn't block booking
    }
  }

  /// Core method to send email via Resend API
  Future<void> _sendEmail({
    required String to,
    required String subject,
    required String html,
    required String fromEmail,
    required String fromName,
    required String apiKey,
  }) async {
    const resendApiUrl = 'https://api.resend.com/emails';

    final body = {
      'from': '$fromName <$fromEmail>',
      'to': [to],
      'subject': subject,
      'html': html,
    };

    final response = await _httpClient.post(
      Uri.parse(resendApiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Resend API error: ${response.statusCode} - ${response.body}',
      );
    }

    LoggingService.logDebug(
      '[EmailNotificationService] Resend API response: ${response.body}',
    );
  }

  /// Generate booking confirmation email HTML
  String _generateBookingConfirmationHtml({
    required BookingModel booking,
    required String propertyName,
    required String bookingReference,
    String? paymentDeadline,
    String? paymentMethod,
    BankTransferConfig? bankTransferConfig,
    bool allowGuestCancellation = false,
    int? cancellationDeadlineHours,
    String? ownerEmail,
    String? ownerPhone,
    String? customLogoUrl,
  }) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final checkInDate = dateFormat.format(booking.checkIn);
    final checkOutDate = dateFormat.format(booking.checkOut);
    final nights = booking.checkOut.difference(booking.checkIn).inDays;

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background-color: white;
            border-radius: 8px;
            padding: 30px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid #0066cc;
        }
        .header img {
            max-height: 60px;
            margin-bottom: 15px;
        }
        h1 {
            color: #0066cc;
            margin: 0;
            font-size: 24px;
        }
        .booking-ref {
            background-color: #f0f7ff;
            padding: 15px;
            border-radius: 6px;
            margin: 20px 0;
            text-align: center;
        }
        .booking-ref strong {
            font-size: 20px;
            color: #0066cc;
        }
        .details {
            margin: 20px 0;
        }
        .detail-row {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #eee;
        }
        .detail-label {
            font-weight: 600;
            color: #666;
        }
        .detail-value {
            color: #333;
        }
        .total {
            background-color: #f0f7ff;
            padding: 15px;
            border-radius: 6px;
            margin: 20px 0;
            font-size: 18px;
            font-weight: 600;
        }
        .info-box {
            background-color: #fff9e6;
            border-left: 4px solid #ffcc00;
            padding: 15px;
            margin: 20px 0;
        }
        .cancellation-box {
            background-color: #f0f9ff;
            border-left: 4px solid #0066cc;
            padding: 15px;
            margin: 20px 0;
        }
        .cancellation-box h3 {
            margin-top: 0;
            color: #0066cc;
        }
        .cancellation-box ul {
            margin: 10px 0;
            padding-left: 20px;
        }
        .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            text-align: center;
            color: #666;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            ${customLogoUrl != null && customLogoUrl.isNotEmpty ? '<img src="$customLogoUrl" alt="Logo" />' : ''}
            <h1>Potvrda rezervacije</h1>
            <p>$propertyName</p>
        </div>

        <p>Poštovani ${booking.guestName},</p>

        <p>Hvala Vam što ste odabrali naš smještaj! Vaša rezervacija je uspješno primljena.</p>

        <div class="booking-ref">
            <div>Broj rezervacije:</div>
            <strong>$bookingReference</strong>
        </div>

        <div class="details">
            <div class="detail-row">
                <span class="detail-label">Dolazak:</span>
                <span class="detail-value">$checkInDate</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Odlazak:</span>
                <span class="detail-value">$checkOutDate</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Broj noći:</span>
                <span class="detail-value">$nights</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Broj gostiju:</span>
                <span class="detail-value">${booking.guestCount}</span>
            </div>
            ${booking.notes != null && booking.notes!.isNotEmpty ? '''
            <div class="detail-row">
                <span class="detail-label">Napomene:</span>
                <span class="detail-value">${booking.notes}</span>
            </div>
            ''' : ''}
        </div>

        <div class="total">
            <div style="display: flex; justify-content: space-between;">
                <span>Ukupan iznos:</span>
                <span>€${booking.totalPrice.toStringAsFixed(2)}</span>
            </div>
        </div>

        ${paymentMethod == 'none' ? '''
        <div class="info-box">
            <strong>💳 Plaćanje pri dolasku</strong><br>
            <p>Vaša rezervacija je potvrđena! Plaćanje ćete izvršiti po dolasku na smještaj.</p>
            <ul style="margin: 10px 0; padding-left: 20px;">
                <li>Ukupan iznos: <strong>€${booking.totalPrice.toStringAsFixed(2)}</strong></li>
                <li>Prihvaćamo: gotovinu i kartice</li>
                <li>Plaćanje pri prijavi (check-in)</li>
            </ul>
            <p style="font-size: 12px; color: #666;">
                Molimo donesite ID/putovnicu za registraciju pri dolasku.
            </p>
        </div>
        ''' : paymentMethod == 'bank_transfer' && bankTransferConfig != null ? '''
        <div class="info-box">
            <strong>🏦 Upute za bankovni prijenos</strong><br>
            <p>Molimo izvršite plaćanje na sljedeći račun:</p>
            <table style="width: 100%; margin: 10px 0; border-collapse: collapse;">
                ${bankTransferConfig.iban != null ? '<tr><td style="padding: 8px 0; font-weight: 600; color: #333;">IBAN:</td><td style="padding: 8px 0; color: #333;">${bankTransferConfig.iban}</td></tr>' : ''}
                ${bankTransferConfig.accountNumber != null && bankTransferConfig.iban == null ? '<tr><td style="padding: 8px 0; font-weight: 600; color: #333;">Broj računa:</td><td style="padding: 8px 0; color: #333;">${bankTransferConfig.accountNumber}</td></tr>' : ''}
                ${bankTransferConfig.swift != null ? '<tr><td style="padding: 8px 0; font-weight: 600; color: #333;">SWIFT/BIC:</td><td style="padding: 8px 0; color: #333;">${bankTransferConfig.swift}</td></tr>' : ''}
                ${bankTransferConfig.bankName != null ? '<tr><td style="padding: 8px 0; font-weight: 600; color: #333;">Banka:</td><td style="padding: 8px 0; color: #333;">${bankTransferConfig.bankName}</td></tr>' : ''}
                ${bankTransferConfig.accountHolder != null ? '<tr><td style="padding: 8px 0; font-weight: 600; color: #333;">Primalac:</td><td style="padding: 8px 0; color: #333;">${bankTransferConfig.accountHolder}</td></tr>' : ''}
                <tr><td style="padding: 8px 0; font-weight: 600; color: #333;">Iznos:</td><td style="padding: 8px 0; color: #333; font-size: 18px; font-weight: bold;">€${booking.totalPrice.toStringAsFixed(2)}</td></tr>
                <tr><td style="padding: 8px 0; font-weight: 600; color: #333;">Poziv na broj:</td><td style="padding: 8px 0; color: #333;"><strong>$bookingReference</strong></td></tr>
            </table>
            ${paymentDeadline != null ? '<p style="margin: 10px 0;"><strong>⏰ Rok za plaćanje:</strong> $paymentDeadline</p>' : ''}
            <p style="font-size: 12px; color: #666; margin-top: 10px;">
                Važno: Molimo unesite broj rezervacije (<strong>$bookingReference</strong>) kao poziv na broj ili opis uplate kako bismo mogli identificirati Vašu uplatu.
            </p>
        </div>
        ''' : paymentDeadline != null ? '''
        <div class="info-box">
            <strong>Rok za plaćanje:</strong> $paymentDeadline<br>
            Molimo izvršite plaćanje do navedenog roka kako bi Vaša rezervacija bila potvrđena.
        </div>
        ''' : ''}

        ${allowGuestCancellation && cancellationDeadlineHours != null ? '''
        <div class="cancellation-box">
            <h3>📋 Politika otkazivanja</h3>
            <p><strong>Besplatno otkazivanje:</strong> Do $cancellationDeadlineHours sati prije dolaska</p>
            <p><strong>Za otkazivanje rezervacije:</strong></p>
            <ul>
                <li>Odgovorite na ovaj email sa brojem rezervacije: <strong>$bookingReference</strong></li>
                ${ownerEmail != null ? '<li>Email: $ownerEmail</li>' : ''}
                ${ownerPhone != null ? '<li>Telefon: $ownerPhone</li>' : ''}
            </ul>
            <p style="font-size: 12px; color: #666;">
                Molimo navedite broj rezervacije u svakoj komunikaciji kako bismo brže obradili Vaš zahtjev.
            </p>
        </div>
        ''' : ''}

        <div class="footer">
            <p>Sačuvajte ovaj email za Vaše evidencije.</p>
            <p>Ako imate pitanja, molimo odgovorite na ovaj email.</p>
        </div>
    </div>
</body>
</html>
''';
  }

  /// Generate payment receipt email HTML
  String _generatePaymentReceiptHtml({
    required BookingModel booking,
    required String propertyName,
    required String bookingReference,
    required double paidAmount,
    required String paymentMethod,
    String? customLogoUrl,
  }) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final checkInDate = dateFormat.format(booking.checkIn);
    final checkOutDate = dateFormat.format(booking.checkOut);
    final nights = booking.checkOut.difference(booking.checkIn).inDays;
    final now = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());

    final paymentMethodLabel = paymentMethod == 'bank_transfer'
        ? 'Bankovni prijenos'
        : paymentMethod == 'stripe'
        ? 'Kreditna kartica'
        : paymentMethod;

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background-color: white;
            border-radius: 8px;
            padding: 30px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid #28a745;
        }
        h1 {
            color: #28a745;
            margin: 0;
            font-size: 24px;
        }
        .success-badge {
            background-color: #d4edda;
            color: #155724;
            padding: 10px 20px;
            border-radius: 20px;
            display: inline-block;
            margin: 10px 0;
            font-weight: 600;
        }
        .booking-ref {
            background-color: #f0f7ff;
            padding: 15px;
            border-radius: 6px;
            margin: 20px 0;
            text-align: center;
        }
        .booking-ref strong {
            font-size: 20px;
            color: #0066cc;
        }
        .payment-info {
            background-color: #d4edda;
            border-left: 4px solid #28a745;
            padding: 15px;
            margin: 20px 0;
        }
        .details {
            margin: 20px 0;
        }
        .detail-row {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #eee;
        }
        .detail-label {
            font-weight: 600;
            color: #666;
        }
        .detail-value {
            color: #333;
        }
        .total {
            background-color: #d4edda;
            padding: 15px;
            border-radius: 6px;
            margin: 20px 0;
            font-size: 18px;
            font-weight: 600;
        }
        .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            text-align: center;
            color: #666;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            ${customLogoUrl != null && customLogoUrl.isNotEmpty ? '<img src="$customLogoUrl" alt="Logo" />' : ''}
            <h1>Potvrda plaćanja</h1>
            <div class="success-badge">✓ Plaćanje uspješno primljeno</div>
        </div>

        <p>Poštovani ${booking.guestName},</p>

        <p>Potvrđujemo da smo primili Vašu uplatu. Vaša rezervacija je sada u potpunosti potvrđena!</p>

        <div class="booking-ref">
            <div>Broj rezervacije:</div>
            <strong>$bookingReference</strong>
        </div>

        <div class="payment-info">
            <div class="detail-row" style="border: none;">
                <span class="detail-label">Plaćeno:</span>
                <span class="detail-value" style="font-weight: 600; font-size: 20px;">€${paidAmount.toStringAsFixed(2)}</span>
            </div>
            <div class="detail-row" style="border: none;">
                <span class="detail-label">Način plaćanja:</span>
                <span class="detail-value">$paymentMethodLabel</span>
            </div>
            <div class="detail-row" style="border: none;">
                <span class="detail-label">Datum plaćanja:</span>
                <span class="detail-value">$now</span>
            </div>
        </div>

        <div class="details">
            <h3 style="color: #0066cc;">Detalji rezervacije</h3>
            <div class="detail-row">
                <span class="detail-label">Dolazak:</span>
                <span class="detail-value">$checkInDate</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Odlazak:</span>
                <span class="detail-value">$checkOutDate</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Broj noći:</span>
                <span class="detail-value">$nights</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Broj gostiju:</span>
                <span class="detail-value">${booking.guestCount}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Ukupan iznos:</span>
                <span class="detail-value">€${booking.totalPrice.toStringAsFixed(2)}</span>
            </div>
        </div>

        <div class="footer">
            <p><strong>Hvala Vam na ukazanom povjerenju!</strong></p>
            <p>Očekujemo Vas $checkInDate. godine.</p>
            <p>Sačuvajte ovaj email kao dokaz o plaćanju.</p>
            <p>Ako imate pitanja, molimo odgovorite na ovaj email.</p>
        </div>
    </div>
</body>
</html>
''';
  }

  /// Generate owner notification email HTML
  String _generateOwnerNotificationHtml({
    required BookingModel booking,
    required String propertyName,
    required String bookingReference,
    required bool requiresApproval,
    String? customLogoUrl,
  }) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    final checkInDate = dateFormat.format(booking.checkIn);
    final checkOutDate = dateFormat.format(booking.checkOut);
    final nights = booking.checkOut.difference(booking.checkIn).inDays;
    final now = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background-color: white;
            border-radius: 8px;
            padding: 30px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 2px solid #0066cc;
        }
        .header img {
            max-height: 60px;
            margin-bottom: 15px;
        }
        h1 {
            color: #0066cc;
            margin: 0;
            font-size: 24px;
        }
        .alert-badge {
            background-color: ${requiresApproval ? '#fff3cd' : '#d4edda'};
            color: ${requiresApproval ? '#856404' : '#155724'};
            padding: 10px 20px;
            border-radius: 20px;
            display: inline-block;
            margin: 10px 0;
            font-weight: 600;
        }
        .booking-ref {
            background-color: #f0f7ff;
            padding: 15px;
            border-radius: 6px;
            margin: 20px 0;
            text-align: center;
        }
        .booking-ref strong {
            font-size: 20px;
            color: #0066cc;
        }
        .details {
            margin: 20px 0;
        }
        .detail-row {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #eee;
        }
        .detail-label {
            font-weight: 600;
            color: #666;
        }
        .detail-value {
            color: #333;
        }
        .guest-info {
            background-color: #f0f7ff;
            padding: 15px;
            border-radius: 6px;
            margin: 20px 0;
        }
        .action-needed {
            background-color: #fff3cd;
            border-left: 4px solid #ffc107;
            padding: 15px;
            margin: 20px 0;
        }
        .footer {
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #eee;
            text-align: center;
            color: #666;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            ${customLogoUrl != null && customLogoUrl.isNotEmpty ? '<img src="$customLogoUrl" alt="Logo" />' : ''}
            <h1>Nova rezervacija</h1>
            <div class="alert-badge">${requiresApproval ? '⚠ Zahteva potvrdu' : '✓ Automatski potvrđena'}</div>
        </div>

        <p>Poštovani,</p>

        <p>Nova rezervacija je kreirana za $propertyName ${requiresApproval ? 'i čeka Vašu potvrdu' : ''}.</p>

        <div class="booking-ref">
            <div>Broj rezervacije:</div>
            <strong>$bookingReference</strong>
        </div>

        <div class="guest-info">
            <h3 style="margin-top: 0; color: #0066cc;">Informacije o gostu</h3>
            <div class="detail-row" style="border: none;">
                <span class="detail-label">Ime:</span>
                <span class="detail-value">${booking.guestName}</span>
            </div>
            <div class="detail-row" style="border: none;">
                <span class="detail-label">Email:</span>
                <span class="detail-value">${booking.guestEmail}</span>
            </div>
            <div class="detail-row" style="border: none;">
                <span class="detail-label">Telefon:</span>
                <span class="detail-value">${booking.guestPhone}</span>
            </div>
        </div>

        <div class="details">
            <h3 style="color: #0066cc;">Detalji rezervacije</h3>
            <div class="detail-row">
                <span class="detail-label">Dolazak:</span>
                <span class="detail-value">$checkInDate</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Odlazak:</span>
                <span class="detail-value">$checkOutDate</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Broj noći:</span>
                <span class="detail-value">$nights</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Broj gostiju:</span>
                <span class="detail-value">${booking.guestCount}</span>
            </div>
            <div class="detail-row">
                <span class="detail-label">Ukupan iznos:</span>
                <span class="detail-value">€${booking.totalPrice.toStringAsFixed(2)}</span>
            </div>
            ${booking.notes != null && booking.notes!.isNotEmpty ? '''
            <div class="detail-row">
                <span class="detail-label">Napomene:</span>
                <span class="detail-value">${booking.notes}</span>
            </div>
            ''' : ''}
            <div class="detail-row">
                <span class="detail-label">Kreirano:</span>
                <span class="detail-value">$now</span>
            </div>
        </div>

        ${requiresApproval ? '''
        <div class="action-needed">
            <strong>Potrebna akcija:</strong> Molimo prijavite se u Vašu Owner Dashboard aplikaciju da potvrdite ili odbijete ovu rezervaciju.
        </div>
        ''' : ''}

        <div class="footer">
            <p>Ovo je automatska notifikacija iz Vašeg booking sistema.</p>
        </div>
    </div>
</body>
</html>
''';
  }

  /// Verify email address (placeholder for future implementation)
  ///
  /// This would send a verification code to the guest's email
  Future<bool> sendEmailVerification({
    required String email,
    required EmailNotificationConfig emailConfig,
  }) async {
    // TODO: Implement email verification flow
    // - Generate verification code
    // - Store code in Firestore with expiry
    // - Send verification email
    // - Provide method to verify code
    LoggingService.logWarning(
      '[EmailNotificationService] Email verification not yet implemented',
    );
    return false;
  }

  /// Dispose resources
  void dispose() {
    _httpClient.close();
  }
}

/// Exception thrown when email service operations fail
class EmailServiceException implements Exception {
  final String message;
  EmailServiceException(this.message);

  @override
  String toString() => 'EmailServiceException: $message';
}
