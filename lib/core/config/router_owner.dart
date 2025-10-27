import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/enhanced_login_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/enhanced_register_screen.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/owner_dashboard/presentation/providers/owner_properties_provider.dart';
import '../../features/owner_dashboard/presentation/screens/analytics_screen.dart';
import '../../features/owner_dashboard/presentation/screens/overview_screen.dart';
import '../../features/owner_dashboard/presentation/screens/properties_screen.dart';
import '../../features/owner_dashboard/presentation/screens/calendar_week_view_screen.dart';
import '../../features/owner_dashboard/presentation/screens/owner_bookings_screen.dart';
import '../../features/owner_dashboard/presentation/screens/property_form_screen.dart';
import '../../features/owner_dashboard/presentation/screens/unit_form_screen.dart';
import '../../features/owner_dashboard/presentation/screens/unit_pricing_screen.dart';
import '../../features/owner_dashboard/presentation/screens/units_management_screen.dart';
import '../../features/owner_dashboard/presentation/screens/notifications_screen.dart';
import '../../features/owner_dashboard/presentation/screens/profile_screen.dart';
import '../../features/owner_dashboard/presentation/screens/edit_profile_screen.dart';
import '../../features/owner_dashboard/presentation/screens/change_password_screen.dart';
import '../../features/owner_dashboard/presentation/screens/notification_settings_screen.dart';
import '../../features/owner_dashboard/presentation/screens/price_list_screen.dart';
import '../../features/widget/presentation/screens/embed_calendar_screen.dart';
import '../../features/widget/presentation/screens/enhanced_booking_flow_screen.dart';
import '../../shared/presentation/screens/not_found_screen.dart';
import '../../shared/providers/repository_providers.dart';
import '../providers/enhanced_auth_provider.dart';

/// Helper class to convert Stream to Listenable for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Routes for Owner App + Public Widget Embed
class OwnerRoutes {
  // Public routes (no auth required)
  static const String embedUnit = '/embed/units/:id';
  static const String booking = '/booking';

  // Auth routes
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';

  // Owner dashboard routes
  static const String overview = '/owner/overview';
  static const String properties = '/owner/properties';
  static const String calendarWeek = '/owner/calendar/week';
  static const String bookings = '/owner/bookings';
  static const String analytics = '/owner/analytics';
  static const String propertyNew = '/owner/properties/new';
  static const String propertyEdit = '/owner/properties/:id/edit';
  static const String units = '/owner/units';
  static const String unitNew = '/owner/units/new';
  static const String unitEdit = '/owner/units/:id/edit';
  static const String unitPricing = '/owner/units/:id/pricing';
  static const String notifications = '/owner/notifications';
  static const String profile = '/owner/profile';
  static const String profileEdit = '/owner/profile/edit';
  static const String profileChangePassword = '/owner/profile/change-password';
  static const String profileNotifications = '/owner/profile/notifications';
  static const String priceList = '/owner/price-list';
  static const String stripeIntegration = '/owner/integrations/stripe';
  static const String notFound = '/404';
}

/// Owner app GoRouter
final ownerRouterProvider = Provider<GoRouter>((ref) {
  // Watch enhancedAuthProvider so router rebuilds when auth state changes
  final authState = ref.watch(enhancedAuthProvider);

  return GoRouter(
    initialLocation: OwnerRoutes.login,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(ref.watch(firebaseAuthProvider).authStateChanges()),
    redirect: (context, state) {
      // Use the watched authState from above
      final isAuthenticated = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == OwnerRoutes.login ||
          state.matchedLocation == OwnerRoutes.register ||
          state.matchedLocation == OwnerRoutes.forgotPassword;

      print('[ROUTER] redirect called:');
      print('  - matchedLocation: ${state.matchedLocation}');
      print('  - isAuthenticated: $isAuthenticated');
      print('  - firebaseUser: ${authState.firebaseUser?.uid}');
      print('  - userModel: ${authState.userModel?.id}');
      print('  - isLoading: ${authState.isLoading}');

      // Allow public access to embed and booking routes (no auth required)
      final isPublicRoute = state.matchedLocation.startsWith('/embed/') ||
          state.matchedLocation.startsWith('/booking');
      if (isPublicRoute) {
        print('  → Allowing public route');
        return null; // Allow access
      }

      // Redirect root to appropriate page
      if (state.matchedLocation == '/') {
        if (isAuthenticated) {
          print('  → Redirecting / to calendar (authenticated)');
          return OwnerRoutes.calendarWeek;
        } else {
          print('  → Redirecting / to login (not authenticated)');
          return OwnerRoutes.login;
        }
      }

      // Redirect to login if not authenticated and trying to access protected routes
      if (!isAuthenticated && !isLoggingIn) {
        print('  → Redirecting to login (not authenticated)');
        return OwnerRoutes.login;
      }

      // Redirect to calendar (timeline view) if authenticated and trying to access login
      if (isAuthenticated && isLoggingIn) {
        print('  → Redirecting to calendar (authenticated, was on login)');
        return OwnerRoutes.calendarWeek; // Changed from overview to calendar
      }

      print('  → No redirect needed');
      return null;
    },
    routes: [
      // PUBLIC ROUTES (No authentication required)
      GoRoute(
        path: '/embed/units/:id',
        builder: (context, state) {
          final unitId = state.pathParameters['id'] ?? '';
          return EmbedCalendarScreen(unitId: unitId);
        },
      ),

      // Enhanced Booking Flow (public)
      GoRoute(
        path: OwnerRoutes.booking,
        builder: (context, state) {
          final propertyId = state.uri.queryParameters['propertyId'];
          return EnhancedBookingFlowScreen(propertyId: propertyId);
        },
      ),

      // Auth routes
      GoRoute(
        path: OwnerRoutes.login,
        builder: (context, state) => const EnhancedLoginScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.register,
        builder: (context, state) => const EnhancedRegisterScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.emailVerification,
        builder: (context, state) => const EmailVerificationScreen(),
      ),

      // Owner main screens
      GoRoute(
        path: OwnerRoutes.overview,
        builder: (context, state) => const OverviewScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.properties,
        builder: (context, state) => const PropertiesScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.calendarWeek,
        builder: (context, state) => const CalendarWeekViewScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.bookings,
        builder: (context, state) => const OwnerBookingsScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.analytics,
        builder: (context, state) => const AnalyticsScreen(),
      ),

      // Property management routes
      GoRoute(
        path: OwnerRoutes.propertyNew,
        builder: (context, state) => const PropertyFormScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.propertyEdit,
        builder: (context, state) {
          final propertyId = state.pathParameters['id'] ?? '';
          return PropertyEditLoader(propertyId: propertyId);
        },
      ),

      // Unit management routes
      GoRoute(
        path: OwnerRoutes.units,
        builder: (context, state) {
          final propertyId = state.uri.queryParameters['propertyId'] ?? '';
          return UnitsManagementScreen(propertyId: propertyId);
        },
      ),
      GoRoute(
        path: OwnerRoutes.unitNew,
        builder: (context, state) {
          final propertyId = state.uri.queryParameters['propertyId'] ?? '';
          return UnitFormScreen(propertyId: propertyId);
        },
      ),
      GoRoute(
        path: OwnerRoutes.unitEdit,
        builder: (context, state) {
          final unitId = state.pathParameters['id'] ?? '';
          return UnitEditLoader(unitId: unitId);
        },
      ),
      GoRoute(
        path: OwnerRoutes.unitPricing,
        builder: (context, state) {
          final unitId = state.pathParameters['id'] ?? '';
          return UnitPricingLoader(unitId: unitId);
        },
      ),

      // Notifications route
      GoRoute(
        path: OwnerRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Profile routes
      GoRoute(
        path: OwnerRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.profileEdit,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.profileChangePassword,
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: OwnerRoutes.profileNotifications,
        builder: (context, state) => const NotificationSettingsScreen(),
      ),

      // Price List route
      GoRoute(
        path: OwnerRoutes.priceList,
        builder: (context, state) => const PriceListScreen(),
      ),

      // 404
      GoRoute(
        path: OwnerRoutes.notFound,
        builder: (context, state) => const NotFoundScreen(),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundScreen(),
  );
});

/// Property Edit Loader - Fetches property and loads edit form
class PropertyEditLoader extends ConsumerWidget {
  final String propertyId;

  const PropertyEditLoader({required this.propertyId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertyAsync = ref.watch(propertyByIdProvider(propertyId));

    return propertyAsync.when(
      data: (property) {
        if (property == null) {
          return const NotFoundScreen();
        }
        return PropertyFormScreen(property: property);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Error loading property: $error'),
        ),
      ),
    );
  }
}

/// Unit Edit Loader - Fetches unit and loads edit form
class UnitEditLoader extends ConsumerWidget {
  final String unitId;

  const UnitEditLoader({required this.unitId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitAsync = ref.watch(unitByIdAcrossPropertiesProvider(unitId));

    return unitAsync.when(
      data: (unit) {
        if (unit == null) {
          return const NotFoundScreen();
        }
        return UnitFormScreen(propertyId: unit.propertyId, unit: unit);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Error loading unit: $error'),
        ),
      ),
    );
  }
}

/// Unit Pricing Loader - Fetches unit and loads pricing screen
class UnitPricingLoader extends ConsumerWidget {
  final String unitId;

  const UnitPricingLoader({required this.unitId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitAsync = ref.watch(unitByIdAcrossPropertiesProvider(unitId));

    return unitAsync.when(
      data: (unit) {
        if (unit == null) {
          return const NotFoundScreen();
        }
        return UnitPricingScreen(unit: unit);
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Error loading unit: $error'),
        ),
      ),
    );
  }
}
