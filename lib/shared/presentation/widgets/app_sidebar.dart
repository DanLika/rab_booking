import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_state_provider.dart';
import '../../../features/auth/presentation/providers/auth_notifier.dart';
import '../../../core/utils/navigation_helpers.dart';
import '../../../core/theme/app_colors.dart';

/// App sidebar with NavigationRail for desktop/tablet
class AppSidebar extends ConsumerWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateNotifierProvider);
    final isAuthenticated = authState.isAuthenticated;
    final userRole = authState.role ?? UserRole.guest;
    final currentRoute = context.currentRoute;

    // Determine selected index based on current route
    final selectedIndex = _getSelectedIndex(currentRoute, isAuthenticated, userRole);

    return NavigationRail(
      extended: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedIndex: selectedIndex,
      onDestinationSelected: (int index) {
        _handleNavigation(context, index, isAuthenticated, userRole, ref);
      },
      labelType: NavigationRailLabelType.none,
      leading: const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(
              Icons.home_work,
              size: 32,
              color: AppColors.primary,
            ),
            SizedBox(height: 8),
            Text(
              'Rab\nBooking',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      trailing: Expanded(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isAuthenticated)
                  IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Odjava',
                    onPressed: () async {
                      await ref.read(authNotifierProvider.notifier).signOut();
                      if (context.mounted) {
                        context.goToHome();
                      }
                    },
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.login),
                    tooltip: 'Prijava',
                    onPressed: () => context.goToLogin(),
                  ),
              ],
            ),
          ),
        ),
      ),
      destinations: _buildDestinations(isAuthenticated, userRole),
    );
  }

  List<NavigationRailDestination> _buildDestinations(
    bool isAuthenticated,
    UserRole userRole,
  ) {
    final destinations = <NavigationRailDestination>[
      const NavigationRailDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: Text('Početna'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.search_outlined),
        selectedIcon: Icon(Icons.search),
        label: Text('Pretraga'),
      ),
    ];

    if (isAuthenticated) {
      destinations.addAll([
        const NavigationRailDestination(
          icon: Icon(Icons.bookmark_outline),
          selectedIcon: Icon(Icons.bookmark),
          label: Text('Rezervacije'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: Text('Profil'),
        ),
      ]);

      if (userRole == UserRole.owner) {
        destinations.add(
          const NavigationRailDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: Text('Owner Dashboard'),
          ),
        );
      }

      if (userRole == UserRole.admin) {
        destinations.add(
          const NavigationRailDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: Text('Admin Panel'),
          ),
        );
      }
    } else {
      destinations.addAll([
        const NavigationRailDestination(
          icon: Icon(Icons.login),
          selectedIcon: Icon(Icons.login),
          label: Text('Prijava'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.person_add_outlined),
          selectedIcon: Icon(Icons.person_add),
          label: Text('Registracija'),
        ),
      ]);
    }

    return destinations;
  }

  int _getSelectedIndex(
    String currentRoute,
    bool isAuthenticated,
    UserRole userRole,
  ) {
    if (currentRoute == Routes.home) return 0;
    if (currentRoute == Routes.search) return 1;

    if (isAuthenticated) {
      if (currentRoute == Routes.myBookings || currentRoute.startsWith('/bookings')) return 2;
      if (currentRoute == Routes.profile) return 3;
      if (userRole == UserRole.owner && (currentRoute == Routes.ownerDashboard || currentRoute.startsWith('/owner'))) {
        return 4;
      }
      if (userRole == UserRole.admin && currentRoute.startsWith('/admin')) {
        return 4;
      }
    } else {
      if (currentRoute.startsWith('/auth/login')) return 2;
      if (currentRoute.startsWith('/auth/register')) return 3;
    }

    return 0; // Default to home
  }

  void _handleNavigation(
    BuildContext context,
    int index,
    bool isAuthenticated,
    UserRole userRole,
    WidgetRef ref,
  ) {
    if (isAuthenticated) {
      switch (index) {
        case 0:
          context.goToHome();
          break;
        case 1:
          context.goToSearch();
          break;
        case 2:
          context.goToMyBookings();
          break;
        case 3:
          context.goToProfile();
          break;
        case 4:
          if (userRole == UserRole.owner) {
            context.goToOwnerDashboard();
          } else if (userRole == UserRole.admin) {
            context.go('/admin');
          }
          break;
      }
    } else {
      switch (index) {
        case 0:
          context.goToHome();
          break;
        case 1:
          context.goToSearch();
          break;
        case 2:
          context.goToLogin();
          break;
        case 3:
          context.goToRegister();
          break;
      }
    }
  }
}
