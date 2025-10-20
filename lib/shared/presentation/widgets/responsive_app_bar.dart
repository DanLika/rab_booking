import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_state_provider.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../core/providers/language_provider.dart';
import '../../../core/utils/navigation_helpers.dart';
import '../../../features/auth/presentation/providers/auth_notifier.dart';

/// Responsive AppBar that adapts based on screen size:
/// - Mobile/Tablet (< 1200px): Hamburger icon + Logo
/// - Desktop (>= 1200px): Logo + Text navigation links (no hamburger)
class ResponsiveAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const ResponsiveAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1200;

    if (isDesktop) {
      return _buildDesktopAppBar(context, ref);
    } else {
      return _buildMobileTabletAppBar(context, ref);
    }
  }

  /// Mobile/Tablet AppBar: Hamburger + Logo
  Widget _buildMobileTabletAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      leading: Builder(
        builder: (context) {
          return IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Meni',
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          );
        },
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.home_work,
            size: 28,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Text(
            'Rab Booking',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
      elevation: 1,
    );
  }

  /// Desktop AppBar: Logo + Text Navigation Links (no hamburger)
  Widget _buildDesktopAppBar(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateNotifierProvider);
    final isAuthenticated = authState.isAuthenticated;
    final userRole = authState.role;
    final currentRoute = context.currentRoute;

    return AppBar(
      automaticallyImplyLeading: false, // No hamburger icon
      elevation: 1,
      title: Row(
        children: [
          // Logo + Brand
          InkWell(
            onTap: () => context.go(Routes.home),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.home_work,
                    size: 32,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Rab Booking',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 48),

          // Navigation Links
          _buildNavLink(
            context,
            label: 'Početna',
            route: Routes.home,
            isActive: currentRoute == Routes.home,
          ),
          const SizedBox(width: 8),
          _buildNavLink(
            context,
            label: 'Pretraga',
            route: Routes.search,
            isActive: currentRoute == Routes.search,
          ),

          if (isAuthenticated) ...[
            const SizedBox(width: 8),
            _buildNavLink(
              context,
              label: 'Rezervacije',
              route: Routes.myBookings,
              isActive: currentRoute == Routes.myBookings ||
                  currentRoute.startsWith('/bookings'),
            ),
            const SizedBox(width: 8),
            _buildNavLink(
              context,
              label: 'Profil',
              route: Routes.profile,
              isActive: currentRoute == Routes.profile,
            ),

            // Owner Dashboard link (for owners and admins)
            if (userRole == UserRole.owner || userRole == UserRole.admin) ...[
              const SizedBox(width: 8),
              _buildNavLink(
                context,
                label: 'Owner Panel',
                route: Routes.ownerDashboard,
                isActive: currentRoute.startsWith('/owner'),
              ),
            ],

            // Admin Dashboard link (for admins only)
            if (userRole == UserRole.admin) ...[
              const SizedBox(width: 8),
              _buildNavLink(
                context,
                label: 'Admin Panel',
                route: Routes.adminDashboard,
                isActive: currentRoute.startsWith('/admin'),
              ),
            ],
          ],

          const Spacer(),

          // Theme Selector
          _buildThemeSelector(context, ref),
          const SizedBox(width: 8),

          // Language Selector
          _buildLanguageSelector(context, ref),
          const SizedBox(width: 16),

          // Auth Section
          if (isAuthenticated)
            _buildLogoutButton(context, ref)
          else
            _buildLoginButton(context),
        ],
      ),
    );
  }

  /// Navigation link for desktop
  Widget _buildNavLink(
    BuildContext context, {
    required String label,
    required String route,
    required bool isActive,
  }) {
    final theme = Theme.of(context);

    return TextButton(
      onPressed: () => context.go(route),
      style: TextButton.styleFrom(
        foregroundColor: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.7),
        textStyle: TextStyle(
          fontSize: 16,
          fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label),
    );
  }

  /// Login button for desktop
  Widget _buildLoginButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilledButton.icon(
        onPressed: () => context.go(Routes.authLogin),
        icon: const Icon(Icons.login, size: 20),
        label: const Text('Prijava'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }

  /// Logout button for desktop
  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Notifications icon button
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            child: IconButton(
              onPressed: () => context.go(Routes.notifications),
              icon: const Icon(Icons.notifications_outlined),
              tooltip: 'Obavještenja',
            ),
          ),
          const SizedBox(width: 8),
          // Profile icon button
          ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 48,
            ),
            child: IconButton(
              onPressed: () => context.go(Routes.profile),
              icon: const Icon(Icons.person),
              tooltip: 'Profil',
            ),
          ),
          const SizedBox(width: 8),
          // Logout button
          OutlinedButton.icon(
            onPressed: () => _handleLogout(context, ref),
            icon: const Icon(Icons.logout, size: 20),
            label: const Text('Odjava'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle logout
  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrda odjave'),
        content: const Text('Jeste li sigurni da se želite odjaviti?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Odjavi se'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) {
        context.go(Routes.home);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Uspješno ste se odjavili'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Theme selector with popup menu
  Widget _buildThemeSelector(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeNotifierProvider);
    final currentMode = themeModeAsync.value ?? ThemeMode.system;

    IconData themeIcon;
    String themeTooltip;

    switch (currentMode) {
      case ThemeMode.light:
        themeIcon = Icons.light_mode;
        themeTooltip = 'Svijetla tema';
        break;
      case ThemeMode.dark:
        themeIcon = Icons.dark_mode;
        themeTooltip = 'Tamna tema';
        break;
      case ThemeMode.system:
        themeIcon = Icons.brightness_auto;
        themeTooltip = 'Sistemska tema';
        break;
    }

    return PopupMenuButton<ThemeMode>(
      icon: Icon(themeIcon),
      tooltip: themeTooltip,
      onSelected: (ThemeMode mode) async {
        await ref.read(themeNotifierProvider.notifier).setThemeMode(mode);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<ThemeMode>>[
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.light,
          child: Row(
            children: [
              Icon(
                Icons.light_mode,
                color: currentMode == ThemeMode.light
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                'Svijetla',
                style: TextStyle(
                  fontWeight: currentMode == ThemeMode.light
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.dark,
          child: Row(
            children: [
              Icon(
                Icons.dark_mode,
                color: currentMode == ThemeMode.dark
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                'Tamna',
                style: TextStyle(
                  fontWeight: currentMode == ThemeMode.dark
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.system,
          child: Row(
            children: [
              Icon(
                Icons.brightness_auto,
                color: currentMode == ThemeMode.system
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                'Sistemska',
                style: TextStyle(
                  fontWeight: currentMode == ThemeMode.system
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Language selector with popup menu
  Widget _buildLanguageSelector(BuildContext context, WidgetRef ref) {
    final localeAsync = ref.watch(languageNotifierProvider);
    final currentLocale = localeAsync.value ?? const Locale('hr');

    return PopupMenuButton<String>(
      icon: const Icon(Icons.language),
      tooltip: 'Jezik',
      onSelected: (String languageCode) async {
        await ref.read(languageNotifierProvider.notifier).setLanguage(languageCode);
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'hr',
          child: Row(
            children: [
              const Text('🇭🇷', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                'Hrvatski',
                style: TextStyle(
                  fontWeight: currentLocale.languageCode == 'hr'
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: currentLocale.languageCode == 'hr'
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'en',
          child: Row(
            children: [
              const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                'English',
                style: TextStyle(
                  fontWeight: currentLocale.languageCode == 'en'
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: currentLocale.languageCode == 'en'
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
