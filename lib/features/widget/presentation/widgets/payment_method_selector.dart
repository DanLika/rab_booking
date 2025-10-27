import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/payment_option.dart';
import '../providers/booking_flow_provider.dart';
import '../theme/bedbooking_theme.dart';

/// Payment method selector (Bank transfer vs Payment on place vs Stripe)
class PaymentMethodSelector extends ConsumerWidget {
  /// Whether to show Stripe payment option
  final bool enableStripe;

  const PaymentMethodSelector({
    super.key,
    this.enableStripe = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMethod = ref.watch(paymentMethodProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment method',
          style: BedBookingTextStyles.heading2,
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            // Bank transfer option
            Expanded(
              child: GestureDetector(
                onTap: () {
                  ref.read(paymentMethodProvider.notifier).state = PaymentMethod.bankTransfer;
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: selectedMethod == PaymentMethod.bankTransfer
                      ? BedBookingCards.selectedCard
                      : BedBookingCards.borderedCard,
                  child: Column(
                    children: [
                      Icon(
                        selectedMethod == PaymentMethod.bankTransfer
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: selectedMethod == PaymentMethod.bankTransfer
                            ? BedBookingColors.primaryGreen
                            : BedBookingColors.textGrey,
                        size: 24,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Bank transfer',
                        style: BedBookingTextStyles.bodyBold,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Waiting time for a bank transfer: 3 working days. If you do not make the transfer, the reservation will be cancelled.',
                        style: BedBookingTextStyles.small,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        Icons.account_balance,
                        size: 32,
                        color: selectedMethod == PaymentMethod.bankTransfer
                            ? BedBookingColors.primaryGreen
                            : BedBookingColors.textGrey,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Stripe credit card option (conditional)
            if (enableStripe)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref.read(paymentMethodProvider.notifier).state = PaymentMethod.stripe;
                  },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: selectedMethod == PaymentMethod.stripe
                      ? BedBookingCards.selectedCard
                      : BedBookingCards.borderedCard,
                  child: Column(
                    children: [
                      Icon(
                        selectedMethod == PaymentMethod.stripe
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: selectedMethod == PaymentMethod.stripe
                            ? BedBookingColors.primaryGreen
                            : BedBookingColors.textGrey,
                        size: 24,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Credit Card',
                            style: BedBookingTextStyles.bodyBold,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'INSTANT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Instant confirmation with credit card payment via Stripe. Secure and fast.',
                        style: BedBookingTextStyles.small,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        Icons.credit_card,
                        size: 32,
                        color: selectedMethod == PaymentMethod.stripe
                            ? BedBookingColors.primaryGreen
                            : BedBookingColors.textGrey,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Payment on arrival option (when Stripe is disabled)
            if (!enableStripe)
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref.read(paymentMethodProvider.notifier).state = PaymentMethod.paymentOnPlace;
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: selectedMethod == PaymentMethod.paymentOnPlace
                        ? BedBookingCards.selectedCard
                        : BedBookingCards.borderedCard,
                    child: Column(
                      children: [
                        Icon(
                          selectedMethod == PaymentMethod.paymentOnPlace
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: selectedMethod == PaymentMethod.paymentOnPlace
                              ? BedBookingColors.primaryGreen
                              : BedBookingColors.textGrey,
                          size: 24,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Pay on Arrival',
                          style: BedBookingTextStyles.bodyBold,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pay the full amount when you arrive at the property.',
                          style: BedBookingTextStyles.small,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Icon(
                          Icons.credit_card_off,
                          size: 32,
                          color: selectedMethod == PaymentMethod.paymentOnPlace
                              ? BedBookingColors.primaryGreen
                              : BedBookingColors.textGrey,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
