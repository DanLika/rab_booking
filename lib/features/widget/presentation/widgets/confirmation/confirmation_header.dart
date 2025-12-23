import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../l10n/widget_translations.dart';

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
///   customLogoUrl: widgetSettings?.themeOptions?.customLogoUrl,
/// )
/// ```
///
/// Uses flutter_animate for scale animation on the icon.
class ConfirmationHeader extends ConsumerWidget {
  /// Payment method: 'stripe', 'bank_transfer', 'pay_on_arrival', 'pending'
  final String paymentMethod;

  /// Color tokens for theming
  final WidgetColorScheme colors;

  /// Optional custom logo URL from widget settings
  final String? customLogoUrl;

  const ConfirmationHeader({
    super.key,
    required this.paymentMethod,
    required this.colors,
    this.customLogoUrl,
  });

  String _getConfirmationMessage(WidgetTranslations tr) {
    switch (paymentMethod) {
      case 'stripe':
        return tr.paymentSuccessfulBookingConfirmed;
      case 'bank_transfer':
        return tr.bookingReceivedCompleteBankTransfer;
      case 'pay_on_arrival':
        return tr.bookingConfirmedPayAtProperty;
      case 'pending':
        return tr.bookingRequestSentWaitingApproval;
      default:
        return tr.yourBookingHasBeenConfirmed;
    }
  }

  Widget _getConfirmationIcon(double iconSize) {
    switch (paymentMethod) {
      case 'stripe':
        return Icon(
          Icons.check_circle,
          size: iconSize,
          color: colors.textPrimary,
        );
      case 'bank_transfer':
        return Icon(
          Icons.schedule,
          size: iconSize,
          color: colors.textSecondary,
        );
      case 'pay_on_arrival':
        return Icon(Icons.hotel, size: iconSize, color: colors.textPrimary);
      case 'pending':
        return Icon(Icons.pending, size: iconSize, color: colors.textSecondary);
      default:
        return Icon(
          Icons.check_circle,
          size: iconSize,
          color: colors.textPrimary,
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = WidgetTranslations.of(context, ref);
    // Bug #53 Fix: Defensive check za MediaQuery
    final screenWidth = MediaQuery.maybeOf(context)?.size.width ?? 400.0;
    final iconSize = screenWidth < 600 ? 56.0 : 80.0;
    final logoHeight = screenWidth < 600 ? 60.0 : 80.0;

    final confirmationMessage = _getConfirmationMessage(tr);
    final confirmationIcon = _getConfirmationIcon(iconSize);
    // Bug #56 Fix: Remove redundant null assertion operator - use local variable
    final logoUrl = customLogoUrl;

    return Column(
      children: [
        // Custom logo display (if configured)
        if (logoUrl != null && logoUrl.isNotEmpty) ...[
          CachedNetworkImage(
            imageUrl: logoUrl,
            height: logoHeight,
            fit: BoxFit.contain,
            placeholder: (context, url) =>
                SizedBox(height: logoHeight, width: logoHeight),
            errorWidget: (context, url, error) => const SizedBox.shrink(),
          ),
          const SizedBox(height: SpacingTokens.l),
        ],

        // Success icon with animation
        // Bug #57 Fix: Add Semantics for accessibility
        Semantics(
          label: confirmationMessage,
          image: true,
          child: confirmationIcon
              .animate()
              .scale(
                duration: const Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                begin: const Offset(0.0, 0.0),
                end: const Offset(1.0, 1.0),
              ),
        ),

        const SizedBox(height: SpacingTokens.l),

        // Confirmation message
        // Bug #57 Fix: Add Semantics for accessibility
        Semantics(
          label: confirmationMessage,
          header: true,
          child: Text(
            confirmationMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeXL,
              fontWeight: TypographyTokens.bold,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
