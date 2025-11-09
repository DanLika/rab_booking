import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/constants/app_dimensions.dart';

/// Premium avatar component with multiple variants and states
/// Features: Network images, initials, icons, status indicators, borders
class PremiumAvatar extends StatelessWidget {
  /// Avatar image URL
  final String? imageUrl;

  /// Avatar initials (if no image)
  final String? initials;

  /// Avatar icon (if no image or initials)
  final IconData? icon;

  /// Avatar size
  final AvatarSize size;

  /// Custom radius (overrides size)
  final double? radius;

  /// Background color (for initials/icon)
  final Color? backgroundColor;

  /// Text/Icon color
  final Color? foregroundColor;

  /// Show border
  final bool showBorder;

  /// Border color
  final Color? borderColor;

  /// Border width
  final double borderWidth;

  /// Show status indicator
  final bool showStatus;

  /// Status color
  final Color? statusColor;

  /// Enable shadow
  final bool enableShadow;

  /// On tap callback
  final VoidCallback? onTap;

  const PremiumAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.icon,
    this.size = AvatarSize.medium,
    this.radius,
    this.backgroundColor,
    this.foregroundColor,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2.0,
    this.showStatus = false,
    this.statusColor,
    this.enableShadow = false,
    this.onTap,
  });

  /// Small avatar (32px)
  factory PremiumAvatar.small({
    String? imageUrl,
    String? initials,
    IconData? icon,
    Color? backgroundColor,
    Color? foregroundColor,
    bool showBorder = false,
    bool showStatus = false,
    Color? statusColor,
    VoidCallback? onTap,
  }) {
    return PremiumAvatar(
      imageUrl: imageUrl,
      initials: initials,
      icon: icon,
      size: AvatarSize.small,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      showBorder: showBorder,
      showStatus: showStatus,
      statusColor: statusColor,
      onTap: onTap,
    );
  }

  /// Medium avatar (48px)
  factory PremiumAvatar.medium({
    String? imageUrl,
    String? initials,
    IconData? icon,
    Color? backgroundColor,
    Color? foregroundColor,
    bool showBorder = false,
    bool showStatus = false,
    Color? statusColor,
    VoidCallback? onTap,
  }) {
    return PremiumAvatar(
      imageUrl: imageUrl,
      initials: initials,
      icon: icon,
      size: AvatarSize.medium,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      showBorder: showBorder,
      showStatus: showStatus,
      statusColor: statusColor,
      onTap: onTap,
    );
  }

  /// Large avatar (64px)
  factory PremiumAvatar.large({
    String? imageUrl,
    String? initials,
    IconData? icon,
    Color? backgroundColor,
    Color? foregroundColor,
    bool showBorder = false,
    bool showStatus = false,
    Color? statusColor,
    VoidCallback? onTap,
  }) {
    return PremiumAvatar(
      imageUrl: imageUrl,
      initials: initials,
      icon: icon,
      size: AvatarSize.large,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      showBorder: showBorder,
      showStatus: showStatus,
      statusColor: statusColor,
      onTap: onTap,
    );
  }

  /// Extra large avatar (96px)
  factory PremiumAvatar.extraLarge({
    String? imageUrl,
    String? initials,
    IconData? icon,
    Color? backgroundColor,
    Color? foregroundColor,
    bool showBorder = false,
    bool showStatus = false,
    Color? statusColor,
    VoidCallback? onTap,
  }) {
    return PremiumAvatar(
      imageUrl: imageUrl,
      initials: initials,
      icon: icon,
      size: AvatarSize.extraLarge,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      showBorder: showBorder,
      showStatus: showStatus,
      statusColor: statusColor,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveRadius = radius ?? _getRadiusForSize(size);
    final effectiveBackgroundColor = backgroundColor ??
        (isDark ? AppColors.surfaceVariantDark : AppColors.authPrimary);
    final effectiveForegroundColor = foregroundColor ??
        (backgroundColor != null
            ? Colors.white
            : (isDark ? AppColors.textPrimaryDark : Colors.white));

    Widget avatar = Container(
      width: effectiveRadius * 2,
      height: effectiveRadius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: effectiveBackgroundColor,
        border: showBorder
            ? Border.all(
                color: borderColor ??
                    (isDark ? AppColors.surfaceDark : Colors.white),
                width: borderWidth,
              )
            : null,
        boxShadow: enableShadow ? AppShadows.elevation2 : null,
      ),
      child: ClipOval(
        child: _buildAvatarContent(isDark, effectiveRadius, effectiveForegroundColor),
      ),
    );

    // Add status indicator if enabled
    if (showStatus) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: effectiveRadius * 0.35,
              height: effectiveRadius * 0.35,
              decoration: BoxDecoration(
                color: statusColor ?? AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Add tap handler if provided
    if (onTap != null) {
      avatar = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: avatar,
      );
    }

    return avatar;
  }

  Widget _buildAvatarContent(bool isDark, double radius, Color foregroundColor) {
    // Image avatar
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
          child: Center(
            child: SizedBox(
              width: radius * 0.5,
              height: radius * 0.5,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.authPrimary),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildFallbackContent(radius, foregroundColor),
      );
    }

    return _buildFallbackContent(radius, foregroundColor);
  }

  Widget _buildFallbackContent(double radius, Color foregroundColor) {
    // Initials avatar
    if (initials != null && initials!.isNotEmpty) {
      return Center(
        child: Text(
          initials!.substring(0, initials!.length > 2 ? 2 : initials!.length).toUpperCase(),
          style: _getTextStyleForSize(size).copyWith(
            color: foregroundColor,
            fontWeight: AppTypography.weightSemibold,
          ),
        ),
      );
    }

    // Icon avatar
    return Center(
      child: Icon(
        icon ?? Icons.person,
        size: _getIconSizeForSize(size),
        color: foregroundColor,
      ),
    );
  }

  double _getRadiusForSize(AvatarSize size) {
    switch (size) {
      case AvatarSize.small:
        return AppDimensions.avatarSizeS / 2;
      case AvatarSize.medium:
        return AppDimensions.avatarSizeM / 2;
      case AvatarSize.large:
        return AppDimensions.avatarSizeL / 2;
      case AvatarSize.extraLarge:
        return AppDimensions.avatarSizeXL / 2;
    }
  }

  TextStyle _getTextStyleForSize(AvatarSize size) {
    switch (size) {
      case AvatarSize.small:
        return AppTypography.small;
      case AvatarSize.medium:
        return AppTypography.bodyMedium;
      case AvatarSize.large:
        return AppTypography.bodyLarge;
      case AvatarSize.extraLarge:
        return AppTypography.h3;
    }
  }

  double _getIconSizeForSize(AvatarSize size) {
    switch (size) {
      case AvatarSize.small:
        return AppDimensions.iconS;
      case AvatarSize.medium:
        return AppDimensions.iconM;
      case AvatarSize.large:
        return AppDimensions.iconL;
      case AvatarSize.extraLarge:
        return AppDimensions.iconXL;
    }
  }
}

/// Avatar size enum
enum AvatarSize {
  /// Small avatar (32px)
  small,

  /// Medium avatar (48px)
  medium,

  /// Large avatar (64px)
  large,

  /// Extra large avatar (96px)
  extraLarge,
}

/// Avatar group widget - displays multiple avatars in a row
class PremiumAvatarGroup extends StatelessWidget {
  /// List of avatar image URLs
  final List<String> imageUrls;

  /// Avatar size
  final AvatarSize size;

  /// Maximum avatars to show (rest will be shown as +N)
  final int maxAvatars;

  /// Overlap amount (negative spacing)
  final double overlap;

  const PremiumAvatarGroup({
    super.key,
    required this.imageUrls,
    this.size = AvatarSize.small,
    this.maxAvatars = 4,
    this.overlap = 8,
  });

  @override
  Widget build(BuildContext context) {
    final visibleAvatars = imageUrls.take(maxAvatars).toList();
    final remainingCount = imageUrls.length - visibleAvatars.length;

    return SizedBox(
      height: _getHeightForSize(size),
      child: Stack(
        children: [
          ...visibleAvatars.asMap().entries.map(
                (entry) => Positioned(
                  left: entry.key * (_getHeightForSize(size) - overlap),
                  child: PremiumAvatar(
                    imageUrl: entry.value,
                    size: size,
                    showBorder: true,
                  ),
                ),
              ),
          if (remainingCount > 0)
            Positioned(
              left: visibleAvatars.length * (_getHeightForSize(size) - overlap),
              child: PremiumAvatar(
                initials: '+$remainingCount',
                size: size,
                showBorder: true,
                backgroundColor: AppColors.surfaceVariantLight,
                foregroundColor: AppColors.textPrimaryLight,
              ),
            ),
        ],
      ),
    );
  }

  double _getHeightForSize(AvatarSize size) {
    switch (size) {
      case AvatarSize.small:
        return AppDimensions.avatarSizeS;
      case AvatarSize.medium:
        return AppDimensions.avatarSizeM;
      case AvatarSize.large:
        return AppDimensions.avatarSizeL;
      case AvatarSize.extraLarge:
        return AppDimensions.avatarSizeXL;
    }
  }
}
