import 'package:flutter/material.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../theme/minimalist_colors.dart';
import '../common/theme_colors_helper.dart';
import 'price_row_widget.dart';

/// Price breakdown container showing room price, services, total, and deposit.
///
/// Displays a summary of booking costs including:
/// - Room price (per night × nights)
/// - Additional services (if any)
/// - Total price
/// - Deposit amount and percentage
///
/// Usage:
/// ```dart
/// PriceBreakdownWidget(
///   isDarkMode: isDarkMode,
///   nights: calculation.nights,
///   formattedRoomPrice: calculation.formattedRoomPrice,
///   additionalServicesTotal: calculation.additionalServicesTotal,
///   formattedAdditionalServices: calculation.formattedAdditionalServices,
///   formattedTotal: calculation.formattedTotal,
///   formattedDeposit: calculation.formattedDeposit,
///   depositPercentage: 20,
/// )
/// ```
class PriceBreakdownWidget extends StatelessWidget {
  /// Whether dark mode is active
  final bool isDarkMode;

  /// Number of nights for the booking
  final int nights;

  /// Formatted room price string (e.g., "€300.00")
  final String formattedRoomPrice;

  /// Total additional services amount (used to determine visibility)
  final double additionalServicesTotal;

  /// Formatted additional services string
  final String? formattedAdditionalServices;

  /// Formatted total price string
  final String formattedTotal;

  /// Formatted deposit amount string
  final String formattedDeposit;

  /// Deposit percentage (e.g., 20 for 20%)
  final int depositPercentage;

  const PriceBreakdownWidget({
    super.key,
    required this.isDarkMode,
    required this.nights,
    required this.formattedRoomPrice,
    this.additionalServicesTotal = 0,
    this.formattedAdditionalServices,
    required this.formattedTotal,
    required this.formattedDeposit,
    required this.depositPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final getColor = ThemeColorsHelper.createColorGetter(isDarkMode);

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        color: getColor(
          MinimalistColors.backgroundSecondary,
          MinimalistColorsDark.backgroundSecondary,
        ),
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
      ),
      child: Column(
        children: [
          // Room price
          PriceRowWidget(
            label: 'Room ($nights ${nights == 1 ? 'night' : 'nights'})',
            amount: formattedRoomPrice,
            isDarkMode: isDarkMode,
          ),

          // Additional services (only show if > 0)
          if (additionalServicesTotal > 0 &&
              formattedAdditionalServices != null) ...[
            const SizedBox(height: SpacingTokens.s),
            PriceRowWidget(
              label: 'Additional Services',
              amount: formattedAdditionalServices!,
              isDarkMode: isDarkMode,
              color: getColor(
                MinimalistColors.statusAvailableBorder,
                MinimalistColorsDark.statusAvailableBorder,
              ),
            ),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(vertical: SpacingTokens.s),
            child: Divider(
              height: 1,
              color: getColor(
                MinimalistColors.borderDefault,
                MinimalistColorsDark.borderDefault,
              ),
            ),
          ),

          // Total
          PriceRowWidget(
            label: 'Total',
            amount: formattedTotal,
            isDarkMode: isDarkMode,
            isBold: true,
          ),

          // Deposit info
          const SizedBox(height: SpacingTokens.s),
          Text(
            'Deposit: $formattedDeposit ($depositPercentage%)',
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeS,
              color: getColor(
                MinimalistColors.textSecondary,
                MinimalistColorsDark.textSecondary,
              ),
              fontFamily: 'Manrope',
            ),
          ),
        ],
      ),
    );
  }
}
