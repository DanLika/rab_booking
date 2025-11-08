import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/booking_price_provider.dart';

/// Bank transfer instructions screen
/// Shows payment details and booking reference
class BankTransferScreen extends ConsumerWidget {
  final String unitId;
  final DateTime checkIn;
  final DateTime checkOut;
  final String bookingReference;

  const BankTransferScreen({
    super.key,
    required this.unitId,
    required this.checkIn,
    required this.checkOut,
    required this.bookingReference,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final priceCalc = ref.watch(bookingPriceProvider(
      unitId: unitId,
      checkIn: checkIn,
      checkOut: checkOut,
    ));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Bank Transfer Instructions'),
        backgroundColor: const Color(0xFF6B8E23),
        foregroundColor: Colors.white,
      ),
      body: priceCalc.when(
        data: (calculation) {
          if (calculation == null) {
            return const Center(child: Text('Error loading price'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Success icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC8E6C9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 48,
                      color: Color(0xFF6B8E23),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Booking confirmed
                const Center(
                  child: Text(
                    'Booking Confirmed!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Booking reference
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Reference: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          bookingReference,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 18),
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(text: bookingReference),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reference copied to clipboard'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Booking details
                _buildSectionTitle('Booking Details'),
                const SizedBox(height: 12),
                _buildDetailRow('Check-in', _formatDate(checkIn)),
                _buildDetailRow('Check-out', _formatDate(checkOut)),
                _buildDetailRow('Nights', '${calculation.nights}'),

                const SizedBox(height: 32),

                // Price breakdown
                _buildSectionTitle('Price Breakdown'),
                const SizedBox(height: 12),
                _buildPriceRow('Total Price', calculation.formattedTotal, false),
                _buildPriceRow('Deposit (20%)', calculation.formattedDeposit, true),
                _buildPriceRow('Remaining', calculation.formattedRemaining, false),

                const SizedBox(height: 32),

                // Payment instructions
                _buildSectionTitle('Payment Instructions'),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9C4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFBC02D),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFFF57C00),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Payment Due: ${calculation.formattedDeposit}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please transfer within 3 days to confirm your booking.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Bank details
                _buildBankDetailCard(
                  'Account Holder',
                  'Your Business Name',
                  Icons.person,
                ),
                const SizedBox(height: 12),
                _buildBankDetailCard(
                  'Bank Name',
                  'Your Bank',
                  Icons.account_balance,
                ),
                const SizedBox(height: 12),
                _buildBankDetailCard(
                  'IBAN',
                  'HR1234567890123456789',
                  Icons.credit_card,
                ),
                const SizedBox(height: 12),
                _buildBankDetailCard(
                  'Reference',
                  bookingReference,
                  Icons.qr_code,
                ),

                const SizedBox(height: 32),

                // Important notes
                _buildSectionTitle('Important Notes'),
                const SizedBox(height: 12),
                _buildNoteItem(
                  '✓ Include booking reference in transfer description',
                ),
                _buildNoteItem(
                  '✓ You will receive confirmation email once payment is received',
                ),
                _buildNoteItem(
                  '✓ Remaining amount (${calculation.formattedRemaining}) payable on arrival',
                ),
                _buildNoteItem(
                  '✓ Cancellation policy: 7 days before check-in for full refund',
                ),

                const SizedBox(height: 32),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B8E23),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, bool highlight) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: highlight ? 12 : 8,
        horizontal: highlight ? 12 : 0,
      ),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: highlight
          ? BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: highlight ? 16 : 14,
              fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: highlight ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: highlight ? const Color(0xFF6B8E23) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetailCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6B8E23)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            onPressed: () {
              // Copy to clipboard
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoteItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }
}
