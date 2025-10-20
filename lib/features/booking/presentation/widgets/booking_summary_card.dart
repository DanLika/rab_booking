import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../../core/theme/theme_extensions.dart';

/// Premium booking summary card
/// Features: Property info, dates, guests, price breakdown, editable
class BookingSummaryCard extends StatelessWidget {
  /// Property name
  final String propertyName;

  /// Property image URL
  final String? propertyImage;

  /// Property location
  final String propertyLocation;

  /// Check-in date
  final DateTime checkIn;

  /// Check-out date
  final DateTime checkOut;

  /// Number of guests
  final int guests;

  /// Number of nights
  final int nights;

  /// Price per night
  final double pricePerNight;

  /// Service fee
  final double serviceFee;

  /// Cleaning fee
  final double cleaningFee;

  /// Taxes
  final double? taxes;

  /// Currency symbol
  final String currencySymbol;

  /// Show edit button
  final bool showEditButton;

  /// On edit callback
  final VoidCallback? onEdit;

  /// Compact mode
  final bool compact;

  const BookingSummaryCard({
    super.key,
    required this.propertyName,
    this.propertyImage,
    required this.propertyLocation,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.nights,
    required this.pricePerNight,
    required this.serviceFee,
    required this.cleaningFee,
    this.taxes,
    this.currencySymbol = '\$',
    this.showEditButton = false,
    this.onEdit,
    this.compact = false,
  });

  double get total {
    final subtotal = pricePerNight * nights;
    return subtotal + serviceFee + cleaningFee + (taxes ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return PremiumCard.elevated(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(
          compact ? AppDimensions.spaceM : AppDimensions.spaceL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Booking Summary',
                  style: compact ? AppTypography.bodyLarge : AppTypography.h3,
                ),
                if (showEditButton && onEdit != null)
                  PremiumButton.text(
                    label: 'Edit',
                    icon: Icons.edit_outlined,
                    onPressed: onEdit,
                    size: ButtonSize.small,
                  ),
              ],
            ),

            const SizedBox(height: AppDimensions.spaceL),

            // Property info
            _buildPropertyInfo(context),

            const SizedBox(height: AppDimensions.spaceL),

            Divider(
              thickness: 1,
              color: context.borderColor,
            ),

            const SizedBox(height: AppDimensions.spaceL),

            // Booking details
            _buildBookingDetails(context),

            const SizedBox(height: AppDimensions.spaceL),

            Divider(
              thickness: 1,
              color: context.borderColor,
            ),

            const SizedBox(height: AppDimensions.spaceL),

            // Price breakdown
            _buildPriceBreakdown(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyInfo(BuildContext context) {
    return Row(
      children: [
        // Property image
        if (propertyImage != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            child: SizedBox(
              width: compact ? 60 : 80,
              height: compact ? 60 : 80,
              child: PremiumImage(
                imageUrl: propertyImage!,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spaceM),
        ],

        // Property details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                propertyName,
                style: compact
                    ? AppTypography.bodyLarge.copyWith(
                        fontWeight: AppTypography.weightSemibold,
                      )
                    : AppTypography.h3,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppDimensions.spaceXXS),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: AppDimensions.iconS,
                    color: context.textColorSecondary,
                  ),
                  const SizedBox(width: AppDimensions.spaceXXS),
                  Expanded(
                    child: Text(
                      propertyLocation,
                      style: AppTypography.bodyMedium.copyWith(
                        color: context.textColorSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBookingDetails(BuildContext context) {
    return Column(
      children: [
        _buildDetailRow(
          context: context,
          icon: Icons.calendar_today_outlined,
          label: 'Check-in',
          value: _formatDate(checkIn),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        _buildDetailRow(
          context: context,
          icon: Icons.calendar_today_outlined,
          label: 'Check-out',
          value: _formatDate(checkOut),
        ),
        const SizedBox(height: AppDimensions.spaceM),
        _buildDetailRow(
          context: context,
          icon: Icons.nightlight_outlined,
          label: 'Nights',
          value: '$nights ${nights == 1 ? 'night' : 'nights'}',
        ),
        const SizedBox(height: AppDimensions.spaceM),
        _buildDetailRow(
          context: context,
          icon: Icons.people_outline,
          label: 'Guests',
          value: '$guests ${guests == 1 ? 'guest' : 'guests'}',
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: AppDimensions.iconM,
          color: AppColors.primary,
        ),
        const SizedBox(width: AppDimensions.spaceM),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: context.textColorSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: AppTypography.weightMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceBreakdown(BuildContext context) {
    final subtotal = pricePerNight * nights;

    return Column(
      children: [
        // Subtotal
        _buildPriceRow(
          context: context,
          label: '$currencySymbol${pricePerNight.toStringAsFixed(0)} x $nights ${nights == 1 ? 'night' : 'nights'}',
          value: '$currencySymbol${subtotal.toStringAsFixed(2)}',
        ),

        const SizedBox(height: AppDimensions.spaceS),

        // Service fee
        _buildPriceRow(
          context: context,
          label: 'Service fee',
          value: '$currencySymbol${serviceFee.toStringAsFixed(2)}',
        ),

        const SizedBox(height: AppDimensions.spaceS),

        // Cleaning fee
        _buildPriceRow(
          context: context,
          label: 'Cleaning fee',
          value: '$currencySymbol${cleaningFee.toStringAsFixed(2)}',
        ),

        // Taxes (if applicable)
        if (taxes != null && taxes! > 0) ...[
          const SizedBox(height: AppDimensions.spaceS),
          _buildPriceRow(
            context: context,
            label: 'Taxes',
            value: '$currencySymbol${taxes!.toStringAsFixed(2)}',
          ),
        ],

        const SizedBox(height: AppDimensions.spaceM),

        Divider(
          thickness: 1,
          color: context.borderColor,
        ),

        const SizedBox(height: AppDimensions.spaceM),

        // Total
        _buildPriceRow(
          context: context,
          label: 'Total',
          value: '$currencySymbol${total.toStringAsFixed(2)}',
          isTotal: true,
        ),
      ],
    );
  }

  Widget _buildPriceRow({
    required BuildContext context,
    required String label,
    required String value,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTypography.bodyLarge.copyWith(
                  fontWeight: AppTypography.weightBold,
                )
              : AppTypography.bodyMedium,
        ),
        Text(
          value,
          style: isTotal
              ? AppTypography.h3.copyWith(
                  fontWeight: AppTypography.weightBold,
                  color: AppColors.primary,
                )
              : AppTypography.bodyMedium.copyWith(
                  fontWeight: AppTypography.weightMedium,
                ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
