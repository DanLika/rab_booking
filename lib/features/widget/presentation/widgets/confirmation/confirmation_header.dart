import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../../../../core/design/tokens.dart';
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
// Widget mint accent (handoff widget-confirmation.jsx WC_MINT / WC_MINT_DEEP).
// Canonical widget mint == BbRedesignTokens.mintWidget (#3DD9B0); the deep
// stop and tint rings are handoff-only, kept as file-local named consts.
const Color _kWcMint = Color(0xFF3DD9B0);
const Color _kWcMintDeep = Color(0xFF1FAF87);
const Color _kWcRingSoft = Color(0x243DD9B0); // rgba(61,217,176,.14)
const Color _kWcRingMedium = Color(0x383DD9B0); // rgba(61,217,176,.22)

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

  /// Handoff success mark (widget-confirmation.jsx): mint→mint-deep gradient
  /// disc with two soft mint rings and a white check glyph. Used only for the
  /// genuinely-confirmed states; pending/bank-transfer keep neutral glyphs.
  Widget _buildSuccessMark(double iconSize) {
    // Handoff: outer soft ring inset -10, medium ring inset 0, core disc
    // size-20. Scale those constants off the icon size for parity across bp.
    final double disc = iconSize + 24; // core disc diameter
    final double ring = disc + 20; // medium ring diameter
    return SizedBox(
      width: ring + 20,
      height: ring + 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer soft ring (rgba .14)
          Container(
            width: ring + 20,
            height: ring + 20,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _kWcRingSoft,
            ),
          ),
          // Medium ring (rgba .22)
          Container(
            width: ring,
            height: ring,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: _kWcRingMedium,
            ),
          ),
          // Core gradient disc + white check
          Container(
            width: disc,
            height: disc,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_kWcMint, _kWcMintDeep],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x661FAF87), // rgba(31,175,135,.40)
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.check_rounded,
              size: disc * 0.46,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _getConfirmationIcon(double iconSize) {
    switch (paymentMethod) {
      case 'stripe':
        return _buildSuccessMark(iconSize);
      case 'bank_transfer':
        return Icon(
          Icons.schedule,
          size: iconSize,
          color: colors.textSecondary,
        );
      case 'pay_on_arrival':
        return _buildSuccessMark(iconSize);
      case 'pending':
        return Icon(Icons.pending, size: iconSize, color: colors.textSecondary);
      default:
        return _buildSuccessMark(iconSize);
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
          const SizedBox(height: BBSpace.md),
        ],

        // Success icon with animation
        // Bug #57 Fix: Add Semantics for accessibility
        Semantics(
          label: confirmationMessage,
          image: true,
          child: confirmationIcon.animate().scale(
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            begin: const Offset(0.0, 0.0),
            end: const Offset(1.0, 1.0),
          ),
        ),

        const SizedBox(height: BBSpace.md),

        // Confirmation message
        // Bug #57 Fix: Add Semantics for accessibility
        Semantics(
          label: confirmationMessage,
          header: true,
          child: Text(
            confirmationMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: BBTypeBridges.fontSizeXL,
              fontWeight: BBTypeBridges.weightBold,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
