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
    final user = FirebaseAuth.instance.currentUser;
    final userProfileAsync = ref.watch(userProfileProvider);
    final authState = ref.watch(enhancedAuthProvider);
    final currentLocale = ref.watch(currentLocaleProvider);
    final currentThemeMode = ref.watch(currentThemeModeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get language display name
    final languageName = currentLocale.languageCode == 'hr' ? 'Hrvatski' : 'English';

    // Get theme display name
    final themeName = currentThemeMode == ThemeMode.light
        ? 'Light'
        : currentThemeMode == ThemeMode.dark
            ? 'Dark'
            : 'System default';

    return Scaffold(
      drawer: const OwnerAppDrawer(currentRoute: 'profile'),
      appBar: CommonAppBar(
        title: 'Profil',
        leadingIcon: Icons.menu,
        onLeadingIconTap: (context) => Scaffold.of(context).openDrawer(),
      ),
      body: user == null
          ? const Center(child: Text('Not authenticated'))
          : userProfileAsync.when(
              data: (profile) {
                final isAnonymous = authState.isAnonymous;
                final displayName = profile?.displayName ?? user.displayName ?? (isAnonymous ? 'Guest User' : 'Owner');
                final email = user.email ?? (isAnonymous ? 'Anonymous Account' : 'No email');
                final screenWidth = MediaQuery.of(context).size.width;
                final isMobile = screenWidth < 600;
                final headerPadding = isMobile ? 16.0 : 32.0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                        // Premium Profile header
                        Container(
                          decoration: BoxDecoration(
                            gradient: isDark
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppColors.elevation2Dark,
                                      AppColors.elevation1Dark,
                                    ],
                                  )
                                : AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? Colors.black.withValues(alpha: 0.3)
                                    : AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: isMobile ? 15 : 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(headerPadding),
                            child: Column(
                              children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: isDark ? 0.2 : 0.3),
                                  width: isMobile ? 3 : 4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: authState.userModel?.avatarUrl != null &&
                                      authState.userModel!.avatarUrl!.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        authState.userModel!.avatarUrl!,
                                        width: isMobile ? 100 : 120,
                                        height: isMobile ? 100 : 120,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return CircleAvatar(
                                            radius: isMobile ? 50 : 60,
                                            backgroundColor: isDark
                                                ? AppColors.primary
                                                : Colors.white,
                                            child: Text(
                                              displayName.substring(0, 1).toUpperCase(),
                                              style: TextStyle(
                                                fontSize: isMobile ? 40 : 48,
                                                fontWeight: FontWeight.bold,
                                                color: isDark
                                                    ? Colors.white
                                                    : AppColors.primary,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    )
                                  : CircleAvatar(
                                      radius: isMobile ? 50 : 60,
                                      backgroundColor: isDark
                                          ? AppColors.primary
                                          : Colors.white,
                                      child: Text(
                                        displayName.substring(0, 1).toUpperCase(),
                                        style: TextStyle(
                                          fontSize: isMobile ? 40 : 48,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.primary,
                                        ),
                                      ),
                                    ),
                            ),
                            SizedBox(height: isMobile ? 16 : 20),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: isMobile ? double.infinity : 400,
                              ),
                              child: Text(
                                displayName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isMobile ? 24 : 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: isDark ? null : [
                                    Shadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      offset: const Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: isMobile ? 8 : 12),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 16,
                                vertical: isMobile ? 6 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isMobile ? 13 : 15,
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 24),

                    // Account settings - Premium
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.elevation1Dark : Colors.white,
                        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark.withValues(alpha: 0.5)
                              : AppColors.borderLight,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _PremiumListTile(
                            icon: Icons.person_outline,
                            title: 'Edit Profile',
                            subtitle: isAnonymous
                                ? 'Sign up to edit your profile'
                                : 'Update your personal information',
                            onTap: isAnonymous
                                ? null
                                : () => context.push(OwnerRoutes.profileEdit),
                          ),
                          if (!isAnonymous) ...[
                            const Divider(height: 1, indent: 72),
                            _PremiumListTile(
                              icon: Icons.lock_outline,
                              title: 'Change Password',
                              subtitle: 'Update your password',
                              onTap: () => context.push(OwnerRoutes.profileChangePassword),
                            ),
                          ],
                          const Divider(height: 1, indent: 72),
                          _PremiumListTile(
                            icon: Icons.notifications_outlined,
                            title: 'Notification Settings',
                            subtitle: 'Manage your notifications',
                            onTap: () => context.push(OwnerRoutes.profileNotifications),
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                const SizedBox(height: 20),

                    // App settings - Premium
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.elevation1Dark : Colors.white,
                        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark.withValues(alpha: 0.5)
                              : AppColors.borderLight,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _PremiumListTile(
                            icon: Icons.language,
                            title: 'Language',
                            subtitle: languageName,
                            onTap: () => showLanguageSelectionBottomSheet(context, ref),
                          ),
                          const Divider(height: 1, indent: 72),
                          _PremiumListTile(
                            icon: Icons.brightness_6_outlined,
                            title: 'Theme',
                            subtitle: themeName,
                            onTap: () => showThemeSelectionBottomSheet(context, ref),
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                const SizedBox(height: 20),

                    // Account actions - Premium
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.elevation1Dark : Colors.white,
                        borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark.withValues(alpha: 0.5)
                              : AppColors.borderLight,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _PremiumListTile(
                            icon: Icons.help_outline,
                            title: 'Help & Support',
                            subtitle: 'Get help with the app',
                            onTap: () {
                              ErrorDisplayUtils.showInfoSnackBar(
                                context,
                                'Help & Support coming soon',
                              );
                            },
                          ),
                          const Divider(height: 1, indent: 72),
                          _PremiumListTile(
                            icon: Icons.info_outline,
                            title: 'About',
                            subtitle: 'App information',
                            onTap: () {
                              ErrorDisplayUtils.showInfoSnackBar(
                                context,
                                'About coming soon',
                              );
                            },
                          ),
                          const Divider(height: 1, indent: 72),
                          _LogoutTile(
                            onLogout: () async {
                              await ref.read(enhancedAuthProvider.notifier).signOut();
                              if (context.mounted) {
                                context.go(OwnerRoutes.login);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                const SizedBox(height: 32),
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
                        'Učitavanje profila...',
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
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Greška pri učitavanju profila',
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
                              label: const Text('Nazad'),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: () => ref.invalidate(userProfileProvider),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Pokušaj ponovo'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

/// Premium List Tile widget
class _PremiumListTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final dynamic subtitle;
  final VoidCallback? onTap;
  final bool isLast;

  const _PremiumListTile({
    required this.icon,
    required this.title,
    this.onTap,
    this.subtitle,
    this.isLast = false,
  });

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
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isHovered && !isDisabled
              ? AppColors.primary.withValues(alpha: 0.04)
              : Colors.transparent,
          borderRadius: widget.isLast
              ? BorderRadius.only(
                  bottomLeft: Radius.circular(isMobile ? 12 : 16),
                  bottomRight: Radius.circular(isMobile ? 12 : 16),
                )
              : BorderRadius.zero,
        ),
        child: Opacity(
          opacity: isDisabled ? 0.4 : 1.0,
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 20,
              vertical: isMobile ? 10 : 12,
            ),
            leading: Container(
              padding: EdgeInsets.all(isMobile ? 8 : 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.icon,
                color: AppColors.primary,
                size: isMobile ? 20 : 22,
              ),
            ),
            title: Text(
              widget.title,
              style: TextStyle(
                fontSize: isMobile ? 15 : 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            subtitle: widget.subtitle is String
                ? Text(
                    widget.subtitle as String,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  )
                : widget.subtitle as Widget?,
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              size: isMobile ? 20 : 24,
            ),
            onTap: widget.onTap,
          ),
        ),
      ),
    );
  }
}

/// Premium Logout Tile
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
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _isHovered
              ? AppColors.error.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(isMobile ? 12 : 16),
            bottomRight: Radius.circular(isMobile ? 12 : 16),
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 20,
            vertical: isMobile ? 10 : 12,
          ),
          leading: Container(
            padding: EdgeInsets.all(isMobile ? 8 : 10),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.logout_rounded,
              color: AppColors.error,
              size: isMobile ? 20 : 22,
            ),
          ),
          title: Text(
            'Logout',
            style: TextStyle(
              fontSize: isMobile ? 15 : 16,
              fontWeight: FontWeight.w600,
              color: AppColors.error,
            ),
          ),
          subtitle: Text(
            'Sign out of your account',
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: AppColors.error,
            size: isMobile ? 20 : 24,
          ),
          onTap: widget.onLogout,
        ),
      ),
    );
  }
}
