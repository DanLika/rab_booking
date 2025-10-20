import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/providers/auth_state_provider.dart';
import '../../../features/auth/presentation/providers/auth_notifier.dart';
import '../../../core/utils/navigation_helpers.dart';
import '../../../core/theme/app_colors.dart';

/// App drawer for mobile navigation
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateNotifierProvider);
    final isAuthenticated = authState.isAuthenticated;
    final user = authState.user;
    final userRole = authState.role ?? UserRole.guest;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer header with user info or login prompt
          if (isAuthenticated && user != null)
            _buildAuthenticatedHeader(context, user, userRole)
          else
            _buildUnauthenticatedHeader(context),

          const Divider(),

          // Main navigation items
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Početna'),
            selected: context.currentRoute == Routes.home,
            onTap: () {
              Navigator.pop(context);
              context.goToHome();
            },
          ),

          ListTile(
            leading: const Icon(Icons.search_outlined),
            title: const Text('Pretraga'),
            selected: context.currentRoute == Routes.search,
            onTap: () {
              Navigator.pop(context);
              context.goToSearch();
            },
          ),

          if (isAuthenticated) ...[
            ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: const Text('Moje rezervacije'),
              selected: context.currentRoute == Routes.myBookings,
              onTap: () {
                Navigator.pop(context);
                context.goToMyBookings();
              },
            ),

            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profil'),
              selected: context.currentRoute == Routes.profile,
              onTap: () {
                Navigator.pop(context);
                context.goToProfile();
              },
            ),

            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Obavještenja'),
              selected: context.currentRoute == Routes.notifications,
              onTap: () {
                Navigator.pop(context);
                context.goToNotifications();
              },
            ),

            ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: const Text('Favoriti'),
              selected: context.currentRoute == Routes.favorites,
              onTap: () {
                Navigator.pop(context);
                context.goToFavorites();
              },
            ),

            ListTile(
              leading: const Icon(Icons.bookmark_border),
              title: const Text('Sačuvane pretrage'),
              selected: context.currentRoute == Routes.savedSearches,
              onTap: () {
                Navigator.pop(context);
                context.goToSavedSearches();
              },
            ),
          ],

          // Owner/Admin section
          if (isAuthenticated &&
              (userRole == UserRole.owner || userRole == UserRole.admin)) ...[
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'UPRAVLJANJE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            if (userRole == UserRole.owner)
              ListTile(
                leading: const Icon(Icons.dashboard_outlined),
                title: const Text('Owner Dashboard'),
                selected: context.currentRoute == Routes.ownerDashboard,
                onTap: () {
                  Navigator.pop(context);
                  context.goToOwnerDashboard();
                },
              ),
            if (userRole == UserRole.admin) ...[
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Admin Dashboard'),
                selected: context.currentRoute?.startsWith('/admin') ?? false,
                onTap: () {
                  Navigator.pop(context);
                  context.goToAdminDashboard();
                },
              ),
            ],
          ],

          // Auth section (login/logout)
          const Divider(),

          if (!isAuthenticated) ...[
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Prijava'),
              onTap: () {
                Navigator.pop(context);
                context.goToLogin();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add_outlined),
              title: const Text('Registracija'),
              onTap: () {
                Navigator.pop(context);
                context.goToRegister();
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Odjava'),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authNotifierProvider.notifier).signOut();
                if (context.mounted) {
                  context.goToHome();
                }
              },
            ),
          ],

          // Design system demo (dev only)
          const Divider(),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Design System'),
            onTap: () {
              Navigator.pop(context);
              context.go('/design-system-demo');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAuthenticatedHeader(
    BuildContext context,
    User user,
    UserRole userRole,
  ) {
    // Try to get name from user metadata, fallback to email
    final firstName = user.userMetadata?['first_name'] as String?;
    final lastName = user.userMetadata?['last_name'] as String?;
    final userName = (firstName != null && lastName != null)
        ? '$firstName $lastName'
        : user.email ?? 'User';

    final roleLabel = userRole == UserRole.owner
        ? 'Vlasnik'
        : userRole == UserRole.admin
            ? 'Administrator'
            : 'Gost';

    return UserAccountsDrawerHeader(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: Colors.white,
        child: Text(
          userName[0].toUpperCase(),
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
      accountName: Text(
        userName,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      accountEmail: Text(
        roleLabel,
        style: const TextStyle(
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildUnauthenticatedHeader(BuildContext context) {
    return DrawerHeader(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Icon(
            Icons.home_work,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          const Text(
            'Rab Booking',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pronađite savršen smještaj',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
