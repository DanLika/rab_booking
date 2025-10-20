import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../../../../shared/widgets/widgets.dart';

/// Call-to-action section for home screen
/// Features: Gradient background, compelling headline, action buttons
class CtaSection extends StatelessWidget {
  /// CTA headline
  final String headline;

  /// CTA description
  final String? description;

  /// Primary action button label
  final String primaryButtonLabel;

  /// Primary action button icon
  final IconData? primaryButtonIcon;

  /// Primary action callback
  final VoidCallback? onPrimaryPressed;

  /// Secondary action button label
  final String? secondaryButtonLabel;

  /// Secondary action button icon
  final IconData? secondaryButtonIcon;

  /// Secondary action callback
  final VoidCallback? onSecondaryPressed;

  /// Show secondary button
  final bool showSecondaryButton;

  /// Background gradient
  final Gradient? gradient;

  /// Background image URL
  final String? backgroundImage;

  /// CTA variant
  final CtaVariant variant;

  const CtaSection({
    super.key,
    required this.headline,
    this.description,
    this.primaryButtonLabel = 'Get Started',
    this.primaryButtonIcon,
    this.onPrimaryPressed,
    this.secondaryButtonLabel,
    this.secondaryButtonIcon,
    this.onSecondaryPressed,
    this.showSecondaryButton = false,
    this.gradient,
    this.backgroundImage,
    this.variant = CtaVariant.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: context.sectionSpacing,
      ),
      child: MaxWidthContainer(
        maxWidth: AppDimensions.containerXL,
        padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (variant) {
      case CtaVariant.gradient:
        return _buildGradientVariant(context);
      case CtaVariant.outlined:
        return _buildOutlinedVariant(context);
      case CtaVariant.elevated:
        return _buildElevatedVariant(context);
      case CtaVariant.image:
        return _buildImageVariant(context);
    }
  }

  Widget _buildGradientVariant(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        boxShadow: AppShadows.glowPrimary,
      ),
      padding: EdgeInsets.all(
        context.isMobile ? AppDimensions.spaceXL : AppDimensions.spaceXXL * 2,
      ),
      child: _buildContentBody(context, isDark: true),
    );
  }

  Widget _buildOutlinedVariant(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.primary,
          width: AppDimensions.borderWidthFocus,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      ),
      padding: EdgeInsets.all(
        context.isMobile ? AppDimensions.spaceXL : AppDimensions.spaceXXL * 2,
      ),
      child: _buildContentBody(context, isDark: isDark),
    );
  }

  Widget _buildElevatedVariant(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        boxShadow: AppShadows.elevation4,
      ),
      padding: EdgeInsets.all(
        context.isMobile ? AppDimensions.spaceXL : AppDimensions.spaceXXL * 2,
      ),
      child: _buildContentBody(context, isDark: isDark),
    );
  }

  Widget _buildImageVariant(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        boxShadow: AppShadows.elevation4,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        child: Stack(
          children: [
            // Background image
            if (backgroundImage != null)
              Positioned.fill(
                child: PremiumImage(
                  imageUrl: backgroundImage!,
                  fit: BoxFit.cover,
                  enableOverlay: true,
                  overlayGradient: LinearGradient(
                    colors: [
                      AppColors.withOpacity(Colors.black, AppColors.opacity60),
                      AppColors.withOpacity(Colors.black, AppColors.opacity80),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

            // Content
            Padding(
              padding: EdgeInsets.all(
                context.isMobile
                    ? AppDimensions.spaceXL
                    : AppDimensions.spaceXXL * 2,
              ),
              child: _buildContentBody(context, isDark: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentBody(BuildContext context, {required bool isDark}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Headline
        Text(
          headline,
          style: context.isMobile
              ? AppTypography.h2.copyWith(
                  color: isDark ? context.colorScheme.surface : null,
                )
              : AppTypography.h1.copyWith(
                  color: isDark ? context.colorScheme.surface : null,
                ),
          textAlign: TextAlign.center,
        ),

        // Description
        if (description != null) ...[
          const SizedBox(height: AppDimensions.spaceM),
          Text(
            description!,
            style: AppTypography.bodyLarge.copyWith(
              color: isDark
                  ? AppColors.withOpacity(context.colorScheme.surface, AppColors.opacity90)
                  : AppColors.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        SizedBox(
          height: context.isMobile ? AppDimensions.spaceL : AppDimensions.spaceXL,
        ),

        // Action buttons
        _buildActionButtons(context, isDark: isDark),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, {required bool isDark}) {
    if (context.isMobile) {
      // Stack buttons vertically on mobile
      return Column(
        children: [
          // Primary button
          PremiumButton(
            label: primaryButtonLabel,
            icon: primaryButtonIcon,
            onPressed: onPrimaryPressed ?? () {},
            isFullWidth: true,
            size: ButtonSize.large,
            backgroundColor: isDark ? context.colorScheme.surface : null,
            textColor: isDark ? AppColors.primary : null,
          ),

          // Secondary button
          if (showSecondaryButton && secondaryButtonLabel != null) ...[
            const SizedBox(height: AppDimensions.spaceM),
            PremiumButton.outline(
              label: secondaryButtonLabel!,
              icon: secondaryButtonIcon,
              onPressed: onSecondaryPressed ?? () {},
              isFullWidth: true,
              size: ButtonSize.large,
            ),
          ],
        ],
      );
    }

    // Horizontal buttons on tablet/desktop
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Primary button
        Flexible(
          child: PremiumButton(
            label: primaryButtonLabel,
            icon: primaryButtonIcon,
            onPressed: onPrimaryPressed ?? () {},
            size: ButtonSize.large,
            backgroundColor: isDark ? context.colorScheme.surface : null,
            textColor: isDark ? AppColors.primary : null,
          ),
        ),

        // Secondary button
        if (showSecondaryButton && secondaryButtonLabel != null) ...[
          const SizedBox(width: AppDimensions.spaceM),
          Flexible(
            child: PremiumButton.outline(
              label: secondaryButtonLabel!,
              icon: secondaryButtonIcon,
              onPressed: onSecondaryPressed ?? () {},
              size: ButtonSize.large,
            ),
          ),
        ],
      ],
    );
  }
}

/// CTA variant enum
enum CtaVariant {
  /// Gradient background
  gradient,

  /// Outlined border
  outlined,

  /// Elevated card
  elevated,

  /// Background image
  image,
}

/// Pre-configured CTA sections for common use cases
class CtaSectionPresets {
  CtaSectionPresets._(); // Private constructor

  /// Get started CTA
  static CtaSection getStarted({
    VoidCallback? onGetStarted,
    VoidCallback? onLearnMore,
  }) {
    return CtaSection(
      headline: 'Ready to Find Your Perfect Getaway?',
      description:
          'Browse thousands of premium vacation rentals and book your dream stay with confidence.',
      primaryButtonLabel: 'Start Exploring',
      primaryButtonIcon: Icons.explore,
      onPrimaryPressed: onGetStarted,
      secondaryButtonLabel: 'Learn More',
      secondaryButtonIcon: Icons.info_outline,
      onSecondaryPressed: onLearnMore,
      showSecondaryButton: true,
      variant: CtaVariant.gradient,
    );
  }

  /// List your property CTA
  static CtaSection listProperty({
    VoidCallback? onListProperty,
    VoidCallback? onContactUs,
  }) {
    return CtaSection(
      headline: 'Become a Host Today',
      description:
          'Share your property with travelers from around the world and start earning.',
      primaryButtonLabel: 'List Your Property',
      primaryButtonIcon: Icons.home,
      onPrimaryPressed: onListProperty,
      secondaryButtonLabel: 'Contact Us',
      secondaryButtonIcon: Icons.email_outlined,
      onSecondaryPressed: onContactUs,
      showSecondaryButton: true,
      variant: CtaVariant.gradient,
      gradient: AppColors.secondaryGradient,
    );
  }

  /// Subscribe to newsletter CTA
  static CtaSection newsletter({
    VoidCallback? onSubscribe,
  }) {
    return CtaSection(
      headline: 'Get Exclusive Travel Deals',
      description:
          'Subscribe to our newsletter and receive special offers, travel tips, and featured properties.',
      primaryButtonLabel: 'Subscribe Now',
      primaryButtonIcon: Icons.mail_outline,
      onPrimaryPressed: onSubscribe,
      variant: CtaVariant.outlined,
    );
  }

  /// Download app CTA
  static CtaSection downloadApp({
    VoidCallback? onDownloadIOS,
    VoidCallback? onDownloadAndroid,
  }) {
    return CtaSection(
      headline: 'Book on the Go',
      description:
          'Download our mobile app for the best booking experience wherever you are.',
      primaryButtonLabel: 'Download for iOS',
      primaryButtonIcon: Icons.apple,
      onPrimaryPressed: onDownloadIOS,
      secondaryButtonLabel: 'Download for Android',
      secondaryButtonIcon: Icons.android,
      onSecondaryPressed: onDownloadAndroid,
      showSecondaryButton: true,
      variant: CtaVariant.elevated,
    );
  }

  /// Premium membership CTA
  static CtaSection premiumMembership({
    VoidCallback? onUpgrade,
    VoidCallback? onViewBenefits,
  }) {
    return CtaSection(
      headline: 'Unlock Premium Benefits',
      description:
          'Get access to exclusive properties, priority support, and special discounts.',
      primaryButtonLabel: 'Upgrade to Premium',
      primaryButtonIcon: Icons.star,
      onPrimaryPressed: onUpgrade,
      secondaryButtonLabel: 'View Benefits',
      secondaryButtonIcon: Icons.info_outline,
      onSecondaryPressed: onViewBenefits,
      showSecondaryButton: true,
      variant: CtaVariant.gradient,
      gradient: const LinearGradient(
        colors: [
          AppColors.primary,
          AppColors.secondary,
          Color(0xFFD4AF37), // Gold
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  /// Image background CTA
  static CtaSection withBackgroundImage({
    required String headline,
    required String description,
    required String imageUrl,
    String primaryButtonLabel = 'Get Started',
    IconData? primaryButtonIcon,
    VoidCallback? onPrimaryPressed,
    String? secondaryButtonLabel,
    IconData? secondaryButtonIcon,
    VoidCallback? onSecondaryPressed,
  }) {
    return CtaSection(
      headline: headline,
      description: description,
      primaryButtonLabel: primaryButtonLabel,
      primaryButtonIcon: primaryButtonIcon,
      onPrimaryPressed: onPrimaryPressed,
      secondaryButtonLabel: secondaryButtonLabel,
      secondaryButtonIcon: secondaryButtonIcon,
      onSecondaryPressed: onSecondaryPressed,
      showSecondaryButton: secondaryButtonLabel != null,
      variant: CtaVariant.image,
      backgroundImage: imageUrl,
    );
  }
}
