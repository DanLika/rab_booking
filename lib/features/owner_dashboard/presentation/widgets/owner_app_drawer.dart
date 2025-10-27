import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/enhanced_auth_provider.dart';
import '../../../../core/config/router_owner.dart';

/// Owner app navigation drawer
class OwnerAppDrawer extends ConsumerWidget {
  final String currentRoute;

  const OwnerAppDrawer({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // User header
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                user?.email?.substring(0, 1).toUpperCase() ?? 'U',
                style: TextStyle(
                  fontSize: 32,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            accountName: Text(user?.displayName ?? 'Owner'),
            accountEmail: Text(user?.email ?? ''),
          ),

          // Navigation items
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Pregled'),
            selected: currentRoute == 'overview',
            onTap: () {
              Navigator.pop(context);
              context.go(OwnerRoutes.overview);
            },
          ),

          const Divider(),

          // 📅 Kalendar - Direct link to timeline calendar
          ListTile(
            leading: const Icon(Icons.calendar_view_month),
            title: const Text('Kalendar'),
            selected: currentRoute == 'calendar/week',
            onTap: () {
              Navigator.pop(context);
              context.go(OwnerRoutes.calendarWeek);
            },
          ),

          // 📋 REZERVACIJE - Bookings Section
          ExpansionTile(
            leading: const Icon(Icons.book_online),
            title: const Text('Rezervacije'),
            initiallyExpanded: currentRoute.startsWith('bookings'),
            children: [
              ListTile(
                leading: const SizedBox(width: 16),
                title: const Text('  Sve rezervacije'),
                selected: currentRoute == 'bookings',
                onTap: () {
                  Navigator.pop(context);
                  context.go(OwnerRoutes.bookings);
                },
              ),
              // Future: Aktivne, Istorija, Pending sections
            ],
          ),

          // ⚙️ KONFIGURACIJA - Configuration Section
          ExpansionTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Konfiguracija'),
            initiallyExpanded: currentRoute.startsWith('properties') ||
                              currentRoute.startsWith('units') ||
                              currentRoute == 'price-list',
            children: [
              ListTile(
                leading: const SizedBox(width: 16),
                title: const Text('  Smještajne jedinice'),
                selected: currentRoute == 'properties',
                onTap: () {
                  Navigator.pop(context);
                  context.go(OwnerRoutes.properties);
                },
              ),
              ListTile(
                leading: const SizedBox(width: 16),
                title: const Text('  Cjenovnik'),
                selected: currentRoute == 'price-list',
                onTap: () {
                  Navigator.pop(context);
                  context.go(OwnerRoutes.priceList);
                },
              ),
              // Future: Dostupnost, Email šabloni, Widget postavke
            ],
          ),

          // 🔗 INTEGRACIJE - Integrations Section
          ExpansionTile(
            leading: const Icon(Icons.extension_outlined),
            title: const Text('Integracije'),
            initiallyExpanded: currentRoute.startsWith('integrations'),
            children: [
              ListTile(
                leading: const SizedBox(width: 16),
                title: const Text('  Stripe Connect'),
                selected: currentRoute == 'integrations/stripe',
                onTap: () {
                  Navigator.pop(context);
                  context.go(OwnerRoutes.stripeIntegration);
                },
              ),
              // Future: Other integrations (iCal, Channel Manager, etc.)
            ],
          ),

          const Divider(),

          // Settings & Profile
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Obavještenja'),
            onTap: () {
              Navigator.pop(context);
              context.go(OwnerRoutes.notifications);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('Profil'),
            onTap: () {
              Navigator.pop(context);
              context.go(OwnerRoutes.profile);
            },
          ),

          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Odjavi se',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              await ref.read(enhancedAuthProvider.notifier).signOut();
              if (context.mounted) {
                context.go(OwnerRoutes.login);
              }
            },
          ),
        ],
      ),
    );
  }
}
