import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../l10n/widget_translations.dart';

/// Reusable next steps section for booking confirmation
/// Displays different steps based on payment method
class NextStepsSection extends ConsumerWidget {
  final bool isDarkMode;
  final String paymentMethod;

  const NextStepsSection({super.key, required this.isDarkMode, required this.paymentMethod});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;
    final tr = WidgetTranslations.of(context, ref);
    final steps = _getStepsForPaymentMethod(tr);
    // Use backgroundTertiary in dark mode for better contrast
    final cardBackground = isDarkMode ? colors.backgroundTertiary : colors.backgroundSecondary;
    final cardBorder = isDarkMode ? colors.borderMedium : colors.borderDefault;

    return Padding(
      padding: const EdgeInsets.only(top: SpacingTokens.l),
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.m),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderTokens.circularMedium,
          border: Border.all(color: cardBorder, width: isDarkMode ? 1.5 : 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr.whatsNext,
              style: TextStyle(
                fontSize: TypographyTokens.fontSizeL,
                fontWeight: TypographyTokens.bold,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: SpacingTokens.m),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isLast = index == steps.length - 1;

              return _buildStepItem(colors, step, isLast);
            }),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getStepsForPaymentMethod(WidgetTranslations tr) {
    switch (paymentMethod) {
      case 'stripe':
        return [
          {'icon': Icons.email, 'title': tr.checkYourEmail, 'description': tr.confirmationEmailSent},
          {'icon': Icons.calendar_today, 'title': tr.addToCalendar, 'description': tr.addToCalendarDescription},
          {'icon': Icons.directions, 'title': tr.prepareForYourStay, 'description': tr.checkInInstructionsSent},
        ];

      case 'bank_transfer':
        return [
          {'icon': Icons.account_balance, 'title': tr.completeBankTransfer, 'description': tr.bankTransferDescription},
          {'icon': Icons.email, 'title': tr.checkYourEmail, 'description': tr.bankTransferInstructionsSent},
          {'icon': Icons.pending, 'title': tr.awaitingConfirmation, 'description': tr.awaitingConfirmationDescription},
        ];

      case 'pay_on_arrival':
        return [
          {'icon': Icons.email, 'title': tr.checkYourEmail, 'description': tr.confirmationEmailSentWithPayment},
          {'icon': Icons.calendar_today, 'title': tr.addToCalendar, 'description': tr.addToCalendarDescription},
          {
            'icon': Icons.payments_outlined,
            'title': tr.paymentOnArrivalTitle,
            'description': tr.paymentOnArrivalDescription,
          },
          {'icon': Icons.directions, 'title': tr.prepareForYourStay, 'description': tr.checkInInstructionsSentBefore},
        ];

      default:
        return [
          {'icon': Icons.email, 'title': tr.checkYourEmail, 'description': tr.confirmationEmailSent},
          {'icon': Icons.pending, 'title': tr.awaitingProcessing, 'description': tr.bookingBeingProcessed},
        ];
    }
  }

  // Bug #55 Fix: Type safety i safe casting
  Widget _buildStepItem(WidgetColorScheme colors, Map<String, dynamic> step, bool isLast) {
    // Safe casting sa provjerama
    final icon = step['icon'] is IconData ? step['icon'] as IconData : Icons.help_outline; // Fallback icon

    final title = step['title'] is String ? step['title'] as String : 'Unknown step'; // Fallback title

    final description = step['description'] is String ? step['description'] as String : ''; // Fallback description

    // Bug #57 Fix: Add Semantics for accessibility
    return Semantics(
      label: title,
      hint: description,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: colors.textPrimary, shape: BoxShape.circle),
                child: Center(child: Icon(icon, color: colors.backgroundPrimary, size: 20)),
              ),
              const SizedBox(width: SpacingTokens.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: TypographyTokens.fontSizeM,
                        fontWeight: TypographyTokens.semiBold,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: SpacingTokens.xxs),
                    Text(
                      description,
                      style: TextStyle(fontSize: TypographyTokens.fontSizeS, color: colors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isLast) ...[
            const SizedBox(height: SpacingTokens.s),
            Container(
              margin: const EdgeInsets.only(left: 19),
              width: 3,
              height: 28,
              decoration: BoxDecoration(
                color: colors.textPrimary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(height: SpacingTokens.s),
          ],
        ],
      ),
    );
  }
}
