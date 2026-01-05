import 'package:flutter/material.dart';
import '../../../../../core/design_tokens/design_tokens.dart';
import '../../theme/minimalist_colors.dart';
import '../../l10n/widget_translations.dart';
import '../../../domain/constants/widget_constants.dart';
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
/// final currency = WidgetTranslations.of(context, ref).currencySymbol;
/// PriceBreakdownWidget(
///   isDarkMode: isDarkMode,
///   nights: calculation.nights,
///   formattedRoomPrice: calculation.formatRoomPrice(currency),
///   additionalServicesTotal: calculation.additionalServicesTotal,
///   formattedAdditionalServices: calculation.formatAdditionalServices(currency),
///   formattedTotal: calculation.formatTotal(currency),
///   formattedDeposit: calculation.formatDeposit(currency),
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

  /// Translations for localization
  final WidgetTranslations translations;

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
    required this.translations,
  });

  @override
  Widget build(BuildContext context) {
    final colors = MinimalistColorSchemeAdapter(dark: isDarkMode);

    return Container(
      padding: const EdgeInsets.all(SpacingTokens.m),
      decoration: BoxDecoration(
        // Pure white (light) / pure black (dark) for form containers
        color: colors.backgroundPrimary,
        borderRadius: BorderRadius.circular(BorderTokens.radiusMedium),
        border: Border.all(color: colors.borderDefault),
      ),
      child: Column(
        children: [
          // Room price
          PriceRowWidget(
            label: translations.roomNights(nights),
            amount: formattedRoomPrice,
            isDarkMode: isDarkMode,
          ),

          // Additional services (only show if > tolerance)
          // Bug #37 Fix: Use tolerance-based comparison to handle floating point precision
          if (additionalServicesTotal.abs() > WidgetConstants.priceTolerance &&
              formattedAdditionalServices != null) ...[
            const SizedBox(height: SpacingTokens.s),
            PriceRowWidget(
              label: translations.additionalServices,
              amount: formattedAdditionalServices!,
              isDarkMode: isDarkMode,
              color: colors.statusAvailableBorder,
            ),
          ],

          Padding(
            padding: const EdgeInsets.symmetric(vertical: SpacingTokens.s),
            child: Divider(height: 1, color: colors.borderDefault),
          ),

          // Total
          PriceRowWidget(
            label: translations.total,
            amount: formattedTotal,
            isDarkMode: isDarkMode,
            isBold: true,
          ),

          // Deposit info
          const SizedBox(height: SpacingTokens.s),
          Text(
            translations.depositWithPercentage(
              formattedDeposit,
              depositPercentage,
            ),
            style: TextStyle(
              fontSize: TypographyTokens.fontSizeS,
              color: colors.textSecondary,
              fontFamily: TypographyTokens.primaryFont,
            ),
          ),
        ],
      ),
    );
  }
}
