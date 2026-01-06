import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/router_owner.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/owner_bookings_provider.dart';
import '../../../../core/theme/app_color_extensions.dart';

/// Determines the selected index of the bottom navigation bar based on the current route.
int _calculateSelectedIndex(String route) {
  if (route.startsWith(OwnerRoutes.overview)) return 0;
  if (route.startsWith(OwnerRoutes.calendarTimeline)) return 1;
  if (route.startsWith(OwnerRoutes.bookings)) return 2;
  if (route.startsWith(OwnerRoutes.unitHub)) return 3;
  return 0; // Default to Overview
}

class OwnerBottomNav extends ConsumerWidget {
  const OwnerBottomNav({
    super.key,
    required this.currentRoute,
  });

  final String currentRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selectedIndex = _calculateSelectedIndex(currentRoute);

    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go(OwnerRoutes.overview);
            break;
          case 1:
            context.go(OwnerRoutes.calendarTimeline);
            break;
          case 2:
            context.go(OwnerRoutes.bookings);
            break;
          case 3:
            context.go(OwnerRoutes.unitHub);
            break;
        }
      },
      // Consistent styling with the rest of the app
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Theme.of(context).unselectedWidgetColor,
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.grid_view_rounded),
          label: l10n.ownerDrawerOverview,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.calendar_month_rounded),
          label: l10n.ownerDrawerCalendar,
        ),
        BottomNavigationBarItem(
          icon: Consumer(
            builder: (context, ref, child) {
              final pendingCountAsync = ref.watch(pendingBookingsCountProvider);
              final pendingCount =
                  pendingCountAsync.maybeWhen(data: (c) => c, orElse: () => 0);
              return Badge(
                isLabelVisible: pendingCount > 0,
                label: Text(pendingCount.toString()),
                child: const Icon(Icons.event_note_rounded),
              );
            },
          ),
          label: l10n.ownerDrawerBookings,
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.apartment_rounded),
          label: l10n.ownerDrawerUnits,
        ),
      ],
    );
  }
}
