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
import '../providers/user_profile_provider.dart';
import '../widgets/language_selection_bottom_sheet.dart';
import '../widgets/theme_selection_bottom_sheet.dart';
import '../widgets/owner_app_drawer.dart';
import '../../../../shared/widgets/common_app_bar.dart';

/// Profile screen for owner dashboard
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final userProfileAsync = ref.watch(watchUserProfileProvider);
    final authState = ref.watch(enhancedAuthProvider);
    final currentLocale = ref.watch(currentLocaleProvider);
    final currentThemeMode = ref.watch(currentThemeModeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get language display name
    final languageName = currentLocale.languageCode == 'hr' ? 'Hrvatski' : 'English';

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
            : userProfileAsync.when(
                data: (profile) {
                  final isAnonymous = authState.isAnonymous;
                  final displayName =
                      profile?.displayName ??
                      user.displayName ??
                      (isAnonymous ? l10n.ownerProfileGuestUser : l10n.ownerProfileOwner);
                  final email =
                      user.email ?? (isAnonymous ? l10n.ownerProfileAnonymousAccount : l10n.ownerProfileNoEmail);
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isMobile = screenWidth < 600;

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                    child: Column(
                      children: [
                        // Compact Profile header
                        Container(
                          decoration: BoxDecoration(
                            gradient: context.gradients.brandPrimary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(isMobile ? 16 : 20),
                            child: Column(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: isDark ? 0.2 : 0.3),
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.15),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child:
                                      authState.userModel?.avatarUrl != null &&
                                          authState.userModel!.avatarUrl!.isNotEmpty
                                      ? ClipOval(
                                          child: Image.network(
                                            authState.userModel!.avatarUrl!,
                                            width: isMobile ? 72 : 88,
                                            height: isMobile ? 72 : 88,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return CircleAvatar(
                                                radius: isMobile ? 36 : 44,
                                                backgroundColor: isDark ? AppColors.primary : Colors.white,
                                                child: Text(
                                                  displayName.substring(0, 1).toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: isMobile ? 28 : 34,
                                                    fontWeight: FontWeight.bold,
                                                    color: isDark ? Colors.white : AppColors.primary,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        )
                                      : CircleAvatar(
                                          radius: isMobile ? 36 : 44,
                                          backgroundColor: isDark ? AppColors.primary : Colors.white,
                                          child: Text(
                                            displayName.substring(0, 1).toUpperCase(),
                                            style: TextStyle(
                                              fontSize: isMobile ? 28 : 34,
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? Colors.white : AppColors.primary,
                                            ),
                                          ),
                                        ),
                                ),
                                SizedBox(height: isMobile ? 12 : 14),
                                ConstrainedBox(
                                  constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 400),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.2),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: isMobile ? 12 : 13,
                                      color: Colors.white.withValues(alpha: 0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Account settings
                        Container(
                          decoration: BoxDecoration(
                            color: context.gradients.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt())),
                            boxShadow: isDark ? AppShadows.elevation1Dark : AppShadows.elevation1,
                          ),
                          child: Column(
                            children: [
                              _PremiumListTile(
                                icon: Icons.person_outline,
                                title: l10n.ownerProfileEditProfile,
                                subtitle: isAnonymous
                                    ? l10n.ownerProfileEditProfileSubtitleAnonymous
                                    : l10n.ownerProfileEditProfileSubtitle,
                                onTap: isAnonymous ? null : () => context.push(OwnerRoutes.profileEdit),
                              ),
                              if (!isAnonymous) ...[
                                Divider(height: 1, indent: 72, color: theme.dividerColor),
                                _PremiumListTile(
                                  icon: Icons.lock_outline,
                                  title: l10n.ownerProfileChangePassword,
                                  subtitle: l10n.ownerProfileChangePasswordSubtitle,
                                  onTap: () => context.push(OwnerRoutes.profileChangePassword),
                                ),
                              ],
                              Divider(height: 1, indent: 72, color: theme.dividerColor),
                              _PremiumListTile(
                                icon: Icons.notifications_outlined,
                                title: l10n.ownerProfileNotificationSettings,
                                subtitle: l10n.ownerProfileNotificationSettingsSubtitle,
                                onTap: () => context.push(OwnerRoutes.profileNotifications),
                                isLast: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // App settings
                        Container(
                          decoration: BoxDecoration(
                            color: context.gradients.cardBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt())),
                            boxShadow: isDark ? AppShadows.elevation1Dark : AppShadows.elevation1,
                          ),
                          child: Column(
                            children: [
                              _PremiumListTile(
                                icon: Icons.language,
                                title: l10n.ownerProfileLanguage,
                                subtitle: languageName,
                                onTap: () => showLanguageSelectionBottomSheet(context, ref),
                              ),
                              Divider(height: 1, indent: 56, color: theme.dividerColor),
                              _PremiumListTile(
                                icon: Icons.brightness_6_outlined,
                                title: l10n.ownerProfileTheme,
                                subtitle: themeName,
                                onTap: () => showThemeSelectionBottomSheet(context, ref),
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
                            border: Border.all(color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt())),
                            boxShadow: isDark ? AppShadows.elevation1Dark : AppShadows.elevation1,
                          ),
                          child: Column(
                            children: [
                              _PremiumListTile(
                                icon: Icons.help_outline,
                                title: l10n.ownerProfileHelpSupport,
                                subtitle: l10n.ownerProfileHelpSupportSubtitle,
                                onTap: () {
                                  ErrorDisplayUtils.showInfoSnackBar(context, l10n.ownerProfileHelpSupportComingSoon);
                                },
                              ),
                              Divider(height: 1, indent: 56, color: theme.dividerColor),
                              _PremiumListTile(
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
                            border: Border.all(color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt())),
                            boxShadow: isDark ? AppShadows.elevation1Dark : AppShadows.elevation1,
                          ),
                          child: _LogoutTile(
                            onLogout: () async {
                              await ref.read(enhancedAuthProvider.notifier).signOut();
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
                            border: Border.all(color: context.gradients.sectionBorder.withAlpha((0.5 * 255).toInt())),
                            boxShadow: isDark ? AppShadows.elevation1Dark : AppShadows.elevation1,
                          ),
                          child: Column(
                            children: [
                              _PremiumListTile(
                                icon: Icons.description_outlined,
                                title: l10n.ownerProfileTermsConditions,
                                subtitle: l10n.ownerProfileTermsConditionsSubtitle,
                                onTap: () => context.push(OwnerRoutes.termsConditions),
                              ),
                              Divider(height: 1, indent: 56, color: theme.dividerColor),
                              _PremiumListTile(
                                icon: Icons.privacy_tip_outlined,
                                title: l10n.ownerProfilePrivacyPolicy,
                                subtitle: l10n.ownerProfilePrivacyPolicySubtitle,
                                onTap: () => context.push(OwnerRoutes.privacyPolicy),
                              ),
                              Divider(height: 1, indent: 56, color: theme.dividerColor),
                              _PremiumListTile(
                                icon: Icons.cookie_outlined,
                                title: l10n.ownerProfileCookiesPolicy,
                                subtitle: l10n.ownerProfileCookiesPolicySubtitle,
                                onTap: () => context.push(OwnerRoutes.cookiesPolicy),
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
                loading: () {
                  final theme = Theme.of(context);
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          l10n.ownerProfileLoading,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                error: (error, stack) {
                  final theme = Theme.of(context);
                  final isDark = theme.brightness == Brightness.dark;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: context.gradients.cardBackground,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: theme.colorScheme.error.withAlpha((0.3 * 255).toInt()),
                                width: 2,
                              ),
                              boxShadow: isDark ? AppShadows.elevation2Dark : AppShadows.elevation2,
                            ),
                            child: Icon(Icons.error_outline, size: 50, color: theme.colorScheme.error),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            l10n.ownerProfileLoadError,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '$error',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.arrow_back),
                                label: Text(l10n.ownerProfileBack),
                              ),
                              const SizedBox(width: 12),
                              FilledButton.icon(
                                onPressed: () => ref.invalidate(watchUserProfileProvider),
                                icon: const Icon(Icons.refresh),
                                label: Text(l10n.ownerProfileTryAgain),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

/// Compact List Tile widget
class _PremiumListTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final dynamic subtitle;
  final VoidCallback? onTap;
  final bool isLast;

  const _PremiumListTile({required this.icon, required this.title, this.onTap, this.subtitle, this.isLast = false});

  @override
  State<_PremiumListTile> createState() => _PremiumListTileState();
}

class _PremiumListTileState extends State<_PremiumListTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onTap == null;
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return MouseRegion(
      onEnter: (_) => !isDisabled ? setState(() => _isHovered = true) : null,
      onExit: (_) => !isDisabled ? setState(() => _isHovered = false) : null,
      cursor: isDisabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isHovered && !isDisabled ? AppColors.primary.withValues(alpha: 0.04) : Colors.transparent,
          borderRadius: widget.isLast
              ? const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12))
              : BorderRadius.zero,
        ),
        child: Opacity(
          opacity: isDisabled ? 0.4 : 1.0,
          child: ListTile(
            dense: true,
            visualDensity: const VisualDensity(vertical: -1),
            contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 4 : 6),
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(widget.icon, color: AppColors.primary, size: isMobile ? 18 : 20),
            ),
            title: Text(
              widget.title,
              style: TextStyle(
                fontSize: isMobile ? 14 : 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            subtitle: widget.subtitle is String
                ? Text(
                    widget.subtitle as String,
                    style: TextStyle(
                      fontSize: isMobile ? 12 : 13,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  )
                : widget.subtitle as Widget?,
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              size: isMobile ? 18 : 20,
            ),
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}

/// Compact Logout Tile
class _LogoutTile extends StatefulWidget {
  final VoidCallback onLogout;

  const _LogoutTile({required this.onLogout});

  @override
  State<_LogoutTile> createState() => _LogoutTileState();
}

class _LogoutTileState extends State<_LogoutTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isHovered ? AppColors.error.withValues(alpha: 0.05) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          dense: true,
          visualDensity: const VisualDensity(vertical: -1),
          contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 4 : 6),
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.logout_rounded, color: AppColors.error, size: isMobile ? 18 : 20),
          ),
          title: Text(
            l10n.ownerProfileLogout,
            style: TextStyle(fontSize: isMobile ? 14 : 15, fontWeight: FontWeight.w600, color: AppColors.error),
          ),
          subtitle: Text(
            l10n.ownerProfileLogoutSubtitle,
            style: TextStyle(fontSize: isMobile ? 12 : 13, color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: AppColors.error.withValues(alpha: 0.7),
            size: isMobile ? 18 : 20,
          ),
          onTap: widget.onLogout,
        ),
      ),
    );
  }
}
