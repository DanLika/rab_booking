import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Bank Transfer Instructions Screen
/// Shows payment details after booking is created
class BankTransferInstructionsScreen extends ConsumerWidget {
  final String bookingId;
  final double totalPrice;
  final String guestEmail;

  const BankTransferInstructionsScreen({
    super.key,
    required this.bookingId,
    required this.totalPrice,
    required this.guestEmail,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final advanceAmount = totalPrice * 0.2; // 20%
    final remainingAmount = totalPrice - advanceAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Uputstva za uplatu'),
        automaticallyImplyLeading: false, // Remove back button
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success icon
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                size: 80,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 24),

            // Success message
            Text(
              'Rezervacija kreirana!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Broj rezervacije: #$bookingId',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Email confirmation notice
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.email, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Potvrda je poslata na email: $guestEmail',
                      style: TextStyle(color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Payment instructions
            Text(
              'Uputstva za uplatu avansa',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPaymentRow(
                      context,
                      'Iznos avansa (20%)',
                      '€${advanceAmount.toStringAsFixed(2)}',
                      canCopy: true,
                      valueToCopy: advanceAmount.toStringAsFixed(2),
                    ),
                    const Divider(height: 24),
                    _buildPaymentRow(
                      context,
                      'Primatelj',
                      'Jasko Apartments',
                      canCopy: true,
                      valueToCopy: 'Jasko Apartments',
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentRow(
                      context,
                      'IBAN',
                      'HR12 3456 7890 1234 5678 90',
                      canCopy: true,
                      valueToCopy: 'HR1234567890123456789',
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentRow(
                      context,
                      'SWIFT/BIC',
                      'HPBZHR2X',
                      canCopy: true,
                      valueToCopy: 'HPBZHR2X',
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentRow(
                      context,
                      'Poziv na broj',
                      bookingId.substring(0, 8),
                      canCopy: true,
                      valueToCopy: bookingId.substring(0, 8),
                    ),
                    const SizedBox(height: 12),
                    _buildPaymentRow(
                      context,
                      'Opis plaćanja',
                      'Avans rezervacija #$bookingId',
                      canCopy: true,
                      valueToCopy: 'Avans rezervacija #$bookingId',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Remaining amount info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Text(
                        'Preostali iznos',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Preostali iznos od €${remainingAmount.toStringAsFixed(2)} uplaćujete po dolasku.',
                    style: TextStyle(color: Colors.orange[900]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Action buttons
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Generate and download PDF receipt
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PDF preuzimanje uskoro dostupno'),
                  ),
                );
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Preuzmi PDF'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.home),
              label: const Text('Povratak na početnu'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(
    BuildContext context,
    String label,
    String value, {
    bool canCopy = false,
    String? valueToCopy,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              if (canCopy)
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: valueToCopy ?? value),
                    );
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
        ),
      ],
    );
  }
}
