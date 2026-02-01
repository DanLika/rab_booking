import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';

const _kAdminDarkModeKey = 'admin_dark_mode';

/// Dark mode state notifier with SharedPreferences persistence
class AdminDarkModeNotifier extends StateNotifier<bool> {
  AdminDarkModeNotifier() : super(true) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kAdminDarkModeKey) ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAdminDarkModeKey, state);
  }
}

/// Dark mode state provider for Admin panel (persisted)
final adminDarkModeProvider =
    StateNotifierProvider<AdminDarkModeNotifier, bool>(
      (ref) => AdminDarkModeNotifier(),
    );

/// Admin shell with unified drawer navigation
class AdminShellScreen extends ConsumerWidget {
  final Widget child;
  final String currentPath;

  const AdminShellScreen({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(adminDarkModeProvider);

    // Use specific admin colors based on mode
    final themeData = isDarkMode
        ? ThemeData.dark(useMaterial3: true).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryLight,
              surface: Color(0xFF1E1E2E), // Modern dark background
              surfaceContainer: Color(0xFF25253A), // Drawer color
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
        drawer: _AdminDrawer(currentPath: currentPath),
        body: Column(
          children: [
            const _AdminHeader(),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _AdminDrawer extends ConsumerWidget {
  final String currentPath;

  const _AdminDrawer({required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIndex = currentPath.startsWith('/activity-log')
        ? 2
        : currentPath.startsWith('/users')
        ? 1
        : 0;
    final isDarkMode = ref.watch(adminDarkModeProvider);
    final authState = ref.watch(enhancedAuthProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      backgroundColor: colorScheme.surfaceContainer,
      child: SafeArea(
        child: Column(
          children: [
            // Logo Area
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
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

            const SizedBox(height: 24),

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
                  _DrawerItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard,
                    label: 'Dashboard',
                    isSelected: navIndex == 0,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/dashboard');
                    },
                  ),
                  const SizedBox(height: 4),
                  _DrawerItem(
                    icon: Icons.people_outline,
                    activeIcon: Icons.people,
                    label: 'Users Management',
                    isSelected: navIndex == 1,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/users');
                    },
                  ),
                  const SizedBox(height: 4),
                  _DrawerItem(
                    icon: Icons.history_outlined,
                    activeIcon: Icons.history,
                    label: 'Activity Log',
                    isSelected: navIndex == 2,
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/activity-log');
                    },
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Theme Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _DrawerItem(
                icon: isDarkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                activeIcon: isDarkMode ? Icons.light_mode : Icons.dark_mode,
                label: isDarkMode ? 'Light Mode' : 'Dark Mode',
                isSelected: false,
                onTap: () {
                  ref.read(adminDarkModeProvider.notifier).toggle();
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
                            Navigator.of(context).pop();
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
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerItem({
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

class _AdminHeader extends StatelessWidget {
  const _AdminHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          const SizedBox(width: 8),
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
          const Spacer(),
        ],
      ),
    );
  }
}
