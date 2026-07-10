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
              surfaceContainer:
                  BbAdminDarkTokens.preset.shellBg, // sidebar/rail/drawer
            ),
            scaffoldBackgroundColor: BbAdminDarkTokens.preset.shellBg,
            extensions: const <ThemeExtension<dynamic>>[
              BbAdminDarkTokens.preset,
            ],
          )
        : ThemeData.light(useMaterial3: true).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              surface: AppColors.surfaceVariantLight,
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
            scaffoldBackgroundColor: AppColors.shellBgLight,
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
                  isDark: isDarkMode,
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
              isDark: isDarkMode,
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
  final bool isDark;
  final VoidCallback onTap;

  const _RailItem({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = BbAdminDarkTokens.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    // Handoff admin-shell.jsx:27-39: 48px tile, radius 12, hero gradient +
    // glow when active, idle fill rgba(255,255,255,0.05). Gradient/white-alpha
    // fills are dark-console-only; light mode falls back to primary tints.
    final bool gradientActive = isSelected && isDark;
    final Color idleFill = isDark ? tokens.navTileIdleBg : Colors.transparent;
    final Color selectedLightFill = colorScheme.primary.withValues(alpha: 0.1);
    return Tooltip(
      message: item.label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          // 48x48 target (>= 44px touch minimum)
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: gradientActive ? tokens.navIconActiveGradient : null,
              color: gradientActive
                  ? null
                  : (isSelected ? selectedLightFill : idleFill),
              borderRadius: BorderRadius.circular(12),
              border: isSelected && !isDark
                  ? Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                    )
                  : null,
              boxShadow: gradientActive ? tokens.navActiveGlow : null,
            ),
            child: Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 22,
              color: gradientActive
                  ? Colors.white
                  : (isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'BookBed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        letterSpacing: -0.02 * 18,
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
              ),
              if (isDarkMode) const _AdminBadgePill(),
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

/// ADMIN tag pill in the dark sidebar header (handoff admin-shell.jsx:81).
class _AdminBadgePill extends StatelessWidget {
  const _AdminBadgePill();

  @override
  Widget build(BuildContext context) {
    final tokens = BbAdminDarkTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: tokens.adminBadgeBg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        'ADMIN',
        style: TextStyle(
          color: tokens.adminBadgeFg,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1 * 9,
        ),
      ),
    );
  }
}

class _DrawerItem extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = ref.watch(adminDarkModeProvider);
    final tokens = BbAdminDarkTokens.of(context);

    // Handoff (admin-shell.jsx:41-64): full nav row = 44px, radius 12, active
    // fill rgba(255,255,255,0.08) + border 0.10; icon lives in a 28px rounded
    // tile that carries the hero gradient + purple glow when active.
    final Color rowBg = isSelected
        ? (isDark
              ? tokens.navTileActiveBg
              : colorScheme.primary.withValues(alpha: 0.1))
        : Colors.transparent;
    final Color rowBorder = isSelected
        ? (isDark
              ? tokens.navTileActiveBorder
              : colorScheme.primary.withValues(alpha: 0.2))
        : Colors.transparent;
    final Color labelColor = isSelected
        ? (isDark ? tokens.textPrimary : colorScheme.primary)
        : colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: rowBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: rowBorder),
          ),
          child: Row(
            children: [
              _NavIconTile(
                icon: isSelected ? activeIcon : icon,
                isSelected: isSelected,
                isDark: isDark,
                size: 28,
                iconSize: 18,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: labelColor,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Rounded icon tile shared by drawer/sidebar rows and the rail. Active =
/// hero gradient fill + purple glow (dark) per admin-shell.jsx:51-58.
class _NavIconTile extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final double size;
  final double iconSize;

  const _NavIconTile({
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.size,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = BbAdminDarkTokens.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final bool gradientActive = isSelected && isDark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradientActive ? tokens.navIconActiveGradient : null,
        color: gradientActive
            ? null
            : (isSelected
                  ? colorScheme.primary.withValues(alpha: 0.12)
                  : (isDark ? tokens.navTileIdleBg : Colors.transparent)),
        borderRadius: BorderRadius.circular(size >= 40 ? 12 : 9),
        boxShadow: gradientActive ? tokens.navActiveGlow : null,
      ),
      child: Icon(
        icon,
        size: iconSize,
        color: gradientActive
            ? Colors.white
            : (isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant),
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

/// Renders the dark-console nav chrome pieces (active + idle nav rows, ADMIN
/// badge, rail tile) in isolation for the fidelity seam test — no Firebase /
/// auth provider. `adminDarkModeProvider` must be overridden by the caller
/// (both `_DrawerItem` and `_RailItem` icon-tile branch on it). Not for
/// production use — see `test/features/admin/admin_shell_nav_test.dart`.
@visibleForTesting
Widget buildAdminNavChromeForTest() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _AdminBadgePill(),
      const SizedBox(height: 8),
      _DrawerItem(
        icon: _navItems[0].icon,
        activeIcon: _navItems[0].activeIcon,
        label: _navItems[0].label,
        isSelected: true,
        onTap: () {},
      ),
      const SizedBox(height: 4),
      _DrawerItem(
        icon: _navItems[1].icon,
        activeIcon: _navItems[1].activeIcon,
        label: _navItems[1].label,
        isSelected: false,
        onTap: () {},
      ),
      const SizedBox(height: 8),
      _RailItem(
        item: _navItems[0],
        isSelected: true,
        isDark: true,
        onTap: () {},
      ),
    ],
  );
}
