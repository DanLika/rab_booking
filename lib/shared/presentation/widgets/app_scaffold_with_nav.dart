import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/navigation_helpers.dart';

/// App scaffold with bottom navigation
/// Used as a shell route wrapper for main app sections
class AppScaffoldWithNav extends StatefulWidget {
  const AppScaffoldWithNav({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  State<AppScaffoldWithNav> createState() => _AppScaffoldWithNavState();
}

class _AppScaffoldWithNavState extends State<AppScaffoldWithNav> {
  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    if (location == Routes.home) return 0;
    if (location == Routes.search) return 1;
    if (location == Routes.myBookings) return 2;
    if (location == Routes.profile) return 3;

    return 0; // Default to home
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(Routes.home);
        break;
      case 1:
        context.go(Routes.search);
        break;
      case 2:
        context.go(Routes.myBookings);
        break;
      case 3:
        context.go(Routes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _onItemTapped(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Pretraga',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
