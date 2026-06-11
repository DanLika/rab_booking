import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/design/bb_redesign_tokens.dart';
import '../../../../core/design/tokens.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/theme/app_colors.dart';

const _kAdminDarkModeKey = 'admin_dark_mode';

// Responsive shell breakpoints (handoff admin chrome: dissolved sidebar on
// desktop, icon rail on tablet, hamburger + drawer on mobile). Values mirror
// the per-screen breakpoints already used by dashboard/users screens.
const double _kRailBreakpoint = 800.0;
const double _kSidebarBreakpoint = 1100.0;
const double _kSidebarWidth = 260.0;
const double _kRailWidth = 72.0;

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

/// Shared nav destinations (drawer, sidebar, rail).
typedef _NavItem = ({
  IconData icon,
  IconData activeIcon,
  String label,
  String path,
});

const List<_NavItem> _navItems = [
  (
    icon: Icons.dashboard_outlined,
    activeIcon: Icons.dashboard,
    label: 'Dashboard',
    path: '/dashboard',
  ),
  (
    icon: Icons.people_outline,
    activeIcon: Icons.people,
    label: 'Users Management',
    path: '/users',
  ),
  (
    icon: Icons.history_outlined,
    activeIcon: Icons.history,
    label: 'Activity Log',
    path: '/activity-log',
  ),
];

int _navIndexFor(String currentPath) {
  if (currentPath.startsWith('/activity-log')) return 2;
  if (currentPath.startsWith('/users')) return 1;
  return 0;
}

/// Admin shell — adaptive navigation chrome.
///
/// - `>= 1100px` desktop: permanent 260px sidebar, no hamburger
/// - `800–1100px` tablet: permanent 72px icon rail, no hamburger
/// - `< 800px` mobile: 64px header with hamburger + modal drawer
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
    final width = MediaQuery.sizeOf(context).width;
    final hasSidebar = width >= _kSidebarBreakpoint;
    final hasRail = !hasSidebar && width >= _kRailBreakpoint;
    final isMobile = !hasSidebar && !hasRail;

    // Use specific admin colors based on mode
    final themeData = isDarkMode
        ? ThemeData.dark(useMaterial3: true).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primaryLight,
              surface: BbAdminDarkTokens.preset.panelBg,
              surfaceContainer: const Color(0xFF25253A), // Drawer color
            ),
            scaffoldBackgroundColor: const Color(0xFF161621),
            extensions: const <ThemeExtension<dynamic>>[
              BbAdminDarkTokens.preset,
            ],
          )
        : ThemeData.light(useMaterial3: true).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              surface: Color(0xFFF4F5F9),
              surfaceContainer: Colors.white,
              // Override MD3 defaults (~#1C1B1F / ~#49454F) with canonical
              // BookBed design slate from tokens.css :root
              //   --bb-text-primary   #2D3748 (BBColor.textPrimaryLight)
              //   --bb-text-secondary #4A5568 (BBColor.textSecondaryLight)
              // Tertiary tier (#718096) has no MD3 ColorScheme slot — admin
              // light screens needing it should read `BBColor.of(context).textTertiary`
              // directly (see `_DashboardPalette.of` light branch on PR #664).
              onSurface: BBColor.textPrimaryLight,
              onSurfaceVariant: BBColor.textSecondaryLight,
            ),
            scaffoldBackgroundColor: const Color(0xFFF3F4F6),
          );

    final content = Column(
      children: [
        _AdminHeader(showMenuButton: isMobile),
        Expanded(child: child),
      ],
    );

    return Theme(
      data: themeData,
      child: Scaffold(
        drawer: isMobile ? _AdminDrawer(currentPath: currentPath) : null,
        body: isMobile
            ? content
            : Builder(
                // Builder so the side panels resolve the admin Theme above.
                builder: (context) => Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (hasSidebar)
                      _AdminSidebar(currentPath: currentPath)
                    else
                      _AdminRail(currentPath: currentPath),
                    Expanded(child: content),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Permanent desktop sidebar (260px) — same content as the drawer, hosted
/// in a persistent panel.
class _AdminSidebar extends StatelessWidget {
  final String currentPath;

  const _AdminSidebar({required this.currentPath});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: _kSidebarWidth,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(child: _AdminNavPanel(currentPath: currentPath)),
    );
  }
}

/// Tablet icon rail (72px) — icon tiles with tooltips, theme toggle +
/// avatar/sign-out pinned at the bottom.
class _AdminRail extends ConsumerWidget {
  final String currentPath;

  const _AdminRail({required this.currentPath});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIndex = _navIndexFor(currentPath);
    final isDarkMode = ref.watch(adminDarkModeProvider);
    final authState = ref.watch(enhancedAuthProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: _kRailWidth,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
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
            const SizedBox(height: 24),
            for (var i = 0; i < _navItems.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _RailItem(
                  item: _navItems[i],
                  isSelected: navIndex == i,
                  onTap: () => context.go(_navItems[i].path),
                ),
              ),
            const Spacer(),
            _RailItem(
              item: (
                icon: isDarkMode
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                activeIcon: isDarkMode ? Icons.light_mode : Icons.dark_mode,
                label: isDarkMode ? 'Light Mode' : 'Dark Mode',
                path: '',
              ),
              isSelected: false,
              onTap: () => ref.read(adminDarkModeProvider.notifier).toggle(),
            ),
            const SizedBox(height: 4),
            Tooltip(
              message: 'Sign Out (${authState.userModel?.email ?? 'Admin'})',
              child: InkWell(
                onTap: () async {
                  await ref.read(enhancedAuthProvider.notifier).signOut();
                  if (context.mounted) context.go('/login');
                },
                borderRadius: BorderRadius.circular(22),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: CircleAvatar(
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
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _RailItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          // 48x48 target (>= 44px touch minimum)
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
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
            child: Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 22,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  final String currentPath;

  const _AdminDrawer({required this.currentPath});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      child: SafeArea(
        child: _AdminNavPanel(currentPath: currentPath, inDrawer: true),
      ),
    );
  }
}

/// Shared nav panel body — used by both the modal drawer (mobile) and the
/// permanent sidebar (desktop).
class _AdminNavPanel extends ConsumerWidget {
  final String currentPath;
  final bool inDrawer;

  const _AdminNavPanel({required this.currentPath, this.inDrawer = false});

  void _popDrawerIfNeeded(BuildContext context) {
    if (inDrawer && context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIndex = _navIndexFor(currentPath);
    final isDarkMode = ref.watch(adminDarkModeProvider);
    final authState = ref.watch(enhancedAuthProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
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
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ),
              for (var i = 0; i < _navItems.length; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : 4),
                  child: _DrawerItem(
                    icon: _navItems[i].icon,
                    activeIcon: _navItems[i].activeIcon,
                    label: _navItems[i].label,
                    isSelected: navIndex == i,
                    onTap: () {
                      _popDrawerIfNeeded(context);
                      context.go(_navItems[i].path);
                    },
                  ),
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
                        _popDrawerIfNeeded(context);
                        await ref.read(enhancedAuthProvider.notifier).signOut();
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
  final bool showMenuButton;

  const _AdminHeader({this.showMenuButton = true});

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
          if (showMenuButton) ...[
            IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Menu',
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            const SizedBox(width: 8),
          ],
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
