import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/models/user_model.dart';

/// Premium profile header widget
/// Features: Gradient background, avatar with upload, user info, role badge
class PremiumProfileHeader extends StatelessWidget {
  /// User model
  final UserModel user;

  /// On avatar tap
  final VoidCallback? onAvatarTap;

  /// On edit profile tap
  final VoidCallback? onEditTap;

  /// Show edit button
  final bool showEditButton;

  const PremiumProfileHeader({
    super.key,
    required this.user,
    this.onAvatarTap,
    this.onEditTap,
    this.showEditButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = user.fullName.isNotEmpty ? user.fullName : 'User';
    final initials = _getInitials(displayName);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        boxShadow: AppShadows.elevation4,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.all(
            context.isMobile ? AppDimensions.spaceXL : AppDimensions.spaceXXL,
          ),
          child: Column(
            children: [
              // Avatar with camera button
              _buildAvatar(initials),

              const SizedBox(height: AppDimensions.spaceL),

              // Name
              Text(
                displayName,
                style: (context.isMobile ? AppTypography.h2 : AppTypography.h1)
                    .copyWith(
                  fontWeight: AppTypography.weightBold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppDimensions.spaceXS),

              // Email
              Text(
                user.email,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.withOpacity(Colors.white, AppColors.opacity90),
                ),
                textAlign: TextAlign.center,
              ),

              if (user.phone != null) ...[
                const SizedBox(height: AppDimensions.spaceXS),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: AppDimensions.iconS,
                      color: AppColors.withOpacity(
                        Colors.white,
                        AppColors.opacity70,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.spaceXS),
                    Text(
                      user.phone!,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.withOpacity(
                          Colors.white,
                          AppColors.opacity70,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppDimensions.spaceM),

              // Role badge
              _buildRoleBadge(user.role.value),

              if (showEditButton) ...[
                const SizedBox(height: AppDimensions.spaceL),
                _buildEditButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String initials) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow effect
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.withOpacity(Colors.white, AppColors.opacity30),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
        ),

        // Avatar
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 4,
            ),
            boxShadow: AppShadows.elevation4,
          ),
          child: ClipOval(
            child: user.avatarUrl != null
                ? CachedNetworkImage(
                    imageUrl: user.avatarUrl!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.withOpacity(
                        AppColors.primary,
                        AppColors.opacity10,
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) =>
                        _buildInitialsAvatar(initials),
                  )
                : _buildInitialsAvatar(initials),
          ),
        ),

        // Camera button
        if (onAvatarTap != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onAvatarTap,
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.spaceS),
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryGradient,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: AppShadows.elevation2,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  size: AppDimensions.iconS,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInitialsAvatar(String initials) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.withOpacity(Colors.white, AppColors.opacity20),
            AppColors.withOpacity(Colors.white, AppColors.opacity10),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTypography.h1.copyWith(
            color: Colors.white,
            fontWeight: AppTypography.weightBold,
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(String role) {
    final (icon, label, color) = _getRoleInfo(role);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceM,
        vertical: AppDimensions.spaceS,
      ),
      decoration: BoxDecoration(
        color: AppColors.withOpacity(color, AppColors.opacity20),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: AppColors.withOpacity(Colors.white, AppColors.opacity30),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: AppDimensions.iconS,
            color: Colors.white,
          ),
          const SizedBox(width: AppDimensions.spaceS),
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: Colors.white,
              fontWeight: AppTypography.weightSemibold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton() {
    return OutlinedButton.icon(
      onPressed: onEditTap,
      icon: const Icon(Icons.edit_outlined, color: Colors.white),
      label: Text(
        'Edit Profile',
        style: AppTypography.bodyMedium.copyWith(
          color: Colors.white,
          fontWeight: AppTypography.weightSemibold,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: AppColors.withOpacity(Colors.white, AppColors.opacity50),
          width: 2,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceL,
          vertical: AppDimensions.spaceM,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  (IconData, String, Color) _getRoleInfo(String role) {
    switch (role.toLowerCase()) {
      case 'owner':
        return (Icons.business, 'Property Owner', AppColors.warning);
      case 'admin':
        return (Icons.admin_panel_settings, 'Administrator', AppColors.error);
      case 'guest':
      default:
        return (Icons.person, 'Guest', AppColors.success);
    }
  }
}
