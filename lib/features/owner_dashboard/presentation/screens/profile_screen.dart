import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/config/router_owner.dart';
import '../../../../core/utils/error_display_utils.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/gradient_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/language_selection_bottom_sheet.dart';
import '../widgets/theme_selection_bottom_sheet.dart';
import '../widgets/notification_settings_bottom_sheet.dart';
import '../widgets/owner_app_drawer.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../../../shared/widgets/premium_list_tile.dart';
import '../../../../shared/widgets/logout_tile.dart';
import '../../../../shared/widgets/delete_account_dialog.dart';

/// Profile screen for owner dashboard
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;
    // OPTIMIZED: Removed watchUserProfileProvider - displayName already available in authState.userModel
    // This eliminates 1 Firestore read (profiles/{userId}) per page load
    final authState = ref.watch(enhancedAuthProvider);
    final currentLocale = ref.watch(currentLocaleProvider);
    final currentThemeMode = ref.watch(currentThemeModeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get language display name from localization
    final languageName = currentLocale.languageCode == 'hr'
        ? l10n.ownerProfileLanguageCroatian
        : l10n.ownerProfileLanguageEnglish;

    // Get theme display name
    final themeName = currentThemeMode == ThemeMode.light
        ? l10n.ownerProfileThemeLight
        : currentThemeMode == ThemeMode.dark
        ? l10n.ownerProfileThemeDark
        : l10n.ownerProfileThemeSystem;

    return Scaffold(
      drawer: const OwnerAppDrawer(currentRoute: 'profile'),
      appBar: CommonAppBar(
        title: l10n.ownerProfileTitle,
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: context.gradients.pageBackground),
        child: user == null
            ? Center(child: Text(l10n.ownerProfileNotAuthenticated))
            : Builder(
                builder: (context) {
                  // OPTIMIZED: Use authState.userModel directly instead of separate Firestore query
                  final isAnonymous = authState.isAnonymous;
                  final displayName =
                      authState.userModel?.displayName ??
                      authState.userModel?.fullName ??
                      user.displayName ??
                      (isAnonymous
                          ? l10n.ownerProfileGuestUser
                          : l10n.ownerProfileOwner);
                  final email =
                      user.email ??
                      (isAnonymous
                          ? l10n.ownerProfileAnonymousAccount
                          : l10n.ownerProfileNoEmail);
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isMobile = screenWidth < 600;

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                    child: Column(
                      children: [
                        // Compact Profile header
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isMobile ? double.infinity : 400,
                            ),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                gradient: context.gradients.brandPrimary,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: isDark
                                    ? AppShadows.elevation2Dark
                                    : AppShadows.elevation2,
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(isMobile ? 16 : 20),
                                child: Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: isDark ? 0.2 : 0.3,
                                          ),
                                          width: 3,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: isDark ? 0.3 : 0.15,
                                            ),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child:
                                          authState.userModel?.avatarUrl !=
                                                  null &&
                                              authState
                                                  .userModel!
                                                  .avatarUrl!
                                                  .isNotEmpty
                                          ? ClipOval(
                                              child: Image.network(
                                                authState.userModel!.avatarUrl!,
                                                width: isMobile ? 72 : 88,
                                                height: isMobile ? 72 : 88,
                                                fit: BoxFit.cover,
                                                loadingBuilder: (context, child, loadingProgress) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  }
                                                  return CircleAvatar(
                                                    radius: isMobile ? 36 : 44,
                                                    backgroundColor: isDark
                                                        ? AppColors.primary
                                                        : Colors.white,
                                                    child: CircularProgressIndicator(
                                                      value:
                                                          loadingProgress
                                                                  .expectedTotalBytes !=
                                                              null
                                                          ? loadingProgress
                                                                    .cumulativeBytesLoaded /
                                                                loadingProgress
                                                                    .expectedTotalBytes!
                                                          : null,
                                                      strokeWidth: 2,
                                                      color: isDark
                                                          ? Colors.white
                                                          : AppColors.primary,
                                                    ),
                                                  );
                                                },
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) {
                                                      return CircleAvatar(
                                                        radius: isMobile
                                                            ? 36
                                                            : 44,
                                                        backgroundColor: isDark
                                                            ? AppColors.primary
                                                            : Colors.white,
                                                        child: Text(
                                                          displayName.isNotEmpty
                                                              ? displayName
                                                                    .substring(
                                                                      0,
                                                                      1,
                                                                    )
                                                                    .toUpperCase()
                                                              : '?',
                                                          style: TextStyle(
                                                            fontSize: isMobile
                                                                ? 28
                                                                : 34,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            color: isDark
                                                                ? Colors.white
                                                                : AppColors
                                                                      .primary,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                              ),
                                            )
                                          : CircleAvatar(
                                              radius: isMobile ? 36 : 44,
                                              backgroundColor: isDark
                                                  ? AppColors.primary
                                                  : Colors.white,
                                              child: Text(
                                                displayName.isNotEmpty
                                                    ? displayName
                                                          .substring(0, 1)
                                                          .toUpperCase()
                                                    : '?',
                                                style: TextStyle(
                                                  fontSize: isMobile ? 28 : 34,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? Colors.white
                                                      : AppColors.primary,
                                                ),
                                              ),
                                            ),
                                    ),
                                    SizedBox(height: isMobile ? 12 : 14),
                                    ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: isMobile
                                            ? double.infinity
                                            : 400,
                                      ),
                                      child: Text(
                                        displayName,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: isMobile ? 20 : 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: isDark ? 0.15 : 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: isMobile ? 12 : 13,
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Account settings
                        Container(
                          decoration: BoxDecoration(
                            color: context.gradients.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.gradients.sectionBorder.withAlpha(
                                (0.5 * 255).toInt(),
                              ),
                            ),
                            boxShadow: isDark
                                ? AppShadows.elevation1Dark
                                : AppShadows.elevation1,
                          ),
                          child: Column(
                            children: [
                              PremiumListTile(
                                icon: Icons.person_outline,
                                title: l10n.ownerProfileEditProfile,
                                subtitle: isAnonymous
                                    ? l10n.ownerProfileEditProfileSubtitleAnonymous
                                    : l10n.ownerProfileEditProfileSubtitle,
                                onTap: isAnonymous
                                    ? null
                                    : () =>
                                          context.push(OwnerRoutes.profileEdit),
                              ),
                              if (!isAnonymous) ...[
                                Divider(
                                  height: 1,
                                  indent: 72,
                                  color: theme.dividerColor,
                                ),
                                PremiumListTile(
                                  icon: Icons.lock_outline,
                                  title: l10n.ownerProfileChangePassword,
                                  subtitle:
                                      l10n.ownerProfileChangePasswordSubtitle,
                                  onTap: () => context.push(
                                    OwnerRoutes.profileChangePassword,
                                  ),
                                ),
                              ],
                              Divider(
                                height: 1,
                                indent: 72,
                                color: theme.dividerColor,
                              ),
                              PremiumListTile(
                                icon: Icons.notifications_outlined,
                                title: l10n.ownerProfileNotificationSettings,
                                subtitle: l10n
                                    .ownerProfileNotificationSettingsSubtitle,
                                onTap: () =>
                                    showNotificationSettingsBottomSheet(
                                      context,
                                      ref,
                                    ),
                              ),
                              // Subscription tile - conditionally hidden by admin
                              if (authState.userModel?.hideSubscription !=
                                  true) ...[
                                Divider(
                                  height: 1,
                                  indent: 72,
                                  color: theme.dividerColor,
                                ),
                                PremiumListTile(
                                  icon: Icons.workspace_premium,
                                  title: l10n.ownerDrawerSubscription,
                                  subtitle: l10n.profileSubscriptionSubtitle,
                                  onTap: () =>
                                      context.push(OwnerRoutes.subscription),
                                  isLast: true,
                                ),
                              ] else ...[
                                // Close the container without subscription
                                const SizedBox.shrink(),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // App settings
                        Container(
                          decoration: BoxDecoration(
                            color: context.gradients.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.gradients.sectionBorder.withAlpha(
                                (0.5 * 255).toInt(),
                              ),
                            ),
                            boxShadow: isDark
                                ? AppShadows.elevation1Dark
                                : AppShadows.elevation1,
                          ),
                          child: Column(
                            children: [
                              PremiumListTile(
                                icon: Icons.language,
                                title: l10n.ownerProfileLanguage,
                                subtitle: languageName,
                                onTap: () => showLanguageSelectionBottomSheet(
                                  context,
                                  ref,
                                ),
                              ),
                              Divider(
                                height: 1,
                                indent: 56,
                                color: theme.dividerColor,
                              ),
                              PremiumListTile(
                                icon: Icons.brightness_6_outlined,
                                title: l10n.ownerProfileTheme,
                                subtitle: themeName,
                                onTap: () =>
                                    showThemeSelectionBottomSheet(context, ref),
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Account actions
                        Container(
                          decoration: BoxDecoration(
                            color: context.gradients.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.gradients.sectionBorder.withAlpha(
                                (0.5 * 255).toInt(),
                              ),
                            ),
                            boxShadow: isDark
                                ? AppShadows.elevation1Dark
                                : AppShadows.elevation1,
                          ),
                          child: Column(
                            children: [
                              PremiumListTile(
                                icon: Icons.help_outline,
                                title: l10n.ownerProfileHelpSupport,
                                subtitle: l10n.ownerProfileHelpSupportSubtitle,
                                onTap: () {
                                  ErrorDisplayUtils.showInfoSnackBar(
                                    context,
                                    l10n.ownerProfileHelpSupportComingSoon,
                                  );
                                },
                              ),
                              Divider(
                                height: 1,
                                indent: 56,
                                color: theme.dividerColor,
                              ),
                              PremiumListTile(
                                icon: Icons.info_outline,
                                title: l10n.ownerProfileAbout,
                                subtitle: l10n.ownerProfileAboutSubtitle,
                                onTap: () => context.push(OwnerRoutes.about),
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Logout section - separate for emphasis
                        Container(
                          decoration: BoxDecoration(
                            color: context.gradients.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.gradients.sectionBorder.withAlpha(
                                (0.5 * 255).toInt(),
                              ),
                            ),
                            boxShadow: isDark
                                ? AppShadows.elevation1Dark
                                : AppShadows.elevation1,
                          ),
                          child: LogoutTile(
                            title: l10n.ownerProfileLogout,
                            subtitle: l10n.ownerProfileLogoutSubtitle,
                            onLogout: () async {
                              await ref
                                  .read(enhancedAuthProvider.notifier)
                                  .signOut();
                              if (context.mounted) {
                                context.go(OwnerRoutes.login);
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Legal Documents
                        Container(
                          decoration: BoxDecoration(
                            color: context.gradients.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.gradients.sectionBorder.withAlpha(
                                (0.5 * 255).toInt(),
                              ),
                            ),
                            boxShadow: isDark
                                ? AppShadows.elevation1Dark
                                : AppShadows.elevation1,
                          ),
                          child: Column(
                            children: [
                              PremiumListTile(
                                icon: Icons.description_outlined,
                                title: l10n.ownerProfileTermsConditions,
                                subtitle:
                                    l10n.ownerProfileTermsConditionsSubtitle,
                                onTap: () =>
                                    context.push(OwnerRoutes.termsConditions),
                              ),
                              Divider(
                                height: 1,
                                indent: 56,
                                color: theme.dividerColor,
                              ),
                              PremiumListTile(
                                icon: Icons.privacy_tip_outlined,
                                title: l10n.ownerProfilePrivacyPolicy,
                                subtitle:
                                    l10n.ownerProfilePrivacyPolicySubtitle,
                                onTap: () =>
                                    context.push(OwnerRoutes.privacyPolicy),
                              ),
                              Divider(
                                height: 1,
                                indent: 56,
                                color: theme.dividerColor,
                              ),
                              PremiumListTile(
                                icon: Icons.cookie_outlined,
                                title: l10n.ownerProfileCookiesPolicy,
                                subtitle:
                                    l10n.ownerProfileCookiesPolicySubtitle,
                                onTap: () =>
                                    context.push(OwnerRoutes.cookiesPolicy),
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Danger Zone - Delete Account (App Store requirement)
                        Container(
                          decoration: BoxDecoration(
                            color: context.gradients.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.error.withAlpha(
                                (0.3 * 255).toInt(),
                              ),
                            ),
                            boxShadow: isDark
                                ? AppShadows.elevation1Dark
                                : AppShadows.elevation1,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  8,
                                ),
                                child: Text(
                                  l10n.dangerZone,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: AppColors.error,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              PremiumListTile(
                                icon: Icons.delete_forever_outlined,
                                iconColor: AppColors.error,
                                title: l10n.deleteAccount,
                                subtitle: l10n.deleteAccountWarning,
                                onTap: () async {
                                  final result = await showDeleteAccountDialog(
                                    context,
                                  );
                                  if (result == true && context.mounted) {
                                    ErrorDisplayUtils.showInfoSnackBar(
                                      context,
                                      l10n.deleteAccountSuccess,
                                    );
                                    context.go(OwnerRoutes.login);
                                  }
                                },
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
