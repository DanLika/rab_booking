import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../providers/admin_providers.dart';

/// Dark mode state provider for Admin panel
final adminDarkModeProvider = StateProvider<bool>((ref) => true);

/// Admin shell with unified drawer navigation (mobile and desktop)
class AdminShellScreen extends ConsumerWidget {
  final Widget child;

  const AdminShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navIndex = ref.watch(adminNavIndexProvider);
    final authState = ref.watch(enhancedAuthProvider);
    final isDarkMode = ref.watch(adminDarkModeProvider);

    return Theme(
      data: isDarkMode
          ? ThemeData.dark(useMaterial3: true)
          : ThemeData.light(useMaterial3: true),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('BookBed Admin'),
          centerTitle: true,
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Menu',
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
                      Tooltip(
                        message: authState.userModel?.email ?? '',
                        child: Text(
                          authState.userModel?.email ?? '',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
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
                // Dark mode toggle in drawer
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  ),
                  title: Text(isDarkMode ? 'Light Mode' : 'Dark Mode'),
                  onTap: () {
                    ref.read(adminDarkModeProvider.notifier).state =
                        !isDarkMode;
                  },
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
      ),
    );
  }
}
