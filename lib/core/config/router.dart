import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_state_provider.dart';
import '../utils/navigation_helpers.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/search/presentation/screens/search_results_screen.dart';
import '../../features/property/presentation/screens/property_details_screen.dart';
import '../../features/booking/presentation/screens/booking_screen.dart';
import '../../features/booking/presentation/screens/user_bookings_screen.dart';
import '../../features/booking/presentation/screens/booking_detail_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/owner/presentation/screens/owner_dashboard_screen.dart';
import '../../features/owner/presentation/screens/property_management_screen.dart';
import '../../features/payment/presentation/screens/payment_confirmation_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/bookings/presentation/screens/my_bookings_screen.dart';
import '../../shared/presentation/widgets/app_scaffold_with_nav.dart';
import '../../shared/presentation/screens/not_found_screen.dart';
import '../../features/design_system_demo/design_system_demo_screen.dart';

/// GoRouter provider with auth integration
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateNotifierProvider);

  // Create a stream controller to listen to auth state changes
  final streamController = StreamController<AuthState>();
  ref.listen(authStateNotifierProvider, (previous, next) {
    streamController.add(next);
  });
  ref.onDispose(() => streamController.close());

  return GoRouter(
    initialLocation: Routes.home,
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(
      streamController.stream,
    ),
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final userRole = authState.role;
      final currentPath = state.uri.path;

      // Auth pages - redirect authenticated users away
      if (currentPath.startsWith('/auth/')) {
        if (isAuthenticated) {
          // Check if there's a redirect query parameter
          final redirectTo = state.uri.queryParameters['redirect'];
          return redirectTo ?? Routes.home;
        }
        return null; // Allow access to auth pages
      }

      // Protected routes - require authentication
      final protectedRoutes = [
        '/booking/',
        '/bookings/',
        Routes.paymentConfirm,
        Routes.profile,
        Routes.myBookings,
      ];

      final isProtectedRoute = protectedRoutes.any(
        (route) => currentPath.startsWith(route),
      );

      if (isProtectedRoute && !isAuthenticated) {
        // Save intended destination and redirect to login
        return '${Routes.authLogin}?redirect=${Uri.encodeComponent(currentPath)}';
      }

      // Owner/Admin routes - require specific role
      if (currentPath.startsWith('/owner/')) {
        if (!isAuthenticated) {
          return '${Routes.authLogin}?redirect=${Uri.encodeComponent(currentPath)}';
        }

        final hasAccess = userRole == UserRole.owner || userRole == UserRole.admin;
        if (!hasAccess) {
          // Redirect to home if user doesn't have owner/admin role
          return Routes.home;
        }
      }

      // Admin routes - require admin role
      if (currentPath.startsWith('/admin/')) {
        if (!isAuthenticated) {
          return '${Routes.authLogin}?redirect=${Uri.encodeComponent(currentPath)}';
        }

        if (userRole != UserRole.admin) {
          // Redirect to home if user is not admin
          return Routes.home;
        }
      }

      return null; // No redirect needed
    },
    errorBuilder: (context, state) => const NotFoundScreen(),
    routes: [
      // Shell route with bottom navigation (for main app sections)
      ShellRoute(
        builder: (context, state, child) {
          // Determine if we should show bottom nav based on route
          final showBottomNav = _shouldShowBottomNav(state.uri.path);

          if (showBottomNav) {
            return AppScaffoldWithNav(child: child);
          }

          return child;
        },
        routes: [
          // Public routes
          GoRoute(
            path: Routes.home,
            name: 'home',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: Routes.search,
            name: 'search',
            pageBuilder: (context, state) {
              final query = state.uri.queryParameters['q'];
              final location = state.uri.queryParameters['location'];
              final guestsStr = state.uri.queryParameters['guests'];
              final checkIn = state.uri.queryParameters['checkIn'];
              final checkOut = state.uri.queryParameters['checkOut'];

              final guests = guestsStr != null ? int.tryParse(guestsStr) : null;

              return CustomTransitionPage(
                key: state.pageKey,
                child: SearchResultsScreen(
                  query: query,
                  location: location,
                  maxGuests: guests,
                  checkIn: checkIn,
                  checkOut: checkOut,
                ),
                transitionsBuilder: _slideTransition,
              );
            },
          ),
          GoRoute(
            path: Routes.myBookings,
            name: 'myBookings',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const UserBookingsScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
          GoRoute(
            path: Routes.profile,
            name: 'profile',
            pageBuilder: (context, state) => CustomTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
              transitionsBuilder: _fadeTransition,
            ),
          ),
        ],
      ),

      // Property details (outside shell for full-screen)
      GoRoute(
        path: Routes.propertyDetails,
        name: 'propertyDetails',
        pageBuilder: (context, state) {
          final propertyId = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: PropertyDetailsScreen(propertyId: propertyId),
            transitionsBuilder: _slideTransition,
          );
        },
      ),

      // Booking flow (outside shell)
      GoRoute(
        path: Routes.booking,
        name: 'booking',
        pageBuilder: (context, state) {
          final unitId = state.pathParameters['unitId']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: BookingScreen(unitId: unitId),
            transitionsBuilder: _slideTransition,
          );
        },
      ),

      // Booking detail
      GoRoute(
        path: '/bookings/:id',
        name: 'bookingDetail',
        pageBuilder: (context, state) {
          final bookingId = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: BookingDetailScreen(bookingId: bookingId),
            transitionsBuilder: _slideTransition,
          );
        },
      ),

      // Payment confirmation
      GoRoute(
        path: Routes.paymentConfirm,
        name: 'paymentConfirm',
        pageBuilder: (context, state) {
          final bookingId = state.uri.queryParameters['bookingId'];
          return CustomTransitionPage(
            key: state.pageKey,
            child: PaymentConfirmationScreen(bookingId: bookingId),
            transitionsBuilder: _fadeTransition,
          );
        },
      ),

      // Auth routes
      GoRoute(
        path: Routes.authLogin,
        name: 'login',
        pageBuilder: (context, state) {
          final redirectTo = state.uri.queryParameters['redirect'];
          return CustomTransitionPage(
            key: state.pageKey,
            child: LoginScreen(redirectTo: redirectTo),
            transitionsBuilder: _fadeTransition,
          );
        },
      ),
      GoRoute(
        path: Routes.authRegister,
        name: 'register',
        pageBuilder: (context, state) {
          final redirectTo = state.uri.queryParameters['redirect'];
          return CustomTransitionPage(
            key: state.pageKey,
            child: RegisterScreen(redirectTo: redirectTo),
            transitionsBuilder: _fadeTransition,
          );
        },
      ),

      // Owner routes
      GoRoute(
        path: Routes.ownerDashboard,
        name: 'ownerDashboard',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const OwnerDashboardScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: Routes.ownerProperty,
        name: 'ownerProperty',
        pageBuilder: (context, state) {
          final propertyId = state.pathParameters['id']!;
          return CustomTransitionPage(
            key: state.pageKey,
            child: PropertyManagementScreen(propertyId: propertyId),
            transitionsBuilder: _slideTransition,
          );
        },
      ),

      // Design System Demo (for development)
      GoRoute(
        path: '/design-system-demo',
        name: 'designSystemDemo',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const DesignSystemDemoScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),

      // 404 route
      GoRoute(
        path: Routes.notFound,
        name: 'notFound',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NotFoundScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
    ],
  );
});

/// Helper to determine if bottom nav should be shown
bool _shouldShowBottomNav(String path) {
  final bottomNavRoutes = [
    Routes.home,
    Routes.search,
    Routes.myBookings,
    Routes.profile,
  ];

  return bottomNavRoutes.any((route) => path == route);
}

/// Custom page transitions

/// Fade transition
Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(
    opacity: animation.drive(CurveTween(curve: Curves.easeInOut)),
    child: child,
  );
}

/// Slide transition (from right)
Widget _slideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  const begin = Offset(1.0, 0.0);
  const end = Offset.zero;
  const curve = Curves.easeInOutCubic;

  final tween = Tween(begin: begin, end: end).chain(
    CurveTween(curve: curve),
  );

  return SlideTransition(
    position: animation.drive(tween),
    child: child,
  );
}

/// Slide transition (from bottom)
Widget _slideUpTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  const begin = Offset(0.0, 1.0);
  const end = Offset.zero;
  const curve = Curves.easeOutCubic;

  final tween = Tween(begin: begin, end: end).chain(
    CurveTween(curve: curve),
  );

  return SlideTransition(
    position: animation.drive(tween),
    child: child,
  );
}

/// Scale transition
Widget _scaleTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return ScaleTransition(
    scale: animation.drive(
      Tween<double>(begin: 0.8, end: 1.0).chain(
        CurveTween(curve: Curves.easeOutCubic),
      ),
    ),
    child: FadeTransition(
      opacity: animation,
      child: child,
    ),
  );
}

/// GoRouter refresh stream helper
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (data) => notifyListeners(),
        );
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
