import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../features/widget/presentation/screens/widget_initializer_screen.dart';
import '../../features/widget/presentation/screens/booking_widget_screen.dart';
import '../../features/widget/presentation/screens/booking_lookup_screen.dart';
import '../../features/widget/presentation/screens/booking_details_screen.dart';
import '../../features/widget/domain/models/booking_details_model.dart';
import '../../shared/presentation/screens/not_found_screen.dart';
import '../utils/unit_resolver.dart';

/// Routes constants for booking widget flow
class Routes {
  static const String widget = '/';
  static const String booking = '/booking'; // New slug-based route
  static const String calendar =
      '/calendar'; // Direct calendar view for single unit
  static const String lookup = '/lookup'; // Booking lookup
  static const String view = '/view'; // View booking details
  static const String notFound = '/404';
}

/// GoRouter for booking widget flow
///
/// Booking Flow:
/// 1. Widget Initializer (/) - Validates unit ID from URL (legacy query params)
///    OR Slug-based route (/booking/{slug}) - Resolves unit from hybrid slug
/// 2. Calendar View (/calendar) - Shows calendar for selected unit with booking form
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.widget,
    routes: [
      // NEW: Slug-based route (SEO-friendly)
      // Example: /booking/apartman-6-gMIOos
      GoRoute(
        path: '${Routes.booking}/:unitSlug',
        builder: (context, state) {
          final unitSlug = state.pathParameters['unitSlug'];
          if (unitSlug == null) {
            return const NotFoundScreen();
          }

          // Show loading while resolving unit ID
          return FutureBuilder<String?>(
            future: resolveUnitId(unitSlug),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data == null) {
                return const NotFoundScreen();
              }

              // Pass resolved unit ID to widget initializer
              // We'll redirect to legacy format internally
              return WidgetInitializerScreen(preResolvedUnitId: snapshot.data);
            },
          );
        },
      ),

      // LEGACY: Step 0: Widget Initializer (parses URL and validates)
      // Supports: /?unit=UNIT_ID or /?property=PROP_ID&unit=UNIT_ID
      GoRoute(
        path: Routes.widget,
        builder: (context, state) => const WidgetInitializerScreen(),
      ),

      // Direct Calendar View (for embedded widget with specific unit)
      // Shows calendar for the specified unit with booking form
      GoRoute(
        path: Routes.calendar,
        builder: (context, state) => const BookingWidgetScreen(),
      ),

      // Booking Lookup Screen
      GoRoute(
        path: Routes.lookup,
        builder: (context, state) => const BookingLookupScreen(),
      ),

      // Booking Details Screen (with booking data passed via extra)
      GoRoute(
        path: Routes.view,
        builder: (context, state) {
          final booking = state.extra as BookingDetailsModel?;
          if (booking == null) {
            // If no booking data, redirect to lookup
            return const BookingLookupScreen();
          }
          return BookingDetailsScreen(booking: booking);
        },
      ),

      // 404 Error page
      GoRoute(
        path: Routes.notFound,
        builder: (context, state) => const NotFoundScreen(),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
});
