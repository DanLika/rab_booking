import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/widget/presentation/screens/booking_widget_screen.dart';
import '../../features/widget/presentation/screens/booking_view_screen.dart';
import '../../features/widget/presentation/screens/booking_details_screen.dart';
import '../../shared/presentation/screens/not_found_screen.dart';

/// Minimal Widget Router - NO authentication, NO owner dashboard routes
///
/// This router is specifically for the embeddable booking widget.
/// It only includes public routes needed for:
/// - Calendar/booking widget display (with query params OR slug URLs)
/// - Booking lookup from email links
/// - Booking details display
///
/// URL formats supported:
/// - Query params: `?property=PROPERTY_ID&unit=UNIT_ID` (iframe embeds)
/// - Slug URL: `/apartman-6` with subdomain (standalone pages)
///
/// NO auth redirects, NO owner dashboard, NO login screens.
final widgetRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    debugLogDiagnostics: true,
    // No auth redirects - all routes are public
    routes: [
      // ROOT ROUTE - Shows booking widget
      // URL: /?property=PROPERTY_ID&unit=UNIT_ID
      // OR: subdomain.bookbed.io/ (property-level, no specific unit)
      GoRoute(
        path: '/',
        builder: (context, state) => const BookingWidgetScreen(),
      ),

      // Calendar route (alternative entry point)
      // URL: /calendar?property=PROPERTY_ID&unit=UNIT_ID
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const BookingWidgetScreen(),
      ),

      // SLUG ROUTE - Clean URL for standalone pages
      // URL: /apartman-6 (subdomain parsed from hostname)
      // Resolves: subdomain -> property, slug -> unit
      GoRoute(
        path: '/:slug',
        builder: (context, state) {
          final slug = state.pathParameters['slug'];
          // Skip if slug looks like a system route
          if (slug == 'view' || slug == 'calendar') {
            return const BookingWidgetScreen();
          }
          return BookingWidgetScreen(urlSlug: slug);
        },
      ),

      // Booking lookup from email link
      // URL: /view?ref=BOOKING_REF&email=EMAIL&token=TOKEN
      GoRoute(
        path: '/view',
        builder: (context, state) {
          final ref = state.uri.queryParameters['ref'];
          final email = state.uri.queryParameters['email'];
          final token = state.uri.queryParameters['token'];
          return BookingViewScreen(bookingRef: ref, email: email, token: token);
        },
        routes: [
          // Booking details sub-route
          // Navigated to after successful booking lookup
          GoRoute(
            path: 'details',
            builder: (context, state) {
              final extra = state.extra;
              if (extra == null) {
                return const NotFoundScreen();
              }

              // Support both old and new format for backwards compatibility
              if (extra is Map<String, dynamic>) {
                // New format: {booking: BookingDetailsModel, widgetSettings: WidgetSettings?}
                final booking = extra['booking'];
                final widgetSettings = extra['widgetSettings'];
                if (booking == null) {
                  return const NotFoundScreen();
                }
                return BookingDetailsScreen(
                  booking: booking as dynamic,
                  widgetSettings: widgetSettings as dynamic,
                );
              } else {
                // Old format: BookingDetailsModel directly
                return BookingDetailsScreen(booking: extra as dynamic);
              }
            },
          ),
        ],
      ),
    ],

    // Error page for unknown routes
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
});
