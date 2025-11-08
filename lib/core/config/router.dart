import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../features/widget/presentation/screens/widget_initializer_screen.dart';
import '../../features/widget/presentation/screens/booking_widget_screen.dart';
import '../../features/widget/presentation/screens/enhanced_room_selection_screen.dart';
import '../../features/widget/presentation/screens/enhanced_summary_screen.dart';
import '../../features/widget/presentation/screens/enhanced_payment_screen.dart';
import '../../features/widget/presentation/screens/enhanced_confirmation_screen.dart';
import '../../shared/presentation/screens/not_found_screen.dart';
import '../utils/unit_resolver.dart';

/// Routes constants for multi-step booking widget flow
class Routes {
  static const String widget = '/';
  static const String booking = '/booking'; // New slug-based route
  static const String calendar = '/calendar'; // Direct calendar view for single unit
  static const String roomSelection = '/rooms';
  static const String summary = '/summary';
  static const String payment = '/payment';
  static const String confirmation = '/confirmation';
  static const String notFound = '/404';
}

/// Multi-step GoRouter for enhanced widget flow
///
/// Booking Flow:
/// 1. Widget Initializer (/) - Validates unit ID from URL (legacy query params)
///    OR Slug-based route (/booking/{slug}) - Resolves unit from hybrid slug
/// 2. Room Selection (/rooms) - Shows calendar + available rooms
/// 3. Summary (/summary) - Booking details review
/// 4. Payment (/payment) - Payment method selection
/// 5. Confirmation (/confirmation) - Booking confirmation
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.widget,
    debugLogDiagnostics: false,
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
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                return const NotFoundScreen();
              }

              // Pass resolved unit ID to widget initializer
              // We'll redirect to legacy format internally
              return WidgetInitializerScreen(
                preResolvedUnitId: snapshot.data,
              );
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
      // Shows ONLY calendar for the specified unit, no room selection
      GoRoute(
        path: Routes.calendar,
        builder: (context, state) => const BookingWidgetScreen(),
      ),

      // Step 1: Room Selection with calendar
      GoRoute(
        path: Routes.roomSelection,
        builder: (context, state) {
          final propertyId = state.uri.queryParameters['property'];
          final unitId = state.uri.queryParameters['unit'];
          return EnhancedRoomSelectionScreen(
            propertyId: propertyId,
            unitId: unitId,
          );
        },
      ),

      // Step 2: Booking Summary
      GoRoute(
        path: Routes.summary,
        builder: (context, state) => const EnhancedSummaryScreen(),
      ),

      // Step 3: Payment
      GoRoute(
        path: Routes.payment,
        builder: (context, state) => const EnhancedPaymentScreen(),
      ),

      // Step 4: Confirmation
      GoRoute(
        path: Routes.confirmation,
        builder: (context, state) {
          final bookingRef = state.uri.queryParameters['ref'];
          final isStripe = state.uri.queryParameters['stripe'] == 'true';
          return EnhancedConfirmationScreen(
            bookingReference: bookingRef,
            isStripePayment: isStripe,
          );
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
