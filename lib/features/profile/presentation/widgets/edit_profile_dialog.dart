import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/widgets.dart';

/// Premium edit profile dialog
/// Features: Form validation, avatar upload, animated entrance, responsive layout
class PremiumEditProfileDialog extends ConsumerStatefulWidget {
  /// Current user
  final UserModel user;

  /// On save callback
  final Future<void> Function({
    String? fullName,
    String? phone,
    String? avatarUrl,
  }) onSave;

  /// On avatar upload callback
  final Future<String?> Function()? onAvatarUpload;

  const PremiumEditProfileDialog({
    super.key,
    required this.user,
    required this.onSave,
    this.onAvatarUpload,
  });

  @override
  ConsumerState<PremiumEditProfileDialog> createState() =>
      _PremiumEditProfileDialogState();
}

class _PremiumEditProfileDialogState
    extends ConsumerState<PremiumEditProfileDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _newAvatarUrl;
  bool _isLoading = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();

    // Initialize form controllers
    _fullNameController.text = widget.user.fullName;
    _phoneController.text = widget.user.phone ?? '';

    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
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
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleAvatarUpload() async {
    if (widget.onAvatarUpload == null) return;

    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final avatarUrl = await widget.onAvatarUpload!();
      if (avatarUrl != null && mounted) {
        setState(() {
          _newAvatarUrl = avatarUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload avatar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onSave(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
        avatarUrl: _newAvatarUrl,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = context.isMobile;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? AppDimensions.spaceM : AppDimensions.spaceXL,
            vertical: isMobile ? AppDimensions.spaceXL : AppDimensions.spaceXXL,
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? double.infinity : 600,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
              boxShadow: AppShadows.elevation4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(isDark),
                Flexible(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(
                      isMobile ? AppDimensions.spaceL : AppDimensions.spaceXL,
                    ),
                    child: _buildForm(isDark, isMobile),
                  ),
                ),
                _buildActions(isDark, isMobile),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceL),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppDimensions.radiusXL),
          topRight: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.edit_outlined,
            color: Colors.white,
            size: AppDimensions.iconL,
          ),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(
            child: Text(
              'Edit Profile',
              style: AppTypography.h2.copyWith(
                color: Colors.white,
                fontWeight: AppTypography.weightBold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildForm(bool isDark, bool isMobile) {
    final currentAvatarUrl = _newAvatarUrl ?? widget.user.avatarUrl;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Avatar section
          Center(
            child: _buildAvatarSection(currentAvatarUrl),
          ),

          SizedBox(height: isMobile ? AppDimensions.spaceXL : AppDimensions.spaceXXL),

          // Full name field
          _buildTextField(
            controller: _fullNameController,
            label: 'Full Name',
            icon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your full name';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
            isDark: isDark,
          ),

          const SizedBox(height: AppDimensions.spaceL),

          // Phone field
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
                if (!phoneRegex.hasMatch(value.trim())) {
                  return 'Please enter a valid phone number';
                }
              }
              return null;
            },
            isDark: isDark,
          ),

          const SizedBox(height: AppDimensions.spaceL),

          // Email field (read-only)
          _buildTextField(
            controller: TextEditingController(text: widget.user.email),
            label: 'Email',
            icon: Icons.email_outlined,
            enabled: false,
            isDark: isDark,
          ),

          const SizedBox(height: AppDimensions.spaceM),

          // Email notice
          Container(
            padding: const EdgeInsets.all(AppDimensions.spaceM),
            decoration: BoxDecoration(
              color: AppColors.withOpacity(AppColors.info, AppColors.opacity10),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              border: Border.all(
                color: AppColors.withOpacity(AppColors.info, AppColors.opacity30),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: AppDimensions.iconM,
                  color: AppColors.info,
                ),
                const SizedBox(width: AppDimensions.spaceM),
                Expanded(
                  child: Text(
                    'Email cannot be changed. Contact support if you need to update your email address.',
                    style: AppTypography.small.copyWith(
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(String? avatarUrl) {
    final initials = _getInitials(widget.user.fullName);

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
                color: AppColors.withOpacity(AppColors.primary, AppColors.opacity30),
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
              color: AppColors.primary,
              width: 4,
            ),
            boxShadow: AppShadows.elevation4,
          ),
          child: ClipOval(
            child: avatarUrl != null
                ? CachedNetworkImage(
                    imageUrl: avatarUrl,
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

        // Upload button
        if (widget.onAvatarUpload != null)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _isUploadingAvatar ? null : _handleAvatarUpload,
              child: Container(
                padding: const EdgeInsets.all(AppDimensions.spaceM),
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryGradient,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.withOpacity(AppColors.primary, AppColors.opacity50),
                    width: 3,
                  ),
                  boxShadow: AppShadows.elevation4,
                ),
                child: _isUploadingAvatar
                    ? const SizedBox(
                        width: AppDimensions.iconS,
                        height: AppDimensions.iconS,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
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
            AppColors.withOpacity(AppColors.primary, AppColors.opacity30),
            AppColors.withOpacity(AppColors.primary, AppColors.opacity10),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: AppTypography.h1.copyWith(
            color: AppColors.primary,
            fontWeight: AppTypography.weightBold,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodyMedium.copyWith(
            fontWeight: AppTypography.weightSemibold,
            color: enabled
                ? null
                : AppColors.textSecondaryLight,
          ),
        ),
        const SizedBox(height: AppDimensions.spaceS),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          enabled: enabled,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary),
            filled: true,
            fillColor: enabled
                ? (isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight)
                : AppColors.withOpacity(AppColors.textSecondaryLight, AppColors.opacity10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 2,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActions(bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(
        isMobile ? AppDimensions.spaceL : AppDimensions.spaceXL,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceVariantDark
            : AppColors.surfaceVariantLight,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppDimensions.radiusXL),
          bottomRight: Radius.circular(AppDimensions.radiusXL),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimensions.spaceL,
                ),
                side: BorderSide(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                ),
              ),
              child: Text(
                'Cancel',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: AppTypography.weightSemibold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spaceM),
          Expanded(
            flex: 2,
            child: _isLoading
                ? Container(
                    height: AppDimensions.buttonHeight,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: AppDimensions.iconM,
                        height: AppDimensions.iconM,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ),
                  )
                : PremiumButton.primary(
                    label: 'Save Changes',
                    icon: Icons.save_outlined,
                    onPressed: _handleSave,
                    isFullWidth: true,
                  ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }
}
