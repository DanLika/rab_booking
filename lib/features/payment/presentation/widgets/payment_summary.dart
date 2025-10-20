import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../../core/theme/theme_extensions.dart';

/// Premium payment summary widget
/// Features: Price breakdown, advance payment, remaining amount, visual hierarchy
class PremiumPaymentSummary extends StatelessWidget {
  /// Base price (per night × nights)
  final double basePrice;

  /// Service fee
  final double serviceFee;

  /// Cleaning fee
  final double cleaningFee;

  /// Taxes (optional)
  final double? taxes;

  /// Total amount
  final double totalAmount;

  /// Advance payment percentage (default 20%)
  final double advancePercentage;

  /// Currency symbol
  final String currencySymbol;

  /// Number of nights
  final int? nights;

  /// Price per night
  final double? pricePerNight;

  /// Show remaining amount
  final bool showRemainingAmount;

  /// Compact mode
  final bool compact;

  const PremiumPaymentSummary({
    super.key,
    required this.basePrice,
    required this.serviceFee,
    required this.cleaningFee,
    this.taxes,
    required this.totalAmount,
    this.advancePercentage = 20.0,
    this.currencySymbol = '€',
    this.nights,
    this.pricePerNight,
    this.showRemainingAmount = true,
    this.compact = false,
  });

  double get advanceAmount => totalAmount * (advancePercentage / 100);
  double get remainingAmount => totalAmount - advanceAmount;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PremiumCard.elevated(
      elevation: compact ? 1 : 2,
      child: Padding(
        padding: EdgeInsets.all(
          compact ? AppDimensions.spaceM : AppDimensions.spaceL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: AppDimensions.iconM,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppDimensions.spaceS),
                Text(
                  'Payment Summary',
                  style: (compact ? AppTypography.bodyLarge : AppTypography.h3)
                      .copyWith(
                    fontWeight: AppTypography.weightBold,
                  ),
                ),
              ],
            ),

            SizedBox(height: compact ? AppDimensions.spaceM : AppDimensions.spaceL),

            // Price breakdown
            if (nights != null && pricePerNight != null) ...[
              _buildPriceRow(
                '$currencySymbol${pricePerNight!.toStringAsFixed(0)} × $nights night${nights! > 1 ? 's' : ''}',
                '$currencySymbol${basePrice.toStringAsFixed(2)}',
                isDark,
              ),
              const SizedBox(height: AppDimensions.spaceS),
            ],

            _buildPriceRow(
              nights != null && pricePerNight != null ? 'Service fee' : 'Base price',
              '$currencySymbol${(nights != null && pricePerNight != null ? serviceFee : basePrice).toStringAsFixed(2)}',
              isDark,
            ),
            const SizedBox(height: AppDimensions.spaceS),

            if (nights != null && pricePerNight != null) ...[
              _buildPriceRow(
                'Service fee',
                '$currencySymbol${serviceFee.toStringAsFixed(2)}',
                isDark,
              ),
              const SizedBox(height: AppDimensions.spaceS),
            ],

            _buildPriceRow(
              'Cleaning fee',
              '$currencySymbol${cleaningFee.toStringAsFixed(2)}',
              isDark,
            ),

            if (taxes != null && taxes! > 0) ...[
              const SizedBox(height: AppDimensions.spaceS),
              _buildPriceRow(
                'Taxes',
                '$currencySymbol${taxes!.toStringAsFixed(2)}',
                isDark,
              ),
            ],

            Divider(
              height: compact ? AppDimensions.spaceL : AppDimensions.spaceXL,
              thickness: 1,
              color: context.borderColor,
            ),

            // Total
            _buildPriceRow(
              'Total',
              '$currencySymbol${totalAmount.toStringAsFixed(2)}',
              isDark,
              isTotal: true,
            ),

            SizedBox(height: compact ? AppDimensions.spaceM : AppDimensions.spaceL),

            // Advance payment section
            _buildAdvancePaymentSection(isDark),

            if (showRemainingAmount) ...[
              const SizedBox(height: AppDimensions.spaceM),
              _buildRemainingAmountSection(isDark),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value,
    bool isDark, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: (isTotal ? AppTypography.bodyLarge : AppTypography.bodyMedium)
                .copyWith(
              fontWeight: isTotal
                  ? AppTypography.weightBold
                  : AppTypography.weightRegular,
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.spaceM),
        Text(
          value,
          style: (isTotal ? AppTypography.bodyLarge : AppTypography.bodyMedium)
              .copyWith(
            fontWeight: isTotal
                ? AppTypography.weightBold
                : AppTypography.weightMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancePaymentSection(bool isDark) {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          boxShadow: AppShadows.glowPrimary,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pay now (${advancePercentage.toStringAsFixed(0)}%)',
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.textColorInverted,
                      fontWeight: AppTypography.weightSemibold,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceXXS),
                  Text(
                    'Secure your booking',
                    style: AppTypography.small.copyWith(
                      color: context.textColorInverted.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$currencySymbol${advanceAmount.toStringAsFixed(2)}',
              style: AppTypography.h2.copyWith(
                color: context.textColorInverted,
                fontWeight: AppTypography.weightBold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemainingAmountSection(bool isDark) {
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppDimensions.spaceM),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(
            color: context.borderColor,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Remaining amount',
                    style: AppTypography.bodyMedium.copyWith(
                      color: context.textColorSecondary,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spaceXXS),
                  Text(
                    'Pay at property',
                    style: AppTypography.small.copyWith(
                      color: context.textColorSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$currencySymbol${remainingAmount.toStringAsFixed(2)}',
              style: AppTypography.h3.copyWith(
                color: context.textColorSecondary,
                fontWeight: AppTypography.weightSemibold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
