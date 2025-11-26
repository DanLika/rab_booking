import 'package:flutter/material.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

/// Reusable next steps section for booking confirmation
/// Displays different steps based on payment method
class NextStepsSection extends StatelessWidget {
  final bool isDarkMode;
  final String paymentMethod;

  const NextStepsSection({
    super.key,
    required this.isDarkMode,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final colors = isDarkMode ? ColorTokens.dark : ColorTokens.light;
    final steps = _getStepsForPaymentMethod();

    return Padding(
      padding: const EdgeInsets.only(top: SpacingTokens.l),
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.m),
        decoration: BoxDecoration(
          color: colors.backgroundSecondary,
          borderRadius: BorderTokens.circularMedium,
          border: Border.all(
            color: colors.borderDefault,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What\'s Next?',
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

  List<Map<String, dynamic>> _getStepsForPaymentMethod() {
    switch (paymentMethod) {
      case 'stripe':
        return [
          {
            'icon': Icons.email,
            'title': 'Check Your Email',
            'description': 'Confirmation email sent with all booking details',
          },
          {
            'icon': Icons.calendar_today,
            'title': 'Add to Calendar',
            'description':
                'Click the "Add to My Calendar" button above to download the event',
          },
          {
            'icon': Icons.directions,
            'title': 'Prepare for Your Stay',
            'description': 'Check-in instructions will be sent 24h before',
          },
        ];

      case 'bank_transfer':
        return [
          {
            'icon': Icons.account_balance,
            'title': 'Complete Bank Transfer',
            'description':
                'Transfer the deposit amount within 3 days using the reference number',
          },
          {
            'icon': Icons.email,
            'title': 'Check Your Email',
            'description':
                'Bank transfer instructions and booking details have been sent',
          },
          {
            'icon': Icons.pending,
            'title': 'Awaiting Confirmation',
            'description':
                'We\'ll confirm your booking once payment is received (usually within 24h)',
          },
        ];

      case 'pay_on_arrival':
        return [
          {
            'icon': Icons.email,
            'title': 'Check Your Email',
            'description':
                'Confirmation email sent with all booking details and payment instructions',
          },
          {
            'icon': Icons.calendar_today,
            'title': 'Add to Calendar',
            'description':
                'Click the "Add to My Calendar" button above to download the event',
          },
          {
            'icon': Icons.payments_outlined,
            'title': 'Payment on Arrival',
            'description':
                'Bring payment with you - cash or card accepted at the property',
          },
          {
            'icon': Icons.directions,
            'title': 'Prepare for Your Stay',
            'description':
                'Check-in instructions will be sent 24h before arrival',
          },
        ];

      default:
        return [
          {
            'icon': Icons.email,
            'title': 'Check Your Email',
            'description': 'Confirmation email sent with all booking details',
          },
          {
            'icon': Icons.pending,
            'title': 'Awaiting Processing',
            'description': 'Your booking is being processed',
          },
        ];
    }
  }

  Widget _buildStepItem(
    dynamic colors,
    Map<String, dynamic> step,
    bool isLast,
  ) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.textPrimary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  step['icon'] as IconData,
                  color: colors.backgroundPrimary,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: SpacingTokens.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step['title'] as String,
                    style: TextStyle(
                      fontSize: TypographyTokens.fontSizeM,
                      fontWeight: TypographyTokens.semiBold,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: SpacingTokens.xxs),
                  Text(
                    step['description'] as String,
                    style: TextStyle(
                      fontSize: TypographyTokens.fontSizeS,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: SpacingTokens.m),
          Container(
            margin: const EdgeInsets.only(left: 20),
            width: 2,
            height: 24,
            color: colors.textPrimary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: SpacingTokens.m),
        ],
      ],
    );
  }
}
