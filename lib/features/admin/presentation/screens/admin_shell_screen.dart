import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../providers/admin_providers.dart';

/// Responsive breakpoint for mobile layout
const double _mobileBreakpoint = 600.0;

/// Admin shell with adaptive navigation (mobile drawer vs desktop rail)
class AdminShellScreen extends ConsumerWidget {
  final Widget child;

  const AdminShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < _mobileBreakpoint) {
          return _MobileLayout(child: child);
        }
        return _DesktopLayout(child: child);
      },
    );
  }
}

/// Mobile layout with AppBar, Drawer, and BottomNavigationBar
class _MobileLayout extends ConsumerWidget {
  final Widget child;

  const _MobileLayout({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIndex = ref.watch(adminNavIndexProvider);
    final authState = ref.watch(enhancedAuthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('BookBed Admin'),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.admin_panel_settings,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authState.userModel?.email ?? '',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Navigation items
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    ListTile(
                      leading: Icon(
                        navIndex == 0
                            ? Icons.dashboard
                            : Icons.dashboard_outlined,
                      ),
                      title: const Text('Dashboard'),
                      selected: navIndex == 0,
                      onTap: () {
                        ref.read(adminNavIndexProvider.notifier).state = 0;
                        context.go('/dashboard');
                        Navigator.pop(context);
                      },
                    ),
                    ListTile(
                      leading: Icon(
                        navIndex == 1 ? Icons.people : Icons.people_outline,
                      ),
                      title: const Text('Users'),
                      selected: navIndex == 1,
                      onTap: () {
                        ref.read(adminNavIndexProvider.notifier).state = 1;
                        context.go('/users');
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
              // Logout
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  Navigator.pop(context); // Close drawer first
                  await ref.read(enhancedAuthProvider.notifier).signOut();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navIndex,
        onTap: (index) {
          ref.read(adminNavIndexProvider.notifier).state = index;
          switch (index) {
            case 0:
              context.go('/dashboard');
              break;
            case 1:
              context.go('/users');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Users',
          ),
        ],
      ),
    );
  }
}

/// Desktop layout with NavigationRail sidebar
class _DesktopLayout extends ConsumerWidget {
  final Widget child;

  const _DesktopLayout({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIndex = ref.watch(adminNavIndexProvider);
    final authState = ref.watch(enhancedAuthProvider);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          NavigationRail(
            selectedIndex: navIndex,
            onDestinationSelected: (index) {
              ref.read(adminNavIndexProvider.notifier).state = index;
              switch (index) {
                case 0:
                  context.go('/dashboard');
                  break;
                case 1:
                  context.go('/users');
                  break;
              }
            },
            extended: MediaQuery.of(context).size.width > 800,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const Icon(Icons.admin_panel_settings, size: 32),
                  const SizedBox(height: 4),
                  Text('Admin', style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            ),
            trailing: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    authState.userModel?.email ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Logout',
                    onPressed: () async {
                      await ref.read(enhancedAuthProvider.notifier).signOut();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                  ),
                ],
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Users'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          // Content
          Expanded(child: child),
        ],
      ),
    );
  }
}
