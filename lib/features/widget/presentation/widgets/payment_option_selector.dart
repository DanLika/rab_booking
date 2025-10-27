import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/payment_option.dart';
import '../providers/booking_flow_provider.dart';
import '../theme/bedbooking_theme.dart';

/// Payment option selector (Full payment vs Down payment)
class PaymentOptionSelector extends ConsumerWidget {
  const PaymentOptionSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedOption = ref.watch(paymentOptionProvider);
    final total = ref.watch(bookingTotalProvider);
    final downPayment = ref.watch(downPaymentAmountProvider);
    final remaining = total - downPayment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment',
          style: BedBookingTextStyles.heading2,
        ),
        const SizedBox(height: 16),

        // Full payment option
        GestureDetector(
          onTap: () {
            ref.read(paymentOptionProvider.notifier).state = PaymentOption.full;
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: selectedOption == PaymentOption.full
                ? BedBookingCards.selectedCard
                : BedBookingCards.borderedCard,
            child: Row(
              children: [
                Icon(
                  selectedOption == PaymentOption.full
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selectedOption == PaymentOption.full
                      ? BedBookingColors.primaryGreen
                      : BedBookingColors.textGrey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: BedBookingTextStyles.bodyBold,
                          ),
                          Text(
                            '\$${total.toStringAsFixed(2)} USD',
                            style: BedBookingTextStyles.bodyBold,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'amount + service payment on place',
                        style: BedBookingTextStyles.small,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Down payment option
        GestureDetector(
          onTap: () {
            ref.read(paymentOptionProvider.notifier).state = PaymentOption.downPayment;
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: selectedOption == PaymentOption.downPayment
                ? BedBookingCards.selectedCard
                : BedBookingCards.borderedCard,
            child: Row(
              children: [
                Icon(
                  selectedOption == PaymentOption.downPayment
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selectedOption == PaymentOption.downPayment
                      ? BedBookingColors.primaryGreen
                      : BedBookingColors.textGrey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Down payment',
                            style: BedBookingTextStyles.bodyBold,
                          ),
                          Text(
                            '\$${downPayment.toStringAsFixed(2)} USD',
                            style: BedBookingTextStyles.bodyBold,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Prepayment + \$${remaining.toStringAsFixed(2)} USD on place required',
                        style: BedBookingTextStyles.small,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
