import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/booking.dart';
import '../../../profile/presentation/providers/payment_info_provider.dart';

/// Payment Confirmation Screen
/// Prikazuje instrukcije za plaćanje nakon kreiranja rezervacije
class PaymentConfirmationScreen extends ConsumerWidget {
  final String bookingId;
  final Booking booking;
  final String unitName;

  const PaymentConfirmationScreen({
    super.key,
    required this.bookingId,
    required this.booking,
    required this.unitName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentInfoAsync = ref.watch(unitPaymentInfoProvider(booking.unitId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Potvrda rezervacije'),
        automaticallyImplyLeading: false,
      ),
      body: paymentInfoAsync.when(
        data: (paymentInfo) {
          if (paymentInfo == null) {
            return _buildErrorState(
              context,
              'Greška pri učitavanju podataka za plaćanje.',
            );
          }

          return _buildSuccessContent(context, paymentInfo);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildErrorState(
          context,
          'Greška: $error',
        ),
      ),
    );
  }

  Widget _buildSuccessContent(BuildContext context, paymentInfo) {
    final dateFormat = DateFormat('dd.MM.yyyy', 'hr');
    final advanceAmount = booking.advanceAmount ?? (booking.totalPrice * 0.2);
    final remainingAmount = booking.totalPrice - advanceAmount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Success Icon
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 80,
          ),

          const SizedBox(height: 16),

          // Success Message
          Text(
            'Rezervacija uspješno kreirana!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
          ),

          const SizedBox(height: 8),

          Text(
            'Broj rezervacije: ${booking.id.substring(0, 8).toUpperCase()}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),

          const SizedBox(height: 24),

          // Booking Summary Card
          _buildBookingSummaryCard(
            context,
            dateFormat,
            advanceAmount,
            remainingAmount,
          ),

          const SizedBox(height: 24),

          // Payment Instructions
          _buildPaymentInstructionsCard(
            context,
            paymentInfo,
            advanceAmount,
          ),

          const SizedBox(height: 24),

          // Important Notes
          _buildImportantNotesCard(context),

          const SizedBox(height: 32),

          // Done Button
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text(
              'Završi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingSummaryCard(
    BuildContext context,
    DateFormat dateFormat,
    double advanceAmount,
    double remainingAmount,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Detalji rezervacije',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const Divider(height: 24),
            _buildDetailRow(
              context,
              Icons.hotel,
              'Smještaj',
              unitName,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              Icons.person,
              'Gost',
              booking.guestName,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              Icons.calendar_today,
              'Dolazak',
              dateFormat.format(booking.checkIn),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              Icons.calendar_today,
              'Odlazak',
              dateFormat.format(booking.checkOut),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              context,
              Icons.nights_stay,
              'Broj noćenja',
              '${booking.nights}',
            ),
            const Divider(height: 24),
            _buildDetailRow(
              context,
              Icons.euro,
              'Ukupna cijena',
              '${booking.totalPrice.toStringAsFixed(0)}€',
              isHighlighted: true,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              context,
              Icons.payment,
              'Avans za platiti',
              '${advanceAmount.toStringAsFixed(0)}€',
              valueColor: Colors.orange,
            ),
            const SizedBox(height: 4),
            _buildDetailRow(
              context,
              Icons.money_off,
              'Ostatak po dolasku',
              '${remainingAmount.toStringAsFixed(0)}€',
              valueColor: Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInstructionsCard(
    BuildContext context,
    paymentInfo,
    double advanceAmount,
  ) {
    return Card(
      elevation: 2,
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: Colors.orange[700],
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Instrukcije za plaćanje',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              'Molimo platite avans bankovnim prijenosom:',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),

            // Amount to pay
            _buildCopyableField(
              context,
              'Iznos',
              '${advanceAmount.toStringAsFixed(2)}€',
              Icons.euro,
            ),

            const SizedBox(height: 12),

            // Account holder
            _buildCopyableField(
              context,
              'Primatelj',
              paymentInfo.accountHolder,
              Icons.account_circle,
            ),

            const SizedBox(height: 12),

            // IBAN
            _buildCopyableField(
              context,
              'IBAN',
              paymentInfo.iban,
              Icons.account_balance,
            ),

            if (paymentInfo.swift != null) ...[
              const SizedBox(height: 12),
              _buildCopyableField(
                context,
                'SWIFT/BIC',
                paymentInfo.swift!,
                Icons.info,
              ),
            ],

            if (paymentInfo.bankName != null) ...[
              const SizedBox(height: 12),
              _buildCopyableField(
                context,
                'Banka',
                paymentInfo.bankName!,
                Icons.business,
              ),
            ],

            const SizedBox(height: 12),

            // Reference number (booking ID)
            _buildCopyableField(
              context,
              'Opis plaćanja',
              'Rezervacija ${booking.id.substring(0, 8).toUpperCase()}',
              Icons.description,
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[900]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Uključite broj rezervacije u opis plaćanja!',
                      style: TextStyle(
                        color: Colors.orange[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyableField(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label kopiran'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            tooltip: 'Kopiraj',
          ),
        ],
      ),
    );
  }

  Widget _buildImportantNotesCard(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Važne napomene',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildBulletPoint(
              context,
              'Rezervacija je potvrđena nakon što primimo uplatu avansa',
            ),
            const SizedBox(height: 8),
            _buildBulletPoint(
              context,
              'Ostatak iznosa plaća se po dolasku u smještaj',
            ),
            const SizedBox(height: 8),
            _buildBulletPoint(
              context,
              'Potvrdu rezervacije ćete dobiti na email nakon što uplata bude evidirana',
            ),
            const SizedBox(height: 8),
            _buildBulletPoint(
              context,
              'Za sva pitanja kontaktirajte vlasnika na email iz potvrde',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '• ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
        ),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isHighlighted = false,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isHighlighted ? FontWeight.bold : null,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
                color: valueColor ??
                    (isHighlighted ? Theme.of(context).primaryColor : null),
              ),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Nazad na početnu'),
            ),
          ],
        ),
      ),
    );
  }
}
