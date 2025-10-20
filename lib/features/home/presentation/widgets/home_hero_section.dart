import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_animations.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/responsive_builder.dart';
import '../../../../shared/widgets/widgets.dart';

/// Premium hero section for home screen
/// Features: Full-width gradient background, search interface, inspiring copy
class HomeHeroSection extends StatelessWidget {
  /// Hero title
  final String title;

  /// Hero subtitle
  final String subtitle;

  /// Hero background image (optional)
  final String? backgroundImage;

  /// On search pressed callback
  final VoidCallback? onSearchPressed;

  /// Show search bar
  final bool showSearch;

  const HomeHeroSection({
    super.key,
    this.title = 'Find Your Perfect Vacation Rental',
    this.subtitle = 'Discover amazing properties for your next getaway',
    this.backgroundImage,
    this.onSearchPressed,
    this.showSearch = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: context.isMobile ? 500 : 600,
      ),
      decoration: _buildDecoration(isDark),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          // Background image with premium overlay
          if (backgroundImage != null)
            Positioned.fill(
              child: PremiumImage(
                imageUrl: backgroundImage,
                fit: BoxFit.cover,
                enableOverlay: true,
                overlayGradient: AppColors.premiumOverlayGradient,
              ),
            ),

          // Content
          SafeArea(
            child: MaxWidthContainer(
              maxWidth: AppDimensions.containerXL,
              padding: EdgeInsets.symmetric(
                horizontal: context.horizontalPadding,
                vertical: context.isMobile
                    ? AppDimensions.spaceXXL
                    : AppDimensions.sectionPaddingVerticalDesktop,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                    // Title
                    _buildTitle(context, isDark),

                    const SizedBox(height: AppDimensions.spaceM),

                    // Subtitle
                    _buildSubtitle(context, isDark),

                    if (showSearch) ...[
                      SizedBox(
                        height: context.isMobile
                            ? AppDimensions.spaceXL
                            : AppDimensions.spaceXXL,
                      ),

                      // Search widget
                      _buildSearchWidget(context, isDark),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  BoxDecoration _buildDecoration(bool isDark) {
    if (backgroundImage != null) {
      return const BoxDecoration();
    }

    return const BoxDecoration(
      gradient: AppColors.heroGradient,
    );
  }

  Widget _buildTitle(BuildContext context, bool isDark) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: AppAnimations.fadeIn.duration,
      curve: AppAnimations.fadeIn.curve,
      child: Text(
        title,
        style: context.isMobile
            ? AppTypography.h1.copyWith(
                color: backgroundImage != null ? Colors.white : Colors.white,
                fontWeight: AppTypography.weightBold,
              )
            : AppTypography.heroTitle.copyWith(
                color: backgroundImage != null ? Colors.white : Colors.white,
                fontWeight: AppTypography.weightBold,
              ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context, bool isDark) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: AppAnimations.fadeIn.duration,
      curve: AppAnimations.fadeIn.curve,
      child: Text(
        subtitle,
        style: context.isMobile
            ? AppTypography.bodyLarge.copyWith(
                color: backgroundImage != null
                    ? AppColors.withOpacity(Colors.white, AppColors.opacity90)
                    : AppColors.withOpacity(Colors.white, AppColors.opacity90),
              )
            : AppTypography.heroSubtitle.copyWith(
                color: backgroundImage != null
                    ? AppColors.withOpacity(Colors.white, AppColors.opacity90)
                    : AppColors.withOpacity(Colors.white, AppColors.opacity90),
              ),
        textAlign: TextAlign.center,
        maxLines: 2,
      ),
    );
  }

  Widget _buildSearchWidget(BuildContext context, bool isDark) {
    return MaxWidthContainer(
      maxWidth: AppDimensions.containerM,
      child: PremiumCard.glass(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spaceM),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Location search
              const PremiumTextField(
                label: 'Where are you going?',
                hint: 'Search destinations',
                prefixIcon: Icons.location_on_outlined,
                variant: TextFieldVariant.filled,
              ),

              if (!context.isMobile) ...[
                const SizedBox(height: AppDimensions.spaceM),

                // Date range and guests in row on desktop
                Row(
                  children: [
                    const Expanded(
                      child: PremiumDatePicker(
                        label: 'Check-in',
                        hint: 'Add date',
                        prefixIcon: Icons.calendar_today_outlined,
                        variant: TextFieldVariant.filled,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceM),
                    const Expanded(
                      child: PremiumDatePicker(
                        label: 'Check-out',
                        hint: 'Add date',
                        prefixIcon: Icons.calendar_today_outlined,
                        variant: TextFieldVariant.filled,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceM),
                    Expanded(
                      child: PremiumDropdown<int>(
                        label: 'Guests',
                        hint: 'Add guests',
                        items: List.generate(
                          10,
                          (index) => DropdownMenuItem(
                            value: index + 1,
                            child: Text('${index + 1} guest${index > 0 ? 's' : ''}'),
                          ),
                        ),
                        prefixIcon: Icons.person_outline,
                        variant: TextFieldVariant.filled,
                      ),
                    ),
                  ],
                ),
              ],

              if (context.isMobile) ...[
                const SizedBox(height: AppDimensions.spaceM),
                const PremiumDatePicker(
                  label: 'Check-in',
                  hint: 'Add date',
                  prefixIcon: Icons.calendar_today_outlined,
                  variant: TextFieldVariant.filled,
                ),
                const SizedBox(height: AppDimensions.spaceM),
                const PremiumDatePicker(
                  label: 'Check-out',
                  hint: 'Add date',
                  prefixIcon: Icons.calendar_today_outlined,
                  variant: TextFieldVariant.filled,
                ),
                const SizedBox(height: AppDimensions.spaceM),
                PremiumDropdown<int>(
                  label: 'Guests',
                  hint: 'Add guests',
                  items: List.generate(
                    10,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('${index + 1} guest${index > 0 ? 's' : ''}'),
                    ),
                  ),
                  prefixIcon: Icons.person_outline,
                  variant: TextFieldVariant.filled,
                ),
              ],

              const SizedBox(height: AppDimensions.spaceL),

              // Search button
              PremiumButton.primary(
                label: 'Search',
                icon: Icons.search,
                onPressed: onSearchPressed ?? () {},
                isFullWidth: true,
                size: ButtonSize.large,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
