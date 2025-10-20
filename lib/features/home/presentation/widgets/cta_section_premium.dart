import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/widgets.dart';

/// Premium Call-to-Action Section
/// Features:
/// - Glassmorphic background with enhanced gradients
/// - Premium button treatments with hover effects
/// - Multiple variants (gradient, outlined, elevated, image)
/// - Responsive layouts
/// - Smooth animations
class CtaSectionPremium extends StatelessWidget {
  const CtaSectionPremium({
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
    super.key,
  });

  final String headline;
  final String? description;
  final String primaryButtonLabel;
  final IconData? primaryButtonIcon;
  final VoidCallback? onPrimaryPressed;
  final String? secondaryButtonLabel;
  final IconData? secondaryButtonIcon;
  final VoidCallback? onSecondaryPressed;
  final bool showSecondaryButton;
  final Gradient? gradient;
  final String? backgroundImage;
  final CtaVariant variant;

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 0 : AppDimensions.spaceXL,
        vertical: AppDimensions.spaceXL,
      ),
      child: _buildContent(context),
    )
        .animate()
        .fadeIn(duration: 800.ms, curve: Curves.easeOut)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
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
    final isMobile = context.isMobile;

    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(
          isMobile ? 0 : AppDimensions.radiusXL,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.all(
        isMobile ? AppDimensions.spaceXL : AppDimensions.spaceXXL * 1.5,
      ),
      child: _buildContentBody(context, isDark: true),
    );
  }

  Widget _buildOutlinedVariant(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = context.isMobile;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border.all(
          color: AppColors.primary,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(
          isMobile ? 0 : AppDimensions.radiusXL,
        ),
        boxShadow: AppShadows.elevation2,
      ),
      padding: EdgeInsets.all(
        isMobile ? AppDimensions.spaceXL : AppDimensions.spaceXXL * 1.5,
      ),
      child: _buildContentBody(context, isDark: isDark),
    );
  }

  Widget _buildElevatedVariant(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = context.isMobile;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.surfaceVariantDark.withValues(alpha: 0.5),
                  AppColors.surfaceDark,
                ]
              : [
                  Colors.white,
                  AppColors.surfaceVariantLight.withValues(alpha: 0.5),
                ],
        ),
        borderRadius: BorderRadius.circular(
          isMobile ? 0 : AppDimensions.radiusXL,
        ),
        border: Border.all(
          color: isDark
              ? AppColors.borderDark.withValues(alpha: 0.3)
              : AppColors.borderLight.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: AppShadows.elevation4,
      ),
      padding: EdgeInsets.all(
        isMobile ? AppDimensions.spaceXL : AppDimensions.spaceXXL * 1.5,
      ),
      child: _buildContentBody(context, isDark: isDark),
    );
  }

  Widget _buildImageVariant(BuildContext context) {
    final isMobile = context.isMobile;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          isMobile ? 0 : AppDimensions.radiusXL,
        ),
        boxShadow: AppShadows.elevation4,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          isMobile ? 0 : AppDimensions.radiusXL,
        ),
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
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),

            // Content
            Padding(
              padding: EdgeInsets.all(
                isMobile ? AppDimensions.spaceXL : AppDimensions.spaceXXL * 1.5,
              ),
              child: _buildContentBody(context, isDark: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentBody(BuildContext context, {required bool isDark}) {
    final isMobile = context.isMobile;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Premium icon (optional, adds visual interest)
        Container(
          padding: const EdgeInsets.all(AppDimensions.spaceM),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.2)
                : AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            primaryButtonIcon ?? Icons.explore,
            color: isDark ? Colors.white : AppColors.primary,
            size: 32,
          ),
        ),

        const SizedBox(height: AppDimensions.spaceL),

        // Headline
        Text(
          headline,
          style: isMobile
              ? AppTypography.h2.copyWith(
                  color: isDark ? Colors.white : null,
                  fontWeight: FontWeight.w700,
                )
              : AppTypography.h1.copyWith(
                  color: isDark ? Colors.white : null,
                  fontWeight: FontWeight.w700,
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
                  ? Colors.white.withValues(alpha: 0.9)
                  : AppColors.textSecondaryLight,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        SizedBox(
          height: isMobile ? AppDimensions.spaceL : AppDimensions.spaceXL,
        ),

        // Action buttons
        _buildActionButtons(context, isDark: isDark),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, {required bool isDark}) {
    final isMobile = context.isMobile;

    if (isMobile) {
      return Column(
        children: [
          // Primary button
          PremiumButton(
            label: primaryButtonLabel,
            icon: primaryButtonIcon,
            onPressed: onPrimaryPressed ?? () {},
            isFullWidth: true,
            size: ButtonSize.large,
            backgroundColor: isDark ? Colors.white : null,
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

    // Desktop/Tablet - Horizontal layout
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Primary button
        PremiumButton(
          label: primaryButtonLabel,
          icon: primaryButtonIcon,
          onPressed: onPrimaryPressed ?? () {},
          size: ButtonSize.large,
          backgroundColor: isDark ? Colors.white : null,
        ),

        // Secondary button
        if (showSecondaryButton && secondaryButtonLabel != null) ...[
          const SizedBox(width: AppDimensions.spaceM),
          PremiumButton.outline(
            label: secondaryButtonLabel!,
            icon: secondaryButtonIcon,
            onPressed: onSecondaryPressed ?? () {},
            size: ButtonSize.large,
          ),
        ],
      ],
    );
  }
}

/// CTA variant enum
enum CtaVariant {
  /// Gradient background with shadow
  gradient,

  /// Outlined border with glassmorphic effect
  outlined,

  /// Elevated card with subtle gradient
  elevated,

  /// Background image with overlay
  image,
}

/// Pre-configured Premium CTA sections for common use cases
class CtaSectionPresetsPremium {
  CtaSectionPresetsPremium._(); // Private constructor

  /// Get started CTA
  static CtaSectionPremium getStarted({
    VoidCallback? onGetStarted,
    VoidCallback? onLearnMore,
  }) {
    return CtaSectionPremium(
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
  static CtaSectionPremium listProperty({
    VoidCallback? onListProperty,
    VoidCallback? onContactUs,
  }) {
    return CtaSectionPremium(
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
  static CtaSectionPremium newsletter({
    VoidCallback? onSubscribe,
  }) {
    return CtaSectionPremium(
      headline: 'Get Exclusive Travel Deals',
      description:
          'Subscribe to our newsletter and receive special offers, travel tips, and featured properties.',
      primaryButtonLabel: 'Subscribe Now',
      primaryButtonIcon: Icons.mail_outline,
      onPrimaryPressed: onSubscribe,
      variant: CtaVariant.outlined,
    );
  }

  /// Premium membership CTA
  static CtaSectionPremium premiumMembership({
    VoidCallback? onUpgrade,
    VoidCallback? onViewBenefits,
  }) {
    return CtaSectionPremium(
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
  static CtaSectionPremium withBackgroundImage({
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
    return CtaSectionPremium(
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

  /// Elevated variant CTA
  static CtaSectionPremium elevated({
    required String headline,
    String? description,
    String primaryButtonLabel = 'Get Started',
    IconData? primaryButtonIcon,
    VoidCallback? onPrimaryPressed,
    String? secondaryButtonLabel,
    IconData? secondaryButtonIcon,
    VoidCallback? onSecondaryPressed,
  }) {
    return CtaSectionPremium(
      headline: headline,
      description: description,
      primaryButtonLabel: primaryButtonLabel,
      primaryButtonIcon: primaryButtonIcon,
      onPrimaryPressed: onPrimaryPressed,
      secondaryButtonLabel: secondaryButtonLabel,
      secondaryButtonIcon: secondaryButtonIcon,
      onSecondaryPressed: onSecondaryPressed,
      showSecondaryButton: secondaryButtonLabel != null,
      variant: CtaVariant.elevated,
    );
  }
}
