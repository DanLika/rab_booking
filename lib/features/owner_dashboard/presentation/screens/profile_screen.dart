import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../shared/models/user_model.dart' show AccountType;
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
import '../providers/user_profile_provider.dart';

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
    final userDataAsync = ref.watch(userDataProvider);
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
                  // Calculate effective account type (admin override takes precedence)
                  final effectiveAccountType =
                      authState.userModel?.adminOverrideAccountType ??
                      authState.userModel?.accountType ??
                      AccountType.trial;
                  final isTrial = effectiveAccountType == AccountType.trial;
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
                                    // Profile completion widget (only for non-anonymous)
                                    if (!isAnonymous && !isMobile) ...[
                                      const SizedBox(height: 16),
                                      _ProfileCompletionWidget(
                                        percentage:
                                            userDataAsync
                                                .value
                                                ?.profile
                                                .completionPercentage ??
                                            0,
                                        isDark: isDark,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Subscription Banner (only for trial users, hidden for premium/enterprise)
                        if (authState.userModel?.hideSubscription != true &&
                            isTrial) ...[
                          _SubscriptionBanner(isDark: isDark),
                          const SizedBox(height: 12),
                        ],

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
                              // Subscription tile - show for all users unless hidden by admin
                              // Trial users see "Upgrade to Pro", paid users see "Manage Subscription"
                              if (authState.userModel?.hideSubscription !=
                                  true) ...[
                                Divider(
                                  height: 1,
                                  indent: 72,
                                  color: theme.dividerColor,
                                ),
                                PremiumListTile(
                                  icon: Icons.workspace_premium,
                                  title: isTrial
                                      ? l10n.ownerDrawerSubscription
                                      : l10n.profileManageSubscription,
                                  subtitle: isTrial
                                      ? l10n.profileSubscriptionSubtitle
                                      : l10n.profileManageSubscriptionSubtitle,
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

/// Progress widget showing profile completion percentage
class _ProfileCompletionWidget extends StatelessWidget {
  final int percentage;
  final bool isDark;

  const _ProfileCompletionWidget({
    required this.percentage,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (percentage >= 100) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);

    // Determine suggestion based on missing data
    String suggestion = l10n.ownerProfileSuggestionPhone;
    if (percentage < 40) {
      suggestion = l10n.ownerProfileSuggestionComplete;
    } else if (percentage < 60) {
      suggestion = l10n.ownerProfileSuggestionAddress;
    }

    return GestureDetector(
      onTap: () => context.push(OwnerRoutes.profileEdit),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.2 : 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.ownerProfileCompletionStatus(percentage),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withValues(alpha: 0.9),
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 14,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Subscription upgrade banner with premium gradient
class _SubscriptionBanner extends StatelessWidget {
  final bool isDark;

  const _SubscriptionBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: () => context.push(OwnerRoutes.subscription),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: context.gradients.premium,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: context.gradients.premiumEnd.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.subscriptionBannerTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.subscriptionBannerSubtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withValues(alpha: 0.7),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
