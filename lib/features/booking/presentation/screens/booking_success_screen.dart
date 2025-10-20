import 'package:flutter/material.dart';
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
class BookingSuccessScreen extends StatefulWidget {
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
    this.currencySymbol = '\$',
    required this.confirmationEmail,
  });

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
                _buildSuccessAnimation(),

                const SizedBox(height: AppDimensions.spaceXL),

                // Success message
                _buildSuccessMessage(),

                const SizedBox(height: AppDimensions.spaceXXL),

                // Booking reference
                _buildBookingReference(),

                const SizedBox(height: AppDimensions.spaceXL),

                // Confirmation email sent
                _buildEmailConfirmation(),

                const SizedBox(height: AppDimensions.spaceXXL),

                // Booking summary
                BookingSummaryCard(
                  propertyName: widget.propertyName,
                  propertyImage: widget.propertyImage,
                  propertyLocation: widget.propertyLocation,
                  checkIn: widget.checkIn,
                  checkOut: widget.checkOut,
                  guests: widget.guests,
                  nights: widget.nights,
                  pricePerNight: widget.totalAmount / widget.nights,
                  serviceFee: 0,
                  cleaningFee: 0,
                  currencySymbol: widget.currencySymbol,
                  compact: context.isMobile,
                ),

                const SizedBox(height: AppDimensions.spaceXXL),

                // Action buttons
                _buildActionButtons(),

                const SizedBox(height: AppDimensions.spaceXL),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
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
      ),
    );
  }

  Widget _buildSuccessMessage() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Text(
            'Booking Confirmed!',
            style: context.isMobile ? AppTypography.h2 : AppTypography.h1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            'Your reservation has been successfully confirmed',
            style: AppTypography.bodyLarge.copyWith(
              color: context.textColorSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingReference() {
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
            'Booking Reference',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.withOpacity(context.textColorInverted, AppColors.opacity90),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceS),
          Text(
            widget.bookingReference,
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

  Widget _buildEmailConfirmation() {
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
                  'Confirmation Email Sent',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: AppTypography.weightSemibold,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXXS),
                Text(
                  'Check ${widget.confirmationEmail} for booking details',
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

  Widget _buildActionButtons() {
    return Column(
      children: [
        // View booking details
        PremiumButton.primary(
          label: 'View Booking Details',
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
                  _buildDownloadButton(),
                  const SizedBox(height: AppDimensions.spaceM),
                  _buildShareButton(),
                  const SizedBox(height: AppDimensions.spaceM),
                  _buildHomeButton(),
                ],
              )
            : Row(
                children: [
                  Expanded(child: _buildDownloadButton()),
                  const SizedBox(width: AppDimensions.spaceM),
                  Expanded(child: _buildShareButton()),
                  const SizedBox(width: AppDimensions.spaceM),
                  Expanded(child: _buildHomeButton()),
                ],
              ),
      ],
    );
  }

  Widget _buildDownloadButton() {
    return PremiumButton.outline(
      label: 'Download PDF',
      icon: Icons.download_outlined,
      isFullWidth: true,
      onPressed: () {
        // Download confirmation PDF
      },
    );
  }

  Widget _buildShareButton() {
    return PremiumButton.outline(
      label: 'Share',
      icon: Icons.share_outlined,
      isFullWidth: true,
      onPressed: () {
        // Share booking details
      },
    );
  }

  Widget _buildHomeButton() {
    return PremiumButton.text(
      label: 'Back to Home',
      icon: Icons.home_outlined,
      isFullWidth: true,
      onPressed: () => context.goToHome(),
    );
  }
}
