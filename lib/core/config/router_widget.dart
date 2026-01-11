import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../services/sentry_navigator_observer.dart';
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
    observers: [SentryNavigatorObserver()],
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

      // Booking lookup from email link
      // URL: /view?ref=BOOKING_REF&email=EMAIL&token=TOKEN
      // IMPORTANT: Must be defined BEFORE /:slug catch-all route!
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
          // URL: /view/details?ref=BOOKING_REF&email=EMAIL
          // Navigated to after successful booking lookup OR accessed directly via refresh
          GoRoute(
            path: 'details',
            builder: (context, state) {
              final extra = state.extra;

              // Check if we have query params (for page refresh scenario)
              final ref = state.uri.queryParameters['ref'];
              final email = state.uri.queryParameters['email'];
              final token = state.uri.queryParameters['token'];

              // If extra is null but we have query params, redirect to /view to re-lookup
              // This handles the page refresh case
              // Use navigateToDetails flag to tell BookingViewScreen to show details inline
              // instead of navigating (which would cause infinite loop)
              if (extra == null && ref != null && email != null) {
                // Return BookingViewScreen in "show details inline" mode
                return BookingViewScreen(
                  bookingRef: ref,
                  email: email,
                  token: token,
                  showDetailsInline:
                      true, // Prevents navigation loop on refresh
                );
              }

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

      // SOCIAL SHARE ROUTE - Short links for sharing
      // URL: /s/:unitId
      // Resolves: unitId -> property automatically
      GoRoute(
        path: '/s/:unitId',
        builder: (context, state) {
          final unitId = state.pathParameters['unitId'];
          return BookingWidgetScreen(initialUnitId: unitId);
        },
      ),

      // SLUG ROUTE - Clean URL for standalone pages (MUST BE LAST - catch-all)
      // URL: /apartman-6 (subdomain parsed from hostname)
      // Resolves: subdomain -> property, slug -> unit
      GoRoute(
        path: '/:slug',
        builder: (context, state) {
          final slug = state.pathParameters['slug'];
          return BookingWidgetScreen(urlSlug: slug);
        },
      ),
    ],

    // Error page for unknown routes
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
});
