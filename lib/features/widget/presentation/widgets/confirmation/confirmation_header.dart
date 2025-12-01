import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/design_tokens/design_tokens.dart';

/// Animated confirmation header with icon and message.
///
/// Displays a success/pending/info icon with scale animation
/// and contextual confirmation message based on payment method.
///
/// Usage:
/// ```dart
/// ConfirmationHeader(
///   paymentMethod: 'stripe',
///   colors: ColorTokens.light,
///   scaleAnimation: _scaleAnimation,
///   customLogoUrl: widgetSettings?.themeOptions?.customLogoUrl,
/// )
/// ```
class ConfirmationHeader extends StatelessWidget {
  /// Payment method: 'stripe', 'bank_transfer', 'pay_on_arrival', 'pending'
  final String paymentMethod;

  /// Color tokens for theming
  final WidgetColorScheme colors;

  /// Scale animation for the icon
  final Animation<double> scaleAnimation;

  /// Optional custom logo URL from widget settings
  final String? customLogoUrl;

  const ConfirmationHeader({
    super.key,
    required this.paymentMethod,
    required this.colors,
    required this.scaleAnimation,
    this.customLogoUrl,
  });

  String _getConfirmationMessage() {
    switch (paymentMethod) {
      case 'stripe':
        return 'Payment successful! Your booking is confirmed.';
      case 'bank_transfer':
        return 'Booking received! Please complete the bank transfer to confirm.';
      case 'pay_on_arrival':
        return 'Booking confirmed! You can pay at the property.';
      case 'pending':
        return 'Booking request sent! Waiting for owner approval.';
      default:
        return 'Your booking has been confirmed!';
    }
  }

  Widget _getConfirmationIcon() {
    switch (paymentMethod) {
      case 'stripe':
        return Icon(Icons.check_circle, size: 80, color: colors.textPrimary);
      case 'bank_transfer':
        return Icon(Icons.schedule, size: 80, color: colors.textSecondary);
      case 'pay_on_arrival':
        return Icon(Icons.hotel, size: 80, color: colors.textPrimary);
      case 'pending':
        return Icon(Icons.pending, size: 80, color: colors.textSecondary);
      default:
        return Icon(Icons.check_circle, size: 80, color: colors.textPrimary);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Custom logo display (if configured)
        if (customLogoUrl != null && customLogoUrl!.isNotEmpty) ...[
          CachedNetworkImage(
            imageUrl: customLogoUrl!,
            height: 80,
            fit: BoxFit.contain,
            placeholder: (context, url) =>
                const SizedBox(height: 80, width: 80),
            errorWidget: (context, url, error) => const SizedBox.shrink(),
          ),
          const SizedBox(height: SpacingTokens.l),
        ],

        // Success icon with animation
        ScaleTransition(
          scale: scaleAnimation,
          child: _getConfirmationIcon(),
        ),

        const SizedBox(height: SpacingTokens.l),

        // Confirmation message
        Text(
          _getConfirmationMessage(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: TypographyTokens.fontSizeXL,
            fontWeight: TypographyTokens.bold,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
