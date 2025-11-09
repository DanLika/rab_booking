import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/models/payment_option.dart';
import '../providers/booking_flow_provider.dart';
import '../theme/responsive_helper.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

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
    final isMobile = ResponsiveHelper.isMobile(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment method',
          style: GoogleFonts.inter(
            fontSize: isMobile ? TypographyTokens.fontSizeXL : TypographyTokens.fontSizeXXL,
            fontWeight: TypographyTokens.semiBold,
            color: ColorTokens.light.textPrimary,
          ),
        ),
        const SizedBox(height: SpacingTokens.m),

        // Responsive layout: Row for desktop, Column for mobile
        isMobile
            ? Column(
                children: [
                  _buildPaymentOption(
                    context: context,
                    ref: ref,
                    method: PaymentMethod.bankTransfer,
                    isSelected: selectedMethod == PaymentMethod.bankTransfer,
                    icon: Icons.account_balance,
                    title: 'Bank transfer',
                    description:
                        'Waiting time for a bank transfer: 3 working days. If you do not make the transfer, the reservation will be cancelled.',
                    badge: null,
                  ),
                  const SizedBox(height: SpacingTokens.m),
                  if (enableStripe)
                    _buildPaymentOption(
                      context: context,
                      ref: ref,
                      method: PaymentMethod.stripe,
                      isSelected: selectedMethod == PaymentMethod.stripe,
                      icon: Icons.credit_card,
                      title: 'Credit Card',
                      description:
                          'Instant confirmation with credit card payment via Stripe. Secure and fast.',
                      badge: 'INSTANT',
                    ),
                  if (enableStripe) const SizedBox(height: SpacingTokens.m),
                  _buildPaymentOption(
                    context: context,
                    ref: ref,
                    method: PaymentMethod.onPlace,
                    isSelected: selectedMethod == PaymentMethod.onPlace,
                    icon: Icons.credit_card_off,
                    title: 'Pay on Arrival',
                    description:
                        'Pay the full amount when you arrive at the property.',
                    badge: null,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: _buildPaymentOption(
                      context: context,
                      ref: ref,
                      method: PaymentMethod.bankTransfer,
                      isSelected: selectedMethod == PaymentMethod.bankTransfer,
                      icon: Icons.account_balance,
                      title: 'Bank transfer',
                      description:
                          'Waiting time for a bank transfer: 3 working days. If you do not make the transfer, the reservation will be cancelled.',
                      badge: null,
                    ),
                  ),
                  const SizedBox(width: SpacingTokens.m),
                  if (enableStripe)
                    Expanded(
                      child: _buildPaymentOption(
                        context: context,
                        ref: ref,
                        method: PaymentMethod.stripe,
                        isSelected: selectedMethod == PaymentMethod.stripe,
                        icon: Icons.credit_card,
                        title: 'Credit Card',
                        description:
                            'Instant confirmation with credit card payment via Stripe. Secure and fast.',
                        badge: 'INSTANT',
                      ),
                    ),
                  if (enableStripe) const SizedBox(width: SpacingTokens.m),
                  Expanded(
                    child: _buildPaymentOption(
                      context: context,
                      ref: ref,
                      method: PaymentMethod.onPlace,
                      isSelected: selectedMethod == PaymentMethod.onPlace,
                      icon: Icons.credit_card_off,
                      title: 'Pay on Arrival',
                      description:
                          'Pay the full amount when you arrive at the property.',
                      badge: null,
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required BuildContext context,
    required WidgetRef ref,
    required PaymentMethod method,
    required bool isSelected,
    required IconData icon,
    required String title,
    required String description,
    String? badge,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          ref.read(paymentMethodProvider.notifier).state = method;
        },
        child: AnimatedContainer(
          duration: AnimationTokens.fast,
          padding: const EdgeInsets.all(SpacingTokens.m2),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      ColorTokens.azure50, // Very light azure
                      ColorTokens.withOpacity(ColorTokens.azure100, OpacityTokens.almostOpaque),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : ColorTokens.light.backgroundCard,
            borderRadius: BorderTokens.circularRounded,
            border: Border.all(
              color: isSelected
                  ? ColorTokens.light.primary
                  : ColorTokens.light.borderDefault,
              width: isSelected ? BorderTokens.widthThick : BorderTokens.widthThin,
            ),
            boxShadow: isSelected
                ? ColorTokens.light.shadowMedium
                : ColorTokens.light.shadowLight,
          ),
          child: Column(
            children: [
              // Radio icon
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected
                    ? ColorTokens.light.primary
                    : ColorTokens.light.textSecondary,
                size: IconSizeTokens.large,
              ),
              const SizedBox(height: SpacingTokens.s2),

              // Title with optional badge
              if (badge != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: TypographyTokens.fontSizeM,
                        fontWeight: TypographyTokens.semiBold,
                        color: ColorTokens.light.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(width: SpacingTokens.xs2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: SpacingTokens.xs2, vertical: SpacingTokens.xxs),
                      decoration: BoxDecoration(
                        color: ColorTokens.light.statusAvailableBackground,
                        borderRadius: BorderTokens.circularSubtle,
                      ),
                      child: Text(
                        badge,
                        style: GoogleFonts.inter(
                          fontSize: TypographyTokens.fontSizeXS,
                          fontWeight: TypographyTokens.bold,
                          color: ColorTokens.light.success,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: TypographyTokens.fontSizeM,
                    fontWeight: TypographyTokens.semiBold,
                    color: ColorTokens.light.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: SpacingTokens.s),

              // Description
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: TypographyTokens.fontSizeS,
                  color: ColorTokens.light.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: SpacingTokens.s2),

              // Icon
              Icon(
                icon,
                size: IconSizeTokens.xxl,
                color: isSelected
                    ? ColorTokens.light.primary
                    : ColorTokens.light.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
