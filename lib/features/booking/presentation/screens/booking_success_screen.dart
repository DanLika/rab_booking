import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../../../../core/utils/navigation_helpers.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/booking_summary_card.dart';

/// Booking success screen
/// Features: Success animation, booking reference, summary, actions
class BookingSuccessScreen extends StatelessWidget {
  /// Booking reference number
  final String bookingReference;

  /// Property name
  final String propertyName;

  /// Property image
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

  /// Total amount paid
  final double totalAmount;

  /// Currency symbol
  final String currencySymbol;

  /// Confirmation email
  final String confirmationEmail;

  const BookingSuccessScreen({
    super.key,
    required this.bookingReference,
    required this.propertyName,
    this.propertyImage,
    required this.propertyLocation,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.nights,
    required this.totalAmount,
    this.currencySymbol = '€',
    required this.confirmationEmail,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: MaxWidthContainer(
            maxWidth: AppDimensions.containerM,
            padding: EdgeInsets.all(context.horizontalPadding),
            child: Column(
              children: [
                SizedBox(height: context.isMobile ? AppDimensions.spaceXL : AppDimensions.spaceXXL),

                // Success animation
                _buildSuccessAnimation(context),

                const SizedBox(height: AppDimensions.spaceXL),

                // Success message
                _buildSuccessMessage(context),

                const SizedBox(height: AppDimensions.spaceXXL),

                // Booking reference
                _buildBookingReference(context),

                const SizedBox(height: AppDimensions.spaceXL),

                // Confirmation email sent
                _buildEmailConfirmation(context),

                const SizedBox(height: AppDimensions.spaceXXL),

                // Booking summary
                BookingSummaryCard(
                  propertyName: propertyName,
                  propertyImage: propertyImage,
                  propertyLocation: propertyLocation,
                  checkIn: checkIn,
                  checkOut: checkOut,
                  guests: guests,
                  nights: nights,
                  pricePerNight: totalAmount / nights,
                  serviceFee: 0,
                  cleaningFee: 0,
                  currencySymbol: currencySymbol,
                  compact: context.isMobile,
                ),

                const SizedBox(height: AppDimensions.spaceXXL),

                // Action buttons
                _buildActionButtons(context),

                const SizedBox(height: AppDimensions.spaceXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessAnimation(BuildContext context) {
    // Success animation with scale and fade effects
    return Container(
      width: 120,
      height: 120,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: AppShadows.glowPrimary,
      ),
      child: Icon(
        Icons.check,
        size: 64,
        color: context.textColorInverted,
      ),
    )
        .animate()
        .scale(
          duration: 800.ms,
          curve: Curves.elasticOut,
          begin: const Offset(0.0, 0.0),
          end: const Offset(1.0, 1.0),
        )
        .fadeIn(duration: 400.ms);
  }

  Widget _buildSuccessMessage(BuildContext context) {
    return Column(
      children: [
        Text(
          'Rezervacija potvrđena!',
          style: context.isMobile ? AppTypography.h2 : AppTypography.h1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDimensions.spaceS),
        Text(
          'Vaša rezervacija je uspješno potvrđena',
          style: AppTypography.bodyLarge.copyWith(
            color: context.textColorSecondary,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    )
        .animate(delay: 300.ms)
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildBookingReference(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: AppShadows.glowPrimary,
      ),
      child: Column(
        children: [
          Text(
            'Referentni broj rezervacije',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.withOpacity(context.textColorInverted, AppColors.opacity90),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            bookingReference,
            style: (context.isMobile ? AppTypography.h2 : AppTypography.h1).copyWith(
              color: context.textColorInverted,
              fontWeight: AppTypography.weightBold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailConfirmation(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: BoxDecoration(
        color: AppColors.withOpacity(AppColors.success, AppColors.opacity10),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: AppColors.success,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.email_outlined,
            color: AppColors.success,
            size: AppDimensions.iconL,
          ),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Potvrda poslana emailom',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: AppTypography.weightSemibold,
                    color: AppColors.success,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppDimensions.spaceXXS),
                Text(
                  'Provjerite $confirmationEmail za detalje rezervacije',
                  style: AppTypography.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // View booking details
        PremiumButton.primary(
          label: 'Pogledaj detalje rezervacije',
          icon: Icons.receipt_long_outlined,
          isFullWidth: true,
          size: ButtonSize.large,
          onPressed: () => context.goToMyBookings(),
        ),

        const SizedBox(height: AppDimensions.spaceM),

        // Secondary actions
        context.isMobile
            ? Column(
                children: [
                  _buildDownloadButton(context),
                  const SizedBox(height: AppDimensions.spaceM),
                  _buildShareButton(context),
                  const SizedBox(height: AppDimensions.spaceM),
                  _buildHomeButton(context),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _buildDownloadButton(context)),
                  const SizedBox(width: AppDimensions.spaceM),
                  Expanded(child: _buildShareButton(context)),
                  const SizedBox(width: AppDimensions.spaceM),
                  Expanded(child: _buildHomeButton(context)),
                ],
              ),
      ],
    );
  }

  Widget _buildDownloadButton(BuildContext context) {
    return PremiumButton.outline(
      label: 'Preuzmi PDF',
      icon: Icons.download_outlined,
      isFullWidth: true,
      onPressed: () {
        // Download confirmation PDF
      },
    );
  }

  Widget _buildShareButton(BuildContext context) {
    return PremiumButton.outline(
      label: 'Podijeli',
      icon: Icons.share_outlined,
      isFullWidth: true,
      onPressed: () {
        // Share booking details
      },
    );
  }

  Widget _buildHomeButton(BuildContext context) {
    return PremiumButton.text(
      label: 'Nazad na početnu',
      icon: Icons.home_outlined,
      isFullWidth: true,
      onPressed: () => context.goToHome(),
    );
  }
}
