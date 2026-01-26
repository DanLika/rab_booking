import 'package:bookbed/core/theme/app_colors.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../providers/admin_providers.dart';

/// Dark mode state provider for Admin panel
final adminDarkModeProvider = StateProvider<bool>((ref) => true);

/// Admin shell with unified responsive navigation
class AdminShellScreen extends ConsumerWidget {
  final Widget child;

  const AdminShellScreen({super.key, required this.child});

  static const double _sidebarWidth = 260.0;
  static const double _mobileBreakpoint = 800.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIndex = ref.watch(adminNavIndexProvider);
    final isDarkMode = ref.watch(adminDarkModeProvider);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= _mobileBreakpoint;

    // Use specific admin colors based on mode
    final themeData = isDarkMode
        ? ThemeData.dark(useMaterial3: true).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryLight,
              surface: Color(0xFF1E1E2E), // Modern dark background
              surfaceContainer: Color(0xFF25253A), // Sidebar color
            ),
            scaffoldBackgroundColor: const Color(0xFF161621),
          )
        : ThemeData.light(useMaterial3: true).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              surface: Color(0xFFF8F9FA),
              surfaceContainer: Colors.white,
            ),
            scaffoldBackgroundColor: const Color(0xFFF3F4F6),
          );

    return Theme(
      data: themeData,
      child: Scaffold(
        body: Row(
          children: [
            // Desktop Sidebar
            if (isDesktop)
              _AdminSidebar(
                width: _sidebarWidth,
                navIndex: navIndex,
                isDarkMode: isDarkMode,
              ),

            // Main Content Area
            Expanded(
              child: Column(
                children: [
                  // Header (Desktop & Mobile)
                  _AdminHeader(isDesktop: isDesktop),

                  // Content Body
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
        // Mobile Bottom Navigation
        bottomNavigationBar: isDesktop
            ? null
            : NavigationBar(
                selectedIndex: navIndex,
                onDestinationSelected: (index) {
                  ref.read(adminNavIndexProvider.notifier).state = index;
                  _navigate(context, index);
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.people_outline),
                    selectedIcon: Icon(Icons.people),
                    label: 'Users',
                  ),
                ],
              ),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    if (index == 0) context.go('/dashboard');
    if (index == 1) context.go('/users');
  }
}

class _AdminSidebar extends ConsumerWidget {
  final double width;
  final int navIndex;
  final bool isDarkMode;

  const _AdminSidebar({
    required this.width,
    required this.navIndex,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(enhancedAuthProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Logo Area
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'BookBed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Admin Portal',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Navigation Items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 8),
                  child: Text(
                    'MAIN MENU',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.7,
                      ),
                    ),
                  ),
                ),
                _SidebarItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Dashboard',
                  isSelected: navIndex == 0,
                  onTap: () {
                    ref.read(adminNavIndexProvider.notifier).state = 0;
                    context.go('/dashboard');
                  },
                ),
                const SizedBox(height: 4),
                _SidebarItem(
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  label: 'Users Management',
                  isSelected: navIndex == 1,
                  onTap: () {
                    ref.read(adminNavIndexProvider.notifier).state = 1;
                    context.go('/users');
                  },
                ),
              ],
            ),
          ),

          const Spacer(),

          // Theme Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SidebarItem(
              icon: isDarkMode
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              activeIcon: isDarkMode ? Icons.light_mode : Icons.dark_mode,
              label: isDarkMode ? 'Light Mode' : 'Dark Mode',
              isSelected: false,
              onTap: () {
                ref.read(adminDarkModeProvider.notifier).state = !isDarkMode;
              },
            ),
          ),

          // User Profile Bottom
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.primary,
                  child: Text(
                    (authState.userModel?.email ?? 'A')[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authState.userModel?.email ?? 'Admin',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      InkWell(
                        onTap: () async {
                          await ref
                              .read(enhancedAuthProvider.notifier)
                              .signOut();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                        child: Text(
                          'Sign Out',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.2)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                size: 20,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminHeader extends ConsumerWidget {
  final bool isDesktop;

  const _AdminHeader({required this.isDesktop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(enhancedAuthProvider);
    final isDarkMode = ref.watch(adminDarkModeProvider);
    final theme = Theme.of(context);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // On mobile, show logo/title as there is no sidebar
          if (!isDesktop) ...[
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.admin_panel_settings,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Admin',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
          const Spacer(),

          // Mobile Actions
          if (!isDesktop) ...[
            IconButton(
              icon: Icon(
                isDarkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
              onPressed: () {
                ref.read(adminDarkModeProvider.notifier).state = !isDarkMode;
              },
            ),
            PopupMenuButton(
              icon: CircleAvatar(
                radius: 14,
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  (authState.userModel?.email ?? 'A')[0].toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Row(
                    children: [
                      Icon(Icons.logout, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Sign Out', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  onTap: () async {
                    await ref.read(enhancedAuthProvider.notifier).signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ],
            ),
          ] else ...[
            // Desktop Actions
            // Can add more header actions here like notification bells etc
          ],
        ],
      ),
    );
  }
}
