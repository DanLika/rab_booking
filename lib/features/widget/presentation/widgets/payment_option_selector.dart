import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../domain/models/payment_option.dart';
import '../providers/booking_flow_provider.dart';

/// Payment option selector (Full payment vs Down payment)
class PaymentOptionSelector extends ConsumerWidget {
  final WidgetColorScheme colors;

  const PaymentOptionSelector({
    super.key,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedOption = ref.watch(paymentOptionProvider);
    final total = ref.watch(bookingTotalProvider);
    final downPayment = ref.watch(downPaymentAmountProvider);
    final remaining = total - downPayment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Full payment option
        GestureDetector(
          onTap: () {
            ref.read(paymentOptionProvider.notifier).state = PaymentOption.full;
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selectedOption == PaymentOption.full
                  ? colors.primarySurface
                  : colors.backgroundCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selectedOption == PaymentOption.full
                    ? colors.primary
                    : colors.borderDefault,
                width: selectedOption == PaymentOption.full ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selectedOption == PaymentOption.full
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selectedOption == PaymentOption.full
                      ? colors.primary
                      : colors.textSecondary,
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
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(2)} USD',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'amount + service payment on place',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
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
            decoration: BoxDecoration(
              color: selectedOption == PaymentOption.downPayment
                  ? colors.primarySurface
                  : colors.backgroundCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selectedOption == PaymentOption.downPayment
                    ? colors.primary
                    : colors.borderDefault,
                width: selectedOption == PaymentOption.downPayment ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selectedOption == PaymentOption.downPayment
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selectedOption == PaymentOption.downPayment
                      ? colors.primary
                      : colors.textSecondary,
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
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                          Text(
                            '\$${downPayment.toStringAsFixed(2)} USD',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Prepayment + \$${remaining.toStringAsFixed(2)} USD on place required',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
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
